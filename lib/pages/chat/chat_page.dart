import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/widgets/custom_app_bar.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/models/message.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import '../../services/my_drawer_service/my_drawer.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'chat_services/chat_notification_service.dart';

class ChatPage extends StatefulWidget {
  final CurrentUser currentUser;
  final String otherUserId;

  const ChatPage({super.key,
    required this.otherUserId,
    required this.currentUser,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final databaseRef = FirebaseDatabase.instance.ref();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late String chatId;
  CurrentUser? otherUser;
  bool isLoadingUser = true;
  bool isFirebaseConnected = false;
  String? errorMessage;
  String? debugInfo;
  final String baseUrl = "https://www.hairbnb.site";

  @override
  void initState() {
    super.initState();
    chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
        ? "${widget.currentUser.uuid}_${widget.otherUserId}"
        : "${widget.otherUserId}_${widget.currentUser.uuid}";

    _initializeChat();
  }

  /// Initialisation complète du chat
  Future<void> _initializeChat() async {
    await _checkFirebaseConnection();
    await _fetchOtherUserUnified();
    await _ensureChatExists();
  }

  /// Vérifier la connexion Firebase
  Future<void> _checkFirebaseConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = "Non connecté à Firebase";
          debugInfo = "❌ Firebase Auth: null";
        });
        return;
      }

      // Test de lecture Firebase
      await databaseRef.child('test').once();

      setState(() {
        isFirebaseConnected = true;
        debugInfo = "✅ Firebase connecté: ${user.uid}";
      });

      if (kDebugMode) {
        print("✅ Firebase connecté: ${user.uid}");
      }

    } catch (e) {
      setState(() {
        isFirebaseConnected = false;
        errorMessage = "Erreur Firebase: ${e.toString()}";
        debugInfo = "❌ Firebase error: $e";
      });

      if (kDebugMode) {
        print("❌ Erreur Firebase: $e");
      }
    }
  }

  /// S'assurer que la conversation existe dans Firebase
  Future<void> _ensureChatExists() async {
    if (!isFirebaseConnected) return;

    try {
      final chatSnapshot = await databaseRef.child(chatId).once();

      if (!chatSnapshot.snapshot.exists) {
        // Créer la conversation
        await databaseRef.child(chatId).set({
          'participants': {
            widget.currentUser.uuid: true,
            widget.otherUserId: true,
          },
          'created_at': ServerValue.timestamp,
          'messages': {},
        });

        if (kDebugMode) {
          print("✅ Conversation créée: $chatId");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur création conversation: $e");
      }
    }
  }

  /// ✅ Récupération utilisateur SIMPLIFIÉE et UNIFIÉE
  Future<void> _fetchOtherUserUnified() async {
    if (!mounted) return;

    setState(() {
      isLoadingUser = true;
      errorMessage = null;
      debugInfo = "🔍 Recherche utilisateur...";
    });

    try {
      if (kDebugMode) {
        print("🔍 Récupération des données pour l'utilisateur: ${widget.otherUserId}");
      }

      CurrentUser? user;

      // Stratégie 1: Endpoint unifié get_user_profile (PRIORITÉ)
      user = await _tryUnifiedEndpoint();

      // Stratégie 2: Fallback vers l'endpoint coiffeuses
      user ??= await _tryCoiffeusesEndpoint();

      // Stratégie 3: Dernier recours - endpoints clients
      user ??= await _tryIndividualClientEndpoint();

      if (mounted) {
        setState(() {
          otherUser = user;
          isLoadingUser = false;
          if (user != null) {
            debugInfo = "✅ Utilisateur trouvé: ${user.prenom} ${user.nom} (${user.type})";
            errorMessage = null;
            _debugLogUserData(user, "Après récupération API");
          } else {
            errorMessage = "Utilisateur introuvable";
            debugInfo = "❌ Toutes les stratégies ont échoué";
          }
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Erreur: $error");
      }
      if (mounted) {
        setState(() {
          isLoadingUser = false;
          errorMessage = "Erreur de chargement";
          debugInfo = "❌ Erreur: $error";
        });
      }
    }
  }

  /// ✅ Stratégie 1: Endpoint unifié (RECOMMANDÉ)
  Future<CurrentUser?> _tryUnifiedEndpoint() async {
    try {
      if (kDebugMode) {
        print("🔄 Test endpoint unifié pour: ${widget.otherUserId}");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/get_user_profile/${widget.otherUserId}/'),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 10));

      if (kDebugMode) {
        print("📡 Statut endpoint unifié: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["success"] == true && jsonData["data"] != null) {
          final userData = jsonData["data"];

          // ✅ Normaliser les champs pour éviter les incohérences
          final normalizedData = {
            'idTblUser': userData['idTblUser'] ?? 0,
            'uuid': userData['uuid'] ?? widget.otherUserId,
            'nom': userData['nom'] ?? '',
            'prenom': userData['prenom'] ?? '',
            'email': userData['email'] ?? '',
            'numero_telephone': userData['numero_telephone'],
            'date_naissance': userData['date_naissance'],
            'is_active': userData['is_active'] ?? true,
            'photo_profil': userData['photo_profil'], // Garder l'underscore
            'type': userData['type'] ?? 'client',
          };

          if (kDebugMode) {
            print("✅ Endpoint unifié réussi: ${userData['prenom']} ${userData['nom']}");
          }

          return CurrentUser.fromJson(normalizedData);
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print("ℹ️ Utilisateur non trouvé via endpoint unifié");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Erreur endpoint unifié: $error");
      }
    }
    return null;
  }

  /// ✅ Stratégie 2: Endpoint coiffeuses (MAINTENU pour compatibilité)
  Future<CurrentUser?> _tryCoiffeusesEndpoint() async {
    try {
      if (kDebugMode) {
        print("🔄 Test endpoint coiffeuses pour: ${widget.otherUserId}");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": [widget.otherUserId]}),
      ).timeout(Duration(seconds: 10));

      if (kDebugMode) {
        print("📡 Statut coiffeuses endpoint: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
          final coiffeusesList = jsonData["coiffeuses"] as List;

          for (var coiffeuseData in coiffeusesList) {
            if (coiffeuseData['uuid'] == widget.otherUserId) {
              // ✅ Convertir les données coiffeuse en CurrentUser NORMALISÉ
              final normalizedData = {
                'idTblUser': coiffeuseData['idTblUser'] ?? 0,
                'uuid': coiffeuseData['uuid'],
                'nom': coiffeuseData['nom'] ?? '',
                'prenom': coiffeuseData['prenom'] ?? '',
                'email': coiffeuseData['email'] ?? '',
                'numero_telephone': coiffeuseData['numero_telephone'],
                'date_naissance': coiffeuseData['date_naissance'],
                'is_active': coiffeuseData['is_active'] ?? true,
                'photo_profil': coiffeuseData['photo_profil'], // Underscore cohérent
                'type': 'coiffeuse',
              };

              if (kDebugMode) {
                print("✅ Coiffeuse trouvée et convertie: ${normalizedData['prenom']} ${normalizedData['nom']}");
              }

              return CurrentUser.fromJson(normalizedData);
            }
          }

          if (kDebugMode) {
            print("❌ UUID ${widget.otherUserId} non trouvé dans la liste des coiffeuses");
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Erreur endpoint coiffeuses: $error");
      }
    }
    return null;
  }

  /// ✅ Stratégie 3: Endpoint client individuel
  Future<CurrentUser?> _tryIndividualClientEndpoint() async {
    try {
      if (kDebugMode) {
        print("🔄 Test client individuel pour: ${widget.otherUserId}");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/get_client_by_uuid/${widget.otherUserId}/'),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 10));

      if (kDebugMode) {
        print("📡 Statut client: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"] == "success" && jsonData["data"] != null) {
          final clientData = jsonData["data"];

          final normalizedData = {
            'idTblUser': clientData['idTblUser'] ?? 0,
            'uuid': clientData['uuid'] ?? widget.otherUserId,
            'nom': clientData['nom'] ?? '',
            'prenom': clientData['prenom'] ?? '',
            'email': clientData['email'] ?? '',
            'numero_telephone': clientData['numero_telephone'],
            'date_naissance': clientData['date_naissance'],
            'is_active': clientData['is_active'] ?? true,
            'photo_profil': clientData['photo_profil'],
            'type': 'client',
          };

          if (kDebugMode) {
            print("✅ Client trouvé: ${normalizedData['prenom']} ${normalizedData['nom']}");
          }

          return CurrentUser.fromJson(normalizedData);
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print("ℹ️ Pas un client");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Erreur client: $error");
      }
    }
    return null;
  }

  /// ✅ Fonction de debug pour tracer les données utilisateur
  void _debugLogUserData(CurrentUser? user, String context) {
    if (kDebugMode && user != null) {
      if (kDebugMode) {
        print("🔍 [$context] Données utilisateur:");
      }
      if (kDebugMode) {
        print("  - UUID: ${user.uuid}");
      }
      if (kDebugMode) {
        print("  - Nom: ${user.nom}");
      }
      if (kDebugMode) {
        print("  - Prénom: ${user.prenom}");
      }
      if (kDebugMode) {
        print("  - Type: ${user.type}");
      }
      if (kDebugMode) {
        print("  - Photo: ${user.photoProfil}");
      }
      if (kDebugMode) {
        print("  - Email: ${user.email}");
      }
    }
  }

  /// ✅ Construire l'URL de la photo NORMALISÉE
  String? _getPhotoUrl(String? photoProfil) {
    if (photoProfil == null || photoProfil.isEmpty) {
      return null;
    }

    // Si l'URL est déjà complète
    if (photoProfil.startsWith('http://') || photoProfil.startsWith('https://')) {
      return photoProfil;
    }

    // Normaliser le chemin
    String normalizedPath = photoProfil;
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    return '$baseUrl$normalizedPath';
  }

  /// Envoyer un message avec gestion d'erreurs Firebase
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (!isFirebaseConnected) {
      _showErrorSnackBar("Pas de connexion Firebase");
      return;
    }

    try {
      // Vérifier l'authentification Firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _showErrorSnackBar("Non authentifié sur Firebase");
        return;
      }

      Message newMessage = Message(
        senderId: widget.currentUser.uuid,
        receiverId: widget.otherUserId,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Envoyer le message à Firebase
      await databaseRef
          .child(chatId)
          .child("messages")
          .push()
          .set(newMessage.toJson());

      if (kDebugMode) {
        print("✅ Message envoyé à Firebase avec succès");
      }

      // Envoyer la notification push SEULEMENT si otherUser existe
      if (otherUser != null) {
        final senderName = "${widget.currentUser.prenom} ${widget.currentUser.nom}".trim();

//         //-------------------------------
// // 🔍 DEBUG: Tracer exactement ce qui est envoyé
//         if (kDebugMode) {
//           print("🔍 === DEBUG NOTIFICATION ===");
//           print("🔍 Current user UUID: ${widget.currentUser.uuid}");
//           print("🔍 Other user UUID: ${widget.otherUserId}");
//           print("🔍 Chat ID: $chatId");
//           print("🔍 === FIN DEBUG ===");
//         }
//
// // 🔒 VALIDATION: Vérifier que l'ID du destinataire est correct
//         if (widget.otherUserId.isEmpty || widget.otherUserId == widget.currentUser.uuid) {
//           if (kDebugMode) {
//             print("❌ ERREUR: ID destinataire invalide: ${widget.otherUserId}");
//           }
//           return;
//         }
// //-------------------------------
//
//         if (kDebugMode) {
//           print("📤 Envoi notification à ${otherUser!.prenom} ${otherUser!.nom}");
//           print("📤 Chat ID: $chatId");
//           print("📤 Recipient ID: ${widget.otherUserId}");
//         }

        try {
          await ChatNotificationService.sendMessageNotification(
            chatId: chatId,
            senderName: senderName,
            messageContent: text.trim(),
            recipientId: widget.otherUserId,
          );

          if (kDebugMode) {
            print("✅ Notification envoyée avec succès");
          }
        } catch (notificationError) {
          // Ne pas faire échouer l'envoi du message si la notification échoue
          if (kDebugMode) {
            print("⚠️ Erreur notification (message envoyé quand même): $notificationError");
          }
        }
      } else {
        if (kDebugMode) {
          print("⚠️ otherUser est null - notification non envoyée");
        }
      }

      // Vider le champ uniquement si l'envoi du message a réussi
      _messageController.clear();

      // Faire défiler vers le bas
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollToBottom();
      });

    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur envoi message: $e");
      }

      String errorMsg = "Impossible d'envoyer le message";
      if (e.toString().contains('permission-denied')) {
        errorMsg = "Permissions insuffisantes";
      } else if (e.toString().contains('network')) {
        errorMsg = "Problème de réseau";
      }

      _showErrorSnackBar(errorMsg);
    }
  }

  /// Afficher une erreur à l'utilisateur
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: "Réessayer",
            textColor: Colors.white,
            onPressed: () => _initializeChat(),
          ),
        ),
      );
    }
  }

  /// Forcer le rechargement
  void _forceRefreshUser() async {
    setState(() {
      otherUser = null;
      isFirebaseConnected = false;
    });
    await _initializeChat();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: MyDrawer(currentUser: widget.currentUser),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: _buildProfileImage(),
                      radius: 25,
                      onBackgroundImageError: (exception, stackTrace) {
                        if (kDebugMode) {
                          print("❌ Erreur de chargement d'image: $exception");
                        }
                      },
                    ),
                    SizedBox(width: 10),
                    Expanded(child: _buildUserInfo()),
                    if (kDebugMode && (errorMessage != null || !isFirebaseConnected))
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _forceRefreshUser,
                        tooltip: "Recharger",
                      ),
                  ],
                ),
                // Indicateur de statut Firebase
                if (!isFirebaseConnected)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          "Connexion Firebase perdue",
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                // Infos de debug
                if (kDebugMode && debugInfo != null)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: errorMessage != null ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: errorMessage != null ? Colors.red.shade200 : Colors.blue.shade200
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          errorMessage != null ? Icons.error : Icons.info,
                          size: 16,
                          color: errorMessage != null ? Colors.red : Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            debugInfo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: errorMessage != null ? Colors.red.shade700 : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: databaseRef.child(chatId).child("messages").onValue,
              builder: (context, snapshot) {
                // Gestion des erreurs de permissions
                if (snapshot.hasError) {
                  String errorMsg = snapshot.error.toString();
                  if (errorMsg.contains('permission-denied')) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            "Permissions insuffisantes",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Impossible d'accéder aux messages",
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _forceRefreshUser,
                            child: Text("Réessayer"),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(child: Text("Erreur: $errorMsg"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Message> messages = data.entries.map((entry) {
                    return Message.fromJson(entry.value);
                  }).toList();

                  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  Future.delayed(Duration(milliseconds: 300), () {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      bool isSender = msg.senderId == widget.currentUser.uuid;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Align(
                          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSender ? Colors.blueAccent : Colors.grey.shade300,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(10),
                                topRight: const Radius.circular(10),
                                bottomLeft: isSender ? const Radius.circular(10) : Radius.zero,
                                bottomRight: isSender ? Radius.zero : const Radius.circular(10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: TextStyle(color: isSender ? Colors.white : Colors.black),
                                ),
                                const SizedBox(height: 5),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp.toUtc()),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text("Aucun message."));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    enabled: isFirebaseConnected, // Désactiver si pas de connexion
                    onSubmitted: (text) {
                      sendMessage(text);
                    },
                    decoration: InputDecoration(
                      hintText: isFirebaseConnected
                          ? "Écrire un message"
                          : "Connexion Firebase nécessaire",
                      filled: true,
                      fillColor: isFirebaseConnected
                          ? Colors.grey.shade200
                          : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: isFirebaseConnected
                      ? () => sendMessage(_messageController.text)
                      : null,
                  mini: true,
                  backgroundColor: isFirebaseConnected
                      ? null
                      : Colors.grey,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {},
      ),
    );
  }

  /// ✅ Construire l'image de profil NORMALISÉE
  ImageProvider _buildProfileImage() {
    if (otherUser == null) {
      return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
    }

    final photoUrl = _getPhotoUrl(otherUser?.photoProfil);
    if (photoUrl != null) {
      try {
        final uri = Uri.parse(photoUrl);
        if (uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https')) {
          return NetworkImage(photoUrl);
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ Erreur URL photo: $e");
        }
      }
    }

    return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
  }

  /// Construire les informations utilisateur avec type dynamique
  Widget _buildUserInfo() {
    if (isLoadingUser) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text("Chargement...", style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
    }

    if (otherUser != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${otherUser!.prenom} ${otherUser!.nom}".trim(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          // Badge avec le type d'utilisateur
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: otherUser!.type == 'coiffeuse' ? Colors.purple.shade600 : Colors.blue.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              otherUser!.type == 'coiffeuse' ? 'Coiffeuse' : 'Client',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            errorMessage ?? "Utilisateur introuvable",
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          Text(
            "ID: ${widget.otherUserId.length > 8 ? widget.otherUserId.substring(0, 8) : widget.otherUserId}",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
  }
}