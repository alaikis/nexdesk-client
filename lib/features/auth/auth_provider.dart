import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/secure_storage_service.dart';
import '../../core/storage_service.dart';
import '../../core/device_fingerprint_service.dart';
import '../../core/lan_discovery_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// 单个授权窗口内的轮询间隔。
const Duration _kSSOPollInterval = Duration(seconds: 2);

/// 单个授权窗口的轮询次数：300 × 2s = 600s，与服务端 ssoSessionTTL 对齐。
const int _kSSOPollAttemptsPerWindow = 300;

/// 授权窗口超时后重新获取 auth_url 的最大次数（0 表示不刷新）。
const int _kSSOMaxRefresh = 2;

/// 单个授权窗口的轮询结果。
enum _SSOPollOutcome {
  /// 拿到 token，登录成功。
  complete,

  /// 窗口超时或服务端 session 已过期，可以重新获取授权地址。
  expired,

  /// 服务端返回明确错误，不重试。
  failed,

  /// 用户取消或页面销毁。
  cancelled,
}

class AuthProvider with ChangeNotifier {
  AuthProvider({
    ApiClient? api,
    Future<bool> Function(Uri uri)? launchBrowser,
    this.pollInterval = _kSSOPollInterval,
    this.pollAttemptsPerWindow = _kSSOPollAttemptsPerWindow,
    this.maxRefresh = _kSSOMaxRefresh,
  })  : _api = api ?? ApiClient(),
        _launchBrowser = launchBrowser ?? _openInBrowser;

  final ApiClient _api;
  final Future<bool> Function(Uri uri) _launchBrowser;

  /// 单个授权窗口内的轮询间隔。
  final Duration pollInterval;

  /// 单个授权窗口的轮询次数，乘 [pollInterval] 即该窗口的有效期。
  final int pollAttemptsPerWindow;

  /// 授权窗口超时后重新获取 auth_url 的最大次数（0 表示不刷新）。
  final int maxRefresh;

