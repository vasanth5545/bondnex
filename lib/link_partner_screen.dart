import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


class LinkPartnerScreen extends StatelessWidget {
  const LinkPartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partnerCodeController = TextEditingController(text: 'A7B3C9X2'); // Example code

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Back arrow venaam, home page-la
        title: Text('Link with your partner', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Generate Code Section
              _buildSectionTitle('Generate a unique partner code'),
              const SizedBox(height: 8),
              Text(
                'Share this code with your partner to link your accounts.',
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: partnerCodeController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: _buildInputDecoration('').copyWith(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: partnerCodeController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied to clipboard!')),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () { /* TODO: Share functionality */ },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Enter Code Section
              _buildSectionTitle("Enter your partner's code"),
              const SizedBox(height: 8),
              Text(
                'If your partner has already generated a code, enter it here.',
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              TextField(decoration: _buildInputDecoration('Enter code')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () { /* TODO: Confirm partner code logic */ },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Confirm', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white));
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: const Color(0xFF1C2C44),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
