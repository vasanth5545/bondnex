import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RtdbService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // --- What's Up Status (Presence & Mood) ---

  Future<void> updateWhatsUpStatus({
    required String uid,
    required String mood,
    required String listeningTo,
    required String musicThumbnail,
  }) async {
    try {
      final DatabaseReference statusRef = _db.ref('whats_up_status/$uid');
      await statusRef.set({
        'mood': mood,
        'listening_to': listeningTo,
        'music_thumbnail': musicThumbnail,
        'updated_at': ServerValue.timestamp,
        'is_online': true,
      });

      // Handle disconnect - when user goes offline
      statusRef.onDisconnect().update({
        'is_online': false,
        'last_seen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint("Error updating What's up status: $e");
    }
  }

  Stream<DatabaseEvent> getPartnerWhatsUpStatus(String partnerUid) {
    return _db.ref('whats_up_status/$partnerUid').onValue;
  }
}
