import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '''
Privacy Policy for BondNex

Last updated: June 2026

1. Introduction
Welcome to BondNex. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.

2. Information We Collect
- Device Information (for Runtime Application Self-Protection)
- Firebase Authentication Tokens
- Call History and Contacts (Stored locally and encrypted)

3. How We Use Your Information
We use your information to provide E2E encrypted communication, partner matching, and synchronization.

4. Data Security
BondNex employs AES-256-GCM encryption for all communications and SQLCipher for local data storage to ensure your data remains secure. We do not have access to your private messages or calls.

5. Data Deletion
You can request the deletion of your account and all associated data from the Account Settings menu. This will instantly wipe your data from our servers and your local device.

6. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by updating the new Privacy Policy in this application.

7. Contact Us
If you have any questions about this Privacy Policy, please contact us at security@bondnex.com.
          ''',
          style: TextStyle(color: Colors.grey[300], fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
