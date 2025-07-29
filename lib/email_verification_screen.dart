import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'home_page.dart'; // Import HomePage
import '../providers/user_provider.dart'; // Import UserProvider

class EmailVerificationScreen extends StatefulWidget {
  final String name;
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    // Start a timer to periodically check if the email has been verified.
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _timer?.cancel();
      return;
    }

    await user.reload();
    
    // **THE FIX IS HERE**: Check if the widget is still mounted before using its context.
    if (!mounted) return;

    if (user.emailVerified) {
      _timer?.cancel();
      // FIX: Load user data into UserProvider after email verification
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserDataFromFirestore(user);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'A verification link has been sent to your email:\n${widget.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Waiting for verification...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your inbox (and spam folder) and click the link.',
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () async {
                  _timer?.cancel();
                  await FirebaseAuth.instance.signOut();
                  // Go back to the login screen
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel & Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
