import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

class StorageService {
  static const _prefix = 'nex_';

  static Future<SharedPreferences> _prefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<String?> getString(String key) async {
    return (await _prefs()).getString(_prefix + key);
  }

  static Future<void> setString(String key, String value) async {
    await (await _prefs()).setString(_prefix + key, value);
  }

  static Future<Uint8List?> getBytes(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    return Uint8List.fromList(base64Decode(raw));
  }

  static Future<void> setBytes(String key, Uint8List value) async {
    await setString(key, base64Encode(value));
  }

  static Future<void> delete(String key) async {
    await (await _prefs()).remove(_prefix + key);
  }

  static Future<void> clear() async {
    final prefs = await _prefs();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<bool> has(String key) async {
    final val = await getString(key);
    return val != null;
  }

  static Future<List<String>> getStringList(String key) async {
    final raw = await getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await setString(key, jsonEncode(value));
  }
}
