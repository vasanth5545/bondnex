// File: lib/services/firestore_service.dart
// UPDATED: Custom Document IDs with [UserName]_[PremiumUID] format.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import '../../models/call_log_model.dart';
import '../security/encryption_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _generatePremiumId() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';

    final randomChars = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    final randomDigits = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => digits.codeUnitAt(random.nextInt(digits.length)),
      ),
    );

    return 'BNX-$randomChars-$randomDigits';
  }

  // --- Utility to Get User Document ID by Auth UID ---
  Future<String> _getUserDocId(String uid) async {
    final querySnapshot = await _db
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    // Fallback for older users or if document isn't found with the query.
    return uid;
  }

  // --- User Management ---
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String gender,
  }) async {
    final premiumId = _generatePremiumId();
    final String cleanName = name.trim().replaceAll(' ', '_');
    final String docId = '${cleanName}_$premiumId';

    await _db.collection('users').doc(docId).set({
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
      'gallery_images': [],
      'friends': [],
      'liked_by': [],
    });
  }

  Future<DocumentSnapshot> getUserData(String userId) async {
    final docId = await _getUserDocId(userId);
    return _db.collection('users').doc(docId).get();
  }

  Future<String?> getUidByPremiumId(String premiumId) async {
    final querySnapshot = await _db
        .collection('users')
        .where('premium_id', isEqualTo: premiumId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Return Auth UID, not document ID, because the app expects Auth UID everywhere
      return querySnapshot.docs.first.data()['uid'] as String?;
    }
    return null;
  }

  Future<void> updateUserName(String uid, String newName) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({'name': newName});
  }

  Future<void> updateUserBio(String uid, String newBio) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({'bio': newBio});
  }

  Future<void> updateUserLink(String uid, String newLink) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({'link': newLink});
  }

  Future<void> updateUserGender(String uid, String newGender) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({'gender': newGender});
  }

  Future<void> updateUserSignature(String uid, String newSignature) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({
      'signature': newSignature,
    });
  }

  Future<void> updateUserStatus(String uid, String newStatus) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({'status': newStatus});
  }

  Future<void> updateUserProfilePhotoUrl(String uid, String photoUrl) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({
      'profile_image_url': photoUrl,
    });
  }

  Future<void> updateUserBannerPhotoUrl(String uid, String photoUrl) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({
      'banner_image_url': photoUrl,
    });
  }

  Future<void> addUserGalleryPhotoUrl(String uid, String photoUrl) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({
      'gallery_images': FieldValue.arrayUnion([photoUrl]),
    });
  }

  Future<void> logPhotoUpdate(String uid, String userName) async {
    final docId = await _getUserDocId(uid);
    final logId = '${docId}_${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('admin_logs').doc(logId).set({
      'userId': uid,
      'userName': userName,
      'action': 'Profile photo updated',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCallLogSharing(String uid, bool enabled) async {
    final docId = await _getUserDocId(uid);
    await _db.collection('users').doc(docId).update({
      'callLogSharingEnabled': enabled,
    });
  }

  Future<void> linkPartners({
    required String currentUserId,
    required String partnerId,
  }) async {
    final currentUserDocId = await _getUserDocId(currentUserId);
    final partnerDocId = await _getUserDocId(partnerId);

    final currentUserRef = _db.collection('users').doc(currentUserDocId);
    final partnerRef = _db.collection('users').doc(partnerDocId);

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
    final currentUserDocId = await _getUserDocId(currentUserId);
    final partnerDocId = await _getUserDocId(partnerId);

    final currentUserRef = _db.collection('users').doc(currentUserDocId);
    final partnerRef = _db.collection('users').doc(partnerDocId);

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
    final senderDocId = await _getUserDocId(senderUid);
    final receiverDocId = await _getUserDocId(receiverUid);
    final docId = '${senderDocId}_$receiverDocId';
    await _db.collection('love_requests').doc(docId).set({
      'sender_uid': senderUid,
      'receiver_uid': receiverUid,
      'sender_name': senderName,
      'sender_profile_image_url': senderProfileImageUrl,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'request_count': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getLoveRequests(String userId) {
    return _db
        .collection('love_requests')
        .where('receiver_uid', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getSentLoveRequests(String userId) {
    return _db
        .collection('love_requests')
        .where('sender_uid', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> cancelLoveRequest(String requestId) async {
    await _db.collection('love_requests').doc(requestId).delete();
  }

  Future<void> updateLoveRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _db.collection('love_requests').doc(requestId).update({
      'status': status,
    });
  }

  Future<void> deleteAllOtherPendingRequests(
    String receiverUid,
    String acceptedRequestId,
  ) async {
    final querySnapshot = await _db
        .collection('love_requests')
        .where('receiver_uid', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'pending')
        .get();

    final WriteBatch batch = _db.batch();
    for (var doc in querySnapshot.docs) {
      if (doc.id != acceptedRequestId) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<void> deleteAllSentPendingRequests(String senderUid) async {
    final querySnapshot = await _db
        .collection('love_requests')
        .where('sender_uid', isEqualTo: senderUid)
        .where('status', isEqualTo: 'pending')
        .get();

    final WriteBatch batch = _db.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Call Log Management ---
  Future<void> uploadCallLogs(String userId, List<CallLogEntry> logs) async {
    final docId = await _getUserDocId(userId);
    final userDoc = await _db.collection('users').doc(docId).get();
    if (!userDoc.exists) return;

    final partnerUid = userDoc.data()?['partner_uid'] as String?;
    if (partnerUid == null || partnerUid.isEmpty) {
      // If no partner, clean up logs and don't upload
      await _db.collection('users').doc(docId).update({
        'encrypted_call_logs': FieldValue.delete(),
        'latest_call_logs': FieldValue.delete(),
      });
      await _db
          .collection('users')
          .doc(docId)
          .collection('call_logs')
          .doc('history')
          .delete();
      return;
    }

    final serializedLogs = logs.map((log) => log.toFirestore()).toList();
    final jsonString = jsonEncode(serializedLogs);
    final encryptedString = EncryptionService.encryptData(
      jsonString,
      userId,
      partnerUid,
    );

    // Save in the call_logs subcollection instead of the main user document
    await _db
        .collection('users')
        .doc(docId)
        .collection('call_logs')
        .doc('history')
        .set({
          'encrypted_call_logs': encryptedString,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Cleanup the old fields from the main document to avoid clutter
    try {
      await _db.collection('users').doc(docId).update({
        'encrypted_call_logs': FieldValue.delete(),
        'latest_call_logs': FieldValue.delete(),
      });
    } catch (e) {
      // Fields might already be deleted, ignore
    }
  }

  Stream<DocumentSnapshot> getPartnerCallLogs(String partnerId) async* {
    final docId = await _getUserDocId(partnerId);
    yield* _db
        .collection('users')
        .doc(docId)
        .collection('call_logs')
        .doc('history')
        .snapshots();
  }

  // --- Likes Management ---
  Future<void> toggleLike({
    required String targetUid,
    required String currentUid,
    required bool isLiked,
  }) async {
    final docId = await _getUserDocId(targetUid);
    final userRef = _db.collection('users').doc(docId);
    if (isLiked) {
      await userRef.update({
        'liked_by': FieldValue.arrayUnion([currentUid]),
      });
    } else {
      await userRef.update({
        'liked_by': FieldValue.arrayRemove([currentUid]),
      });
    }
  }

  // --- Friends Management ---
  Future<void> acceptFriendRequest({
    required String currentUid,
    required String friendUid,
  }) async {
    final currentDocId = await _getUserDocId(currentUid);
    final friendDocId = await _getUserDocId(friendUid);

    // Add to each other's friends list
    final currentUserRef = _db.collection('users').doc(currentDocId);
    final friendRef = _db.collection('users').doc(friendDocId);

    await _db.runTransaction((transaction) async {
      transaction.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([friendUid]),
      });
      transaction.update(friendRef, {
        'friends': FieldValue.arrayUnion([currentUid]),
      });
    });
  }

  Future<void> removeFriend({
    required String currentUid,
    required String friendUid,
  }) async {
    final currentDocId = await _getUserDocId(currentUid);
    final friendDocId = await _getUserDocId(friendUid);

    final currentUserRef = _db.collection('users').doc(currentDocId);
    final friendRef = _db.collection('users').doc(friendDocId);

    await _db.runTransaction((transaction) async {
      transaction.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([friendUid]),
      });
      transaction.update(friendRef, {
        'friends': FieldValue.arrayRemove([currentUid]),
      });
    });
  }

  Future<String> getChatId(String id1, String id2) async {
    final docId1 = await _getUserDocId(id1);
    final docId2 = await _getUserDocId(id2);
    return docId1.compareTo(docId2) < 0
        ? '${docId1}_$docId2'
        : '${docId2}_$docId1';
  }

  // --- Chat Messaging ---
  Future<String> sendMessage(
    String senderUid,
    String receiverUid,
    String text,
  ) async {
    final senderDocId = await _getUserDocId(senderUid);
    final receiverDocId = await _getUserDocId(receiverUid);
    // Use user document IDs to build the chat ID
    final chatId = await getChatId(senderUid, receiverUid);

    final docRef = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': senderUid,
          'receiverId': receiverUid,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'sent',
        });

    await _db.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': [senderUid, receiverUid], // Auth UIDs for query
      'participantDocIds': [senderDocId, receiverDocId], // Extra metadata
    }, SetOptions(merge: true));

    return docRef.id;
  }

  Stream<QuerySnapshot> getMessagesStream(
    String uid1,
    String uid2, {
    int? lastTimestamp,
  }) async* {
    final chatId = await getChatId(uid1, uid2);

    Query query = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    if (lastTimestamp != null && lastTimestamp > 0) {
      query = query.where(
        'timestamp',
        isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastTimestamp),
      );
    }

    yield* query.snapshots();
  }

  Future<void> markMessagesAsRead(String currentUid, String partnerUid) async {
    final chatId = await getChatId(currentUid, partnerUid);

    final unreadMessages = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: partnerUid)
        .where('status', isEqualTo: 'sent')
        .get();

    if (unreadMessages.docs.isNotEmpty) {
      final batch = _db.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    }
  }

  // --- Search History ---
  Future<void> saveSearchHistory(
    String currentUid,
    Map<String, dynamic> searchedUserData,
  ) async {
    final currentDocId = await _getUserDocId(currentUid);
    final searchedUid =
        searchedUserData['uid'] ??
        searchedUserData['premium_id']; // Use whatever unique ID we have
    if (searchedUid == null) return;

    final searchedDocId = await _getUserDocId(searchedUid);

    await _db
        .collection('users')
        .doc(currentDocId)
        .collection('recent_searches')
        .doc(searchedDocId)
        .set({
          'uid': searchedUserData['uid'],
          'premium_id': searchedUserData['premium_id'],
          'name': searchedUserData['name'],
          'profile_image_url': searchedUserData['profile_image_url'],
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteSearchHistoryItem(
    String currentUid,
    String searchedUid,
  ) async {
    final currentDocId = await _getUserDocId(currentUid);
    await _db
        .collection('users')
        .doc(currentDocId)
        .collection('recent_searches')
        .doc(searchedUid)
        .delete();
  }

  Stream<QuerySnapshot> getSearchHistory(String currentUid) async* {
    final currentDocId = await _getUserDocId(currentUid);
    yield* _db
        .collection('users')
        .doc(currentDocId)
        .collection('recent_searches')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Fetch full profile by Premium ID
  Future<Map<String, dynamic>?> getUserProfileByPremiumId(
    String premiumId,
  ) async {
    final querySnapshot = await _db
        .collection('users')
        .where('premium_id', isEqualTo: premiumId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  // --- Follow & Like Interactions ---
  Future<void> followUser({
    required String currentUid,
    required String targetUid,
    required String currentName,
    required String currentProfileImageUrl,
  }) async {
    final targetDocId = await _getUserDocId(targetUid);
    final targetRef = _db.collection('users').doc(targetDocId);

    final currentDocId = await _getUserDocId(currentUid);
    final currentRef = _db.collection('users').doc(currentDocId);

    final batch = _db.batch();

    batch.update(targetRef, {
      'friends': FieldValue.arrayUnion([currentUid]),
      'friends_count': FieldValue.increment(1),
    });

    batch.update(currentRef, {
      'following': FieldValue.arrayUnion([targetUid]),
      'following_count': FieldValue.increment(1),
    });

    await batch.commit();

    // Send a notification
    final notifId = '${currentDocId}_$targetDocId';
    await _db.collection('notifications').doc(notifId).set({
      'sender_uid': currentUid,
      'receiver_uid': targetUid,
      'sender_name': currentName,
      'sender_profile_image_url': currentProfileImageUrl,
      'type': 'follow',
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    }, SetOptions(merge: true));
  }

  Future<void> unfollowUser({
    required String currentUid,
    required String targetUid,
  }) async {
    final targetDocId = await _getUserDocId(targetUid);
    final targetRef = _db.collection('users').doc(targetDocId);

    final currentDocId = await _getUserDocId(currentUid);
    final currentRef = _db.collection('users').doc(currentDocId);

    final batch = _db.batch();

    batch.update(targetRef, {
      'friends': FieldValue.arrayRemove([currentUid]),
      'friends_count': FieldValue.increment(-1),
    });

    batch.update(currentRef, {
      'following': FieldValue.arrayRemove([targetUid]),
      'following_count': FieldValue.increment(-1),
    });

    await batch.commit();

    // Optional: remove notification
    final notifId = '${currentDocId}_$targetDocId';
    await _db.collection('notifications').doc(notifId).delete();
  }

  Future<void> likeUser({
    required String currentUid,
    required String targetUid,
    required String currentName,
    required String currentProfileImageUrl,
  }) async {
    final targetDocId = await _getUserDocId(targetUid);
    final targetRef = _db.collection('users').doc(targetDocId);

    await targetRef.update({
      'liked_by': FieldValue.arrayUnion([currentUid]),
      'likes_count': FieldValue.increment(1),
    });

    final currentDocId = await _getUserDocId(currentUid);

    // Send a notification
    final notifId = 'like_${currentDocId}_$targetDocId';
    await _db.collection('notifications').doc(notifId).set({
      'sender_uid': currentUid,
      'receiver_uid': targetUid,
      'sender_name': currentName,
      'sender_profile_image_url': currentProfileImageUrl,
      'type': 'like',
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    }, SetOptions(merge: true));
  }

  Future<void> unlikeUser({
    required String currentUid,
    required String targetUid,
  }) async {
    final targetDocId = await _getUserDocId(targetUid);
    final targetRef = _db.collection('users').doc(targetDocId);

    await targetRef.update({
      'liked_by': FieldValue.arrayRemove([currentUid]),
      'likes_count': FieldValue.increment(-1),
    });

    final currentDocId = await _getUserDocId(currentUid);
    final notifId = 'like_${currentDocId}_$targetDocId';
    await _db.collection('notifications').doc(notifId).delete();
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('receiver_uid', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
