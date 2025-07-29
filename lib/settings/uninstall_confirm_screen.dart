// File: lib/settings/uninstall_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

class UninstallConfirmScreen extends StatelessWidget {
  const UninstallConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final otpController = TextEditingController();
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.poppins(fontSize: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF2B1B2C), // Custom background from design
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Uninstall',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'To uninstall, an OTP will be sent to your partner.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'Enter OTP',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Verify OTP and proceed with uninstall logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Uninstall'),
              ),
              const SizedBox(height: 16),
              Text(
                'Uninstalling without OTP will send a fear alert to your partner and your data will remain monitored.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[300]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
