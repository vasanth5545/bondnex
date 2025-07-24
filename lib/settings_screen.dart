// File: lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationSwitch = false;
  bool _locationSwitch = false;

  Future<void> _handleLogout() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await FirebaseAuth.instance.signOut();
      await userProvider.clearUserData();

      if (mounted) {
        // ✅ Immediately navigate to login and clear all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Account'),
              _buildSettingsTile(
                icon: Icons.settings_outlined,
                title: 'Account Settings',
                subtitle: 'Manage your account details',
                onTap: () => Navigator.pushNamed(context, '/account_settings'),
              ),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Change Name',
                onTap: () => Navigator.pushNamed(context, '/change_name'),
              ),
              _buildSettingsTile(
                icon: Icons.photo_camera_back_outlined,
                title: 'Profile Photo',
                onTap: () => Navigator.pushNamed(context, '/profile_photo'),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Password',
                onTap: () => Navigator.pushNamed(context, '/password'),
              ),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Appearance'),
              _buildSwitchTile(
                icon: Icons.brightness_6_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Permissions'),
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
                subtitle: 'Enable/Disable push notifications',
                value: _notificationSwitch,
                onChanged: (value) => setState(() => _notificationSwitch = value),
              ),
              _buildSwitchTile(
                icon: Icons.location_on_outlined,
                title: 'Location Settings',
                subtitle: 'Enable/Disable live location sharing',
                value: _locationSwitch,
                onChanged: (value) => setState(() => _locationSwitch = value),
              ),
              _buildSettingsTile(
                icon: Icons.data_usage_outlined,
                title: 'Usage Access',
                subtitle: 'Manage Usage Stats permission',
                onTap: () => Navigator.pushNamed(context, '/usage_access'),
              ),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Security'),
              _buildSettingsTile(
                icon: Icons.phone_android_outlined,
                title: 'Panic Button Settings',
                subtitle: 'Setup or update your emergency contact',
                onTap: () => Navigator.pushNamed(context, '/panic_button_settings'),
              ),
              _buildSettingsTile(
                icon: Icons.phonelink_lock_outlined,
                title: 'Uninstall Lock',
                subtitle: 'Manage or change your OTP Uninstall Lock',
                onTap: () => Navigator.pushNamed(context, '/uninstall_lock'),
              ),
              _buildSettingsTile(icon: Icons.visibility_outlined, title: 'View current lock status', onTap: () {}),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Support'),
              _buildSettingsTile(icon: Icons.help_outline, title: 'FAQ section', onTap: () {}),
              _buildSettingsTile(icon: Icons.headset_mic_outlined, title: 'Contact Support', onTap: () {}),

              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                isLogout: true,
                onTap: _handleLogout,
              ),

              const SizedBox(height: 20),
              Center(child: Text('Version 1.0.0', style: GoogleFonts.poppins(color: Colors.grey[600]))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.redAccent : null),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: isLogout ? Colors.redAccent : null),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            )
          : null,
      trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(color: Colors.grey[500]),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }
}
