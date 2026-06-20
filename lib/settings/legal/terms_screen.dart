import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '''
Terms & Conditions for BondNex

Last updated: June 2026

1. Agreement to Terms
By accessing or using the BondNex application, you agree to be bound by these Terms and Conditions.

2. User Accounts
You must create an account using Firebase Authentication. You are responsible for safeguarding the password and the one-time passwords you use to access the service.

3. Prohibited Activities
You may not access or use the application for any purpose other than that for which we make it available. Reverse engineering, decompiling, or attempting to extract the source code of the app is strictly prohibited. Security mechanisms such as Root Detection and Emulator blocks are in place to enforce this.

4. E2E Encryption
BondNex provides end-to-end encryption for your messages and call logs. However, you acknowledge that no electronic transmission over the internet or information storage technology can be guaranteed to be 100% secure.

5. Termination
We may terminate or suspend your account and bar access to the application immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.

6. Changes
We reserve the right, at our sole discretion, to modify or replace these Terms at any time.

7. Contact Us
If you have any questions about these Terms, please contact us at support@bondnex.com.
          ''',
          style: TextStyle(color: Colors.grey[300], fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
