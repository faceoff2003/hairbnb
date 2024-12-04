import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/home_page.dart';

import '../../pages/profil/profil_creation_page.dart';

class AuthService {
  static get http => null;

  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authentifiez-vous avec Firebase
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userUuid = user.uid; // Firebase UID
        final email = user.email ?? "";

        // Vérifie si le profil existe dans PostgreSQL
        final bool hasProfile = await _checkUserProfile(userUuid);

        if (hasProfile) {
          // Rediriger vers la page d'accueil si le profil existe
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Rediriger vers la page de création de profil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileCreationPage(
                userUuid: userUuid,
                email: email,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la connexion Google : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la connexion Google")),
      );
    }
  }

  // Méthode pour vérifier si le profil existe dans la base PostgreSQL
  static Future<bool> _checkUserProfile(String userUuid) async {
    final url = Uri.parse("http://192.168.0.202:8000/api/check-user-profile/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userUuid": userUuid}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'exists'; // Retourne 'true' si le profil existe
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification du profil : $e");
    }
    return false; // Par défaut, retourne 'false'
  }
}