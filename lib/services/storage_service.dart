// File: lib/services/storage_service.dart
// This new service handles all file uploads to Firebase Storage.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a user's profile photo and returns the download URL.
  Future<String?> uploadProfilePhoto(String uid, File file) async {
    try {
      // Create a reference to the file's location
      final ref = _storage.ref().child('profile_photos/$uid');
      
      // Upload the file
      UploadTask uploadTask = ref.putFile(file);
      
      // Await the upload to complete
      TaskSnapshot snapshot = await uploadTask;
      
      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }

  /// Uploads an image for a post and returns the download URL.
  Future<String?> uploadPostImage(String uid, File file) async {
    try {
      // Generate a unique file name for the post image
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('post_images/$uid/$fileName');
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      return null;
    }
  }
}
