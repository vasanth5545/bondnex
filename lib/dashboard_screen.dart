// File: lib/dashboard_screen.dart
// UPDATED: The status bubble now navigates to the new UpdateStatusScreen.

import 'dart:async';
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
  // Animation controllers for Lottie files
  late final AnimationController _heartLottieController;
  late final AnimationController _lockLottieController;
  
  // State for profile interactions
  bool _isLiked = false;
  int _likeCount = 100000;
  bool _isUploadingBanner = false;

  // --- AppBar Animation ---
  Timer? _animationTimer;
  final List<String> _animatedTexts = [];
  int _currentTextIndex = 0;
  String _displayText = '';
  bool _showAnimatedText = false;

  @override
  void initState() {
    super.initState();
    _heartLottieController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _lockLottieController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    
    _lockLottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lockLottieController.value = 0.35;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAnimatedTexts();
    });
  }

  void _setupAnimatedTexts() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoggedIn) {
      _animatedTexts.clear();
      _animatedTexts.add(userProvider.signature ?? 'Broken hero');
      _animatedTexts.add('dialer app');
      _animatedTexts.add(userProvider.userName);
      _startAnimationLoop();
    }
  }

  void _startAnimationLoop() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _displayText = _animatedTexts[_currentTextIndex];
        _currentTextIndex = (_currentTextIndex + 1) % _animatedTexts.length;
        _showAnimatedText = true;
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showAnimatedText = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _heartLottieController.dispose();
    _lockLottieController.dispose();
    _animationTimer?.cancel();
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

  void _showEditSignatureDialog(BuildContext context, UserProvider userProvider) {
    final signatureController = TextEditingController(text: userProvider.signature ?? 'Broken hero');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Signature', style: GoogleFonts.poppins(color: Colors.white)),
          content: TextField(
            controller: signatureController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[850],
              hintText: 'Enter your signature',
              hintStyle: TextStyle(color: Colors.grey[600]),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                if (signatureController.text.trim().isNotEmpty) {
                  await userProvider.updateUserSignature(signatureController.text.trim());
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'BondNex',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              left: _showAnimatedText ? (MediaQuery.of(context).size.width / 2) - (_displayText.length * 4.5) : 16.0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _showAnimatedText ? 1.0 : 0.0,
                child: Text(
                  _displayText,
                  style: GoogleFonts.pacifico(
                    color: Colors.lightBlueAccent,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
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
                  Positioned(
                    bottom: 45,
                    right: (MediaQuery.of(context).size.width / 2) + 15,
                    child: _buildStatusBubble(context, userProvider),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 18),
                  _buildSocialStat(Icons.people_alt, "1K", Colors.green),
                  const SizedBox(width: 27),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userProvider.userName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                userProvider.myPermanentId,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[400]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.visibility_outlined, color: Colors.grey, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userProvider.bio ?? 'add bio',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _onLikeTapped,
                    child: _buildLottieStat(_formatCount(_likeCount)),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: _buildActionButton('Edit profile', () {
                     Navigator.pushNamed(context, '/edit_profile');
                  })),
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
                            0.27,
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
              GestureDetector(
                onTap: () => _showEditSignatureDialog(context, userProvider),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    userProvider.signature ?? 'Broken hero',
                    style: GoogleFonts.pacifico(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Puthu Widget
  Widget _buildStatusBubble(BuildContext context, UserProvider userProvider) {
    return GestureDetector(
      onTap: () {
        // Itha maathirukkom
        Navigator.pushNamed(context, '/update_status');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E), // Dark bubble color
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userProvider.status ?? "what's up?",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),
          Positioned(
            bottom: -5,
            left: 20,
            child: Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Container(
                width: 10,
                height: 10,
                color: const Color(0xFF2C2C2E),
              ),
            ),
          )
        ],
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
