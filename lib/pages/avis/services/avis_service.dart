// services/avis_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../../../models/avis.dart';
import '../../../services/firebase_token/token_service.dart';
import '../../../services/providers/current_user_provider.dart';

class AvisService {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  // 📱 Méthode pour récupérer le token Firebase via votre TokenService
  static Future<String?> _getAuthToken() async {
    try {
      final token = await TokenService.getAuthToken();
      if (token == null) {
        print("⚠️ Token Firebase non disponible");
      }
      return token;
    } catch (e) {
      print("❌ Erreur lors de la récupération du token: $e");
      return null;
    }
  }

  // 📱 Méthode pour récupérer l'UUID via votre CurrentUserProvider
  static String? _getCurrentUserUuid(BuildContext context) {
    try {
      final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser?.uuid != null) {
        return currentUser!.uuid;
      } else {
        print("⚠️ UUID utilisateur non disponible");
        return null;
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération de l'UUID: $e");
      return null;
    }
  }

  // 🎯 MÉTHODE 1: Récupérer les RDV éligibles aux avis
  static Future<RdvEligiblesResponse> getRdvEligibles() async {
    try {
      print("🔄 Récupération des RDV éligibles...");

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/mes-rdv-avis-en-attente/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("📡 API Call: GET $baseUrl/mes-rdv-avis-en-attente/");
      print("📡 Statut de la réponse: ${response.statusCode}");
      print("📄 Corps de la réponse: ${response.body}");

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        final rdvResponse = RdvEligiblesResponse.fromJson(jsonData);
        print("✅ ${rdvResponse.count} RDV éligibles trouvés");

        // Log des détails pour debug
        for (var rdv in rdvResponse.rdvEligibles) {
          print("📋 RDV: ${rdv.salonNom} - ${rdv.dateFormatee} - ${rdv.prixFormate}");
        }

        return rdvResponse;
      } else if (response.statusCode == 401) {
        print("❌ Token expiré ou invalide");
        throw Exception('Token d\'authentification invalide');
      } else {
        print("❌ Erreur API: ${response.statusCode} - ${response.body}");
        throw Exception('Erreur lors du chargement des RDV: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Exception dans getRdvEligibles: $e");
      rethrow;
    }
  }

  // 🎯 MÉTHODE 2: Compter les avis en attente (pour le badge) - VERSION SIMPLIFIÉE
  static Future<int> getCountAvisEnAttente() async {
    try {
      final rdvResponse = await getRdvEligibles();
      return rdvResponse.count;
    } catch (e) {
      print("❌ Erreur lors du comptage des avis: $e");
      return 0; // Retourner 0 en cas d'erreur pour éviter de casser l'UI
    }
  }

  // 🎯 MÉTHODE 3: Créer un avis
  static Future<ApiResponse> creerAvis({
    required BuildContext context,
    required int rdvId,
    required int note,
    required String commentaire,
  }) async {
    try {
      print("🔄 Création d'un avis...");

      // Validation des données
      if (note < 1 || note > 5) {
        throw Exception('La note doit être entre 1 et 5');
      }

      if (commentaire.trim().length < 10) {
        throw Exception('Le commentaire doit contenir au moins 10 caractères');
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      final userUuid = _getCurrentUserUuid(context);
      if (userUuid == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Création de l'objet Avis
      final avis = Avis(
        idRendezVous: rdvId,
        note: note,
        commentaire: commentaire.trim(),
      );

      final requestBody = {
        ...avis.toJson(),
        'client_uuid': userUuid, // Pour votre décorateur @is_owner
      };

      print("📤 Données envoyées: $requestBody");

      final response = await http.post(
        Uri.parse('$baseUrl/avis/creer/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("📡 API Call: POST $baseUrl/avis/creer/");
      print("📡 Statut de la réponse: ${response.statusCode}");
      print("📄 Corps de la réponse: ${response.body}");

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(decodedBody);

      if (response.statusCode == 201) {
        print("✅ Avis créé avec succès");
        return ApiResponse(
          success: true,
          message: jsonData['message'] ?? 'Avis créé avec succès',
          data: jsonData,
        );
      } else {
        print("❌ Erreur création avis: ${response.statusCode} - $jsonData");
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la création de l\'avis',
        );
      }
    } catch (e) {
      print("❌ Exception dans creerAvis: $e");
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // 🎯 MÉTHODE 4: Récupérer mes avis donnés
  static Future<List<Avis>> getMesAvis({required BuildContext context}) async {
    try {
      print("🔄 Récupération de mes avis...");

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      final userUuid = _getCurrentUserUuid(context);
      if (userUuid == null) {
        throw Exception("Utilisateur non connecté");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/mes-avis/?client_uuid=$userUuid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("📡 API Call: GET $baseUrl/mes-avis/?client_uuid=$userUuid");
      print("📡 Statut de la réponse: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        final avisList = (jsonData['avis'] as List<dynamic>? ?? [])
            .map((avisJson) => Avis.fromJson(avisJson))
            .toList();

        print("✅ ${avisList.length} avis trouvés");
        return avisList;
      } else {
        print("❌ Erreur récupération avis: ${response.statusCode}");
        throw Exception('Erreur lors du chargement des avis');
      }
    } catch (e) {
      print("❌ Exception dans getMesAvis: $e");
      rethrow;
    }
  }

  // 🎯 MÉTHODE 5: Récupérer les avis d'un salon (publics)
  static Future<AvisStatistiques> getAvisSalon(int salonId) async {
    try {
      print("🔄 Récupération des avis du salon $salonId...");

      final response = await http.get(
        Uri.parse('$baseUrl/salon/$salonId/avis/'),
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 API Call: GET $baseUrl/salon/$salonId/avis/");
      print("📡 Statut de la réponse: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        final avisStats = AvisStatistiques.fromJson(jsonData);
        print("✅ Stats salon: ${avisStats.moyenneFormatee}/5 (${avisStats.totalAvis} avis)");

        return avisStats;
      } else {
        print("❌ Erreur récupération avis salon: ${response.statusCode}");
        throw Exception('Erreur lors du chargement des avis du salon');
      }
    } catch (e) {
      print("❌ Exception dans getAvisSalon: $e");
      rethrow;
    }
  }

  // 🎯 MÉTHODE 6: Modifier un avis
  static Future<ApiResponse> modifierAvis({
    required BuildContext context,
    required int avisId,
    required int note,
    required String commentaire,
  }) async {
    try {
      print("🔄 Modification de l'avis $avisId...");

      // Validation des données
      if (note < 1 || note > 5) {
        throw Exception('La note doit être entre 1 et 5');
      }

      if (commentaire.trim().length < 10) {
        throw Exception('Le commentaire doit contenir au moins 10 caractères');
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      final userUuid = _getCurrentUserUuid(context);
      if (userUuid == null) {
        throw Exception("Utilisateur non connecté");
      }

      final requestBody = {
        'note': note,
        'commentaire': commentaire.trim(),
        'client_uuid': userUuid, // Pour votre décorateur @is_owner
      };

      final response = await http.put(
        Uri.parse('$baseUrl/avis/$avisId/modifier/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("📡 API Call: PUT $baseUrl/avis/$avisId/modifier/");
      print("📡 Statut de la réponse: ${response.statusCode}");

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(decodedBody);

      if (response.statusCode == 200) {
        print("✅ Avis modifié avec succès");
        return ApiResponse(
          success: true,
          message: jsonData['message'] ?? 'Avis modifié avec succès',
          data: jsonData,
        );
      } else {
        print("❌ Erreur modification avis: ${response.statusCode}");
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la modification',
        );
      }
    } catch (e) {
      print("❌ Exception dans modifierAvis: $e");
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // 🎯 MÉTHODE 7: Supprimer un avis
  static Future<ApiResponse> supprimerAvis({
    required BuildContext context,
    required int avisId,
  }) async {
    try {
      print("🔄 Suppression de l'avis $avisId...");

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      final userUuid = _getCurrentUserUuid(context);
      if (userUuid == null) {
        throw Exception("Utilisateur non connecté");
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/avis/$avisId/supprimer/?client_uuid=$userUuid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("📡 API Call: DELETE $baseUrl/avis/$avisId/supprimer/");
      print("📡 Statut de la réponse: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ Avis supprimé avec succès");
        return ApiResponse(
          success: true,
          message: 'Avis supprimé avec succès',
        );
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);
        print("❌ Erreur suppression avis: ${response.statusCode}");
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      print("❌ Exception dans supprimerAvis: $e");
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // 🎯 MÉTHODES DE TEST (conservées)

  /// Test de connexion à l'API
  static Future<bool> testConnexion() async {
    try {
      print("🧪 Test de connexion à l'API...");

      final response = await http.get(
        Uri.parse('$baseUrl/salon/1/avis/'), // Endpoint public pour tester
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Test API Call: GET $baseUrl/salon/1/avis/");
      print("📡 Test - Statut: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 404) {
        print("✅ API accessible");
        return true;
      } else {
        print("❌ API non accessible - Statut: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Erreur de connexion API: $e");
      return false;
    }
  }

  /// Test d'authentification
  static Future<bool> testAuthentification() async {
    try {
      print("🧪 Test d'authentification...");

      final token = await _getAuthToken();
      if (token == null) {
        print("❌ Aucun token disponible");
        return false;
      }

      print("✅ Token Firebase récupéré (${token.length} caractères)");
      print("🔑 Début du token: ${token.substring(0, 20)}...");

      return true;
    } catch (e) {
      print("❌ Erreur test authentification: $e");
      return false;
    }
  }
}