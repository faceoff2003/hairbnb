import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hairbnb/pages/profil/profil_creation_page.dart';

Future<User?> signUpWithGoogle(BuildContext context) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",
    );
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      debugPrint("Création de compte annulée par l'utilisateur.");
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCreationPage(
            email: user.email ?? '',
            userUuid: user.uid,
          ),
        ),
      );
      return user;
    }

    return null;
  } catch (e) {
    debugPrint("Erreur inattendue lors de la création de compte Google : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur lors de la création de compte Google.")),
    );
    return null;
  }
}





// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:hairbnb/pages/home_page.dart';
//
// Future<User?> signUpWithGoogle(BuildContext context) async {
//   try {
//     final GoogleSignIn googleSignIn = GoogleSignIn(clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",);
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