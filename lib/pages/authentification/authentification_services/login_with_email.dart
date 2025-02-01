import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/home_page.dart';




Future<void> loginUserWithEmailandPassword(String email,
    String password,
    BuildContext context,
    TextEditingController emailController,
    TextEditingController passwordController) async {
  try {
    // Étape 1 : Connexion de l'utilisateur
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint("Utilisateur connecté : ${userCredential.user?.email}");

    // Étape 2 : Vérifie si le widget est encore monté avant d'utiliser le context
    if (!context.mounted) return;

    // Étape 3 : Vider les champs de texte
    emailController.clear();
    passwordController.clear();

    // Étape 4 : Redirection après connexion réussie
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  } on FirebaseAuthException catch (e) {
    // Étape 5 : Gestion des erreurs Firebase
    String message;
    if (e.code == 'user-not-found') {
      message = "Aucun utilisateur trouvé avec cet email.";
    } else if (e.code == 'wrong-password') {
      message = "Mot de passe incorrect.";
    } else {
      message = "Erreur : ${e.message}";
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  } catch (e) {
    debugPrint("Erreur inconnue : $e");

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Une erreur inattendue s'est produite.")),
    );
  }
}