import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../services/firebase_token/token_service.dart';

/// Service pour envoyer des notifications de chat via le backend Django
class ChatNotificationService {
  static const String baseUrl = "https://www.hairbnb.site";

  /// Envoie une notification de nouveau message
  static Future<void> sendMessageNotification({
    required String chatId,
    required String senderName,
    required String messageContent,
    required String recipientId,
  }) async {
    try {
      // 🔐 Récupérer le token d'authentification
      final token = await TokenService.getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print('⚠️ Aucun token disponible pour envoyer la notification');
        }
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/send_message_notification/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'sender_name': senderName,
          'message_content': messageContent,
          'recipient_id': recipientId,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (kDebugMode) {
            print('✅ Notification envoyée avec succès');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Notification non envoyée: ${data['message']}');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Erreur HTTP notification: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur envoi notification: $e');
      }
      // Ne pas faire planter l'app si la notification échoue
    }
  }
}