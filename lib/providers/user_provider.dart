// File: lib/providers/user_provider.dart
// UPDATED: Added state and methods for the user's customizable status.

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bondnex/services/database/firestore_service.dart';
import 'package:bondnex/services/storage/cloudinary_service.dart';
import 'package:bondnex/services/database/database_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  String? _partnerBannerImageUrl;
  String? _partnerStatus;
  String? _partnerPremiumId;
  bool _callLogSharingEnabled = true;
  List<String> _galleryImages = [];
  int _friendsCount = 0;
  int _followingCount = 0;
  int _likesCount = 0;
  List<String> _friends = [];
  List<String> _following = [];
  List<String> _likedBy = [];
  bool _isLikedByMe = false;
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
  String? get partnerBannerImageUrl => _partnerBannerImageUrl;
  String? get partnerStatus => _partnerStatus;
  String? get partnerPremiumId => _partnerPremiumId;
  String? get partnerId => _partnerId;
  bool get callLogSharingEnabled => _callLogSharingEnabled;
  List<String> get galleryImages => _galleryImages;
  int get friendsCount => _friendsCount;
  int get followingCount => _followingCount;
  int get likesCount => _likesCount;
  List<String> get friends => _friends;
  List<String> get following => _following;
  List<String> get likedBy => _likedBy;
  bool get isLikedByMe => _isLikedByMe;
  UserProvider() {
    _authStateSubscription = _auth.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null && user.emailVerified) {
      _authStatus = AuthStatus.checking;
      notifyListeners();
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
    // Fast loading from cache
    await loadProfileFromCache();

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

        // Ultra-safe list parsing
        _galleryImages = (data['gallery_images'] is List)
            ? List<String>.from(data['gallery_images'].map((e) => e.toString()))
            : [];

        final friendsList = (data['friends'] is List)
            ? List<String>.from(data['friends'].map((e) => e.toString()))
            : <String>[];

        final followingList = (data['following'] is List)
            ? List<String>.from(data['following'].map((e) => e.toString()))
            : <String>[];

        final likedByList = (data['liked_by'] is List)
            ? List<String>.from(data['liked_by'].map((e) => e.toString()))
            : <String>[];

        _friends = friendsList;
        _following = followingList;
        _likedBy = likedByList;
        _friendsCount = friendsList.length;
        _followingCount = followingList.length;
        _likesCount = likedByList.length;
        _isLikedByMe = likedByList.contains(fcmUser.uid);
        await _updateBackgroundServiceConfig();

        if (_partnerId != null) {
          final partnerDoc = await _firestoreService.getUserData(_partnerId!);
          if (partnerDoc.exists) {
            final partnerData = partnerDoc.data() as Map<String, dynamic>;
            _partnerName = partnerData['name'] ?? 'Partner';
            _partnerProfileImageUrl = partnerData['profile_image_url'];
            _partnerBannerImageUrl = partnerData['banner_image_url'];
            _partnerStatus = partnerData['status'];
            _partnerPremiumId = partnerData['premium_id'];
          }
        }
        _authStatus = AuthStatus.loggedIn;
        await saveProfileToCache(); // Cache for fast load
        notifyListeners();
      } else {
        // Document doesn't exist? Create a fallback document so they aren't locked out.
        debugPrint('User document missing! Creating fallback...');
        await _firestoreService.createUser(
          uid: fcmUser.uid,
          name: fcmUser.displayName ?? 'User',
          email: fcmUser.email ?? '',
          gender: 'Not specified',
        );
        // Try loading again
        final newDoc = await _firestoreService.getUserData(fcmUser.uid);
        if (newDoc.exists) {
          final data = newDoc.data() as Map<String, dynamic>;
          _userName = data['name'] ?? 'User';
          _firebaseUid = fcmUser.uid;
          _premiumId = data['premium_id'] ?? '';
          _authStatus = AuthStatus.loggedIn;
          notifyListeners();
        } else {
          await clearUserData();
          _authStatus = AuthStatus.loggedOut;
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user data: $e');
      debugPrint('Stack trace: $stackTrace');
      await clearUserData();
      _authStatus = AuthStatus.loggedOut;
      notifyListeners();
      throw Exception('Data Load Error: $e');
    }
  }

  Future<void> uploadAndSaveProfilePhoto(File imageFile) async {
    if (_firebaseUid.isEmpty) return;
    try {
      final String? imageUrl = await _cloudinaryService.uploadProfilePhoto(
        imageFile,
        _firebaseUid,
      );
      if (imageUrl != null) {
        await _firestoreService.updateUserProfilePhotoUrl(
          _firebaseUid,
          imageUrl,
        );
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
      final String? imageUrl = await _cloudinaryService.uploadBannerPhoto(
        imageFile,
        _firebaseUid,
      );
      if (imageUrl != null) {
        await _firestoreService.updateUserBannerPhotoUrl(
          _firebaseUid,
          imageUrl,
        );
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

  Future<void> uploadAndSaveGalleryPhoto(File imageFile) async {
    if (_firebaseUid.isEmpty) return;
    try {
      final String? imageUrl = await _cloudinaryService.uploadGalleryPhoto(
        imageFile,
        _firebaseUid,
      );
      if (imageUrl != null) {
        await _firestoreService.addUserGalleryPhotoUrl(_firebaseUid, imageUrl);
        _galleryImages.add(imageUrl);
        notifyListeners();
      } else {
        throw Exception("Cloudinary upload failed, URL is null.");
      }
    } catch (e) {
      debugPrint("Error uploading gallery photo: $e");
      throw Exception("Photo upload failed: ${e.toString()}");
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
    if (_firebaseUid.isEmpty) {
      throw Exception("Current user not authenticated.");
    }
    try {
      await _firestoreService.linkPartners(
        currentUserId: _firebaseUid,
        partnerId: partnerId,
      );
      await loadUserDataFromFirestore(_auth.currentUser!);
    } catch (e) {
      throw Exception("Failed to link partner: ${e.toString()}");
    }
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
    _galleryImages = [];

    await _updateBackgroundServiceConfig();
    _authStatus = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_firebaseUid.isEmpty) return;
    try {
      // 1. Delete Firestore Data & Unlink Partner
      await _firestoreService.deleteUserAccount(_firebaseUid);
      
      // 2. Delete Local Database
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.deleteEntireDatabase();
      } catch (e) {
        debugPrint('Error deleting local DB: $e');
      }

      // 3. Delete Secure Storage
      try {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.deleteAll();
      } catch (e) {
        debugPrint('Error deleting secure storage: $e');
      }

      // 4. Delete Firebase Auth User
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }

      // 5. Clear Local State
      await clearUserData();
    } catch (e) {
      throw Exception("Failed to delete account: ${e.toString()}");
    }
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
      await _firestoreService.updateUserSignature(
        _firebaseUid,
        newSignature.trim(),
      );
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

  Future<void> toggleLike() async {
    if (_firebaseUid.isEmpty) return;
    try {
      final newLikeState = !_isLikedByMe;
      await _firestoreService.toggleLike(
        targetUid: _firebaseUid, // Because this is my profile
        currentUid: _firebaseUid,
        isLiked: newLikeState,
      );
      _isLikedByMe = newLikeState;
      _likesCount += newLikeState ? 1 : -1;
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to toggle like.");
    }
  }

  Future<void> saveProfileToCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userName.isNotEmpty) prefs.setString('cache_userName', _userName);
    if (_profileImageUrl != null) {
      prefs.setString('cache_profileImageUrl', _profileImageUrl!);
    }
    if (_bannerImageUrl != null) {
      prefs.setString('cache_bannerImageUrl', _bannerImageUrl!);
    }
    if (_status != null) prefs.setString('cache_status', _status!);

    if (_partnerId != null) {
      prefs.setString('cache_partnerId', _partnerId!);
      if (_partnerName != null) {
        prefs.setString('cache_partnerName', _partnerName!);
      }
      if (_partnerProfileImageUrl != null) {
        prefs.setString(
          'cache_partnerProfileImageUrl',
          _partnerProfileImageUrl!,
        );
      }
      if (_partnerBannerImageUrl != null) {
        prefs.setString('cache_partnerBannerImageUrl', _partnerBannerImageUrl!);
      }
      if (_partnerStatus != null) {
        prefs.setString('cache_partnerStatus', _partnerStatus!);
      }
      if (_partnerPremiumId != null) {
        prefs.setString('cache_partnerPremiumId', _partnerPremiumId!);
      }
    } else {
      prefs.remove('cache_partnerId');
    }
  }

  Future<void> loadProfileFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('cache_userName') ?? _userName;
    _profileImageUrl =
        prefs.getString('cache_profileImageUrl') ?? _profileImageUrl;
    _bannerImageUrl =
        prefs.getString('cache_bannerImageUrl') ?? _bannerImageUrl;
    _status = prefs.getString('cache_status') ?? _status;

    _partnerId = prefs.getString('cache_partnerId');
    if (_partnerId != null) {
      _partnerName = prefs.getString('cache_partnerName');
      _partnerProfileImageUrl = prefs.getString('cache_partnerProfileImageUrl');
      _partnerBannerImageUrl = prefs.getString('cache_partnerBannerImageUrl');
      _partnerStatus = prefs.getString('cache_partnerStatus');
      _partnerPremiumId = prefs.getString('cache_partnerPremiumId');
    }
    notifyListeners();
  }
}
