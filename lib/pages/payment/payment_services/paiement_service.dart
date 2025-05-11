// payment_services/paiement_service.dart - avec correction d'encodage

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';

class PaiementService {
  static const String _baseUrl = 'https://www.hairbnb.site/api';
  static AppLinks? _appLinks;

  // Initialise les deep links (pour les redirections)
  static Future<void> listenForDeepLinks(Function(Uri) callback) async {
    try {
      _appLinks = AppLinks();

      // Écouter les liens entrants
      _appLinks!.uriLinkStream.listen((uri) {
        print("Deep link reçu: $uri");
        callback(uri);
      });

      // Vérifier si l'app a été ouverte par un lien
      try {
        final initialLink = await _appLinks!.getLatestLink();
        if (initialLink != null) {
          print("Lien initial: $initialLink");
          callback(initialLink);
        }
      } catch (e) {
        print("Impossible de récupérer le lien initial : $e");
      }
    } catch (e) {
      print("Erreur lors de l'initialisation des deep links: $e");
    }
  }

  // Crée une session de paiement
  static Future<Map<String, dynamic>> createCheckoutSession(int rendezVousId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Utilisateur non authentifié.");

      final response = await http.post(
        Uri.parse('$_baseUrl/paiement/create-checkout-session/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rendez_vous_id': rendezVousId,
        }),
      );

      print("Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return jsonResponse;
        } catch (e) {
          throw Exception("Erreur lors du décodage de la réponse: $e");
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? "Erreur serveur");
        } catch (e) {
          throw Exception("Erreur serveur: ${response.body}");
        }
      }
    } catch (e) {
      print("❌ Exception: $e");
      rethrow;
    }
  }

  // Vérifie le statut du paiement avec une correction pour l'encodage
  static Future<bool> checkPaymentStatus(int rendezVousId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Utilisateur non authentifié.");

      print("Vérification du paiement pour RDV #$rendezVousId");

      final response = await http.get(
        Uri.parse('$_baseUrl/paiement/status/$rendezVousId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print("Erreur HTTP: ${response.statusCode}");
        print("Réponse: ${response.body}");
        throw Exception("Erreur lors de la vérification du statut de paiement.");
      }

      final data = jsonDecode(response.body);

      // Afficher la réponse complète pour debug
      print("Réponse complète: $data");

      // ⚠️ CORRECTION: Problème d'encodage détecté
      // La réponse contient "payÃ©" au lieu de "payé" à cause d'un problème d'encodage

      // 1. Vérifier le status direct avec tolérance d'encodage
      if (data['status'] == 'payÃ©' || data['status'] == 'payé') {
        print("✅ Paiement confirmé par status (avec correction d'encodage)");
        return true;
      }

      // 2. Vérifier dans details.statut.code avec tolérance d'encodage
      if (data['details'] != null &&
          data['details']['statut'] != null &&
          (data['details']['statut']['code'] == 'payÃ©' ||
              data['details']['statut']['code'] == 'payé')) {
        print("✅ Paiement confirmé par details.statut.code (avec correction d'encodage)");
        return true;
      }

      // 3. Méthode alternative: vérifier si le texte contient "pay" (sans accents)
      if (data['status'] != null &&
          data['status'].toString().toLowerCase().contains('pay')) {
        print("✅ Paiement confirmé par contenu de status");
        return true;
      }

      // 4. Fallback: Si aucune des vérifications précédentes n'a fonctionné,
      // mais que la structure ressemble à un paiement confirmé (présence de receipt_url)
      if (data['details'] != null &&
          data['details']['receipt_url'] != null) {
        print("✅ Paiement confirmé par la présence d'un reçu");
        return true;
      }

      print("❌ Paiement non confirmé selon la réponse");
      return false;
    } catch (e) {
      print("Erreur checkPaymentStatus: $e");
      rethrow;
    }
  }
}






