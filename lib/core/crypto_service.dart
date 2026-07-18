import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class CryptoService {
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
    return base64Encode(encrypted);
  }

  String decrypt(String ciphertext, Uint8List sharedKey) {
    final key = sharedKey.sublist(0, 32);
    final encrypted = base64Decode(ciphertext);
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
    final pub = <int>[];
    final priv = <int>[];
    for (var i = 0; i < 32; i++) {
      priv.add((DateTime.now().microsecondsSinceEpoch % 256).toUnsigned(8));
      pub.add((priv[i] * 3 + 7) % 256);
    }
    return (publicKey: Uint8List.fromList(pub), privateKey: Uint8List.fromList(priv));
  }
}
