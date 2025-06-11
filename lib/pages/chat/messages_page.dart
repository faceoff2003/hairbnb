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
        final coiffeuseUuids = conversations.map<String>((c) => c['otherUserId'] as String).toList();
        _cachedMinimalCoiffeuses = await _fetchMinimalCoiffeusesFromApi(coiffeuseUuids);
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

  Future<List<MinimalCoiffeuse>> _fetchMinimalCoiffeusesFromApi(List<String> coiffeuseUuids) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": coiffeuseUuids}),
      );

      if (response.statusCode != 200) throw Exception("Erreur API : ${response.statusCode}");

      final jsonData = jsonDecode(response.body);
      if (jsonData["status"] == "success") {
        return (jsonData["coiffeuses"] as List)
            .map((json) => MinimalCoiffeuse.fromJson(json))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur API : $e");
      }
    }

    return [];
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
  Future<bool> _showDeleteConfirmation(BuildContext context, String coiffeuseNom) async {
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
                'Voulez-vous vraiment supprimer votre conversation avec $coiffeuseNom ?',
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
  void _showStyledSuccessMessage(String coiffeuseNom) {
    // 🎨 CHOISISSEZ LE STYLE QUE VOUS PRÉFÉREZ :

    // Option 1: Dialog élégant (style promotion) - ACTUEL
    _showSuccessDialog(coiffeuseNom);

    // Option 2: Toast moderne en haut - Décommentez si vous préférez
    // _showStyledToast(coiffeuseNom);

    // Option 3: Banner animé - Décommentez si vous préférez
    // _showAnimatedBanner(coiffeuseNom);

    // Option 4: Card flottante au centre - Décommentez si vous préférez
    // _showFloatingCard(coiffeuseNom);
  }

  /// Dialog de succès élégant (style promotion)
  void _showSuccessDialog(String coiffeuseNom) {
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
                        text: coiffeuseNom,
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

  /// Toast stylé en haut
  void _showStyledToast(String coiffeuseNom) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Conversation supprimée',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Conversation avec $coiffeuseNom supprimée',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto-fermer après 4 secondes
    Future.delayed(Duration(seconds: 4), () {
      overlayEntry.remove();
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

            final coiffeuseNom = "${coiffeuse.prenom} ${coiffeuse.nom}".trim();
            final displayName = coiffeuseNom.isNotEmpty ? coiffeuseNom : "Coiffeuse";

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
                    backgroundImage: coiffeuse.photoProfil != null &&
                        coiffeuse.photoProfil!.isNotEmpty
                        ? NetworkImage(baseUrl + coiffeuse.photoProfil!)
                        : null,
                    child: coiffeuse.photoProfil == null ||
                        coiffeuse.photoProfil!.isEmpty
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
}













// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/models/message.dart';
// import 'package:hairbnb/services/my_drawer_service/hairbnb_scaffold.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../../models/minimal_coiffeuse.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import 'chat_page.dart';
//
// class MessagesPage extends StatefulWidget {
//   const MessagesPage({super.key});
//
//   @override
//   _MessagesPageState createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final String baseUrl = "https://www.hairbnb.site";
//
//   List<MinimalCoiffeuse> _cachedMinimalCoiffeuses = [];
//   List<Map<String, dynamic>> _conversations = [];
//   CurrentUser? currentUser;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadConversations();
//   }
//
//   Future<void> _loadConversations() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     if (currentUser == null) {
//       if (kDebugMode) {
//         print("⚠️ currentUser est null !");
//       }
//       setState(() {
//         _isLoading = false;
//       });
//       return;
//     }
//
//     try {
//       final snapshot = await databaseRef.once();
//
//       if (snapshot.snapshot.value == null) {
//         if (kDebugMode) {
//           print("⚠️ Aucune conversation trouvée.");
//         }
//         setState(() {
//           _conversations = [];
//           _isLoading = false;
//         });
//         return;
//       }
//
//       final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
//
//       final conversations = data.entries.where((entry) {
//         final participants = entry.key.split("_");
//         return participants.contains(currentUser!.uuid);
//       }).map((entry) {
//         final conversationKey = entry.key;
//         final messagesMap = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
//         if (messagesMap.isEmpty) return null;
//
//         final lastMessageKey = messagesMap.keys.last;
//         final lastMessage = Message.fromJson(messagesMap[lastMessageKey]);
//
//         final participants = conversationKey.split("_");
//         final otherUserId = (participants[0] == currentUser!.uuid) ? participants[1] : participants[0];
//
//         return {
//           "conversationKey": conversationKey,
//           "lastMessage": lastMessage.text,
//           "timestamp": lastMessage.timestamp,
//           "otherUserId": otherUserId,
//         };
//       }).whereType<Map<String, dynamic>>().toList();
//
//       conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
//
//       setState(() {
//         _conversations = conversations;
//       });
//
//       if (conversations.isNotEmpty) {
//         final coiffeuseUuids = conversations.map<String>((c) => c['otherUserId'] as String).toList();
//         _cachedMinimalCoiffeuses = await _fetchMinimalCoiffeusesFromApi(coiffeuseUuids);
//         setState(() {});
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur lors du chargement des conversations: $e");
//       }
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<List<MinimalCoiffeuse>> _fetchMinimalCoiffeusesFromApi(List<String> coiffeuseUuids) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"uuids": coiffeuseUuids}),
//       );
//
//       if (response.statusCode != 200) throw Exception("Erreur API : ${response.statusCode}");
//
//       final jsonData = jsonDecode(response.body);
//       if (jsonData["status"] == "success") {
//         return (jsonData["coiffeuses"] as List)
//             .map((json) => MinimalCoiffeuse.fromJson(json))
//             .toList();
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur API : $e");
//       }
//     }
//
//     return [];
//   }
//
//   /// Supprimer une conversation de Firebase
//   Future<void> _deleteConversation(String conversationKey) async {
//     try {
//       if (kDebugMode) {
//         print("🗑️ Suppression de la conversation: $conversationKey");
//       }
//
//       await databaseRef.child(conversationKey).remove();
//
//       if (kDebugMode) {
//         print("✅ Conversation supprimée avec succès");
//       }
//
//       // Recharger les conversations après suppression
//       await _loadConversations();
//
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur lors de la suppression: $e");
//       }
//
//       // Afficher une erreur à l'utilisateur
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Erreur lors de la suppression de la conversation"),
//             backgroundColor: Colors.red,
//             action: SnackBarAction(
//               label: "Réessayer",
//               textColor: Colors.white,
//               onPressed: () => _deleteConversation(conversationKey),
//             ),
//           ),
//         );
//       }
//     }
//   }
//
//   /// Afficher la boîte de dialogue de confirmation
//   Future<bool> _showDeleteConfirmation(BuildContext context, String coiffeuseNom) async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Row(
//             children: [
//               Icon(Icons.warning_amber_rounded, color: Colors.orange),
//               SizedBox(width: 8),
//               Text('Supprimer la conversation'),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Voulez-vous vraiment supprimer votre conversation avec $coiffeuseNom ?',
//                 style: TextStyle(fontSize: 16),
//               ),
//               SizedBox(height: 12),
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.red.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.info_outline, color: Colors.red.shade600, size: 20),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Cette action est irréversible. Tous les messages seront perdus.',
//                         style: TextStyle(
//                           color: Colors.red.shade700,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text(
//                 'Annuler',
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text('Supprimer'),
//             ),
//           ],
//         );
//       },
//     ) ?? false;
//   }
//
//   /// Afficher le SnackBar de succès avec option d'annulation
//   void _showDeleteSuccessSnackBar(String conversationKey, String coiffeuseNom) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text('Conversation avec $coiffeuseNom supprimée'),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         duration: Duration(seconds: 4),
//         action: SnackBarAction(
//           label: 'Annuler',
//           textColor: Colors.white,
//           onPressed: () {
//             // Note: L'annulation réelle nécessiterait de sauvegarder
//             // les données avant suppression, ce qui est complexe
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Impossible d\'annuler - conversation déjà supprimée'),
//                 backgroundColor: Colors.orange,
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   /// Rafraîchir les conversations (pull-to-refresh)
//   Future<void> _refreshConversations() async {
//     await _loadConversations();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return HairbnbScaffold(
//       body: RefreshIndicator(
//         onRefresh: _refreshConversations,
//         child: _isLoading
//             ? Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text("Chargement des conversations..."),
//             ],
//           ),
//         )
//             : _conversations.isEmpty
//             ? Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.chat_bubble_outline,
//                 size: 80,
//                 color: Colors.grey,
//               ),
//               SizedBox(height: 16),
//               Text(
//                 "Aucune conversation",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 "Vos conversations avec les coiffeuses\napparaîtront ici",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.grey[500],
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         )
//             : ListView.builder(
//           itemCount: _conversations.length,
//           itemBuilder: (context, index) {
//             final conversation = _conversations[index];
//             final otherUserId = conversation['otherUserId'];
//             final conversationKey = conversation['conversationKey'];
//
//             final coiffeuse = _cachedMinimalCoiffeuses.firstWhere(
//                   (c) => c.uuid == otherUserId,
//               orElse: () => MinimalCoiffeuse(
//                 uuid: otherUserId,
//                 idTblUser: 0,
//                 nom: "",
//                 prenom: "",
//                 photoProfil: '',
//               ),
//             );
//
//             final coiffeuseNom = "${coiffeuse.prenom} ${coiffeuse.nom}".trim();
//             final displayName = coiffeuseNom.isNotEmpty ? coiffeuseNom : "Coiffeuse";
//
//             return Dismissible(
//               key: Key(conversationKey),
//               direction: DismissDirection.endToStart,
//               background: Container(
//                 alignment: Alignment.centerRight,
//                 padding: EdgeInsets.only(right: 20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.red.shade300, Colors.red.shade600],
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.delete_forever,
//                       color: Colors.white,
//                       size: 32,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'Supprimer',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               confirmDismiss: (direction) async {
//                 return await _showDeleteConfirmation(context, displayName);
//               },
//               onDismissed: (direction) async {
//                 // Sauvegarder les infos avant suppression pour le SnackBar
//                 final tempConversationKey = conversationKey;
//                 final tempDisplayName = displayName;
//
//                 await _deleteConversation(tempConversationKey);
//                 _showDeleteSuccessSnackBar(tempConversationKey, tempDisplayName);
//               },
//               child: Card(
//                 margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ListTile(
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.grey.shade300,
//                     radius: 28,
//                     backgroundImage: coiffeuse.photoProfil != null &&
//                         coiffeuse.photoProfil!.isNotEmpty
//                         ? NetworkImage(baseUrl + coiffeuse.photoProfil!)
//                         : null,
//                     child: coiffeuse.photoProfil == null ||
//                         coiffeuse.photoProfil!.isEmpty
//                         ? Icon(Icons.person, color: Colors.white, size: 30)
//                         : null,
//                   ),
//                   title: Text(
//                     displayName,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: 4),
//                       Text(
//                         conversation['lastMessage'],
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: Colors.grey[700],
//                           fontSize: 14,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.access_time,
//                             size: 14,
//                             color: Colors.grey[500],
//                           ),
//                           SizedBox(width: 4),
//                           Text(
//                             DateFormat('dd/MM/yyyy HH:mm')
//                                 .format(conversation['timestamp']),
//                             style: TextStyle(
//                               color: Colors.grey[500],
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Bouton de suppression explicite (optionnel)
//                       IconButton(
//                         icon: Icon(
//                           Icons.delete_outline,
//                           color: Colors.red.shade400,
//                           size: 20,
//                         ),
//                         onPressed: () async {
//                           final confirmed = await _showDeleteConfirmation(
//                             context,
//                             displayName,
//                           );
//                           if (confirmed) {
//                             await _deleteConversation(conversationKey);
//                             _showDeleteSuccessSnackBar(conversationKey, displayName);
//                           }
//                         },
//                         tooltip: "Supprimer la conversation",
//                       ),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         size: 16,
//                         color: Colors.grey[400],
//                       ),
//                     ],
//                   ),
//                   onTap: () {
//                     final currentUser = Provider.of<CurrentUserProvider>(
//                       context,
//                       listen: false,
//                     ).currentUser;
//
//                     if (currentUser != null) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ChatPage(
//                             currentUser: currentUser,
//                             otherUserId: coiffeuse.uuid,
//                           ),
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 3,
//         onTap: (index) {
//           // Navigation gérée dans le BottomNavBar lui-même
//         },
//       ),
//     );
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
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:hairbnb/models/message.dart';
// // import 'package:hairbnb/services/my_drawer_service/hairbnb_scaffold.dart';
// // import 'package:hairbnb/services/providers/current_user_provider.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:provider/provider.dart';
// // import 'package:intl/intl.dart';
// // import '../../models/minimal_coiffeuse.dart';
// // import '../../widgets/bottom_nav_bar.dart';
// // import 'chat_page.dart';
// //
// // class MessagesPage extends StatefulWidget {
// //   const MessagesPage({super.key});
// //
// //   @override
// //   _MessagesPageState createState() => _MessagesPageState();
// // }
// //
// // class _MessagesPageState extends State<MessagesPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final String baseUrl = "https://www.hairbnb.site";
// //
// //   List<MinimalCoiffeuse> _cachedMinimalCoiffeuses = [];
// //   List<Map<String, dynamic>> _conversations = [];
// //   CurrentUser? currentUser;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadConversations();
// //   }
// //
// //   Future<void> _loadConversations() async {
// //     currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
// //
// //     if (currentUser == null) {
// //       print("⚠️ currentUser est null !");
// //       return;
// //     }
// //
// //     databaseRef.once().then((snapshot) async {
// //       if (snapshot.snapshot.value == null) {
// //         print("⚠️ Aucune conversation trouvée.");
// //         return;
// //       }
// //
// //       final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
// //
// //       final conversations = data.entries.where((entry) {
// //         final participants = entry.key.split("_");
// //         return participants.contains(currentUser!.uuid);
// //       }).map((entry) {
// //         final conversationKey = entry.key;
// //         final messagesMap = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
// //         if (messagesMap.isEmpty) return null;
// //
// //         final lastMessageKey = messagesMap.keys.last;
// //         final lastMessage = Message.fromJson(messagesMap[lastMessageKey]);
// //
// //         final participants = conversationKey.split("_");
// //         final otherUserId = (participants[0] == currentUser!.uuid) ? participants[1] : participants[0];
// //
// //         return {
// //           "conversationKey": conversationKey,
// //           "lastMessage": lastMessage.text,
// //           "timestamp": lastMessage.timestamp,
// //           "otherUserId": otherUserId,
// //         };
// //       }).whereType<Map<String, dynamic>>().toList();
// //
// //       conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
// //
// //       setState(() {
// //         _conversations = conversations;
// //       });
// //
// //       final coiffeuseUuids = _conversations.map<String>((c) => c['otherUserId'] as String).toList();
// //       _cachedMinimalCoiffeuses = await _fetchMinimalCoiffeusesFromApi(coiffeuseUuids);
// //       setState(() {});
// //     });
// //   }
// //
// //   Future<List<MinimalCoiffeuse>> _fetchMinimalCoiffeusesFromApi(List<String> coiffeuseUuids) async {
// //     try {
// //       final response = await http.post(
// //         Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode({"uuids": coiffeuseUuids}),
// //       );
// //
// //       if (response.statusCode != 200) throw Exception("Erreur API : ${response.statusCode}");
// //
// //       final jsonData = jsonDecode(response.body);
// //       if (jsonData["status"] == "success") {
// //         return (jsonData["coiffeuses"] as List)
// //             .map((json) => MinimalCoiffeuse.fromJson(json))
// //             .toList();
// //       }
// //     } catch (e) {
// //       print("Erreur API : $e");
// //     }
// //
// //     return [];
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     // Plus besoin de récupérer currentUser ici, c'est géré dans HairbnbScaffold
// //
// //     return HairbnbScaffold(
// //       body: _conversations.isEmpty
// //           ? const Center(child: Text("Aucune conversation."))
// //           : ListView.builder(
// //         itemCount: _conversations.length,
// //         itemBuilder: (context, index) {
// //           final conversation = _conversations[index];
// //           final otherUserId = conversation['otherUserId'];
// //
// //           final coiffeuse = _cachedMinimalCoiffeuses.firstWhere(
// //                 (c) => c.uuid == otherUserId,
// //             orElse: () => MinimalCoiffeuse(
// //               uuid: otherUserId,
// //               idTblUser: 0,
// //               nom: "",
// //               prenom: "",
// //               photoProfil: '',
// //               //position: '',
// //             ),
// //           );
// //
// //           return ListTile(
// //             leading: CircleAvatar(
// //               backgroundColor: Colors.grey.shade300,
// //               backgroundImage: coiffeuse.photoProfil != null && coiffeuse.photoProfil!.isNotEmpty
// //                   ? NetworkImage(baseUrl + coiffeuse.photoProfil!)
// //                   : null,
// //               child: coiffeuse.photoProfil == null || coiffeuse.photoProfil!.isEmpty
// //                   ? const Icon(Icons.person, color: Colors.white)
// //                   : null,
// //             ),
// //             title: Text(
// //               "${coiffeuse.prenom} ${coiffeuse.nom}",
// //               style: const TextStyle(fontWeight: FontWeight.bold),
// //             ),
// //             subtitle: Text(conversation['lastMessage']),
// //             trailing: Text(
// //               DateFormat('dd/MM/yyyy HH:mm').format(conversation['timestamp']),
// //               style: const TextStyle(color: Colors.grey),
// //             ),
// //             onTap: () {
// //               // Nous avons toujours besoin du currentUser ici, mais nous le récupérons du Provider
// //               final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
// //
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(
// //                   builder: (context) => ChatPage(
// //                     currentUser: currentUser!,
// //                     otherUserId: coiffeuse.uuid,
// //                   ),
// //                 ),
// //               );
// //             },
// //           );
// //         },
// //       ),
// //       bottomNavigationBar: BottomNavBar(
// //         currentIndex: 3, // 👈 Onglet "Messages"
// //         onTap: (index) {
// //           // Navigation gérée dans le BottomNavBar lui-même
// //         },
// //       ),
// //     );
// //   }
// // }