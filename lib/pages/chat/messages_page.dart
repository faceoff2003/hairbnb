import 'dart:convert';
import 'package:flutter/material.dart';
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

      final coiffeuseUuids = _conversations.map<String>((c) => c['otherUserId'] as String).toList();
      _cachedMinimalCoiffeuses = await _fetchMinimalCoiffeusesFromApi(coiffeuseUuids);
      setState(() {});
    });
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
      print("Erreur API : $e");
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Plus besoin de récupérer currentUser ici, c'est géré dans HairbnbScaffold

    return HairbnbScaffold(
      body: _conversations.isEmpty
          ? const Center(child: Text("Aucune conversation."))
          : ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final otherUserId = conversation['otherUserId'];

          final coiffeuse = _cachedMinimalCoiffeuses.firstWhere(
                (c) => c.uuid == otherUserId,
            orElse: () => MinimalCoiffeuse(
              uuid: otherUserId,
              idTblUser: 0,
              nom: "",
              prenom: "",
              photoProfil: '',
              //position: '',
            ),
          );

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              backgroundImage: coiffeuse.photoProfil != null && coiffeuse.photoProfil!.isNotEmpty
                  ? NetworkImage(baseUrl + coiffeuse.photoProfil!)
                  : null,
              child: coiffeuse.photoProfil == null || coiffeuse.photoProfil!.isEmpty
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
              // Nous avons toujours besoin du currentUser ici, mais nous le récupérons du Provider
              final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    currentUser: currentUser!,
                    otherUserId: coiffeuse.uuid,
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // 👈 Onglet "Messages"
        onTap: (index) {
          // Navigation gérée dans le BottomNavBar lui-même
        },
      ),
    );
  }
}