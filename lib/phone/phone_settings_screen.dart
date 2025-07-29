// File: lib/phone/phone_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_helper.dart';
import 'display_options_screen.dart';

class PhoneSettingsScreen extends StatelessWidget {
  const PhoneSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Phone settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Display'),
          _buildSettingsTile(
            context,
            icon: Icons.display_settings,
            title: 'Display options',
            subtitle: 'Theme, sort order',
            onTap: () {
              Navigator.pushNamed(context, '/display_options');
            },
          ),
          _buildSectionHeader('Sound & Vibration'),
          _buildSettingsTile(
            context,
            icon: Icons.volume_up,
            title: 'Sounds and vibration',
            subtitle: 'Ringtone, vibrate for calls',
            onTap: () {},
          ),
          _buildSectionHeader('General'),
          _buildSettingsTile(
            context,
            icon: Icons.block,
            title: 'Blocked numbers',
            subtitle: 'You won\'t receive calls or texts from blocked numbers',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.voicemail,
            title: 'Voicemail',
            subtitle: 'Notifications, advanced settings',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.call_split,
            title: 'Calling accounts',
            subtitle: 'Manage SIM cards and VoIP accounts',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.merge_type,
            title: 'Merge Contacts',
            subtitle: 'Find and merge duplicate contacts',
            onTap: () => Navigator.pushNamed(context, '/merge_contacts'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.grey[400],
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(color: Colors.grey[400]),
      ),
      onTap: onTap,
    );
  }
}
