// File: lib/login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'email_verification_screen.dart';
import 'providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late PageController _pageController;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form controllers and keys
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  // --- UPDATED LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          // Fetch user data from MySQL backend
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final bool success = await userProvider.fetchAndSetUserData(user);

          if (success && mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else if (mounted) {
            _showErrorSnackBar('Could not sync your account. Please try again.');
          }
        } else {
          _showErrorSnackBar('Please verify your email before logging in.');
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  name: user.displayName ?? '',
                  email: user.email!,
                ),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Login failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UPDATED REGISTER LOGIC ---
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(_registerNameController.text.trim());
        await user.sendEmailVerification();
        _showSuccessSnackBar('A verification link has been sent to your email.');
        if (mounted) {
          // Navigate to verification screen, which will handle the final registration step
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                name: _registerNameController.text.trim(),
                email: user.email!,
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Registration failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showRegisterPage() => _pageController.animateToPage(1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  void _showLoginPage() => _pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildLoginWidget(),
        _buildRegisterWidget(),
      ],
    );
  }

  Widget _buildLoginWidget() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                Text('Log In', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7))),
                const SizedBox(height: 16),
                Text('Welcome back', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _loginEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email address'),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email address' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _loginPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot password?', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        child: Text('Log In', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _showRegisterPage,
                  child: Text('Register', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterWidget() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: _showLoginPage),
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _registerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registerNameController,
                  decoration: const InputDecoration(hintText: 'Enter your name'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 24),
                Text('Email', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registerEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Enter your email address'),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email address' : null,
                ),
                const SizedBox(height: 24),
                Text('Password', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registerPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Enter your password'),
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 24),
                Text('Confirm Password', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registerConfirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Confirm your password'),
                  validator: (value) {
                    if (value != _registerPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleRegister,
                        child: Text('Register', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
