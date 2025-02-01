import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'authentification/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // Abonnement pour écouter les changements d'état utilisateur
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return; // Vérifie si le widget est toujours monté

      if (user == null) {
        // L'utilisateur est déconnecté
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // L'utilisateur est connecté
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    // Annule l'abonnement pour éviter d'utiliser le context démonté
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}






// import 'package:firebase_auth/firebase_auth.dart';

// import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'login_page.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//
//     // Écoute les changements d'état de l'utilisateur
//     FirebaseAuth.instance.authStateChanges().listen((User? user) {
//       if (user == null) {
//         // L'utilisateur est déconnecté ou supprimé, redirige vers LoginPage
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       } else {
//         // L'utilisateur est connecté, redirige vers HomePage
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const HomePage()),
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Affiche un indicateur de chargement pendant la vérification
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }
