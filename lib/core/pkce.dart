import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// 生成 PKCE code verifier 和 S256 code challenge (RFC 7636)
class Pkce {
  /// 随机 code_verifier (43-128 字符, 使用 URL-safe base64)
  static String generateCodeVerifier({int length = 64}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      buf.write(chars[rng.nextInt(chars.length)]);
    }
    return buf.toString();
  }

  /// S256: BASE64URL(SHA256(code_verifier))
  static String generateCodeChallenge(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// 生成随机 state (防 CSRF)
  static String generateState({int length = 32}) {
    final rng = Random.secure();
    final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// 生成随机 nonce (防重放)
  static String generateNonce({int length = 24}) {
    final rng = Random.secure();
    final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}