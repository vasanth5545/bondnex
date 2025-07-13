// File: lib/email_verification_screen.dart
// This screen handles the email verification process and syncs with the PHP backend.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class EmailVerificationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const EmailVerificationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  Timer? _timer;
  bool _canResendEmail = false;
  int _resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    // Check if the email is already verified when the screen loads.
    _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!_isEmailVerified) {
      // Start a timer to periodically check the verification status.
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Important to cancel the timer to avoid memory leaks.
    super.dispose();
  }

  /// Periodically checks with Firebase if the user's email has been verified.
  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // Refresh user data from Firebase.

    if (user?.emailVerified ?? false) {
      _timer?.cancel(); // Stop the timer once verified.
      setState(() => _isEmailVerified = true);
      
      _showSnackBar('Email successfully verified! Syncing with server...', Colors.green);
      
      // Once verified, send the data to your PHP backend.
      await _syncWithPhpRegister(user!);
      
      // Navigate to the home screen after successful sync.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  /// Resends the verification email to the user.
  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _showSnackBar('A new verification email has been sent.', Colors.blue);
      _startResendTimer(); // Restart the cooldown timer.
    } catch (e) {
      _showSnackBar('Failed to send verification email.', Colors.redAccent);
    }
  }

  /// Sends the new user's data to your `register.php` script.
  Future<void> _syncWithPhpRegister(User user) async {
    // The URL of your PHP registration script.
    final url = Uri.parse('https://bondnexapi.great-site.net/register.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firebase_uid': user.uid,
          'name': widget.name,
          'email': widget.email,
        }),
      );
      
      debugPrint('PHP Register Response: ${response.body}');
      if (response.statusCode == 200) {
        _showSnackBar('Account synced with server!', Colors.green);
      } else {
        _showSnackBar('Server sync failed. Please contact support.', Colors.redAccent);
      }
    } catch (e) {
      debugPrint('PHP Register Sync failed: $e');
      _showSnackBar('Could not connect to the server.', Colors.redAccent);
    }
  }

  /// Helper to start the cooldown timer for the "Resend Email" button.
  void _startResendTimer() {
    setState(() => _canResendEmail = false);
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown == 0) {
        timer.cancel();
        setState(() {
          _canResendEmail = true;
          _resendCooldown = 30;
        });
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  /// Helper to show a SnackBar message.
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
        child: Padding(
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
              const SizedBox(height: 32),
              _isEmailVerified
                ? Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 40),
                      const SizedBox(height: 16),
                      Text('Email Verified!', style: GoogleFonts.poppins(fontSize: 18, color: Colors.green)),
                    ],
                  )
                : const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Waiting for verification...'),
                    ],
                  ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _canResendEmail ? _resendVerificationEmail : null,
                child: Text(_canResendEmail ? 'Resend Email' : 'Resend in $_resendCooldown s'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Cancel & Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
