import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../notifications_services/fcm_backend_service.dart';

class FCMTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// 🔔 Récupère et sauvegarde le token FCM
  static Future<void> saveTokenToFirebase(String userId) async {
    try {
      // Demander permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Récupérer le token
        String? token = await _messaging.getToken();

        if (token != null) {
          if (kDebugMode) {
            print("📱 Token FCM: $token");
          }

          // Sauvegarder dans Firebase Realtime Database
          await _database.child('fcm_tokens/$userId').set({
            'token': token,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          // 🆕 Envoyer aussi au backend Django
          await FCMBackendService.sendTokenToBackend(token);

          if (kDebugMode) {
            print("✅ Token FCM sauvegardé avec succès");
          }
        }
      } else {
        if (kDebugMode) {
          print("❌ Permission notifications refusée");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur sauvegarde token FCM: $e");
      }
    }
  }

  /// 🔄 Écouter les changements de token
  static void listenToTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print("🔄 Token FCM mis à jour: $newToken");
      }

      // Sauvegarder le nouveau token
      _database.child('fcm_tokens/$userId').set({
        'token': newToken,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Envoyer au backend Django
      FCMBackendService.sendTokenToBackend(newToken);
    });
  }
}