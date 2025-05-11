import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../models/mes_commandes.dart';

class CommandesApiService {
  static const String _baseUrl = 'https://www.hairbnb.site/api';

  // Méthode pour charger les commandes d'un utilisateur
  static Future<List<Commande>> chargerCommandes(int userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Utilisateur non authentifié.");

      final response = await http.get(
        Uri.parse('$_baseUrl/mes-commandes/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        List<Commande> commandes = Commande.fromJsonList(jsonList);

        // Trier les commandes par date (de la plus proche à la plus éloignée)
        final now = DateTime.now();
        commandes.sort((a, b) {
          // Si les deux dates sont dans le futur, on prend la plus proche en premier
          if (a.dateHeure.isAfter(now) && b.dateHeure.isAfter(now)) {
            return a.dateHeure.compareTo(b.dateHeure);
          }
          // Si une date est dans le passé et l'autre dans le futur, la future d'abord
          else if (a.dateHeure.isAfter(now) && b.dateHeure.isBefore(now)) {
            return -1;
          }
          else if (a.dateHeure.isBefore(now) && b.dateHeure.isAfter(now)) {
            return 1;
          }
          // Si les deux sont dans le passé, on montre d'abord la plus récente
          else {
            return b.dateHeure.compareTo(a.dateHeure);
          }
        });

        return commandes;
      } else {
        throw Exception('Erreur lors du chargement des commandes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Autres méthodes API
  static Future<bool> annulerCommande(int commandeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Utilisateur non authentifié.");

      final response = await http.post(
        Uri.parse('$_baseUrl/annuler-commande/$commandeId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  static Future<String> obtenirUrlRecu(int commandeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Utilisateur non authentifié.");

      final response = await http.get(
        Uri.parse('$_baseUrl/recu-commande/$commandeId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['receiptUrl'] ?? '';
      } else {
        throw Exception('Erreur lors de la récupération du reçu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}






// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../models/mes_commandes.dart';
//
// class CommandesApiService {
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//
//   // Méthode pour charger les commandes d'un utilisateur
//   static Future<List<Commande>> chargerCommandes(int userId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.get(
//         Uri.parse('$_baseUrl/mes-commandes/$userId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
//         return Commande.fromJsonList(jsonList);
//       } else {
//         throw Exception('Erreur lors du chargement des commandes: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
//
//   // Autres méthodes API possibles:
//
//   // Méthode pour annuler une commande
//   static Future<bool> annulerCommande(int commandeId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.post(
//         Uri.parse('$_baseUrl/annuler-commande/$commandeId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       throw Exception('Erreur lors de l\'annulation: $e');
//     }
//   }
//
//   // Méthode pour télécharger le reçu d'une commande
//   static Future<String> obtenirUrlRecu(int commandeId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.get(
//         Uri.parse('$_baseUrl/recu-commande/$commandeId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//         return data['receiptUrl'] ?? '';
//       } else {
//         throw Exception('Erreur lors de la récupération du reçu: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
// }