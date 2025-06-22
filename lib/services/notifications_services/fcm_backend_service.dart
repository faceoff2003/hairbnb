import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class FCMBackendService {
  static const String baseUrl = "https://www.hairbnb.site";

  /// 📤 Envoie le token FCM au backend Django
  static Future<bool> sendTokenToBackend(String fcmToken) async {
    if (kDebugMode) {
      print("📤 [FCMBackendService] === DÉBUT ENVOI TOKEN AU BACKEND ===");
      print("📤 [FCMBackendService] Token à envoyer (20 chars): ${fcmToken.substring(0, 20)}...");
    }

    try {
      // Vérifier l'authentification Firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (kDebugMode) {
          print("❌ [FCMBackendService] Utilisateur Firebase non connecté");
        }
        return false;
      }

      if (kDebugMode) {
        print("👤 [FCMBackendService] Utilisateur Firebase connecté: ${firebaseUser.uid}");
        print("📧 [FCMBackendService] Email utilisateur: ${firebaseUser.email}");
      }

      // Récupérer le token d'authentification
      if (kDebugMode) {
        print("🔑 [FCMBackendService] Récupération du token d'authentification...");
      }

      final authToken = await firebaseUser.getIdToken();

      if (kDebugMode) {
        print("🔑 [FCMBackendService] Token auth récupéré (20 chars): ${authToken?.substring(0, 20)}...");
      }

      // Préparer la requête
      final url = '$baseUrl/api/fcm/save-token/';
      final headers = {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      };
      final body = json.encode({
        'token': fcmToken,
      });

      if (kDebugMode) {
        print("🌐 [FCMBackendService] URL: $url");
        print("📋 [FCMBackendService] Headers: $headers");
        print("📄 [FCMBackendService] Body: $body");
      }

      // Envoyer la requête
      if (kDebugMode) {
        print("📡 [FCMBackendService] Envoi de la requête HTTP...");
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 15));

      if (kDebugMode) {
        print("📡 [FCMBackendService] Réponse reçue:");
        print("📡 [FCMBackendService] Status code: ${response.statusCode}");
        print("📡 [FCMBackendService] Headers réponse: ${response.headers}");
        print("📡 [FCMBackendService] Body réponse: ${response.body}");
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (kDebugMode) {
            print("✅ [FCMBackendService] Token FCM envoyé au backend avec succès");
            print("✅ [FCMBackendService] Réponse parsée: $responseData");
          }
          return true;
        } catch (jsonError) {
          if (kDebugMode) {
            print("⚠️ [FCMBackendService] Erreur parsing JSON réponse: $jsonError");
            print("⚠️ [FCMBackendService] Réponse brute: ${response.body}");
          }
          // Considérer comme succès si le status code est 200 même si le JSON ne parse pas
          return true;
        }
      } else {
        if (kDebugMode) {
          print("❌ [FCMBackendService] Erreur HTTP: ${response.statusCode}");
          print("❌ [FCMBackendService] Message d'erreur: ${response.body}");
          
          // Diagnostics supplémentaires selon le code d'erreur
          switch (response.statusCode) {
            case 401:
              print("❌ [FCMBackendService] DIAGNOSTIC: Token d'authentification invalide ou expiré");
              break;
            case 403:
              print("❌ [FCMBackendService] DIAGNOSTIC: Permissions insuffisantes");
              break;
            case 404:
              print("❌ [FCMBackendService] DIAGNOSTIC: Endpoint non trouvé - vérifier l'URL");
              break;
            case 500:
              print("❌ [FCMBackendService] DIAGNOSTIC: Erreur serveur backend");
              break;
            default:
              print("❌ [FCMBackendService] DIAGNOSTIC: Erreur HTTP non spécifique");
          }
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [FCMBackendService] === EXCEPTION ENVOI BACKEND ===");
        print("❌ [FCMBackendService] Type d'erreur: ${e.runtimeType}");
        print("❌ [FCMBackendService] Message d'erreur: $e");
        print("❌ [FCMBackendService] Stack trace: ${StackTrace.current}");
        
        // Diagnostics spécifiques selon le type d'erreur
        if (e.toString().contains('timeout')) {
          print("❌ [FCMBackendService] DIAGNOSTIC: Timeout de connexion - vérifier la connectivité");
        } else if (e.toString().contains('network')) {
          print("❌ [FCMBackendService] DIAGNOSTIC: Problème réseau");
        } else if (e.toString().contains('certificate')) {
          print("❌ [FCMBackendService] DIAGNOSTIC: Problème de certificat SSL");
        }
      }
      return false;
    }
  }

  /// 🔧 Méthode de diagnostic pour tester la connectivité backend
  static Future<Map<String, dynamic>> testBackendConnectivity() async {
    try {
      if (kDebugMode) {
        print("🔍 [FCMBackendService] Test de connectivité backend...");
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      final response = await http.get(
        Uri.parse('$baseUrl/api/health/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      return {
        'backend_reachable': response.statusCode == 200,
        'status_code': response.statusCode,
        'firebase_user_connected': firebaseUser != null,
        'firebase_user_id': firebaseUser?.uid,
        'firebase_user_email': firebaseUser?.email,
      };
    } catch (e) {
      return {
        'backend_reachable': false,
        'error': e.toString(),
        'firebase_user_connected': FirebaseAuth.instance.currentUser != null,
      };
    }
  }
}