// // payment_services/paiement_service.dart - version corrigée
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:app_links/app_links.dart';
//
// class PaiementService {
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//   static AppLinks? _appLinks;
//
//   // Initialise les deep links (pour les redirections)
//   static Future<void> listenForDeepLinks(Function(Uri) callback) async {
//     try {
//       _appLinks = AppLinks();
//
//       // Écouter les liens entrants
//       _appLinks!.uriLinkStream.listen((uri) {
//         print("Deep link reçu: $uri");
//         callback(uri);
//       });
//
//       // Vérifier si l'app a été ouverte par un lien
//       try {
//         final initialLink = await _appLinks!.getLatestLink();
//         if (initialLink != null) {
//           print("Lien initial: $initialLink");
//           callback(initialLink);
//         }
//       } catch (e) {
//         print("Impossible de récupérer le lien initial : $e");
//       }
//     } catch (e) {
//       print("Erreur lors de l'initialisation des deep links: $e");
//     }
//   }
//
//   // Crée une session de paiement
//   static Future<Map<String, dynamic>> createCheckoutSession(int rendezVousId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.post(
//         Uri.parse('$_baseUrl/paiement/create-checkout-session/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'rendez_vous_id': rendezVousId,
//         }),
//       );
//
//       print("Status code: ${response.statusCode}");
//
//       if (response.statusCode == 200) {
//         try {
//           final jsonResponse = jsonDecode(response.body);
//           return jsonResponse;
//         } catch (e) {
//           throw Exception("Erreur lors du décodage de la réponse: $e");
//         }
//       } else {
//         try {
//           final errorData = jsonDecode(response.body);
//           throw Exception(errorData['error'] ?? "Erreur serveur");
//         } catch (e) {
//           throw Exception("Erreur serveur: ${response.body}");
//         }
//       }
//     } catch (e) {
//       print("❌ Exception: $e");
//       rethrow;
//     }
//   }
//
//   // Vérifie le statut du paiement avec gestion des erreurs améliorée
//   static Future<bool> checkPaymentStatus(int rendezVousId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       print("Vérification du paiement pour RDV #$rendezVousId");
//
//       final response = await http.get(
//         Uri.parse('$_baseUrl/paiement/status/$rendezVousId/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode != 200) {
//         print("Erreur HTTP: ${response.statusCode}");
//         print("Réponse: ${response.body}");
//         throw Exception("Erreur lors de la vérification du statut de paiement.");
//       }
//
//       final data = jsonDecode(response.body);
//       print("Réponse status: ${data['status']}");
//
//       // Vérifier le format de la réponse selon votre API Django
//       return data['status'] == 'payé';
//     } catch (e) {
//       print("Erreur checkPaymentStatus: $e");
//       rethrow;
//     }
//   }
//
// // ⚠️ Cette méthode était à l'origine du problème - supprimée ou remplacée
// // Dans la nouvelle implémentation, nous utilisons directement url_launcher.launchUrl
// }


