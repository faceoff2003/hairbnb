import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/services/firebase_token/token_service.dart';
import 'package:hairbnb/widgets/custom_app_bar.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/models/message.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import '../../services/my_drawer_service/my_drawer.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? errorMessage;
  String? debugInfo;
  final String baseUrl = "https://www.hairbnb.site";

  @override
  void initState() {
    super.initState();
    chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
        ? "${widget.currentUser.uuid}_${widget.otherUserId}"
        : "${widget.otherUserId}_${widget.currentUser.uuid}";
    _fetchOtherUser();
  }

  /// Récupération de l'autre utilisateur en utilisant TokenService
  Future<void> _fetchOtherUser() async {
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

      // Utiliser le TokenService pour récupérer le token
      final token = await TokenService.getAuthToken();

      if (token == null) {
        if (kDebugMode) {
          print("❌ Aucun token d'authentification disponible");
        }
        setState(() {
          errorMessage = "Erreur d'authentification";
          debugInfo = "❌ Pas de token";
          isLoadingUser = false;
        });
        return;
      }

      if (kDebugMode) {
        print("🔑 Token récupéré (longueur: ${token.length})");
      }

      // Essayer différents endpoints
      CurrentUser? user = await _tryUserEndpoints(token);

      user ??= await _tryCoiffeusesEndpoint();

      if (mounted) {
        setState(() {
          otherUser = user;
          isLoadingUser = false;
          if (user != null) {
            debugInfo = "✅ Utilisateur trouvé: ${user.prenom} ${user.nom}";
            errorMessage = null;
          } else {
            errorMessage = "Utilisateur introuvable";
            debugInfo = "❌ Aucune méthode n'a fonctionné";
          }
        });

        if (user != null && kDebugMode) {
          if (kDebugMode) {
            print("✅ Utilisateur récupéré: ${user.prenom} ${user.nom}");
          }
          if (kDebugMode) {
            print("📷 Photo profil: ${user.photoProfil}");
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Erreur lors de la récupération de l'utilisateur: $error");
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

  /// Essayer les endpoints utilisateur avec le token
  Future<CurrentUser?> _tryUserEndpoints(String token) async {
    final endpoints = [
      '/api/get_user_by_uuid/${widget.otherUserId}/',
      '/api/get_current_user/${widget.otherUserId}/',
      '/api/user_profile/${widget.otherUserId}/',
    ];

    for (String endpoint in endpoints) {
      try {
        final url = '$baseUrl$endpoint';
        if (kDebugMode) {
          print("🌐 Tentative endpoint: $url");
        }

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 10));

        if (kDebugMode) {
          print("📡 $endpoint - Status: ${response.statusCode}");
        }

        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final data = json.decode(decodedBody);

          // Essayer différentes structures de réponse
          CurrentUser? user = _parseUserResponse(data);
          if (user != null) {
            if (kDebugMode) {
              print("✅ Utilisateur trouvé via $endpoint");
            }
            return user;
          }
        } else if (response.statusCode == 401) {
          if (kDebugMode) {
            print("❌ Token expiré, tentative de refresh");
          }
          // Utiliser TokenService pour refresh
          final newToken = await TokenService.getAuthToken(forceRefresh: true);
          if (newToken != null) {
            // Réessayer avec le nouveau token
            return await _retryWithNewToken(endpoint, newToken);
          }
        }
      } catch (error) {
        if (kDebugMode) {
          print("❌ Erreur avec $endpoint: $error");
        }
        continue;
      }
    }
    return null;
  }

  /// Réessayer un endpoint avec un nouveau token
  Future<CurrentUser?> _retryWithNewToken(String endpoint, String token) async {
    try {
      final url = '$baseUrl$endpoint';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        return _parseUserResponse(data);
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Erreur retry $endpoint: $error");
      }
    }
    return null;
  }

  /// Essayer l'endpoint spécialisé pour les coiffeuses
  Future<CurrentUser?> _tryCoiffeusesEndpoint() async {
    try {
      if (kDebugMode) {
        print("🔄 Tentative endpoint coiffeuses");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": [widget.otherUserId]}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
          for (var coiffeuseData in jsonData["coiffeuses"]) {
            if (coiffeuseData['uuid'] == widget.otherUserId) {
              // Convertir les données coiffeuse en CurrentUser
              final userData = {
                'idTblUser': coiffeuseData['idTblUser'] ?? 0,
                'uuid': coiffeuseData['uuid'],
                'nom': coiffeuseData['nom'] ?? '',
                'prenom': coiffeuseData['prenom'] ?? '',
                'email': coiffeuseData['email'] ?? '',
                'numero_telephone': coiffeuseData['numero_telephone'],
                'date_naissance': coiffeuseData['date_naissance'],
                'is_active': coiffeuseData['is_active'] ?? true,
                'photo_profil': coiffeuseData['photo_profil'],
                'type': 'coiffeuse',
              };

              return CurrentUser.fromJson(userData);
            }
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

  /// Parser la réponse utilisateur
  CurrentUser? _parseUserResponse(Map<String, dynamic> data) {
    try {
      if (data['user'] != null) {
        return CurrentUser.fromJson(data['user']);
      } else if (data['data'] != null && data['success'] == true) {
        return CurrentUser.fromJson(data['data']);
      } else if (data['uuid'] != null) {
        return CurrentUser.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur parsing utilisateur: $e");
      }
    }
    return null;
  }

  /// Construire l'URL de la photo
  String? _getPhotoUrl(String? photoProfil) {
    if (photoProfil == null || photoProfil.isEmpty) {
      return null;
    }

    if (photoProfil.startsWith('http://') || photoProfil.startsWith('https://')) {
      return photoProfil;
    }

    if (photoProfil.startsWith('/')) {
      return baseUrl.replaceAll(RegExp(r'/$'), '') + photoProfil;
    }

    return '${baseUrl.replaceAll(RegExp(r'/$'), '')}/$photoProfil';
  }

  /// Forcer le rechargement de l'utilisateur
  void _forceRefreshUser() async {
    setState(() {
      otherUser = null;
    });
    await _fetchOtherUser();
  }

  /// Envoyer un message
  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    Message newMessage = Message(
      senderId: widget.currentUser.uuid,
      receiverId: widget.otherUserId,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    await databaseRef.child(chatId).child("messages").push().set(newMessage.toJson());
    _messageController.clear();

    Future.delayed(Duration(milliseconds: 300), () {
      _scrollToBottom();
    });
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
                    if (kDebugMode && errorMessage != null)
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _forceRefreshUser,
                        tooltip: "Recharger l'utilisateur",
                      ),
                  ],
                ),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Erreur de chargement des messages."));
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
                    onSubmitted: (text) {
                      sendMessage(text);
                    },
                    decoration: InputDecoration(
                      hintText: "Écrire un message",
                      filled: true,
                      fillColor: Colors.grey.shade200,
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
                  onPressed: () {
                    sendMessage(_messageController.text);
                  },
                  mini: true,
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

  /// Construire l'image de profil
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

  /// Construire les informations utilisateur
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
          if (otherUser!.type == 'coiffeuse')
            Text(
              "Coiffeuse",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
            "ID: ${widget.otherUserId.substring(0, 8)}...",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
  }
}








// // Version améliorée de ChatPage avec debugging renforcé
// // Remplacez le contenu de votre chat_page.dart par cette version
//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/user_service.dart';
// import 'package:hairbnb/services/firebase_token/token_service.dart';
// import 'package:hairbnb/widgets/custom_app_bar.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/models/message.dart';
// import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// import '../../services/my_drawer_service/my_drawer.dart';
// import 'package:intl/intl.dart';
//
// class ChatPage extends StatefulWidget {
//   final CurrentUser currentUser;
//   final String otherUserId;
//
//   const ChatPage({super.key,
//     required this.otherUserId,
//     required this.currentUser,
//   });
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final FocusNode _focusNode = FocusNode();
//   late String chatId;
//   CurrentUser? otherUser;
//   bool isLoadingUser = true;
//   String? debugInfo;
//   late String baseUrl = "https://www.hairbnb.site/";
//
//   @override
//   void initState() {
//     super.initState();
//     chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
//         ? "${widget.currentUser.uuid}_${widget.otherUserId}"
//         : "${widget.otherUserId}_${widget.currentUser.uuid}";
//     _debugAuthenticationStatus();
//     _fetchOtherUser();
//   }
//
//   /// Debug : Vérifier le statut d'authentification
//   Future<void> _debugAuthenticationStatus() async {
//     final token = await TokenService.getAuthToken();
//     if (token != null) {
//       if (kDebugMode) {
//         print("🔑 Token d'authentification disponible (longueur: ${token.length})");
//       }
//       setState(() {
//         debugInfo = "✅ Token disponible";
//       });
//     } else {
//       if (kDebugMode) {
//         print("❌ Aucun token d'authentification disponible");
//       }
//       setState(() {
//         debugInfo = "❌ Pas de token";
//       });
//     }
//   }
//
//   Future<void> _fetchOtherUser() async {
//     try {
//       if (kDebugMode) {
//         print("🔍 Récupération des données pour l'utilisateur: ${widget.otherUserId}");
//       }
//
//       setState(() {
//         debugInfo = "🔍 Recherche utilisateur...";
//       });
//
//       // Utiliser la fonction qui suit le pattern du CurrentUserProvider
//       final user = await fetchOtherUserComplete(widget.otherUserId);
//
//       if (mounted) {
//         setState(() {
//           otherUser = user;
//           isLoadingUser = false;
//           if (user != null) {
//             debugInfo = "✅ Utilisateur trouvé: ${user.prenom} ${user.nom}";
//           } else {
//             debugInfo = "❌ Utilisateur introuvable pour UUID: ${widget.otherUserId}";
//           }
//         });
//
//         if (user != null) {
//           if (kDebugMode) {
//             print("✅ Utilisateur récupéré: ${user.prenom} ${user.nom}");
//             print("📷 Photo profil: ${user.photoProfil}");
//             print("📧 Email: ${user.email}");
//             print("🆔 Type: ${user.type}");
//           }
//         } else {
//           if (kDebugMode) {
//             print("❌ Aucun utilisateur trouvé pour l'ID: ${widget.otherUserId}");
//           }
//
//           // Essayer une recherche directe dans Firebase comme fallback
//           _tryFirebaseFallback();
//         }
//       }
//     } catch (error) {
//       if (kDebugMode) {
//         print("❌ Erreur lors de la récupération de l'utilisateur: $error");
//       }
//       if (mounted) {
//         setState(() {
//           isLoadingUser = false;
//           debugInfo = "❌ Erreur: $error";
//         });
//       }
//     }
//   }
//
//   /// Fallback : Essayer de récupérer des infos depuis Firebase directement
//   Future<void> _tryFirebaseFallback() async {
//     if (kDebugMode) {
//       print("🔄 Tentative de fallback Firebase...");
//     }
//
//     setState(() {
//       debugInfo = "🔄 Recherche dans Firebase...";
//     });
//
//     try {
//       // Chercher dans toutes les conversations pour voir si on trouve cet utilisateur
//       final snapshot = await databaseRef.once();
//       if (snapshot.snapshot.value != null) {
//         final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
//
//         for (var entry in data.entries) {
//           final conversationKey = entry.key;
//           final participants = conversationKey.split("_");
//
//           if (participants.contains(widget.otherUserId)) {
//             if (kDebugMode) {
//               print("✅ UUID trouvé dans Firebase conversation: $conversationKey");
//             }
//             setState(() {
//               debugInfo = "⚠️ UUID trouvé dans Firebase mais pas dans l'API";
//             });
//             break;
//           }
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur fallback Firebase: $e");
//       }
//     }
//   }
//
//   // Fonction pour construire l'URL de la photo correctement
//   String? getPhotoUrl(String? photoProfil) {
//     if (photoProfil == null || photoProfil.isEmpty) {
//       return null;
//     }
//
//     if (kDebugMode) {
//       print("🖼️ Photo profil brute: '$photoProfil'");
//     }
//
//     // Si l'URL est déjà complète, la retourner telle quelle
//     if (photoProfil.startsWith('http://') || photoProfil.startsWith('https://')) {
//       if (kDebugMode) {
//         print("🖼️ URL complète détectée: $photoProfil");
//       }
//       return photoProfil;
//     }
//
//     // Si l'URL commence par '/', la concaténer avec baseUrl sans slash final
//     if (photoProfil.startsWith('/')) {
//       final cleanBaseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');
//       final finalUrl = cleanBaseUrl + photoProfil;
//       if (kDebugMode) {
//         print("🖼️ URL construite (avec /): $finalUrl");
//       }
//       return finalUrl;
//     }
//
//     // Sinon, construire l'URL complète
//     final cleanBaseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');
//     final finalUrl = cleanBaseUrl + '/' + photoProfil;
//     if (kDebugMode) {
//       print("🖼️ URL construite (normale): $finalUrl");
//     }
//     return finalUrl;
//   }
//
//   void sendMessage(String text) async {
//     if (text.trim().isEmpty) return;
//
//     Message newMessage = Message(
//       senderId: widget.currentUser.uuid,
//       receiverId: widget.otherUserId,
//       text: text.trim(),
//       timestamp: DateTime.now(),
//       isRead: false,
//     );
//
//     await databaseRef.child(chatId).child("messages").push().set(newMessage.toJson());
//     _messageController.clear();
//
//     Future.delayed(Duration(milliseconds: 300), () {
//       _scrollToBottom();
//     });
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   // Fonction pour forcer le rechargement de l'utilisateur
//   void _forceRefreshUser() async {
//     setState(() {
//       isLoadingUser = true;
//       debugInfo = "🔄 Rechargement forcé...";
//     });
//
//     // Vider le cache et essayer de recharger
//     clearUserCache();
//     await _fetchOtherUser();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       drawer: MyDrawer(currentUser: widget.currentUser),
//       body: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(10),
//             color: Colors.grey.shade200,
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: Colors.blueAccent,
//                       backgroundImage: _buildProfileImage(),
//                       radius: 25,
//                       onBackgroundImageError: (exception, stackTrace) {
//                         if (kDebugMode) {
//                           print("❌ Erreur de chargement d'image: $exception");
//                         }
//                       },
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(child: _buildUserName()),
//                     // Bouton de debug uniquement en mode développement
//                     if (kDebugMode)
//                       IconButton(
//                         icon: Icon(Icons.refresh, color: Colors.blue),
//                         onPressed: _forceRefreshUser,
//                         tooltip: "Recharger l'utilisateur",
//                       ),
//                   ],
//                 ),
//                 // Afficher les infos de debug en mode développement
//                 if (kDebugMode && debugInfo != null)
//                   Container(
//                     margin: EdgeInsets.only(top: 8),
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(4),
//                       border: Border.all(color: Colors.blue.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.bug_report, size: 16, color: Colors.blue),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             debugInfo!,
//                             style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder(
//               stream: databaseRef.child(chatId).child("messages").onValue,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (snapshot.hasError) {
//                   return const Center(child: Text("Erreur de chargement des messages."));
//                 }
//
//                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   List<Message> messages = data.entries.map((entry) {
//                     return Message.fromJson(entry.value);
//                   }).toList();
//
//                   messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//                   Future.delayed(Duration(milliseconds: 300), () {
//                     _scrollToBottom();
//                   });
//
//                   return ListView.builder(
//                     controller: _scrollController,
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = messages[index];
//                       bool isSender = msg.senderId == widget.currentUser.uuid;
//
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                         child: Align(
//                           alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             constraints: BoxConstraints(
//                               maxWidth: MediaQuery.of(context).size.width * 0.7,
//                             ),
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: isSender ? Colors.blueAccent : Colors.grey.shade300,
//                               borderRadius: BorderRadius.only(
//                                 topLeft: const Radius.circular(10),
//                                 topRight: const Radius.circular(10),
//                                 bottomLeft: isSender ? const Radius.circular(10) : Radius.zero,
//                                 bottomRight: isSender ? Radius.zero : const Radius.circular(10),
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   msg.text,
//                                   style: TextStyle(color: isSender ? Colors.white : Colors.black),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Align(
//                                   alignment: Alignment.bottomRight,
//                                   child: Text(
//                                     DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp.toUtc()),
//                                     style: const TextStyle(fontSize: 10, color: Colors.grey),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 }
//                 return const Center(child: Text("Aucun message."));
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     focusNode: _focusNode,
//                     onSubmitted: (text) {
//                       sendMessage(text);
//                     },
//                     decoration: InputDecoration(
//                       hintText: "Écrire un message",
//                       filled: true,
//                       fillColor: Colors.grey.shade200,
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 FloatingActionButton(
//                   onPressed: () {
//                     sendMessage(_messageController.text);
//                   },
//                   mini: true,
//                   child: const Icon(Icons.send),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 3,
//         onTap: (index) {
//           // Navigation gérée dans le widget lui-même
//         },
//       ),
//     );
//   }
//
//   // Widget pour construire l'image de profil
//   ImageProvider _buildProfileImage() {
//     // Toujours utiliser l'avatar par défaut si pas d'utilisateur
//     if (otherUser == null) {
//       if (kDebugMode) {
//         print("🖼️ Aucun utilisateur - utilisation de l'avatar par défaut");
//       }
//       return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
//     }
//
//     final photoUrl = getPhotoUrl(otherUser?.photoProfil);
//
//     if (photoUrl != null) {
//       if (kDebugMode) {
//         print("🖼️ URL de l'image finale: $photoUrl");
//       }
//       // Vérifier que l'URL est valide avant de l'utiliser
//       try {
//         final uri = Uri.parse(photoUrl);
//         if (uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https')) {
//           return NetworkImage(photoUrl);
//         } else {
//           if (kDebugMode) {
//             print("❌ URL invalide: $photoUrl");
//           }
//           return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print("❌ Erreur de parsing d'URL: $e");
//         }
//         return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
//       }
//     } else {
//       if (kDebugMode) {
//         print("🖼️ Pas de photo profil - utilisation de l'avatar par défaut");
//       }
//       return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
//     }
//   }
//
//   // Widget pour construire le nom de l'utilisateur
//   Widget _buildUserName() {
//     if (isLoadingUser) {
//       return Row(
//         children: [
//           SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//           SizedBox(width: 8),
//           Text("Chargement...", style: TextStyle(fontSize: 14, color: Colors.grey)),
//         ],
//       );
//     }
//
//     if (otherUser != null) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "${otherUser!.prenom ?? ''} ${otherUser!.nom ?? ''}".trim(),
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           if (kDebugMode)
//             Text(
//               "UUID: ${widget.otherUserId}",
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//         ],
//       );
//     } else {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Utilisateur introuvable",
//             style: TextStyle(fontSize: 16, color: Colors.red),
//           ),
//           if (kDebugMode)
//             Text(
//               "UUID: ${widget.otherUserId}",
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//         ],
//       );
//     }
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/services/providers/user_service.dart';
// // import 'package:hairbnb/services/firebase_token/token_service.dart';
// // import 'package:hairbnb/widgets/custom_app_bar.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:hairbnb/models/message.dart';
// // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // import '../../services/my_drawer_service/my_drawer.dart';
// // import 'package:intl/intl.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final CurrentUser currentUser;
// //   final String otherUserId;
// //
// //   const ChatPage({super.key,
// //     required this.otherUserId,
// //     required this.currentUser,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //   final ScrollController _scrollController = ScrollController();
// //   final FocusNode _focusNode = FocusNode();
// //   late String chatId;
// //   CurrentUser? otherUser;
// //   bool isLoadingUser = true;
// //   late String baseUrl = "https://www.hairbnb.site/";
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
// //         ? "${widget.currentUser.uuid}_${widget.otherUserId}"
// //         : "${widget.otherUserId}_${widget.currentUser.uuid}";
// //     _debugAuthenticationStatus();
// //     _fetchOtherUser();
// //   }
// //
// //   /// Debug : Vérifier le statut d'authentification
// //   Future<void> _debugAuthenticationStatus() async {
// //     final token = await TokenService.getAuthToken();
// //     if (token != null) {
// //       if (kDebugMode) {
// //         print("🔑 Token d'authentification disponible (longueur: ${token.length})");
// //       }
// //     } else {
// //       if (kDebugMode) {
// //         print("❌ Aucun token d'authentification disponible");
// //       }
// //     }
// //   }
// //
// //   Future<void> _fetchOtherUser() async {
// //     try {
// //       if (kDebugMode) {
// //         print("🔍 Récupération des données pour l'utilisateur: ${widget.otherUserId}");
// //       }
// //       // Utiliser la nouvelle fonction qui suit le pattern du CurrentUserProvider
// //       final user = await fetchOtherUserComplete(widget.otherUserId);
// //
// //       if (mounted) {
// //         setState(() {
// //           otherUser = user;
// //           isLoadingUser = false;
// //         });
// //
// //         if (user != null) {
// //           if (kDebugMode) {
// //             print("✅ Utilisateur récupéré: ${user.prenom} ${user.nom}");
// //             print("📷 Photo profil: ${user.photoProfil}");
// //           }
// //         } else {
// //           if (kDebugMode) {
// //             print("❌ Aucun utilisateur trouvé pour l'ID: ${widget.otherUserId}");
// //           }
// //         }
// //       }
// //     } catch (error) {
// //       if (kDebugMode) {
// //         print("❌ Erreur lors de la récupération de l'utilisateur: $error");
// //       }
// //       if (mounted) {
// //         setState(() {
// //           isLoadingUser = false;
// //         });
// //       }
// //     }
// //   }
// //
// //   // Fonction pour construire l'URL de la photo correctement
// //   String? getPhotoUrl(String? photoProfil) {
// //     if (photoProfil == null || photoProfil.isEmpty) {
// //       return null;
// //     }
// //
// //     if (kDebugMode) {
// //       print("🖼️ Photo profil brute: '$photoProfil'");
// //     }
// //
// //     // Si l'URL est déjà complète, la retourner telle quelle
// //     if (photoProfil.startsWith('http://') || photoProfil.startsWith('https://')) {
// //       if (kDebugMode) {
// //         print("🖼️ URL complète détectée: $photoProfil");
// //       }
// //       return photoProfil;
// //     }
// //
// //     // Si l'URL commence par '/', la concaténer avec baseUrl sans slash final
// //     if (photoProfil.startsWith('/')) {
// //       final cleanBaseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');
// //       final finalUrl = cleanBaseUrl + photoProfil;
// //       if (kDebugMode) {
// //         print("🖼️ URL construite (avec /): $finalUrl");
// //       }
// //       return finalUrl;
// //     }
// //
// //     // Sinon, construire l'URL complète
// //     final cleanBaseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');
// //     final finalUrl = cleanBaseUrl + '/' + photoProfil;
// //     if (kDebugMode) {
// //       print("🖼️ URL construite (normale): $finalUrl");
// //     }
// //     return finalUrl;
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     Message newMessage = Message(
// //       senderId: widget.currentUser.uuid,
// //       receiverId: widget.otherUserId,
// //       text: text.trim(),
// //       timestamp: DateTime.now(),
// //       isRead: false,
// //     );
// //
// //     await databaseRef.child(chatId).child("messages").push().set(newMessage.toJson());
// //     _messageController.clear();
// //
// //     Future.delayed(Duration(milliseconds: 300), () {
// //       _scrollToBottom();
// //     });
// //   }
// //
// //   void _scrollToBottom() {
// //     if (_scrollController.hasClients) {
// //       _scrollController.animateTo(
// //         _scrollController.position.maxScrollExtent,
// //         duration: Duration(milliseconds: 300),
// //         curve: Curves.easeOut,
// //       );
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: CustomAppBar(),
// //       drawer: MyDrawer(currentUser: widget.currentUser),
// //       body: Column(
// //         children: [
// //           Container(
// //             width: double.infinity,
// //             padding: EdgeInsets.all(10),
// //             color: Colors.grey.shade200,
// //             child: Row(
// //               children: [
// //                 CircleAvatar(
// //                   backgroundColor: Colors.blueAccent,
// //                   backgroundImage: _buildProfileImage(),
// //                   radius: 25,
// //                   onBackgroundImageError: (exception, stackTrace) {
// //                     if (kDebugMode) {
// //                       print("❌ Erreur de chargement d'image: $exception");
// //                     }
// //                   },
// //                 ),
// //                 SizedBox(width: 10),
// //                 _buildUserName(),
// //               ],
// //             ),
// //           ),
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef.child(chatId).child("messages").onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }
// //
// //                 if (snapshot.hasError) {
// //                   return const Center(child: Text("Erreur de chargement des messages."));
// //                 }
// //
// //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //                   List<Message> messages = data.entries.map((entry) {
// //                     return Message.fromJson(entry.value);
// //                   }).toList();
// //
// //                   messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
// //
// //                   Future.delayed(Duration(milliseconds: 300), () {
// //                     _scrollToBottom();
// //                   });
// //
// //                   return ListView.builder(
// //                     controller: _scrollController,
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       bool isSender = msg.senderId == widget.currentUser.uuid;
// //
// //                       return Padding(
// //                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
// //                         child: Align(
// //                           alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                           child: Container(
// //                             constraints: BoxConstraints(
// //                               maxWidth: MediaQuery.of(context).size.width * 0.7,
// //                             ),
// //                             padding: const EdgeInsets.all(10),
// //                             decoration: BoxDecoration(
// //                               color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                               borderRadius: BorderRadius.only(
// //                                 topLeft: const Radius.circular(10),
// //                                 topRight: const Radius.circular(10),
// //                                 bottomLeft: isSender ? const Radius.circular(10) : Radius.zero,
// //                                 bottomRight: isSender ? Radius.zero : const Radius.circular(10),
// //                               ),
// //                             ),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   msg.text,
// //                                   style: TextStyle(color: isSender ? Colors.white : Colors.black),
// //                                 ),
// //                                 const SizedBox(height: 5),
// //                                 Align(
// //                                   alignment: Alignment.bottomRight,
// //                                   child: Text(
// //                                     DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp.toUtc()),
// //                                     style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //                 return const Center(child: Text("Aucun message."));
// //               },
// //             ),
// //           ),
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _messageController,
// //                     focusNode: _focusNode,
// //                     onSubmitted: (text) {
// //                       sendMessage(text);
// //                     },
// //                     decoration: InputDecoration(
// //                       hintText: "Écrire un message",
// //                       filled: true,
// //                       fillColor: Colors.grey.shade200,
// //                       contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// //                       border: OutlineInputBorder(
// //                         borderRadius: BorderRadius.circular(20),
// //                         borderSide: BorderSide.none,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 10),
// //                 FloatingActionButton(
// //                   onPressed: () {
// //                     sendMessage(_messageController.text);
// //                   },
// //                   mini: true,
// //                   child: const Icon(Icons.send),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //       bottomNavigationBar: BottomNavBar(
// //         currentIndex: 3, // 👈 Correspond à l'onglet "Messages"
// //         onTap: (index) {
// //           // rien ici, le contrôle se fait dans le widget lui-même
// //         },
// //       ),
// //     );
// //   }
// //
// //   // Widget pour construire l'image de profil
// //   ImageProvider _buildProfileImage() {
// //     // Toujours utiliser l'avatar par défaut si pas d'utilisateur
// //     if (otherUser == null) {
// //       if (kDebugMode) {
// //         print("🖼️ Aucun utilisateur - utilisation de l'avatar par défaut");
// //       }
// //       return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
// //     }
// //
// //     final photoUrl = getPhotoUrl(otherUser?.photoProfil);
// //
// //     if (photoUrl != null) {
// //       if (kDebugMode) {
// //         print("🖼️ URL de l'image finale: $photoUrl");
// //       }
// //       // Vérifier que l'URL est valide avant de l'utiliser
// //       try {
// //         final uri = Uri.parse(photoUrl);
// //         if (uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https')) {
// //           return NetworkImage(photoUrl);
// //         } else {
// //           if (kDebugMode) {
// //             print("❌ URL invalide: $photoUrl");
// //           }
// //           return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
// //         }
// //       } catch (e) {
// //         if (kDebugMode) {
// //           print("❌ Erreur de parsing d'URL: $e");
// //         }
// //         return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
// //       }
// //     } else {
// //       if (kDebugMode) {
// //         print("🖼️ Pas de photo profil - utilisation de l'avatar par défaut");
// //       }
// //       return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
// //     }
// //   }
// //
// //   // Widget pour construire le nom de l'utilisateur
// //   Widget _buildUserName() {
// //     if (isLoadingUser) {
// //       return Row(
// //         children: [
// //           SizedBox(
// //             width: 16,
// //             height: 16,
// //             child: CircularProgressIndicator(strokeWidth: 2),
// //           ),
// //           SizedBox(width: 8),
// //           Text("Chargement...", style: TextStyle(fontSize: 14, color: Colors.grey)),
// //         ],
// //       );
// //     }
// //
// //     if (otherUser != null) {
// //       return Text(
// //         "${otherUser!.prenom ?? ''} ${otherUser!.nom ?? ''}".trim(),
// //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //       );
// //     } else {
// //       return Text(
// //         "Utilisateur introuvable",
// //         style: TextStyle(fontSize: 16, color: Colors.red),
// //       );
// //     }
// //   }
// // }
// //
// //
// //
// //
// //
// //
// // // import 'package:firebase_database/firebase_database.dart';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/services/providers/user_service.dart';
// // // import 'package:hairbnb/widgets/custom_app_bar.dart';
// // // import 'package:hairbnb/models/current_user.dart';
// // // import 'package:hairbnb/models/message.dart';
// // // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // // import '../../services/my_drawer_service/my_drawer.dart';
// // // import 'package:intl/intl.dart';
// // //
// // // class ChatPage extends StatefulWidget {
// // //   final CurrentUser currentUser;
// // //   final String otherUserId;
// // //
// // //   const ChatPage({super.key,
// // //     required this.otherUserId,
// // //     required this.currentUser,
// // //   });
// // //
// // //   @override
// // //   _ChatPageState createState() => _ChatPageState();
// // // }
// // //
// // // class _ChatPageState extends State<ChatPage> {
// // //   final databaseRef = FirebaseDatabase.instance.ref();
// // //   final TextEditingController _messageController = TextEditingController();
// // //   final ScrollController _scrollController = ScrollController();
// // //   final FocusNode _focusNode = FocusNode();
// // //   late String chatId;
// // //   CurrentUser? otherUser;
// // //   bool isLoadingUser = true;
// // //   late String baseUrl = "https://www.hairbnb.site/";
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
// // //         ? "${widget.currentUser.uuid}_${widget.otherUserId}"
// // //         : "${widget.otherUserId}_${widget.currentUser.uuid}";
// // //     _fetchOtherUser();
// // //   }
// // //
// // //   Future<void> _fetchOtherUser() async {
// // //     try {
// // //       if (kDebugMode) {
// // //         print("🔍 Récupération des données pour l'utilisateur: ${widget.otherUserId}");
// // //       }
// // //       final user = await fetchOtherUser(widget.otherUserId);
// // //
// // //       if (mounted) {
// // //         setState(() {
// // //           otherUser = user;
// // //           isLoadingUser = false;
// // //         });
// // //
// // //         if (user != null) {
// // //           if (kDebugMode) {
// // //             print("✅ Utilisateur récupéré: ${user.prenom} ${user.nom}");
// // //           }
// // //           if (kDebugMode) {
// // //             print("📷 Photo profil: ${user.photoProfil}");
// // //           }
// // //         } else {
// // //           if (kDebugMode) {
// // //             print("❌ Aucun utilisateur trouvé pour l'ID: ${widget.otherUserId}");
// // //           }
// // //         }
// // //       }
// // //     } catch (error) {
// // //       if (kDebugMode) {
// // //         print("❌ Erreur lors de la récupération de l'utilisateur: $error");
// // //       }
// // //       if (mounted) {
// // //         setState(() {
// // //           isLoadingUser = false;
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   // Fonction pour construire l'URL de la photo correctement
// // //   String? getPhotoUrl(String? photoProfil) {
// // //     if (photoProfil == null || photoProfil.isEmpty) {
// // //       return null;
// // //     }
// // //
// // //     // Si l'URL est déjà complète, la retourner telle quelle
// // //     if (photoProfil.startsWith('http://') || photoProfil.startsWith('https://')) {
// // //       return photoProfil;
// // //     }
// // //
// // //     // Si l'URL commence par '/', la concaténer avec baseUrl sans slash final
// // //     if (photoProfil.startsWith('/')) {
// // //       return baseUrl.replaceAll(RegExp(r'/$'), '') + photoProfil;
// // //     }
// // //
// // //     // Sinon, construire l'URL complète
// // //     return baseUrl + photoProfil;
// // //   }
// // //
// // //   void sendMessage(String text) async {
// // //     if (text.trim().isEmpty) return;
// // //
// // //     Message newMessage = Message(
// // //       senderId: widget.currentUser.uuid,
// // //       receiverId: widget.otherUserId,
// // //       text: text.trim(),
// // //       timestamp: DateTime.now(),
// // //       isRead: false,
// // //     );
// // //
// // //     await databaseRef.child(chatId).child("messages").push().set(newMessage.toJson());
// // //     _messageController.clear();
// // //
// // //     Future.delayed(Duration(milliseconds: 300), () {
// // //       _scrollToBottom();
// // //     });
// // //   }
// // //
// // //   void _scrollToBottom() {
// // //     if (_scrollController.hasClients) {
// // //       _scrollController.animateTo(
// // //         _scrollController.position.maxScrollExtent,
// // //         duration: Duration(milliseconds: 300),
// // //         curve: Curves.easeOut,
// // //       );
// // //     }
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: CustomAppBar(),
// // //       drawer: MyDrawer(currentUser: widget.currentUser),
// // //       body: Column(
// // //         children: [
// // //           Container(
// // //             width: double.infinity,
// // //             padding: EdgeInsets.all(10),
// // //             color: Colors.grey.shade200,
// // //             child: Row(
// // //               children: [
// // //                 CircleAvatar(
// // //                   backgroundColor: Colors.blueAccent,
// // //                   backgroundImage: _buildProfileImage(),
// // //                   radius: 25,
// // //                   onBackgroundImageError: (exception, stackTrace) {
// // //                     if (kDebugMode) {
// // //                       print("❌ Erreur de chargement d'image: $exception");
// // //                     }
// // //                   },
// // //                 ),
// // //                 SizedBox(width: 10),
// // //                 _buildUserName(),
// // //               ],
// // //             ),
// // //           ),
// // //           Expanded(
// // //             child: StreamBuilder(
// // //               stream: databaseRef.child(chatId).child("messages").onValue,
// // //               builder: (context, snapshot) {
// // //                 if (snapshot.connectionState == ConnectionState.waiting) {
// // //                   return const Center(child: CircularProgressIndicator());
// // //                 }
// // //
// // //                 if (snapshot.hasError) {
// // //                   return const Center(child: Text("Erreur de chargement des messages."));
// // //                 }
// // //
// // //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// // //                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// // //                   List<Message> messages = data.entries.map((entry) {
// // //                     return Message.fromJson(entry.value);
// // //                   }).toList();
// // //
// // //                   messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
// // //
// // //                   Future.delayed(Duration(milliseconds: 300), () {
// // //                     _scrollToBottom();
// // //                   });
// // //
// // //                   return ListView.builder(
// // //                     controller: _scrollController,
// // //                     itemCount: messages.length,
// // //                     itemBuilder: (context, index) {
// // //                       final msg = messages[index];
// // //                       bool isSender = msg.senderId == widget.currentUser.uuid;
// // //
// // //                       return Padding(
// // //                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
// // //                         child: Align(
// // //                           alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// // //                           child: Container(
// // //                             constraints: BoxConstraints(
// // //                               maxWidth: MediaQuery.of(context).size.width * 0.7,
// // //                             ),
// // //                             padding: const EdgeInsets.all(10),
// // //                             decoration: BoxDecoration(
// // //                               color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// // //                               borderRadius: BorderRadius.only(
// // //                                 topLeft: const Radius.circular(10),
// // //                                 topRight: const Radius.circular(10),
// // //                                 bottomLeft: isSender ? const Radius.circular(10) : Radius.zero,
// // //                                 bottomRight: isSender ? Radius.zero : const Radius.circular(10),
// // //                               ),
// // //                             ),
// // //                             child: Column(
// // //                               crossAxisAlignment: CrossAxisAlignment.start,
// // //                               children: [
// // //                                 Text(
// // //                                   msg.text,
// // //                                   style: TextStyle(color: isSender ? Colors.white : Colors.black),
// // //                                 ),
// // //                                 const SizedBox(height: 5),
// // //                                 Align(
// // //                                   alignment: Alignment.bottomRight,
// // //                                   child: Text(
// // //                                     DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp.toUtc()),
// // //                                     style: const TextStyle(fontSize: 10, color: Colors.grey),
// // //                                   ),
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       );
// // //                     },
// // //                   );
// // //                 }
// // //                 return const Center(child: Text("Aucun message."));
// // //               },
// // //             ),
// // //           ),
// // //           Padding(
// // //             padding: const EdgeInsets.all(8.0),
// // //             child: Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: TextField(
// // //                     controller: _messageController,
// // //                     focusNode: _focusNode,
// // //                     onSubmitted: (text) {
// // //                       sendMessage(text);
// // //                     },
// // //                     decoration: InputDecoration(
// // //                       hintText: "Écrire un message",
// // //                       filled: true,
// // //                       fillColor: Colors.grey.shade200,
// // //                       contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // //                       border: OutlineInputBorder(
// // //                         borderRadius: BorderRadius.circular(20),
// // //                         borderSide: BorderSide.none,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 10),
// // //                 FloatingActionButton(
// // //                   onPressed: () {
// // //                     sendMessage(_messageController.text);
// // //                   },
// // //                   mini: true,
// // //                   child: const Icon(Icons.send),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //       bottomNavigationBar: BottomNavBar(
// // //         currentIndex: 3, // 👈 Correspond à l'onglet "Messages"
// // //         onTap: (index) {
// // //           // rien ici, le contrôle se fait dans le widget lui-même
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Widget pour construire l'image de profil
// // //   ImageProvider _buildProfileImage() {
// // //     final photoUrl = getPhotoUrl(otherUser?.photoProfil);
// // //
// // //     if (photoUrl != null) {
// // //       if (kDebugMode) {
// // //         print("🖼️ URL de l'image construite: $photoUrl");
// // //       }
// // //       return NetworkImage(photoUrl);
// // //     } else {
// // //       if (kDebugMode) {
// // //         print("🖼️ Utilisation de l'avatar par défaut");
// // //       }
// // //       return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
// // //     }
// // //   }
// // //
// // //   // Widget pour construire le nom de l'utilisateur
// // //   Widget _buildUserName() {
// // //     if (isLoadingUser) {
// // //       return Row(
// // //         children: [
// // //           SizedBox(
// // //             width: 16,
// // //             height: 16,
// // //             child: CircularProgressIndicator(strokeWidth: 2),
// // //           ),
// // //           SizedBox(width: 8),
// // //           Text("Chargement...", style: TextStyle(fontSize: 14, color: Colors.grey)),
// // //         ],
// // //       );
// // //     }
// // //
// // //     if (otherUser != null) {
// // //       return Text(
// // //         "${otherUser!.prenom} ${otherUser!.nom}".trim(),
// // //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //       );
// // //     } else {
// // //       return Text(
// // //         "Utilisateur introuvable",
// // //         style: TextStyle(fontSize: 16, color: Colors.red),
// // //       );
// // //     }
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // // // import 'package:firebase_database/firebase_database.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:hairbnb/services/providers/user_service.dart';
// // // // import 'package:hairbnb/widgets/custom_app_bar.dart';
// // // // import 'package:hairbnb/models/current_user.dart';
// // // // import 'package:hairbnb/models/message.dart';
// // // // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // // // import '../../services/my_drawer_service/my_drawer.dart';
// // // // import 'package:intl/intl.dart';
// // // //
// // // // class ChatPage extends StatefulWidget {
// // // //   final CurrentUser currentUser;
// // // //   final String otherUserId;
// // // //
// // // //   const ChatPage({super.key,
// // // //     required this.otherUserId,
// // // //     required this.currentUser,
// // // //   });
// // // //
// // // //   @override
// // // //   _ChatPageState createState() => _ChatPageState();
// // // // }
// // // //
// // // // class _ChatPageState extends State<ChatPage> {
// // // //   final databaseRef = FirebaseDatabase.instance.ref();
// // // //   final TextEditingController _messageController = TextEditingController();
// // // //   final ScrollController _scrollController = ScrollController();
// // // //   final FocusNode _focusNode = FocusNode();
// // // //   late String chatId;
// // // //   CurrentUser? otherUser;
// // // //   late String baseUrl = "https://www.hairbnb.site/";
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
// // // //         ? "${widget.currentUser.uuid}_${widget.otherUserId}"
// // // //         : "${widget.otherUserId}_${widget.currentUser.uuid}";
// // // //     _fetchOtherUser();
// // // //   }
// // // //
// // // //   Future<void> _fetchOtherUser() async {
// // // //     final user = await fetchOtherUser(widget.otherUserId);
// // // //     setState(() {
// // // //       otherUser = user;
// // // //     });
// // // //   }
// // // //
// // // //   void sendMessage(String text) async {
// // // //     if (text.trim().isEmpty) return;
// // // //
// // // //     Message newMessage = Message(
// // // //       senderId: widget.currentUser.uuid,
// // // //       receiverId: widget.otherUserId,
// // // //       text: text.trim(),
// // // //       timestamp: DateTime.now(),
// // // //       isRead: false,
// // // //     );
// // // //
// // // //     await databaseRef.child(chatId).child("messages").push().set(newMessage.toJson());
// // // //     _messageController.clear();
// // // //
// // // //     Future.delayed(Duration(milliseconds: 300), () {
// // // //       _scrollToBottom();
// // // //     });
// // // //   }
// // // //
// // // //   void _scrollToBottom() {
// // // //     if (_scrollController.hasClients) {
// // // //       _scrollController.animateTo(
// // // //         _scrollController.position.maxScrollExtent,
// // // //         duration: Duration(milliseconds: 300),
// // // //         curve: Curves.easeOut,
// // // //       );
// // // //     }
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: CustomAppBar(),
// // // //       drawer: MyDrawer(currentUser: widget.currentUser),
// // // //       body: Column(
// // // //         children: [
// // // //           Container(
// // // //             width: double.infinity,
// // // //             padding: EdgeInsets.all(10),
// // // //             color: Colors.grey.shade200,
// // // //             child: Row(
// // // //               children: [
// // // //                 CircleAvatar(
// // // //                   backgroundColor: Colors.blueAccent,
// // // //                   backgroundImage: otherUser != null && otherUser!.photoProfil != null
// // // //                       ? NetworkImage(baseUrl + otherUser!.photoProfil.toString())
// // // //                       : AssetImage("assets/logo_login/avatar.png") as ImageProvider,
// // // //                   radius: 25,
// // // //                 ),
// // // //                 SizedBox(width: 10),
// // // //                 otherUser != null
// // // //                     ? Text(
// // // //                   "${otherUser!.prenom} ${otherUser!.nom}",
// // // //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // //                 )
// // // //                     : CircularProgressIndicator(),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //           Expanded(
// // // //             child: StreamBuilder(
// // // //               stream: databaseRef.child(chatId).child("messages").onValue,
// // // //               builder: (context, snapshot) {
// // // //                 if (snapshot.connectionState == ConnectionState.waiting) {
// // // //                   return const Center(child: CircularProgressIndicator());
// // // //                 }
// // // //
// // // //                 if (snapshot.hasError) {
// // // //                   return const Center(child: Text("Erreur de chargement des messages."));
// // // //                 }
// // // //
// // // //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// // // //                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// // // //                   List<Message> messages = data.entries.map((entry) {
// // // //                     return Message.fromJson(entry.value);
// // // //                   }).toList();
// // // //
// // // //                   messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
// // // //
// // // //                   Future.delayed(Duration(milliseconds: 300), () {
// // // //                     _scrollToBottom();
// // // //                   });
// // // //
// // // //                   return ListView.builder(
// // // //                     controller: _scrollController,
// // // //                     itemCount: messages.length,
// // // //                     itemBuilder: (context, index) {
// // // //                       final msg = messages[index];
// // // //                       bool isSender = msg.senderId == widget.currentUser.uuid;
// // // //
// // // //                       return Padding(
// // // //                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
// // // //                         child: Align(
// // // //                           alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// // // //                           child: Container(
// // // //                             constraints: BoxConstraints(
// // // //                               maxWidth: MediaQuery.of(context).size.width * 0.7,
// // // //                             ),
// // // //                             padding: const EdgeInsets.all(10),
// // // //                             decoration: BoxDecoration(
// // // //                               color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// // // //                               borderRadius: BorderRadius.only(
// // // //                                 topLeft: const Radius.circular(10),
// // // //                                 topRight: const Radius.circular(10),
// // // //                                 bottomLeft: isSender ? const Radius.circular(10) : Radius.zero,
// // // //                                 bottomRight: isSender ? Radius.zero : const Radius.circular(10),
// // // //                               ),
// // // //                             ),
// // // //                             child: Column(
// // // //                               crossAxisAlignment: CrossAxisAlignment.start,
// // // //                               children: [
// // // //                                 Text(
// // // //                                   msg.text,
// // // //                                   style: TextStyle(color: isSender ? Colors.white : Colors.black),
// // // //                                 ),
// // // //                                 const SizedBox(height: 5),
// // // //                                 Align(
// // // //                                   alignment: Alignment.bottomRight,
// // // //                                   child: Text(
// // // //                                     DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp.toUtc()),
// // // //                                     style: const TextStyle(fontSize: 10, color: Colors.grey),
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       );
// // // //                     },
// // // //                   );
// // // //                 }
// // // //                 return const Center(child: Text("Aucun message."));
// // // //               },
// // // //             ),
// // // //           ),
// // // //           Padding(
// // // //             padding: const EdgeInsets.all(8.0),
// // // //             child: Row(
// // // //               children: [
// // // //                 Expanded(
// // // //                   child: TextField(
// // // //                     controller: _messageController,
// // // //                     focusNode: _focusNode,
// // // //                     onSubmitted: (text) {
// // // //                       sendMessage(text);
// // // //                     },
// // // //                     decoration: InputDecoration(
// // // //                       hintText: "Écrire un message",
// // // //                       filled: true,
// // // //                       fillColor: Colors.grey.shade200,
// // // //                       contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // // //                       border: OutlineInputBorder(
// // // //                         borderRadius: BorderRadius.circular(20),
// // // //                         borderSide: BorderSide.none,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(width: 10),
// // // //                 FloatingActionButton(
// // // //                   onPressed: () {
// // // //                     sendMessage(_messageController.text);
// // // //                   },
// // // //                   mini: true,
// // // //                   child: const Icon(Icons.send),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       bottomNavigationBar: BottomNavBar(
// // // //         currentIndex: 3, // 👈 Correspond à l'onglet "Messages"
// // // //         onTap: (index) {
// // // //           // rien ici, le contrôle se fait dans le widget lui-même
// // // //         },
// // // //       ),
// // // //     );
// // // //   }
// // // // }