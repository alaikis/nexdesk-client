import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
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
    return res['otpauth_url'] as String?;
  }

  Future<bool> enableTOTP(String code) async {
    final res = await _api.post('/auth/2fa/enable', {'code': code});
    return res['ok'] == true;
  }

  Future<bool> disableTOTP(String code) async {
    final res = await _api.post('/auth/2fa/disable', {'code': code});
    return res['ok'] == true;
  }

  Future<bool> isEnabled() async {
    final res = await _api.get('/auth/2fa/status');
    return res['enabled'] == true;
  }

  static String generateOTP(String secret) {
    final bytes = Uint8List.fromList(utf8.encode(secret));
    final hash = sha256.convert(bytes);
    final code = hash.toString().substring(0, 6);
    return code;
  }
}
