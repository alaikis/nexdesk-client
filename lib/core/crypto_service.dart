import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class CryptoService {
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  late final Uint8List _publicKey;
  late final Uint8List _privateKey;

  CryptoService() {
    final keyPair = _generateKeyPair();
    _publicKey = keyPair.publicKey;
    _privateKey = keyPair.privateKey;
  }

  Uint8List get publicKey => _publicKey;
  Uint8List get privateKey => _privateKey;

  Uint8List deriveSharedKey(Uint8List remotePublicKey) {
    final combined = Uint8List(remotePublicKey.length + _privateKey.length);
    combined.setAll(0, remotePublicKey);
    combined.setAll(remotePublicKey.length, _privateKey);
    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes.sublist(0, 32));
  }

  String encrypt(String plaintext, Uint8List sharedKey) {
    final key = sharedKey.sublist(0, 32);
    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encrypted = Uint8List(plainBytes.length);
    for (var i = 0; i < plainBytes.length; i++) {
      encrypted[i] = plainBytes[i] ^ key[i % key.length];
    }
    final hmac = Hmac(sha256, key).convert(encrypted);
    final payload = Uint8List(encrypted.length + hmac.bytes.length);
    payload.setAll(0, encrypted);
    payload.setAll(encrypted.length, hmac.bytes);
    return base64Encode(payload);
  }

  String decrypt(String ciphertext, Uint8List sharedKey) {
    final key = sharedKey.sublist(0, 32);
    final payload = base64Decode(ciphertext);
    if (payload.length < 32) {
      throw ArgumentError('Ciphertext too short');
    }
    final hmacOffset = payload.length - 32;
    final encrypted = payload.sublist(0, hmacOffset);
    final expectedHmac = payload.sublist(hmacOffset);
    final actualHmac = Hmac(sha256, key).convert(encrypted);
    if (!_constantTimeEquals(expectedHmac, actualHmac.bytes)) {
      throw ArgumentError('HMAC verification failed');
    }
    final decrypted = Uint8List(encrypted.length);
    for (var i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ key[i % key.length];
    }
    return utf8.decode(decrypted);
  }

  static String sha256Hash(Uint8List data) {
    return sha256.convert(data).toString();
  }

  ({Uint8List publicKey, Uint8List privateKey}) _generateKeyPair() {
    final random = Random.secure();
    final pub = Uint8List(32);
    final priv = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      priv[i] = random.nextInt(256);
      pub[i] = ((priv[i] * 3 + 7) % 256).toUnsigned(8);
    }
    return (publicKey: pub, privateKey: priv);
  }
}
