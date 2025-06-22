// lib/pages/ai_chat/providers/coiffeuse_ai_chat_provider.dart
import 'package:flutter/material.dart';
import '../../models/ai_chat_coiffeuse.dart';
import '../../pages/ai_chat/services/coiffeuse_ai_chat_service.dart';

class CoiffeuseAIChatProvider with ChangeNotifier {
  late final CoiffeuseAIChatService _chatService;

  List<CoiffeuseConversationItem> _conversations = [];
  CoiffeuseConversationDetail? _activeConversation;
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;

  CoiffeuseAIChatProvider(this._chatService);

  // Getters
  List<CoiffeuseConversationItem> get conversations => _conversations;
  CoiffeuseConversationDetail? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;

  // Mettre à jour le service API avec un nouveau token
  void updateToken(String newToken) {
    _chatService.updateToken(newToken);
    notifyListeners();
  }

  // Charger toutes les conversations de la coiffeuse
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

  // Charger les messages d'une conversation spécifique
  Future<void> loadConversationMessages(int? conversationId) async {
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeConversation = await _chatService.getConversationMessages(conversationId);

      // Mettre à jour la conversation dans la liste si elle existe
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        // Mettre à jour le titre de la conversation si nécessaire
        _conversations[index] = CoiffeuseConversationItem(
          id: _activeConversation!.id,
          createdAt: _activeConversation!.createdAt,
          tokensUsed: _conversations[index].tokensUsed,
          title: _activeConversation!.messages.isNotEmpty
              ? _activeConversation!.messages.first.content.length > 50
              ? '${_activeConversation!.messages.first.content.substring(0, 50)}...'
              : _activeConversation!.messages.first.content
              : 'Nouvelle Conversation',
        );
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
  Future<CoiffeuseConversationDetail?> createNewConversation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("🚀 Début création nouvelle conversation");

      final newConversation = await _chatService.createConversation();
      print("✅ Conversation créée côté serveur - ID: ${newConversation.id}");

      // Créer une conversation détaillée vide
      _activeConversation = CoiffeuseConversationDetail(
        id: newConversation.id,
        userId: 0, // On ne connait pas l'userId depuis la réponse
        createdAt: newConversation.createdAt,
        messages: [],
      );
      print("✅ _activeConversation définie avec ID: ${_activeConversation!.id}");

      // Créer l'élément de liste
      final conversationItem = CoiffeuseConversationItem(
        id: newConversation.id,
        createdAt: newConversation.createdAt,
        tokensUsed: 0,
        title: 'Nouvelle Conversation',
      );

      // Ajouter en début de liste
      _conversations.insert(0, conversationItem);
      print("✅ Conversation ajoutée à la liste");

      _isLoading = false;

      // Notifier les listeners APRÈS avoir tout défini
      notifyListeners();


      // Retourner la conversation créée
      return _activeConversation;
    } catch (e) {
      print("❌ Erreur lors de la création de conversation: $e");
      _error = e.toString();
      _isLoading = false;
      _activeConversation = null;
      notifyListeners();
      return null;
    }
  }

  // Nouvelle méthode pour créer et naviguer
  Future<void> createNewConversationAndNavigate(BuildContext context) async {
    final newConversation = await createNewConversation();

    if (newConversation != null) {
      // Naviguer vers la nouvelle conversation
      Navigator.pushNamed(
          context,
          '/coiffeuse/ai/chat/${newConversation.id}'
      );
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
    if (message.trim().isEmpty) return;

    // Créer une nouvelle conversation si nécessaire
    if (_activeConversation == null) {
      await createNewConversation();
      if (_activeConversation == null) return; // Si la création a échoué
    }

    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    // Créer un message temporaire de l'utilisateur
    final tempUserMessage = CoiffeuseMessage(
      id: -1, // ID temporaire
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Ajouter le message à la conversation active
    try {
      _activeConversation!.messages = List<CoiffeuseMessage>.from(_activeConversation!.messages)
        ..add(tempUserMessage);
      notifyListeners();
    } catch (e) {
      print("Erreur lors de l'ajout du message: $e");
      var newMessages = <CoiffeuseMessage>[];
      newMessages.addAll(_activeConversation!.messages);
      newMessages.add(tempUserMessage);
      _activeConversation!.messages = newMessages;
      notifyListeners();
    }

    try {
      // Envoyer le message et recevoir la réponse
      await _chatService.sendMessage(
        conversationId: _activeConversation!.id,
        message: message,
      );

      // Recharger la conversation pour obtenir les messages mis à jour
      await loadConversationMessages(_activeConversation!.id);

      _isSendingMessage = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSendingMessage = false;

      // Supprimer le message temporaire en cas d'erreur
      if (_activeConversation != null && _activeConversation!.messages.isNotEmpty) {
        final lastMessage = _activeConversation!.messages.last;
        if (lastMessage.id == -1) {
          _activeConversation!.messages.removeLast();
        }
      }

      notifyListeners();
    }
  }

  // Définir la conversation active
  void setActiveConversation(int? conversationId) {
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      notifyListeners();
      return;
    }

    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      // Réinitialiser la conversation active
      _activeConversation = null;
      notifyListeners();

      // Charger les messages de la conversation
      loadConversationMessages(conversationId);
    } else {
      _error = "Conversation non trouvée";
      notifyListeners();
    }
  }

  // Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Réinitialiser la conversation active
  void clearActiveConversation() {
    _activeConversation = null;
    notifyListeners();
  }

  // Obtenir une conversation par ID depuis la liste
  CoiffeuseConversationItem? getConversationById(int id) {
    try {
      return _conversations.firstWhere((conv) => conv.id == id);
    } catch (e) {
      return null;
    }
  }

  // Vérifier si on a des conversations
  bool get hasConversations => _conversations.isNotEmpty;

  // Vérifier si on a une conversation active
  bool get hasActiveConversation => _activeConversation != null;

  // Obtenir le nombre de messages dans la conversation active
  int get activeConversationMessageCount => _activeConversation?.messages.length ?? 0;
}
