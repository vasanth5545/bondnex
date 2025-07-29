// File: lib/app_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'providers/app_lock_provider.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final pinController = TextEditingController();

  void _verifyPin(BuildContext context, String enteredPin) {
    final provider = Provider.of<AppLockProvider>(context, listen: false);
    if (enteredPin == provider.pin) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Please try again.')),
      );
      pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.poppins(fontSize: 22, color: theme.textTheme.bodyLarge?.color),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 60),
              const SizedBox(height: 24),
              Text('Enter PIN to unlock', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 40),
              Pinput(
                length: 4, // Or 6, based on your settings
                controller: pinController,
                obscureText: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                ),
                onCompleted: (pin) => _verifyPin(context, pin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
