// File: lib/services/firestore_service.dart
// UPDATED: Added 'status' field and a method to update it.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../phone/call_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // --- User Management ---
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String gender,
  }) async {
    final premiumId = _generatePremiumId();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'premium_id': premiumId,
      'name': name,
      'email': email,
      'gender': gender,
      'partner_uid': null,
      'created_at': FieldValue.serverTimestamp(),
      'profile_image_url': '',
      'banner_image_url': '',
      'bio': 'Add your bio here!',
      'link': '',
      'signature': 'Broken hero',
      'status': "what's up?", // Puthu field
      'callLogSharingEnabled': true,
    });
  }

  Future<DocumentSnapshot> getUserData(String userId) {
    return _db.collection('users').doc(userId).get();
  }

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
  
  Future<void> updateUserBio(String uid, String newBio) async {
    await _db.collection('users').doc(uid).update({'bio': newBio});
  }

  Future<void> updateUserLink(String uid, String newLink) async {
    await _db.collection('users').doc(uid).update({'link': newLink});
  }

  Future<void> updateUserGender(String uid, String newGender) async {
    await _db.collection('users').doc(uid).update({'gender': newGender});
  }
  
  Future<void> updateUserSignature(String uid, String newSignature) async {
    await _db.collection('users').doc(uid).update({'signature': newSignature});
  }

  // Puthu function
  Future<void> updateUserStatus(String uid, String newStatus) async {
    await _db.collection('users').doc(uid).update({'status': newStatus});
  }

  Future<void> updateUserProfilePhotoUrl(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).update({'profile_image_url': photoUrl});
  }

  Future<void> updateUserBannerPhotoUrl(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).update({'banner_image_url': photoUrl});
  }

  Future<void> logPhotoUpdate(String uid, String userName) async {
    await _db.collection('admin_logs').add({
      'userId': uid,
      'userName': userName,
      'action': 'Profile photo updated',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCallLogSharing(String uid, bool enabled) async {
    await _db.collection('users').doc(uid).update({'callLogSharingEnabled': enabled});
  }

  Future<void> linkPartners({
    required String currentUserId,
    required String partnerId,
  }) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final partnerRef = _db.collection('users').doc(partnerId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot partnerDoc = await transaction.get(partnerRef);
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

  // --- Love Request Management ---
  Future<void> sendLoveRequest({
    required String senderUid,
    required String receiverUid,
    required String senderName,
    required String senderProfileImageUrl,
  }) async {
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

  // --- Call Log Management ---
  Future<void> uploadCallLogs(String userId, List<CallLogEntry> logs) async {
    final userCallLogCollection = _db.collection('users').doc(userId).collection('call_logs');
    final WriteBatch batch = _db.batch();

    for (final log in logs) {
      final docRef = userCallLogCollection.doc(log.id);
      batch.set(docRef, log.toFirestore());
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> getPartnerCallLogs(String partnerId) {
    return _db
        .collection('users')
        .doc(partnerId)
        .collection('call_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPartnerCallLogsForNumber(String partnerId, String number) {
    return _db
        .collection('users')
        .doc(partnerId)
        .collection('call_logs')
        .where('contactNumber', isEqualTo: number)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
