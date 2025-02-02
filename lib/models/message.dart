import 'package:firebase_database/firebase_database.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  /// ✅ Convertir un objet `Message` en JSON pour Firebase
  Map<String, dynamic> toJson() {
    return {
      "senderId": senderId,
      "receiverId": receiverId,
      "text": text,
      "timestamp": timestamp.millisecondsSinceEpoch, // ✅ Stockage en int pour Firebase
      "isRead": isRead,
    };
  }

  /// ✅ Convertir un JSON Firebase en `Message`
  factory Message.fromJson(Map<dynamic, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      text: json['text'],
      timestamp: _parseTimestamp(json['timestamp']), // ✅ Utilisation de la nouvelle fonction
      isRead: json['isRead'] ?? false,
    );
  }

  /// ✅ Convertir un `DataSnapshot` Firebase en `Message`
  factory Message.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return Message.fromJson(data);
  }

  /// ✅ Fonction pour convertir le `timestamp` (String ou int) en `DateTime`
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      return DateTime.parse(timestamp).toUtc(); // ✅ Cas d'une String ISO
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true); // ✅ Cas d'un int Unix
    }
    return DateTime.now().toUtc(); // ✅ Valeur par défaut (sécurité)
  }
}













// import 'package:firebase_database/firebase_database.dart';
//
// class Message {
//   final String senderId;
//   final String receiverId;
//   final String text;
//   final DateTime timestamp;
//   final bool isRead;
//
//   Message({
//     required this.senderId,
//     required this.receiverId,
//     required this.text,
//     required this.timestamp,
//     this.isRead = false,
//   });
//
//   /// ✅ Convertir un objet `Message` en JSON pour Firebase
//   Map<String, dynamic> toJson() {
//     return {
//       "senderId": senderId,
//       "receiverId": receiverId,
//       "text": text,
//       "timestamp": timestamp.toIso8601String(),
//       "isRead": isRead,
//     };
//   }
//
//   /// ✅ Convertir un JSON Firebase en `Message`
//   factory Message.fromJson(Map<dynamic, dynamic> json) {
//     return Message(
//       senderId: json['senderId'],
//       receiverId: json['receiverId'],
//       text: json['text'],
//       timestamp: DateTime.parse(json['timestamp']),
//       isRead: json['isRead'] ?? false,
//     );
//   }
//
//   /// ✅ Convertir un `DataSnapshot` Firebase en `Message`
//   factory Message.fromSnapshot(DataSnapshot snapshot) {
//     final data = snapshot.value as Map<dynamic, dynamic>;
//     return Message.fromJson(data);
//   }
// }













// import 'package:firebase_database/firebase_database.dart';
//
// class Message {
//   final String senderId; // ID de l'expéditeur (client ou coiffeuse)
//   final String receiverId; // ID du destinataire
//   final String text; // Contenu du message
//   final DateTime timestamp; // Horodatage du message
//   final bool isRead; // Statut de lecture du message
//
//   Message({
//     required this.senderId,
//     required this.receiverId,
//     required this.text,
//     required this.timestamp,
//     this.isRead = false, // Par défaut, non lu
//   });
//
//   /// ✅ Convertir un objet Message en JSON pour Firebase Realtime Database
//   Map<String, dynamic> toJson() {
//     return {
//       "senderId": senderId,
//       "receiverId": receiverId,
//       "text": text,
//       "timestamp": timestamp.toIso8601String(),
//       "isRead": isRead,
//     };
//   }
//
//   /// ✅ Convertir un JSON Firebase en objet Message
//   factory Message.fromJson(Map<dynamic, dynamic> json) {
//     return Message(
//       senderId: json['senderId'],
//       receiverId: json['receiverId'],
//       text: json['text'],
//       timestamp: DateTime.parse(json['timestamp']),
//       isRead: json['isRead'] ?? false,
//     );
//   }
//
//   /// ✅ Convertir un `DataSnapshot` Firebase en objet Message
//   factory Message.fromSnapshot(DataSnapshot snapshot) {
//     final data = snapshot.value as Map<dynamic, dynamic>;
//     return Message.fromJson(data);
//   }
// }
