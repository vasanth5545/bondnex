// File: lib/settings/password.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial settings when the page opens
    final provider = Provider.of<AppLockProvider>(context, listen: false);
    provider.loadSettings();
  }
  
  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics(AppLockProvider provider) async {
    try {
      final bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        final bool authenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to enable fingerprint lock',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (authenticated) {
          provider.setFingerprintEnabled(true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to get the latest state from the provider
    return Consumer<AppLockProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('App Lock Settings'),
            centerTitle: true,
          ),
          // **THE FIX IS HERE** - Wrapped with SingleChildScrollView to prevent overflow
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _pinController,
                    decoration: const InputDecoration(hintText: 'Create PIN (4 or 6 digits)'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPinController,
                    decoration: const InputDecoration(hintText: 'Confirm PIN'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Enable App Lock',
                    value: provider.isAppLockEnabled,
                    onChanged: (value) => provider.setAppLockEnabled(value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.fingerprint,
                    title: 'Unlock with Fingerprint',
                    value: provider.isFingerprintEnabled,
                    onChanged: (value) {
                      if (value) {
                        _authenticateWithBiometrics(provider);
                      } else {
                        provider.setFingerprintEnabled(false);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(child: TextButton(onPressed: () {}, child: const Text('Forgot PIN?'))),
                  const SizedBox(height: 24),
                  Text('Auto Lock Timer', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Immediate', '1 min', '5 min'].map((timer) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(timer),
                          selected: provider.autoLockTimer == timer,
                          onSelected: (selected) {
                            if (selected) provider.setAutoLockTimer(timer);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40), // Added space before buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_pinController.text.isNotEmpty && _pinController.text == _confirmPinController.text) {
                              provider.setPin(_pinController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Settings saved!')),
                              );
                              Navigator.of(context).pop();
                            } else if (_pinController.text.isEmpty) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please create a PIN.')),
                              );
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PINs do not match.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile({String? title, IconData? icon, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      title: Text(title!, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      secondary: icon != null ? Icon(icon) : null,
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
