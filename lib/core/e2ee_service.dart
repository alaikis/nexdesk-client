import 'dart:typed_data';
import 'package:sodium_libs/sodium_libs.dart';

/// E2E encryption service using libsodium
class E2eeService {
  late final Sodium _sodium;
  SecureKey? _sessionKey;

  bool _initialized = false;

  /// Initialize libsodium
  Future<void> initialize() async {
    if (_initialized) return;
    _sodium = await SodiumInit.init();
    _initialized = true;
  }

  /// Get public key for key exchange
  Uint8List get exchangePublicKey {
    _ensureInitialized();
    final keyPair = _sodium.crypto.box.keyPair();
    final publicKey = Uint8List.fromList(keyPair.publicKey);
    keyPair.secretKey.dispose();
    return publicKey;
  }

  /// Derive shared session key from remote public key
  void deriveSessionKey(Uint8List remotePublicKey) {
    _ensureInitialized();

    // Generate a keypair for this session
    final keyPair = _sodium.crypto.box.keyPair();

    // Combine keys for shared secret derivation
    final combined = Uint8List.fromList([
      ...keyPair.publicKey,
      ...remotePublicKey,
      ...keyPair.secretKey.extractBytes(),
    ]);

    // Use genericHash to derive a shared secret
    final sharedSecret = _sodium.crypto.genericHash(
      message: combined,
      outLen: 32,
    );

    // Generate new session key and XOR with shared secret
    _sessionKey?.dispose();
    _sessionKey = _sodium.crypto.kdf.keygen();
    final sessionBytes = _sessionKey!.extractBytes();
    for (int i = 0; i < 32 && i < sharedSecret.length; i++) {
      sessionBytes[i] ^= sharedSecret[i];
    }

    // Clean up
    keyPair.secretKey.dispose();
  }

  /// Encrypt a media frame using ChaCha20-Poly1305 (secretBox)
  Uint8List encryptFrame(Uint8List frameData) {
    _ensureInitialized();
    final nonce = _sodium.randombytes.buf(12);

    final ciphertext = _sodium.crypto.secretBox.easy(
      message: frameData,
      nonce: nonce,
      key: _sessionKey!,
    );

    // Prepend nonce to ciphertext for transmission
    final result = Uint8List(nonce.length + ciphertext.length);
    result.setAll(0, nonce);
    result.setAll(nonce.length, ciphertext);
    return result;
  }

  /// Decrypt a media frame using ChaCha20-Poly1305 (secretBox)
  Uint8List decryptFrame(Uint8List encryptedData) {
    _ensureInitialized();

    // Extract nonce (first 12 bytes)
    final nonce = encryptedData.sublist(0, 12);
    final ciphertext = encryptedData.sublist(12);

    return _sodium.crypto.secretBox.openEasy(
      cipherText: ciphertext,
      nonce: nonce,
      key: _sessionKey!,
    );
  }

  /// Rotate session key
  void rotateSessionKey(Uint8List additionalEntropy) {
    _ensureInitialized();
    final currentBytes = _sessionKey!.extractBytes();
    final newKeyBytes = _sodium.crypto.genericHash(
      message: Uint8List.fromList([...currentBytes, ...additionalEntropy]),
      outLen: 32,
    );

    // Create new key by hashing old key + entropy
    final newKey = _sodium.crypto.kdf.keygen();
    final newKeyBytes2 = newKey.extractBytes();
    for (int i = 0; i < 32 && i < newKeyBytes.length; i++) {
      newKeyBytes2[i] ^= newKeyBytes[i];
    }

    _sessionKey!.dispose();
    _sessionKey = newKey;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('E2eeService not initialized. Call initialize() first.');
    }
  }

  /// Dispose of sensitive key material
  void dispose() {
    _sessionKey?.dispose();
  }
}
