// File: lib/settings_screen.dart
// UPDATED: Changed logout navigation route to '/home' as requested.
// UPDATED: Added a 2-second loading indicator to the logout process for better UX.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'providers/theme_provider.dart'; 
import 'providers/user_provider.dart';
import 'providers/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationSwitch = true;
  bool _locationSwitch = false;
  bool _isLoggingOut = false; // State for logout loading indicator

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Wait for 2 seconds to show loading animation
      await Future.delayed(const Duration(seconds: 2));

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await FirebaseAuth.instance.signOut();
      await userProvider.clearUserData();

      if (mounted) {
        // Navigate back to the home flow and clear all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', // This route points to AuthWrapper which will show HomePage
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Error logging out: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

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
              _buildSectionHeader('Account', theme),
              _buildSettingsTile(
                context: context,
                icon: Icons.person_outline,
                title: 'Account Settings',
                subtitle: 'Manage your account details',
                onTap: () => Navigator.pushNamed(context, '/account_settings'),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.lock_outline,
                title: 'Password',
                subtitle: 'Change your login password',
                onTap: () => Navigator.pushNamed(context, '/password'),
              ),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Appearance', theme),
              _buildSwitchTile(
                context: context,
                icon: theme.brightness == Brightness.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Permissions', theme),
              _buildSwitchTile(
                context: context,
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
                subtitle: 'Enable/Disable push notifications',
                value: _notificationSwitch,
                onChanged: (value) => setState(() => _notificationSwitch = value),
              ),
              _buildSwitchTile(
                context: context,
                icon: Icons.location_on_outlined,
                title: 'Location Settings',
                subtitle: 'Enable/Disable live location sharing',
                value: _locationSwitch,
                onChanged: (value) => setState(() => _locationSwitch = value),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.data_usage_outlined,
                title: 'Usage Access',
                subtitle: 'Manage Usage Stats permission',
                onTap: () => Navigator.pushNamed(context, '/usage_access'),
              ),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Security', theme),
              _buildSettingsTile(
                context: context,
                icon: Icons.phone_android_outlined,
                title: 'Panic Button Settings',
                subtitle: 'Setup your emergency contact',
                onTap: () => Navigator.pushNamed(context, '/panic_button_settings'),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.phonelink_lock_outlined,
                title: 'Uninstall Lock',
                subtitle: 'Prevent unauthorized uninstallation',
                onTap: () => Navigator.pushNamed(context, '/uninstall_lock'),
              ),
              const Divider(indent: 24, endIndent: 24),

              _buildSectionHeader('Support', theme),
              _buildSettingsTile(context: context, icon: Icons.help_outline, title: 'FAQ section', onTap: () {}),
              _buildSettingsTile(context: context, icon: Icons.headset_mic_outlined, title: 'Contact Support', onTap: () {}),

              // Conditional UI for Logout button vs Loading Indicator
              if (_isLoggingOut)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _buildSettingsTile(
                  context: context,
                  icon: Icons.logout,
                  title: 'Logout',
                  isLogout: true,
                  onTap: _handleLogout,
                ),

              const SizedBox(height: 20),
              Center(child: Text('Version 1.0.0', style: theme.textTheme.bodySmall)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final theme = Theme.of(context);
    final color = isLogout ? theme.colorScheme.error : theme.iconTheme.color;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: isLogout ? null : Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color?.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: theme.iconTheme.color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryGreen,
    );
  }
}
