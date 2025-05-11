// payment_page.dart - version corrigée

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:hairbnb/pages/payment/payment_services/paiement_service.dart';
import 'package:hairbnb/pages/payment/payment_verification_page.dart';

class PaiementPage extends StatefulWidget {
  final int rendezVousId;

  const PaiementPage({
    required this.rendezVousId,
    super.key,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
  }

  // ⚠️ IMPORTANT: Fonction corrigée pour éviter la récursion infinie
  Future<void> _lancerPaiementStripeCheckout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await PaiementService.createCheckoutSession(widget.rendezVousId);
      final checkoutUrl = response['checkout_url'];

      if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
        throw Exception("URL de paiement manquante.");
      }

      // ⚠️ Utilisation directe de url_launcher sans appeler notre propre fonction
      final uri = Uri.parse(checkoutUrl);

      // CORRECTION: Éviter la récursion en utilisant directement le package
      if (!await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication
      )) {
        throw Exception("Impossible d'ouvrir la page de paiement.");
      }

      // Rediriger vers la page de vérification
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentVerificationPage(
              rendezVousId: widget.rendezVousId,
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Finalisez votre paiement sécurisé",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Redirection en cours..."),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _lancerPaiementStripeCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  "Payer maintenant",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              "Votre paiement est sécurisé via Stripe.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  "Paiement 100% sécurisé",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}






