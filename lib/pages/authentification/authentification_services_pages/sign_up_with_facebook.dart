// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
//
// /// Méthode pour créer un compte avec Facebook
// Future<User?> signUpWithFacebook(BuildContext context) async {
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//   try {
//     final LoginResult loginResult = await FacebookAuth.instance.login(
//       permissions: ['email', 'public_profile'],
//     );
//
//     if (loginResult.status != LoginStatus.success) {
//       debugPrint("Création de compte Facebook annulée ou échouée.");
//       return null;
//     }
//
//     final OAuthCredential credential =
//     FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
//
//     final UserCredential userCredential =
//     await _firebaseAuth.signInWithCredential(credential);
//
//     final User? user = userCredential.user;
//
//     if (user != null) {
//       debugPrint("Compte Facebook créé avec succès : ${user.email}");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Bienvenue, ${user.email}! Compte créé.")),
//       );
//       return user;
//     }
//
//     return null;
//   } catch (e) {
//     debugPrint("Erreur lors de la création du compte Facebook : $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Erreur lors de la création du compte.")),
//     );
//     return null;
//   }
// }