import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/models/message.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/Custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/MinimalCoiffeuse.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final databaseRef = FirebaseDatabase.instance.ref();
  final String baseUrl = "http://192.168.0.248:8000";

  List<MinimalCoiffeuse> _cachedMinimalCoiffeuses = []; // Stocke les coiffeuses minimales
  List<Map<String, dynamic>> _conversations = []; // Stocke les conversations une seule fois
  CurrentUser? currentUser;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

    if (currentUser == null) {
      print("⚠️ currentUser est null !");
      return;
    }

    databaseRef.once().then((snapshot) async {
      if (snapshot.snapshot.value == null) {
        print("⚠️ Aucune conversation trouvée.");
        return;
      }

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};

      // Filtrer les conversations de l'utilisateur actuel
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

      // Trier les conversations par timestamp (du plus récent au plus ancien)
      conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Stocker les conversations une seule fois
      setState(() {
        _conversations = conversations;
      });

      // Charger les coiffeuses minimales une seule fois
      final coiffeuseUuids = _conversations.map<String>((c) => c['otherUserId'] as String).toList();
      _cachedMinimalCoiffeuses = await _fetchMinimalCoiffeusesFromApi(coiffeuseUuids);
      setState(() {}); // Rafraîchir l'affichage
    });
  }

  /// 🔹 Fonction pour récupérer les **coiffeuses minimales** depuis l'API
  Future<List<MinimalCoiffeuse>> _fetchMinimalCoiffeusesFromApi(List<String> coiffeuseUuids) async {
    print("UUIDs envoyés à l'API : ${jsonEncode({"uuids": coiffeuseUuids})}");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": coiffeuseUuids}),
      );

      if (response.statusCode != 200) {
        throw Exception("Erreur API : ${response.statusCode}");
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData["status"] == "success") {
        return (jsonData["coiffeuses"] as List)
            .map((json) => MinimalCoiffeuse.fromJson(json))
            .toList();
      }
    } catch (e) {
      print("Erreur lors de la récupération des coiffeuses : $e");
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: CustomAppBar(),
      body: _conversations.isEmpty
          ? const Center(child: Text("Aucune conversation."))
          : ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final otherUserId = conversation['otherUserId'];

          // Récupérer l'autre utilisateur (coiffeuse minimale)
          final coiffeuse = _cachedMinimalCoiffeuses.firstWhere(
                (c) => c.uuid == otherUserId,
            orElse: () => MinimalCoiffeuse(uuid: otherUserId, idTblUser: 0, nom: "", prenom: "", photoProfil: '',position: ''),
          );

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              backgroundImage: coiffeuse.photoProfil != null
                  ? NetworkImage(baseUrl + coiffeuse.photoProfil!)
                  : null,
              child: coiffeuse.photoProfil == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              "${coiffeuse.prenom} ${coiffeuse.nom}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(conversation['lastMessage']),
            trailing: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(conversation['timestamp']),
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    currentUser :currentUser,
                    otherUserId: coiffeuse.uuid,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}























// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:hairbnb/models/message.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'chat_page.dart';
//
// class MessagesPage extends StatefulWidget {
//   const MessagesPage({Key? key}) : super(key: key);
//
//   @override
//   _MessagesPageState createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final String baseUrl = "http://192.168.0.248:8000";
//
//   List<Coiffeuse> _cachedCoiffeuses = []; // Stocker les coiffeuses pour éviter les appels API répétitifs
//   List<Map<String, dynamic>> _conversations = []; // Stocker les conversations une seule fois
//
//   @override
//   void initState() {
//     super.initState();
//     _loadConversations();
//   }
//
//   Future<void> _loadConversations() async {
//     final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     if (currentUser == null) {
//       print("⚠️ currentUser est null !");
//       return;
//     }
//
//     databaseRef.once().then((snapshot) async {
//       if (snapshot.snapshot.value == null) {
//         print("⚠️ Aucune conversation trouvée.");
//         return;
//       }
//
//       final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
//
//       // Filtrer les conversations de l'utilisateur actuel
//       final conversations = data.entries.where((entry) {
//         final participants = entry.key.split("_");
//         return participants.contains(currentUser.uuid);
//       }).map((entry) {
//         final conversationKey = entry.key;
//         final messagesMap = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
//         if (messagesMap.isEmpty) return null;
//
//         final lastMessageKey = messagesMap.keys.last;
//         final lastMessage = Message.fromJson(messagesMap[lastMessageKey]);
//
//         final participants = conversationKey.split("_");
//         final otherUserId = (participants[0] == currentUser.uuid) ? participants[1] : participants[0];
//
//         return {
//           "conversationKey": conversationKey,
//           "lastMessage": lastMessage.text,
//           "timestamp": lastMessage.timestamp,
//           "otherUserId": otherUserId,
//         };
//       }).whereType<Map<String, dynamic>>().toList();
//
//       // Trier les conversations par timestamp (du plus récent au plus ancien)
//       conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
//
//       // Stocker les conversations une seule fois
//       setState(() {
//         _conversations = conversations;
//       });
//
//       // Charger les coiffeuses une seule fois
//       final coiffeuseUuids = _conversations.map<String>((c) => c['otherUserId'] as String).toList();
//       _cachedCoiffeuses = await _fetchCoiffeusesFromApi(coiffeuseUuids);
//       setState(() {}); // Rafraîchir l'affichage
//     });
//   }
//
//   Future<List<Coiffeuse>> _fetchCoiffeusesFromApi(List<String> coiffeuseUuids) async {
//     print("UUIDs envoyés à l'API : ${jsonEncode({"uuids": coiffeuseUuids})}");
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"uuids": coiffeuseUuids}),
//       );
//
//       if (response.statusCode != 200) {
//         throw Exception("Erreur API : ${response.statusCode}");
//       }
//
//       final jsonData = jsonDecode(response.body);
//       if (jsonData["status"] == "success") {
//         return (jsonData["coiffeuses"] as List)
//             .map((json) => Coiffeuse.fromJson(json))
//             .toList();
//       }
//     } catch (e) {
//       print("Erreur lors de la récupération des coiffeuses : $e");
//     }
//
//     return [];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//     if (currentUser == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return Scaffold(
//       appBar: CustomAppBar(),
//       body: _conversations.isEmpty
//           ? const Center(child: Text("Aucune conversation."))
//           : ListView.builder(
//         itemCount: _conversations.length,
//         itemBuilder: (context, index) {
//           final conversation = _conversations[index];
//           final otherUserId = conversation['otherUserId'];
//
//           // Récupérer l'autre utilisateur (coiffeuse)
//           final coiffeuse = _cachedCoiffeuses.firstWhere(
//                 (c) => c.uuid == otherUserId,
//             orElse: () => Coiffeuse(uuid: otherUserId, nom: "", prenom: "", idTblUser: 0, email: '', numeroTelephone: '', sexe: '', isActive: true),
//           );
//
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.grey.shade300,
//               backgroundImage: coiffeuse.photoProfil != null && coiffeuse.photoProfil!.isNotEmpty
//                   ? NetworkImage(baseUrl + coiffeuse.photoProfil!)
//                   : null,
//               child: coiffeuse.photoProfil == null || coiffeuse.photoProfil!.isEmpty
//                   ? const Icon(Icons.person, color: Colors.white)
//                   : null,
//             ),
//             title: Text(
//               "${coiffeuse.prenom} ${coiffeuse.nom}",
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text(conversation['lastMessage']),
//             trailing: Text(
//               DateFormat('dd/MM/yyyy HH:mm').format(conversation['timestamp']),
//               style: const TextStyle(color: Colors.grey),
//             ),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatPage(
//                     clientId: currentUser.uuid,
//                     otherUserId: coiffeuse.uuid,
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }











// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:hairbnb/models/message.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart' show Provider;
// import 'package:intl/intl.dart';
// import 'chat_page.dart';
//
// class MessagesPage extends StatefulWidget {
//   const MessagesPage({Key? key}) : super(key: key);
//
//   @override
//   _MessagesPageState createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final String baseUrl = "http://192.168.0.248:8000";
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       body: StreamBuilder(
//         stream: databaseRef.onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 "Une erreur est survenue. Veuillez réessayer.",
//                 style: TextStyle(color: Colors.red),
//               ),
//             );
//           }
//
//           if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//             final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
//             final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//
//             //-------------------------------------------------------------
//             print('UUID current user: ${currentUser!.uuid}');
//             //----------------------------------------------------------------
//
//             // Filtrer uniquement les conversations de l'utilisateur actuel
//             final conversations = data.entries.where((entry) {
//               final participants = entry.key.split("_");
//               return participants.contains(currentUser.uuid);
//             }).map((entry) {
//               final conversationKey = entry.key;
//               final messagesMap = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
//               if (messagesMap.isEmpty) return null;
//
//               final lastMessageKey = messagesMap.keys.last;
//               final lastMessage = Message.fromJson(messagesMap[lastMessageKey]);
//
//               // Identifier le participant autre que l'utilisateur actuel
//               final participants = conversationKey.split("_");
//               final otherUserId = (participants[0] == currentUser.uuid) ? participants[1] : participants[0];
//
//               return {
//                 "conversationKey": conversationKey,
//                 "lastMessage": lastMessage.text,
//                 "timestamp": lastMessage.timestamp,
//                 "otherUserId": otherUserId, // UUID de l'autre utilisateur
//               };
//             }).whereType<Map<String, dynamic>>().toList(); // Supprimer les null
//
//             // Trier les conversations par timestamp (du plus récent au plus ancien)
//             conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
//
//             return ListView.builder(
//               itemCount: conversations.length,
//               itemBuilder: (context, index) {
//                 final conversation = conversations[index];
//                 final otherUserId = conversation['otherUserId'];
//
//                 //----------------------------------------------------------------
//                 print('UUID autre utilisateur: $otherUserId');
//                 //----------------------------------------------------------------
//
//                 return FutureBuilder<List<Coiffeuse>>(
//                   future: _fetchAndCacheCoiffeuses(
//                       conversations.map<String>((c) => c['otherUserId'] as String).toList()),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//
//                     if (snapshot.hasError || snapshot.data == null) {
//                       return const Center(child: Text("Erreur de chargement des coiffeuses."));
//                     }
//
//                     final coiffeuses = snapshot.data!;
//
//                     return ListView.builder(
//                       itemCount: coiffeuses.length,
//                       itemBuilder: (context, index) {
//                         final coiffeuse = coiffeuses[index];
//
//                         return ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.grey.shade300,
//                             backgroundImage: coiffeuse.photoProfil != null && coiffeuse.photoProfil!.isNotEmpty
//                                 ? NetworkImage(baseUrl + coiffeuse.photoProfil!)
//                                 : null,
//                             child: coiffeuse.photoProfil == null || coiffeuse.photoProfil!.isEmpty
//                                 ? const Icon(Icons.person, color: Colors.white)
//                                 : null,
//                           ),
//                           title: Text(
//                             "${coiffeuse.prenom} ${coiffeuse.nom}",
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(conversations[index]['lastMessage']),
//                           trailing: Text(
//                             DateFormat('dd/MM/yyyy HH:mm').format(conversations[index]['timestamp']),
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ChatPage(
//                                   clientId: Provider.of<CurrentUserProvider>(context, listen: false).currentUser!.uuid,
//                                   otherUserId: coiffeuse.uuid,
//                                 ),
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             );
//           }
//
//           return const Center(
//             child: Text("Aucune conversation."),
//           );
//         },
//       ),
//     );
//   }
//
//   Future<List<Coiffeuse>> _fetchAndCacheCoiffeuses(List<String> coiffeuseUuids) async {
//     List<Coiffeuse> coiffeusesList = [];
//
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"uuids": coiffeuseUuids}),
//       );
//
//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);
//         if (jsonData["status"] == "success") {
//           final List<dynamic> coiffeusesData = jsonData["coiffeuses"];
//           coiffeusesList = coiffeusesData.map((json) => Coiffeuse.fromJson(json)).toList();
//         }
//       }
//     } catch (e) {
//       print("Erreur lors de la récupération des informations: $e");
//     }
//
//     return coiffeusesList;
//   }
//   }




// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:hairbnb/models/message.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:provider/provider.dart' show Provider;
// import 'package:intl/intl.dart';
// import 'chat_page.dart';
//
// class MessagesPage extends StatefulWidget {
//   const MessagesPage({Key? key}) : super(key: key);
//
//   @override
//   _MessagesPageState createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       body: StreamBuilder(
//         stream: databaseRef.onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 "Une erreur est survenue. Veuillez réessayer.",
//                 style: TextStyle(color: Colors.red),
//               ),
//             );
//           }
//
//           if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//             final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
//             final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//
//             //-------------------------------------------------------------
//             print('UUID current user: ${currentUser!.uuid}');
//             //----------------------------------------------------------------
//
//
//             // Filtrer uniquement les conversations de l'utilisateur actuel
//             final conversations = data.entries.where((entry) {
//               final participants = entry.key.split("_");
//               return participants.contains(currentUser.uuid);
//             }).map((entry) {
//               final conversationKey = entry.key;
//               final messagesMap = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
//               if (messagesMap.isEmpty) return null;
//
//               final lastMessageKey = messagesMap.keys.last;
//               final lastMessage = Message.fromJson(messagesMap[lastMessageKey]);
//
//               // Identifier le participant autre que l'utilisateur actuel
//               final participants = conversationKey.split("_");
//               final otherUserId = (participants[0] == currentUser.uuid) ? participants[1] : participants[0];
//
//               return {
//                 "conversationKey": conversationKey,
//                 "lastMessage": lastMessage.text,
//                 "timestamp": lastMessage.timestamp,
//                 "otherUserId": otherUserId, // UUID de l'autre utilisateur
//               };
//             }).whereType<Map<String, dynamic>>().toList(); // Supprimer les null
//
//             // Trier les conversations par timestamp (du plus récent au plus ancien)
//             conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
//
//             return ListView.builder(
//               itemCount: conversations.length,
//               itemBuilder: (context, index) {
//                 final conversation = conversations[index];
//                 final otherUserId = conversation['otherUserId'];
//
//
//                 //----------------------------------------------------------------
//                 print('UUID autre utilisateur: $otherUserId');
//                 //----------------------------------------------------------------
//
//                 return ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Colors.blueAccent,
//                     child: Icon(Icons.person, color: Colors.white),
//                   ),
//                   title: Text(
//                     "Utilisateur $otherUserId",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(conversation['lastMessage']),
//                   trailing: Text(
//                     DateFormat('dd/MM/yyyy HH:mm').format(conversation['timestamp']),
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChatPage(
//                           clientId: currentUser.uuid,
//                           coiffeuseId: otherUserId,
//                           coiffeuseName: "Utilisateur $otherUserId",
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           }
//
//           return const Center(
//             child: Text("Aucune conversation."),
//           );
//         },
//       ),
//     );
//   }
// }





















