import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login_page.dart';

Future<bool> signUpWithEmail(
    BuildContext context,
    String email,
    String password,
    ) async {
  try {
    final UserCredential userCredential =
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();

      if (!context.mounted) return false;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirme ton adresse e-mail"),
          content: const Text(
              "Un lien de vérification a été envoyé. Clique dessus depuis ta boîte mail."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ferme la popup
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ); // redirige vers Login
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }

    return true;
  } on FirebaseAuthException catch (e) {
    String message = e.message ?? "Une erreur s'est produite";
    debugPrint(message);
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    return false;
  } catch (e) {
    debugPrint("Erreur inconnue : $e");
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Une erreur inattendue est survenue.")),
    );
    return false;
  }
}






// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// Future<bool> signUpWithEmail(
//     BuildContext context,
//     String email,
//     String password,
//     ) async {
//   try {
//     final UserCredential userCredential =
//     await FirebaseAuth.instance.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//
//     final user = userCredential.user;
//     if (user != null && !user.emailVerified) {
//       await user.sendEmailVerification();
//
//       if (!context.mounted) return false;
//
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("Confirme ton adresse e-mail"),
//           content: const Text(
//               "Un lien de vérification a été envoyé. Clique dessus depuis ta boîte mail."),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text("OK"),
//             )
//           ],
//         ),
//       );
//     }
//     return true;
//   } on FirebaseAuthException catch (e) {
//     String message = e.message ?? "Une erreur s'est produite";
//     debugPrint(message);
//     if (!context.mounted) return false;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     return false;
//   } catch (e) {
//     debugPrint("Erreur inconnue : $e");
//     if (!context.mounted) return false;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Une erreur inattendue est survenue.")),
//     );
//     return false;
//   }
// }





// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/profil/profil_creation_page.dart';
//
//
//
//
// final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//
// /// Méthode pour créer un compte avec email et mot de passe
// Future<void> signUpWithEmailAndPassword({
//   required String email,
//   required String password,
//   required BuildContext context,
//   required TextEditingController emailController,
//   required TextEditingController passwordController,
// }) async {
//   try {
//     // Étape 1 : Créer un compte utilisateur dans Firebase Auth
//     UserCredential userCredential = await _firebaseAuth
//         .createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//     debugPrint("Utilisateur créé : ${userCredential.user?.email}");
//     debugPrint("le mp est : $password");
//
//     // Vérifie si le widget est toujours monté avant d'exécuter les actions suivantes
//     if (!context.mounted) return;
//
//     // Étape 2 : Vider les champs après succès
//     emailController.clear();
//     passwordController.clear();
//
//     // Étape 3 : Récupérer l'UID et l'email de l'utilisateur
//     String userUuid = userCredential.user?.uid ?? "";
//     String userEmail = userCredential.user?.email ?? "";
//
//     // Étape 4 : Rediriger vers la page de création de profil
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             ProfileCreationPage(
//               userUuid: userUuid,
//               email: userEmail,
//             ),
//       ),
//     );
//
//     // Vérifie à nouveau si le widget est monté avant d'afficher le SnackBar
//     if (!context.mounted) return;
//
//     // Étape 5 : Confirmation de succès
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Compte créé avec succès pour $userEmail")),
//     );
//   } on FirebaseAuthException catch (e) {
//     // Gestion des erreurs Firebase
//     String message;
//     if (e.code == 'weak-password') {
//       message = "Le mot de passe est trop faible.";
//     } else if (e.code == 'email-already-in-use') {
//       message = "Cet email est déjà utilisé.";
//     } else if (e.code == 'invalid-email') {
//       message = "L'email est invalide.";
//     } else {
//       message = "Erreur : ${e.message}";
//     }
//     debugPrint(message);
//
//     // Vérifie si le widget est toujours monté avant d'afficher l'erreur
//     if (!context.mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)));
//   } catch (e) {
//     // Gestion des erreurs générales
//     debugPrint("Erreur inconnue : $e");
//
//     // Vérifie si le widget est toujours monté avant d'afficher l'erreur
//     if (!context.mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Une erreur inattendue s'est produite.")),
//     );
//   }
// }