import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:hairbnb/pages/home_page.dart';
import '../../pages/profil/profil_creation_page.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;


//----------------------------------------------signInWithGoogle-----------------------------------------------
  // Future<User?> signInWithGoogle(BuildContext context) async {
  //   try {
  //     final GoogleSignIn googleSignIn = GoogleSignIn();
  //     await googleSignIn.signOut();
  //
  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //
  //     if (googleUser == null) {
  //       debugPrint("Création de compte annulée par l'utilisateur.");
  //       return null;
  //     }
  //
  //     final GoogleSignInAuthentication googleAuth = await googleUser
  //         .authentication;
  //
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final UserCredential userCredential =
  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //
  //     final User? user = userCredential.user;
  //
  //     if (user != null) {
  //       debugPrint("Compte créé avec succès : ${user.email}");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Bienvenue, ${user.email}! Compte créé.")),
  //       );
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => const HomePage()),
  //       );
  //       return user;
  //     }
  //
  //     return null;
  //   } catch (e) {
  //     debugPrint("Erreur inattendue lors de la création de compte Google : $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //           content: Text("Erreur lors de la création de compte Google.")),
  //     );
  //     return null;
  //   }
  // }
  //----------------------------------------------Fin de signInWithGoogle---------------------------------------

//   }
// //---------------------------------------------loginWithGoogle------------------------------
//   /// Méthode pour créer un compte avec Google
//   Future<User?> loginWithGoogle(BuildContext context) async {
//     try {
//       // Étape 1 : Déconnecter le compte Google actif pour forcer la sélection d'un compte
//       final GoogleSignIn googleSignIn = GoogleSignIn();
//       await googleSignIn.signOut();
//
//       // Étape 2 : Démarrer Google Sign-In
//       final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//
//       if (googleUser == null) {
//         debugPrint("Connexion annulée par l'utilisateur.");
//         return null;
//       }
//
//       // Étape 3 : Récupérer les informations d'authentification Google
//       final GoogleSignInAuthentication googleAuth = await googleUser
//           .authentication;
//
//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       // Étape 4 : Essayer de se connecter avec Firebase
//       try {
//         final UserCredential userCredential =
//         await FirebaseAuth.instance.signInWithCredential(credential);
//
//         final User? user = userCredential.user;
//
//         // Afficher le UID de l'utilisateur
//         print("++++++++++++++++++++UID de l'utilisateur : ${_firebaseAuth
//             .currentUser?.uid}+++++++++++");
//
//         if (user != null) {
//           debugPrint("Utilisateur connecté avec succès : ${user.email}");
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//           return user;
//         }
//
//         // Vérifie si l'utilisateur existe
//         final List<String> signInMethods =
//         await FirebaseAuth.instance.fetchSignInMethodsForEmail(
//             googleUser.email);
//
//         if (signInMethods.isEmpty) {
//           // Aucun compte trouvé : afficher la boîte de dialogue
//
//           print("++++++++++++++++++++UID de l'utilisateur VIDE : ${_firebaseAuth
//               .currentUser?.uid}+++++++++++");
//
//
//           final bool? createAccount = await _showCreateAccountDialog(
//               context, googleUser.email);
//           if (createAccount == true) {
//             // Créer un nouvel utilisateur avec les credentials Google
//             final UserCredential userCredential =
//             await FirebaseAuth.instance.signInWithCredential(credential);
//
//             debugPrint(
//                 "Nouvel utilisateur créé avec succès : ${userCredential.user
//                     ?.email}");
//
//             // Rediriger vers HomePage
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => const HomePage()),
//             );
//
//             return userCredential.user;
//           } else {
//             // L'utilisateur a refusé de créer un compte
//             debugPrint("Création de compte refusée.");
//             return null;
//           }
//         }
//       } on FirebaseAuthException catch (e) {
//         // Étape 5 : Gestion des erreurs Firebase
//         if (e.code == 'account-exists-with-different-credential') {
//           debugPrint(
//               "Un compte existe avec un autre fournisseur pour cet email.");
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text("Ce compte est lié à un autre fournisseur.")),
//           );
//         } else if (e.code == 'user-not-found') {
//           // Aucun compte trouvé : demander à l'utilisateur s'il souhaite créer un compte
//           final bool? createAccount = await _showCreateAccountDialog(
//               context, googleUser.email);
//           if (createAccount == true) {
//             return await signInWithGoogle(
//                 context); // <-- Réessayer la connexion
//           }
//         } else {
//           debugPrint("Erreur Firebase : ${e.message}");
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Erreur : ${e.message}")),
//           );
//         }
//       }
//
//       return null;
//     } catch (e) {
//       debugPrint("Erreur inattendue lors de la connexion Google : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur lors de la connexion Google.")),
//       );
//       return null;
//     }
//   }
//   //----------------------------------------Fin loginWithGoogle---------------------------------------------------



  // /// Affiche une boîte de dialogue pour demander à l'utilisateur s'il veut créer un compte
  // Future<bool?> _showCreateAccountDialog(BuildContext context,
  //     String email) async {
  //   return showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Compte non trouvé"),
  //         content: Text(
  //             "Aucun compte trouvé pour l'adresse $email. Voulez-vous créer un compte ?"),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("Non"),
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //           ),
  //           TextButton(
  //             child: const Text("Oui"),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }


  // /// Méthode pour créer un compte avec Facebook
  // Future<User?> signInWithFacebook(BuildContext context) async {
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

  /// Méthode pour se connecter avec Facebook
  Future<User?> loginWithFacebook(BuildContext context) async {
    try {
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

  /// Méthode pour se déconnecter de Google
  Future<void> logoutWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      await _firebaseAuth.signOut();
      debugPrint("Utilisateur déconnecté de Google.");
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion Google : $e");
    }
  }

  /// Méthode pour se déconnecter de Facebook
  Future<void> logoutWithFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      await _firebaseAuth.signOut();
      debugPrint("Utilisateur déconnecté de Facebook.");
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion Facebook : $e");
    }
  }

  /// Méthode pour créer un compte avec email et mot de passe
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required BuildContext context,
    required TextEditingController emailController,
    required TextEditingController passwordController,
  }) async {
    try {
      // Étape 1 : Créer un compte utilisateur dans Firebase Auth
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("Utilisateur créé : ${userCredential.user?.email}");
      debugPrint("le mp est : ${password}");

      // Vérifie si le widget est toujours monté avant d'exécuter les actions suivantes
      if (!context.mounted) return;

      // Étape 2 : Vider les champs après succès
      emailController.clear();
      passwordController.clear();

      // Étape 3 : Récupérer l'UID et l'email de l'utilisateur
      String userUuid = userCredential.user?.uid ?? "";
      String userEmail = userCredential.user?.email ?? "";

      // Étape 4 : Rediriger vers la page de création de profil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfileCreationPage(
                userUuid: userUuid,
                email: userEmail,
              ),
        ),
      );

      // Vérifie à nouveau si le widget est monté avant d'afficher le SnackBar
      if (!context.mounted) return;

      // Étape 5 : Confirmation de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Compte créé avec succès pour $userEmail")),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs Firebase
      String message;
      if (e.code == 'weak-password') {
        message = "Le mot de passe est trop faible.";
      } else if (e.code == 'email-already-in-use') {
        message = "Cet email est déjà utilisé.";
      } else if (e.code == 'invalid-email') {
        message = "L'email est invalide.";
      } else {
        message = "Erreur : ${e.message}";
      }
      debugPrint(message);

      // Vérifie si le widget est toujours monté avant d'afficher l'erreur
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)));
    } catch (e) {
      // Gestion des erreurs générales
      debugPrint("Erreur inconnue : $e");

      // Vérifie si le widget est toujours monté avant d'afficher l'erreur
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une erreur inattendue s'est produite.")),
      );
    }
  }

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
}