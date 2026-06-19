import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../communication/notification_screen.dart';

class PartnerProfileScreen extends StatelessWidget {
  const PartnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Partner data from UserProvider cache
    final partnerName = userProvider.partnerName ?? 'Partner';
    final partnerStatus =
        userProvider.partnerStatus ?? 'Hey there! I am using BondNex.';
    final partnerBannerUrl = userProvider.partnerBannerImageUrl;
    final partnerProfileUrl = userProvider.partnerProfileImageUrl;

    ImageProvider? bannerImageProvider;
    if (partnerBannerUrl != null && partnerBannerUrl.isNotEmpty) {
      bannerImageProvider = NetworkImage(partnerBannerUrl);
    }

    ImageProvider? profileImageProvider;
    if (partnerProfileUrl != null && partnerProfileUrl.isNotEmpty) {
      profileImageProvider = NetworkImage(partnerProfileUrl);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$partnerName\'s Profile'),
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
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
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.white54,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[700],
                      backgroundImage: profileImageProvider,
                      child: profileImageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Text(
              partnerName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              partnerStatus,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Placeholder for partner's gallery or photos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gallery',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No photos available.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
