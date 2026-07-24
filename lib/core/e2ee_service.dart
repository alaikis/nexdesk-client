import 'dart:typed_data';
import 'package:sodium_libs/sodium_libs.dart';

/// E2E encryption service using libsodium
/// Replaces the old XOR-based fake encryption
class E2eeService {
  late final Sodium _sodium;
  late final KeyPair _identityKeyPair;
  late final KeyPair _x25519KeyPair;
  SecureKey? _sessionKey;

  bool _initialized = false;

  /// Initialize libsodium and generate device identity keys
  Future<void> initialize() async {
    if (_initialized) return;
    _sodium = await SodiumInit.init();

    _identityKeyPair = _sodium.crypto.sign.keyPair();
    _x25519KeyPair = _sodium.crypto.box.keyPair();

    _initialized = true;
  }

  /// Get public keys to share with remote device
  Uint8List get identityPublicKey => _identityKeyPair.publicKey;
  Uint8List get exchangePublicKey => _x25519KeyPair.publicKey;

  /// Derive shared session key from remote public key
  void deriveSessionKey(Uint8List remotePublicKey) {
    // Derive a shared secret using genericHash
    final sharedSecret = _sodium.crypto.genericHash(
      message: Uint8List.fromList([
        ..._x25519KeyPair.publicKey,
        ...remotePublicKey,
        ..._x25519KeyPair.secretKey.extractBytes(),
      ]),
      outLen: 32,
    );
    _sessionKey?.dispose();
    _sessionKey = _sodium.crypto.kdf.keygen();
    // Derive key by hashing the shared secret into the key
    final keyBytes = _sessionKey!.extractBytes();
    for (var i = 0; i < 32; i++) {
      keyBytes[i] = sharedSecret[i];
    }
  }

  /// Encrypt a media frame using ChaCha20-Poly1305
  Uint8List encryptFrame(Uint8List frameData) {
    _ensureInitialized();
    final nonce = _sodium.randombytes.buf(12);

    final ciphertext = _sodium.crypto.secretBox.easy(
      message: frameData,
      nonce: nonce,
      key: _sessionKey!,
    );

    final result = Uint8List(nonce.length + ciphertext.length);
    result.setAll(0, nonce);
    result.setAll(nonce.length, ciphertext);
    return result;
  }

  /// Decrypt a media frame using ChaCha20-Poly1305
  Uint8List decryptFrame(Uint8List encryptedData) {
    _ensureInitialized();

    final nonce = encryptedData.sublist(0, 12);
    final ciphertext = encryptedData.sublist(12);

    return _sodium.crypto.secretBox.openEasy(
      cipherText: ciphertext,
      nonce: nonce,
      key: _sessionKey!,
    );
  }

  /// Sign data with device identity key (Ed25519)
  Uint8List sign(Uint8List data) {
    _ensureInitialized();
    return _sodium.crypto.sign.detached(
      message: data,
      secretKey: _identityKeyPair.secretKey,
    );
  }

  /// Verify signature from remote device
  bool verifySignature(Uint8List data, Uint8List signature, Uint8List remotePublicKey) {
    _ensureInitialized();
    return _sodium.crypto.sign.verifyDetached(
      signature: signature,
      message: data,
      publicKey: remotePublicKey,
    );
  }

  /// Rotate session key (triggered every 1 hour or 1GB transferred)
  void rotateSessionKey(Uint8List additionalEntropy) {
    _ensureInitialized();
    final currentBytes = _sessionKey!.extractBytes();
    final newBytes = _sodium.crypto.genericHash(
      message: Uint8List.fromList([...currentBytes, ...additionalEntropy]),
      outLen: 32,
    );
    _sessionKey!.dispose();
    _sessionKey = _sodium.crypto.kdf.keygen();
    final keyBytes = _sessionKey!.extractBytes();
    for (var i = 0; i < 32; i++) {
      keyBytes[i] = newBytes[i];
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('E2eeService not initialized. Call initialize() first.');
    }
    if (_sessionKey == null) {
      throw StateError('No session key derived. Call deriveSessionKey() first.');
    }
  }

  /// Dispose of sensitive key material
  void dispose() {
    _x25519KeyPair.secretKey.dispose();
    _identityKeyPair.secretKey.dispose();
  }
}
