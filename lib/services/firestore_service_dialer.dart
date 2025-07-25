import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';

/// A service for all Firestore-related operations for the call logs.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves a list of call logs to a user's Firestore collection.
  ///
  /// [userId] The ID of the user whose call logs are being saved.
  /// [logs] The list of [CallLogEntry] from the call_log plugin to save.
  Future<void> saveCallLogs(String userId, Iterable<CallLogEntry> logs) async {
    if (userId.isEmpty) return;

    final batch = _db.batch();
    final userCallLogCollection = _db.collection('users').doc(userId).collection('calls');

    for (var log in logs) {
      final docRef = userCallLogCollection.doc();
      batch.set(docRef, {
        'name': log.name,
        'number': log.number,
        'formattedNumber': log.formattedNumber,
        'callType': log.callType?.toString(),
        'date': DateTime.fromMillisecondsSinceEpoch(log.timestamp ?? 0),
        'duration': log.duration,
        'simDisplayName': log.simDisplayName,
        'firestoreTimestamp': FieldValue.serverTimestamp(),
      });
    }

    // Commit the batch write.
    await batch.commit();
  }

  /// Saves a single new call to Firestore.
  ///
  /// This would be called in real-time when a new call is made or received.
  Future<void> saveNewCall(String userId, CallLogEntry log) async {
    if (userId.isEmpty) return;

    final userCallLogCollection = _db.collection('users').doc(userId).collection('calls');
    await userCallLogCollection.add({
        'name': log.name,
        'number': log.number,
        'formattedNumber': log.formattedNumber,
        'callType': log.callType?.toString(),
        'date': DateTime.fromMillisecondsSinceEpoch(log.timestamp ?? 0),
        'duration': log.duration,
        'simDisplayName': log.simDisplayName,
        'firestoreTimestamp': FieldValue.serverTimestamp(),
    });

    // Here, you would also trigger the push notification to the partner.
    _sendPushNotificationToPartner(userId, log);
  }

  void _sendPushNotificationToPartner(String userId, CallLogEntry log) {
    // 1. Get the partner's FCM token from their user document in Firestore.
    // 2. Use a cloud function or your server to send a push notification
    //    with the new call log data.
    debugPrint("Sending push notification for new call from: ${log.number}");
  }
}
