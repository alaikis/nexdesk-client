import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/api_client.dart';
import '../../core/crypto_service.dart';
import '../../core/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  final CryptoService _crypto = CryptoService();

  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _email;
  String? _deviceId;
  String? _deviceName;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get email => _email;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  String? _lastError;
  String? get lastError => _lastError;

  Future<void> init() async {
    _lastError = null;
    await _api.init();
    final token = await StorageService.getString('jwt_token');
    if (token != null) {
      _status = AuthStatus.authenticated;
      try {
        final meRes = await _api.get('/auth/me');
        _userId = meRes['id']?.toString();
        _email = meRes['email'] as String?;
      } on ApiException catch (e) {
        _status = AuthStatus.unauthenticated;
        _lastError = e.message;
        await StorageService.delete('jwt_token');
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    _deviceId = await StorageService.getString('device_id');
    if (_deviceId == null) {
      _deviceId = _generateDeviceId();
      await StorageService.setString('device_id', _deviceId!);
    }
    notifyListeners();
  }

  Future<bool> register(String email, String password, String name) async {
    _lastError = null;
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
    try {
      final res = await _api.login(email: email, password: password);
      _userId = res['id']?.toString();
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
    await _api.logout();
    _status = AuthStatus.unauthenticated;
    _userId = null;
    _email = null;
    notifyListeners();
  }

  Future<void> _ensureDeviceRegistered(String fallbackName) async {
    final existing = await _api.listDevices();
    final known = existing.firstWhere(
      (d) => d['id'] == _deviceId,
      orElse: () => <String, dynamic>{},
    );
    if ((known as Map).isEmpty) {
      final pubkey = base64Encode(_crypto.publicKey);
      final fingerprint = CryptoService.sha256Hash(_crypto.publicKey);
      await _api.registerDevice(
        name: fallbackName,
        os: _detectOS(),
        pubkey: pubkey,
        fingerprint: fingerprint,
      );
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
