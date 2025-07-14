// File: lib/email_verification_screen.dart
// UPDATED: Wrapped the Column with a SingleChildScrollView to fix layout overflow.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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

  final String _apiUrl = Platform.isAndroid 
    ? 'http://10.0.2.2/myappapi/register.php' 
    : 'http://localhost/myappapi/register.php';

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
      await _syncWithPhpRegister(user);
    }
  }

  Future<void> _syncWithPhpRegister(User user) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'firebase_uid': user.uid,
          'name': widget.name,
          'email': widget.email,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && responseData['unique_id'] != null) {
          final String uniqueId = responseData['unique_id'];
          
          if (mounted) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            userProvider.setMyPermanentId(uniqueId);
            userProvider.updateUserName(widget.name);
            _showSnackBar('Account synced successfully! Welcome!', Colors.green);
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        } else {
           _showSnackBar(responseData['message'] ?? 'Server sync failed.', Colors.redAccent);
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}. Please try again.', Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar('Could not connect to the local server. Is XAMPP running?', Colors.redAccent);
    } finally {
        if (mounted) {
            setState(() => _isSyncing = false);
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
        // FIX: Added SingleChildScrollView to prevent overflow on smaller screens.
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
