// lib/screens/ai_chat/chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/ai_chat.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/bottom_nav_bar.dart';

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
      // ✅ Ajout du CustomAppBar
      appBar: CustomAppBar(),

      // ✅ Drawer pour la navigation
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.assistant, color: Colors.white, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Assistant Hairbnb',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Chat en cours...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_back, color: primaryColor),
              title: Text('Retour aux conversations'),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                Navigator.pop(context); // Retourner à la liste
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: primaryColor),
              title: Text('Nouvelle conversation'),
              onTap: () {
                Navigator.pop(context);
                _createNewConversation();
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: primaryColor),
              title: Text('Informations tokens'),
              onTap: () {
                Navigator.pop(context);
                _showTokensInfo(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: primaryColor),
              title: Text('Statistiques'),
              onTap: () {
                Navigator.pop(context);
                // Naviguer vers les statistiques
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ✅ Header spécialisé pour l'assistant Hairbnb
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.assistant, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant Hairbnb',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Consumer<AIChatProvider>(
                        builder: (context, chatProvider, child) {
                          return Text(
                            chatProvider.activeConversation != null
                                ? 'Conversation active • ${chatProvider.activeConversation!.messages.length} messages'
                                : 'Aucune conversation',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () => _showTokensInfo(context),
                ),
              ],
            ),
          ),

          // ✅ Contenu principal du chat
          Expanded(
            child: Consumer<AIChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.activeConversation == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: primaryColor.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune conversation active',
                          style: TextStyle(
                            fontSize: 18,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_circle_outline),
                          label: Text('Créer une conversation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () => _createNewConversation(),
                        ),
                      ],
                    ),
                  );
                }

                // Faire défiler vers le bas à chaque mise à jour des messages
                _scrollToBottom();

                return Column(
                  children: [
                    // Indicateur de chargement
                    if (chatProvider.isLoading)
                      Container(
                        height: 4,
                        child: LinearProgressIndicator(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
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
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border(
                            top: BorderSide(color: Colors.red.shade200, width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Erreur: ${chatProvider.error}',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => chatProvider.clearError(),
                              color: Colors.red.shade700,
                            ),
                          ],
                        ),
                      ),

                    // Compteur de tokens
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.token, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'Tokens utilisés: ${chatProvider.activeConversation!.tokensUsed}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.help_outline, size: 16),
                            label: Text('Aide'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () => _showTokensInfo(context),
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
          ),
        ],
      ),

      // ✅ Ajout du BottomNavBar
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4, // Index pour "Profil" ou selon votre logique
        onTap: (index) {
          // La gestion est faite dans BottomNavBar lui-même
        },
      ),
    );
  }

  // ✅ Méthode pour créer une nouvelle conversation
  void _createNewConversation() async {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    print("🚀 Création manuelle d'une nouvelle conversation");
    // Vous pouvez implémenter la logique de création ici selon votre provider
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.assistant,
              size: 80,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🤖 Bienvenue sur l\'assistant Hairbnb',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Je peux vous aider avec les statistiques de votre application, les réservations, les coiffeuses, les salons et bien plus encore.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            '💡 Exemples de questions :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleQuestion(context, '📊 Combien de rendez-vous ai-je ce mois-ci ?'),
          _buildExampleQuestion(context, '⭐ Quels sont mes services les plus populaires ?'),
          _buildExampleQuestion(context, '👩‍💼 Quelles sont mes coiffeuses les plus demandées ?'),
          _buildExampleQuestion(context, '💰 Quel est mon chiffre d\'affaires cette semaine ?'),
          _buildExampleQuestion(context, '📈 Comment puis-je améliorer mon salon ?'),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Astuce: Posez des questions précises pour obtenir des réponses personnalisées !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleQuestion(BuildContext context, String question) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _messageController.text = question;
            setState(() {
              _isComposing = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Theme.of(context).primaryColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chat, color: Theme.of(context).primaryColor, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<AIMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.assistant, color: Colors.white, size: 16),
            ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? primaryColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Text(
                    message.content,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  )
                      : _buildMessageContent(message.content),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey.shade600,
                        ),
                      ),
                      if (message.tokensIn > 0 || message.tokensOut > 0) ...[
                        Text(
                          ' • ${isUser ? message.tokensIn : message.tokensOut} tokens',
                          style: TextStyle(
                            fontSize: 11,
                            color: isUser
                                ? Colors.white.withOpacity(0.8)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isUser)
            Container(
              margin: EdgeInsets.only(left: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, color: primaryColor, size: 16),
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
          height: 1.4,
        ),
      );
    }

    return Text(
      content,
      style: TextStyle(
        color: Colors.black87,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Posez une question...',
                  hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _isComposing ? (_) => _sendMessage(context) : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<AIChatProvider>(
            builder: (context, chatProvider, child) {
              final isLoading = chatProvider.isLoading;

              return Container(
                decoration: BoxDecoration(
                  gradient: _isComposing && !isLoading
                      ? LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: _isComposing && !isLoading ? () => _sendMessage(context) : null,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      child: isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('Information sur les tokens'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.token, color: Theme.of(context).primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tokens utilisés: $tokensUsed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Les tokens sont des unités de texte utilisées par l\'IA. Plus vous échangez de messages, plus vous utilisez de tokens.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Conseil: Pour économiser des tokens, posez des questions précises et concises.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Compris !',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}










// // lib/screens/ai_chat/chat_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
//
// import '../../models/ai_chat.dart';
//
// class AiChatPage extends StatefulWidget {
//   final dynamic currentUser;
//
//   const AiChatPage({super.key, required this.currentUser});
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<AiChatPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isComposing = false;
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Assistant Hairbnb'),
//         backgroundColor: primaryColor,
//         actions: [
//           // Bouton d'information sur les tokens
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: () => _showTokensInfo(context),
//           ),
//         ],
//       ),
//       body: Consumer<AIChatProvider>(
//         builder: (context, chatProvider, child) {
//           //
//           // // -----------------------------------------------------------------------------------------------------------------------
//           // print("État actuel: activeConversation=${chatProvider.activeConversation?.id}, isLoading=${chatProvider.isLoading}");
//           // //------------------------------------------------------------------------------------------------------------------------
//
//           if (chatProvider.activeConversation == null) {
//             return const Center(
//               child: Text('Aucune conversation active'),
//             );
//           }
//
//           // Faire défiler vers le bas à chaque mise à jour des messages
//           _scrollToBottom();
//
//           return Column(
//             children: [
//               // Indicateur de chargement
//               if (chatProvider.isLoading)
//                 LinearProgressIndicator(
//                   backgroundColor: primaryColor.withOpacity(0.3),
//                   valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                 ),
//
//               // Zone de messages
//               Expanded(
//                 child: chatProvider.activeConversation!.messages.isEmpty
//                     ? _buildWelcomeMessage(context)
//                     : _buildMessagesList(context, chatProvider.activeConversation!.messages),
//               ),
//
//               // Barre d'erreur (visible seulement en cas d'erreur)
//               if (chatProvider.error != null)
//                 Container(
//                   color: Colors.red.shade50,
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                   child: Row(
//                     children: [
//                       Icon(Icons.error_outline, color: Colors.red.shade700),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Erreur: ${chatProvider.error}',
//                           style: TextStyle(color: Colors.red.shade700),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => chatProvider.clearError(),
//                         color: Colors.red.shade700,
//                       ),
//                     ],
//                   ),
//                 ),
//
//               // Compteur de tokens
//               Container(
//                 padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
//                 color: Colors.grey.shade100,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Icon(Icons.token, size: 14, color: Colors.grey.shade600),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Tokens: ${chatProvider.activeConversation!.tokensUsed}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Zone de saisie
//               _buildInputArea(context),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildWelcomeMessage(BuildContext context) {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.assistant, size: 100, color: primaryColor.withOpacity(0.7)),
//             const SizedBox(height: 20),
//             const Text(
//               'Bienvenue sur l\'assistant Hairbnb',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 15),
//             Text(
//               'Je peux vous aider avec les statistiques de votre application, les réservations, les coiffeuses, les salons et bien plus encore.',
//               style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'Exemples de questions :',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildExampleQuestion(context, 'Combien de rendez-vous ai-je ce mois-ci ?'),
//             _buildExampleQuestion(context, 'Quels sont mes services les plus populaires ?'),
//             _buildExampleQuestion(context, 'Quelles sont mes coiffeuses les plus demandées ?'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildExampleQuestion(BuildContext context, String question) {
//     return GestureDetector(
//       onTap: () {
//         _messageController.text = question;
//         setState(() {
//           _isComposing = true;
//         });
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 5),
//         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//         decoration: BoxDecoration(
//           color: Theme.of(context).primaryColor.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(
//             color: Theme.of(context).primaryColor.withOpacity(0.3),
//           ),
//         ),
//         child: Text(
//           question,
//           style: TextStyle(color: Theme.of(context).primaryColor),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessagesList(BuildContext context, List<AIMessage> messages) {
//     return ListView.builder(
//       controller: _scrollController,
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//       itemCount: messages.length,
//       itemBuilder: (context, index) {
//         final message = messages[index];
//         return _buildMessageBubble(context, message);
//       },
//     );
//   }
//
//   Widget _buildMessageBubble(BuildContext context, AIMessage message) {
//     final isUser = message.isUser;
//     final dateFormat = DateFormat('HH:mm');
//     final time = dateFormat.format(message.timestamp);
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         mainAxisAlignment:
//         isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!isUser)
//             CircleAvatar(
//               backgroundColor: primaryColor,
//               child: const Icon(Icons.assistant, color: Colors.white, size: 20),
//               radius: 16,
//             ),
//
//           const SizedBox(width: 8),
//
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 color: isUser
//                     ? primaryColor
//                     : Colors.grey.shade200,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 5,
//                     offset: const Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment:
//                 isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                 children: [
//                   // Remplacer le widget Text par cette nouvelle implémentation
//                   isUser
//                       ? Text(
//                     message.content,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                     ),
//                   )
//                       : _buildMessageContent(message.content),
//                   const SizedBox(height: 5),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         time,
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: isUser
//                               ? Colors.white.withOpacity(0.7)
//                               : Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       if (message.tokensIn > 0 || message.tokensOut > 0)
//                         Text(
//                           '· ${isUser ? message.tokensIn : message.tokensOut} tokens',
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: isUser
//                                 ? Colors.white.withOpacity(0.7)
//                                 : Colors.black54,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           if (isUser)
//             CircleAvatar(
//               backgroundColor: Colors.grey.shade700,
//               child: const Icon(Icons.person, color: Colors.white, size: 20),
//               radius: 16,
//             ),
//         ],
//       ),
//     );
//   }
//
// // Nouvelle méthode pour gérer le contenu des messages
//   Widget _buildMessageContent(String content) {
//     bool containsHtml = content.contains('<') && content.contains('>');
//
//     if (containsHtml) {
//       return HtmlWidget(
//         content,
//         textStyle: TextStyle(
//           color: Colors.black87,
//           fontSize: 15,
//         ),
//       );
//     }
//
//     return Text(
//       content,
//       style: TextStyle(
//         color: Colors.black87,
//         fontSize: 15,
//       ),
//     );
//   }
//
//   // Widget _buildMessageBubble(BuildContext context, AIMessage message) {
//   //   final isUser = message.isUser;
//   //   final dateFormat = DateFormat('HH:mm');
//   //   final time = dateFormat.format(message.timestamp);
//   //   final Color primaryColor = Theme.of(context).primaryColor;
//   //
//   //   return Padding(
//   //     padding: const EdgeInsets.symmetric(vertical: 5),
//   //     child: Row(
//   //       mainAxisAlignment:
//   //       isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         if (!isUser)
//   //           CircleAvatar(
//   //             backgroundColor: primaryColor,
//   //             child: const Icon(Icons.assistant, color: Colors.white, size: 20),
//   //             radius: 16,
//   //           ),
//   //
//   //         const SizedBox(width: 8),
//   //
//   //         Flexible(
//   //           child: Container(
//   //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//   //             decoration: BoxDecoration(
//   //               color: isUser
//   //                   ? primaryColor
//   //                   : Colors.grey.shade200,
//   //               borderRadius: BorderRadius.circular(20),
//   //               boxShadow: [
//   //                 BoxShadow(
//   //                   color: Colors.black.withOpacity(0.05),
//   //                   blurRadius: 5,
//   //                   offset: const Offset(0, 1),
//   //                 ),
//   //               ],
//   //             ),
//   //             child: Column(
//   //               crossAxisAlignment:
//   //               isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//   //               children: [
//   //                 Text(
//   //                   message.content,
//   //                   style: TextStyle(
//   //                     color: isUser ? Colors.white : Colors.black87,
//   //                     fontSize: 15,
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 5),
//   //                 Row(
//   //                   mainAxisSize: MainAxisSize.min,
//   //                   children: [
//   //                     Text(
//   //                       time,
//   //                       style: TextStyle(
//   //                         fontSize: 11,
//   //                         color: isUser
//   //                             ? Colors.white.withOpacity(0.7)
//   //                             : Colors.black54,
//   //                       ),
//   //                     ),
//   //                     const SizedBox(width: 5),
//   //                     if (message.tokensIn > 0 || message.tokensOut > 0)
//   //                       Text(
//   //                         '· ${isUser ? message.tokensIn : message.tokensOut} tokens',
//   //                         style: TextStyle(
//   //                           fontSize: 11,
//   //                           color: isUser
//   //                               ? Colors.white.withOpacity(0.7)
//   //                               : Colors.black54,
//   //                         ),
//   //                       ),
//   //                   ],
//   //                 ),
//   //               ],
//   //             ),
//   //           ),
//   //         ),
//   //
//   //         const SizedBox(width: 8),
//   //
//   //         if (isUser)
//   //           CircleAvatar(
//   //             backgroundColor: Colors.grey.shade700,
//   //             child: const Icon(Icons.person, color: Colors.white, size: 20),
//   //             radius: 16,
//   //           ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   Widget _buildInputArea(BuildContext context) {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             blurRadius: 5,
//             spreadRadius: 1,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               onChanged: (text) {
//                 setState(() {
//                   _isComposing = text.isNotEmpty;
//                 });
//               },
//               decoration: InputDecoration(
//                 hintText: 'Posez une question...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey.shade100,
//                 contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//               textCapitalization: TextCapitalization.sentences,
//               keyboardType: TextInputType.multiline,
//               maxLines: null,
//               textInputAction: TextInputAction.send,
//               onSubmitted: _isComposing ? (_) => _sendMessage(context) : null,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Consumer<AIChatProvider>(
//             builder: (context, chatProvider, child) {
//               final isLoading = chatProvider.isLoading;
//
//               return FloatingActionButton(
//                 onPressed: _isComposing && !isLoading
//                     ? () => _sendMessage(context)
//                     : null,
//                 mini: true,
//                 backgroundColor: _isComposing && !isLoading
//                     ? primaryColor
//                     : Colors.grey,
//                 child: isLoading
//                     ? SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 )
//                     : const Icon(Icons.send),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _sendMessage(BuildContext context) {
//     final text = _messageController.text.trim();
//     if (text.isNotEmpty) {
//       final provider = Provider.of<AIChatProvider>(context, listen: false);
//       provider.sendMessage(text);
//       _messageController.clear();
//       setState(() {
//         _isComposing = false;
//       });
//     }
//   }
//
//   void _showTokensInfo(BuildContext context) {
//     final provider = Provider.of<AIChatProvider>(context, listen: false);
//     final tokensUsed = provider.activeConversation?.tokensUsed ?? 0;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Information sur les tokens'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Tokens utilisés dans cette conversation: $tokensUsed'),
//             const SizedBox(height: 10),
//             const Text(
//               'Les tokens sont des unités de texte utilisées par l\'IA. Plus vous échangez de messages, plus vous utilisez de tokens.',
//               style: TextStyle(fontSize: 14),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Conseil: Pour économiser des tokens, posez des questions précises et concises.',
//               style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Fermer'),
//           ),
//         ],
//       ),
//     );
//   }
//
// }