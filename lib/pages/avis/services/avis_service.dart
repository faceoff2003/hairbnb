// services/avis_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hairbnb/models/avis.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../models/avis_client.dart';
import '../../../services/providers/current_user_provider.dart';

class AvisService {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  // Méthode pour récupérer le token Firebase via votre TokenService
  static Future<String?> _getAuthToken() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (kDebugMode) {
          print("⚠️ Utilisateur Firebase non connecté");
        }
        return null;
      }

      final token = await firebaseUser.getIdToken(true); // forceRefresh = true
      if (kDebugMode) {
        //print("✅ Token Firebase récupéré (${token?.length} caractères)");
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors de la récupération du token: $e");
      }
      return null;
    }
  }

  // static Future<String?> _getAuthToken() async {
  //   try {
  //     final token = await TokenService.getAuthToken();
  //     if (token == null) {
  //       if (kDebugMode) {
  //         print("⚠️ Token Firebase non disponible");
  //       }
  //     }
  //     return token;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print("❌ Erreur lors de la récupération du token: $e");
  //     }
  //     return null;
  //   }
  // }

  // 📱 Méthode pour récupérer l'UUID via votre CurrentUserProvider
  static String? _getCurrentUserUuid(BuildContext context) {
    try {
      final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser?.uuid != null) {
        return currentUser!.uuid;
      } else {
        if (kDebugMode) {
          print("⚠️ UUID utilisateur non disponible");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors de la récupération de l'UUID: $e");
      }
      return null;
    }
  }

  // 🎯 MÉTHODE 1: Récupérer les RDV éligibles aux avis
  static Future<RdvEligiblesResponse> getRdvEligibles() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      // Vérification du type d'utilisateur
      final userResponse = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(utf8.decode(userResponse.bodyBytes));
        final userType = userData['user']['type'];

        if (userType != 'Client') {
          // Retourner une réponse vide pour les non-clients avec la structure JSON attendue
          final emptyResponse = {
            'success': true,
            'message': 'Aucun RDV éligible pour ce type d\'utilisateur',
            'count': 0,
            'rdv_eligibles': []
          };
          return RdvEligiblesResponse.fromJson(emptyResponse);
        }
      }

      final response = await http.get(
        Uri.parse('$baseUrl/mes-rdv-avis-en-attente/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);
        return RdvEligiblesResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else {
        throw Exception('Erreur lors du chargement des RDV: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }


  // static Future<RdvEligiblesResponse> getRdvEligibles() async {
  //   try {
  //     if (kDebugMode) {
  //       print("🔄 Récupération des RDV éligibles...");
  //     }
  //
  //     final token = await _getAuthToken();
  //     if (token == null) {
  //       throw Exception("Token d'authentification manquant");
  //     }
  //
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/mes-rdv-avis-en-attente/'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //
  //
  //     if (response.statusCode == 200) {
  //       final decodedBody = utf8.decode(response.bodyBytes);
  //       final jsonData = json.decode(decodedBody);
  //
  //       final rdvResponse = RdvEligiblesResponse.fromJson(jsonData);
  //
  //       return rdvResponse;
  //     } else if (response.statusCode == 401) {
  //       if (kDebugMode) {
  //         print("❌ Token expiré ou invalide");
  //       }
  //       throw Exception('Token d\'authentification invalide');
  //     } else {
  //       if (kDebugMode) {
  //         //print("❌ Erreur API: ${response.statusCode} - ${response.body}");
  //       }
  //       throw Exception('Erreur lors du chargement des RDV: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       //print("❌ Exception dans getRdvEligibles: $e");
  //     }
  //     rethrow;
  //   }
  // }

  // 🎯 Compter les avis en attente (pour le badge) - VERSION SIMPLIFIÉE
  static Future<int> getCountAvisEnAttente() async {
    try {
      final rdvResponse = await getRdvEligibles();
      return rdvResponse.count;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors du comptage des avis: $e");
      }
      return 0; // Retourner 0 en cas d'erreur pour éviter de casser l'UI
    }
  }

  // Créer un avis
  static Future<ApiResponse> creerAvis({
    required BuildContext context,
    required int rdvId,
    required int note,
    required String commentaire,
  }) async {
    try {
      if (kDebugMode) {
        print("🔄 Création d'un avis...");
      }

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

      if (kDebugMode) {
        print("📤 Données envoyées: $requestBody");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/avis/creer/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print("📡 API Call: POST $baseUrl/avis/creer/");
      }
      if (kDebugMode) {
        print("📡 Statut de la réponse: ${response.statusCode}");
      }
      if (kDebugMode) {
        print("📄 Corps de la réponse: ${response.body}");
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(decodedBody);

      if (response.statusCode == 201) {
        if (kDebugMode) {
          print("✅ Avis créé avec succès");
        }
        return ApiResponse(
          success: true,
          message: jsonData['message'] ?? 'Avis créé avec succès',
          data: jsonData,
        );
      } else {
        if (kDebugMode) {
          print("❌ Erreur création avis: ${response.statusCode} - $jsonData");
        }
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la création de l\'avis',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans creerAvis: $e");
      }
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Récupérer mes avis donnés
  static Future<List<Avis>> getMesAvis({required BuildContext context}) async {
    try {
      if (kDebugMode) {
        print("🔄 Récupération de mes avis...");
      }

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

      if (kDebugMode) {
        print("📡 API Call: GET $baseUrl/mes-avis/?client_uuid=$userUuid");
      }
      if (kDebugMode) {
        print("📡 Statut de la réponse: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        final avisList = (jsonData['avis'] as List<dynamic>? ?? [])
            .map((avisJson) => Avis.fromJson(avisJson))
            .toList();

        if (kDebugMode) {
          print("✅ ${avisList.length} avis trouvés");
        }
        return avisList;
      } else {
        if (kDebugMode) {
          print("❌ Erreur récupération avis: ${response.statusCode}");
        }
        throw Exception('Erreur lors du chargement des avis');
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans getMesAvis: $e");
      }
      rethrow;
    }
  }

  // Récupérer les avis d'un salon (publics)
  static Future<AvisStatistiques> getAvisSalon(int salonId) async {
    try {
      // if (kDebugMode) {
      //   print("🔄 Récupération des avis du salon $salonId...");
      // }

      final response = await http.get(
        Uri.parse('$baseUrl/salon/$salonId/avis/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (kDebugMode) {
        print("📡 API Call: GET $baseUrl/salon/$salonId/avis/");
      }
      if (kDebugMode) {
        print("📡 Statut de la réponse: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        final avisStats = AvisStatistiques.fromJson(jsonData);
        // if (kDebugMode) {
        //   print("✅ Stats salon: ${avisStats.moyenneFormatee}/5 (${avisStats.totalAvis} avis)");
        // }

        return avisStats;
      } else {
        if (kDebugMode) {
          print("❌ Erreur récupération avis salon: ${response.statusCode}");
        }
        throw Exception('Erreur lors du chargement des avis du salon');
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans getAvisSalon: $e");
      }
      rethrow;
    }
  }

  //Modifier un avis
  static Future<ApiResponse> modifierAvis({
    required BuildContext context,
    required int avisId,
    required int note,
    required String commentaire,
  }) async {
    try {
      if (kDebugMode) {
        print("🔄 Modification de l'avis $avisId...");
      }

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
        'client_uuid': userUuid,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/avis/$avisId/modifier/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print("📡 API Call: PUT $baseUrl/avis/$avisId/modifier/");
      }
      if (kDebugMode) {
        print("📡 Statut de la réponse: ${response.statusCode}");
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(decodedBody);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("✅ Avis modifié avec succès");
        }
        return ApiResponse(
          success: true,
          message: jsonData['message'] ?? 'Avis modifié avec succès',
          data: jsonData,
        );
      } else {
        if (kDebugMode) {
          print("❌ Erreur modification avis: ${response.statusCode}");
        }
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la modification',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans modifierAvis: $e");
      }
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
      if (kDebugMode) {
        print("🔄 Suppression de l'avis $avisId...");
      }

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

      if (kDebugMode) {
        print("📡 API Call: DELETE $baseUrl/avis/$avisId/supprimer/");
      }
      if (kDebugMode) {
        print("📡 Statut de la réponse: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("✅ Avis supprimé avec succès");
        }
        return ApiResponse(
          success: true,
          message: 'Avis supprimé avec succès',
        );
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);
        if (kDebugMode) {
          print("❌ Erreur suppression avis: ${response.statusCode}");
        }
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans supprimerAvis: $e");
      }
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
      if (kDebugMode) {
        print("🧪 Test de connexion à l'API...");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/salon/1/avis/'), // Endpoint public pour tester
        headers: {'Content-Type': 'application/json'},
      );

      if (kDebugMode) {
        print("📡 Test API Call: GET $baseUrl/salon/1/avis/");
      }
      if (kDebugMode) {
        print("📡 Test - Statut: ${response.statusCode}");
      }

      if (response.statusCode == 200 || response.statusCode == 404) {
        if (kDebugMode) {
          print("✅ API accessible");
        }
        return true;
      } else {
        if (kDebugMode) {
          print("❌ API non accessible - Statut: ${response.statusCode}");
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur de connexion API: $e");
      }
      return false;
    }
  }

  /// Test d'authentification
  static Future<bool> testAuthentification() async {
    try {
      if (kDebugMode) {
        print("🧪 Test d'authentification...");
      }

      final token = await _getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print("❌ Aucun token disponible");
        }
        return false;
      }

      if (kDebugMode) {
        print("✅ Token Firebase récupéré (${token.length} caractères)");
      }
      if (kDebugMode) {
        print("🔑 Début du token: ${token.substring(0, 20)}...");
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur test authentification: $e");
      }
      return false;
    }
  }

// Ajouter cette méthode dans AvisService (vers la ligne 400, après supprimerAvis)

  // 👥 Récupérer les avis des clients pour une coiffeuse
  static Future<Map<String, dynamic>> getAvisClientsCoiffeuse({
    required BuildContext context,
    int? noteFiltre,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      if (kDebugMode) {
        print("🔄 Récupération des avis clients pour la coiffeuse...");
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      // Construction de l'URL avec paramètres
      final uri = Uri.parse('$baseUrl/avis-clients-coiffeuse/').replace(
        queryParameters: {
          if (noteFiltre != null) 'note': noteFiltre.toString(),
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print("📡 API Call: GET $uri");
        print("📡 Statut de la réponse: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        // Convertir les avis en utilisant le model AvisClient
        final avisList = (jsonData['avis'] as List<dynamic>? ?? [])
            .map((avisJson) => AvisClient.fromJson(avisJson))
            .toList();

        if (kDebugMode) {
          print("✅ ${avisList.length} avis clients trouvés");
        }

        return {
          'success': true,
          'avis': avisList,
          'salon': jsonData['salon'],
          'pagination': jsonData['pagination'],
        };
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print("⚠️ Aucun salon trouvé pour cette coiffeuse");
        }
        return {
          'success': false,
          'avis': <AvisClient>[],
          'salon': null,
          'message': 'Aucun salon trouvé pour cette coiffeuse',
        };
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);
        if (kDebugMode) {
          print("❌ Erreur récupération avis clients: ${response.statusCode}");
        }
        throw Exception(jsonData['message'] ?? 'Erreur lors du chargement des avis');
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans getAvisClientsCoiffeuse: $e");
      }
      rethrow;
    }
  }

}