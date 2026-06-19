import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../../providers/user_provider.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const PublicProfileScreen({super.key, required this.profileData});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with TickerProviderStateMixin {
  bool _isSendingRequest = false;
  String? _partnerImageUrl;
  String? _partnerName;
  String? _partnerStatus;
  bool _isLoadingPartner = false;
  bool _isFollowing = false;
  bool _isLiked = false;
  int _localFriendsCount = 0;
  int _localLikesCount = 0;
  List<dynamic> _localFriends = [];
  List<dynamic> _localLikedBy = [];

  late final AnimationController _heartLottieController;

  @override
  void initState() {
    super.initState();
    _heartLottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _localFriends = widget.profileData['friends'] ?? [];
    _localLikedBy = widget.profileData['liked_by'] ?? [];
    _localFriendsCount =
        widget.profileData['friends_count'] ?? _localFriends.length;
    _localLikesCount =
        widget.profileData['likes_count'] ?? _localLikedBy.length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        _isFollowing = _localFriends.contains(userProvider.firebaseUid);
        _isLiked = _localLikedBy.contains(userProvider.firebaseUid);
        if (_isLiked) {
          _heartLottieController.value = 1.0;
        }
      });
    });

    _fetchPartnerData();
  }

  @override
  void dispose() {
    _heartLottieController.dispose();
    super.dispose();
  }

  Future<void> _fetchPartnerData() async {
    final partnerUid = widget.profileData['partner_uid'];
    if (partnerUid != null && partnerUid.toString().isNotEmpty) {
      setState(() {
        _isLoadingPartner = true;
      });
      try {
        final doc = await FirestoreService().getUserData(partnerUid);
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _partnerImageUrl = data['profile_image_url'];
            _partnerName = data['name'];
            _partnerStatus = data['status'];
          });
        }
      } catch (e) {
        debugPrint('Error fetching partner data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingPartner = false;
          });
        }
      }
    }
  }

  Future<void> _sendLoveRequest() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.isPartnerConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already connected to a partner!'),
        ),
      );
      return;
    }

    final partnerUid = widget.profileData['uid'];
    if (partnerUid == userProvider.firebaseUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot send a request to yourself!'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }

    setState(() => _isSendingRequest = true);

    try {
      final firestoreService = FirestoreService();

      await firestoreService.sendLoveRequest(
        senderUid: userProvider.firebaseUid,
        receiverUid: partnerUid,
        senderName: userProvider.userName,
        senderProfileImageUrl:
            userProvider.profileImageUrl ??
            'https://placehold.co/600x800/E91E63/FFFFFF?text=${userProvider.userName[0]}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Love request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Future<void> _toggleFollow() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetUid = widget.profileData['uid'];

    if (targetUid == null) return;
    
    if (targetUid == userProvider.firebaseUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot follow yourself!'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }

    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _localFriendsCount++;
        _localFriends.add(userProvider.firebaseUid);
      } else {
        _localFriendsCount--;
        _localFriends.remove(userProvider.firebaseUid);
      }
    });

    try {
      if (_isFollowing) {
        await FirestoreService().followUser(
          currentUid: userProvider.firebaseUid,
          targetUid: targetUid,
          currentName: userProvider.userName,
          currentProfileImageUrl: userProvider.profileImageUrl ?? '',
        );
      } else {
        await FirestoreService().unfollowUser(
          currentUid: userProvider.firebaseUid,
          targetUid: targetUid,
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isFollowing = !_isFollowing;
        _isFollowing ? _localFriendsCount++ : _localFriendsCount--;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleLike() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetUid = widget.profileData['uid'];

    if (targetUid == null) return;

    if (targetUid == userProvider.firebaseUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot like your own profile!'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _localLikesCount++;
        _localLikedBy.add(userProvider.firebaseUid);
        _heartLottieController.forward(from: 0);
      } else {
        _localLikesCount--;
        _localLikedBy.remove(userProvider.firebaseUid);
        _heartLottieController
            .reset(); // Instantly turns to empty/unliked state with no animation
      }
    });

    try {
      if (_isLiked) {
        await FirestoreService().likeUser(
          currentUid: userProvider.firebaseUid,
          targetUid: targetUid,
          currentName: userProvider.userName,
          currentProfileImageUrl: userProvider.profileImageUrl ?? '',
        );
      } else {
        await FirestoreService().unlikeUser(
          currentUid: userProvider.firebaseUid,
          targetUid: targetUid,
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _isLiked ? _localLikesCount++ : _localLikesCount--;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildStatusBubble(BuildContext context, String statusText) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
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
    );
  }

  Widget _buildSocialStat(
    IconData icon,
    String value,
    Color color, {
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    Widget? extraWidget,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: extraWidget ?? Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl = widget.profileData['banner_image_url'] as String?;
    final profileUrl = widget.profileData['profile_image_url'] as String?;
    final name = widget.profileData['name'] ?? 'Unknown User';
    final premiumId = widget.profileData['premium_id'] ?? '';
    final bio = widget.profileData['bio'] ?? 'No bio available.';
    final status = widget.profileData['status'] ?? "what's up?";
    final signature = widget.profileData['signature'] ?? 'Broken hero';
    final List<dynamic> galleryImages =
        widget.profileData['gallery_images'] ?? [];

    final hasPartner =
        widget.profileData['partner_uid'] != null &&
        widget.profileData['partner_uid'].toString().isNotEmpty;

    ImageProvider? bannerImageProvider =
        bannerUrl != null && bannerUrl.isNotEmpty
        ? NetworkImage(bannerUrl)
        : null;
    ImageProvider? profileImageProvider =
        profileUrl != null && profileUrl.isNotEmpty
        ? NetworkImage(profileUrl)
        : null;
    ImageProvider? partnerImageProvider =
        _partnerImageUrl != null && _partnerImageUrl!.isNotEmpty
        ? NetworkImage(_partnerImageUrl!)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
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
                        child: bannerImageProvider == null
                            ? const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: hasPartner
                        ? SizedBox(
                            width: 250,
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  left: 0,
                                  child: Container(
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
                                      child: profileImageProvider == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.white70,
                                            )
                                          : null,
                                    ),
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
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: partnerImageProvider,
                                      child: _isLoadingPartner
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : (partnerImageProvider == null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Colors.white70,
                                                  )
                                                : null),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 5),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: profileImageProvider,
                              child: profileImageProvider == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white70,
                                    )
                                  : null,
                            ),
                          ),
                  ),
                  if (!hasPartner)
                    Positioned(
                      bottom: 95,
                      right: (MediaQuery.of(context).size.width / 2) + 15,
                      child: _buildStatusBubble(context, status),
                    ),
                  if (hasPartner) ...[
                    Positioned(
                      bottom: 95,
                      right: (MediaQuery.of(context).size.width / 2) + 15,
                      child: _buildStatusBubble(context, status),
                    ),
                    Positioned(
                      bottom: 95,
                      left: (MediaQuery.of(context).size.width / 2) + 15,
                      child: _buildStatusBubble(
                        context,
                        _partnerStatus ?? "what's up?",
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
                  const SizedBox(width: 18),
                  _buildSocialStat(
                    Icons.people_alt,
                    _formatCount(_localFriendsCount),
                    Colors.green,
                    onLongPress: () =>
                        _showUsersListBottomSheet(_localFriends, 'Followers'),
                  ),
                  const SizedBox(width: 27),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasPartner
                              ? '$name & ${_partnerName ?? 'Partner'}'
                              : name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: hasPartner ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          premiumId,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildLottieStat(
                    _formatCount(_localLikesCount),
                    onTap: _toggleLike,
                    onLongPress: () =>
                        _showUsersListBottomSheet(_localLikedBy, 'Liked By'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Send Request',
                      Icons.favorite,
                      Colors.pinkAccent,
                      _isSendingRequest ? null : _sendLoveRequest,
                      extraWidget: _isSendingRequest
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      _isFollowing ? 'Following' : 'Follow',
                      _isFollowing ? Icons.check : Icons.person_add,
                      _isFollowing ? Colors.grey[800]! : Colors.blueAccent,
                      _toggleFollow,
                    ),
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
                child: galleryImages.isEmpty
                    ? Center(
                        child: Text(
                          'No photos uploaded yet',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : PageView.builder(
                        itemCount: galleryImages.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.network(
                              galleryImages[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  signature,
                  style: GoogleFonts.pacifico(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
