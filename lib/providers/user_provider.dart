import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  // User's own details
  String _userName = "Your Name";
  File? _userImage;
  String _myPermanentId = "";
  String? _instagramUsername;
  String? _instagramFollowers;

  // Partner's details
  String? _partnerId;

  // Keys for SharedPreferences
  static const String _uniqueIdKey = 'user_unique_id';
  static const String _userNameKey = 'user_name';

  // Getters
  String get userName => _userName;
  File? get userImage => _userImage;
  String get myPermanentId => _myPermanentId;
  String? get instagramUsername => _instagramUsername;
  String? get instagramFollowers => _instagramFollowers;
  String? get partnerId => _partnerId;
  bool get isPartnerConnected => _partnerId != null;

  UserProvider() {
    // Load user data from local storage when the provider is created
    loadUserFromStorage();
  }

  // --- NEW: Load user data from SharedPreferences ---
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _myPermanentId = prefs.getString(_uniqueIdKey) ?? "";
    _userName = prefs.getString(_userNameKey) ?? "Your Name";
    notifyListeners();
  }

  // --- NEW: Save user data to SharedPreferences ---
  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uniqueIdKey, _myPermanentId);
    await prefs.setString(_userNameKey, _userName);
  }

  // --- UPDATED: Methods now save to storage automatically ---
  void setMyPermanentId(String id) {
    if (id.isNotEmpty) {
      _myPermanentId = id;
      _saveUserToStorage(); // Save automatically
      notifyListeners();
    }
  }

  void updateUserName(String newName) {
    if (newName.isNotEmpty) {
      _userName = newName;
      _saveUserToStorage(); // Save automatically
      notifyListeners();
    }
  }

  // --- NEW: Clear user data on logout ---
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all data from SharedPreferences
    _userName = "Your Name";
    _myPermanentId = "";
    _partnerId = null;
    notifyListeners();
  }

  void updateUserImage(File? newImage) {
    _userImage = newImage;
    notifyListeners();
  }

  // --- FIXED: Added the missing updateInstagramProfile method ---
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

  void linkPartner(String newPartnerId) {
    _partnerId = newPartnerId;
    notifyListeners();
  }

  void disconnectPartner() {
    _partnerId = null;
    notifyListeners();
  }
}
