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
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // If a user is logged in
        if (snapshot.hasData) {
          final User user = snapshot.data!;

          // Check if the user's email is verified
          if (user.emailVerified) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            
            // Use a FutureBuilder to load user data from Firestore
            return FutureBuilder(
              future: userProvider.loadUserDataFromFirestore(user),
              builder: (context, futureSnapshot) {
                // While data is loading, show a progress indicator
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                // **THE FIX IS HERE**: Handle and display specific errors during data loading
                if (futureSnapshot.hasError) {
                  // Print the detailed error to the debug console for more info
                  print("AuthWrapper FutureBuilder Error: ${futureSnapshot.error}");
                  
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 60),
                            const SizedBox(height: 20),
                            const Text(
                              'Failed to Load User Data',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            // Display the actual error message to the user
                            Text(
                              'Error: ${futureSnapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                // Allow the user to retry by rebuilding the FutureBuilder
                                (context as Element).reassemble();
                              },
                              child: const Text('Retry'),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // After data is successfully loaded, navigate to HomePage
                return const HomePage();
              },
            );
          } else {
            // If email is not verified, show the verification screen
            return EmailVerificationScreen(name: user.displayName ?? '', email: user.email!);
          }
        }

        // If no user is logged in, show the LoginScreen
        return const LoginScreen();
      },
    );
  }
}
