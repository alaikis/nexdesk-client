import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/crypto_service.dart';

void main() {
  group('CryptoService', () {
    test('generates unique keys on each instantiation', () {
      final a = CryptoService();
      final b = CryptoService();
      expect(a.publicKey, isNot(b.publicKey));
      expect(a.privateKey, isNot(b.privateKey));
    });

    test('keys are 32 bytes', () {
      final service = CryptoService();
      expect(service.publicKey.length, 32);
      expect(service.privateKey.length, 32);
    });

    test('encrypt/decrypt round-trip for random payloads', () {
      final service = CryptoService();
      final sharedKey = service.deriveSharedKey(Uint8List.fromList(List.generate(32, (i) => i)));
      const message = 'Hello, NEX secure channel!';
      final encrypted = service.encrypt(message, sharedKey);
      final decrypted = service.decrypt(encrypted, sharedKey);
      expect(decrypted, message);
    });

    test('decrypt fails when ciphertext is modified', () {
      final service = CryptoService();
      final sharedKey = service.deriveSharedKey(Uint8List.fromList(List.generate(32, (i) => i)));
      final encrypted = service.encrypt('secret payload', sharedKey);
      final payload = base64Decode(encrypted);
      payload[10] ^= 0xFF;
      final tampered = base64Encode(payload);
      expect(() => service.decrypt(tampered, sharedKey), throwsArgumentError);
    });

    test('decrypt fails when ciphertext is too short', () {
      final service = CryptoService();
      final sharedKey = Uint8List(32);
      expect(() => service.decrypt('', sharedKey), throwsArgumentError);
    });

    test('deriveSharedKey is deterministic for same input', () {
      final service = CryptoService();
      final remote = Uint8List.fromList(List.generate(32, (i) => i * 7));
      final a = service.deriveSharedKey(remote);
      final b = service.deriveSharedKey(remote);
      expect(a, b);
    });

    test('sha256Hash returns hex string', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final hash = CryptoService.sha256Hash(data);
      expect(hash, isA<String>());
      expect(hash.length, 64);
    });
  });
}
