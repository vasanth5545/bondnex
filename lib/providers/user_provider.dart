// File: lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math'; // For random number generation

class UserProvider extends ChangeNotifier {
  // User's own details
  String _userName = "Your Name";
  File? _userImage;
  final String _myPermanentId = "USER-ABCD-1234";
  String? _instagramUsername;
  String? _instagramFollowers; // This will now be set by a simulated API call

  // Partner's details
  String? _partnerId;

  // Getters
  String get userName => _userName;
  File? get userImage => _userImage;
  String get myPermanentId => _myPermanentId;
  String? get instagramUsername => _instagramUsername;
  String? get instagramFollowers => _instagramFollowers;
  String? get partnerId => _partnerId;
  bool get isPartnerConnected => _partnerId != null;

  // Methods to update state
  void updateUserName(String newName) {
    _userName = newName;
    notifyListeners();
  }

  void updateUserImage(File? newImage) {
    _userImage = newImage;
    notifyListeners();
  }

  // **THE FIX IS HERE** - Now only takes username, simulates fetching followers
  Future<void> updateInstagramProfile(String? newUsername) async {
    _instagramUsername = newUsername;
    
    if (newUsername != null && newUsername.isNotEmpty) {
      // Simulate fetching followers from an API
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      final random = Random();
      final followers = random.nextInt(5000000) + 1000; // Generate random followers
      
      if (followers > 1000000) {
        _instagramFollowers = '${(followers / 1000000).toStringAsFixed(1)}M';
      } else if (followers > 1000) {
        _instagramFollowers = '${(followers / 1000).toStringAsFixed(1)}K';
      } else {
        _instagramFollowers = followers.toString();
      }

    } else {
      // If username is removed, clear followers
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
