import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
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

  // --- NEW: API URL ---
  final String _syncApiUrl = Platform.isAndroid
      ? 'http://10.160.155.209/myappapi/register.php'
      : 'http://localhost/myappapi/register.php';

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
    loadUserFromStorage();
  }

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _myPermanentId = prefs.getString(_uniqueIdKey) ?? "";
    _userName = prefs.getString(_userNameKey) ?? "Your Name";
    notifyListeners();
  }

  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uniqueIdKey, _myPermanentId);
    await prefs.setString(_userNameKey, _userName);
  }

  // --- NEW & IMPORTANT: Function to fetch/sync data with your MySQL backend ---
  /// Fetches user data from MySQL backend using Firebase user object.
  /// If the user is new, it registers them in MySQL.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> fetchAndSetUserData(User fcmUser, {String? newName}) async {
    try {
      final response = await http.post(
        Uri.parse(_syncApiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'firebase_uid': fcmUser.uid,
          'name': newName ?? fcmUser.displayName ?? 'Unknown User',
          'email': fcmUser.email!,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && responseData['unique_id'] != null) {
          // Update provider state with fetched/created data
          _myPermanentId = responseData['unique_id'];
          _userName = newName ?? fcmUser.displayName ?? 'Unknown User';
          
          // Save to local storage for persistence
          await _saveUserToStorage();
          notifyListeners();
          return true; // Success
        }
      }
      // If server returns an error or unexpected response
      return false;
    } catch (e) {
      // If there's a network error
      debugPrint("Error fetching user data: $e");
      return false;
    }
  }

  void setMyPermanentId(String id) {
    if (id.isNotEmpty) {
      _myPermanentId = id;
      _saveUserToStorage();
      notifyListeners();
    }
  }

  void updateUserName(String newName) {
    if (newName.isNotEmpty) {
      _userName = newName;
      _saveUserToStorage();
      notifyListeners();
    }
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _userName = "Your Name";
    _myPermanentId = "";
    _partnerId = null;
    notifyListeners();
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

  void linkPartner(String newPartnerId) {
    _partnerId = newPartnerId;
    notifyListeners();
  }

  void disconnectPartner() {
    _partnerId = null;
    notifyListeners();
  }
}
