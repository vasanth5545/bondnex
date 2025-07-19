// File: lib/services/firestore_service.dart
// UPDATED: Added logic to generate and use a user-friendly "Premium ID".

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // **THE FIX IS HERE**: Helper function to generate the random Premium ID.
  String _generatePremiumId() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';

    final randomChars = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final randomDigits = String.fromCharCodes(Iterable.generate(
        4, (_) => digits.codeUnitAt(random.nextInt(digits.length))));

    return 'BNX-$randomChars-$randomDigits';
  }

  //--- User Management ---
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String gender,
  }) async {
    // **THE FIX IS HERE**: Generate and save the Premium ID for the new user.
    final premiumId = _generatePremiumId();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'premium_id': premiumId, // The new user-facing ID
      'name': name,
      'email': email,
      'gender': gender,
      'partner_uid': null,
      'created_at': FieldValue.serverTimestamp(),
      'profile_image_url': '',
    });
  }

  Future<DocumentSnapshot> getUserData(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  // **THE FIX IS HERE**: New function to find a user's raw UID from their Premium ID.
  Future<String?> getUidByPremiumId(String premiumId) async {
    final querySnapshot = await _db
        .collection('users')
        .where('premium_id', isEqualTo: premiumId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  Future<void> updateUserName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({'name': newName});
  }

  Future<void> linkPartners({
    required String currentUserId,
    required String partnerId,
  }) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final partnerRef = _db.collection('users').doc(partnerId);

    await _db.runTransaction((transaction) async {
      final partnerDoc = await transaction.get(partnerRef);
      if (!partnerDoc.exists) {
        throw Exception("Partner with this ID does not exist.");
      }
      transaction.update(currentUserRef, {'partner_uid': partnerId});
      transaction.update(partnerRef, {'partner_uid': currentUserId});
    });
  }

  Future<void> disconnectPartner({
    required String currentUserId,
    required String partnerId,
  }) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final partnerRef = _db.collection('users').doc(partnerId);

    await _db.runTransaction((transaction) async {
      transaction.update(currentUserRef, {'partner_uid': null});
      transaction.update(partnerRef, {'partner_uid': null});
    });
  }


  //--- Love Request Management ---
  Future<void> sendLoveRequest({
    required String senderUid,
    required String receiverUid,
    required String senderName,
    required String senderProfileImageUrl,
  }) async {
    final existingRequest = await _db
        .collection('love_requests')
        .where('sender_uid', isEqualTo: senderUid)
        .where('receiver_uid', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception("You have already sent a request to this user.");
    }

    await _db.collection('love_requests').add({
      'sender_uid': senderUid,
      'receiver_uid': receiverUid,
      'sender_name': senderName,
      'sender_profile_image_url': senderProfileImageUrl,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getLoveRequests(String userId) {
    return _db
        .collection('love_requests')
        .where('receiver_uid', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> updateLoveRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _db.collection('love_requests').doc(requestId).update({
      'status': status,
    });
  }
}
