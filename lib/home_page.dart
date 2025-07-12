// File: lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'notification_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    LinkPartnerScreen(),
    ChatListScreen(),
    NotificationScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
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

  @override
  void dispose() {
    _partnerCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // **THE FIX IS HERE** - Using Consumer to get user's permanent ID
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final myPermanentIdController = TextEditingController(text: userProvider.myPermanentId);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Link with your partner'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generate a unique partner code', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Share this code with your partner to link your accounts.', style: GoogleFonts.poppins(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: myPermanentIdController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Your Unique ID',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.copy, color: Theme.of(context).iconTheme.color),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: myPermanentIdController.text));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your ID copied!')));
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(minimumSize: const Size(100, 50)),
                        child: const Text('Share'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text("Enter your partner's code", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('If your partner has already generated a code, enter it here.', style: GoogleFonts.poppins(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _partnerCodeController,
                    decoration: const InputDecoration(hintText: 'Enter code'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // **THE FIX IS HERE** - Linking logic
                      if (_partnerCodeController.text.isNotEmpty) {
                        userProvider.linkPartner(_partnerCodeController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Partner linked successfully!')),
                        );
                        // Optionally navigate to dashboard or another screen
                        // For now, it just updates the state.
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid partner code.')),
                        );
                      }
                    },
                    child: Text('Confirm', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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
