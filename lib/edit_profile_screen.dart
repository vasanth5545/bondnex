// File: lib/edit_profile_screen.dart
// UPDATED: TextFields now have a professional, bordered, and rounded design.
// UPDATED: Gender selection is removed and now only displays the user's registered gender.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'providers/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _linkController;

  File? _tempBannerImage;
  File? _tempProfileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.userName);
    _bioController = TextEditingController(text: userProvider.bio ?? '');
    _linkController = TextEditingController(text: userProvider.link ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {required bool isBanner}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile == null || !mounted) return;

      setState(() {
        if (isBanner) {
          _tempBannerImage = File(pickedFile.path);
        } else {
          _tempProfileImage = File(pickedFile.path);
        }
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
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      if (_nameController.text.trim() != userProvider.userName) {
        await userProvider.updateUserName(_nameController.text.trim());
      }
      if (_bioController.text.trim() != (userProvider.bio ?? '')) {
        await userProvider.updateUserBio(_bioController.text.trim());
      }
      if (_linkController.text.trim() != (userProvider.link ?? '')) {
        await userProvider.updateUserLink(_linkController.text.trim());
      }
      if (_tempBannerImage != null) {
        await userProvider.uploadAndSaveBannerPhoto(_tempBannerImage!);
      }
      if (_tempProfileImage != null) {
        await userProvider.uploadAndSaveProfilePhoto(_tempProfileImage!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
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

    ImageProvider? bannerImageProvider;
    if (_tempBannerImage != null) {
      bannerImageProvider = FileImage(_tempBannerImage!);
    } else if (userProvider.bannerImageUrl != null && userProvider.bannerImageUrl!.isNotEmpty) {
      bannerImageProvider = NetworkImage(userProvider.bannerImageUrl!);
    }

    ImageProvider? profileImageProvider;
    if (_tempProfileImage != null) {
      profileImageProvider = FileImage(_tempProfileImage!);
    } else if (userProvider.profileImageUrl != null && userProvider.profileImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(userProvider.profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.blueAccent, size: 28),
              onPressed: _onSave,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery, isBanner: true),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20.0),
                        image: bannerImageProvider != null
                            ? DecorationImage(image: bannerImageProvider, fit: BoxFit.cover)
                            : null,
                      ),
                      child: bannerImageProvider == null
                          ? const Center(child: Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery, isBanner: false),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 5),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: profileImageProvider,
                              child: profileImageProvider == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.white70)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.blueAccent,
                              child: const Icon(LucideIcons.pencil, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70),
              _buildEditableField(
                context,
                controller: _nameController,
                label: 'Name',
              ),
              const SizedBox(height: 24),
              _buildEditableField(
                context,
                controller: _bioController,
                label: 'Bio',
                maxLines: 5,
                maxLength: 100,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 24),
              _buildEditableField(
                context,
                controller: _linkController,
                label: 'Link',
              ),
              const SizedBox(height: 24),
              // --- ITHA MAATHIRUKKOM ---
              _buildInfoDisplay(
                label: 'Gender',
                value: userProvider.gender?.capitalize() ?? 'Not specified',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- ITHA MAATHIRUKKOM ---
  Widget _buildEditableField(BuildContext context, {
    required TextEditingController controller, 
    required String label, 
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.grey[900],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // --- ITHU PUTHU WIDGET ---
  Widget _buildInfoDisplay({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This cannot be changed.',
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

// Helper extension to capitalize first letter
extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}
