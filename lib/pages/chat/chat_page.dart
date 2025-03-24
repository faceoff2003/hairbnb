import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/services/providers/user_service.dart';
import 'package:hairbnb/widgets/Custom_app_bar.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/models/message.dart';
import 'package:intl/intl.dart';

import 'chat_services/my_drawer_service.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart'; // 👈 Assure-toi que le chemin est correct

class ChatPage extends StatefulWidget {
  final CurrentUser currentUser;
  final String otherUserId;

  ChatPage({
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
                  child: const Icon(Icons.send),
                  mini: true,
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








// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/user_service.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/models/message.dart';
// import 'package:intl/intl.dart';
//
// import 'chat_services/my_drawer_service.dart';
//
// class ChatPage extends StatefulWidget {
//   final CurrentUser currentUser;
//   final String otherUserId;
//
//   ChatPage({
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
//   late String baseUrl = "https://www.hairbnb.site/";
//
//   @override
//   void initState() {
//     super.initState();
//     chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
//         ? "${widget.currentUser.uuid}_${widget.otherUserId}"
//         : "${widget.otherUserId}_${widget.currentUser.uuid}";
//     _fetchOtherUser();
//   }
//
//   Future<void> _fetchOtherUser() async {
//     final user = await fetchOtherUser(widget.otherUserId);
//     setState(() {
//       otherUser = user;
//     });
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       drawer: MyDrawer(currentUser: widget.currentUser), // 🧩 Sidebar ajoutée
//       body: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(10),
//             color: Colors.grey.shade200,
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.blueAccent,
//                   backgroundImage: otherUser != null && otherUser!.photoProfil != null
//                       ? NetworkImage(baseUrl + otherUser!.photoProfil.toString())
//                       : AssetImage("assets/logo_login/avatar.png") as ImageProvider,
//                   radius: 25,
//                 ),
//                 SizedBox(width: 10),
//                 otherUser != null
//                     ? Text(
//                   "${otherUser!.prenom} ${otherUser!.nom}",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 )
//                     : CircularProgressIndicator(),
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
//                   child: const Icon(Icons.send),
//                   mini: true,
//                 ),
//               ],
//             ),
//           ),
//         ],
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
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/services/providers/user_service.dart';
// // import 'package:hairbnb/widgets/Custom_app_bar.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:hairbnb/models/message.dart';
// // import 'package:intl/intl.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   //final String clientId; // ID de l'utilisateur actuel
// //   final CurrentUser currentUser;
// //   final String otherUserId;
// //
// //   ChatPage({
// //     //required this.clientId,
// //     required this.otherUserId, required this.currentUser,
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
// //   CurrentUser? otherUser; // 🔥 Stocke les infos de l'autre utilisateur
// //   late String baseUrl = "https://www.hairbnb.site/";
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
// //         ? "${widget.currentUser.uuid}_${widget.otherUserId}"
// //         : "${widget.otherUserId}_${widget.currentUser.uuid}";
// //
// //     // 🔥 Charger les infos de l'autre utilisateur
// //     _fetchOtherUser();
// //   }
// //
// //   Future<void> _fetchOtherUser() async {
// //     final user = await fetchOtherUser(widget.otherUserId);
// //     setState(() {
// //       otherUser = user;
// //     });
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text
// //         .trim()
// //         .isEmpty) return;
// //
// //     Message newMessage = Message(
// //       senderId: widget.currentUser.uuid,
// //       receiverId: widget.otherUserId,
// //       text: text.trim(),
// //       timestamp: DateTime.now(),
// //       isRead: false,
// //     );
// //
// //     await databaseRef.child(chatId).child("messages").push().set(
// //         newMessage.toJson());
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
// //       body: Column(
// //         children: [
// //           // 🔥 Barre sous l'AppBar avec nom, prénom et photo de l'utilisateur
// //           Container(
// //             width: double.infinity,
// //             padding: EdgeInsets.all(10),
// //             color: Colors.grey.shade200,
// //             child: Row(
// //               children: [
// //                 CircleAvatar(
// //                   backgroundColor: Colors.blueAccent,
// //                   backgroundImage: otherUser != null &&
// //                       otherUser!.photoProfil != null
// //                       ? NetworkImage(
// //                       baseUrl + otherUser!.photoProfil.toString())
// //                       : AssetImage("logo_login/avatar.png"),
// //                   radius: 25,
// //                 ),
// //                 SizedBox(width: 10),
// //                 otherUser != null
// //                     ? Text(
// //                   "${otherUser!.prenom} ${otherUser!.nom}",
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                 )
// //                     : CircularProgressIndicator(),
// //               ],
// //             ),
// //           ),
// //
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef
// //                   .child(chatId)
// //                   .child("messages")
// //                   .onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }
// //
// //                 if (snapshot.hasError) {
// //                   return const Center(
// //                       child: Text("Erreur de chargement des messages."));
// //                 }
// //
// //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //                   final data = snapshot.data!.snapshot.value as Map<
// //                       dynamic,
// //                       dynamic>;
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
// //                         padding: const EdgeInsets.symmetric(
// //                             vertical: 4, horizontal: 8),
// //                         child: Align(
// //                           alignment: isSender
// //                               ? Alignment.centerRight
// //                               : Alignment.centerLeft,
// //                           child: Container(
// //                             constraints: BoxConstraints(
// //                               maxWidth: MediaQuery
// //                                   .of(context)
// //                                   .size
// //                                   .width * 0.7,
// //                             ),
// //                             padding: const EdgeInsets.all(10),
// //                             decoration: BoxDecoration(
// //                               color: isSender ? Colors.blueAccent : Colors.grey
// //                                   .shade300,
// //                               borderRadius: BorderRadius.only(
// //                                 topLeft: const Radius.circular(10),
// //                                 topRight: const Radius.circular(10),
// //                                 bottomLeft: isSender
// //                                     ? const Radius.circular(10)
// //                                     : Radius.zero,
// //                                 bottomRight: isSender
// //                                     ? Radius.zero
// //                                     : const Radius.circular(10),
// //                               ),
// //                             ),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   msg.text,
// //                                   style: TextStyle(
// //                                       color: isSender ? Colors.white : Colors
// //                                           .black),
// //                                 ),
// //                                 const SizedBox(height: 5),
// //                                 Align(
// //                                   alignment: Alignment.bottomRight,
// //                                   child: Text(
// //                                     DateFormat('dd/MM/yyyy HH:mm').format(
// //                                         msg.timestamp.toUtc()),
// //                                     style: const TextStyle(
// //                                         fontSize: 10, color: Colors.grey),
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
// //
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
// //                       contentPadding: const EdgeInsets.symmetric(
// //                           horizontal: 10, vertical: 10),
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
// //----------------------------code fonctionel refactoriser en parti-----------------------------
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/widgets/Custom_app_bar.dart';
// // import 'package:hairbnb/services/providers/user_by_uuid_provider.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:intl/intl.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId; // ID de l'utilisateur actuel
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId, required this.coiffeuseName,
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
// //   CurrentUser? otherUser; // 🔥 Stocker les infos de otherUser
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     chatId = widget.clientId.compareTo(widget.coiffeuseId) < 0
// //         ? "${widget.clientId}_${widget.coiffeuseId}"
// //         : "${widget.coiffeuseId}_${widget.clientId}";
// //
// //     // 🔥 Charger les infos de l'autre utilisateur
// //     _fetchOtherUser();
// //   }
// //
// //   Future<void> _fetchOtherUser() async {
// //     final user = await fetchOtherUser(widget.coiffeuseId);
// //     setState(() {
// //       otherUser = user;
// //     });
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "senderId": widget.clientId,
// //       "receiverId": widget.coiffeuseId,
// //       "timestamp": ServerValue.timestamp,
// //       "text": text.trim(),
// //       "read": false,
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
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
// //       body: Column(
// //         children: [
// //           // 🔥 Barre sous l'AppBar avec le nom & prénom
// //           Container(
// //             width: double.infinity,
// //             padding: EdgeInsets.all(10),
// //             color: Colors.grey.shade200,
// //             child: Center(
// //               child: otherUser != null
// //                   ? Text(
// //                 "${otherUser!.prenom} ${otherUser!.nom}",
// //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //               )
// //                   : CircularProgressIndicator(), // 🔄 Chargement
// //             ),
// //           ),
// //
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
// //                   List<Map<dynamic, dynamic>> messages = data.entries.map((entry) {
// //                     final message = entry.value as Map<dynamic, dynamic>;
// //
// //                     if (message.containsKey('timestamp')) {
// //                       if (message['timestamp'] is int) {
// //                         message['timestamp'] = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
// //                       } else if (message['timestamp'] is String) {
// //                         message['timestamp'] = DateTime.parse(message['timestamp']).toUtc();
// //                       }
// //                     } else {
// //                       message['timestamp'] = DateTime.now().toUtc();
// //                     }
// //                     return message;
// //                   }).toList();
// //
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
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
// //                       bool isSender = msg['senderId'] == widget.clientId;
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
// //                                   msg['text'] ?? '',
// //                                   style: TextStyle(color: isSender ? Colors.white : Colors.black),
// //                                 ),
// //                                 const SizedBox(height: 5),
// //                                 Align(
// //                                   alignment: Alignment.bottomRight,
// //                                   child: Text(
// //                                     DateFormat('dd/MM/yyyy HH:mm').format(msg['timestamp'].toUtc()),
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
// //
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
// //-----------------------------------Code fonctionel a 100% il faut de refactoring------------------------------------
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/widgets/Custom_app_bar.dart';
// // import 'package:intl/intl.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId; // ID de l'utilisateur actuel
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //   final ScrollController _scrollController = ScrollController(); // 🔥 Ajout du ScrollController
// //   final FocusNode _focusNode = FocusNode(); // 🔥 FocusNode pour détecter clavier
// //   late String chatId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Générer un ID de conversation unique basé sur l'ordre alphabétique des UUID
// //     chatId = widget.clientId.compareTo(widget.coiffeuseId) < 0
// //         ? "${widget.clientId}_${widget.coiffeuseId}"
// //         : "${widget.coiffeuseId}_${widget.clientId}";
// //
// //     // 🔥 Défilement automatique dès l'ouverture de la page
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //     _scrollToBottom();
// //     });
// //
// //     // 🔥 Ajouter un listener pour détecter l'ouverture du clavier et scroller en bas
// //     _focusNode.addListener(() {
// //       if (_focusNode.hasFocus) {
// //         Future.delayed(Duration(milliseconds: 300), () {
// //           _scrollToBottom();
// //         });
// //       }
// //     });
// //
// //   }
// //
// //
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "senderId": widget.clientId,
// //       "receiverId": widget.coiffeuseId,
// //       "timestamp": ServerValue.timestamp, // Utilisation de l'heure Firebase
// //       "text": text.trim(),
// //       "read": false,
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //
// //     // 🔥 Scroll automatique après envoi
// //     Future.delayed(Duration(milliseconds: 300), () {
// //       _scrollToBottom();
// //     });
// //
// //     // 🔥 Faire défiler automatiquement vers le bas après l'envoi d'un message
// //     Future.delayed(Duration(milliseconds: 300), () {
// //       _scrollController.animateTo(
// //         _scrollController.position.maxScrollExtent,
// //         duration: Duration(milliseconds: 300),
// //         curve: Curves.easeOut,
// //       );
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
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef.child(chatId).child("messages").onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }
// //
// //                 if (snapshot.hasError) {
// //                   return const Center(
// //                       child: Text("Erreur de chargement des messages."));
// //                 }
// //
// //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //                   final data =
// //                   snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //
// //                   // Convertir et trier les messages
// //                   List<Map<dynamic, dynamic>> messages = data.entries.map((entry) {
// //                     final message = entry.value as Map<dynamic, dynamic>;
// //
// //                     // Convertir le timestamp Firebase en DateTime
// //                     if (message.containsKey('timestamp')) {
// //                       if (message['timestamp'] is int) {
// //                         message['timestamp'] = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
// //                       } else if (message['timestamp'] is String) {
// //                         message['timestamp'] = DateTime.parse(message['timestamp']).toUtc();
// //                       }
// //                     } else {
// //                       message['timestamp'] = DateTime.now().toUtc(); // Sécurité en cas de problème
// //                     }
// //                     return message;
// //                   }).toList();
// //
// //
// //                   // Trier les messages par ordre chronologique
// //                   messages
// //                       .sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
// //
// //                   // 🔥 Défilement automatique après le chargement des messages
// //                   Future.delayed(Duration(milliseconds: 300), () {
// //                     _scrollToBottom();
// //                   });
// //
// //                   return ListView.builder(
// //                     controller: _scrollController,  // 🔥 Ajout du controller ici
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       bool isSender = msg['senderId'] == widget.clientId;
// //
// //                       return Padding(
// //                         padding: const EdgeInsets.symmetric(
// //                             vertical: 4, horizontal: 8),
// //                         child: Align(
// //                           alignment: isSender
// //                               ? Alignment.centerRight
// //                               : Alignment.centerLeft,
// //                           child: Container(
// //                             constraints: BoxConstraints(
// //                               maxWidth:
// //                               MediaQuery.of(context).size.width * 0.7,
// //                             ),
// //                             padding: const EdgeInsets.all(10),
// //                             decoration: BoxDecoration(
// //                               color: isSender
// //                                   ? Colors.blueAccent
// //                                   : Colors.grey.shade300,
// //                               borderRadius: BorderRadius.only(
// //                                 topLeft: const Radius.circular(10),
// //                                 topRight: const Radius.circular(10),
// //                                 bottomLeft: isSender
// //                                     ? const Radius.circular(10)
// //                                     : Radius.zero,
// //                                 bottomRight: isSender
// //                                     ? Radius.zero
// //                                     : const Radius.circular(10),
// //                               ),
// //                             ),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   msg['text'] ?? '',
// //                                   style: TextStyle(
// //                                     color: isSender
// //                                         ? Colors.white
// //                                         : Colors.black,
// //                                   ),
// //                                 ),
// //                                 const SizedBox(height: 5),
// //                                 Align(
// //                                   alignment: Alignment.bottomRight,
// //                                   child: Text(
// //                                     DateFormat('dd/MM/yyyy HH:mm').format(
// //                                       msg['timestamp'].toUtc(), // Convertir en UTC avant d'afficher
// //                                     ),
// //                                     style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                                   ),
// //
// //
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
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
// //                     focusNode: _focusNode, // 🔥 Ajout du focusNode pour détecter l'ouverture du clavier
// //                     onSubmitted: (text) {
// //                       sendMessage(text); // 🔥 Envoie le message quand on appuie sur Entrée
// //                     },
// //                     decoration: InputDecoration(
// //                       hintText: "Écrire un message",
// //                       filled: true,
// //                       fillColor: Colors.grey.shade200,
// //                       contentPadding: const EdgeInsets.symmetric(
// //                           horizontal: 10, vertical: 10),
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// //
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
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// //
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId; // ID de l'utilisateur actuel
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //   late String chatId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Générer un ID de conversation unique basé sur l'ordre alphabétique des UUID
// //     chatId = widget.clientId.compareTo(widget.coiffeuseId) < 0
// //         ? "${widget.clientId}_${widget.coiffeuseId}"
// //         : "${widget.coiffeuseId}_${widget.clientId}";
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "senderId": widget.clientId,
// //       "receiverId": widget.coiffeuseId,
// //       "timestamp": DateTime.now().toUtc().toIso8601String(),
// //       "text": text.trim(),
// //       "read": false,
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
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
// //
// //                   // Convertir et trier les messages
// //                   List<Map<dynamic, dynamic>> messages = data.entries.map((entry) {
// //                     final message = entry.value as Map<dynamic, dynamic>;
// //
// //                     // Vérifier si le timestamp est bien un String avant de le parser
// //                     if (message.containsKey('timestamp') && message['timestamp'] is String) {
// //                       message['timestamp'] = DateTime.parse(message['timestamp']).toUtc();
// //                     } else {
// //                       message['timestamp'] = DateTime.now().toUtc(); // Fallback en cas d'erreur
// //                     }
// //                     return message;
// //                   }).toList();
// //
// //                   // Trier les messages par ordre chronologique
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //
// //                       bool isSender = msg['senderId'] == widget.clientId;
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 DateFormat('dd/MM/yyyy HH:mm').format(
// //                                   msg['timestamp'].toLocal(), // Convertir en heure locale
// //                                 ),
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
// //                 return const Center(child: Text("Aucun message."));
// //               },
// //             ),
// //
// //           ),
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _messageController,
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   /// Fonction pour formater le timestamp en une chaîne lisible
// //   String _formatTimestamp(String? timestamp) {
// //     if (timestamp == null) return "";
// //     final dateTime = DateTime.parse(timestamp);
// //     return "${dateTime.hour}:${dateTime.minute}";
// //   }
// // }
//
//
//
// //-----------------------------Fonctionel mais il affiche pas les msg en ordre chronologiik-----------------------------
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId; // ID de l'utilisateur actuel
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //   late String chatId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Générer un ID de conversation unique basé sur l'ordre alphabétique des UUID
// //     chatId = widget.clientId.compareTo(widget.coiffeuseId) < 0
// //         ? "${widget.clientId}_${widget.coiffeuseId}"
// //         : "${widget.coiffeuseId}_${widget.clientId}";
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "senderId": widget.clientId,
// //       "receiverId": widget.coiffeuseId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text.trim(),
// //       "read": false,
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef.child(chatId).child("messages").onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }
// //
// //                 if (snapshot.hasError) {
// //                   return const Center(
// //                     child: Text("Erreur de chargement des messages."),
// //                   );
// //                 }
// //
// //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //                   final messages = data.entries
// //                       .map((entry) => entry.value as Map<dynamic, dynamic>)
// //                       .toList();
// //
// //                   // Trier les messages par ordre chronologique
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       final isSender = msg['senderId'] == widget.clientId; // Vérifie l'expéditeur
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 msg['timestamp'] ?? '',
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
// //                 return const Center(
// //                   child: Text("Aucun message."),
// //                 );
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
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
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId; // ID de l'utilisateur actuel
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //   late String chatId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Générer un ID de conversation unique basé sur l'ordre alphabétique des UUID
// //     chatId = widget.clientId.compareTo(widget.coiffeuseId) < 0
// //         ? "${widget.clientId}_${widget.coiffeuseId}"
// //         : "${widget.coiffeuseId}_${widget.clientId}";
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "senderId": widget.clientId,
// //       "receiverId": widget.coiffeuseId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text.trim(),
// //       "read": false,
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef.child(chatId).child("messages").onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }
// //
// //                 if (snapshot.hasError) {
// //                   return const Center(
// //                     child: Text("Erreur de chargement des messages."),
// //                   );
// //                 }
// //
// //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //                   final messages = data.entries
// //                       .map((entry) => entry.value as Map<dynamic, dynamic>)
// //                       .toList();
// //
// //                   // Trier les messages par ordre chronologique
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       final isSender = msg['senderId'] == widget.clientId; // Vérifie l'expéditeur
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 msg['timestamp'] ?? '',
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
// //                 return const Center(
// //                   child: Text("Aucun message."),
// //                 );
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
//
//
// //----------------------Code fonctionnelle mais il fau amilliorer l'affichage des msg----------------------------------
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId; // Ensure consistency
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //
// //   late String chatId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     //chatId = "${widget.clientId}_${widget.coiffeuseId}";
// //
// //     chatId = widget.clientId.compareTo(widget.coiffeuseId) < 0
// //         ? "${widget.clientId}_${widget.coiffeuseId}"
// //         : "${widget.coiffeuseId}_${widget.clientId}";
// //
// //
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "senderId": widget.clientId,
// //       "receiverId": widget.coiffeuseId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text.trim(),
// //       "read": false,
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //
// //   // void sendMessage(String text) async {
// //   //   if (text.trim().isEmpty) return;
// //   //
// //   //   final message = {
// //   //     "sender": widget.clientId,
// //   //     "coiffeuseUuid": widget.coiffeuseId,
// //   //     "timestamp": DateTime.now().toIso8601String(),
// //   //     "text": text.trim(),
// //   //     "read": false,
// //   //   };
// //   //
// //   //   await databaseRef.child(chatId).child("messages").push().set(message);
// //   //   _messageController.clear();
// //   // }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
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
// //                   final messages = data.entries
// //                       .map((entry) => entry.value as Map<dynamic, dynamic>)
// //                       .toList();
// //
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       final isSender = msg['sender'] == widget.clientId;
// //
// //                       //---------------------------------------------------------------
// //                       print('le client id est '+ widget.clientId);
// //                       print('le coiffeuse id est '+ widget.coiffeuseId);
// //                       //----------------------------------------------------------------
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 msg['timestamp'] ?? '',
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId; // L'identifiant unique de l'utilisateur
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //
// //   late String chatId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     chatId = "currentUserUuid_${widget.coiffeuseId}";
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "sender": widget.clientId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text.trim(),
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
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
// //                   final messages = data.entries
// //                       .map((entry) => entry.value as Map<dynamic, dynamic>)
// //                       .toList();
// //
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       final isSender = msg['sender'] == widget.clientId;
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 msg['timestamp'] ?? '',
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
//
//
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId;
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //
// //   late String chatId; // Identifiant unique pour cette conversation
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Génère un chatId unique en utilisant une convention unifiée
// //     chatId = "currentUserUuid_${widget.coiffeuseId}";
// //   }
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final message = {
// //       "sender": widget.clientId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text.trim(),
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef.child(chatId).child("messages").onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }
// //
// //                 if (snapshot.hasError) {
// //                   return const Center(
// //                       child: Text("Erreur de chargement des messages."));
// //                 }
// //
// //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //                   final messages = data.entries
// //                       .map((entry) => entry.value as Map<dynamic, dynamic>)
// //                       .toList();
// //
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       final isSender = msg['sender'] == widget.clientId;
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 msg['timestamp'] ?? '',
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
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
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId;
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //
// //   void sendMessage(String text) async {
// //     if (text.trim().isEmpty) return;
// //
// //     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
// //     final message = {
// //       "sender": widget.clientId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text.trim(),
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
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
// //                   final messages = data.entries
// //                       .map((entry) => entry.value as Map<dynamic, dynamic>)
// //                       .toList();
// //
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp'])); // Trier par date
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       final isSender = msg['sender'] == widget.clientId;
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 msg['timestamp'] ?? '',
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
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
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId;
// //   final String coiffeuseId;
// //   final String coiffeuseName;
// //
// //   ChatPage({
// //     required this.clientId,
// //     required this.coiffeuseId,
// //     required this.coiffeuseName,
// //   });
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //
// //   void sendMessage(String text) async {
// //     if (text
// //         .trim()
// //         .isEmpty) return;
// //
// //     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
// //     final message = {
// //       "sender": widget.clientId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text.trim(),
// //     };
// //
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final chatId = "${widget.clientId}_${widget
// //         .coiffeuseId}"; // La clé utilisée pour les messages
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.coiffeuseName),
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef.child("${widget.clientId}_${widget.coiffeuseId}/messages").onValue,
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
// //                   final messages = data.entries.map((e) => e.value).toList();
// //
// //                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp'])); // Trier par date
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index];
// //                       final isSender = msg['sender'] == widget.clientId;
// //
// //                       return Align(
// //                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
// //                         child: Container(
// //                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //                           padding: const EdgeInsets.all(10),
// //                           decoration: BoxDecoration(
// //                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 msg['text'] ?? '',
// //                                 style: TextStyle(
// //                                   color: isSender ? Colors.white : Colors.black,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 msg['timestamp'] ?? '',
// //                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //
// //                 return const Center(child: Text("Aucun message."));
// //               },
// //             )
// //           ),
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _messageController,
// //                     decoration: InputDecoration(
// //                       hintText: "Écrire un message",
// //                       filled: true,
// //                       fillColor: Colors.grey.shade200,
// //                       contentPadding: const EdgeInsets.symmetric(
// //                           horizontal: 10, vertical: 10),
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
// //                   child: const Icon(Icons.send),
// //                   mini: true,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
//
//
//
//
//
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String clientId;
// //   final String coiffeuseId;
// //
// //   ChatPage({required this.clientId, required this.coiffeuseId});
// //
// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   //final databaseRef = FirebaseDatabase.instance.ref("chats");
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   final TextEditingController _messageController = TextEditingController();
// //
// //   void sendMessage(String text) async {
// //     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
// //     final message = {
// //       "sender": widget.clientId,
// //       "timestamp": DateTime.now().toIso8601String(),
// //       "text": text,
// //     };
// //     await databaseRef.child(chatId).child("messages").push().set(message);
// //     _messageController.clear();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text("Chat avec la coiffeuse"),
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: databaseRef
// //                   .child("${widget.clientId}_${widget.coiffeuseId}/messages")
// //                   .onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
// //                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //                   final messages = data.entries.map((e) => e.value).toList();
// //
// //                   return ListView.builder(
// //                     itemCount: messages.length,
// //                     itemBuilder: (context, index) {
// //                       final msg = messages[index] as Map<dynamic, dynamic>;
// //                       return ListTile(
// //                         title: Text(msg['text'] ?? ''),
// //                         subtitle: Text(msg['timestamp'] ?? ''),
// //                         trailing: Text(
// //                           msg['sender'] == widget.clientId ? "Vous" : "Coiffeuse",
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 }
// //                 return const Center(
// //                   child: Text("Aucun message pour l'instant."),
// //                 );
// //               },
// //             )
// //           ),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: TextField(
// //                   controller: _messageController,
// //                   decoration: InputDecoration(hintText: "Écrire un message"),
// //                 ),
// //               ),
// //               IconButton(
// //                 icon: Icon(Icons.send),
// //                 onPressed: () {
// //                   sendMessage(_messageController.text);
// //                 },
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
