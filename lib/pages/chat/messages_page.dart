import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/models/message.dart';
import 'package:hairbnb/services/my_drawer_service/hairbnb_scaffold.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/minimal_coiffeuse.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final databaseRef = FirebaseDatabase.instance.ref();
  final String baseUrl = "https://www.hairbnb.site";

  List<MinimalCoiffeuse> _cachedMinimalCoiffeuses = [];
  List<Map<String, dynamic>> _conversations = [];
  CurrentUser? currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

    if (currentUser == null) {
      if (kDebugMode) {
        print("⚠️ currentUser est null !");
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await databaseRef.once();

      if (snapshot.snapshot.value == null) {
        if (kDebugMode) {
          print("⚠️ Aucune conversation trouvée.");
        }
        setState(() {
          _conversations = [];
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};

      final conversations = data.entries.where((entry) {
        final participants = entry.key.split("_");
        return participants.contains(currentUser!.uuid);
      }).map((entry) {
        final conversationKey = entry.key;
        final messagesMap = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
        if (messagesMap.isEmpty) return null;

        final lastMessageKey = messagesMap.keys.last;
        final lastMessage = Message.fromJson(messagesMap[lastMessageKey]);

        final participants = conversationKey.split("_");
        final otherUserId = (participants[0] == currentUser!.uuid) ? participants[1] : participants[0];

        return {
          "conversationKey": conversationKey,
          "lastMessage": lastMessage.text,
          "timestamp": lastMessage.timestamp,
          "otherUserId": otherUserId,
        };
      }).whereType<Map<String, dynamic>>().toList();

      conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _conversations = conversations;
      });

      if (conversations.isNotEmpty) {
        final userUuids = conversations.map<String>((c) => c['otherUserId'] as String).toList();
        _cachedMinimalCoiffeuses = await _fetchUsersFromApiUnified(userUuids);
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors du chargement des conversations: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Récupération utilisateurs UNIFIÉE avec gestion d'erreurs améliorée
  Future<List<MinimalCoiffeuse>> _fetchUsersFromApiUnified(List<String> userUuids) async {
    final results = <MinimalCoiffeuse>[];
    final errors = <String>[];

    if (kDebugMode) {
      print("🔍 [MessagesPage] Recherche pour ${userUuids.length} UUIDs: ${userUuids.join(', ')}");
    }

    for (String uuid in userUuids) {
      try {
        // Stratégie 1: Endpoint unifié (PRIORITÉ)
        MinimalCoiffeuse? user = await _tryUnifiedEndpointForUser(uuid);
        
        // Stratégie 2: Fallback endpoint coiffeuses
        user ??= await _tryCoiffeusesEndpointForUser(uuid);
        
        if (user != null) {
          results.add(user);
          if (kDebugMode) {
            print("✅ [MessagesPage] Utilisateur trouvé: ${user.prenom} ${user.nom} (${user.uuid})");
          }
        } else {
          errors.add("UUID $uuid: Non trouvé");
          if (kDebugMode) {
            print("❌ [MessagesPage] Utilisateur non trouvé pour UUID: $uuid");
          }
        }
      } catch (e) {
        errors.add("UUID $uuid: Exception $e");
        if (kDebugMode) {
          print("❌ [MessagesPage] Exception pour UUID $uuid: $e");
        }
      }
    }

    // Logger les erreurs pour débuggage
    if (errors.isNotEmpty && kDebugMode) {
      if (kDebugMode) {
        print("❌ [MessagesPage] Erreurs de récupération utilisateurs:");
      }
      for (String error in errors) {
        if (kDebugMode) {
          print("  - $error");
        }
      }
    }

    if (kDebugMode) {
      print("✅ [MessagesPage] Total utilisateurs récupérés: ${results.length}/${userUuids.length}");
    }

    return results;
  }

  /// ✅ Stratégie 1: Endpoint unifié pour un utilisateur
  Future<MinimalCoiffeuse?> _tryUnifiedEndpointForUser(String uuid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_user_profile/$uuid/'),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 8));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        if (userData["success"] == true && userData["data"] != null) {
          final user = userData["data"];

          return MinimalCoiffeuse(
            uuid: user['uuid'] ?? uuid,
            idTblUser: user['idTblUser'] ?? 0,
            nom: user['nom'] ?? '',
            prenom: user['prenom'] ?? '',
            photoProfil: user['photo_profil'], // ✅ Underscore cohérent
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [Endpoint Unifié] Erreur pour $uuid: $e");
      }
    }
    return null;
  }

  /// ✅ Stratégie 2: Endpoint coiffeuses pour un utilisateur
  Future<MinimalCoiffeuse?> _tryCoiffeusesEndpointForUser(String uuid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": [uuid]}),
      ).timeout(Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
          final coiffeusesList = jsonData["coiffeuses"] as List;
          
          for (var coiffeuseData in coiffeusesList) {
            if (coiffeuseData['uuid'] == uuid) {
              return MinimalCoiffeuse(
                uuid: coiffeuseData['uuid'] ?? uuid,
                idTblUser: coiffeuseData['idTblUser'] ?? 0,
                nom: coiffeuseData['nom'] ?? '',
                prenom: coiffeuseData['prenom'] ?? '',
                photoProfil: coiffeuseData['photo_profil'], // ✅ Underscore cohérent
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ [Endpoint Coiffeuses] Erreur pour $uuid: $e");
      }
    }
    return null;
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

  /// Supprimer une conversation de Firebase
  Future<void> _deleteConversation(String conversationKey) async {
    try {
      if (kDebugMode) {
        print("🗑️ Suppression de la conversation: $conversationKey");
      }

      await databaseRef.child(conversationKey).remove();

      if (kDebugMode) {
        print("✅ Conversation supprimée avec succès");
      }

      // Recharger les conversations après suppression
      await _loadConversations();

    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors de la suppression: $e");
      }

      // Afficher une erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression de la conversation"),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: "Réessayer",
              textColor: Colors.white,
              onPressed: () => _deleteConversation(conversationKey),
            ),
          ),
        );
      }
    }
  }

  /// Afficher la boîte de dialogue de confirmation
  Future<bool> _showDeleteConfirmation(BuildContext context, String userName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Supprimer la conversation'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voulez-vous vraiment supprimer votre conversation avec $userName ?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade600, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette action est irréversible. Tous les messages seront perdus.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Message de succès stylé (type promotion)
  void _showStyledSuccessMessage(String userName) {
    _showSuccessDialog(userName);
  }

  /// Dialog de succès élégant (style promotion)
  void _showSuccessDialog(String userName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 50,
                  ),
                ),
                SizedBox(height: 20),

                // Titre
                Text(
                  'Conversation supprimée',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 12),

                // Message
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: 'Votre conversation avec '),
                      TextSpan(
                        text: userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                      TextSpan(text: ' a été supprimée avec succès.'),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Bouton OK
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Parfait !',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Auto-fermer après 3 secondes
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Rafraîchir les conversations (pull-to-refresh)
  Future<void> _refreshConversations() async {
    await _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return HairbnbScaffold(
      body: RefreshIndicator(
        onRefresh: _refreshConversations,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Chargement des conversations..."),
            ],
          ),
        )
            : _conversations.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                "Aucune conversation",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Vos conversations avec les coiffeuses\napparaîtront ici",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final conversation = _conversations[index];
            final otherUserId = conversation['otherUserId'];
            final conversationKey = conversation['conversationKey'];

            final coiffeuse = _cachedMinimalCoiffeuses.firstWhere(
                  (c) => c.uuid == otherUserId,
              orElse: () => MinimalCoiffeuse(
                uuid: otherUserId,
                idTblUser: 0,
                nom: "",
                prenom: "",
                photoProfil: '',
              ),
            );

            final userName = "${coiffeuse.prenom} ${coiffeuse.nom}".trim();
            final displayName = userName.isNotEmpty ? userName : "Utilisateur";

            return Dismissible(
              key: Key(conversationKey),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade300, Colors.red.shade600],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Supprimer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              confirmDismiss: (direction) async {
                return await _showDeleteConfirmation(context, displayName);
              },
              onDismissed: (direction) async {
                await _deleteConversation(conversationKey);
                _showStyledSuccessMessage(displayName);
              },
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    radius: 28,
                    backgroundImage: _buildProfileImage(coiffeuse.photoProfil),
                    child: _buildProfileImage(coiffeuse.photoProfil) == null
                        ? Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        conversation['lastMessage'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(conversation['timestamp']),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        onPressed: () async {
                          final confirmed = await _showDeleteConfirmation(
                            context,
                            displayName,
                          );
                          if (confirmed) {
                            await _deleteConversation(conversationKey);
                            _showStyledSuccessMessage(displayName);
                          }
                        },
                        tooltip: "Supprimer la conversation",
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  onTap: () {
                    final currentUser = Provider.of<CurrentUserProvider>(
                      context,
                      listen: false,
                    ).currentUser;

                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            currentUser: currentUser,
                            otherUserId: coiffeuse.uuid,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          // Navigation gérée dans le BottomNavBar lui-même
        },
      ),
    );
  }

  /// ✅ Construire l'image de profil NORMALISÉE
  ImageProvider? _buildProfileImage(String? photoProfil) {
    final photoUrl = _getPhotoUrl(photoProfil);
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
    return null; // Retourner null pour utiliser l'icône par défaut
  }
}
