// File: lib/services/firestore_service.dart
// UPDATED: Added logic to link two users together.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //--- User Management ---

  /// Creates a new user document in Firestore after registration.
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'partner_uid': null, // Partner UID is initially null
      'created_at': FieldValue.serverTimestamp(), // Uses the server's time
    });
  }

  /// **THE FIX IS HERE**: Links the current user with a partner in Firestore.
  /// This is a transaction to ensure both users are updated together.
  Future<void> linkPartners({
    required String currentUserId,
    required String partnerId,
  }) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final partnerRef = _db.collection('users').doc(partnerId);

    // Use a transaction to safely update both documents.
    await _db.runTransaction((transaction) async {
      final partnerDoc = await transaction.get(partnerRef);

      // Check if the partner ID actually exists in the database.
      if (!partnerDoc.exists) {
        throw Exception("Partner with this ID does not exist. Please check the ID and try again.");
      }

      // Update both the current user's and the partner's documents.
      transaction.update(currentUserRef, {'partner_uid': partnerId});
      transaction.update(partnerRef, {'partner_uid': currentUserId});
    });
  }
}
