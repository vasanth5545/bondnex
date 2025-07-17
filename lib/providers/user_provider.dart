import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart'; // Import FirestoreService

class UserProvider extends ChangeNotifier {
  // **THE FIX IS HERE**: Added FirestoreService instance
  final FirestoreService _firestoreService = FirestoreService();

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
  static const String _permanentIdKey = 'permanent_id';

  // Getters
  String get userName => _userName;
  File? get userImage => _userImage;
  String get myPermanentId => _myPermanentId;
  String? get instagramUsername => _instagramUsername;
  String? get instagramFollowers => _instagramFollowers;
  String? get partnerId => _partnerId;
  bool get isPartnerConnected => _partnerId != null;

  UserProvider() {
    _loadInitialDataFromStorage();
  }

  Future<void> _loadInitialDataFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _myPermanentId = prefs.getString(_permanentIdKey) ?? "";
    _userName = prefs.getString(_userNameKey) ?? "Your Name";
    _partnerId = prefs.getString(_partnerIdKey); // Also load partner ID on start
    notifyListeners();
  }

  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, _userName);
    await prefs.setString(_permanentIdKey, _myPermanentId);
    if (_partnerId != null) {
      await prefs.setString(_partnerIdKey, _partnerId!);
    } else {
      await prefs.remove(_partnerIdKey);
    }
  }

  Future<void> loadUserDataFromFirestore(User fcmUser) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(fcmUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['name'] ?? 'No Name';
        _myPermanentId = fcmUser.uid;
        _partnerId = data['partner_uid'];
        
        await _saveUserToStorage();
        
        notifyListeners();
      } else {
        throw Exception('User data not found in the database.');
      }
    } catch (e) {
      debugPrint("Error loading user data from Firestore: $e");
      throw Exception('Failed to load user data. Please try again.');
    }
  }

  /// **THE FIX IS HERE**: New function to handle the full partner linking process.
  Future<void> linkPartnerInFirestore(String partnerId) async {
    // Prevent linking with oneself
    if (partnerId == _myPermanentId) {
      throw Exception("You cannot link with yourself.");
    }
    
    // Call the service to update the database
    await _firestoreService.linkPartners(
      currentUserId: _myPermanentId,
      partnerId: partnerId,
    );

    // Update local state after successful database update
    _partnerId = partnerId;
    await _saveUserToStorage();
    notifyListeners();
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_partnerIdKey);
    // Keep user name and ID for better UX on re-login
    // await prefs.remove(_userNameKey);
    // await prefs.remove(_permanentIdKey);

    _partnerId = null;
    _userImage = null;
    _instagramUsername = null;
    _instagramFollowers = null;
    notifyListeners();
  }

  void updateUserName(String newName) {
    _userName = newName;
    _saveUserToStorage();
    notifyListeners();
  }

  void updateUserImage(File? newImage) {
    _userImage = newImage;
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
