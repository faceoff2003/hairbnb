import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String clientId; // Ensure consistency
  final String coiffeuseId;
  final String coiffeuseName;

  ChatPage({
    required this.clientId,
    required this.coiffeuseId,
    required this.coiffeuseName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final databaseRef = FirebaseDatabase.instance.ref();
  final TextEditingController _messageController = TextEditingController();

  late String chatId;

  @override
  void initState() {
    super.initState();
    chatId = "${widget.clientId}_${widget.coiffeuseId}";

  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final message = {
      "sender": widget.clientId,
      "coiffeuseUuid": widget.coiffeuseId,
      "timestamp": DateTime.now().toIso8601String(),
      "text": text.trim(),
      "read": false,
    };

    await databaseRef.child(chatId).child("messages").push().set(message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coiffeuseName),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                  final messages = data.entries
                      .map((entry) => entry.value as Map<dynamic, dynamic>)
                      .toList();

                  messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isSender = msg['sender'] == widget.clientId;

                      //---------------------------------------------------------------
                      print('le client id est '+ widget.clientId);
                      print('le coiffeuse id est '+ widget.coiffeuseId);
                      //----------------------------------------------------------------

                      return Align(
                        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSender ? Colors.blueAccent : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  color: isSender ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                msg['timestamp'] ?? '',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
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
    );
  }
}






// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// class ChatPage extends StatefulWidget {
//   final String clientId; // L'identifiant unique de l'utilisateur
//   final String coiffeuseId;
//   final String coiffeuseName;
//
//   ChatPage({
//     required this.clientId,
//     required this.coiffeuseId,
//     required this.coiffeuseName,
//   });
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _messageController = TextEditingController();
//
//   late String chatId;
//
//   @override
//   void initState() {
//     super.initState();
//     chatId = "currentUserUuid_${widget.coiffeuseId}";
//   }
//
//   void sendMessage(String text) async {
//     if (text.trim().isEmpty) return;
//
//     final message = {
//       "sender": widget.clientId,
//       "timestamp": DateTime.now().toIso8601String(),
//       "text": text.trim(),
//     };
//
//     await databaseRef.child(chatId).child("messages").push().set(message);
//     _messageController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.coiffeuseName),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
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
//                   final messages = data.entries
//                       .map((entry) => entry.value as Map<dynamic, dynamic>)
//                       .toList();
//
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = messages[index];
//                       final isSender = msg['sender'] == widget.clientId;
//
//                       return Align(
//                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 msg['text'] ?? '',
//                                 style: TextStyle(
//                                   color: isSender ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 msg['timestamp'] ?? '',
//                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 }
//
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




// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// class ChatPage extends StatefulWidget {
//   final String clientId;
//   final String coiffeuseId;
//   final String coiffeuseName;
//
//   ChatPage({
//     required this.clientId,
//     required this.coiffeuseId,
//     required this.coiffeuseName,
//   });
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _messageController = TextEditingController();
//
//   late String chatId; // Identifiant unique pour cette conversation
//
//   @override
//   void initState() {
//     super.initState();
//     // Génère un chatId unique en utilisant une convention unifiée
//     chatId = "currentUserUuid_${widget.coiffeuseId}";
//   }
//
//   void sendMessage(String text) async {
//     if (text.trim().isEmpty) return;
//
//     final message = {
//       "sender": widget.clientId,
//       "timestamp": DateTime.now().toIso8601String(),
//       "text": text.trim(),
//     };
//
//     await databaseRef.child(chatId).child("messages").push().set(message);
//     _messageController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.coiffeuseName),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder(
//               stream: databaseRef.child(chatId).child("messages").onValue,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (snapshot.hasError) {
//                   return const Center(
//                       child: Text("Erreur de chargement des messages."));
//                 }
//
//                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   final messages = data.entries
//                       .map((entry) => entry.value as Map<dynamic, dynamic>)
//                       .toList();
//
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = messages[index];
//                       final isSender = msg['sender'] == widget.clientId;
//
//                       return Align(
//                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 msg['text'] ?? '',
//                                 style: TextStyle(
//                                   color: isSender ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 msg['timestamp'] ?? '',
//                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 }
//
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










// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// class ChatPage extends StatefulWidget {
//   final String clientId;
//   final String coiffeuseId;
//   final String coiffeuseName;
//
//   ChatPage({
//     required this.clientId,
//     required this.coiffeuseId,
//     required this.coiffeuseName,
//   });
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _messageController = TextEditingController();
//
//   void sendMessage(String text) async {
//     if (text.trim().isEmpty) return;
//
//     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
//     final message = {
//       "sender": widget.clientId,
//       "timestamp": DateTime.now().toIso8601String(),
//       "text": text.trim(),
//     };
//
//     await databaseRef.child(chatId).child("messages").push().set(message);
//     _messageController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.coiffeuseName),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
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
//                   final messages = data.entries
//                       .map((entry) => entry.value as Map<dynamic, dynamic>)
//                       .toList();
//
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp'])); // Trier par date
//
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = messages[index];
//                       final isSender = msg['sender'] == widget.clientId;
//
//                       return Align(
//                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 msg['text'] ?? '',
//                                 style: TextStyle(
//                                   color: isSender ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 msg['timestamp'] ?? '',
//                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 }
//
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










// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// class ChatPage extends StatefulWidget {
//   final String clientId;
//   final String coiffeuseId;
//   final String coiffeuseName;
//
//   ChatPage({
//     required this.clientId,
//     required this.coiffeuseId,
//     required this.coiffeuseName,
//   });
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _messageController = TextEditingController();
//
//   void sendMessage(String text) async {
//     if (text
//         .trim()
//         .isEmpty) return;
//
//     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
//     final message = {
//       "sender": widget.clientId,
//       "timestamp": DateTime.now().toIso8601String(),
//       "text": text.trim(),
//     };
//
//     await databaseRef.child(chatId).child("messages").push().set(message);
//     _messageController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = "${widget.clientId}_${widget
//         .coiffeuseId}"; // La clé utilisée pour les messages
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.coiffeuseName),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder(
//               stream: databaseRef.child("${widget.clientId}_${widget.coiffeuseId}/messages").onValue,
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
//                   final messages = data.entries.map((e) => e.value).toList();
//
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp'])); // Trier par date
//
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = messages[index];
//                       final isSender = msg['sender'] == widget.clientId;
//
//                       return Align(
//                         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: isSender ? Colors.blueAccent : Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 msg['text'] ?? '',
//                                 style: TextStyle(
//                                   color: isSender ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 msg['timestamp'] ?? '',
//                                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 }
//
//                 return const Center(child: Text("Aucun message."));
//               },
//             )
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: "Écrire un message",
//                       filled: true,
//                       fillColor: Colors.grey.shade200,
//                       contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 10),
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





// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// class ChatPage extends StatefulWidget {
//   final String clientId;
//   final String coiffeuseId;
//
//   ChatPage({required this.clientId, required this.coiffeuseId});
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   //final databaseRef = FirebaseDatabase.instance.ref("chats");
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _messageController = TextEditingController();
//
//   void sendMessage(String text) async {
//     final chatId = "${widget.clientId}_${widget.coiffeuseId}";
//     final message = {
//       "sender": widget.clientId,
//       "timestamp": DateTime.now().toIso8601String(),
//       "text": text,
//     };
//     await databaseRef.child(chatId).child("messages").push().set(message);
//     _messageController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Chat avec la coiffeuse"),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder(
//               stream: databaseRef
//                   .child("${widget.clientId}_${widget.coiffeuseId}/messages")
//                   .onValue,
//               builder: (context, snapshot) {
//                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   final messages = data.entries.map((e) => e.value).toList();
//
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = messages[index] as Map<dynamic, dynamic>;
//                       return ListTile(
//                         title: Text(msg['text'] ?? ''),
//                         subtitle: Text(msg['timestamp'] ?? ''),
//                         trailing: Text(
//                           msg['sender'] == widget.clientId ? "Vous" : "Coiffeuse",
//                         ),
//                       );
//                     },
//                   );
//                 }
//                 return const Center(
//                   child: Text("Aucun message pour l'instant."),
//                 );
//               },
//             )
//           ),
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _messageController,
//                   decoration: InputDecoration(hintText: "Écrire un message"),
//                 ),
//               ),
//               IconButton(
//                 icon: Icon(Icons.send),
//                 onPressed: () {
//                   sendMessage(_messageController.text);
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
