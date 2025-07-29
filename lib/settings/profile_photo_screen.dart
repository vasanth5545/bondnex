// File: lib/settings/profile_photo_screen.dart
// VILAKKAM: Intha file-la irundhu 'crop' sambanthamaana code neekapattullathu.
// Ippo image picker neradiyaaga velai seiyum.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/user_provider.dart';
// 'crop_photo_screen.dart' import neekapattathu.

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _tempImage;
  bool _isLoading = false;

  // --- ITHA MAATHIRUKKOM ---
  // Intha puthu function, photo-va select senja odane, neradiyaaga use pannum.
  // Crop screen-ku pogaathu.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85, // Quality konjam korachirukkom for better performance
      );

      if (pickedFile == null || !mounted) return;

      // Cropping illama, neradiyaaga image ah set panrom
      setState(() {
        _tempImage = File(pickedFile.path);
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }
  
  Future<void> _onSave() async {
    if (_tempImage == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.uploadAndSaveProfilePhoto(_tempImage!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating photo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRemove() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.removeProfilePhoto();
      if (mounted) {
        setState(() {
          _tempImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing photo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    ImageProvider? imageToShow;
    if (_tempImage != null) {
      imageToShow = FileImage(_tempImage!);
    } else if (userProvider.profileImageUrl != null && userProvider.profileImageUrl!.isNotEmpty) {
      imageToShow = NetworkImage(userProvider.profileImageUrl!);
    }


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profile Photo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width / 4,
                backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundImage: imageToShow,
                child: imageToShow == null
                    ? Icon(
                        Icons.person,
                        size: 80,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      )
                    : null,
              ),
              const SizedBox(height: 30),
              _buildOptionButton(
                context,
                text: 'Take New Photo',
                onTap: () => _pickImage(ImageSource.camera), // Maathapattullathu
              ),
              _buildOptionButton(
                context,
                text: 'Choose from Gallery',
                onTap: () => _pickImage(ImageSource.gallery), // Maathapattullathu
              ),
              _buildOptionButton(
                context,
                text: 'Remove Photo',
                onTap: _onRemove,
              ),
              const SizedBox(height: 12),
              Text(
                'This photo will be visible to your partner.',
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          minimumSize: const Size(0, 50),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                        child: const Text('Save/Update'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, {required String text, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          elevation: 0,
        ),
        child: Text(text),
      ),
    );
  }
}
