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

  /// Derive shared session key from remote public key using X25519 DH
  void deriveSessionKey(Uint8List remotePublicKey) {
    // Use X25519 Diffie-Hellman to derive a shared secret
    final sharedSecret = _sodium.crypto.box.beforenm(
      publicKey: remotePublicKey,
      secretKey: _x25519KeyPair.secretKey,
    );
    _sessionKey?.dispose();
    // Derive a proper session key from the shared secret using KDF
    _sessionKey = _sodium.crypto.kdf.deriveFromKey(
      subKeyId: 1,
      context: "e2ee00",
      masterKey: sharedSecret,
    );
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
    final currentKey = _sessionKey!;
    final newKey = _sodium.crypto.kdf.deriveFromKey(
      subKeyId: DateTime.now().millisecondsSinceEpoch ~/ 3600000, // hour-based rotation
      context: "e2ee01",
      masterKey: currentKey,
    );
    currentKey.dispose();
    _sessionKey = newKey;
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
