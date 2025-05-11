// lib/providers/ai_chat_provider.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hairbnb/models/ai_chat.dart';

import '../services/ai_chat_service.dart';

class AIChatProvider with ChangeNotifier {
  late final AIChatService _chatService;

  List<AIConversation> _conversations = [];
  AIConversation? _activeConversation;
  bool _isLoading = false;
  String? _error;

  AIChatProvider(this._chatService);

  // Getters
  List<AIConversation> get conversations => _conversations;
  AIConversation? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mettre à jour le service API
  void updateToken(String newToken) {
    _chatService.updateToken(newToken);
    notifyListeners();
  }

  // Charger toutes les conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter cette fonction en haut de votre classe
  String _cleanTextIfNeeded(String text) {
    try {
      // Utiliser latin1 pour encoder puis utf8 pour décoder
      return utf8.decode(latin1.encode(text), allowMalformed: true);
    } catch (e) {
      print("Erreur lors du nettoyage du texte: $e");
      return text;  // Retourner le texte original en cas d'erreur
    }
  }


  // Charger les messages d'une conversation
  Future<void> loadConversationMessages(int? conversationId) async {
    // Vérifier si l'ID est null
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _chatService.getConversationMessages(conversationId);

      // Mettre à jour la conversation active
      _activeConversation = conversation;

      // Mettre à jour la conversation dans la liste des conversations
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = conversation;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer une nouvelle conversation
  // Créer une nouvelle conversation
  Future<void> createNewConversation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeConversation = await _chatService.createConversation();

      _conversations.insert(0, _activeConversation!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Supprimer une conversation
  Future<void> deleteConversation(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Appeler l'API pour supprimer la conversation
      await _chatService.deleteConversation(conversationId);

      // Supprimer la conversation de la liste locale
      _conversations.removeWhere((conversation) => conversation.id == conversationId);

      // Si la conversation active a été supprimée, la réinitialiser
      if (_activeConversation != null && _activeConversation!.id == conversationId) {
        _activeConversation = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  // Envoyer un message et obtenir une réponse
  Future<void> sendMessage(String message) async {
    if (_activeConversation == null && message.isNotEmpty) {
      await createNewConversation();
    }

    if (_activeConversation != null && message.isNotEmpty) {
      // Créer un message temporaire
      final tempUserMessage = AIMessage(
        id: -1,
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      // Ajouter le message à la conversation active
      try {
        // Créer une nouvelle liste modifiable à partir de l'existante
        _activeConversation!.messages = List<AIMessage>.from(_activeConversation!.messages)
          ..add(tempUserMessage);
        notifyListeners();
      } catch (e) {
        print("Erreur lors de l'ajout du message: $e");
        // Si l'erreur persiste, essayer une approche différente
        var newMessages = <AIMessage>[];
        newMessages.addAll(_activeConversation!.messages);
        newMessages.add(tempUserMessage);
        _activeConversation!.messages = newMessages;
        notifyListeners();
      }

      try {
        // Envoyer le message et recevoir la réponse
        final response = await _chatService.sendMessage(
          conversationId: _activeConversation!.id,
          message: message,
        );

        // Utiliser la réponse pour mettre à jour les messages
        // Mettre à jour le message utilisateur avec l'ID réel
        final userMessageIndex = _activeConversation!.messages.length - 1;
        if (userMessageIndex >= 0) {
          final updatedUserMsg = AIMessage(
            id: response.userMessageId,
            content: message,
            isUser: true,
            timestamp: DateTime.now(),
            tokensIn: response.tokens['input'] ?? 0,
          );

          // Créer une nouvelle liste pour la mise à jour
          var updatedMessages = List<AIMessage>.from(_activeConversation!.messages);
          updatedMessages[userMessageIndex] = updatedUserMsg;
          _activeConversation!.messages = updatedMessages;
        }

        // Ajouter la réponse de l'IA
        final aiMessage = AIMessage(
          id: response.aiMessageId,
          content: _cleanTextIfNeeded(response.aiResponse),  // Nettoyage appliqué ici
          isUser: false,
          timestamp: DateTime.now(),
          tokensOut: response.tokens['output'] ?? 0,
        );
        // final aiMessage = AIMessage(
        //   id: response.aiMessageId,
        //   content: response.aiResponse,
        //   isUser: false,
        //   timestamp: DateTime.now(),
        //   tokensOut: response.tokens['output'] ?? 0,
        // );

        // Créer une nouvelle liste pour l'ajout
        var updatedMessages = List<AIMessage>.from(_activeConversation!.messages);
        updatedMessages.add(aiMessage);
        _activeConversation!.messages = updatedMessages;

        // Mettre à jour le nombre total de tokens
        _activeConversation!.tokensUsed += ((response.tokens['total'] ?? 0) as num).toInt();

        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    }

  }
  // Future<void> sendMessage(String message) async {
  //   if (_activeConversation == null && message.isNotEmpty) {
  //     await createNewConversation();
  //   }
  //
  //   if (_activeConversation != null && message.isNotEmpty) {
  //     // Créer un message temporaire
  //     final tempUserMessage = AIMessage(
  //       id: -1,
  //       content: message,
  //       isUser: true,
  //       timestamp: DateTime.now(),
  //     );
  //
  //     // Ajouter le message à la conversation active
  //     _activeConversation!.messages.add(tempUserMessage);
  //     notifyListeners();
  //
  //     try {
  //       final response = await _chatService.sendMessage(
  //         conversationId: _activeConversation!.id,
  //         message: message,
  //       );
  //
  //       // Mettre à jour le message utilisateur avec l'ID réel
  //       final userMessageIndex = _activeConversation!.messages.length - 1;
  //       if (userMessageIndex >= 0) {
  //         final updatedUserMsg = AIMessage(
  //           id: response.userMessageId,
  //           content: message,
  //           isUser: true,
  //           timestamp: DateTime.now(),
  //           tokensIn: response.tokens['input'] ?? 0,
  //         );
  //         _activeConversation!.messages[userMessageIndex] = updatedUserMsg;
  //       }
  //
  //       // Ajouter la réponse de l'IA
  //       final aiMessage = AIMessage(
  //         id: response.aiMessageId,
  //         content: response.aiResponse,
  //         isUser: false,
  //         timestamp: DateTime.now(),
  //         tokensOut: response.tokens['output'] ?? 0,
  //       );
  //
  //       _activeConversation!.messages.add(aiMessage);
  //
  //       // Mettre à jour le nombre total de tokens
  //       _activeConversation!.tokensUsed += ((response.tokens['total'] ?? 0) as num).toInt();
  //
  //       notifyListeners();
  //     } catch (e) {
  //       _error = e.toString();
  //       notifyListeners();
  //     }
  //   }
  // }

  // Définir la conversation active
  void setActiveConversation(int? conversationId) {
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      notifyListeners();
      return;
    }

    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _activeConversation = _conversations[conversationIndex];
      loadConversationMessages(conversationId);
    } else {
      _error = "Conversation non trouvée";
      notifyListeners();
    }
  }

  // Ajouter cette méthode qui était manquante
  void clearError() {
    _error = null;
    notifyListeners();
  }
}




// // lib/providers/ai_chat_provider.dart
// import 'package:flutter/foundation.dart';
// import '../../../models/ai_chat.dart';
// import '../services/ai_chat_service.dart';
//
// class AIChatProvider with ChangeNotifier {
//   late final AIChatService _chatService;
//
//   List<AIConversation> _conversations = [];
//   AIConversation? _activeConversation;
//   bool _isLoading = false;
//   String? _error;
//
//   AIChatProvider(this._chatService);
//
//   // Getters
//   List<AIConversation> get conversations => _conversations;
//   AIConversation? get activeConversation => _activeConversation;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//
//   // Mettre à jour le service API
//   void updateToken(String newToken) {
//     _chatService.updateToken(newToken);
//     notifyListeners();
//   }
//
//   // Charger toutes les conversations
//   Future<void> loadConversations() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       _conversations = await _chatService.getConversations();
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Charger les messages d'une conversation
//   Future<void> loadConversationMessages(int conversationId) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       final conversation = await _chatService.getConversationMessages(conversationId);
//
//       // Mettre à jour la conversation active
//       _activeConversation = conversation;
//
//       // Mettre à jour la conversation dans la liste des conversations
//       final index = _conversations.indexWhere((c) => c.id == conversationId);
//       if (index != -1) {
//         _conversations[index] = conversation;
//       }
//
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Créer une nouvelle conversation
//   Future<void> createNewConversation() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       _activeConversation = await _chatService.createConversation();
//       _conversations.insert(0, _activeConversation!);
//
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Envoyer un message et obtenir une réponse
//   Future<void> sendMessage(String message) async {
//     if (_activeConversation == null && message.isNotEmpty) {
//       await createNewConversation();
//     }
//
//     if (_activeConversation != null && message.isNotEmpty) {
//       // Créer un message temporaire
//       final tempUserMessage = AIMessage(
//         id: -1,
//         content: message,
//         isUser: true,
//         timestamp: DateTime.now(),
//       );
//
//       // Ajouter le message à la conversation active
//       _activeConversation!.messages.add(tempUserMessage);
//       notifyListeners();
//
//       try {
//         final response = await _chatService.sendMessage(
//           conversationId: _activeConversation!.id,
//           message: message,
//         );
//
//         // Mettre à jour le message utilisateur avec l'ID réel
//         final userMessageIndex = _activeConversation!.messages.length - 1;
//         if (userMessageIndex >= 0) {
//           final updatedUserMsg = AIMessage(
//             id: response.userMessageId,
//             content: message,
//             isUser: true,
//             timestamp: DateTime.now(),
//             tokensIn: response.tokens['input'] ?? 0,
//           );
//           _activeConversation!.messages[userMessageIndex] = updatedUserMsg;
//         }
//
//         // Ajouter la réponse de l'IA
//         final aiMessage = AIMessage(
//           id: response.aiMessageId,
//           content: response.aiResponse,
//           isUser: false,
//           timestamp: DateTime.now(),
//           tokensOut: response.tokens['output'] ?? 0,
//         );
//
//         _activeConversation!.messages.add(aiMessage);
//
//         // Mettre à jour le nombre total de tokens (corrigé)
//         _activeConversation!.tokensUsed += ((response.tokens['total'] ?? 0) as num).toInt();
//
//         notifyListeners();
//       } catch (e) {
//         _error = e.toString();
//         notifyListeners();
//       }
//     }
//   }
//
//   // Définir la conversation active
//   void setActiveConversation(int conversationId) {
//     final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
//     if (conversationIndex != -1) {
//       _activeConversation = _conversations[conversationIndex];
//       loadConversationMessages(conversationId);
//     }
//   }
//
//   // Effacer les erreurs
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
// }