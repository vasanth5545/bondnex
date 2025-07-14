import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // This stream listens for changes in the user's login state in real-time.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // If the connection is still loading, show a progress indicator.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the snapshot has data, it means the user is logged in.
        if (snapshot.hasData) {
          // So, show the HomePage.
          return const HomePage();
        }

        // If there's no data, the user is logged out.
        // So, show the LoginScreen.
        return const LoginScreen();
      },
    );
  }
}
