// File: lib/notification_screen.dart
// UPDATED: Ippo sariyaana Firebase UID-ah vachi love request-ah thedurom.
// UPDATED: Requests are now grouped by sender, and a count is displayed.
// FIX: Allowing notifications for temporary/anonymous users.
// FIX: Improved acceptance flow for immediate UI update and navigation.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth-ஐ இறக்குமதி செய்யவும்
import '../../providers/user_provider.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import '../profile/public_profile_screen.dart'; // For navigating to user profiles
import 'package:lucide_icons/lucide_icons.dart';

class LoveRequest {
  final String id;
  final String senderName;
  final String senderProfileImageUrl;
  final String senderUid;
  final String receiverUid;
  final Timestamp timestamp;
  final int requestCount;

  LoveRequest({
    required this.id,
    required this.senderName,
    required this.senderProfileImageUrl,
    required this.senderUid,
    required this.receiverUid,
    required this.timestamp,
    required this.requestCount,
  });

  factory LoveRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return LoveRequest(
      id: doc.id,
      senderName: data['sender_name'] ?? 'Someone',
      senderProfileImageUrl:
          (data['sender_profile_image_url'] != null &&
              data['sender_profile_image_url'].isNotEmpty)
          ? data['sender_profile_image_url']
          : 'https://via.placeholder.com/600x800/E91E63/FFFFFF?text=${(data['sender_name'] ?? 'S')[0]}',
      senderUid: data['sender_uid'] ?? '',
      receiverUid: data['receiver_uid'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      requestCount: data['request_count'] ?? 1,
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Firebase Auth-இன் தற்போதைய பயனரின் UID-ஐ நேரடியாகப் பயன்படுத்துதல்
    final currentUser = FirebaseAuth.instance.currentUser;
    final String? currentUid = currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notification'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
              Tab(text: 'Alerts'),
            ],
            indicatorColor: Colors.pinkAccent,
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (currentUid == null || currentUid.isEmpty) {
                return Center(
                  child: Text(
                    'No user found to fetch notifications. Please try generating a UID or logging in.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                );
              }

              final firestoreService = FirestoreService();

              return TabBarView(
                children: [
                  // Tab 1: Received Requests
                  _buildRequestsTab(
                    firestoreService.getLoveRequests(currentUid),
                    false,
                  ),
                  // Tab 2: Sent Requests
                  _buildRequestsTab(
                    firestoreService.getSentLoveRequests(currentUid),
                    true,
                  ),
                  // Tab 3: Alerts (Likes and Follows)
                  _buildAlertsTab(
                    firestoreService.getNotifications(currentUid),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsTab(Stream<QuerySnapshot> stream, bool isSent) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isSent ? 'No sent requests' : 'No new love requests',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          );
        }

        final allRequests = snapshot.data!.docs
            .map((doc) => LoveRequest.fromFirestore(doc))
            .toList();

        // For sent requests, group by receiver instead of sender
        final Map<String, List<LoveRequest>> groupedRequests = {};
        for (var request in allRequests) {
          final key = isSent ? request.receiverUid : request.senderUid;
          groupedRequests.putIfAbsent(key, () => []).add(request);
        }

        final sortedIds = groupedRequests.keys.toList()
          ..sort((a, b) {
            final latestA = groupedRequests[a]!.reduce(
              (curr, next) =>
                  curr.timestamp.compareTo(next.timestamp) > 0 ? curr : next,
            );
            final latestB = groupedRequests[b]!.reduce(
              (curr, next) =>
                  curr.timestamp.compareTo(next.timestamp) > 0 ? curr : next,
            );
            return latestB.timestamp.compareTo(latestA.timestamp);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedIds.length,
          itemBuilder: (context, index) {
            final targetUid = sortedIds[index];
            final requestsForTarget = groupedRequests[targetUid]!;
            final latestRequest = requestsForTarget.reduce(
              (curr, next) =>
                  curr.timestamp.compareTo(next.timestamp) > 0 ? curr : next,
            );

            return GestureDetector(
              onTap: () async {
                // Navigate to public profile
                final targetDoc = await FirestoreService().getUserData(
                  isSent ? latestRequest.receiverUid : latestRequest.senderUid,
                );
                if (targetDoc.exists && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfileScreen(
                        profileData: targetDoc.data() as Map<String, dynamic>,
                      ),
                    ),
                  );
                }
              },
              child: isSent
                  ? SentRequestCard(
                      request: latestRequest,
                      requestCount: latestRequest.requestCount,
                    )
                  : LoveRequestCard(
                      request: latestRequest,
                      requestCount: latestRequest.requestCount,
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertsTab(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No new alerts',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          );
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index].data() as Map<String, dynamic>;
            final senderName = notif['sender_name'] ?? 'Someone';
            final senderImageUrl = notif['sender_profile_image_url'] ?? '';
            final type = notif['type'] ?? 'follow';
            final senderUid = notif['sender_uid'];

            return ListTile(
              onTap: () async {
                if (senderUid != null) {
                  final targetDoc = await FirestoreService().getUserData(
                    senderUid,
                  );
                  if (targetDoc.exists && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PublicProfileScreen(
                          profileData: targetDoc.data() as Map<String, dynamic>,
                        ),
                      ),
                    );
                  }
                }
              },
              leading: CircleAvatar(
                backgroundImage: senderImageUrl.isNotEmpty
                    ? NetworkImage(senderImageUrl)
                    : null,
                child: senderImageUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(
                senderName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                type == 'like' ? 'Liked your profile' : 'Started following you',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              trailing: Icon(
                type == 'like' ? Icons.favorite : Icons.person_add,
                color: Colors.pinkAccent,
              ),
            );
          },
        );
      },
    );
  }
}

class LoveRequestCard extends StatefulWidget {
  final LoveRequest request;
  final int requestCount;

  const LoveRequestCard({
    super.key,
    required this.request,
    this.requestCount = 1,
  });

  @override
  State<LoveRequestCard> createState() => _LoveRequestCardState();
}

class _LoveRequestCardState extends State<LoveRequestCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.request.senderProfileImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF2B1B2C)),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // கோரிக்கை எண்ணிக்கையைக் காட்டும் சிறிய வட்டம்
                if (widget.requestCount > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red, // Count circle color
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.requestCount}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 30,
                  child: Icon(
                    LucideIcons.sparkles,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ),
                Positioned(
                  bottom: 100,
                  right: 40,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 22,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.senderName,
                        style: GoogleFonts.pacifico(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accept my love request? ❤️',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () async {
                                      setState(() => _isLoading = true);
                                      try {
                                        await firestoreService
                                            .updateLoveRequestStatus(
                                              requestId: widget.request.id,
                                              status: 'declined',
                                            );
                                        if (context.mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Dismiss after decline
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error declining: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() => _isLoading = true);
                                      try {
                                        await userProvider.linkPartner(
                                          widget.request.senderUid,
                                        );
                                        await firestoreService
                                            .updateLoveRequestStatus(
                                              requestId: widget.request.id,
                                              status: 'accepted',
                                            );

                                        // Cleanup logic: delete all other pending requests to prevent spam
                                        await firestoreService
                                            .deleteAllOtherPendingRequests(
                                              userProvider.firebaseUid,
                                              widget.request.id,
                                            );
                                        await firestoreService
                                            .deleteAllSentPendingRequests(
                                              userProvider.firebaseUid,
                                            );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Partner linked successfully!',
                                              ),
                                            ),
                                          );
                                          // Navigate back to the previous screen (Dashboard/Home)
                                          Navigator.of(context).pop();
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error accepting: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE91E63),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Accept',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SentRequestCard extends StatefulWidget {
  final LoveRequest request;
  final int requestCount;

  const SentRequestCard({
    super.key,
    required this.request,
    this.requestCount = 1,
  });

  @override
  State<SentRequestCard> createState() => _SentRequestCardState();
}

class _SentRequestCardState extends State<SentRequestCard> {
  bool _isLoading = false;
  Map<String, dynamic>? receiverData;

  @override
  void initState() {
    super.initState();
    _fetchReceiverData();
  }

  Future<void> _fetchReceiverData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.request.receiverUid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        receiverData = doc.data();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    final receiverName = receiverData?['name'] ?? 'Unknown User';
    final receiverProfileUrl = receiverData?['profile_image_url'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (receiverProfileUrl.isNotEmpty)
                  Image.network(
                    receiverProfileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: const Color(0xFF1B222C)),
                  )
                else
                  Container(color: const Color(0xFF1B222C)),

                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),

                if (widget.requestCount > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent, // Count circle color
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.requestCount}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receiverName,
                        style: GoogleFonts.pacifico(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Love request sent... ⏳',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    await firestoreService.cancelLoveRequest(
                                      widget.request.id,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Request cancelled.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Cancel Request',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
