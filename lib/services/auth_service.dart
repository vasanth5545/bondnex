import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Unga PHP script URLs-a inga maathikonga
  final String _registerUrl = "https://yourdomain.com/register.php";
  final String _loginUrl = "https://yourdomain.com/login.php";

  // Firebase: Puthu user-a create panni verification email anuppurathu
  Future<User?> registerWithEmailAndPassword(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification();
        debugPrint("Verification email anuppapattathu.");
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase registration thavar: ${e.message}");
      throw Exception(e.message);
    } catch (e) {
      debugPrint("Registration-la ariyaatha thavar: $e");
      throw Exception("Oru ariyaatha thavar erpattathu.");
    }
  }

  // Firebase: Login seivathu
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase login thavar: ${e.message}");
      throw Exception(e.message);
    } catch (e) {
      debugPrint("Login-la ariyaatha thavar: $e");
      throw Exception("Oru ariyaatha thavar erpattathu.");
    }
  }

  // PHP Backend: User-a register seivathu
  Future<void> syncUserWithBackend(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password, // Kurippu: Password-a ipdi anuppurathu paathukaapanathu alla.
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          debugPrint("User PHP backend-la vetrigaramaaga register seiyapattar.");
        } else {
          throw Exception("PHP backend registration tholvi: ${responseData['message']}");
        }
      } else {
        throw Exception("PHP backend-udan inaivathil sikkkal. Status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Backend-udan user-a sync seivathil thavar: $e");
      throw Exception("Server-udan user data-vai sync seiya mudiyavillai.");
    }
  }
}
