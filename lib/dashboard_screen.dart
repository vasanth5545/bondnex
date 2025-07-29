// File: lib/dashboard_screen.dart
// VILAKKAM: Unga puthiya animation rules-kaaga, controller logic sariyaaga
// maati amaikapattullathu.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_provider.dart';
import 'notification_screen.dart';
import 'private_gallery_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late final AnimationController _heartLottieController;
  late final AnimationController _lockLottieController;
  
  bool _isLiked = false;
  int _likeCount = 100000;
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();
    _heartLottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _lockLottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // --- ITHU THAAN SARIYAANA LOGIC ---
    _lockLottieController.addStatusListener((status) {
      // Animation mulusaa odi mudincha odane...
      if (status == AnimationStatus.completed) {
        // Neradiyaaga 0-ku kondu varom (reverse illama)
        _lockLottieController.value = 0.35;
      }
    });
  }

  @override
  void dispose() {
    _heartLottieController.dispose();
    _lockLottieController.dispose();
    super.dispose();
  }

  void _onLikeTapped() {
    setState(() {
      if (_isLiked) {
        _heartLottieController.reset();
        _likeCount--;
        _isLiked = false;
      } else {
        _heartLottieController.animateTo(1, duration: const Duration(milliseconds: 500));
        _likeCount++;
        _isLiked = true;
      }
    });
  }

  Future<void> _pickAndUploadBanner() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

      if (pickedFile == null || !mounted) return;

      final imageFile = File(pickedFile.path);
      final int fileSizeInBytes = await imageFile.length();
      if (fileSizeInBytes > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo must be under 2MB.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _isUploadingBanner = true);
      await userProvider.uploadAndSaveBannerPhoto(imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating banner: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
      }
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return NumberFormat.compact().format(count);
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return _buildSingleUserProfile(context, userProvider);
      },
    );
  }

  Widget _buildSingleUserProfile(BuildContext context, UserProvider userProvider) {
    ImageProvider? profileImageProvider;
    if (userProvider.userImage != null) {
      profileImageProvider = FileImage(userProvider.userImage!);
    } else if (userProvider.profileImageUrl != null && userProvider.profileImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(userProvider.profileImageUrl!);
    }

    ImageProvider? bannerImageProvider;
    if (userProvider.bannerImageUrl != null && userProvider.bannerImageUrl!.isNotEmpty) {
      bannerImageProvider = NetworkImage(userProvider.bannerImageUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(backgroundColor: Colors.transparent),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20.0),
                      image: bannerImageProvider != null
                          ? DecorationImage(image: bannerImageProvider, fit: BoxFit.cover)
                          : null,
                    ),
                    child: _isUploadingBanner
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : (bannerImageProvider == null
                            ? const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey)
                            : null),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        onPressed: _isUploadingBanner ? null : _pickAndUploadBanner,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
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
                            backgroundColor: Colors.green,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              onPressed: () => Navigator.pushNamed(context, '/profile_photo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 13),
                  _buildSocialStat(Icons.people_alt, "1K", Colors.green),
                  const SizedBox(width: 18),
                  Column(
                    children: [
                      Text(
                        userProvider.userName,
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userProvider.myPermanentId,
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.visibility_outlined, color: Colors.grey, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'add bio',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(width:7),
                  GestureDetector(
                    onTap: _onLikeTapped,
                    child: _buildLottieStat(_formatCount(_likeCount)),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: _buildActionButton('Edit profile', () {})),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton('Account Setting', () {
                      Navigator.pushNamed(context, '/account_settings');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: () async {
                  final bool? fileAdded = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivateGalleryScreen()),
                  );
                  if (fileAdded == true) {
                    _lockLottieController.forward(from: 0.27);
                  }
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/lock.json',
                        width: 80,
                        height: 80,
                        controller: _lockLottieController,
                        onLoaded: (composition) {
                          _lockLottieController.duration = composition.duration;
                          _lockLottieController.animateTo(
                            0.27, // 38 / 141 = ~0.27
                            duration: const Duration(milliseconds: 800),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Private Gallery',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialStat(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildLottieStat(String value) {
    return Column(
      children: [
        Lottie.asset('assets/heart.json', controller: _heartLottieController, width: 60, height: 60),
        Transform.translate(
          offset: const Offset(0, -8), 
          child: Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
    );
  }
}
