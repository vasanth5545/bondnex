// File: lib/splash_screen.dart
// RE-CHECKED & FIXED: The permission request logic has been added back.
// The splash screen now requests permissions first and then waits for the auth check to complete before navigating.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Permission package
import '../providers/user_provider.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  // *** THE FIX IS HERE ***
  // Indha puthu function, modhalla permission kettutu, aprom auth status ku wait pannum
  Future<void> _initializeAndNavigate() async {
    // Step 1: App open aagum bodhe phone and contacts permission ah kekkurom
    // Indha pazhaya code ah thirumba serthirukkom
    await Permission.phone.request();
    await Permission.contacts.request();

    // Step 2: Auth status ku wait panradhu (idhu Consumer la nadakkum)
    // Adhunaala inga vera edhum seiya theva illa.
  }

  void _navigateToNextScreen(BuildContext context) {
    Future.microtask(() {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("👀 Splash Screen loaded");
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Auth status 'checking' la irundhu maaruna odane, adutha screen ku pogum
          if (userProvider.authStatus != AuthStatus.checking) {
            _navigateToNextScreen(context);
          }

          // Auth status check aagura varaikkum, splash screen UI ah kaatum
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/infinity.json',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                 Text(
                  'BondNex',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
