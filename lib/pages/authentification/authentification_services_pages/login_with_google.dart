import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hairbnb/pages/profil/profil_creation_page.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../services/providers/current_user_provider.dart';

Future<User?> loginWithGoogle(BuildContext context) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",
    );

    await googleSignIn.signOut(); // 🧼 déconnexion précédente
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      debugPrint("Connexion Google annulée.");
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user == null || !context.mounted) return null;

    final token = await user.getIdToken(); // ✅ token Firebase
    //-------------------------------------------------
    print("TOKEN FIREBASE : $token");
    //------------------------------------------------
    // 🔄 Appel backend sécurisé
    final response = await http.get(
      Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      await userProvider.fetchCurrentUser(); // Met à jour le provider

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (response.statusCode == 404) {
      // 🔁 User existe pas → aller à la page de création de profil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileCreationPage(
            email: user.email ?? '',
            userUuid: user.uid,
          ),
        ),
      );
    } else {
      throw Exception("Erreur backend : ${response.statusCode}");
    }

    return user;
  } catch (e) {
    debugPrint("❌ Erreur Google Sign-In : $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la connexion avec Google.")),
      );
    }

    return null;
  }
}





// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import '../api/api_authentification.dart';
//
// Future<User?> loginWithGoogle(BuildContext context) async {
//   final apiAuth = ApiAuthentification();
//
//   try {
//     // Afficher indicateur de chargement
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );
//
//     // Débuter le processus de connexion Google
//     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//
//     if (googleUser == null) {
//       // L'utilisateur a annulé la connexion
//       Navigator.pop(context);
//       return null;
//     }
//
//     // Obtenir les détails d'authentification
//     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//     // Créer les identifiants Firebase
//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );
//
//     // Connexion à Firebase avec les identifiants Google
//     final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
//
//     // Vérifier avec le backend
//     try {
//       // Faire une requête API pour vérifier l'utilisateur avec votre backend
//       await apiAuth.verifyUser();
//
//       // Fermer l'indicateur de chargement
//       Navigator.pop(context);
//
//       // Rediriger vers la page d'accueil
//       if (context.mounted) {
//         Navigator.pushReplacementNamed(context, '/home');
//       }
//
//       return userCredential.user;
//     } catch (apiError) {
//       // Si l'utilisateur n'existe pas dans votre backend
//       Navigator.pop(context);
//
//       // Afficher une erreur
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Erreur de connexion au serveur: $apiError'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return userCredential.user; // Retourne quand même l'utilisateur pour la création de compte si nécessaire
//     }
//   } catch (e) {
//     // Fermer l'indicateur de chargement
//     Navigator.pop(context);
//
//     // Afficher erreur
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Erreur de connexion Google: $e'), backgroundColor: Colors.red),
//     );
//     return null;
//   }
// }





// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:hairbnb/pages/profil/profil_creation_page.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:provider/provider.dart';
//
// import '../../../services/providers/current_user_provider.dart';
//
// Future<User?> loginWithGoogle(BuildContext context) async {
//   try {
//     final GoogleSignIn googleSignIn = GoogleSignIn(
//       clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",
//     );
//     await googleSignIn.signOut();
//
//     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//
//     if (googleUser == null) {
//       debugPrint("Connexion annulée.");
//       return null;
//     }
//
//     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );
//
//     final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
//     final User? user = userCredential.user;
//
//     if (user == null) return null;
//
//     // // ⚠️ Si l'email N'EST PAS vérifié
//     // if (!user.emailVerified) {
//     //   Navigator.pushReplacement(
//     //     context,
//     //     MaterialPageRoute(
//     //       builder: (_) => EmailNotVerifiedPage(email: user.email ?? ''),
//     //     ),
//     //   );
//     //   return null;
//     // }
//
//     // ✅ Si email vérifié → on check si un profil existe
//     final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     await userProvider.fetchCurrentUser();
//
//     if (context.mounted) {
//       if (userProvider.currentUser != null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const HomePage()),
//         );
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ProfileCreationPage(
//               email: user.email ?? '',
//               userUuid: user.uid,
//             ),
//           ),
//         );
//       }
//     }
//
//     return user;
//   } catch (e) {
//     debugPrint("❌ Erreur Google Sign-In : $e");
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur lors de la connexion avec Google.")),
//       );
//     }
//     return null;
//   }
// }







// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:hairbnb/pages/authentification/authentification_services_pages/sign_up_with_google.dart';
// import 'package:hairbnb/pages/home_page.dart';
//
// /// Méthode pour créer un compte avec Google
// Future<User?> loginWithGoogle(BuildContext context) async {
//   try {
//     // Étape 1 : Déconnecter le compte Google actif pour forcer la sélection d'un compte
//     final GoogleSignIn googleSignIn = GoogleSignIn(clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",);
//     await googleSignIn.signOut();
//
//     // Étape 2 : Démarrer Google Sign-In
//     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//
//     if (googleUser == null) {
//       debugPrint("Connexion annulée par l'utilisateur.");
//       return null;
//     }
//
//     // Étape 3 : Récupérer les informations d'authentification Google
//     final GoogleSignInAuthentication googleAuth = await googleUser
//         .authentication;
//
//     final AuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );
//
//     // Étape 4 : Essayer de se connecter avec Firebase
//     try {
//       final UserCredential userCredential =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//
//       final User? user = userCredential.user;
//
//
//       if (user != null) {
//         debugPrint("Utilisateur connecté avec succès : ${user.email}");
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const HomePage()),
//         );
//         return user;
//       }
//
//       // Vérifie si l'utilisateur existe
//       final List<String> signInMethods =
//       await FirebaseAuth.instance.fetchSignInMethodsForEmail(
//           googleUser.email);
//
//
//       if (signInMethods.isEmpty) {
//         // Aucun compte trouvé : afficher la boîte de dialogue
//
//
//         final bool? createAccount = await _showCreateAccountDialog(
//             context, googleUser.email);
//         if (createAccount == true) {
//           // Créer un nouvel utilisateur avec les credentials Google
//           final UserCredential userCredential =
//           await FirebaseAuth.instance.signInWithCredential(credential);
//
//           debugPrint(
//               "Nouvel utilisateur créé avec succès : ${userCredential.user
//                   ?.email}");
//
//           // Rediriger vers HomePage
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//
//           return userCredential.user;
//         } else {
//           // L'utilisateur a refusé de créer un compte
//           debugPrint("Création de compte refusée.");
//           return null;
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       // Étape 5 : Gestion des erreurs Firebase
//       if (e.code == 'account-exists-with-different-credential') {
//         debugPrint(
//             "Un compte existe avec un autre fournisseur pour cet email.");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text("Ce compte est lié à un autre fournisseur.")),
//         );
//       } else if (e.code == 'user-not-found') {
//         // Aucun compte trouvé : demander à l'utilisateur s'il souhaite créer un compte
//         final bool? createAccount = await _showCreateAccountDialog(
//             context, googleUser.email);
//         if (createAccount == true) {
//           return await signUpWithGoogle(
//               context); // <-- Réessayer la connexion
//         }
//       } else {
//         debugPrint("Erreur Firebase : ${e.message}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : ${e.message}")),
//         );
//       }
//     }
//
//     return null;
//   } catch (e) {
//     debugPrint("Erreur inattendue lors de la connexion Google : $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Erreur lors de la connexion Google.")),
//     );
//     return null;
//   }
// }
//
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

//-------------------------------------------------------------------------------------------