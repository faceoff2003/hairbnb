// lib/models/ai_chat/ai_conversation.dart
// lib/models/ai_chat/ai_conversation.dart
import 'dart:convert';

class AIConversation {
  final int id;
  final DateTime createdAt;
  int tokensUsed;    // Non final pour permettre la modification
  final String? lastMessage;
  List<AIMessage> messages;

  AIConversation({
    required this.id,
    required this.createdAt,
    this.tokensUsed = 0,
    this.lastMessage,
    this.messages = const [],
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id'] ?? -1, // Ajouter une valeur par défaut au cas où id est null
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      tokensUsed: json['tokens_used'] ?? 0,
      lastMessage: json['last_message'],
      messages: json['messages'] != null
          ? List<AIMessage>.from(json['messages'].map((x) => AIMessage.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'tokens_used': tokensUsed,
    'last_message': lastMessage,
  };
}

// lib/models/ai_chat/ai_message.dart
class AIMessage {
  final int id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final int tokensIn;    // Gardons int ici
  final int tokensOut;   // Gardons int ici

  AIMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.tokensIn = 0,
    this.tokensOut = 0,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['is_user'],
      timestamp: DateTime.parse(json['timestamp']),
      tokensIn: (json['tokens_in'] ?? 0) is int ? json['tokens_in'] : (json['tokens_in'] ?? 0).toInt(),
      tokensOut: (json['tokens_out'] ?? 0) is int ? json['tokens_out'] : (json['tokens_out'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
    'tokens_in': tokensIn,
    'tokens_out': tokensOut,
  };
}

// lib/models/ai_chat/ai_response.dart
class SendMessageResponse {
  final int conversationId;
  final int userMessageId;
  final int aiMessageId;
  final String aiResponse;
  final Map<String, dynamic> tokens;  // Nous garderons le type dynamic ici

  SendMessageResponse({
    required this.conversationId,
    required this.userMessageId,
    required this.aiMessageId,
    required this.aiResponse,
    required this.tokens,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    String responseText;
    if (json['ai_response'] is String) {
      // La réponse est déjà une chaîne, pas besoin de décodage
      responseText = json['ai_response'];
    } else if (json['ai_response'] is List<int>) {
      // La réponse est une liste d'octets, il faut la décoder
      responseText = utf8.decode(json['ai_response']);
    } else {
      // Cas improbable mais géré par sécurité
      responseText = json['ai_response'].toString();
    }

    return SendMessageResponse(
      conversationId: json['conversation_id'],
      userMessageId: json['user_message_id'],
      aiMessageId: json['ai_message_id'],
      aiResponse: responseText,
      tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
    );
  }


  // factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
  //   return SendMessageResponse(
  //     conversationId: json['conversation_id'],
  //     userMessageId: json['user_message_id'],
  //     aiMessageId: json['ai_message_id'],
  //     aiResponse: json['ai_response'],
  //     tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
  //   );
  // }
}

// lib/models/ai_chat/conversations_list.dart
class ConversationsList {
  final List<AIConversation> conversations;

  ConversationsList({required this.conversations});

  factory ConversationsList.fromJson(Map<String, dynamic> json) {
    return ConversationsList(
      conversations: List<AIConversation>.from(
          json['conversations'].map((x) => AIConversation.fromJson(x))
      ),
    );
  }
}