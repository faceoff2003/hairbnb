// lib/models/coiffeuse_ai_chat.dart
import 'dart:convert';

/// Modèle pour la liste des conversations des coiffeuses
/// Correspond à la réponse de get_coiffeuse_conversations
class CoiffeuseConversationItem {
  final int id;
  final DateTime createdAt;
  final int tokensUsed;
  final String title;

  CoiffeuseConversationItem({
    required this.id,
    required this.createdAt,
    required this.tokensUsed,
    required this.title,
  });

  factory CoiffeuseConversationItem.fromJson(Map<String, dynamic> json) {
    return CoiffeuseConversationItem(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      tokensUsed: json['tokens_used'] ?? 0,
      title: json['title'] ?? 'Nouvelle Conversation',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'tokens_used': tokensUsed,
    'title': title,
  };
}

/// Modèle pour une conversation complète avec ses messages
/// Correspond à la réponse de get_coiffeuse_conversation_messages
class CoiffeuseConversationDetail {
  final int id;
  final int userId;
  final DateTime createdAt;
  List<CoiffeuseMessage> messages;

  CoiffeuseConversationDetail({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.messages = const [],
  });

  factory CoiffeuseConversationDetail.fromJson(Map<String, dynamic> json) {
    return CoiffeuseConversationDetail(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      messages: json['messages'] != null
          ? List<CoiffeuseMessage>.from(json['messages'].map((x) => CoiffeuseMessage.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'messages': messages.map((x) => x.toJson()).toList(),
  };
}

/// Modèle pour un message individuel
/// Correspond au AIMessageSerializer du backend
class CoiffeuseMessage {
  final int id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  CoiffeuseMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  factory CoiffeuseMessage.fromJson(Map<String, dynamic> json) {
    return CoiffeuseMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['is_user'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Modèle pour la création d'une nouvelle conversation
/// Correspond à la réponse de create_coiffeuse_conversation
class CoiffeuseConversationCreate {
  final int id;
  final DateTime createdAt;

  CoiffeuseConversationCreate({
    required this.id,
    required this.createdAt,
  });

  factory CoiffeuseConversationCreate.fromJson(Map<String, dynamic> json) {
    return CoiffeuseConversationCreate(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Modèle pour la réponse d'envoi de message
/// Correspond à la réponse de send_coiffeuse_message
class CoiffeuseMessageResponse {
  final int conversationId;
  final String aiResponse;
  final Map<String, dynamic> tokens;

  CoiffeuseMessageResponse({
    required this.conversationId,
    required this.aiResponse,
    required this.tokens,
  });

  factory CoiffeuseMessageResponse.fromJson(Map<String, dynamic> json) {
    String responseText;
    if (json['ai_response'] is String) {
      responseText = json['ai_response'];
    } else if (json['ai_response'] is List<int>) {
      responseText = utf8.decode(json['ai_response']);
    } else {
      responseText = json['ai_response'].toString();
    }

    return CoiffeuseMessageResponse(
      conversationId: json['conversation_id'],
      aiResponse: responseText,
      tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'ai_response': aiResponse,
    'tokens': tokens,
  };
}

/// Modèle pour l'envoi d'un message (requête)
class CoiffeuseMessageRequest {
  final int? conversationId;
  final String message;

  CoiffeuseMessageRequest({
    this.conversationId,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'message': message,
  };
}