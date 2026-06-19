// File: lib/photo_view_screen.dart
// FINAL VERSION: Uses image_gallery_saver_plus to "unlock" photos back to the public gallery.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class PhotoViewScreen extends StatelessWidget {
  final File imageFile;

  const PhotoViewScreen({super.key, required this.imageFile});

  Future<void> _unlockPhoto(BuildContext context) async {
    try {
      final result = await ImageGallerySaverPlus.saveFile(imageFile.path);
      if (result != null && result['isSuccess']) {
        await imageFile.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo returned to gallery!')),
        );
        Navigator.of(context).pop(true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to return photo to gallery.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deletePhoto(BuildContext context) async {
    try {
      await imageFile.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted permanently.')),
      );
      Navigator.of(context).pop(true); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting photo: $e')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Delete Photo?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'This action is permanent and cannot be undone.',
            style: TextStyle(color: Colors.white70)
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePhoto(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.file(imageFile),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black.withOpacity(0.8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.lock_open, color: Colors.white),
              onPressed: () => _unlockPhoto(context),
              tooltip: 'Return to Gallery',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'Delete Permanently',
            ),
          ],
        ),
      ),
    );
  }
}
