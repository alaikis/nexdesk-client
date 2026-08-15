import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../core/storage_service.dart';

class DeviceFingerprintService {
  static const _storageKey = 'device_fingerprint';

  static Future<String> getFingerprint() async {
    final cached = await StorageService.getString(_storageKey);
    if (cached != null) return cached;

    final parts = <String>[];

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      parts.add(Platform.localHostname);
      parts.add(Platform.operatingSystem);
      parts.add(Platform.operatingSystemVersion);
    } else if (Platform.isAndroid) {
      parts.add(Platform.localHostname);
      parts.add(Platform.operatingSystem);
      parts.add(Platform.operatingSystemVersion);
    } else {
      parts.add(Platform.localHostname);
      parts.add(Platform.operatingSystem);
    }

    final raw = parts.join('|');
    final bytes = utf8.encode(raw);
    final hash = sha256.convert(bytes).toString().substring(0, 32);

    await StorageService.setString(_storageKey, hash);
    return hash;
  }

  static Future<void> clear() async {
    await StorageService.delete(_storageKey);
  }
}