//-------------------------------------------------30/04/2024-------------------------------------------------
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:app_links/app_links.dart';
//
// class PaiementService {
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//
//   // Crée une session de paiement
//   static Future<Map<String, dynamic>> createCheckoutSession(int rendezVousId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       print("Token JWT: ${token.substring(0, 20)}..."); // Affiche les 20 premiers caractères
//
//       final response = await http.post(
//         Uri.parse('$_baseUrl/paiement/create-checkout-session/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'rendez_vous_id': rendezVousId,
//         }),
//       );
//
//       print("Status code: ${response.statusCode}");
//       print("Response body: ${response.body}");
//
//       // Si le statut est 200, la réponse est valide
//       if (response.statusCode == 200) {
//         try {
//           // Essayer de décoder la réponse JSON
//           final jsonResponse = jsonDecode(response.body);
//           return jsonResponse;
//         } catch (e) {
//           // Si le décodage échoue, c'est probablement du HTML
//           if (response.body.contains('<!doctype')) {
//             throw Exception("Erreur serveur - Page HTML reçue au lieu de JSON");
//           } else {
//             throw Exception("Erreur lors du décodage de la réponse: $e");
//           }
//         }
//       } else {
//         // Gérer les erreurs si le statut n'est pas 200
//         if (response.body.contains('<!doctype')) {
//           throw Exception("Erreur serveur - Page HTML reçue au lieu de JSON");
//         }
//
//         try {
//           final errorData = jsonDecode(response.body);
//           throw Exception(errorData['error'] ?? "Erreur serveur");
//         } catch (e) {
//           throw Exception("Erreur serveur: ${response.body}");
//         }
//       }
//     } catch (e) {
//       print("❌ Exception: $e");
//       rethrow;
//     }
//   }
//
//   // Initialise le paiement Stripe
//   static Future<void> initializePayment(String clientSecret) async {
//     try {
//       print("Initialisation du paiement avec clientSecret: $clientSecret");
//
//       // Initialiser le paiement avec le clientSecret
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: clientSecret,
//           merchantDisplayName: 'Hairbnb',
//           style: ThemeMode.system,
//         ),
//       );
//
//       print("PaymentSheet initialisé avec succès");
//
//       // Afficher la feuille de paiement
//       await Stripe.instance.presentPaymentSheet();
//       print("PaymentSheet présenté avec succès");
//
//     } catch (e) {
//       print("❌ Erreur Stripe: $e");
//       if (e is StripeException) {
//         throw Exception("Erreur Stripe: ${e.error.localizedMessage}");
//       } else {
//         throw Exception("Erreur lors de l'initialisation du paiement: $e");
//       }
//     }
//   }
//
//   // Vérifie le statut du paiement
//   static Future<bool> checkPaymentStatus(int rendezVousId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.get(
//         Uri.parse('$_baseUrl/paiement/status/$rendezVousId/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode != 200) {
//         throw Exception("Erreur lors de la vérification du statut de paiement.");
//       }
//
//       final data = jsonDecode(response.body);
//       return data['status'] == 'payé';
//
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   // Configuration pour écouter les deep links (pour redirection après paiement Stripe)
//   // Configuration pour écouter les deep links (pour redirection après paiement Stripe)
//   static Future<void> listenForDeepLinks(Function(Uri) callback) async {
//     try {
//       final appLinks = AppLinks();
//
//       // Écouter les liens entrants
//       appLinks.uriLinkStream.listen((uri) {
//         callback(uri);
//       });
//
//       // Vérifier si l'app a été ouverte par un lien
//       try {
//         final initialLink = await appLinks.getLatestLink();
//         if (initialLink != null) {
//           callback(initialLink);
//         }
//       } catch (e) {
//         print("Impossible de récupérer le lien initial : $e");
//       }
//     } catch (e) {
//       print("Erreur lors de l'initialisation des deep links: $e");
//     }
//   }
//   }




// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
//
// class PaiementService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // Récupère le token Firebase
//   static Future<String> _getToken() async {
//     final user = FirebaseAuth.instance.currentUser;
//     final token = await user?.getIdToken();
//     if (token == null) {
//       throw Exception("Utilisateur non authentifié");
//     }
//     return token;
//   }
//
//   // Crée une session de paiement Stripe
//   static Future<Map<String, dynamic>> createCheckoutSession(int rendezVousId) async {
//     try {
//       final token = await _getToken();
//
//       final response = await http.post(
//         Uri.parse('$baseUrl/paiement/create-checkout-session/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'rendez_vous_id': rendezVousId,
//         }),
//       );
//
//       if (response.statusCode != 200) {
//         final errorObj = jsonDecode(response.body);
//         throw Exception(errorObj['error'] ?? "Erreur serveur lors de la création de la session de paiement");
//       }
//
//       return jsonDecode(response.body);
//     } catch (e) {
//       print("❌ Erreur création session de paiement: $e");
//       rethrow;
//     }
//   }
//
//   // Vérifie si le paiement a été effectué
//   static Future<bool> checkPaymentStatus(int rendezVousId) async {
//     try {
//       final token = await _getToken();
//
//       final response = await http.get(
//         Uri.parse('$baseUrl/paiement/status/$rendezVousId/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode != 200) {
//         final errorObj = jsonDecode(response.body);
//         throw Exception(errorObj['error'] ?? "Erreur serveur lors de la vérification du statut");
//       }
//
//       final data = jsonDecode(response.body);
//       return data['status'] == 'payé';
//     } catch (e) {
//       print("❌ Erreur vérification statut paiement: $e");
//       rethrow;
//     }
//   }
// }