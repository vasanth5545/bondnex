import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:bondnex/services/encryption/key_exchange_service.dart';

class AesEncryptionService {
  static final AesEncryptionService _instance = AesEncryptionService._internal();
  factory AesEncryptionService() => _instance;

  AesEncryptionService._internal();

  final AesGcm _aesGcm = AesGcm.with256bits();

  /// Helper to get the derived shared secret for a specific partner
  Future<SecretKey> _getSharedSecret(String partnerUid) async {
    final keyExchangeService = KeyExchangeService();
    // In a production app, you'd want to cache this SecretKey in memory 
    // rather than deriving it on every single message/call log to save CPU.
    final secretKey = await keyExchangeService.derivePartnerSharedSecret(partnerUid);
    if (secretKey == null) {
      throw Exception('Could not derive shared secret for partner $partnerUid');
    }
    return secretKey;
  }

  /// Encrypts plaintext using AES-256-GCM. 
  /// Returns a Base64 string containing the concatenated nonce, ciphertext, and mac.
  Future<String> encrypt(String plaintext, String partnerUid) async {
    final secretKey = await _getSharedSecret(partnerUid);
    final clearTextBytes = utf8.encode(plaintext);

    final secretBox = await _aesGcm.encrypt(
      clearTextBytes,
      secretKey: secretKey,
    );

    // Combine nonce, mac, and ciphertext into a single byte array
    // SecretBox structure: nonce + ciphertext + mac (if mac is appended by default in SecretBox, 
    // we need to be explicit to ensure cross-platform compatibility)
    final combined = <int>[
      ...secretBox.nonce,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ];

    return base64Encode(combined);
  }

  /// Decrypts a Base64 payload (nonce + mac + ciphertext) back to plaintext.
  Future<String> decrypt(String encryptedPayloadBase64, String partnerUid) async {
    final secretKey = await _getSharedSecret(partnerUid);
    final combinedBytes = base64Decode(encryptedPayloadBase64);

    // Standard AES-GCM nonces are 12 bytes
    const nonceLength = 12;
    // Standard AES-GCM MACs are 16 bytes
    const macLength = 16;

    if (combinedBytes.length < nonceLength + macLength) {
      throw Exception('Invalid encrypted payload: too short');
    }

    final nonce = combinedBytes.sublist(0, nonceLength);
    final macBytes = combinedBytes.sublist(nonceLength, nonceLength + macLength);
    final cipherText = combinedBytes.sublist(nonceLength + macLength);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearTextBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(clearTextBytes);
  }
}
