// lib/pages/ai_chat/coiffeuse/coiffeuse_chat_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../services/providers/coiffeuse_ai_chat_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/bottom_nav_bar.dart';

class CoiffeuseAiChatPage extends StatefulWidget {
  final dynamic currentUser;

  const CoiffeuseAiChatPage({super.key, required this.currentUser});

  @override
  _CoiffeuseAiChatPageState createState() => _CoiffeuseAiChatPageState();
}

class _CoiffeuseAiChatPageState extends State<CoiffeuseAiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  // Couleurs spécifiques aux coiffeuses
  static const Color primaryCoiffeuseColor = Color(0xFFE91E63); // Rose vibrant
  static const Color secondaryCoiffeuseColor = Color(0xFF9C27B0); // Violet
  static const Color accentCoiffeuseColor = Color(0xFFFFC107); // Doré
  static const Color lightCoiffeuseColor = Color(0xFFFCE4EC); // Rose très clair

  @override
  void initState() {
    super.initState();

    // ✅ Vérifier si on a une conversation active au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
      if (kDebugMode) {
        print("🔍 Chat initState - activeConversation: ${provider.activeConversation?.id}");
      }

      // Si pas de conversation active, on peut en créer une nouvelle
      if (provider.activeConversation == null) {
        if (kDebugMode) {
          print("⚠️ Aucune conversation active dans le chat, création d'une nouvelle");
        }
        provider.createNewConversation();
      }
    });
  }

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
                  colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Assistant IA',
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
              leading: Icon(Icons.arrow_back, color: primaryCoiffeuseColor),
              title: Text('Retour aux conversations'),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                Navigator.pop(context); // Retourner à la liste
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: primaryCoiffeuseColor),
              title: Text('Nouvelle conversation'),
              onTap: () {
                Navigator.pop(context);
                _createNewConversation();
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: primaryCoiffeuseColor),
              title: Text('Aide'),
              onTap: () {
                Navigator.pop(context);
                _showTokensInfo(context);
              },
            ),
          ],
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lightCoiffeuseColor.withOpacity(0.3), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // ✅ Header spécialisé pour le chat IA
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryCoiffeuseColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assistant IA Coiffeuse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Consumer<CoiffeuseAIChatProvider>(
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
              child: Consumer<CoiffeuseAIChatProvider>(
                builder: (context, chatProvider, child) {
                  // ✅ Ajout de logs pour debug
                  if (kDebugMode) {
                    print("🔍 Chat Page - activeConversation: ${chatProvider.activeConversation?.id}");
                  }
                  if (kDebugMode) {
                    print("🔍 Chat Page - hasActiveConversation: ${chatProvider.hasActiveConversation}");
                  }
                  if (kDebugMode) {
                    print("🔍 Chat Page - isLoading: ${chatProvider.isLoading}");
                  }

                  // ✅ Affichage conditionnel amélioré
                  if (chatProvider.activeConversation == null) {
                    // Si on est en train de créer une conversation, on affiche un loader
                    if (chatProvider.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: primaryCoiffeuseColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Création de votre conversation...',
                              style: TextStyle(
                                fontSize: 16,
                                color: primaryCoiffeuseColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Sinon, on affiche une interface permettant de créer une conversation
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: primaryCoiffeuseColor.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune conversation active',
                            style: TextStyle(
                              fontSize: 18,
                              color: primaryCoiffeuseColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Créer une conversation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryCoiffeuseColor,
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

                  // ✅ Le reste du code - conversation active trouvée
                  _scrollToBottom();

                  return Column(
                    children: [
                      // Indicateur de chargement
                      if (chatProvider.isLoading)
                        SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            backgroundColor: primaryCoiffeuseColor.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryCoiffeuseColor),
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

                      // ✅ Zone de saisie TOUJOURS affichée si on a une conversation active
                      _buildInputArea(context),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
    final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
    if (kDebugMode) {
      print("🚀 Création manuelle d'une nouvelle conversation");
    }
    await provider.createNewConversation();
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryCoiffeuseColor.withOpacity(0.1), secondaryCoiffeuseColor.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 80,
              color: primaryCoiffeuseColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '✨ Bienvenue dans votre Assistant IA ✨',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryCoiffeuseColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Je suis là pour vous aider à analyser vos données, optimiser votre salon et booster votre activité !',
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
              color: primaryCoiffeuseColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleQuestion(
            context,
            '📊 Combien de rendez-vous ai-je ce mois-ci ?',
            Icons.analytics,
          ),
          _buildExampleQuestion(
            context,
            '⭐ Quels sont mes services les plus populaires ?',
            Icons.trending_up,
          ),
          _buildExampleQuestion(
            context,
            '💰 Quel est mon chiffre d\'affaires cette semaine ?',
            Icons.attach_money,
          ),
          _buildExampleQuestion(
            context,
            '📅 Combien de créneaux libres ai-je demain ?',
            Icons.schedule,
          ),
          _buildExampleQuestion(
            context,
            '🎯 Comment améliorer ma visibilité ?',
            Icons.lightbulb,
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentCoiffeuseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentCoiffeuseColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, color: accentCoiffeuseColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Astuce: Posez des questions précises pour obtenir des réponses personnalisées à votre salon !',
                    style: TextStyle(
                      fontSize: 14,
                      color: accentCoiffeuseColor.withOpacity(0.8),
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

  Widget _buildExampleQuestion(BuildContext context, String question, IconData icon) {
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
                colors: [Colors.white, lightCoiffeuseColor.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryCoiffeuseColor.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryCoiffeuseColor.withOpacity(0.1),
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
                    color: primaryCoiffeuseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryCoiffeuseColor, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      color: primaryCoiffeuseColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: primaryCoiffeuseColor.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List messages) {
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

  Widget _buildMessageBubble(BuildContext context, dynamic message) {
    final isUser = message.isUser;
    final dateFormat = DateFormat('HH:mm');
    final time = dateFormat.format(message.timestamp);

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
                  colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                  colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.white, lightCoiffeuseColor.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? primaryCoiffeuseColor.withOpacity(0.3)
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
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey.shade600,
                    ),
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
              child: Icon(Icons.person, color: primaryCoiffeuseColor, size: 16),
            ),
        ],
      ),
    );
  }

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryCoiffeuseColor.withOpacity(0.1),
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
                color: lightCoiffeuseColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: primaryCoiffeuseColor.withOpacity(0.2),
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
                  hintText: 'Posez votre question...',
                  hintStyle: TextStyle(color: primaryCoiffeuseColor.withOpacity(0.6)),
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
          Consumer<CoiffeuseAIChatProvider>(
            builder: (context, chatProvider, child) {
              final isLoading = chatProvider.isSendingMessage;

              return Container(
                decoration: BoxDecoration(
                  gradient: _isComposing && !isLoading
                      ? LinearGradient(
                    colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
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
      final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
      provider.sendMessage(text);
      _messageController.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  void _showTokensInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: primaryCoiffeuseColor),
            SizedBox(width: 8),
            Text(
              'Information sur l\'IA',
              style: TextStyle(color: primaryCoiffeuseColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightCoiffeuseColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: primaryCoiffeuseColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Votre assistant IA personnel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryCoiffeuseColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(Icons.analytics, 'Analyse vos données en temps réel'),
            _buildInfoRow(Icons.schedule, 'Optimise votre planning'),
            _buildInfoRow(Icons.trending_up, 'Identifie vos opportunités'),
            _buildInfoRow(Icons.lightbulb, 'Propose des conseils personnalisés'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentCoiffeuseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Plus vos questions sont précises, plus les réponses seront utiles pour votre salon !',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: accentCoiffeuseColor.withOpacity(0.8),
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
              style: TextStyle(color: primaryCoiffeuseColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryCoiffeuseColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}









// // lib/pages/ai_chat/coiffeuse/coiffeuse_chat_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
//
// import '../../../services/providers/coiffeuse_ai_chat_provider.dart';
//
// class CoiffeuseAiChatPage extends StatefulWidget {
//   final dynamic currentUser;
//
//   const CoiffeuseAiChatPage({super.key, required this.currentUser});
//
//   @override
//   _CoiffeuseAiChatPageState createState() => _CoiffeuseAiChatPageState();
// }
//
// class _CoiffeuseAiChatPageState extends State<CoiffeuseAiChatPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isComposing = false;
//
//   // Couleurs spécifiques aux coiffeuses
//   static const Color primaryCoiffeuseColor = Color(0xFFE91E63); // Rose vibrant
//   static const Color secondaryCoiffeuseColor = Color(0xFF9C27B0); // Violet
//   static const Color accentCoiffeuseColor = Color(0xFFFFC107); // Doré
//   static const Color lightCoiffeuseColor = Color(0xFFFCE4EC); // Rose très clair
//
//   @override
//   void initState() {
//     super.initState();
//
//     // ✅ Vérifier si on a une conversation active au démarrage
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
//       print("🔍 Chat initState - activeConversation: ${provider.activeConversation?.id}");
//
//       // Si pas de conversation active, on peut en créer une nouvelle
//       if (provider.activeConversation == null) {
//         print("⚠️ Aucune conversation active dans le chat, création d'une nouvelle");
//         provider.createNewConversation();
//       }
//     });
//   }
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
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             Icon(Icons.auto_awesome, color: Colors.white),
//             SizedBox(width: 8),
//             Text(
//               'Assistant IA Coiffeuse',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         backgroundColor: primaryCoiffeuseColor,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline, color: Colors.white),
//             onPressed: () => _showTokensInfo(context),
//           ),
//         ],
//       ),
//       body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [lightCoiffeuseColor.withOpacity(0.3), Colors.white],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: Consumer<CoiffeuseAIChatProvider>(
//             builder: (context, chatProvider, child) {
//               // ✅ Ajout de logs pour debug
//               print("🔍 Chat Page - activeConversation: ${chatProvider.activeConversation?.id}");
//               print("🔍 Chat Page - hasActiveConversation: ${chatProvider.hasActiveConversation}");
//               print("🔍 Chat Page - isLoading: ${chatProvider.isLoading}");
//
//               // ✅ Affichage conditionnel amélioré
//               if (chatProvider.activeConversation == null) {
//                 // Si on est en train de créer une conversation, on affiche un loader
//                 if (chatProvider.isLoading) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(
//                           color: primaryCoiffeuseColor,
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'Création de votre conversation...',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: primaryCoiffeuseColor,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 // Sinon, on affiche une interface permettant de créer une conversation
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.chat_bubble_outline,
//                         size: 80,
//                         color: primaryCoiffeuseColor.withOpacity(0.5),
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Aucune conversation active',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: primaryCoiffeuseColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       ElevatedButton.icon(
//                         icon: Icon(Icons.add_circle_outline),
//                         label: Text('Créer une conversation'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryCoiffeuseColor,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(25),
//                           ),
//                         ),
//                         onPressed: () async {
//                           print("🚀 Création manuelle d'une nouvelle conversation");
//                           await chatProvider.createNewConversation();
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               }
//
//               // ✅ Le reste du code - conversation active trouvée
//               _scrollToBottom();
//
//               return Column(
//                 children: [
//                   // Indicateur de chargement
//                   if (chatProvider.isLoading)
//                     Container(
//                       height: 4,
//                       child: LinearProgressIndicator(
//                         backgroundColor: primaryCoiffeuseColor.withOpacity(0.2),
//                         valueColor: AlwaysStoppedAnimation<Color>(primaryCoiffeuseColor),
//                       ),
//                     ),
//
//                   // Zone de messages
//                   Expanded(
//                     child: chatProvider.activeConversation!.messages.isEmpty
//                         ? _buildWelcomeMessage(context)
//                         : _buildMessagesList(context, chatProvider.activeConversation!.messages),
//                   ),
//
//                   // Barre d'erreur (visible seulement en cas d'erreur)
//                   if (chatProvider.error != null)
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         border: Border(
//                           top: BorderSide(color: Colors.red.shade200, width: 1),
//                         ),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                       child: Row(
//                         children: [
//                           Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'Erreur: ${chatProvider.error}',
//                               style: TextStyle(color: Colors.red.shade700, fontSize: 14),
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close, size: 20),
//                             onPressed: () => chatProvider.clearError(),
//                             color: Colors.red.shade700,
//                           ),
//                         ],
//                       ),
//                     ),
//
//                   // ✅ Zone de saisie TOUJOURS affichée si on a une conversation active
//                   _buildInputArea(context),
//                 ],
//               );
//             },
//           )
//       ),
//     );
//   }
//
//   Widget _buildWelcomeMessage(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [primaryCoiffeuseColor.withOpacity(0.1), secondaryCoiffeuseColor.withOpacity(0.1)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Icon(
//               Icons.auto_awesome,
//               size: 80,
//               color: primaryCoiffeuseColor,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             '✨ Bienvenue dans votre Assistant IA ✨',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: primaryCoiffeuseColor,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Je suis là pour vous aider à analyser vos données, optimiser votre salon et booster votre activité !',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade700,
//               height: 1.4,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 32),
//           Text(
//             '💡 Exemples de questions :',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: primaryCoiffeuseColor,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildExampleQuestion(
//             context,
//             '📊 Combien de rendez-vous ai-je ce mois-ci ?',
//             Icons.analytics,
//           ),
//           _buildExampleQuestion(
//             context,
//             '⭐ Quels sont mes services les plus populaires ?',
//             Icons.trending_up,
//           ),
//           _buildExampleQuestion(
//             context,
//             '💰 Quel est mon chiffre d\'affaires cette semaine ?',
//             Icons.attach_money,
//           ),
//           _buildExampleQuestion(
//             context,
//             '📅 Combien de créneaux libres ai-je demain ?',
//             Icons.schedule,
//           ),
//           _buildExampleQuestion(
//             context,
//             '🎯 Comment améliorer ma visibilité ?',
//             Icons.lightbulb,
//           ),
//           SizedBox(height: 24),
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: accentCoiffeuseColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: accentCoiffeuseColor.withOpacity(0.3)),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.tips_and_updates, color: accentCoiffeuseColor),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     'Astuce: Posez des questions précises pour obtenir des réponses personnalisées à votre salon !',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: accentCoiffeuseColor.withOpacity(0.8),
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildExampleQuestion(BuildContext context, String question, IconData icon) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () {
//             _messageController.text = question;
//             setState(() {
//               _isComposing = true;
//             });
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.white, lightCoiffeuseColor.withOpacity(0.5)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: primaryCoiffeuseColor.withOpacity(0.2),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: primaryCoiffeuseColor.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: primaryCoiffeuseColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(icon, color: primaryCoiffeuseColor, size: 18),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     question,
//                     style: TextStyle(
//                       color: primaryCoiffeuseColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 Icon(
//                   Icons.arrow_forward_ios,
//                   color: primaryCoiffeuseColor.withOpacity(0.5),
//                   size: 14,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessagesList(BuildContext context, List messages) {
//     return ListView.builder(
//       controller: _scrollController,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       itemCount: messages.length,
//       itemBuilder: (context, index) {
//         final message = messages[index];
//         return _buildMessageBubble(context, message);
//       },
//     );
//   }
//
//   Widget _buildMessageBubble(BuildContext context, dynamic message) {
//     final isUser = message.isUser;
//     final dateFormat = DateFormat('HH:mm');
//     final time = dateFormat.format(message.timestamp);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!isUser)
//             Container(
//               margin: EdgeInsets.only(right: 12),
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
//             ),
//
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 gradient: isUser
//                     ? LinearGradient(
//                   colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 )
//                     : LinearGradient(
//                   colors: [Colors.white, lightCoiffeuseColor.withOpacity(0.3)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: isUser
//                         ? primaryCoiffeuseColor.withOpacity(0.3)
//                         : Colors.black.withOpacity(0.1),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                 children: [
//                   isUser
//                       ? Text(
//                     message.content,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       height: 1.4,
//                     ),
//                   )
//                       : _buildMessageContent(message.content),
//                   const SizedBox(height: 6),
//                   Text(
//                     time,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: isUser
//                           ? Colors.white.withOpacity(0.8)
//                           : Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           if (isUser)
//             Container(
//               margin: EdgeInsets.only(left: 12),
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade200,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.person, color: primaryCoiffeuseColor, size: 16),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMessageContent(String content) {
//     bool containsHtml = content.contains('<') && content.contains('>');
//
//     if (containsHtml) {
//       return HtmlWidget(
//         content,
//         textStyle: TextStyle(
//           color: Colors.black87,
//           fontSize: 15,
//           height: 1.4,
//         ),
//       );
//     }
//
//     return Text(
//       content,
//       style: TextStyle(
//         color: Colors.black87,
//         fontSize: 15,
//         height: 1.4,
//       ),
//     );
//   }
//
//   Widget _buildInputArea(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: primaryCoiffeuseColor.withOpacity(0.1),
//             blurRadius: 10,
//             spreadRadius: 1,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: lightCoiffeuseColor.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(25),
//                 border: Border.all(
//                   color: primaryCoiffeuseColor.withOpacity(0.2),
//                 ),
//               ),
//               child: TextField(
//                 controller: _messageController,
//                 onChanged: (text) {
//                   setState(() {
//                     _isComposing = text.trim().isNotEmpty;
//                   });
//                 },
//                 decoration: InputDecoration(
//                   hintText: 'Posez votre question...',
//                   hintStyle: TextStyle(color: primaryCoiffeuseColor.withOpacity(0.6)),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 ),
//                 textCapitalization: TextCapitalization.sentences,
//                 keyboardType: TextInputType.multiline,
//                 maxLines: null,
//                 textInputAction: TextInputAction.send,
//                 onSubmitted: _isComposing ? (_) => _sendMessage(context) : null,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Consumer<CoiffeuseAIChatProvider>(
//             builder: (context, chatProvider, child) {
//               final isLoading = chatProvider.isSendingMessage;
//
//               return Container(
//                 decoration: BoxDecoration(
//                   gradient: _isComposing && !isLoading
//                       ? LinearGradient(
//                     colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   )
//                       : LinearGradient(
//                     colors: [Colors.grey.shade400, Colors.grey.shade500],
//                   ),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: Material(
//                   color: Colors.transparent,
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(25),
//                     onTap: _isComposing && !isLoading ? () => _sendMessage(context) : null,
//                     child: Container(
//                       padding: EdgeInsets.all(12),
//                       child: isLoading
//                           ? SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                           : Icon(
//                         Icons.send,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
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
//       final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
//       provider.sendMessage(text);
//       _messageController.clear();
//       setState(() {
//         _isComposing = false;
//       });
//     }
//   }
//
//   void _showTokensInfo(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.info, color: primaryCoiffeuseColor),
//             SizedBox(width: 8),
//             Text(
//               'Information sur l\'IA',
//               style: TextStyle(color: primaryCoiffeuseColor),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: lightCoiffeuseColor.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.auto_awesome, color: primaryCoiffeuseColor, size: 20),
//                   SizedBox(width: 8),
//                   Text(
//                     'Votre assistant IA personnel',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: primaryCoiffeuseColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16),
//             _buildInfoRow(Icons.analytics, 'Analyse vos données en temps réel'),
//             _buildInfoRow(Icons.schedule, 'Optimise votre planning'),
//             _buildInfoRow(Icons.trending_up, 'Identifie vos opportunités'),
//             _buildInfoRow(Icons.lightbulb, 'Propose des conseils personnalisés'),
//             SizedBox(height: 16),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: accentCoiffeuseColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 '💡 Plus vos questions sont précises, plus les réponses seront utiles pour votre salon !',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontStyle: FontStyle.italic,
//                   color: accentCoiffeuseColor.withOpacity(0.8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text(
//               'Compris !',
//               style: TextStyle(color: primaryCoiffeuseColor, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(IconData icon, String text) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: primaryCoiffeuseColor),
//           SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }