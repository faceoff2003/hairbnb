// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'message.dart';
//
// class ChatService {
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   /// ✅ Récupérer l'utilisateur actuellement connecté
//   String get currentUserId {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception("Utilisateur non authentifié.");
//     return user.uid;
//   }
//
//   /// ✅ Générer un ID de conversation unique
//   String getChatId(String receiverId) {
//     String senderId = currentUserId;
//     return senderId.hashCode <= receiverId.hashCode
//         ? "${senderId}_$receiverId"
//         : "${receiverId}_$senderId";
//   }
//
//   /// ✅ Envoyer un message
//   Future<void> sendMessage(String receiverId, String text) async {
//     if (text.trim().isEmpty) return;
//
//     String chatId = getChatId(receiverId);
//     final message = Message(
//       senderId: currentUserId,
//       receiverId: receiverId,
//       text: text,
//       timestamp: DateTime.now(),
//       isRead: false,
//     );
//
//     await _databaseRef.child("chats").child(chatId).child("messages").push().set(message.toJson());
//   }
//
//   /// ✅ Récupérer les messages d'une conversation
//   Stream<List<Message>> getMessages(String receiverId) {
//     String chatId = getChatId(receiverId);
//
//     return _databaseRef.child("chats").child(chatId).child("messages").onValue.map((event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
//       final messages = data.entries.map((entry) {
//         return Message.fromJson(Map<String, dynamic>.from(entry.value));
//       }).toList();
//
//       messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//       return messages;
//     });
//   }
//
//   /// ✅ Récupérer les conversations de l'utilisateur courant
//   Stream<List<Map<String, dynamic>>> getUserConversations() {
//     String userId = currentUserId;
//
//     return _databaseRef.child("chats").onValue.map((event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
//
//       final conversations = data.entries.where((entry) {
//         return entry.key.contains(userId);
//       }).map((entry) {
//         final conversationKey = entry.key;
//         final messages = entry.value['messages'] as Map<dynamic, dynamic>? ?? {};
//
//         if (messages.isEmpty) return null;
//
//         final lastMessageKey = messages.keys.last;
//         final lastMessage = messages[lastMessageKey];
//
//         return {
//           "conversationKey": conversationKey,
//           "lastMessage": lastMessage?['text'] ?? "Pas de message.",
//           "timestamp": lastMessage?['timestamp'] ?? "",
//           "receiverId": conversationKey.replaceAll(userId, "").replaceAll("_", ""),
//         };
//       }).whereType<Map<String, dynamic>>().toList();
//
//       conversations.sort((a, b) {
//         final tsA = a['timestamp'] ?? '';
//         final tsB = b['timestamp'] ?? '';
//         return tsB.compareTo(tsA);
//       });
//
//       return conversations;
//     });
//   }
// }
