import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';

class StorageService {
  static const _secure = FlutterSecureStorage();
  static const _prefix = 'nex_';

  static Future<String?> getString(String key) async {
    return await _secure.read(key: _prefix + key);
  }

  static Future<void> setString(String key, String value) async {
    await _secure.write(key: _prefix + key, value: value);
  }

  static Future<Uint8List?> getBytes(String key) async {
    final raw = await _secure.read(key: _prefix + key);
    if (raw == null) return null;
    return Uint8List.fromList(base64Decode(raw));
  }

  static Future<void> setBytes(String key, Uint8List value) async {
    await _secure.write(key: _prefix + key, value: base64Encode(value));
  }

  static Future<void> delete(String key) async {
    await _secure.delete(key: _prefix + key);
  }

  static Future<void> clear() async {
    await _secure.deleteAll();
  }

  static Future<bool> has(String key) async {
    final val = await _secure.read(key: _prefix + key);
    return val != null;
  }

  static Future<List<String>> getStringList(String key) async {
    final raw = await _secure.read(key: _prefix + key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _secure.write(key: _prefix + key, value: jsonEncode(value));
  }
}
