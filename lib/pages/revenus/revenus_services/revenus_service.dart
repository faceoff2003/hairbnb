// lib/services/revenus_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hairbnb/models/revenus_model.dart';
import 'package:http/http.dart' as http;
import '../../../services/firebase_token/token_service.dart';

class RevenusService {
  static const String _baseUrl = "https://www.hairbnb.site";
  static const String _baseEndpoint = '/api/revenus_coiffeuse/';

  /// Récupère les revenus d'une coiffeuse selon les filtres spécifiés
  ///
  /// [periode] : Type de période ("jour", "semaine", "mois", "annee", "custom")
  /// [dateDebut] : Date de début (obligatoire si periode = "custom")
  /// [dateFin] : Date de fin (obligatoire si periode = "custom")
  /// [salonId] : ID du salon (optionnel)
  ///
  /// Retourne [RevenusCoiffeuseModel] en cas de succès ou [RevenusErrorModel] en cas d'erreur
  static Future<dynamic> getRevenusCoiffeuse({
    PeriodeRevenu periode = PeriodeRevenu.mois,
    DateTime? dateDebut,
    DateTime? dateFin,
    int? salonId,
  }) async {
    try {
      // Construction des paramètres de requête
      Map<String, String> queryParams = {
        'periode': periode.value,
      };

      // Ajout des dates si période custom
      if (periode == PeriodeRevenu.custom) {
        if (dateDebut == null || dateFin == null) {
          return RevenusErrorModel(
              success: false,
              error: 'Les dates de début et fin sont obligatoires pour une période personnalisée'
          );
        }
        queryParams['date_debut'] = _formatDate(dateDebut);
        queryParams['date_fin'] = _formatDate(dateFin);
      } else {
        // Ajout optionnel des dates pour override
        if (dateDebut != null) {
          queryParams['date_debut'] = _formatDate(dateDebut);
        }
        if (dateFin != null) {
          queryParams['date_fin'] = _formatDate(dateFin);
        }
      }

      // Ajout du salon si spécifié
      if (salonId != null) {
        queryParams['salon_id'] = salonId.toString();
      }

      // Construction de l'URL complète
      String url = _buildUrl(_baseEndpoint, queryParams);

      // Récupération du token d'authentification Firebase
      String? token = await TokenService.getAuthToken();
      if (token == null) {
        return RevenusErrorModel(
            success: false,
            error: 'Token d\'authentification manquant. Veuillez vous reconnecter.'
        );
      }

      // Headers de la requête
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Exécution de la requête GET avec timeout de 10 secondes (comme CurrentUserProvider)
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps (>10s)');
        },
      );

      // Traitement de la réponse
      return _handleResponse(response);

    } catch (e) {
      // Gestion des erreurs de réseau (comme CurrentUserProvider)
      if (kDebugMode) {
        print("❌ Erreur RevenusService : $e");
      }
      return RevenusErrorModel(
          success: false,
          error: 'Erreur de connexion: ${e.toString()}'
      );
    }
  }

  /// Récupère les revenus pour une période prédéfinie (méthode raccourcie)
  static Future<dynamic> getRevenusParPeriode(PeriodeRevenu periode) {
    return getRevenusCoiffeuse(periode: periode);
  }

  /// Récupère les revenus pour une période personnalisée (méthode raccourcie)
  static Future<dynamic> getRevenusPersonnalises({
    required DateTime dateDebut,
    required DateTime dateFin,
    int? salonId,
  }) {
    return getRevenusCoiffeuse(
      periode: PeriodeRevenu.custom,
      dateDebut: dateDebut,
      dateFin: dateFin,
      salonId: salonId,
    );
  }

  /// Récupère les revenus d'aujourd'hui
  static Future<dynamic> getRevenusAujourdhui() {
    return getRevenusCoiffeuse(periode: PeriodeRevenu.jour);
  }

  /// Récupère les revenus de cette semaine
  static Future<dynamic> getRevenusSemaine() {
    return getRevenusCoiffeuse(periode: PeriodeRevenu.semaine);
  }

  /// Récupère les revenus de ce mois
  static Future<dynamic> getRevenusMois() {
    return getRevenusCoiffeuse(periode: PeriodeRevenu.mois);
  }

  /// Récupère les revenus de cette année
  static Future<dynamic> getRevenusAnnee() {
    return getRevenusCoiffeuse(periode: PeriodeRevenu.annee);
  }

  // MÉTHODES UTILITAIRES PRIVÉES

  /// Formate une date au format YYYY-MM-DD attendu par l'API
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Construit l'URL complète avec les paramètres de requête
  static String _buildUrl(String endpoint, Map<String, String> queryParams) {
    String baseUrl = _baseUrl + endpoint;

    if (queryParams.isNotEmpty) {
      String query = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      baseUrl += '?$query';
    }

    return baseUrl;
  }

  //------------------------------------------------------------------------------------
  // Ajoutez ces logs dans votre _handleResponse dans revenus_service.dart

  static dynamic _handleResponse(http.Response response) {
    try {
      // 🔥 LOGS DE DEBUG - À AJOUTER TEMPORAIREMENT
      // if (kDebugMode) {
      //   print("📥 Status Code: ${response.statusCode}");
      //   print("📥 Response Body COMPLET: ${response.body}");
      // }

      // Décodage UTF-8 comme CurrentUserProvider
      final decodedBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonData = json.decode(decodedBody);

      switch (response.statusCode) {
        case 200:
        // Succès - parsing du modèle de revenus
          return RevenusCoiffeuseModel.fromJson(jsonData);

        case 400:
        // Erreur de validation - parsing du modèle d'erreur
          return RevenusErrorModel.fromJson(jsonData);

        case 401:
        // Non autorisé
          return RevenusErrorModel(
              success: false,
              error: 'Authentification requise. Veuillez vous reconnecter.'
          );

        case 403:
        // Accès interdit
          return RevenusErrorModel(
              success: false,
              error: 'Accès non autorisé. Cette fonctionnalité est réservée aux propriétaires de salon.'
          );

        case 404:
        // Ressource non trouvée
          return RevenusErrorModel(
              success: false,
              error: 'Service non disponible. Veuillez réessayer plus tard.'
          );

        case 500:
        // // Erreur serveur - 🔥 AFFICHER LE JSON D'ERREUR
        //   if (kDebugMode) {
        //     print("🚨 Erreur 500 - JSON reçu: $jsonData");
        //   }
          return RevenusErrorModel(
              success: false,
              error: 'Erreur serveur. Veuillez réessayer plus tard.'
          );

        default:
        // Autres codes d'erreur
          return RevenusErrorModel(
              success: false,
              error: 'Erreur inattendue (${response.statusCode}): ${jsonData['error'] ?? 'Erreur inconnue'}'
          );
      }
    } catch (e) {
      // // Erreur de parsing JSON
      // if (kDebugMode) {
      //   print("🚨 Erreur de parsing JSON: $e");
      //   print("🚨 Response brute: ${response.body}");
      // }
      return RevenusErrorModel(
          success: false,
          error: 'Erreur de traitement des données: ${e.toString()}'
      );
    }
  }
