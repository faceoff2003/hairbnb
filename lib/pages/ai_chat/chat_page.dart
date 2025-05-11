// lib/screens/ai_chat/chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/ai_chat.dart';

class AiChatPage extends StatefulWidget {
  final dynamic currentUser;

  const AiChatPage({super.key, required this.currentUser});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Hairbnb'),
        backgroundColor: primaryColor,
        actions: [
          // Bouton d'information sur les tokens
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showTokensInfo(context),
          ),
        ],
      ),
      body: Consumer<AIChatProvider>(
        builder: (context, chatProvider, child) {
          //
          // // -----------------------------------------------------------------------------------------------------------------------
          // print("État actuel: activeConversation=${chatProvider.activeConversation?.id}, isLoading=${chatProvider.isLoading}");
          // //------------------------------------------------------------------------------------------------------------------------

          if (chatProvider.activeConversation == null) {
            return const Center(
              child: Text('Aucune conversation active'),
            );
          }

          // Faire défiler vers le bas à chaque mise à jour des messages
          _scrollToBottom();

          return Column(
            children: [
              // Indicateur de chargement
              if (chatProvider.isLoading)
                LinearProgressIndicator(
                  backgroundColor: primaryColor.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),

              // Zone de messages
              Expanded(
                child: chatProvider.activeConversation!.messages.isEmpty
                    ? _buildWelcomeMessage(context)
                    : _buildMessagesList(context, chatProvider.activeConversation!.messages),
              ),

              // Barre d'erreur (visible seulement en cas d'erreur)
              if (chatProvider.error != null)
                Container(
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Erreur: ${chatProvider.error}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => chatProvider.clearError(),
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                ),

              // Compteur de tokens
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.token, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Tokens: ${chatProvider.activeConversation!.tokensUsed}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Zone de saisie
              _buildInputArea(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assistant, size: 100, color: primaryColor.withOpacity(0.7)),
            const SizedBox(height: 20),
            const Text(
              'Bienvenue sur l\'assistant Hairbnb',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'Je peux vous aider avec les statistiques de votre application, les réservations, les coiffeuses, les salons et bien plus encore.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Text(
              'Exemples de questions :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildExampleQuestion(context, 'Combien de rendez-vous ai-je ce mois-ci ?'),
            _buildExampleQuestion(context, 'Quels sont mes services les plus populaires ?'),
            _buildExampleQuestion(context, 'Quelles sont mes coiffeuses les plus demandées ?'),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleQuestion(BuildContext context, String question) {
    return GestureDetector(
      onTap: () {
        _messageController.text = question;
        setState(() {
          _isComposing = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          question,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<AIMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(context, message);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, AIMessage message) {
    final isUser = message.isUser;
    final dateFormat = DateFormat('HH:mm');
    final time = dateFormat.format(message.timestamp);
    final Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: primaryColor,
              child: const Icon(Icons.assistant, color: Colors.white, size: 20),
              radius: 16,
            ),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Remplacer le widget Text par cette nouvelle implémentation
                  isUser
                      ? Text(
                    message.content,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  )
                      : _buildMessageContent(message.content),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (message.tokensIn > 0 || message.tokensOut > 0)
                        Text(
                          '· ${isUser ? message.tokensIn : message.tokensOut} tokens',
                          style: TextStyle(
                            fontSize: 11,
                            color: isUser
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.grey.shade700,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
              radius: 16,
            ),
        ],
      ),
    );
  }

// Nouvelle méthode pour gérer le contenu des messages
  Widget _buildMessageContent(String content) {
    bool containsHtml = content.contains('<') && content.contains('>');

    if (containsHtml) {
      return HtmlWidget(
        content,
        textStyle: TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
      );
    }

    return Text(
      content,
      style: TextStyle(
        color: Colors.black87,
        fontSize: 15,
      ),
    );
  }

  // Widget _buildMessageBubble(BuildContext context, AIMessage message) {
  //   final isUser = message.isUser;
  //   final dateFormat = DateFormat('HH:mm');
  //   final time = dateFormat.format(message.timestamp);
  //   final Color primaryColor = Theme.of(context).primaryColor;
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 5),
  //     child: Row(
  //       mainAxisAlignment:
  //       isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         if (!isUser)
  //           CircleAvatar(
  //             backgroundColor: primaryColor,
  //             child: const Icon(Icons.assistant, color: Colors.white, size: 20),
  //             radius: 16,
  //           ),
  //
  //         const SizedBox(width: 8),
  //
  //         Flexible(
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //             decoration: BoxDecoration(
  //               color: isUser
  //                   ? primaryColor
  //                   : Colors.grey.shade200,
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.05),
  //                   blurRadius: 5,
  //                   offset: const Offset(0, 1),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               crossAxisAlignment:
  //               isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   message.content,
  //                   style: TextStyle(
  //                     color: isUser ? Colors.white : Colors.black87,
  //                     fontSize: 15,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 5),
  //                 Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Text(
  //                       time,
  //                       style: TextStyle(
  //                         fontSize: 11,
  //                         color: isUser
  //                             ? Colors.white.withOpacity(0.7)
  //                             : Colors.black54,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 5),
  //                     if (message.tokensIn > 0 || message.tokensOut > 0)
  //                       Text(
  //                         '· ${isUser ? message.tokensIn : message.tokensOut} tokens',
  //                         style: TextStyle(
  //                           fontSize: 11,
  //                           color: isUser
  //                               ? Colors.white.withOpacity(0.7)
  //                               : Colors.black54,
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //         const SizedBox(width: 8),
  //
  //         if (isUser)
  //           CircleAvatar(
  //             backgroundColor: Colors.grey.shade700,
  //             child: const Icon(Icons.person, color: Colors.white, size: 20),
  //             radius: 16,
  //           ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildInputArea(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: 'Posez une question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _isComposing ? (_) => _sendMessage(context) : null,
            ),
          ),
          const SizedBox(width: 8),
          Consumer<AIChatProvider>(
            builder: (context, chatProvider, child) {
              final isLoading = chatProvider.isLoading;

              return FloatingActionButton(
                onPressed: _isComposing && !isLoading
                    ? () => _sendMessage(context)
                    : null,
                mini: true,
                backgroundColor: _isComposing && !isLoading
                    ? primaryColor
                    : Colors.grey,
                child: isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.send),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final provider = Provider.of<AIChatProvider>(context, listen: false);
      provider.sendMessage(text);
      _messageController.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  void _showTokensInfo(BuildContext context) {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    final tokensUsed = provider.activeConversation?.tokensUsed ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Information sur les tokens'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tokens utilisés dans cette conversation: $tokensUsed'),
            const SizedBox(height: 10),
            const Text(
              'Les tokens sont des unités de texte utilisées par l\'IA. Plus vous échangez de messages, plus vous utilisez de tokens.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              'Conseil: Pour économiser des tokens, posez des questions précises et concises.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

}