// lib/screens/ai_chat/conversations_list_page.dart
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  final dynamic currentUser;

  const ConversationsListPage({super.key, required this.currentUser});

  @override
  _ConversationsListPageState createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  @override
  void initState() {
    super.initState();
    // Charger les conversations au démarrage
    Future.microtask(() =>
        Provider.of<AIChatProvider>(context, listen: false).loadConversations()
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Hairbnb'),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AIChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.error != null &&
              chatProvider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erreur: ${chatProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => chatProvider.loadConversations(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (chatProvider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                      Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Aucune conversation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Commencez une nouvelle conversation avec l\'assistant',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle conversation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    onPressed: () => _startNewConversation(context),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.loadConversations(),
            child: ListView.builder(
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];
                final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
                final formattedDate = dateFormat.format(conversation.createdAt);

                // Texte à afficher comme aperçu de la conversation
                final previewText = conversation.lastMessage ??
                    (conversation.messages.isNotEmpty ?
                    conversation.messages.last.content :
                    "Nouvelle conversation");

                return Dismissible(
                  // Clé unique pour le widget Dismissible
                  key: Key('conversation-${conversation.id}'),

                  // Direction pour laquelle la suppression est autorisée (ici, glisser à gauche ou à droite)
                  direction: DismissDirection.endToStart,

                  // Fonction appelée lorsque l'élément est confirmé comme supprimé
                  onDismissed: (direction) {
                    // Appeler la méthode pour supprimer la conversation
                    chatProvider.deleteConversation(conversation.id);

                    // Afficher un message de confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Conversation supprimée'),
                        action: SnackBarAction(
                          label: 'Annuler',
                          onPressed: () {
                            // Vous pourriez implémenter une fonctionnalité pour annuler la suppression
                            // Pour l'instant, nous rechargeons simplement les conversations
                            chatProvider.loadConversations();
                          },
                        ),
                      ),
                    );
                  },

                  // Confirmation avant suppression
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmation'),
                          content: const Text('Voulez-vous vraiment supprimer cette conversation ?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },

                  // Arrière-plan qui apparaît lors du glissement
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),

                  // Le contenu qui sera glissé (votre Card)
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.2),
                        child: Icon(Icons.chat, color: primaryColor),
                      ),
                      title: Text(
                        'Conversation du $formattedDate',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            previewText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tokens utilisés: ${conversation.tokensUsed}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton de suppression
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () async {
                              // Confirmation avant suppression
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirmation'),
                                    content: const Text('Voulez-vous vraiment supprimer cette conversation ?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              ) ?? false;

                              if (confirmed) {
                                // Appeler la méthode pour supprimer la conversation
                                chatProvider.deleteConversation(conversation.id);

                                // Afficher un message de confirmation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Conversation supprimée'),
                                    action: SnackBarAction(
                                      label: 'Annuler',
                                      onPressed: () {
                                        // Recharger les conversations
                                        chatProvider.loadConversations();
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          // Flèche de navigation
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => _openConversation(context, conversation.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewConversation(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Nouvelle conversation',
      ),
    );
  }

  void _startNewConversation(BuildContext context) async {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    await provider.createNewConversation();
    if (provider.activeConversation != null) {
      _navigateToChatPage(context);
    }
  }

  void _openConversation(BuildContext context, int conversationId) {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    provider.setActiveConversation(conversationId);
    _navigateToChatPage(context);
  }

  void _navigateToChatPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangeNotifierProvider.value(
              value: Provider.of<AIChatProvider>(context, listen: false),
              child: AiChatPage(currentUser: widget.currentUser),
            ),
      ),
    );
  }
}