import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../core/api_client.dart';
import '../../core/oidc_sso_client.dart';
import '../../core/local_sso_server.dart';
import '../../core/secure_storage_service.dart';
import '../../core/storage_service.dart';
import '../../core/device_fingerprint_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _email;
  String? _deviceId;
  String? _deviceName;

  // SSO 状态
  String? _ssoAuthUrl;
  bool _ssoPolling = false;
  LocalSsoCallbackServer? _localServer;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get email => _email;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  String? get lastError => _lastError;
  String? get ssoAuthUrl => _ssoAuthUrl;
  bool get ssoInProgress => _ssoPolling;

  String? _lastError;
  String? _pending2FATempToken;
  bool get requires2FA => _pending2FATempToken != null;

  /// 标准 OIDC 公共客户端
  OidcSsoClient get _oidcClient => OidcSsoClient(
        passportBaseUrl: AppConfig.passportBaseUrl,
        clientId: AppConfig.passportClientId,
        redirectUri: AppConfig.ssoCallbackUrl,
      );

  Future<void> init() async {
    _lastError = null;
    await _api.init();
    final token = await SecureStorageService.getString('jwt_token');
    if (token != null) {
      _status = AuthStatus.authenticated;
      try {
        final meRes = await _api.get('/auth/me');
        _userId = meRes['id']?.toString();
        _email = meRes['email'] as String?;
      } on ApiException {
        _status = AuthStatus.unauthenticated;
        await SecureStorageService.delete('jwt_token');
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    _deviceId = await SecureStorageService.getString('device_id');
    if (_deviceId == null) {
      _deviceId = _generateDeviceId();
      await SecureStorageService.setString('device_id', _deviceId!);
    }

    final existingClientId = await StorageService.getString('client_id');
    if (existingClientId == null) {
      await StorageService.setString('client_id', const Uuid().v4());
    }

    notifyListeners();
  }

  /// 标准 OIDC + PKCE 桌面登录:
  /// 1. 启动本地回调服务器
  /// 2. 生成 PKCE + state, 打开系统浏览器到 passport authorize
  /// 3. 浏览器登录成功后重定向到本地服务器, 捕获 code
  /// 4. 验证 state, 本地用 code + PKCE verifier 交换 token
  /// 5. 保存 token
  Future<bool> startSSOLogin() async {
    _lastError = null;
    _ssoPolling = true;
    notifyListeners();

    try {
      // 1. 启动本地回调服务器
      _localServer = LocalSsoCallbackServer(AppConfig.ssoCallbackPort);
      await _localServer!.start();

      // 2. 生成 PKCE + 授权 URL
      final oidc = _oidcClient;
      final authUrl = oidc.buildAuthorizeUrl();
      final expectedState = oidc.expectedState;
      _ssoAuthUrl = authUrl;

      // 3. 打开系统浏览器
      final uri = Uri.parse(authUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw ApiException(0, 'Could not open browser for SSO login');
      }

      // 4. 等待浏览器回跳到本地服务器
      final callback = await _localServer!.waitForCallback();
      _localServer = null;

      final error = callback['error'];
      if (error != null) {
        _lastError = error == 'timeout'
            ? 'Login timed out. Please try again.'
            : 'SSO login failed: $error';
        _ssoPolling = false;
        _ssoAuthUrl = null;
        notifyListeners();
        return false;
      }

      final code = callback['code'];
      final state = callback['state'];
      if (code == null) {
        _lastError = 'No authorization code received';
        _ssoPolling = false;
        _ssoAuthUrl = null;
        notifyListeners();
        return false;
      }

      // 5. 验证 state (防 CSRF)
      if (state != expectedState) {
        _lastError = 'State mismatch - security check failed';
        _ssoPolling = false;
        _ssoAuthUrl = null;
        notifyListeners();
        return false;
      }

      // 6. 本地 PKCE 交换 token
      final tokenData = await oidc.exchangeCodeForToken(code);
      final accessToken = tokenData['access_token'] as String?;
      final refreshToken = tokenData['refresh_token'] as String?;

      if (accessToken == null) {
        _lastError = 'No access token in response';
        _ssoPolling = false;
        _ssoAuthUrl = null;
        notifyListeners();
        return false;
      }

      // 7. 保存 token
      await _api.saveSsoToken(accessToken, refreshToken);

      try {
        final meRes = await _api.get('/auth/me');
        _userId = meRes['id']?.toString();
        _email = meRes['email'] as String?;
      } on ApiException {
        // token 有效但 /auth/me 失败(如 passport 用户 ID 不匹配), 仍视为已登录
      }

      await _ensureDeviceRegistered(_email ?? 'My Device');
      _status = AuthStatus.authenticated;
      _ssoPolling = false;
      _ssoAuthUrl = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      debugPrint('SSO login failed: $e');
      await _localServer?.waitForCallback(timeout: Duration.zero);
      _localServer = null;
      _ssoPolling = false;
      _ssoAuthUrl = null;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('SSO login error: $e');
      _ssoPolling = false;
      _ssoAuthUrl = null;
      notifyListeners();
      return false;
    }
  }

  void cancelSSOLogin() {
    _ssoPolling = false;
    _ssoAuthUrl = null;
    notifyListeners();
  }

  Future<bool> register(String email, String password, String name) async {
    _lastError = null;
    _pending2FATempToken = null;
    try {
      final res = await _api.register(email: email, password: password, name: name);
      _userId = res['id']?.toString();
      _email = email;
      await _ensureDeviceRegistered(name);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      debugPrint('Register failed: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    _pending2FATempToken = null;
    try {
      final res = await _api.login(email: email, password: password);
      if (res['requires_2fa'] == true) {
        _pending2FATempToken = res['temp_token'] as String?;
        return false;
      }
      _userId = (res['user'] as Map?)?['id']?.toString() ?? res['id']?.toString();
      _email = email;
      await _ensureDeviceRegistered(_email ?? 'My Device');
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      debugPrint('Login failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _lastError = null;
    _pending2FATempToken = null;
    await _api.logout();
    _status = AuthStatus.unauthenticated;
    _userId = null;
    _email = null;
    notifyListeners();
  }

  String? get pending2FATempToken => _pending2FATempToken;

  Future<bool> verify2FA(String code) async {
    _lastError = null;
    if (_pending2FATempToken == null) return false;
    try {
      final ok = await _api.verifyTOTP(_pending2FATempToken!, code);
      if (ok) {
        final meRes = await _api.get('/auth/me');
        _userId = meRes['id']?.toString();
        _email = meRes['email'] as String?;
        _status = AuthStatus.authenticated;
        _pending2FATempToken = null;
        notifyListeners();
        return true;
      }
      _lastError = 'Invalid code';
      return false;
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    }
  }

  Future<void> _ensureDeviceRegistered(String fallbackName) async {
    final clientId = await StorageService.getString('client_id');
    final fingerprint = await DeviceFingerprintService.getFingerprint();
    try {
      final existing = await _api.listDevices();
      final known = existing.firstWhere(
        (d) => d['client_id']?.toString() == clientId,
        orElse: () => <String, dynamic>{},
      );
      if ((known as Map).isEmpty) {
        final knownByFingerprint = existing.firstWhere(
          (d) => d['fingerprint']?.toString() == fingerprint,
          orElse: () => <String, dynamic>{},
        );
        if ((knownByFingerprint as Map).isNotEmpty) {
          final existingId = knownByFingerprint['id']?.toString();
          if (existingId != null) {
            _deviceId = existingId;
            await SecureStorageService.setString('device_id', _deviceId!);
            _deviceName = fallbackName;
            return;
          }
        }
        final res = await _api.registerDevice(
          name: fallbackName,
          os: _detectOS(),
          pubkey: '',
          clientId: clientId,
          fingerprint: fingerprint,
        );
        final newDeviceId = res['id']?.toString();
        if (newDeviceId != null) {
          _deviceId = newDeviceId;
          await SecureStorageService.setString('device_id', _deviceId!);
        }
      } else {
        final existingId = known['id']?.toString();
        if (existingId != null && _deviceId != existingId) {
          _deviceId = existingId;
          await SecureStorageService.setString('device_id', _deviceId!);
        }
      }
    } on ApiException {
      // 设备注册失败不阻塞登录
    }
    _deviceName = fallbackName;
  }

  String _generateDeviceId() => const Uuid().v4();

  String _detectOS() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}