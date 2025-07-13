import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math'; // For random number generation

class UserProvider extends ChangeNotifier {
  // User's own details
  String _userName = "Your Name";
  File? _userImage;
  // MODIFICATION: Changed from final to allow updating after registration
  String _myPermanentId = ""; 
  String? _instagramUsername;
  String? _instagramFollowers; 

  // Partner's details
  String? _partnerId;

  // Getters
  String get userName => _userName;
  File? get userImage => _userImage;
  // MODIFICATION: This now returns the dynamic ID from the database
  String get myPermanentId => _myPermanentId;
  String? get instagramUsername => _instagramUsername;
  String? get instagramFollowers => _instagramFollowers;
  String? get partnerId => _partnerId;
  bool get isPartnerConnected => _partnerId != null;

  // MODIFICATION: New method to set the unique ID after fetching from PHP
  void setMyPermanentId(String id) {
    _myPermanentId = id;
    notifyListeners();
  }

  // Methods to update state
  void updateUserName(String newName) {
    _userName = newName;
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
