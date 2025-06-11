// lib/pages/ai_chat/services/coiffeuse_ai_chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/ai_chat_coiffeuse.dart';

class CoiffeuseAIChatService {
  final String baseUrl;
  String token;

  CoiffeuseAIChatService({
    required this.baseUrl,
    required this.token,
  });

  // Mettre à jour le token si nécessaire
  void updateToken(String newToken) {
    token = newToken;
  }

  // Headers pour les requêtes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Récupérer toutes les conversations de la coiffeuse
  Future<List<CoiffeuseConversationItem>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonData = json.decode(decodedResponse);

        // Le backend retourne directement une liste de conversations
        return jsonData.map((item) => CoiffeuseConversationItem.fromJson(item)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des conversations: ${response.body}');
      }
    } catch (e) {
      print("Erreur dans getConversations: $e");
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }

  /// Récupérer les messages d'une conversation spécifique
  Future<CoiffeuseConversationDetail> getConversationMessages(int? conversationId) async {
    print("getConversationMessages appelé avec id: $conversationId");

    if (conversationId == null) {
      print("ERREUR: conversationId est null dans getConversationMessages");
      throw Exception('L\'ID de conversation ne peut pas être null');
    }

    try {
      print("Tentative de récupération des messages pour conversation $conversationId");
      final response = await http.get(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/$conversationId/messages/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);

        return CoiffeuseConversationDetail.fromJson(jsonData);
      } else {
        print("Erreur HTTP ${response.statusCode}: ${response.body}");
        throw Exception('Erreur lors de la récupération des messages: ${response.body}');
      }
    } catch (e) {
      print("Exception dans getConversationMessages: $e");
      throw Exception('Erreur lors de la récupération des messages: $e');
    }
  }

  /// Créer une nouvelle conversation
  Future<CoiffeuseConversationCreate> createConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/create/'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);

        return CoiffeuseConversationCreate.fromJson(jsonData);
      } else {
        print("Erreur HTTP ${response.statusCode} lors de la création de conversation: ${response.body}");
        throw Exception('Erreur lors de la création de la conversation: ${response.body}');
      }
    } catch (e) {
      print("Exception dans createConversation: $e");
      throw Exception('Erreur lors de la création de la conversation: $e');
    }
  }

  /// Envoyer un message et obtenir une réponse de l'IA
  Future<CoiffeuseMessageResponse> sendMessage({
    int? conversationId,
    required String message,
  }) async {
    try {
      final request = CoiffeuseMessageRequest(
        conversationId: conversationId,
        message: message,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/coiffeuse/ai/messages/send/'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(responseBody);

        return CoiffeuseMessageResponse.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de l\'envoi du message: ${response.body}');
      }
    } catch (e) {
      print("Erreur dans sendMessage: $e");
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Supprimer une conversation
  Future<void> deleteConversation(int conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/$conversationId/delete/'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur lors de la suppression de la conversation: ${response.body}');
      }
    } catch (e) {
      print("Erreur dans deleteConversation: $e");
      throw Exception('Erreur lors de la suppression de la conversation: $e');
    }
  }
}