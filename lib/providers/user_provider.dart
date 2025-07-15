import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  // User's own details
  String _userName = "Your Name";
  File? _userImage;
  String _myPermanentId = ""; // This will be the user's UID
  String? _instagramUsername;
  String? _instagramFollowers;

  // Partner's details
  String? _partnerId;

  // Keys for SharedPreferences
  static const String _userNameKey = 'user_name';
  static const String _partnerIdKey = 'partner_id';

  // Getters
  String get userName => _userName;
  File? get userImage => _userImage;
  String get myPermanentId => _myPermanentId;
  String? get instagramUsername => _instagramUsername;
  String? get instagramFollowers => _instagramFollowers;
  String? get partnerId => _partnerId;
  bool get isPartnerConnected => _partnerId != null;

  UserProvider() {
    // Initial load from storage can be done here if needed
  }

  /// Loads user data from local storage (for faster startup)
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(_userNameKey) ?? "Your Name";
    _partnerId = prefs.getString(_partnerIdKey);
    notifyListeners();
  }

  /// Saves user data to local storage
  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, _userName);
    if (_partnerId != null) {
      await prefs.setString(_partnerIdKey, _partnerId!);
    } else {
      await prefs.remove(_partnerIdKey);
    }
  }

  /// **CORRECTED**: Loads user data from Firestore and updates the provider state.
  /// This is the main function to call after a user logs in.
  Future<void> loadUserDataFromFirestore(User fcmUser) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(fcmUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['name'] ?? 'No Name';
        _myPermanentId = fcmUser.uid; // The user's UID is their permanent ID
        _partnerId = data['partner_uid']; // Load partner UID from Firestore
        
        // Save the latest data to local storage
        await _saveUserToStorage();
        
        // Notify all listening widgets to rebuild with the new data
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data from Firestore: $e");
    }
  }

  /// Clears all user data on logout.
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _userName = "Your Name";
    _myPermanentId = "";
    _partnerId = null;
    _userImage = null;
    _instagramUsername = null;
    _instagramFollowers = null;
    notifyListeners();
  }

  // Other update functions remain the same
  void updateUserName(String newName) {
    _userName = newName;
    _saveUserToStorage();
    notifyListeners();
  }

  void updateUserImage(File? newImage) {
    _userImage = newImage;
    notifyListeners();
  }
  
  void linkPartner(String newPartnerId) {
    _partnerId = newPartnerId;
    _saveUserToStorage();
    notifyListeners();
  }

  void disconnectPartner() {
    _partnerId = null;
    _saveUserToStorage();
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
}
