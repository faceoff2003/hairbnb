// services/admin_avis_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/admin_avis.dart';
import '../../../../services/firebase_token/token_service.dart';
import '../../../../services/providers/current_user_provider.dart';

class AdminAvisService {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  // 📱 Méthode pour récupérer le token Firebase
  static Future<String?> _getAuthToken() async {
    try {
      final token = await TokenService.getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print("⚠️ Token Firebase non disponible");
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors de la récupération du token: $e");
      }
      return null;
    }
  }

  // 📱 Vérifier que l'utilisateur est admin
  static bool _isAdmin(BuildContext context) {
    try {
      final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      return currentUser?.role?.toLowerCase() == 'admin';
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur vérification admin: $e");
      }
      return false;
    }
  }

  // 🎯 MÉTHODE 1: Lister tous les avis (avec filtres)
  static Future<AdminAvisListeResponse> getAvisAdmin({
    required BuildContext context,
    AdminAvisFilters? filters,
  }) async {
    try {
      if (!_isAdmin(context)) {
        throw Exception("Accès refusé. Droits administrateur requis.");
      }

      if (kDebugMode) {
        print("🔄 Récupération des avis admin...");
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      // Construction de l'URL avec paramètres
      final params = filters?.toUrlParams() ?? {'page': '1', 'page_size': '20'};
      final uri = Uri.parse('$baseUrl/admin/avis/').replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print("📡 API Call: GET $uri");
        print("📡 Statut: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        final adminResponse = AdminAvisListeResponse.fromJson(jsonData);
        if (kDebugMode) {
          print("✅ ${adminResponse.nombreAvis} avis admin récupérés");
        }

        return adminResponse;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Droits administrateur requis.');
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);
        throw Exception(jsonData['message'] ?? 'Erreur lors du chargement des avis');
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans getAvisAdmin: $e");
      }
      rethrow;
    }
  }

  // 🎯 MÉTHODE 2: Supprimer un avis (admin)
  static Future<AdminActionResponse> supprimerAvisAdmin({
    required BuildContext context,
    required int avisId,
  }) async {
    try {
      if (!_isAdmin(context)) {
        throw Exception("Accès refusé. Droits administrateur requis.");
      }

      if (kDebugMode) {
        print("🔄 Suppression admin de l'avis $avisId...");
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/avis/$avisId/supprimer/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print("📡 API Call: DELETE $baseUrl/admin/avis/$avisId/supprimer/");
        print("📡 Statut: ${response.statusCode}");
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(decodedBody);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("✅ Avis supprimé par admin avec succès");
        }
        return AdminActionResponse(
          success: true,
          message: jsonData['message'] ?? 'Avis supprimé avec succès',
        );
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Droits administrateur requis.');
      } else if (response.statusCode == 404) {
        throw Exception('Avis non trouvé');
      } else {
        return AdminActionResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans supprimerAvisAdmin: $e");
      }
      return AdminActionResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // 🎯 MÉTHODE 3: Masquer/Démasquer un avis (admin)
  static Future<AdminActionResponse> modererAvisAdmin({
    required BuildContext context,
    required int avisId,
    required String action, // 'masquer' ou 'visible'
  }) async {
    try {
      if (!_isAdmin(context)) {
        throw Exception("Accès refusé. Droits administrateur requis.");
      }

      if (action != 'masquer' && action != 'visible') {
        throw Exception("Action invalide. Utilisez 'masquer' ou 'visible'");
      }

      if (kDebugMode) {
        print("🔄 Modération admin de l'avis $avisId: $action");
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Token d'authentification manquant");
      }

      final requestBody = {'action': action};

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/avis/$avisId/moderer/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print("📡 API Call: PATCH $baseUrl/admin/avis/$avisId/moderer/");
        print("📤 Body: $requestBody");
        print("📡 Statut: ${response.statusCode}");
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(decodedBody);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("✅ Avis modéré par admin avec succès");
        }
        return AdminActionResponse.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Droits administrateur requis.');
      } else if (response.statusCode == 404) {
        throw Exception('Avis non trouvé');
      } else {
        return AdminActionResponse(
          success: false,
          message: jsonData['message'] ?? 'Erreur lors de la modération',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans modererAvisAdmin: $e");
      }
      return AdminActionResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // 🎯 MÉTHODE 4: Statistiques rapides admin
  static Future<Map<String, int>> getStatistiquesAdmin({
    required BuildContext context,
  }) async {
    try {
      if (!_isAdmin(context)) {
        throw Exception("Accès refusé. Droits administrateur requis.");
      }

      // Récupérer tous les avis (première page pour stats rapides)
      final response = await getAvisAdmin(
        context: context,
        filters: AdminAvisFilters(pageSize: 100), // Plus d'avis pour de meilleures stats
      );

      if (response.success) {
        return response.statistiques;
      } else {
        return {
          'total': 0,
          'visibles': 0,
          'masques': 0,
          'problematiques': 0,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur récupération statistiques: $e");
      }
      return {
        'total': 0,
        'visibles': 0,
        'masques': 0,
        'problematiques': 0,
      };
    }
  }

  // 🎯 MÉTHODE 5: Test de connexion admin
  static Future<bool> testConnexionAdmin(BuildContext context) async {
    try {
      if (!_isAdmin(context)) {
        if (kDebugMode) {
          print("❌ Utilisateur non admin");
        }
        return false;
      }

      if (kDebugMode) {
        print("🧪 Test de connexion admin...");
      }

      final token = await _getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print("❌ Aucun token disponible");
        }
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/avis/?page_size=1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print("📡 Test API Call: GET $baseUrl/admin/avis/?page_size=1");
        print("📡 Test - Statut: ${response.statusCode}");
      }

      if (response.statusCode == 200 || response.statusCode == 403) {
        if (kDebugMode) {
          print("✅ API admin accessible");
        }
        return true;
      } else {
        if (kDebugMode) {
          print("❌ API admin non accessible - Statut: ${response.statusCode}");
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur test connexion admin: $e");
      }
      return false;
    }
  }

  // 🎯 MÉTHODE 6: Actions en lot (future feature)
  static Future<AdminActionResponse> actionEnLot({
    required BuildContext context,
    required List<int> avisIds,
    required String action, // 'supprimer', 'masquer', 'visible'
  }) async {
    try {
      if (!_isAdmin(context)) {
        throw Exception("Accès refusé. Droits administrateur requis.");
      }

      if (kDebugMode) {
        print("🔄 Action en lot: $action sur ${avisIds.length} avis");
      }

      int succes = 0;
      int echecs = 0;
      String dernierErreur = '';

      for (int avisId in avisIds) {
        try {
          AdminActionResponse result;

          if (action == 'supprimer') {
            result = await supprimerAvisAdmin(context: context, avisId: avisId);
          } else {
            result = await modererAvisAdmin(context: context, avisId: avisId, action: action);
          }

          if (result.success) {
            succes++;
          } else {
            echecs++;
            dernierErreur = result.message;
          }
        } catch (e) {
          echecs++;
          dernierErreur = e.toString();
        }

        // Petite pause pour éviter de surcharger l'API
        await Future.delayed(const Duration(milliseconds: 200));
      }

      return AdminActionResponse(
        success: succes > 0,
        message: succes > 0
            ? '$succes avis traités avec succès${echecs > 0 ? ', $echecs échecs' : ''}'
            : 'Aucun avis traité. Dernière erreur: $dernierErreur',
      );
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception dans actionEnLot: $e");
      }
      return AdminActionResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
}