//--------------------------------------30/04/2025-----------------------------------
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import 'payment_services/paiement_service.dart';
//
// class PaiementPage extends StatefulWidget {
//   final int rendezVousId;
//
//   const PaiementPage({
//     required this.rendezVousId,
//     super.key,
//   });
//
//   @override
//   State<PaiementPage> createState() => _PaiementPageState();
// }
//
// class _PaiementPageState extends State<PaiementPage> {
//   bool _isLoading = false;
//   bool _isPaid = false;
//   String _errorMessage = "";
//   Timer? _statusCheckTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     PaiementService.listenForDeepLinks(_handleDeepLink);
//   }
//
//   @override
//   void dispose() {
//     _statusCheckTimer?.cancel();
//     super.dispose();
//   }
//
//   void _handleDeepLink(Uri uri) {
//     if (uri.path.contains('/paiement/success')) {
//       _checkPaymentStatus();
//     } else if (uri.path.contains('/paiement/error')) {
//       setState(() {
//         _errorMessage = "Le paiement a été annulé ou a échoué.";
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _startPaymentStatusCheck() {
//     _checkPaymentStatus();
//     _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
//       _checkPaymentStatus();
//     });
//   }
//
//   Future<void> _checkPaymentStatus() async {
//     try {
//       final isPaid = await PaiementService.checkPaymentStatus(widget.rendezVousId);
//       if (isPaid) {
//         setState(() {
//           _isPaid = true;
//           _isLoading = false;
//         });
//         _statusCheckTimer?.cancel();
//         _showPaymentSuccessDialog();
//       }
//     } catch (e) {
//       print("Erreur statut paiement : $e");
//     }
//   }
//
//   void _showPaymentSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("Paiement réussi"),
//         content: const Text("Votre paiement a bien été confirmé."),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Ferme le dialogue
//               Navigator.of(context).pop(true); // Ferme la page et retourne à l'écran précédent
//             },
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _lancerPaiementStripeCheckout() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = "";
//     });
//
//     try {
//       final response = await PaiementService.createCheckoutSession(widget.rendezVousId);
//       final checkoutUrl = response['checkout_url'];
//
//       if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
//         throw Exception("URL de paiement manquante.");
//       }
//
//       final uri = Uri.parse(checkoutUrl);
//       if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//         throw Exception("Impossible d'ouvrir la page de paiement.");
//       }
//
//       _startPaymentStatusCheck();
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString().replaceAll("Exception: ", "");
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Paiement"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               "Finalisez votre paiement sécurisé",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 32),
//             if (_isPaid)
//               Column(
//                 children: const [
//                   Icon(Icons.check_circle, color: Colors.green, size: 64),
//                   SizedBox(height: 16),
//                   Text("Paiement confirmé", style: TextStyle(fontSize: 18, color: Colors.green)),
//                 ],
//               )
//             else if (_isLoading)
//               const Center(
//                 child: Column(
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text("Redirection en cours..."),
//                   ],
//                 ),
//               )
//             else
//               ElevatedButton(
//                 onPressed: _lancerPaiementStripeCheckout,
//                 child: const Text("Payer maintenant", style: TextStyle(fontSize: 18)),
//               ),
//             if (_errorMessage.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 16),
//                 child: Text(
//                   _errorMessage,
//                   style: const TextStyle(color: Colors.red),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }





// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:url_launcher/url_launcher.dart'; // ✅ Import important
//
// class PaiementPage extends StatefulWidget {
//   final dynamic rendezVousId;
//
//   const PaiementPage({
//     this.rendezVousId,
//     super.key,
//   });
//
//   @override
//   State<PaiementPage> createState() => _PaiementPageState();
// }
//
// class _PaiementPageState extends State<PaiementPage> {
//   bool isLoading = false;
//   String errorMessage = "";
//
//   Future<void> makePayment() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = "";
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       print("✅ Paiement pour rendez-vous ID : ${widget.rendezVousId}");
//
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/paiement/create_checkout_session/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'rendez_vous_id': widget.rendezVousId,
//         }),
//       );
//
//       print("📡 Réponse: ${response.statusCode}");
//       print("📡 Corps: ${response.body}");
//
//       if (response.statusCode != 200) {
//         final errorObj = jsonDecode(response.body);
//         throw Exception(errorObj['error'] ?? "Erreur serveur.");
//       }
//
//       final jsonResponse = jsonDecode(response.body);
//       final checkoutUrl = jsonResponse['checkout_url'];
//
//       if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
//         throw Exception("URL de paiement invalide ou manquante.");
//       }
//
//       final uri = Uri.parse(checkoutUrl);
//       if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//         throw Exception("Impossible d'ouvrir la page de paiement.");
//       }
//
//       print("✅ Redirection vers : $checkoutUrl");
//
//     } catch (e) {
//       print("❌ Erreur paiement : $e");
//       setState(() {
//         errorMessage = e.toString();
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Paiement"),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (isLoading)
//               const CircularProgressIndicator()
//             else
//               ElevatedButton(
//                 onPressed: makePayment,
//                 child: const Text("Procéder au paiement"),
//               ),
//             if (errorMessage.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   errorMessage,
//                   style: const TextStyle(color: Colors.red),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }





// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
//
// import 'package:url_launcher/url_launcher.dart';
//
//
// class PaiementPage extends StatefulWidget {
//   final dynamic rendezVousId;
//   const PaiementPage({
//     this.rendezVousId,
//     super.key
//   });
//   @override
//   State<PaiementPage> createState() => _PaiementPageState();
// }
//
//
//
// class _PaiementPageState extends State<PaiementPage> {
//   bool isLoading = false;
//   String errorMessage = "";
//
//
//   Future<void> makePayment() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = "";
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/paiement/create_checkout_session/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'rendez_vous_id': widget.rendezVousId,
//         }),
//       );
//
//       if (response.statusCode != 200) {
//         final errorObj = jsonDecode(response.body);
//         throw Exception(errorObj['error'] ?? "Erreur serveur.");
//       }
//
//       final jsonResponse = jsonDecode(response.body);
//       final checkoutUrl = jsonResponse['checkout_url'];
//
//       final uri = Uri.parse(checkoutUrl);
//       if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//         throw Exception("Impossible d'ouvrir la page de paiement.");
//       }
//
//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString();
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
// //
// //   Future<void> makePayment() async {
// //     setState(() {
// //       isLoading = true;
// //       errorMessage = "";
// //     });
// //
// //     try {
// //       final user = FirebaseAuth.instance.currentUser;
// //       final token = await user?.getIdToken();
// //       if (token == null) throw Exception("Utilisateur non authentifié.");
// //
// //       // Afficher les informations de débogage pour le rendez-vous ID
// //       print("✅ Tentative de paiement pour le rendez-vous: ${widget.rendezVousId}");
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/paiement/create_checkout_session/'),
// //         headers: {
// //           'Content-Type': 'application/json',
// //           'Authorization': 'Bearer $token',
// //         },
// //         body: jsonEncode({
// //           'rendez_vous_id': widget.rendezVousId,
// //         }),
// //       );
// //
// //       // Afficher la réponse brute pour débogage
// //       print("📡 Statut de la réponse: ${response.statusCode}");
// //       print("📡 Corps de la réponse: ${response.body.substring(0, min(200, response.body.length))}...");
// //
// //       if (response.statusCode != 200) {
// //         // Essayer de décoder la réponse JSON, sinon afficher le texte brut
// //         try {
// //           final errorObj = jsonDecode(response.body);
// //           throw Exception(errorObj['error'] ?? "Erreur serveur: ${response.statusCode}");
// //         } catch (e) {
// //           if (e is FormatException) {
// //             throw Exception("Réponse invalide du serveur (${response.statusCode}). Veuillez contacter le support.");
// //           } else {
// //             rethrow;
// //           }
// //         }
// //       }
// //
// //       try {
// //         final jsonResponse = jsonDecode(response.body);
// //         final checkoutUrl = jsonResponse['checkout_url'];
// //
// //         if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
// //           throw Exception("URL de paiement invalide ou manquante");
// //         }
// //
// //         // Redirection vers l'URL de paiement
// //         if (kIsWeb) {
// //           html.window.open(checkoutUrl, '_blank');
// //         } else {
// //           final uri = Uri.parse(checkoutUrl);
// //           if (await canLaunchUrl(uri)) {
// //             await launchUrl(uri, mode: LaunchMode.externalApplication);
// //           } else {
// //             throw Exception("Impossible d'ouvrir l'URL de paiement.");
// //           }
// //         }
// //
// //
// //         print("✅ Redirection vers l'URL de paiement: $checkoutUrl");
// //       } catch (e) {
// //         if (e is FormatException) {
// //           throw Exception("Réponse invalide du serveur. La réponse n'est pas au format JSON.");
// //         } else {
// //           rethrow;
// //         }
// //       }
// //     } catch (e) {
// //       print("❌ Erreur paiement web : $e");
// //       setState(() {
// //         errorMessage = e.toString();
// //       });
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Paiement"),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (isLoading)
//               const CircularProgressIndicator()
//             else
//               ElevatedButton(
//                 onPressed: makePayment,
//                 child: const Text("Procéder au paiement"),
//               ),
//             if (errorMessage.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   errorMessage,
//                   style: const TextStyle(color: Colors.red),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Fonction utilitaire pour éviter les erreurs de longueur
// int min(int a, int b) {
//   return a < b ? a : b;
// }

  // Future<void> makePayment() async {
  //   setState(() => isLoading = true);
  //
  //   try {
  //     // Vibration de confirmation
  //     HapticFeedback.lightImpact();
  //
  //     // 🔐 Récupération du token Firebase
  //     final user = FirebaseAuth.instance.currentUser;
  //     final token = await user?.getIdToken();
  //     if (token == null) {
  //       throw Exception("Utilisateur non authentifié.");
  //     }
  //
  //     // 🧾 Récupération du user_id (idTblUser) via Provider
  //     final currentUser = Provider.of<CurrentUserProvider>(context, listen: false);
  //     final userId = currentUser.currentUser?.idTblUser;
  //     if (userId == null) {
  //       throw Exception("ID utilisateur non disponible.");
  //     }
  //
  //     // Vérifier si l'ID du rendez-vous est disponible
  //     final rendezVousId = widget.rendezVousId ?? 1; // Utiliser la valeur par défaut si non spécifiée
  //
  //     print("🔄 Création du paiement pour le rendez-vous ID: $rendezVousId");
  //
  //     // 1. Créer le PaymentIntent depuis le backend
  //     final response = await http.post(
  //       Uri.parse('https://www.hairbnb.site/api/paiement/create_payment_intent/'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: json.encode({
  //         'rendez_vous_id': rendezVousId,
  //         'methode_paiement': 'carte',
  //         'user_id': userId,
  //       }),
  //     );
  //
  //     if (response.statusCode != 200) {
  //       throw Exception(json.decode(response.body)['error'] ?? "Erreur lors de la création du paiement");
  //     }
  //
  //     final jsonResponse = json.decode(response.body);
  //     final clientSecret = jsonResponse['clientSecret'];
  //
  //     if (clientSecret == null) {
  //       throw Exception("Client secret non reçu du serveur");
  //     }
  //
  //     print("✅ PaymentIntent créé avec succès");
  //
  //     // 2. Initier le paiement
  //     await Stripe.instance.initPaymentSheet(
  //       paymentSheetParameters: SetupPaymentSheetParameters(
  //         paymentIntentClientSecret: clientSecret,
  //         style: ThemeMode.light,
  //         merchantDisplayName: 'Hairbnb',
  //         googlePay: PaymentSheetGooglePay(
  //           merchantCountryCode: 'FR',
  //           currencyCode: 'EUR',
  //           testEnv: true,
  //         ),
  //       ),
  //     );
  //
  //     print("✅ Feuille de paiement initialisée");
  //
  //     // 3. Afficher la feuille de paiement
  //     await Stripe.instance.presentPaymentSheet();
  //
  //     print("✅ Paiement effectué avec succès");
  //
  //     // Vibration de succès
  //     HapticFeedback.mediumImpact();
  //
  //     // 4. Afficher le message de succès et retourner à la page précédente
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Paiement réussi ✅"),
  //         backgroundColor: Colors.green,
  //         duration: Duration(seconds: 2),
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //         margin: EdgeInsets.all(10),
  //       ),
  //     );
  //
  //     // Afficher une boîte de dialogue de confirmation
  //     await showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => AlertDialog(
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //         content: Container(
  //           height: 220,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               CircleAvatar(
  //                 radius: 40,
  //                 backgroundColor: Colors.green.shade100,
  //                 child: Icon(
  //                   Icons.check,
  //                   size: 45,
  //                   color: Colors.green,
  //                 ),
  //               ),
  //               SizedBox(height: 20),
  //               Text(
  //                 "Paiement confirmé !",
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               SizedBox(height: 10),
  //               Text(
  //                 "Merci pour votre réservation",
  //                 style: TextStyle(
  //                   color: Colors.grey.shade700,
  //                 ),
  //               ),
  //               SizedBox(height: 25),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   Navigator.pop(context);
  //                   Navigator.pop(context); // Retourner à l'écran principal
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.green,
  //                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  //                 ),
  //                 child: Text("Parfait !"),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //
  //   } catch (e) {
  //     // Vibration d'erreur
  //     HapticFeedback.heavyImpact();
  //
  //     print("❌ Erreur de paiement : $e");
  //
  //     String errorMessage = "Erreur de paiement";
  //     if (e is StripeException) {
  //       errorMessage = e.error.localizedMessage ?? "Erreur Stripe";
  //     }
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(errorMessage),
  //         backgroundColor: Colors.red,
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //         margin: EdgeInsets.all(10),
  //         duration: Duration(seconds: 3),
  //       ),
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() => isLoading = false);
  //     }
  //   }
  // }

//   @override
//   void initState() {
//     super.initState();
//     // Démarrer automatiquement le processus de paiement après un court délai
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Future.delayed(Duration(milliseconds: 500), () {
//         if (mounted) {
//           makePayment();
//         }
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Paiement"),
//         backgroundColor: Colors.orange.shade700,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.orange.shade50, Colors.white],
//           ),
//         ),
//         child: Center(
//           child: isLoading
//               ? Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 "Préparation du paiement...",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               )
//             ],
//           )
//               : Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.payment_rounded,
//                 size: 80,
//                 color: Colors.deepOrange,
//               ),
//               SizedBox(height: 20),
//               Text(
//                 "Prêt pour le paiement",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: makePayment,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.deepOrange,
//                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                 ),
//                 child: Text(
//                   "Payer maintenant",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }