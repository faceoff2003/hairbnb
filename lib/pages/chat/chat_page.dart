import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/services/providers/user_service.dart';
import 'package:hairbnb/widgets/custom_app_bar.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/models/message.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import '../../services/my_drawer_service/my_drawer.dart';
import 'package:intl/intl.dart';

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
  late String baseUrl = "https://www.hairbnb.site/";

  @override
  void initState() {
    super.initState();
    chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
        ? "${widget.currentUser.uuid}_${widget.otherUserId}"
        : "${widget.otherUserId}_${widget.currentUser.uuid}";
    _fetchOtherUser();
  }

  Future<void> _fetchOtherUser() async {
    final user = await fetchOtherUser(widget.otherUserId);
    setState(() {
      otherUser = user;
    });
  }

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
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: otherUser != null && otherUser!.photoProfil != null
                      ? NetworkImage(baseUrl + otherUser!.photoProfil.toString())
                      : AssetImage("assets/logo_login/avatar.png") as ImageProvider,
                  radius: 25,
                ),
                SizedBox(width: 10),
                otherUser != null
                    ? Text(
                  "${otherUser!.prenom} ${otherUser!.nom}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
                    : CircularProgressIndicator(),
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
        currentIndex: 3, // 👈 Correspond à l'onglet "Messages"
        onTap: (index) {
          // rien ici, le contrôle se fait dans le widget lui-même
        },
      ),
    );
  }
}