/// *****************************************************************************
///
/// SERVICE DE GESTION DES NOTIFICATIONS (NotificationService)
///
/// Ce fichier définit la classe `NotificationService`, une classe utilitaire
/// statique qui centralise toute la logique liée aux notifications push pour
/// l'application. Elle n'a pas besoin d'être instanciée.
///
/// RESPONSABILITÉS PRINCIPALES :
/// 1.  **Initialisation Complète** : Fournit une méthode unique `initialize()`
/// qui orchestre l'ensemble du processus de configuration des notifications.
///
/// 2.  **Gestion des Permissions** : Gère la demande d'autorisation auprès de
/// l'utilisateur pour l'affichage des notifications (alertes, sons, badges).
///
/// 3.  **Récupération du Token FCM** : Obtient le jeton unique de Firebase Cloud
/// Messaging (FCM) pour l'appareil. Ce jeton est indispensable pour que
/// le backend puisse envoyer des notifications ciblées à cet appareil.
///
/// 4.  **Configuration des Handlers** : Met en place les écouteurs nécessaires
/// pour réagir aux messages entrants lorsque l'application est en premier
/// plan, en arrière-plan ou terminée.
///
/// 5.  **Notifications Locales** : Configure le plugin `flutter_local_notifications`
/// pour permettre l'affichage de notifications lorsque l'application est
/// active au premier plan.
///
///*****************************************************************************
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'fcm_backend_service.dart';

class NotificationService {
  // Instance statique de Firebase Messaging pour interagir avec FCM.
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // Instance statique du plugin de notifications locales.
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Variable statique pour stocker le token FCM une fois récupéré.
  static String? _fcmToken;
  
