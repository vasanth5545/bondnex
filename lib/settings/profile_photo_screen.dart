// File: lib/settings/profile_photo_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/user_provider.dart';

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _tempImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _tempImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle any errors, e.g., permissions denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final imageToShow = _tempImage ?? userProvider.userImage;

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
              // **THE FIX IS HERE** - Displaying image in a circle
              CircleAvatar(
                radius: MediaQuery.of(context).size.width / 4,
                backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundImage: imageToShow != null ? FileImage(imageToShow) : null,
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
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _buildOptionButton(
                context,
                text: 'Choose from Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              _buildOptionButton(context, text: 'Crop & Preview', onTap: () {}),
              _buildOptionButton(
                context,
                text: 'Remove Photo',
                onTap: () {
                  setState(() {
                    _tempImage = null;
                  });
                  userProvider.updateUserImage(null);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'This photo will be visible to your partner.',
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
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
                      onPressed: () {
                        if (_tempImage != null) {
                          userProvider.updateUserImage(_tempImage);
                        }
                        Navigator.of(context).pop();
                      },
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
