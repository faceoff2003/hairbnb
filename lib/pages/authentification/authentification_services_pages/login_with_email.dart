import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/pages/profil/profil_creation_page.dart';
import '../../../services/providers/current_user_provider.dart';
import 'email_not_verified.dart';

Future<void> loginWithEmail(
    BuildContext context,
    String email,
    String password, {
      TextEditingController? emailController,
      TextEditingController? passwordController,
    }) async {
  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (!context.mounted || user == null) return;

    // Nettoyer les champs
    emailController?.clear();
    passwordController?.clear();

    // ✅ Email vérifié ?
    final creationTime = user.metadata.creationTime;
    final allowBypass = creationTime != null && creationTime.isBefore(DateTime(2025, 4, 10));

    if (!user.emailVerified && !allowBypass) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailNotVerifiedPage(email: user.email!),
        ),
      );
      return;
    }

    // ✅ Récupérer le token Firebase
    final token = await user.getIdToken();

    // ✅ Vérifier sur le backend si le profil existe
    final response = await http.get(
      Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // ✅ User existe dans Django → Aller à la HomePage
      final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      await currentUserProvider.fetchCurrentUser();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (response.statusCode == 404) {
      // ❌ User pas encore créé dans Django → Aller à ProfileCreationPage
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
      throw Exception('Erreur du serveur (${response.statusCode})');
    }
  } on FirebaseAuthException catch (e) {
    final message = switch (e.code) {
      'user-not-found' => "Aucun utilisateur trouvé avec cet email.",
      'wrong-password' => "Mot de passe incorrect.",
      _ => "Erreur : ${e.message}",
    };

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  } catch (e) {
    debugPrint("Erreur inconnue : $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une erreur inattendue s'est produite.")),
      );
    }
  }
}









//-------------------------------Avant firebase auth-------------------------------
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/pages/profil/profil_creation_page.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'email_not_verified.dart';
//
// Future<void> loginWithEmail(
//     BuildContext context,
//     String email,
//     String password, {
//       TextEditingController? emailController,
//       TextEditingController? passwordController,
//     }) async {
//   try {
//     final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//
//     final user = userCredential.user;
//
//     if (!context.mounted || user == null) return;
//
//     // Nettoyer les champs si fournis
//     emailController?.clear();
//     passwordController?.clear();
//
//     // ✅ Autoriser les anciens comptes sans vérification
//     final creationTime = user.metadata.creationTime;
//     final allowBypass = creationTime != null &&
//         creationTime.isBefore(DateTime(2025, 4, 10));
//
//     if (!user.emailVerified && !allowBypass) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => EmailNotVerifiedPage(email: user.email!),
//         ),
//       );
//       return;
//     }
//
//     // ✅ Charger le profil depuis le provider
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     await currentUserProvider.fetchCurrentUser();
//
//     final hasProfile = currentUserProvider.currentUser != null;
//
//     if (hasProfile) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomePage()),
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ProfileCreationPage(
//             email: user.email ?? '',
//             userUuid: user.uid,
//           ),
//         ),
//       );
//     }
//   } on FirebaseAuthException catch (e) {
//     final message = switch (e.code) {
//       'user-not-found' => "Aucun utilisateur trouvé avec cet email.",
//       'wrong-password' => "Mot de passe incorrect.",
//       _ => "Erreur : ${e.message}",
//     };
//
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     }
//   } catch (e) {
//     debugPrint("Erreur inconnue : $e");
//
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Une erreur inattendue s'est produite.")),
//       );
//     }
//   }
// }