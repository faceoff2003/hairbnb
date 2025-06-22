// lib/services/api_service.dart

//==============================================================================
// SERVICE DE CONFIGURATION DES APPELS API
//------------------------------------------------------------------------------
// Ce fichier définit la classe `APIService`, qui centralise la configuration
// nécessaire pour communiquer avec l'API backend du projet HairBNB.
//
// Rôles principaux :
// 1. Fournir l'URL de base de l'API.
// 2. Construire dynamiquement les en-têtes (headers) HTTP pour les requêtes.
// 3. Gérer différents types d'en-têtes :
//    - `headers` : Pour les requêtes authentifiées (avec token JWT).
//    - `headersPublic` : Pour les requêtes publiques (sans token).
//    - `headersBasic` : Pour les cas les plus simples.
//
// L'utilisation de ce service garantit que toutes les requêtes API sont
// cohérentes et incluent des informations importantes comme la version de
// l'application et le token d'authentification lorsque nécessaire.
//==============================================================================

import 'package:package_info_plus/package_info_plus.dart';

// Service pour la gestion du token d'authentification.
import '../firebase_token/token_service.dart';


/// Fournit des configurations centralisées pour les appels à l'API.
class APIService {

  /// L'URL de base pour toutes les requêtes de l'API HairBNB.
  static const String baseURL = 'https://www.hairbnb.site/api';

  /// Construit et retourne les en-têtes HTTP pour les requêtes **authentifiées**.
  ///
  /// Cette méthode asynchrone récupère la version de l'application et le
  /// token d'authentification pour les inclure dans les en-têtes.
  /// Le token n'est ajouté que s'il est disponible.
  static Future<Map<String, String>> get headers async {
    // Récupère les informations du package de l'application (version, etc.).
    final packageInfo = await PackageInfo.fromPlatform();
    // Récupère le token d'authentification stocké localement.
    final token = await TokenService.getAuthToken();

    // Crée une base d'en-têtes commune à la plupart des requêtes.
    final baseHeaders = {
      'Content-Type': 'application/json',
      'X-App-Version': packageInfo.version,
    };

    // Ajoute l'en-tête 'Authorization' conditionnellement.
    // Il n'est inclus que si un token valide a été trouvé.
    if (token != null && token.isNotEmpty) {
      baseHeaders['Authorization'] = 'Bearer $token';
    }

    return baseHeaders;
  }

  /// Construit et retourne les en-têtes HTTP pour les requêtes **publiques**.
  ///
  /// Similaire à `headers`, mais n'inclut jamais le token d'authentification.
  /// Idéal pour les points d'API qui ne nécessitent pas de connexion (ex: login, signup).
  static Future<Map<String, String>> get headersPublic async {
    // Récupère les informations du package pour la version de l'application.
    final packageInfo = await PackageInfo.fromPlatform();

    return {
      'Content-Type': 'application/json',
      'X-App-Version': packageInfo.version,
    };
  }

  /// Retourne un dictionnaire d'en-têtes de base de manière synchrone.
  ///
  /// Utile pour les cas simples où seule la définition du type de contenu
  /// est nécessaire et où une opération asynchrone n'est pas souhaitable.
  static Map<String, String> get headersBasic => {
    'Content-Type': 'application/json',
  };
}