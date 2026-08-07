import 'dart:typed_data';
import 'package:sodium_libs/sodium_libs.dart';

class E2eeService {
  late final Sodium _sodium;
  late final SecureKey _secretKey;
  late final Uint8List _publicKey;
  PrecalculatedBox? _sessionBox;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _sodium = await SodiumInit.init();
    final keyPair = _sodium.crypto.box.keyPair();
    _secretKey = keyPair.secretKey;
    _publicKey = Uint8List.fromList(keyPair.publicKey);
    _initialized = true;
  }

  Uint8List get publicKey => Uint8List.fromList(_publicKey);

  void deriveSessionKey(Uint8List remotePublicKey) {
    _ensureInitialized();
    _sessionBox?.dispose();
    _sessionBox = _sodium.crypto.box.precalculate(
      publicKey: remotePublicKey,
      secretKey: _secretKey,
    );
  }

  Uint8List encryptFrame(Uint8List frameData) {
    _ensureInitialized();
    if (_sessionBox == null) throw StateError('Session key not derived');
    final nonce = _sodium.randombytes.buf(12);
    final ciphertext = _sessionBox!.easy(
      message: frameData,
      nonce: nonce,
    );
    final result = Uint8List(nonce.length + ciphertext.length);
    result.setAll(0, nonce);
    result.setAll(nonce.length, ciphertext);
    return result;
  }

  Uint8List decryptFrame(Uint8List encryptedData) {
    _ensureInitialized();
    if (_sessionBox == null) throw StateError('Session key not derived');
    final nonce = encryptedData.sublist(0, 12);
    final ciphertext = encryptedData.sublist(12);
    return _sessionBox!.openEasy(
      cipherText: ciphertext,
      nonce: nonce,
    );
  }

  void rotateSessionKey(Uint8List additionalEntropy) {
    _ensureInitialized();
    final newKeyBytes = _sodium.crypto.genericHash(
      message: additionalEntropy,
      outLen: 32,
    );
    _sessionBox?.dispose();
    _sessionBox = _sodium.crypto.box.precalculate(
      publicKey: _publicKey,
      secretKey: SecureKey.fromList(_sodium, newKeyBytes),
    );
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('E2eeService not initialized. Call initialize() first.');
    }
  }

  void dispose() {
    _sessionBox?.dispose();
    _secretKey.dispose();
  }
}
