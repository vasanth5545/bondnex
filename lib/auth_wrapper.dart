// File: lib/auth_wrapper.dart
// UPDATED: Simplified to rely on the UserProvider's state.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import 'login_screen.dart';
import 'providers/user_provider.dart';
import 'email_verification_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // **THE FIX IS HERE**: Use a Consumer to listen to changes in UserProvider.
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // We also check the firebase auth state to handle the email verification step
        final firebaseUser = FirebaseAuth.instance.currentUser;

        if (userProvider.isLoggedIn) {
          // If the provider says we are logged in, show the main app.
          return const HomePage();
        } else if (firebaseUser != null && !firebaseUser.emailVerified) {
          // If there's a firebase user but they are not verified, show the verification screen.
          return EmailVerificationScreen(
            name: firebaseUser.displayName ?? '', 
            email: firebaseUser.email!,
          );
        }
        else {
          // Otherwise, the user is not logged in, so show the login screen.
          return const LoginScreen();
        }
      },
    );
  }
}
