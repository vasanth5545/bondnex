import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  /// Generates a consistent 32-byte AES key based on the two UIDs.
  /// By sorting the UIDs, we ensure that both users generate the exact same key.
  static encrypt.Key _generateKey(String uid1, String uid2) {
    // Sort UIDs so that user A and user B always get the same combination string
    final uids = [uid1, uid2]..sort();
    final combinedString = "${uids[0]}_${uids[1]}_bondnex_secret_salt_2026";

    // Hash the combined string with SHA-256 to get exactly 32 bytes (256 bits)
    final bytes = utf8.encode(combinedString);
    final digest = sha256.convert(bytes);

    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts the payload string using AES.
  static String encryptData(String payload, String currentUid, String partnerUid) {
    if (payload.isEmpty) return "";
    
    final key = _generateKey(currentUid, partnerUid);
    final iv = encrypt.IV.fromLength(16); // Initialization vector
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(payload, iv: iv);
    
    // We store the IV along with the ciphertext, separated by a colon, so we can decrypt it later
    return "${iv.base64}:${encrypted.base64}";
  }

  /// Decrypts the payload string using AES.
  static String decryptData(String encryptedPayload, String currentUid, String partnerUid) {
    if (encryptedPayload.isEmpty || !encryptedPayload.contains(':')) return "";
    
    try {
      final parts = encryptedPayload.split(':');
      final iv = encrypt.IV.fromBase64(parts[0]);
      final ciphertext = parts[1];
      
      final key = _generateKey(currentUid, partnerUid);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final decrypted = encrypter.decrypt64(ciphertext, iv: iv);
      return decrypted;
    } catch (e) {
      debugPrint("Decryption failed: \$e");
      return "";
    }
  }
}
