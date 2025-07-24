// File: lib/phone/incoming_call_screen.dart
// UPDATED: Fixed layout error by replacing ElevatedButton with FloatingActionButton.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String callerNumber;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  const SizedBox(height: 60),
                  const CircleAvatar(
                    radius: 60,
                    child: Icon(Icons.person, size: 60),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    callerName,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    callerNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ringing...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCallActionButton(
                      label: 'Decline',
                      icon: Icons.call_end,
                      color: Colors.red,
                      onPressed: () => Navigator.pop(context),
                    ),
                    _buildCallActionButton(
                      label: 'Accept',
                      icon: Icons.call,
                      color: Colors.green,
                      onPressed: () {
                        // TODO: Implement accept call logic
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          heroTag: null, // Set heroTag to null to avoid conflicts
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
