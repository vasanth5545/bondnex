// File: lib/services/firestore_service.dart
// UPDATED: Added function to log calls to a `call_history` collection.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //--- User Management ---

  /// Creates a new user document in Firestore after registration.
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String gender,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'gender': gender, // Storing the gender in Firestore.
      'partner_uid': null,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Links the current user with a partner in Firestore.
  Future<void> linkPartners({
    required String currentUserId,
    required String partnerId,
  }) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final partnerRef = _db.collection('users').doc(partnerId);

    await _db.runTransaction((transaction) async {
      final partnerDoc = await transaction.get(partnerRef);

      if (!partnerDoc.exists) {
        throw Exception("Partner with this ID does not exist. Please check the ID and try again.");
      }

      transaction.update(currentUserRef, {'partner_uid': partnerId});
      transaction.update(partnerRef, {'partner_uid': currentUserId});
    });
  }

  //--- Call History ---

  /// Adds a new call record to the call history.
  Future<void> addCallToHistory({
    required String callerUid,
    required String receiverUid,
    required String callType,
    required String callMode,
    required String status,
    required double duration,
  }) async {
    await _db.collection('call_history').add({
      'caller_uid': callerUid,
      'receiver_uid': receiverUid,
      'call_type': callType,
      'call_mode': callMode,
      'status': status,
      'duration': duration,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
