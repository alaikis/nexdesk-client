import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _prefix = 'nex_';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: _prefix + key);
    } on Exception catch (_) {
      return null;
    }
  }

  static Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: _prefix + key, value: value);
    } on Exception catch (_) {
      debugPrint('SecureStorage write failed for $key');
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: _prefix + key);
    } on Exception catch (_) {
      debugPrint('SecureStorage delete failed for $key');
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } on Exception catch (_) {
      debugPrint('SecureStorage clear failed');
    }
  }

  static Future<bool> has(String key) async {
    final val = await getString(key);
    return val != null;
  }
}
