// lib/pages/ai_chat/services/coiffeuse_ai_chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hairbnb/models/ai_chat.dart';

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
  Future<List<AIConversation>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonData = json.decode(decodedResponse);

        // Le backend retourne directement une liste, pas un objet avec conversations
        return jsonData.map((item) => AIConversation.fromJson(item)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des conversations: ${response.body}');
      }
    } catch (e) {
      print("Erreur dans getConversations: $e");
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }

  /// Récupérer les messages d'une conversation spécifique
  Future<AIConversation> getConversationMessages(int? conversationId) async {
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

        // Vérifier si l'ID est présent dans la réponse
        if (!jsonData.containsKey('id')) {
          print("ATTENTION: La réponse JSON ne contient pas de champ 'id'");
          jsonData['id'] = conversationId; // Ajouter l'ID manuellement
        }
        return AIConversation.fromJson(jsonData);
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
  Future<AIConversation> createConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/create/'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);

        // Le backend retourne {id: ..., created_at: ...}
        if (jsonData['id'] == null) {
          print("ERREUR: La réponse de création de conversation ne contient pas d'ID");
          throw Exception('ID de conversation manquant dans la réponse');
        }

        return AIConversation(
          id: jsonData['id'],
          createdAt: DateTime.parse(jsonData['created_at'] ?? DateTime.now().toIso8601String()),
        );
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
  Future<SendMessageResponse> sendMessage({
    int? conversationId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coiffeuse/ai/messages/send/'),
        headers: _headers,
        body: json.encode({
          'conversation_id': conversationId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(responseBody);

        // Adapter la réponse du backend coiffeuse au format attendu
        return SendMessageResponse(
          conversationId: jsonData['conversation_id'],
          userMessageId: 0, // Le backend coiffeuse ne retourne pas ces IDs
          aiMessageId: 0,   // Le backend coiffeuse ne retourne pas ces IDs
          aiResponse: jsonData['ai_response'],
          tokens: jsonData['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
        );
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