  static Future<bool> _openInBrowser(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _email;
  String? _deviceId;
  String? _deviceName;

  // SSO 状态（云端驱动，客户端不保存凭据）
  String? _ssoAuthUrl;
  bool _ssoPolling = false;

  /// 授权窗口超时后自动刷新登录地址时的用户提示；为 null 表示无提示。
  String? _ssoHint;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get email => _email;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  String? get lastError => _lastError;
  String? get ssoAuthUrl => _ssoAuthUrl;
  bool get ssoInProgress => _ssoPolling;
  String? get ssoHint => _ssoHint;

  String? _lastError;
  String? _pending2FATempToken;
  bool get requires2FA => _pending2FATempToken != null;

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

  /// 云端 SSO 桌面登录（客户端不保存任何登录凭据）:
  /// 1. 调用云端 /sso/desktop/init，服务端生成 PKCE + passport authorize URL
  /// 2. 打开系统浏览器到 auth_url
  /// 3. 用户在 passport 登录，passport 重定向到云端 /sso/desktop/callback
  /// 4. 云端用 code + code_verifier + client_secret 交换 token，存入 session
  /// 5. 客户端轮询 /sso/desktop/poll，获取 access/refresh token
  /// 6. 保存 token（仅 token，不含密码/凭据）
  ///
  /// 若用户打开登录窗口后长时间未登录，该授权窗口会超时（客户端窗口长度与
  /// 服务端 session TTL 对齐）。此时自动重新调用 init 获取新的 auth_url 并
  /// 重新打开浏览器，最多刷新 [maxRefresh] 次，避免用户停留在已失效的登录页
  /// 而误以为登录失败。
  Future<bool> startSSOLogin() async {
    _lastError = null;
    _ssoHint = null;
    _ssoPolling = true;
    _ssoAuthUrl = null;
    notifyListeners();

    for (var window = 0; window <= maxRefresh; window++) {
      if (!_ssoPolling) return _finishSSOLogin(false);

      if (window > 0) {
        _ssoHint = '登录窗口已超时，正在刷新登录地址（$window/$maxRefresh）';
        notifyListeners();
      }

      try {
        // 1. 调用云端获取 auth_url + session_id
        final initRes = await _api.ssoDesktopInit();
        final authUrl = initRes['auth_url'] as String?;
        final sessionId = initRes['session_id'] as String?;

        if (authUrl == null || sessionId == null) {
          _lastError = 'Failed to initialize SSO login';
          return _finishSSOLogin(false);
        }

        _ssoAuthUrl = authUrl;
        notifyListeners();

        // 2. 打开系统浏览器
        final launched = await _launchBrowser(Uri.parse(authUrl));
        if (!launched) {
          _lastError = 'Could not open browser for SSO login';
          return _finishSSOLogin(false);
        }

        // 3. 轮询云端登录状态
        switch (await _pollSSOStatus(sessionId)) {
          case _SSOPollOutcome.complete:
            return _finishSSOLogin(true);
          case _SSOPollOutcome.failed:
          case _SSOPollOutcome.cancelled:
            return _finishSSOLogin(false);
          case _SSOPollOutcome.expired:
            // 窗口超时或服务端 session 已过期 → 进入下一轮重新获取授权地址
            continue;
        }
      } on ApiException catch (e) {
        _lastError = e.message;
        debugPrint('SSO login failed: $e');
        return _finishSSOLogin(false);
      } catch (e) {
        _lastError = e.toString();
        debugPrint('SSO login error: $e');
        return _finishSSOLogin(false);
      }
    }

    _lastError = 'Login timed out. Please try again.';
    return _finishSSOLogin(false);
  }

  /// 结束 SSO 登录，统一清理临时状态并通知 UI。
  bool _finishSSOLogin(bool ok) {
    _ssoPolling = false;
    _ssoAuthUrl = null;
    _ssoHint = null;
    notifyListeners();
    return ok;
  }

  /// 轮询云端 SSO 登录状态，直到 complete/error/窗口超时。
  Future<_SSOPollOutcome> _pollSSOStatus(String sessionId) async {
    for (var i = 0; i < pollAttemptsPerWindow; i++) {
      await Future.delayed(pollInterval);
      if (!_ssoPolling) return _SSOPollOutcome.cancelled;

      try {
        final res = await _api.ssoDesktopPoll(sessionId);
        final status = res['status'] as String?;

        if (status == 'complete') {
          final accessToken = res['access_token'] as String?;
          final refreshToken = res['refresh_token'] as String?;
          if (accessToken == null) {
            _lastError = 'No access token in response';
            return _SSOPollOutcome.failed;
          }

          // 保存 token（仅 token，不含密码）
          await _api.saveSsoToken(accessToken, refreshToken);

          try {
            final meRes = await _api.get('/auth/me');
            _userId = meRes['id']?.toString();
            _email = meRes['email'] as String?;
          } on ApiException {
            // token 有效但 /auth/me 失败，仍视为已登录
          }

          await _ensureDeviceRegistered(_email ?? 'My Device');
          _status = AuthStatus.authenticated;
          return _SSOPollOutcome.complete;
        } else if (status == 'error') {
          _lastError = res['error'] as String? ?? 'SSO login failed';
          return _SSOPollOutcome.failed;
        }
        // status == "pending" → 继续轮询
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          // 服务端 session 已过期（超过 TTL 或已被清理）→ 需要新的授权地址
          return _SSOPollOutcome.expired;
        }
        // 网络抖动，继续轮询
      }
    }

    // 窗口内一直 pending → 视为超时，交由上层决定是否重新获取授权地址
    return _SSOPollOutcome.expired;
  }

  void cancelSSOLogin() {
    _ssoPolling = false;
    _ssoAuthUrl = null;
    _ssoHint = null;
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
    // 整个过程都不阻塞登录：本地存储/指纹插件缺失、网络异常都只跳过设备登记。
    try {
      final clientId = await StorageService.getString('client_id');
      final fingerprint = await DeviceFingerprintService.getFingerprint();
      // 上报本机局域网 IPv4，服务端存 devices.ip，供 host 候选/局域网直连使用。
      final lanIp = await LanDiscoveryService.localIpv4();
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
          ip: lanIp,
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
    } catch (e) {
      // 设备指纹/本地存储等能力异常同样不阻塞登录
      debugPrint('Device registration skipped: $e');
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