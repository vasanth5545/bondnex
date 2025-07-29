// File: lib/home_page.dart
// UPDATED: The BottomNavigationBar is now dynamic.
// Logged-out users will only see 'Home' (Intro Screen) and 'Phone' tabs.
// Logged-in users will see all four tabs.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';
import 'phone/phone_screen.dart';
import 'activity_screen.dart';
import '../services/firestore_service.dart';
import 'intro_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final bool isLoggedIn = userProvider.isLoggedIn;
        final List<Widget> pages;
        final List<BottomNavigationBarItem> navItems;

        if (isLoggedIn) {
          // --- UI for LOGGED-IN user ---
          pages = const [
            LinkPartnerScreen(),
            PhoneScreen(),
            ActivityScreen(),
            DashboardScreen(),
          ];
          navItems = const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Call'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Activity'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          ];
        } else {
          // --- UI for LOGGED-OUT user ---
          pages = const [
            
            PhoneScreen(),          // Index 0: Shows the Phone dialer
            IntroDashboardScreen(), // Index 1: Shows Login/Register
          ];
          navItems = const [
            
            BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Call'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          ];
        }

        // Prevents range error when logging out
        if (_selectedIndex >= pages.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: navItems,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
          ),
        );
      },
    );
  }
}


class LinkPartnerScreen extends StatefulWidget {
  const LinkPartnerScreen({super.key});

  @override
  State<LinkPartnerScreen> createState() => _LinkPartnerScreenState();
}

class _LinkPartnerScreenState extends State<LinkPartnerScreen> {
  final TextEditingController _partnerCodeController = TextEditingController();
  bool _isLoading = false;
  late FocusNode _partnerCodeFocusNode;

  @override
  void initState() {
    super.initState();
    _partnerCodeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _partnerCodeController.dispose();
    _partnerCodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSendRequest() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final partnerPremiumId = _partnerCodeController.text.trim();

    if (partnerPremiumId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid partner code.')),
      );
      return;
    }

    if (!userProvider.isLoggedIn) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send a request.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = FirestoreService();
      final partnerUid = await firestoreService.getUidByPremiumId(
        partnerPremiumId,
      );

      if (partnerUid == null) {
        throw Exception("Partner with this ID was not found.");
      }

      await firestoreService.sendLoveRequest(
        senderUid: userProvider.firebaseUid,
        receiverUid: partnerUid,
        senderName: userProvider.userName,
        senderProfileImageUrl:
            userProvider.profileImageUrl ??
            'https://placehold.co/600x800/E91E63/FFFFFF?text=${userProvider.userName[0]}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Love request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _partnerCodeController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    final String displayId = userProvider.myPermanentId;
    final myPermanentIdController = TextEditingController(text: displayId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Link with your partner'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Unique ID',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this ID with your partner so they can link with you.',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: myPermanentIdController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Your Unique ID',
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: myPermanentIdController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Your ID copied!')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Enter your partner's code",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your partner's ID here to send a love request.",
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _partnerCodeController,
                  focusNode: _partnerCodeFocusNode,
                  decoration: const InputDecoration(
                    hintText: "Enter partner's ID",
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _onSendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Send Request',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
