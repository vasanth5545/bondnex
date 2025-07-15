import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';

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
  bool _isEmailVerified = false;
  Timer? _timer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
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

    if (user.emailVerified) {
      _timer?.cancel();

      if (mounted) {
        setState(() {
            _isEmailVerified = true;
            _isSyncing = true;
        });
      }

      _showSnackBar('Email successfully verified! Syncing your account...', Colors.green);
      // --- UPDATED LOGIC ---
      // Now we call the central function from our provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final bool success = await userProvider.fetchAndSetUserData(user, newName: widget.name);

      if (success && mounted) {
        _showSnackBar('Account synced successfully! Welcome!', Colors.green);
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (mounted) {
        _showSnackBar('Could not sync your account. Please try logging in.', Colors.redAccent);
        // Navigate to login if sync fails
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
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
              if (_isEmailVerified)
                Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      _isSyncing ? 'Syncing your account...' : 'Email Verified!',
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.green)
                    ),
                    if (_isSyncing) const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: CircularProgressIndicator(),
                    )
                  ],
                )
              else
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
                onPressed: () {
                  _timer?.cancel();
                  FirebaseAuth.instance.signOut();
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