//-----------------------------------------------------------------------------------------
  /// Traite la réponse HTTP et retourne le modèle approprié

  // static dynamic _handleResponse(http.Response response) {
  //   try {
  //     // Décodage UTF-8 comme CurrentUserProvider
  //     final decodedBody = utf8.decode(response.bodyBytes);
  //     Map<String, dynamic> jsonData = json.decode(decodedBody);
  //
  //     switch (response.statusCode) {
  //       case 200:
  //       // Succès - parsing du modèle de revenus
  //         return RevenusCoiffeuseModel.fromJson(jsonData);
  //
  //       case 400:
  //       // Erreur de validation - parsing du modèle d'erreur
  //         return RevenusErrorModel.fromJson(jsonData);
  //
  //       case 401:
  //       // Non autorisé
  //         return RevenusErrorModel(
  //             success: false,
  //             error: 'Authentification requise. Veuillez vous reconnecter.'
  //         );
  //
  //       case 403:
  //       // Accès interdit
  //         return RevenusErrorModel(
  //             success: false,
  //             error: 'Accès non autorisé. Cette fonctionnalité est réservée aux propriétaires de salon.'
  //         );
  //
  //       case 404:
  //       // Ressource non trouvée
  //         return RevenusErrorModel(
  //             success: false,
  //             error: 'Service non disponible. Veuillez réessayer plus tard.'
  //         );
  //
  //       case 500:
  //       // Erreur serveur
  //         return RevenusErrorModel(
  //             success: false,
  //             error: 'Erreur serveur. Veuillez réessayer plus tard.'
  //         );
  //
  //       default:
  //       // Autres codes d'erreur
  //         return RevenusErrorModel(
  //             success: false,
  //             error: 'Erreur inattendue (${response.statusCode}): ${jsonData['error'] ?? 'Erreur inconnue'}'
  //         );
  //     }
  //   } catch (e) {
  //     // Erreur de parsing JSON
  //     return RevenusErrorModel(
  //         success: false,
  //         error: 'Erreur de traitement des données: ${e.toString()}'
  //     );
  //   }
  // }
}

// CLASSES UTILITAIRES POUR LA GESTION DES ERREURS

/// Exception personnalisée pour les erreurs de revenus
class RevenusException implements Exception {
  final String message;
  final int? statusCode;

  RevenusException(this.message, [this.statusCode]);

  @override
  String toString() => 'RevenusException: $message';
}

/// Wrapper pour les résultats d'API avec gestion d'erreur typée
class RevenusResult<T> {
  final T? data;
  final RevenusErrorModel? error;
  final bool isSuccess;

  RevenusResult.success(this.data)
      : error = null,
        isSuccess = true;

  RevenusResult.failure(this.error)
      : data = null,
        isSuccess = false;

  /// Helper pour vérifier si le résultat contient des données valides
  bool get hasData => isSuccess && data != null;

  /// Helper pour vérifier si le résultat contient une erreur
  bool get hasError => !isSuccess && error != null;
}