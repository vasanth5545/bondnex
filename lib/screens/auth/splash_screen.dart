// File: lib/splash_screen.dart
// RE-CHECKED & FIXED: The permission request logic has been added back.
// The splash screen now requests permissions first and then waits for the auth check to complete before navigating.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Permission package
import '../../providers/user_provider.dart';
import '../../providers/call_log_provider.dart';
import 'auth_wrapper.dart';
import 'default_dialer_prompt_screen.dart';
import '../../services/telephony/call_manager_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool _hasError = false;
  String _errorMessage = "";
  bool _canUpdate = false;

  Future<void> _initializeAndNavigate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('checkAppStatus');
      final result = await callable.call();
      final data = result.data;

      if (data['maintenanceMode'] == true) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = "App is currently under maintenance. Please try again later.";
          });
        }
        return;
      }

      final minVersion = data['minVersion'] ?? 1;
      final List<dynamic> blockedVersions = data['blockedVersions'] ?? [];

      if (currentVersion < minVersion || blockedVersions.contains(currentVersion)) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _canUpdate = true;
            _errorMessage = "A critical update is required. Please update the app to continue.";
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("App Config check failed, proceeding anyway: $e");
    }

    await Permission.phone.request();
    await Permission.contacts.request();
    await Permission.notification.request();

    if (mounted) {
      Provider.of<CallLogProvider>(context, listen: false).initializeCallLogs();
    }
  }

  bool _isNavigating = false;

  Future<void> _navigateToNextScreen(BuildContext context) async {
    if (_isNavigating) return;
    _isNavigating = true;

    final isDefaultDialer = await CallManagerService().isDefaultDialer();

    if (context.mounted) {
      if (!isDefaultDialer) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DefaultDialerPromptScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("👀 Splash Screen loaded");
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: _hasError ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              Text(
                "App Notice",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_canUpdate)
                ElevatedButton(
                  onPressed: () {
                    // Replace with actual Play Store link
                    launchUrl(Uri.parse("market://details?id=com.bondnex.couple"));
                  },
                  child: const Text("Update App"),
                ),
            ],
          ),
        )
      ) : Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Auth status 'checking' la irundhu maaruna odane, adutha screen ku pogum
          if (userProvider.authStatus != AuthStatus.checking && !_hasError) {
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
                    color: Colors.white.withValues(alpha: 0.9),
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