  // 🆕 NavigatorKey pour la navigation globale
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Méthode pour configurer le navigateur global
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    // if (kDebugMode) {
    //   print("🧭 [NotificationService] NavigatorKey configuré");
    // }
  }

  /// Initialise l'ensemble du service de notifications.
  /// C'est la méthode principale à appeler au démarrage de l'application.
  static Future<void> initialize() async {
    // if (kDebugMode) {
    //   print("🔔 [NotificationService] === DÉBUT INITIALISATION ===");
    // }
    
    try {
      // 1. Demande les permissions de notification à l'utilisateur.
      // if (kDebugMode) {
      //   print("🔔 [NotificationService] Étape 1: Demande des permissions...");
      // }
      await _requestPermissions();

      // 2. Configure le plugin pour afficher les notifications locales.
      // if (kDebugMode) {
      //   print("🔔 [NotificationService] Étape 2: Configuration notifications locales...");
      // }
      await _setupLocalNotifications();

      // 3. Récupère le jeton unique de l'appareil depuis Firebase.
      // if (kDebugMode) {
      //   print("🔔 [NotificationService] Étape 3: Récupération token FCM...");
      // }
      await _getFCMToken();

      // 4. Met en place les écouteurs pour les messages entrants.
      // if (kDebugMode) {
      //   print("🔔 [NotificationService] Étape 4: Configuration des handlers...");
      // }
      _setupMessageHandlers();

      // 5. 🆕 Vérifier si l'app a été ouverte depuis une notification
      // if (kDebugMode) {
      //   print("🔔 [NotificationService] Étape 5: Vérification notification initiale...");
      // }
      _checkInitialMessage();

      // if (kDebugMode) {
      //   print("🔔 [NotificationService] === INITIALISATION TERMINÉE AVEC SUCCÈS ===");
      //   print("🔔 [NotificationService] Token FCM final: ${_fcmToken?.substring(0, 20) ?? 'null'}...");
      // }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] === ERREUR INITIALISATION ===");
        print("❌ [NotificationService] Erreur: $e");
        print("❌ [NotificationService] Stack trace: ${StackTrace.current}");
      }
    }
  }

  /// Convertir ID numérique en UUID
  static Future<String?> _getUuidFromId(String id) async {
    try {
      // if (kDebugMode) {
      //   print("🔄 [NotificationService] Conversion ID $id vers UUID...");
      // }

      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_user_by_id/$id/'),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["status"] == "success" && jsonData["user"] != null) {
          final uuid = jsonData["user"]["uuid"];
          // if (kDebugMode) {
          //   print("✅ [NotificationService] ID $id → UUID $uuid");
          // }
          return uuid;
        }
      }
      
      // if (kDebugMode) {
      //   print("❌ [NotificationService] Conversion échouée pour ID $id");
      // }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur conversion ID: $e");
      }
      return null;
    }
  }

  /// Méthode privée pour demander les permissions de notification à l'utilisateur.
  static Future<void> _requestPermissions() async {
    try {
      // if (kDebugMode) {
      //   print("🔑 [NotificationService] Demande des permissions FCM...");
      // }

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      // if (kDebugMode) {
      //   print("🔑 [NotificationService] Statut permission: ${settings.authorizationStatus}");
      //   print("🔑 [NotificationService] Alert autorisé: ${settings.alert}");
      //   print("🔑 [NotificationService] Badge autorisé: ${settings.badge}");
      //   print("🔑 [NotificationService] Son autorisé: ${settings.sound}");
      // }

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        // if (kDebugMode) {
        //   print("⚠️ [NotificationService] Permissions refusées ou non accordées");
        // }
      } else {
        // if (kDebugMode) {
        //   print("✅ [NotificationService] Permissions accordées");
        // }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur demande permissions: $e");
      }
    }
  }

  /// Méthode privée pour récupérer le token FCM et le stocker.
  /// Le token est essentiel pour cibler cet appareil depuis un serveur backend.
  static Future<String?> _getFCMToken() async {
    try {
      // if (kDebugMode) {
      //   print("🎫 [NotificationService] Récupération du token FCM...");
      // }

      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        if (kDebugMode) {
          // print("🎫 [NotificationService] Token FCM récupéré avec succès:");
          // print("🎫 [NotificationService] Token (20 premiers chars): ${_fcmToken!.substring(0, 20)}...");
          // print("🎫 [NotificationService] Longueur du token: ${_fcmToken!.length} caractères");
        }

        // // 🆕 Envoyer le token au backend Django
        // if (kDebugMode) {
        //   print("📤 [NotificationService] Envoi du token au backend...");
        // }
        
        try {
          bool success = await FCMBackendService.sendTokenToBackend(_fcmToken!);
          if (kDebugMode) {
            if (success) {
              //print("✅ [NotificationService] Token envoyé au backend avec succès");
            } else {
              //print("❌ [NotificationService] Échec envoi token au backend");
            }
          }
        } catch (backendError) {
          if (kDebugMode) {
            print("❌ [NotificationService] Erreur envoi backend: $backendError");
          }
        }
      } else {
        if (kDebugMode) {
          print("❌ [NotificationService] Token FCM est null");
        }
      }

      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur récupération token: $e");
        print("❌ [NotificationService] Stack trace: ${StackTrace.current}");
      }
      return null;
    }
  }

  /// Getter public statique pour accéder au jeton FCM depuis d'autres parties de l'application.
  ///
  /// Utile pour envoyer le token à votre backend et l'associer à un utilisateur.
  static String? get fcmToken {
    // if (kDebugMode) {
    //   print("🎫 [NotificationService] Getter fcmToken appelé: ${_fcmToken?.substring(0, 20) ?? 'null'}...");
    // }
    return _fcmToken;
  }

  /// Configurer les notifications locales
  static Future<void> _setupLocalNotifications() async {
    try {
      // if (kDebugMode) {
      //   print("📱 [NotificationService] Configuration notifications locales...");
      // }

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // 🆕 Ajouter callback pour les clics sur notifications locales
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // if (kDebugMode) {
      //   print("✅ [NotificationService] Notifications locales configurées");
      // }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur config notifications locales: $e");
      }
    }
  }

  /// Callback pour les clics sur notifications locales
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    // if (kDebugMode) {
    //   print("🔔 [NotificationService] Notification locale cliquée:");
    //   print("🔔 [NotificationService] Payload: ${notificationResponse.payload}");
    // }

    if (notificationResponse.payload != null) {
      _handleNotificationNavigation(notificationResponse.payload!);
    }
  }

  /// Configurer les handlers de messages FCM
  static void _setupMessageHandlers() {
    try {
      // if (kDebugMode) {
      //   print("🎯 [NotificationService] Configuration des handlers de messages...");
      // }

      // Message reçu quand app en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // if (kDebugMode) {
        //   print('📱 [NotificationService] Message reçu en premier plan:');
        //   print('📱 [NotificationService] Titre: ${message.notification?.title}');
        //   print('📱 [NotificationService] Corps: ${message.notification?.body}');
        //   print('📱 [NotificationService] Data: ${message.data}');
        // }
        _showLocalNotification(message);
      });

      // 🆕 Message cliqué quand app en arrière-plan
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // if (kDebugMode) {
        //   print('🔔 [NotificationService] Notification FCM cliquée:');
        //   print('🔔 [NotificationService] Titre: ${message.notification?.title}');
        //   print('🔔 [NotificationService] Data: ${message.data}');
        // }
        _navigateToChat(message.data);
      });

      // if (kDebugMode) {
      //   print("✅ [NotificationService] Handlers de messages configurés");
      // }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur config handlers: $e");
      }
    }
  }

  /// Vérifier si l'app a été ouverte depuis une notification
  static Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      
      if (initialMessage != null) {
        // if (kDebugMode) {
        //   print('🚀 [NotificationService] App ouverte depuis notification:');
        //   print('🚀 [NotificationService] Data: ${initialMessage.data}');
        // }
        
        // Attendre un peu que l'app soit complètement chargée
        Future.delayed(Duration(seconds: 1), () {
          _navigateToChat(initialMessage.data);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur vérification message initial: $e");
      }
    }
  }

  /// 🆕 Navigation vers le chat avec conversion ID → UUID
  static void _navigateToChat(Map<String, dynamic> data) async {
    // if (kDebugMode) {
    //   print("🧭 [NotificationService] === NAVIGATION VERS CHAT ===");
    //   print("🧭 [NotificationService] Data reçue: $data");
    // }

    // SIMPLE: Toujours aller vers MessagesPage
    _navigateToRoute('/messages');

    try {
      final String? chatId = data['chat_id'];
      final String? senderId = data['sender_id'];
      final String? receiverId = data['receiver_id'];

      // if (kDebugMode) {
      //   print("🧭 [NotificationService] ChatID: $chatId");
      //   print("🧭 [NotificationService] SenderID: $senderId");
      //   print("🧭 [NotificationService] ReceiverID: $receiverId");
      // }

      if (senderId != null) {
        // 🆕 Vérifier si c'est un UUID ou un ID numérique
        String targetUserId = senderId;
        
        if (RegExp(r'^\d+$').hasMatch(senderId)) {
          // C'est un ID numérique, le convertir en UUID
          // if (kDebugMode) {
          //   print("🔄 [NotificationService] ID numérique détecté: $senderId");
          // }
          
          final uuid = await _getUuidFromId(senderId);
          if (uuid != null) {
            targetUserId = uuid;
            // if (kDebugMode) {
            //   print("✅ [NotificationService] Conversion réussie: $senderId → $uuid");
            // }
          } else {
            if (kDebugMode) {
              print("❌ [NotificationService] Conversion échouée pour ID: $senderId");
            }
            return;
          }
        }

        _navigateToRoute('/chat/$targetUserId');
      } else {
        if (kDebugMode) {
          print("❌ [NotificationService] Sender ID manquant");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur navigation: $e");
      }
    }
  }

  /// 🆕 Navigation vers une route
  static void _navigateToRoute(String route) {
    if (_navigatorKey?.currentState != null) {
      // if (kDebugMode) {
      //   print("🧭 [NotificationService] Navigation vers: $route");
      // }
      
      _navigatorKey!.currentState!.pushNamed(route);
    } else {
      if (kDebugMode) {
        print("❌ [NotificationService] NavigatorKey non configuré ou null");
      }
    }
  }

  /// 🆕 Gestion des notifications avec payload - vers MessagesPage
  static void _handleNotificationNavigation(String payload) async {
    // if (kDebugMode) {
    //   print("🧭 [NotificationService] Traitement payload: $payload");
    // }

    // ✅ SIMPLE: Toujours aller vers MessagesPage
    _navigateToRoute('/messages');
  }


  // static void _handleNotificationNavigation(String payload) async {
  //   if (kDebugMode) {
  //     print("🧭 [NotificationService] Traitement payload: $payload");
  //   }
  //
  //   try {
  //     // Le payload peut contenir des infos sur le chat
  //     // Format attendu: "chat:senderId" ou "chat:senderId:chatId"
  //     if (payload.startsWith('chat:')) {
  //       final parts = payload.split(':');
  //       if (parts.length >= 2) {
  //         String senderId = parts[1];
  //
  //         // 🆕 Convertir ID numérique en UUID si nécessaire
  //         if (RegExp(r'^\d+$').hasMatch(senderId)) {
  //           final uuid = await _getUuidFromId(senderId);
  //           if (uuid != null) {
  //             senderId = uuid;
  //           }
  //         }
  //
  //         _navigateToRoute('/chat/$senderId');
  //       }
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print("❌ [NotificationService] Erreur traitement payload: $e");
  //     }
  //   }
  // }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print("🔔 [NotificationService] Affichage notification locale...");
      }

      // ✅ Payload simple pour MessagesPage
      String payload = 'messages';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'chat_channel',
        'Messages de chat',
        channelDescription: 'Notifications pour les nouveaux messages',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Nouveau message',
        message.notification?.body ?? 'Vous avez reçu un message',
        platformChannelSpecifics,
        payload: payload, // ✅ Payload simplifié
      );

      if (kDebugMode) {
        print("✅ [NotificationService] Notification locale affichée avec payload: $payload");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [NotificationService] Erreur affichage notification: $e");
      }
    }
  }

  /// Méthode de diagnostic pour vérifier l'état du service
  static Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      final token = await _messaging.getToken();
      
      return {
        'fcm_token_stored': _fcmToken?.substring(0, 20) ?? 'null',
        'fcm_token_current': token?.substring(0, 20) ?? 'null',
        'tokens_match': _fcmToken == token,
        'permission_status': settings.authorizationStatus.toString(),
        'alert_enabled': settings.alert.toString(),
        'badge_enabled': settings.badge.toString(),
        'sound_enabled': settings.sound.toString(),
        'navigator_key_configured': _navigatorKey != null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
