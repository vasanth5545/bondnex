// File: lib/providers/user_provider.dart
// UPDATED: Added state and methods for the user's customizable status.

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

enum AuthStatus { checking, loggedIn, loggedOut }

class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _authStateSubscription;

  AuthStatus _authStatus = AuthStatus.checking;
  AuthStatus get authStatus => _authStatus;

  String _userName = "Your Name";
  String _firebaseUid = "";
  String _premiumId = "";
  String? _gender;
  File? _userImage;
  String? _profileImageUrl;
  String? _bannerImageUrl;
  String? _bio;
  String? _link;
  String? _signature;
  String? _status; // Puthu variable
  String? _partnerId;
  String? _partnerName;
  String? _partnerProfileImageUrl;
  bool _callLogSharingEnabled = true;

  bool get isLoggedIn => _authStatus == AuthStatus.loggedIn;
  String get userName => _userName;
  String get myPermanentId => _premiumId;
  String get firebaseUid => _firebaseUid;
  String? get gender => _gender;
  File? get userImage => _userImage;
  String? get profileImageUrl => _profileImageUrl;
  String? get bannerImageUrl => _bannerImageUrl;
  String? get bio => _bio;
  String? get link => _link;
  String? get signature => _signature;
  String? get status => _status; // Getter
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
      _authStatus = AuthStatus.loggedOut;
      notifyListeners();
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
      DocumentSnapshot? doc = await _firestoreService.getUserData(fcmUser.uid);
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _userName = data['name'] ?? 'No Name';
        _firebaseUid = fcmUser.uid;
        _premiumId = data['premium_id'] ?? '';
        _gender = data['gender'];
        _profileImageUrl = data['profile_image_url'];
        _bannerImageUrl = data['banner_image_url'];
        _bio = data['bio'];
        _link = data['link'];
        _signature = data['signature'];
        _status = data['status']; // Load status
        _partnerId = data['partner_uid'];
        _callLogSharingEnabled = data['callLogSharingEnabled'] ?? true;
        
        await _updateBackgroundServiceConfig();

        if (_partnerId != null) {
          final partnerDoc = await _firestoreService.getUserData(_partnerId!);
          if (partnerDoc.exists) {
            final partnerData = partnerDoc.data() as Map<String, dynamic>;
            _partnerName = partnerData['name'] ?? 'Partner';
            _partnerProfileImageUrl = partnerData['profile_image_url'];
          }
        }
        _authStatus = AuthStatus.loggedIn;
        notifyListeners();
      } else {
        await clearUserData();
        _authStatus = AuthStatus.loggedOut;
        notifyListeners();
      }
    } catch (e) {
      await clearUserData();
      _authStatus = AuthStatus.loggedOut;
      notifyListeners();
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 50,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        return compressedFile;
      }
    } catch (e) {
      debugPrint("Error compressing image: $e");
    }
    return null;
  }

  Future<void> uploadAndSaveProfilePhoto(File imageFile) async {
    if (_firebaseUid.isEmpty) return;
    try {
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) throw Exception("Image compression failed.");
      final String? imageUrl = await _cloudinaryService.uploadProfilePhoto(compressedImage, _firebaseUid);
      if (imageUrl != null) {
        await _firestoreService.updateUserProfilePhotoUrl(_firebaseUid, imageUrl);
        await _firestoreService.logPhotoUpdate(_firebaseUid, _userName);
        _profileImageUrl = imageUrl;
        _userImage = null;
        notifyListeners();
      } else {
        throw Exception("Cloudinary upload failed, URL is null.");
      }
    } catch (e) {
      throw Exception("Photo upload failed: ${e.toString()}");
    }
  }

  Future<void> uploadAndSaveBannerPhoto(File imageFile) async {
    if (_firebaseUid.isEmpty) return;
    try {
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) throw Exception("Image compression failed.");
      final String? imageUrl = await _cloudinaryService.uploadBannerPhoto(compressedImage, _firebaseUid);
      if (imageUrl != null) {
        await _firestoreService.updateUserBannerPhotoUrl(_firebaseUid, imageUrl);
        _bannerImageUrl = imageUrl;
        notifyListeners();
      } else {
        throw Exception("Cloudinary upload failed, URL is null.");
      }
    } catch (e) {
      debugPrint("Error uploading and saving banner photo: $e");
      rethrow;
    }
  }

  Future<void> removeProfilePhoto() async {
    if (_firebaseUid.isEmpty) return;
    try {
      await _firestoreService.updateUserProfilePhotoUrl(_firebaseUid, '');
      _profileImageUrl = null;
      _userImage = null;
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to remove photo.");
    }
  }

  Future<void> linkPartner(String partnerId) async {
    if (_firebaseUid.isEmpty) throw Exception("Current user not authenticated.");
    try {
      await _firestoreService.linkPartners(currentUserId: _firebaseUid, partnerId: partnerId);
      await loadUserDataFromFirestore(_auth.currentUser!);
    } catch (e) {
      throw Exception("Failed to link partner: ${e.toString()}");
    }
  }
  
  Future<void> disconnectPartner() async {
    if (_partnerId == null || _firebaseUid.isEmpty) return;
    try {
      await _firestoreService.disconnectPartner(currentUserId: _firebaseUid, partnerId: _partnerId!);
      _partnerId = null;
      _partnerName = null;
      _partnerProfileImageUrl = null;
      notifyListeners();
    } catch (e) {
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
    _bannerImageUrl = null;
    _bio = null;
    _link = null;
    _signature = null;
    _status = null; // Clear status
    _partnerId = null;
    _partnerName = null;
    _partnerProfileImageUrl = null;
    _callLogSharingEnabled = true;
    
    await _updateBackgroundServiceConfig();
    _authStatus = AuthStatus.loggedOut;
    notifyListeners();
  }
  
  Future<void> updateUserName(String newName) async {
    if (_firebaseUid.isEmpty || newName.trim().isEmpty) return;
    try {
      await _firestoreService.updateUserName(_firebaseUid, newName.trim());
      _userName = newName.trim();
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update name.");
    }
  }

  Future<void> updateUserBio(String newBio) async {
    if (_firebaseUid.isEmpty) return;
    try {
      await _firestoreService.updateUserBio(_firebaseUid, newBio.trim());
      _bio = newBio.trim();
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update bio.");
    }
  }

  Future<void> updateUserLink(String newLink) async {
    if (_firebaseUid.isEmpty) return;
    try {
      await _firestoreService.updateUserLink(_firebaseUid, newLink.trim());
      _link = newLink.trim();
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update link.");
    }
  }

  Future<void> updateUserGender(String newGender) async {
    if (_firebaseUid.isEmpty) return;
    try {
      await _firestoreService.updateUserGender(_firebaseUid, newGender);
      _gender = newGender;
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update gender.");
    }
  }

  Future<void> updateUserSignature(String newSignature) async {
    if (_firebaseUid.isEmpty) return;
    try {
      await _firestoreService.updateUserSignature(_firebaseUid, newSignature.trim());
      _signature = newSignature.trim();
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update signature.");
    }
  }

  // Puthu function
  Future<void> updateUserStatus(String newStatus) async {
    if (_firebaseUid.isEmpty) return;
    try {
      await _firestoreService.updateUserStatus(_firebaseUid, newStatus.trim());
      _status = newStatus.trim();
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update status.");
    }
  }

  void updateUserImage(File? newImage) {
    _userImage = newImage;
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
