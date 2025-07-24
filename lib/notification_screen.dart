// File: lib/notification_screen.dart
// UPDATED: Ippo sariyaana Firebase UID-ah vachi love request-ah thedurom.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoveRequest {
  final String id;
  final String senderName;
  final String senderProfileImageUrl;
  final String senderUid;
  final String receiverUid;
  final Timestamp timestamp;

  LoveRequest({
    required this.id,
    required this.senderName,
    required this.senderProfileImageUrl,
    required this.senderUid,
    required this.receiverUid,
    required this.timestamp,
  });

  factory LoveRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return LoveRequest(
      id: doc.id,
      senderName: data['sender_name'] ?? 'Someone',
      senderProfileImageUrl: (data['sender_profile_image_url'] != null && data['sender_profile_image_url'].isNotEmpty)
          ? data['sender_profile_image_url']
          : 'https://via.placeholder.com/600x800/E91E63/FFFFFF?text=${(data['sender_name'] ?? 'S')[0]}',
      senderUid: data['sender_uid'] ?? '',
      receiverUid: data['receiver_uid'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Stream<QuerySnapshot> _requestsStream;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firestoreService = FirestoreService();
    if (userProvider.isLoggedIn) {
      // **THE FIX IS HERE**: Ippo sariyaana receiver-oda Firebase UID-ah vachi thedurom.
      _requestsStream = firestoreService.getLoveRequests(userProvider.firebaseUid);
    } else {
      _requestsStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _requestsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No new love requests',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              );
            }

            final requests = snapshot.data!.docs
                .map((doc) => LoveRequest.fromFirestore(doc))
                .toList();

            requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return LoveRequestCard(request: requests[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class LoveRequestCard extends StatefulWidget {
  final LoveRequest request;

  const LoveRequestCard({super.key, required this.request});

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
                color: Colors.pink.withOpacity(0.15),
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
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF2B1B2C)),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                    child: Container(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                Positioned(top: 20, right: 20, child: Icon(Icons.favorite, color: Colors.white.withOpacity(0.3), size: 18)),
                Positioned(top: 100, left: 30, child: Icon(LucideIcons.sparkles, color: Colors.white.withOpacity(0.3), size: 16)),
                Positioned(bottom: 100, right: 40, child: Icon(Icons.favorite, color: Colors.white.withOpacity(0.2), size: 22)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () async {
                                      setState(() => _isLoading = true);
                                      await firestoreService.updateLoveRequestStatus(
                                        requestId: widget.request.id,
                                        status: 'declined',
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white.withOpacity(0.8),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                                      await userProvider.linkPartner(widget.request.senderUid);
                                      await firestoreService.updateLoveRequestStatus(
                                        requestId: widget.request.id,
                                        status: 'accepted',
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE91E63),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Text('Accept', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
