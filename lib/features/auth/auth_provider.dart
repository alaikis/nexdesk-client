import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
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

  String? _ssoAuthUrl;
  String? _ssoSessionId;
  bool _ssoPolling = false;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get email => _email;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  String? get lastError => _lastError;
  String? get ssoAuthUrl => _ssoAuthUrl;
  bool get ssoPolling => _ssoPolling;

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

  Future<bool> startSSOLogin() async {
    _lastError = null;
    try {
      final res = await _api.ssoDesktopInit();
      _ssoAuthUrl = res['auth_url'] as String?;
      _ssoSessionId = res['session_id'] as String?;

      if (_ssoAuthUrl == null || _ssoSessionId == null) {
        _lastError = 'Failed to initialize SSO login';
        notifyListeners();
        return false;
      }

      final uri = Uri.parse(_ssoAuthUrl!);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      _pollSSOStatus();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      debugPrint('SSO init failed: $e');
      notifyListeners();
      return false;
    }
  }

  void _pollSSOStatus() {
    if (_ssoPolling || _ssoSessionId == null) return;
    _ssoPolling = true;
    notifyListeners();
    _pollLoop();
  }

  void _pollLoop() async {
    while (_ssoPolling && _ssoSessionId != null) {
      await Future.delayed(const Duration(seconds: 2));
      if (!_ssoPolling) break;

      try {
        final res = await _api.ssoDesktopPoll(_ssoSessionId!);
        final status = res['status'] as String?;

        if (status == 'complete') {
          final token = res['access_token'] as String?;
          final refresh = res['refresh_token'] as String?;
          if (token != null) {
            await _api.saveSsoToken(token, refresh);

            try {
              final meRes = await _api.get('/auth/me');
              _userId = meRes['id']?.toString();
              _email = meRes['email'] as String?;
            } catch (_) {}

            await _ensureDeviceRegistered(_email ?? 'My Device');
            _status = AuthStatus.authenticated;
          }
          _ssoPolling = false;
          _ssoAuthUrl = null;
          _ssoSessionId = null;
          notifyListeners();
          return;
        } else if (status == 'error') {
          _lastError = res['error'] as String? ?? 'SSO login failed';
          _ssoPolling = false;
          _ssoAuthUrl = null;
          _ssoSessionId = null;
          notifyListeners();
          return;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          _lastError = 'SSO session expired. Please try again.';
          _ssoPolling = false;
          _ssoAuthUrl = null;
          _ssoSessionId = null;
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('SSO poll error: $e');
      }
    }
  }

  void cancelSSOLogin() {
    _ssoPolling = false;
    _ssoAuthUrl = null;
    _ssoSessionId = null;
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
    await _api.ssoDesktopLogout();
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