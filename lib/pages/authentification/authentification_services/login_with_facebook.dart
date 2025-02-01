import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Méthode pour se connecter avec Facebook
Future<User?> loginWithFacebook(BuildContext context) async {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  try {
    // 🔹 Initialiser Facebook SDK pour Web
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "618756030871872", // Remplace avec ton Facebook App ID
      cookie: true,
      xfbml: true,
      version: "v16.0",
    );

    final LoginResult loginResult = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (loginResult.status != LoginStatus.success) {
      debugPrint("Connexion Facebook annulée ou échouée.");
      return null;
    }

    final OAuthCredential credential =
    FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

    final UserCredential userCredential =
    await _firebaseAuth.signInWithCredential(credential);

    final User? user = userCredential.user;

    if (user != null) {
      final signInMethods =
      await _firebaseAuth.fetchSignInMethodsForEmail(user.email!);

      if (signInMethods.isEmpty) {
        debugPrint("Utilisateur non trouvé : ${user.email}");
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: "Ce compte n'existe pas.",
        );
      }

      debugPrint("Utilisateur Facebook connecté avec succès : ${user.email}");
      return user;
    }

    return null;
  } catch (e) {
    debugPrint("Erreur inattendue lors de la connexion Facebook : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur lors de la connexion Facebook.")),
    );
    return null;
  }
}