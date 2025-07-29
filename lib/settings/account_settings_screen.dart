// File: lib/settings/account_settings_screen.dart
// UPDATED: Added the 'Profile Photo' option back into the Personal Information section.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _twoFactorAuth = false;

  void _showDisconnectDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Partner?'),
        content: const Text('This will permanently unlink your current partner. You will need to share your User ID to link with a new partner. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await userProvider.disconnectPartner();
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully disconnected from partner.')),
                );
              } catch (e) {
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final String displayName = userProvider.userName;
        final String displayId = userProvider.myPermanentId;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Account Settings'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Personal Information'),
                  _buildInfoTile(icon: Icons.person_outline, title: 'Name', subtitle: displayName, onTap: () => Navigator.pushNamed(context, '/change_name')),
                  // *** THE FIX IS HERE ***
                  // Profile Photo section ah marubadiyum serthirukkom
                  _buildInfoTile(icon: Icons.camera_alt_outlined, title: 'Profile Photo', onTap: () => Navigator.pushNamed(context, '/profile_photo')),
                  _buildInfoTile(icon: Icons.email_outlined, title: 'Email', subtitle: userProvider.firebaseUid, onTap: () {}),
                  _buildInfoTile(icon: Icons.phone_outlined, title: 'Phone Number', subtitle: 'Not set', onTap: () {}),
                  const SizedBox(height: 10),

                  _buildSectionHeader('Partner Link'),
                  userProvider.isPartnerConnected
                      ? _buildConnectedView(userProvider)
                      : _buildDisconnectedView(userProvider),
                  const SizedBox(height: 10),

                  _buildSectionHeader('Security'),
                  _buildInfoTile(icon: Icons.lock_outline, title: 'Change Password', onTap: () => Navigator.pushNamed(context, '/password')),
                  _buildSwitchTile(
                    icon: Icons.shield_outlined,
                    title: '2FA',
                    value: _twoFactorAuth,
                    onChanged: (value) => setState(() => _twoFactorAuth = value),
                  ),
                  _buildInfoTile(icon: Icons.devices_outlined, title: 'Login Devices', onTap: () {}),
                  const SizedBox(height: 10),

                  _buildSectionHeader('Data & Privacy'),
                  _buildSwitchTile(
                    icon: Icons.history_toggle_off,
                    title: 'Share Call History',
                    subtitle: 'Sync call logs with your partner',
                    value: userProvider.callLogSharingEnabled,
                    onChanged: (value) => userProvider.setCallLogSharing(value),
                  ),
                  _buildInfoTile(icon: Icons.download_outlined, title: 'Download My Data', onTap: () {}),
                  _buildInfoTile(icon: Icons.delete_outline, title: 'Delete Account', isDestructive: true, onTap: () {}),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectedView(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          TextField(
            controller: TextEditingController(text: userProvider.partnerId),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Linked Partner ID',
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: userProvider.partnerId!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partner ID copied to clipboard!')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            child: const Text('Relink Partner'),
          ),
           const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showDisconnectDialog(userProvider),
            child: const Text('Disconnect from Partner', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView(UserProvider userProvider) {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
           TextField(
            controller: TextEditingController(text: userProvider.myPermanentId),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Your Unique User ID',
               suffixIcon: IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: userProvider.myPermanentId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Your User ID copied!')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            child: const Text('Link with a Partner'),
          ),
        ],
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

  Widget _buildInfoTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.redAccent : null),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }
}
