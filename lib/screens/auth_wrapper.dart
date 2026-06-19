// File: lib/auth_wrapper.dart
// UPDATED: This wrapper now consistently directs users to the HomePage.
// The HomePage itself will handle displaying different content based on the login state.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'providers/user_provider.dart';
import 'email_verification_screen.dart'; 

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final firebaseUser = FirebaseAuth.instance.currentUser;

        // First, handle the specific case of a user who has registered but not verified their email.
        if (firebaseUser != null && !firebaseUser.emailVerified) {
          return EmailVerificationScreen(
            name: firebaseUser.displayName ?? '', 
            email: firebaseUser.email!,
          );
        }
        else {
          // For all other cases (both logged-in and logged-out users), show the HomePage.
          // The HomePage will then determine what UI to present.
          return const HomePage();
        }
      },
    );
  }
}
