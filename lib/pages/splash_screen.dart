// lib/pages/splash_screen.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/pages/authentification/login_page.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<User?>? _authSubscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;


  @override
  void initState() {
    super.initState();

    _setupAnimation();
    _navigateAfterDelay();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward(); // Démarre l'animation dès le début
  }

  Future<void> _navigateAfterDelay() async {
    // await Future.delayed(const Duration(seconds: 2));

    // ✅ DÉMARRER immédiatement :
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (!mounted) return;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        try {
          // ✅ CHARGER en parallèle avec l'animation
          await currentUserProvider.fetchCurrentUser();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } catch (e) {
          debugPrint("Erreur lors de fetchCurrentUser: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
          );
          FirebaseAuth.instance.signOut();
        }
      }
    });
  }

  // Future<void> _navigateAfterDelay() async {
  //   await Future.delayed(const Duration(seconds: 2)); // Laisse l'animation jouer
  //   _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
  //     if (!mounted) return;
  //     if (user == null) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => const LoginPage()),
  //       );
  //     } else {
  //       final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
  //       try {
  //         await currentUserProvider.fetchCurrentUser();
  //
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => const HomePage()),
  //         );
  //       } catch (e) {
  //         debugPrint("Erreur lors de fetchCurrentUser: $e");
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
  //         );
  //         FirebaseAuth.instance.signOut();
  //       }
  //     }
  //   });
  // }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cut, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Hairbnb",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}






















//--------------------------------------------l'ajour de chat IA--------------------------------------------------
//
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/pages/authentification/login_page.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:provider/provider.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   StreamSubscription<User?>? _authSubscription;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _setupAnimation();
//     _navigateAfterDelay();
//   }
//
//   void _setupAnimation() {
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
//
//     _animationController.forward(); // Démarre l'animation dès le début
//   }
//
//   Future<void> _navigateAfterDelay() async {
//     await Future.delayed(const Duration(seconds: 2)); // Laisse l'animation jouer
//
//     _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
//       if (!mounted) return;
//       if (user == null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       } else {
//         final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         try {
//           await currentUserProvider.fetchCurrentUser();
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//         } catch (e) {
//           debugPrint("Erreur lors de fetchCurrentUser: $e");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
//           );
//           FirebaseAuth.instance.signOut();
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _authSubscription?.cancel();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.cut, size: 80),
//               const SizedBox(height: 20),
//               const Text(
//                 "Hairbnb",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const CircularProgressIndicator(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }







//-------------------------------------29/04/2025 ajour de l'annimation de demarrage de l'application----------------------------------
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/pages/authentification/login_page.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:provider/provider.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   StreamSubscription<User?>? _authSubscription;
//   //AppLinks? _appLinks;
//   //StreamSubscription<Uri?>? _deepLinkSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _navigateAfterDelay();
//   }
//
//   Future<void> _navigateAfterDelay() async {
//     await Future.delayed(const Duration(seconds: 2)); // Attend 2 secondes
//
//     _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
//       if (!mounted) return;
//       if (user == null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       } else {
//         final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         try {
//           await currentUserProvider.fetchCurrentUser();
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//         } catch (e) {
//           debugPrint("Erreur lors de fetchCurrentUser: $e");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
//           );
//           FirebaseAuth.instance.signOut();
//         }
//       }
//     });
//   }
//
//   // void initState() {
//   //   super.initState();
//   //   // Initialiser le gestionnaire de liens profonds
//   //   //_initDeepLinks();
//   //   _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
//   //     if (!mounted) return;
//   //     if (user == null) {
//   //       // 🔴 Déconnecté → Aller au login
//   //       Navigator.pushReplacement(
//   //         context,
//   //         MaterialPageRoute(builder: (context) => const LoginPage()),
//   //       );
//   //     } else {
//   //       // ✅ Connecté → Charger les données avant d'aller à HomePage
//   //       final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//   //       try {
//   //         await currentUserProvider.fetchCurrentUser();
//   //         Navigator.pushReplacement(
//   //           context,
//   //           MaterialPageRoute(builder: (context) => const HomePage()),
//   //         );
//   //       } catch (e) {
//   //         // En cas d'erreur de récupération de l'utilisateur
//   //         debugPrint("Erreur lors de fetchCurrentUser: $e");
//   //         ScaffoldMessenger.of(context).showSnackBar(
//   //           const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
//   //         );
//   //         FirebaseAuth.instance.signOut(); // Pour forcer retour au login
//   //       }
//   //     }
//   //   });
//   // }
//
//   // Future<void> _initDeepLinks() async {
//   //   _appLinks = AppLinks();
//   //   // Vérifier s'il y a un lien initial
//   //   try {
//   //     final initialUri = await _appLinks!.getInitialLink();
//   //     if (initialUri != null && mounted) {
//   //       debugPrint("Deep link initial: $initialUri");
//   //       // Appel au service de gestion des deep links
//   //       DeepLinkHandlerService.handleDeepLink(context, initialUri);
//   //     }
//   //   } catch (e) {
//   //     debugPrint("Erreur lors de la récupération du lien initial: $e");
//   //   }
//   //
//   //   // Écouter les liens entrants
//   //   _deepLinkSubscription = _appLinks!.uriLinkStream.listen((Uri? uri) {
//   //     if (uri != null && mounted) {
//   //       debugPrint("Deep link reçu: $uri");
//   //       // Appel au service de gestion des deep links
//   //       DeepLinkHandlerService.handleDeepLink(context, uri);
//   //     }
//   //   }, onError: (error) {
//   //     debugPrint("Erreur de deep link: $error");
//   //   });
//   // }
//
//   @override
//   void dispose() {
//     _authSubscription?.cancel();
//     //_deepLinkSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }




