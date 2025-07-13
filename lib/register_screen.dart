// File: lib/register_screen.dart
// Handles new user registration using Firebase and prepares for PHP backend sync.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// A new helper screen to handle the email verification process.
import 'email_verification_screen.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers to manage text field input
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // State variables
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handles the entire registration process.
  Future<void> _handleRegister() async {
    // First, validate the form fields.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create the user with Firebase Authentication.
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // 2. Update the user's display name in Firebase.
        await user.updateDisplayName(_nameController.text.trim());

        // 3. Send the verification email.
        await user.sendEmailVerification();

        // Show a success message to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! A verification link has been sent to your email.'),
            backgroundColor: Colors.green,
          ),
        );

        // 4. Navigate to the verification screen to wait for the user to verify their email.
        // We pass the user details needed for the final PHP registration step.
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                name: _nameController.text.trim(),
                email: user.email!,
                // Note: Passing the password is required for your PHP script.
                // In a more advanced setup, you might use tokens instead.
                password: _passwordController.text.trim(),
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors (e.g., email already in use).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An error occurred.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      // Handle other potential errors.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      // Ensure the loading indicator is turned off.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Enter your name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Gender'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildGenderButton('Boy')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGenderButton('Girl')),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Enter your email'),
                  validator: (value) => value == null || !value.contains('@') ? 'Please enter a valid email' : null,
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Enter your password'),
                  validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Confirm your password'),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500));
  }

  Widget _buildGenderButton(String gender) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    bool isSelected = _selectedGender == gender;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.2);
      foregroundColor = theme.colorScheme.primary;
      borderSide = BorderSide(color: theme.colorScheme.primary, width: 1.5);
    } else {
      backgroundColor = Colors.transparent;
      foregroundColor = isDarkMode ? Colors.white70 : Colors.black54;
      borderSide = BorderSide(color: Colors.grey.withOpacity(0.5), width: 1.5);
    }

    return ElevatedButton(
      onPressed: () => setState(() => _selectedGender = gender),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: borderSide,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        minimumSize: const Size(0, 50),
      ),
      child: Text(gender, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
    );
  }
}