//----------------------------------------code fonction 100% il fau le factoring----------------------------------
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:provider/provider.dart' show Provider;
// import 'chat_page.dart';
// import 'package:intl/intl.dart';
//
// class MessagesPage extends StatefulWidget {
//   //final String clientId;
//
//   const MessagesPage({Key? key}) : super(key: key);
//
//   @override
//   _MessagesPageState createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       body: StreamBuilder(
//         stream: databaseRef.onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 "Une erreur est survenue. Veuillez réessayer.",
//                 style: TextStyle(color: Colors.red),
//               ),
//             );
//           }
//
//           if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//             final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
//
//             final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//       //------------------------------------------------------------------------------------------
//             print('le uuid current user est : '+currentUser!.uuid);
//       //-----------------------------------------------------------------------------
//             // Filtrer uniquement les conversations de l'utilisateur actuel
//             final conversations = data.entries.where((entry) {
//               final participants = entry.key.split("_");
//               return participants.contains(currentUser.uuid);
//             }).map((entry) {
//               final conversationKey = entry.key;
//               final messages = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
//               if (messages.isEmpty) return null;
//
//               final lastMessageKey = messages.keys.last;
//               final lastMessage = messages[lastMessageKey];
//
//               // Identifier qui est la coiffeuse dans la conversation
//               final participants = conversationKey.split("_");
//               final coiffeuseId = (participants[0] == currentUser.uuid) ? participants[1] : participants[0];
//
//               return {
//                 "conversationKey": conversationKey,
//                 "lastMessage": lastMessage?['text'] ?? "Pas de message.",
//                 "timestamp": lastMessage?['timestamp'] ?? "",
//                 "coiffeuseId": coiffeuseId, // Extraire l'ID de la coiffeuse
//               };
//             }).whereType<Map<String, dynamic>>().toList(); // Supprimer les null
//
//
//             // Trier les conversations par timestamp
//             // Trier les conversations par timestamp
//             conversations.sort((a, b) {
//               final DateTime tsA = getDateTime(a['timestamp']);
//               final DateTime tsB = getDateTime(b['timestamp']);
//               return tsB.compareTo(tsA); // Trier du plus récent au plus ancien
//             });
//
//
//             return ListView.builder(
//               itemCount: conversations.length,
//               itemBuilder: (context, index) {
//                 final conversation = conversations[index];
//                 final coiffeuseId = conversation['coiffeuseId'];
//
//                 //------------------------------------------------------------------------------------------
//                 //print('le uuid coiffeuse est : '+conversation['sender']);
//                 print('le uuid coiffeuse est : '+coiffeuseId);
//                 //-----------------------------------------------------------------------------
//
//                 return ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Colors.blueAccent,
//                     child: Icon(Icons.person, color: Colors.white),
//                   ),
//                   title: Text(
//                     "Coiffeuse $coiffeuseId",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(conversation['lastMessage']),
//                   trailing: Text(
//                     DateFormat('dd/MM/yyyy HH:mm').format(
//                       getDateTime(conversation['timestamp']),
//                     ),
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChatPage(
//                           clientId: currentUser.uuid,
//                           coiffeuseId: coiffeuseId,
//                           coiffeuseName: "Coiffeuse $coiffeuseId",
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           }
//
//           return const Center(
//             child: Text("Aucune conversation."),
//           );
//         },
//       ),
//     );
//   }
//   DateTime getDateTime(dynamic timestamp) {
//     if (timestamp is String) {
//       return DateTime.parse(timestamp).toUtc(); // Format ISO (String)
//     } else if (timestamp is int) {
//       return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true); // Timestamp Unix (int)
//     }
//     return DateTime.now().toUtc(); // Sécurité : si null, on prend l'heure actuelle
//   }
//
//
// }



// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'chat_page.dart';
//
// class MessagesPage extends StatefulWidget {
//   final String clientId;
//
//   const MessagesPage({Key? key, required this.clientId}) : super(key: key);
//
//   @override
//   _MessagesPageState createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Chats"),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF6D20A5),
//       ),
//       body: StreamBuilder(
//         stream: databaseRef.onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 "Une erreur est survenue. Veuillez réessayer.",
//                 style: TextStyle(color: Colors.red),
//               ),
//             );
//           }
//
//           if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//             final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
//
//             final conversations = data.entries.where((entry) {
//               return entry.key.startsWith("currentUserUuid");
//             }).map((entry) {
//               final conversationKey = entry.key;
//               final messages = entry.value['messages'] as Map<dynamic, dynamic>;
//               final lastMessageKey = messages.keys.last;
//               final lastMessage = messages[lastMessageKey];
//
//               return {
//                 "conversationKey": conversationKey,
//                 "lastMessage": lastMessage?['text'] ?? "Pas de message.",
//                 "timestamp": lastMessage?['timestamp'] ?? "",
//               };
//             }).toList();
//
//             conversations.sort((a, b) {
//               final tsA = a['timestamp'] ?? '';
//               final tsB = b['timestamp'] ?? '';
//               return tsB.compareTo(tsA);
//             });
//
//             return ListView.builder(
//               itemCount: conversations.length,
//               itemBuilder: (context, index) {
//                 final conversation = conversations[index];
//                 final conversationKey = conversation['conversationKey'];
//                 final coiffeuseId = conversationKey.split("_").last;
//
//                 return ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Colors.blueAccent,
//                     child: Icon(Icons.person, color: Colors.white),
//                   ),
//                   title: Text(
//                     coiffeuseId,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(conversation['lastMessage']),
//                   trailing: Text(
//                     conversation['timestamp']?.substring(0, 10) ?? "",
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChatPage(
//                           clientId: widget.clientId,
//                           coiffeuseId: coiffeuseId,
//                           coiffeuseName: "Coiffeuse $coiffeuseId",
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           }
//
//           return const Center(
//             child: Text("Aucune conversation."),
//           );
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




// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'chat_page.dart'; // Assurez-vous d'importer votre ChatPage ici
//
// class MessagesPage extends StatefulWidget {
//   final String clientId; // L'identifiant de l'utilisateur actuel
//
//   const MessagesPage({Key? key, required this.clientId}) : super(key: key);
//
//   @override
//   _MessagesPageState createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Chats"),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF6D20A5),
//       ),
//       body: StreamBuilder(
//         stream: databaseRef.onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 "Une erreur est survenue. Veuillez réessayer.",
//                 style: TextStyle(color: Colors.red),
//               ),
//             );
//           }
//
//           if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//             final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
//
//             if (data.isEmpty) {
//               return const Center(child: Text("Aucune conversation."));
//             }
//
//             final conversations = data.entries.where((entry) {
//               final messages = entry.value['messages'] as Map<dynamic, dynamic>?;
//               return messages != null && messages.isNotEmpty;
//             }).map((entry) {
//               final conversationKey = entry.key;
//               final messages = entry.value['messages'] as Map<dynamic, dynamic>;
//               final lastMessageKey = messages.keys.last;
//               final lastMessage = messages[lastMessageKey];
//
//               return {
//                 "conversationKey": conversationKey,
//                 "lastMessage": lastMessage?['text'] ?? "Pas de message.",
//                 "timestamp": lastMessage?['timestamp'] ?? "",
//               };
//             }).toList();
//
//             conversations.sort((a, b) {
//               final tsA = a['timestamp'] ?? '';
//               final tsB = b['timestamp'] ?? '';
//               return tsB.compareTo(tsA);
//             });
//
//             return ListView.builder(
//               itemCount: conversations.length,
//               itemBuilder: (context, index) {
//                 final conversation = conversations[index];
//                 final conversationKey = conversation['conversationKey'];
//                 final coiffeuseId = conversationKey.split("_").last;
//
//                 return ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Colors.blueAccent,
//                     child: Icon(Icons.person, color: Colors.white),
//                   ),
//                   title: Text(
//                     coiffeuseId,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(conversation['lastMessage']),
//                   trailing: Text(
//                     conversation['timestamp']?.substring(0, 10) ?? "",
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChatPage(
//                           clientId: widget.clientId,
//                           coiffeuseId: coiffeuseId,
//                           coiffeuseName: "Coiffeuse $coiffeuseId",
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           }
//
//           return const Center(
//             child: Text("Aucune conversation."),
//           );
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
// // import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'chat_page.dart'; // Assurez-vous d'importer votre ChatPage ici
// //
// // class MessagesPage extends StatefulWidget {
// //   final String clientId; // L'identifiant de l'utilisateur actuel
// //
// //   const MessagesPage({Key? key, required this.clientId}) : super(key: key);
// //
// //   @override
// //   _MessagesPageState createState() => _MessagesPageState();
// // }
// //
// // class _MessagesPageState extends State<MessagesPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Chats"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF6D20A5),
// //       ),
// //       body: StreamBuilder(
// //         stream: databaseRef.onValue, // Écoute tous les changements dans Firebase
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //
// //           if (snapshot.hasError) {
// //             return const Center(
// //               child: Text(
// //                 "Une erreur est survenue. Veuillez réessayer.",
// //                 style: TextStyle(color: Colors.red),
// //               ),
// //             );
// //           }
// //
// //           if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //             final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //
// //             // Filtre les conversations correspondant à l'utilisateur actuel
// //             final conversations = data.entries
// //                 .where((entry) => entry.key.startsWith(widget.clientId))
// //                 .map((entry) {
// //               final conversationKey = entry.key;
// //               final messages = entry.value['messages'] as Map<dynamic, dynamic>;
// //               final lastMessageKey = messages.keys.last;
// //               final lastMessage = messages[lastMessageKey];
// //
// //               return {
// //                 "conversationKey": conversationKey,
// //                 "lastMessage": lastMessage['text'],
// //                 "timestamp": lastMessage['timestamp'],
// //               };
// //             })
// //                 .toList();
// //
// //             conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp'])); // Trier par date
// //
// //             return ListView.builder(
// //               itemCount: conversations.length,
// //               itemBuilder: (context, index) {
// //                 final conversation = conversations[index];
// //                 final conversationKey = conversation['conversationKey'];
// //                 final coiffeuseId = conversationKey.split("_").last; // Récupère l'ID de la coiffeuse
// //
// //                 return ListTile(
// //                   leading: const CircleAvatar(
// //                     backgroundColor: Colors.blueAccent,
// //                     child: Icon(Icons.person, color: Colors.white),
// //                   ),
// //                   title: Text(
// //                     coiffeuseId,
// //                     style: const TextStyle(fontWeight: FontWeight.bold),
// //                   ),
// //                   subtitle: Text(conversation['lastMessage'] ?? "Pas de message."),
// //                   trailing: Text(
// //                     conversation['timestamp']?.substring(0, 10) ?? "",
// //                     style: const TextStyle(color: Colors.grey),
// //                   ),
// //                   onTap: () {
// //                     // Naviguer vers le chat de cette conversation
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (context) => ChatPage(
// //                           clientId: widget.clientId,
// //                           coiffeuseId: coiffeuseId,
// //                           coiffeuseName: "Coiffeuse $coiffeuseId", // Ajoutez une logique pour afficher le vrai nom si disponible
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 );
// //               },
// //             );
// //           }
// //
// //           return const Center(
// //             child: Text("Aucune conversation."),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
// //
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
// // import 'package:flutter/material.dart';
// //
// // class ChatsScreen extends StatelessWidget {
// //   const ChatsScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         centerTitle: false,
// //         elevation: 0,
// //         backgroundColor: const Color(0xFF6D20A5),
// //         foregroundColor: Colors.white,
// //         automaticallyImplyLeading: false,
// //         title: const Text("Chats"),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.search),
// //             onPressed: () {},
// //           ),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           Container(
// //             padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
// //             color: const Color(0xFF6D20A5),
// //             child: Row(
// //               children: [
// //                 FillOutlineButton(press: () {}, text: "Recent Message"),
// //                 const SizedBox(width: 16.0),
// //                 FillOutlineButton(
// //                   press: () {},
// //                   text: "Active",
// //                   isFilled: false,
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Expanded(
// //             child: ListView.builder(
// //               itemCount: chatsData.length,
// //               itemBuilder: (context, index) => ChatCard(
// //                 chat: chatsData[index],
// //                 press: () {},
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () {},
// //         backgroundColor: const Color(0xFF6D20A5),
// //         child: const Icon(
// //           Icons.person_add_alt_1,
// //           color: Colors.white,
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class ChatCard extends StatelessWidget {
// //   const ChatCard({
// //     super.key,
// //     required this.chat,
// //     required this.press,
// //   });
// //
// //   final Chat chat;
// //   final VoidCallback press;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return InkWell(
// //       onTap: press,
// //       child: Padding(
// //         padding:
// //         const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0 * 0.75),
// //         child: Row(
// //           children: [
// //             CircleAvatarWithActiveIndicator(
// //               image: chat.image,
// //               isActive: chat.isActive,
// //             ),
// //             Expanded(
// //               child: Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       chat.name,
// //                       style: const TextStyle(
// //                           fontSize: 16, fontWeight: FontWeight.w500),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Opacity(
// //                       opacity: 0.64,
// //                       child: Text(
// //                         chat.lastMessage,
// //                         maxLines: 1,
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             Opacity(
// //               opacity: 0.64,
// //               child: Text(chat.time),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class FillOutlineButton extends StatelessWidget {
// //   const FillOutlineButton({
// //     super.key,
// //     this.isFilled = true,
// //     required this.press,
// //     required this.text,
// //   });
// //
// //   final bool isFilled;
// //   final VoidCallback press;
// //   final String text;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialButton(
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(30),
// //         side: const BorderSide(color: Colors.white),
// //       ),
// //       elevation: isFilled ? 2 : 0,
// //       color: isFilled ? Colors.white : Colors.transparent,
// //       onPressed: press,
// //       child: Text(
// //         text,
// //         style: TextStyle(
// //           color: isFilled ? const Color(0xFF1D1D35) : Colors.white,
// //           fontSize: 12,
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class CircleAvatarWithActiveIndicator extends StatelessWidget {
// //   const CircleAvatarWithActiveIndicator({
// //     super.key,
// //     this.image,
// //     this.radius = 24,
// //     this.isActive,
// //   });
// //
// //   final String? image;
// //   final double? radius;
// //   final bool? isActive;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Stack(
// //       children: [
// //         CircleAvatar(
// //           radius: radius,
// //           backgroundImage: NetworkImage(image!),
// //         ),
// //         if (isActive!)
// //           Positioned(
// //             right: 0,
// //             bottom: 0,
// //             child: Container(
// //               height: 16,
// //               width: 16,
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFF6D20A5),
// //                 shape: BoxShape.circle,
// //                 border: Border.all(
// //                     color: Theme.of(context).scaffoldBackgroundColor, width: 3),
// //               ),
// //             ),
// //           )
// //       ],
// //     );
// //   }
// // }
// //
// // class Chat {
// //   final String name, lastMessage, image, time;
// //   final bool isActive;
// //
// //   Chat({
// //     this.name = '',
// //     this.lastMessage = '',
// //     this.image = '',
// //     this.time = '',
// //     this.isActive = false,
// //   });
// // }
// //
// // List chatsData = [
// //   Chat(
// //     name: "Jenny Wilson",
// //     lastMessage: "Hope you are doing well...",
// //     image: "https://i.postimg.cc/g25VYN7X/user-1.png",
// //     time: "3m ago",
// //     isActive: false,
// //   ),
// //   Chat(
// //     name: "Esther Howard",
// //     lastMessage: "Hello Abdullah! I am...",
// //     image: "https://i.postimg.cc/cCsYDjvj/user-2.png",
// //     time: "8m ago",
// //     isActive: true,
// //   ),
// //   Chat(
// //     name: "Ralph Edwards",
// //     lastMessage: "Do you have update...",
// //     image: "https://i.postimg.cc/sXC5W1s3/user-3.png",
// //     time: "5d ago",
// //     isActive: false,
// //   ),
// //   Chat(
// //     name: "Jacob Jones",
// //     lastMessage: "You’re welcome :)",
// //     image: "https://i.postimg.cc/4dvVQZxV/user-4.png",
// //     time: "5d ago",
// //     isActive: true,
// //   ),
// //   Chat(
// //     name: "Albert Flores",
// //     lastMessage: "Thanks",
// //     image: "https://i.postimg.cc/FzDSwZcK/user-5.png",
// //     time: "6d ago",
// //     isActive: false,
// //   ),
// //   Chat(
// //     name: "Jenny Wilson",
// //     lastMessage: "Hope you are doing well...",
// //     image: "https://i.postimg.cc/g25VYN7X/user-1.png",
// //     time: "3m ago",
// //     isActive: false,
// //   ),
// //   Chat(
// //     name: "Esther Howard",
// //     lastMessage: "Hello Abdullah! I am...",
// //     image: "https://i.postimg.cc/cCsYDjvj/user-2.png",
// //     time: "8m ago",
// //     isActive: true,
// //   ),
// //   Chat(
// //     name: "Ralph Edwards",
// //     lastMessage: "Do you have update...",
// //     image: "https://i.postimg.cc/sXC5W1s3/user-3.png",
// //     time: "5d ago",
// //     isActive: false,
// //   ),
// // ];