// import 'dart:async';
// import 'package:app_links/app_links.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/pages/authentification/login_page.dart';
// import 'package:hairbnb/pages/payment/paiement_error_page.dart';
// import 'package:hairbnb/pages/payment/paiement_sucess_page.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:provider/provider.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   StreamSubscription<User?>? _authSubscription;
//   AppLinks? _appLinks;
//   StreamSubscription<Uri?>? _deepLinkSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialiser le gestionnaire de liens profonds
//     _initDeepLinks();
//
//     _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
//       if (!mounted) return;
//       if (user == null) {
//         // 🔴 Déconnecté → Aller au login
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       } else {
//         // ✅ Connecté → Charger les données avant d'aller à HomePage
//         final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         try {
//           await currentUserProvider.fetchCurrentUser();
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//         } catch (e) {
//           // En cas d'erreur de récupération de l'utilisateur
//           debugPrint("Erreur lors de fetchCurrentUser: $e");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
//           );
//           FirebaseAuth.instance.signOut(); // Pour forcer retour au login
//         }
//       }
//     });
//   }
//
//   Future<void> _initDeepLinks() async {
//     _appLinks = AppLinks();
//
//     // Vérifier s'il y a un lien initial
//     try {
//       final initialUri = await _appLinks!.getInitialLink();
//       if (initialUri != null && mounted) {
//         debugPrint("Deep link initial: $initialUri");
//         _handleDeepLink(initialUri);
//       }
//     } catch (e) {
//       debugPrint("Erreur lors de la récupération du lien initial: $e");
//     }
//
//     // Écouter les liens entrants
//     _deepLinkSubscription = _appLinks!.uriLinkStream.listen((Uri? uri) {
//       if (uri != null && mounted) {
//         debugPrint("Deep link reçu: $uri");
//         _handleDeepLink(uri);
//       }
//     }, onError: (error) {
//       debugPrint("Erreur de deep link: $error");
//     });
//   }
//
//   void _handleDeepLink(Uri uri) {
//     if (uri.scheme == 'hairbnb' && uri.host == 'paiement') {
//       if (uri.path == '/success') {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const PaiementSuccessPage()),
//         );
//       } else if (uri.path == '/echec') {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const PaiementErrorPage()),
//         );
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _authSubscription?.cancel();
//     _deepLinkSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }




// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/pages/authentification/login_page.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:provider/provider.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   StreamSubscription<User?>? _authSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
//       if (!mounted) return;
//
//       if (user == null) {
//         // 🔴 Déconnecté → Aller au login
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       } else {
//         // ✅ Connecté → Charger les données avant d'aller à HomePage
//         final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//
//         try {
//           await currentUserProvider.fetchCurrentUser();
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//         } catch (e) {
//           // En cas d'erreur de récupération de l'utilisateur
//           debugPrint("Erreur lors de fetchCurrentUser: $e");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
//           );
//           FirebaseAuth.instance.signOut(); // Pour forcer retour au login
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _authSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }






// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'authentification/login_page.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   StreamSubscription<User?>? _authSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Abonnement pour écouter les changements d'état utilisateur
//     _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
//       if (!mounted) return; // Vérifie si le widget est toujours monté
//
//       if (user == null) {
//         // L'utilisateur est déconnecté
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       } else {
//         // L'utilisateur est connecté
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const HomePage()),
//         );
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     // Annule l'abonnement pour éviter d'utiliser le context démonté
//     _authSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }






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
