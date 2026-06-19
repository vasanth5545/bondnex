// File: lib/services/cloudinary_service.dart
// VILAKKAM: Ithu banner feature-kaana maatangal serkapattulla mulumaiyaana file.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:bondnex/services/core/api_keys.dart';

class CloudinaryService {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    ApiKeys.cloudinaryCloudName,
    ApiKeys.cloudinaryUploadPreset,
    cache: false,
  );

  /// Uploads a user's profile photo to Cloudinary and returns the secure URL.
  Future<String?> uploadProfilePhoto(File file, String uid) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: uid,
        ),
      );

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('Error uploading to Cloudinary: ${e.message}');
      return null;
    }
  }

  // User-oda banner photo-vai upload seiya
  Future<String?> uploadBannerPhoto(File file, String uid) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'banners/$uid', // Banner-ku thani folder
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('Error uploading banner to Cloudinary: ${e.message}');
      return null;
    }
  }

  // Upload gallery photo
  Future<String?> uploadGalleryPhoto(File file, String uid) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'gallery/$uid',
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('Error uploading gallery photo to Cloudinary: ${e.message}');
      return null;
    }
  }
}
