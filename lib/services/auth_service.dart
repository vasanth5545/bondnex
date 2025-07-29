// File: lib/services/auth_service.dart
// UPDATED: Removed parameters related to temporary user migration ({existingPremiumId, existingPartnerUid})
// from the registerWithEmailAndPassword method, as they are no longer needed.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  /// Handles user registration with Firebase Auth and creates a user record in Firestore.
  Future<User?> registerWithEmailAndPassword(String name, String email, String password, String gender) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = userCredential.user;
      if (user != null) {
        // 2. Create user document in Firestore.
        await _firestoreService.createUser(
          uid: user.uid,
          name: name,
          email: email,
          gender: gender,
        );
        
        // 3. Send verification email
        await user.sendEmailVerification();
        debugPrint("Verification email sent.");
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase registration error: ${e.message}");
      throw Exception(e.message);
    }
  }

  /// Handles user sign-in.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase sign-in error: ${e.message}");
      throw Exception(e.message);
    }
  }

  /// Handles user sign-out.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
