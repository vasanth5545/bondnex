// File: lib/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedGender;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Name'),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(hintText: 'Enter your name')),
              const SizedBox(height: 24),

              // Gender selection section
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
              const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'Enter your email')),
              const SizedBox(height: 24),
              _buildSectionTitle('Password'),
              const SizedBox(height: 8),
              const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Enter your password')),
              const SizedBox(height: 24),
              _buildSectionTitle('Confirm Password'),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500));
  }

  // **THE FIX IS HERE** - Recoded with more explicit styling for visibility
  Widget _buildGenderButton(String gender) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    bool isSelected = _selectedGender == gender;

    // Define colors and border based on selection and theme
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    if (isSelected) {
      // Styles for the selected button
      backgroundColor = theme.colorScheme.primary.withOpacity(0.2);
      foregroundColor = theme.colorScheme.primary;
      borderSide = BorderSide(color: theme.colorScheme.primary, width: 1.5);
    } else {
      // Styles for the unselected button
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
