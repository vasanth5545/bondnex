import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import 'login_screen.dart';
import 'providers/user_provider.dart';
import 'email_verification_screen.dart'; // Import verification screen

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final User user = snapshot.data!;

          // Check if the user's email is verified
          if (user.emailVerified) {
            // If verified, load user data from Firestore
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            return FutureBuilder(
              future: userProvider.loadUserDataFromFirestore(user),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                // After data is loaded, navigate to HomePage
                return const HomePage();
              },
            );
          } else {
            // If not verified, show the verification screen
            return EmailVerificationScreen(name: user.displayName ?? '', email: user.email!);
          }
        }

        // If no user is logged in, show the LoginScreen
        return const LoginScreen();
      },
    );
  }
}
