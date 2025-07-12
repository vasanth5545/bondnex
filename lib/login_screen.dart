// File: lib/screens/login_screen.dart
// This screen now handles both Login and Register views for instant switching.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // PageController to manage the switch between Login and Register views
  late PageController _pageController;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Function to switch to the Register page view
  void _showRegisterPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // Function to switch back to the Login page view
  void _showLoginPage() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using PageView to hold both Login and Register widgets
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Disable swiping
      children: [
        _buildLoginWidget(),
        // The RegisterScreen's UI is now built here directly
        // This avoids creating a new route and feels much faster.
        _buildRegisterWidget(),
      ],
    );
  }

  // Widget for the Login View
  Widget _buildLoginWidget() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              Text('Log In', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7))),
              const SizedBox(height: 16),
              Text('Welcome back', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 50),
              const TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(hintText: 'Email address'),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () { /* TODO: Forgot password */ },
                  child: Text('Forgot password?', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () { /* TODO: Login logic */ },
                child: Text('Log In', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _showRegisterPage, // **THE FIX IS HERE**
                child: Text('Register', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for the Register View (previously register_screen.dart)
  Widget _buildRegisterWidget() {
    return Scaffold(
      appBar: AppBar(
        // Back button to return to the login view
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _showLoginPage, // **THE FIX IS HERE**
        ),
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(hintText: 'Enter your name')),
              const SizedBox(height: 24),
              Text('Email', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'Enter your email')),
              const SizedBox(height: 24),
              Text('Password', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Enter your password')),
              const SizedBox(height: 24),
              Text('Confirm Password', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Confirm your password')),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/email_verification'),
                child: Text('Register', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
