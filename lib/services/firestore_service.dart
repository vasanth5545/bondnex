// File: lib/services/firestore_service.dart
// This new service encapsulates all Firestore database operations.

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
}
