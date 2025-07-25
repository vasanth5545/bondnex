// File: lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_background_service/flutter_background_service.dart'; // Intha line-a comment pannirukken
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';
import 'phone/phone_screen.dart';
import 'activity_screen.dart';
import '../services/firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    LinkPartnerScreen(),
    PhoneScreen(),
    ActivityScreen(),
    DashboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Background service start pandra code-a remove pannirukken
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Call'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
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

  @override
  void dispose() {
    _partnerCodeController.dispose();
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
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final myPermanentIdController = TextEditingController(
          text: userProvider.myPermanentId,
        );

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Link with your partner'),
            centerTitle: true,
          ),
          body: SafeArea(
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
                            backgroundColor:
                                Colors.green, // 🟢 Intha line add pannirukken
                            foregroundColor:
                                Colors.white, // 🟢 Intha line add pannirukken
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
        );
      },
    );
  }
}
