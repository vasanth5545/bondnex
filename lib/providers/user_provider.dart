// File: lib/providers/user_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _authStateSubscription;

  String _userName = "Your Name";
  String _firebaseUid = "";
  String _premiumId = "";
  String? _gender;
  File? _userImage;
  String? _profileImageUrl;
  String? _instagramUsername;
  String? _instagramFollowers;
  String? _partnerId;
  String? _partnerName;
  String? _partnerProfileImageUrl;
  bool _callLogSharingEnabled = true;

  bool get isLoggedIn => _firebaseUid.isNotEmpty;
  String get userName => _userName;
  String get myPermanentId => _premiumId;
  String get firebaseUid => _firebaseUid;
  String? get gender => _gender;
  File? get userImage => _userImage;
  String? get profileImageUrl => _profileImageUrl;
  String? get instagramUsername => _instagramUsername;
  String? get instagramFollowers => _instagramFollowers;
  bool get isPartnerConnected => _partnerId != null;
  String? get partnerName => _partnerName;
  String? get partnerProfileImageUrl => _partnerProfileImageUrl;
  String? get partnerId => _partnerId;
  bool get callLogSharingEnabled => _callLogSharingEnabled;

  UserProvider() {
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null && user.emailVerified) {
      await loadUserDataFromFirestore(user);
    } else {
      await clearUserData();
    }
  }
  
  Future<void> _updateBackgroundServiceConfig() async {
     final prefs = await SharedPreferences.getInstance();
     if (_firebaseUid.isNotEmpty) {
       await prefs.setString('user_uid', _firebaseUid);
       await prefs.setBool('callLogSharingEnabled', _callLogSharingEnabled);
     } else {
       await prefs.remove('user_uid');
       await prefs.remove('callLogSharingEnabled');
     }
  }

  Future<void> loadUserDataFromFirestore(User fcmUser) async {
    try {
      final doc = await _firestoreService.getUserData(fcmUser.uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _userName = data['name'] ?? 'No Name';
        _firebaseUid = fcmUser.uid;
        _premiumId = data['premium_id'] ?? '';
        _gender = data['gender'];
        _profileImageUrl = data['profile_image_url'];
        _partnerId = data['partner_uid'];
        _callLogSharingEnabled = data['callLogSharingEnabled'] ?? true;
        
        await _updateBackgroundServiceConfig();

        if (_partnerId != null) {
          final partnerDoc = await _firestoreService.getUserData(_partnerId!);
          if (partnerDoc.exists) {
            final partnerData = partnerDoc.data() as Map<String, dynamic>;
            _partnerName = partnerData['name'];
            _partnerProfileImageUrl = partnerData['profile_image_url'];
          }
        } else {
          _partnerName = null;
          _partnerProfileImageUrl = null;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      await clearUserData();
    }
  }

  Future<void> linkPartner(String partnerId) async {
    if (_firebaseUid.isEmpty) return;
    await _firestoreService.linkPartners(
      currentUserId: _firebaseUid,
      partnerId: partnerId,
    );
    await loadUserDataFromFirestore(_auth.currentUser!);
  }
  
  Future<void> disconnectPartner() async {
    if (_partnerId == null || _firebaseUid.isEmpty) return;

    try {
      await _firestoreService.disconnectPartner(
        currentUserId: _firebaseUid,
        partnerId: _partnerId!,
      );

      _partnerId = null;
      _partnerName = null;
      _partnerProfileImageUrl = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Error disconnecting partner: $e");
      throw Exception("Failed to disconnect. Please try again.");
    }
  }

  Future<void> clearUserData() async {
    _firebaseUid = "";
    _premiumId = "";
    _userName = "Your Name";
    _gender = null;
    _userImage = null;
    _profileImageUrl = null;
    _partnerId = null;
    _partnerName = null;
    _partnerProfileImageUrl = null;
    _instagramUsername = null;
    _instagramFollowers = null;
    _callLogSharingEnabled = true;
    await _updateBackgroundServiceConfig();
    notifyListeners();
  }
  
  Future<void> updateUserName(String newName) async {
    if (_firebaseUid.isEmpty || newName.trim().isEmpty) return;

    try {
      await _firestoreService.updateUserName(_firebaseUid, newName.trim());
      _userName = newName.trim();
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating name: $e");
      throw Exception("Failed to update name.");
    }
  }

  void updateUserImage(File? newImage) {
    _userImage = newImage;
    notifyListeners();
  }

  Future<void> updateInstagramProfile(String? newUsername) async {
    _instagramUsername = newUsername;
    if (newUsername != null && newUsername.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      final random = Random();
      final followers = random.nextInt(5000000) + 1000;
      if (followers > 1000000) {
        _instagramFollowers = '${(followers / 1000000).toStringAsFixed(1)}M';
      } else if (followers > 1000) {
        _instagramFollowers = '${(followers / 1000).toStringAsFixed(1)}K';
      } else {
        _instagramFollowers = followers.toString();
      }
    } else {
      _instagramFollowers = null;
    }
    notifyListeners();
  }

  Future<void> setCallLogSharing(bool enabled) async {
    if (_firebaseUid.isEmpty) return;
    _callLogSharingEnabled = enabled;
    await _firestoreService.updateCallLogSharing(_firebaseUid, enabled);
    await _updateBackgroundServiceConfig();
    notifyListeners();
  }
}
