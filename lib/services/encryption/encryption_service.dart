import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;

  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final X25519 _keyExchangeAlgorithm = X25519();
  
  static const String _privateKeyKey = 'bondnex_private_key';
  static const String _publicKeyKey = 'bondnex_public_key';
  
  SimpleKeyPair? _currentKeyPair;

  /// Generate a new ECDH KeyPair (X25519) and save it securely.
  Future<void> generateAndStoreKeyPair() async {
    final keyPair = await _keyExchangeAlgorithm.newKeyPair();
    _currentKeyPair = keyPair;

    // Extract private key bytes
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    // Store private key securely
    await _secureStorage.write(
      key: _privateKeyKey, 
      value: base64Encode(privateKeyBytes)
    );

    // Store public key in standard preferences (not strictly needed to be secure, but good to cache)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_publicKeyKey, base64Encode(publicKeyBytes));
  }

  /// Get the current public key as a base64 string
  Future<String?> getPublicKeyBase64() async {
    final prefs = await SharedPreferences.getInstance();
    String? pubKey = prefs.getString(_publicKeyKey);
    
    if (pubKey == null) {
      // If not in prefs but we have keys generated, try to rebuild it
      final keyPair = await _getKeyPair();
      if (keyPair != null) {
        final publicKey = await keyPair.extractPublicKey();
        pubKey = base64Encode(publicKey.bytes);
        await prefs.setString(_publicKeyKey, pubKey);
      }
    }
    return pubKey;
  }

  /// Internal: Reconstruct SimpleKeyPair from secure storage
  Future<SimpleKeyPair?> _getKeyPair() async {
    if (_currentKeyPair != null) return _currentKeyPair;

    final privateKeyBase64 = await _secureStorage.read(key: _privateKeyKey);
    if (privateKeyBase64 == null) return null;

    final privateKeyBytes = base64Decode(privateKeyBase64);
    _currentKeyPair = await _keyExchangeAlgorithm.newKeyPairFromSeed(privateKeyBytes);
    return _currentKeyPair;
  }

  /// Clear keys (e.g., on logout or account deletion)
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _privateKeyKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_publicKeyKey);
    _currentKeyPair = null;
  }

  /// Derive shared secret using HKDF
  Future<SecretKey?> deriveSharedSecret(String peerPublicKeyBase64) async {
    final keyPair = await _getKeyPair();
    if (keyPair == null) return null;

    final peerPublicKeyBytes = base64Decode(peerPublicKeyBase64);
    final peerPublicKey = SimplePublicKey(peerPublicKeyBytes, type: KeyPairType.x25519);

    final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: peerPublicKey,
    );

    // Pass through HKDF for cryptographic strength
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );

    final derivedKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('bondnex_e2ee_salt'), // Fixed salt for both ends
    );

    return derivedKey;
  }
}
