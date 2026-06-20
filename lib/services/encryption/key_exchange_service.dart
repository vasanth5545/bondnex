import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cryptography/cryptography.dart';
import 'package:bondnex/services/encryption/encryption_service.dart';

class KeyExchangeService {
  static final KeyExchangeService _instance = KeyExchangeService._internal();
  factory KeyExchangeService() => _instance;

  KeyExchangeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Publish the current user's public key to Firestore
  Future<void> publishPublicKey() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final encryptionService = EncryptionService();
    String? pubKey = await encryptionService.getPublicKeyBase64();
    
    // If we don't have keys generated, generate them now
    if (pubKey == null) {
      await encryptionService.generateAndStoreKeyPair();
      pubKey = await encryptionService.getPublicKeyBase64();
    }

    if (pubKey != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'publicKey': pubKey,
      }, SetOptions(merge: true));
    }
  }

  /// Get partner's public key from Firestore and derive the shared secret
  Future<SecretKey?> derivePartnerSharedSecret(String partnerUid) async {
    final doc = await _firestore.collection('users').doc(partnerUid).get();
    
    if (!doc.exists) {
      throw Exception('Partner document not found.');
    }

    final partnerData = doc.data();
    final partnerPubKey = partnerData?['publicKey'] as String?;

    if (partnerPubKey == null) {
      throw Exception('Partner public key not found. They must open the app to generate one.');
    }

    final encryptionService = EncryptionService();
    final sharedSecret = await encryptionService.deriveSharedSecret(partnerPubKey);
    
    if (sharedSecret == null) {
      throw Exception('Failed to derive shared secret.');
    }

    return sharedSecret;
  }
}
