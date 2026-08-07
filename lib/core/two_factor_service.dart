import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'api_client.dart';

class TwoFactorService {
  static final TwoFactorService _instance = TwoFactorService._internal();
  factory TwoFactorService() => _instance;
  TwoFactorService._internal();

  final ApiClient _api = ApiClient();

  Future<String?> setupTOTP() async {
    final res = await _api.post('/auth/2fa/setup', {});
    return res['secret'] as String?;
  }

  Future<String?> getOtpAuthUrl() async {
    final res = await _api.post('/auth/2fa/setup', {});
    return res['key'] as String? ?? res['otpauth_url'] as String?;
  }

  Future<bool> enableTOTP() async {
    final res = await _api.post('/auth/2fa/enable', {});
    return res['enabled'] == true || res['ok'] == true;
  }

  Future<bool> disableTOTP() async {
    final res = await _api.post('/auth/2fa/disable', {});
    return res['ok'] == true;
  }

  Future<bool> isEnabled() async {
    final res = await _api.get('/auth/2fa/status');
    return res['enabled'] == true;
  }

  /// Generate TOTP code using HMAC-SHA1 (RFC 6238)
  static String generateOTP(String secret, {int? timestamp}) {
    try {
      // Decode base32 secret
      final key = _base32Decode(secret);

      // Time counter (30-second intervals)
      final time = (timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 30;
      final timeBytes = _int64ToBytes(time);

      // HMAC-SHA1
      final hmac = Hmac(sha1, key);
      final hash = hmac.convert(timeBytes).bytes;

      // Dynamic truncation
      final offset = hash[hash.length - 1] & 0x0F;
      final binary = ((hash[offset] & 0x7F) << 24) |
          ((hash[offset + 1] & 0xFF) << 16) |
          ((hash[offset + 2] & 0xFF) << 8) |
          (hash[offset + 3] & 0xFF);

      final otp = binary % 1000000;
      return otp.toString().padLeft(6, '0');
    } catch (e) {
      return '000000';
    }
  }

  /// Verify a TOTP code (with 30-second window tolerance)
  static bool verifyOTP(String secret, String code, {int windowSize = 1}) {
    final current = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (int i = -windowSize; i <= windowSize; i++) {
      final expected = generateOTP(secret, timestamp: current + i * 30);
      if (expected == code) return true;
    }
    return false;
  }

  /// Base32 decode (RFC 4648)
  static Uint8List _base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final clean = input.toUpperCase().replaceAll('=', '').replaceAll(' ', '');

    final bits = StringBuffer();
    for (final char in clean.codeUnits) {
      final idx = alphabet.indexOf(String.fromCharCode(char));
      if (idx >= 0) {
        bits.write(idx.toRadixString(2).padLeft(5, '0'));
      }
    }

    final bytes = <int>[];
    for (int i = 0; i + 8 <= bits.length; i += 8) {
      final byte = int.parse(bits.toString().substring(i, i + 8), radix: 2);
      bytes.add(byte);
    }

    return Uint8List.fromList(bytes);
  }

  static Uint8List _int64ToBytes(int value) {
    final bytes = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xFF;
      value >>= 8;
    }
    return bytes;
  }
}
