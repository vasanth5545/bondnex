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
import '../../providers/user_provider.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../communication/notification_screen.dart';
import '../profile/partner_profile_screen.dart';
import '../profile/public_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // Animation controllers for Lottie files
  late final AnimationController _heartLottieController;
  late final AnimationController _lockLottieController;

  // State for profile interactions
  bool _isUploadingBanner = false;
  bool _isUploadingProfile = false;

  // --- AppBar Animation ---
  Timer? _animationTimer;
  final List<String> _animatedTexts = [];
  int _currentTextIndex = 0;
  String _displayText = '';
  bool _showAnimatedText = false;

  // --- Gallery Animation ---
  int _currentGalleryIndex = 0;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You cannot like your own profile!'),
        backgroundColor: Colors.pinkAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditSignatureDialog(
    BuildContext context,
    UserProvider userProvider,
  ) {
    final signatureController = TextEditingController(
      text: userProvider.signature ?? 'Broken hero',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Signature',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: TextField(
            controller: signatureController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[850],
              hintText: 'Enter your signature',
              hintStyle: TextStyle(color: Colors.grey[600]),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                borderSide: const BorderSide(
                  color: Colors.blueAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (signatureController.text.trim().isNotEmpty) {
                  await userProvider.updateUserSignature(
                    signatureController.text.trim(),
                  );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      final imageFile = File(pickedFile.path);
      final int fileSizeInBytes = await imageFile.length();
      if (!mounted) return;
      if (fileSizeInBytes > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo must be under 2MB.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _isUploadingProfile = true);
      await userProvider.uploadAndSaveProfilePhoto(imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile photo: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingProfile = false);
      }
    }
  }

  Future<void> _pickAndUploadBanner() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      final imageFile = File(pickedFile.path);
      final int fileSizeInBytes = await imageFile.length();
      if (!mounted) return;
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

  Widget _buildSingleUserProfile(
    BuildContext context,
    UserProvider userProvider,
  ) {
    ImageProvider? profileImageProvider;
    if (userProvider.userImage != null) {
      profileImageProvider = FileImage(userProvider.userImage!);
    } else if (userProvider.profileImageUrl != null &&
        userProvider.profileImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(userProvider.profileImageUrl!);
    }

    ImageProvider? partnerImageProvider;
    if (userProvider.partnerProfileImageUrl != null &&
        userProvider.partnerProfileImageUrl!.isNotEmpty) {
      partnerImageProvider = NetworkImage(userProvider.partnerProfileImageUrl!);
    }

    ImageProvider? bannerImageProvider;
    if (userProvider.bannerImageUrl != null &&
        userProvider.bannerImageUrl!.isNotEmpty) {
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
              left: _showAnimatedText
                  ? (MediaQuery.of(context).size.width / 2) -
                        (_displayText.length * 4.5)
                  : 16.0,
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
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
                  Column(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(20.0),
                          image: bannerImageProvider != null
                              ? DecorationImage(
                                  image: bannerImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _isUploadingBanner
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : (bannerImageProvider == null
                                  ? const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    )
                                  : null),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _isUploadingBanner
                            ? null
                            : _pickAndUploadBanner,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: userProvider.isPartnerConnected
                        ? SizedBox(
                            width: 250,
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  left: 0,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 5,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.grey[800],
                                          backgroundImage: profileImageProvider,
                                          child: _isUploadingProfile
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : (profileImageProvider == null
                                                    ? const Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color: Colors.white70,
                                                      )
                                                    : null),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: -10,
                                        child: GestureDetector(
                                          onTap: _pickAndUploadProfile,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.pinkAccent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 2,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(
                                              Icons.add,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 5,
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const PartnerProfileScreen(),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[800],
                                        backgroundImage: partnerImageProvider,
                                        child: partnerImageProvider == null
                                            ? const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.white70,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ), // Closing Positioned
                              ],
                            ),
                          )
                        : Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: profileImageProvider,
                                  child: _isUploadingProfile
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : (profileImageProvider == null
                                            ? const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.white70,
                                              )
                                            : null),
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
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: _isUploadingProfile
                                        ? null
                                        : _pickAndUploadProfile,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (!userProvider.isPartnerConnected)
                    Positioned(
                      bottom: 95,
                      right: (MediaQuery.of(context).size.width / 2) + 15,
                      child: _buildStatusBubble(
                        context,
                        userProvider.status ?? "what's up?",
                        onTap: () =>
                            Navigator.pushNamed(context, '/update_status'),
                      ),
                    ),
                  if (userProvider.isPartnerConnected) ...[
                    Positioned(
                      bottom: 95,
                      right: (MediaQuery.of(context).size.width / 2) + 15,
                      child: _buildStatusBubble(
                        context,
                        userProvider.status ?? "what's up?",
                        onTap: () =>
                            Navigator.pushNamed(context, '/update_status'),
                      ),
                    ),
                    Positioned(
                      bottom: 95,
                      left: (MediaQuery.of(context).size.width / 2) + 15,
                      child: _buildStatusBubble(
                        context,
                        userProvider.partnerStatus ?? "what's up?",
                        onTap: null,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side (Followers/Following)
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 80,
                      child: PageView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildSocialStat(
                            Icons.people_alt,
                            _formatCount(userProvider.friendsCount),
                            'Followers',
                            Colors.green,
                            onTap: () => _showUsersListBottomSheet(
                              userProvider.friends,
                              'Followers',
                            ),
                          ),
                          _buildSocialStat(
                            Icons.person_add_alt_1,
                            _formatCount(userProvider.followingCount),
                            'Following',
                            Colors.blueAccent,
                            onTap: () => _showUsersListBottomSheet(
                              userProvider.following,
                              'Following',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center (Name, ID, Bio)
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userProvider.userName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (userProvider.isPartnerConnected) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.pinkAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  userProvider.partnerName ?? 'Partner',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pinkAccent,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                userProvider.myPermanentId,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userProvider.bio ?? 'add bio',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side (Likes)
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.center,
                      child: _buildLottieStat(
                        _formatCount(userProvider.likesCount),
                        onTap: _onLikeTapped,
                        onLongPress: () => _showUsersListBottomSheet(
                          userProvider.likedBy,
                          'Liked By',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton('Edit profile', () {
                      Navigator.pushNamed(context, '/edit_profile');
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton('Account Setting', () {
                      Navigator.pushNamed(context, '/account_settings');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Stack(
                  children: [
                    if (userProvider.galleryImages.isEmpty)
                      Center(
                        child: Text(
                          'No photos uploaded yet',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    else
                      PageView.builder(
                        itemCount: userProvider.galleryImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentGalleryIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Image.network(
                                  userProvider.galleryImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Uploader info
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Uploaded by ${userProvider.userName}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Page indicators (••••)
                              if (userProvider.galleryImages.length > 1)
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        userProvider.galleryImages.length,
                                        (dotIndex) => Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                _currentGalleryIndex == dotIndex
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                    alpha: 0.4,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    // Indicators
                    if (userProvider.galleryImages.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              userProvider.galleryImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                width: _currentGalleryIndex == index ? 8 : 6,
                                height: _currentGalleryIndex == index ? 8 : 6,
                                decoration: BoxDecoration(
                                  color: _currentGalleryIndex == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.upload, color: Colors.white),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (pickedFile != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Uploading photo...'),
                                ),
                              );
                              try {
                                await userProvider.uploadAndSaveGalleryPhoto(
                                  File(pickedFile.path),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Photo uploaded successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Upload failed: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildStatusBubble(
    BuildContext context,
    String statusText, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              statusText,
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
          ),
        ],
      ),
    );
  }

  void _showUsersListBottomSheet(List<dynamic> uids, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1120),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (uids.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: 150,
            child: Center(
              child: Text(
                'No one yet!',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
            ),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: uids.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirestoreService().getUserData(uids[index]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const ListTile(
                          title: Text(
                            'Loading...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      if (!snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final name = userData['name'] ?? 'Unknown';
                      final imageUrl = userData['profile_image_url'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PublicProfileScreen(profileData: userData),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialStat(
    IconData icon,
    String value,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildLottieStat(
    String value, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Lottie.asset(
            'assets/heart.json',
            controller: _heartLottieController,
            width: 60,
            height: 60,
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
    );
  }
}
