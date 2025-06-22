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
      "timestamp": timestamp.millisecondsSinceEpoch, // ✅ Toujours utiliser milliseconds
      "isRead": isRead,
    };
  }

  /// ✅ Convertir un JSON Firebase en `Message`
  factory Message.fromJson(Map<dynamic, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      text: json['text'],
      timestamp: _parseTimestamp(json['timestamp']), // ✅ Utilisation de la fonction robuste
      isRead: json['isRead'] ?? false,
    );
  }

  /// ✅ Convertir un `DataSnapshot` Firebase en `Message`
  factory Message.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return Message.fromJson(data);
  }

  /// ✅ Fonction robuste pour convertir le `timestamp` en `DateTime`
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now().toUtc();
    }
    
    // Cas le plus courant : timestamp Unix en millisecondes (int)
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    }
    
    // Cas String
    if (timestamp is String) {
      try {
        // Tenter de parser comme string de millisecondes
        final millis = int.tryParse(timestamp);
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
        }
        
        // Tenter de parser comme ISO string
        return DateTime.parse(timestamp).toUtc();
      } catch (e) {
        print("❌ Erreur parsing timestamp '$timestamp': $e");
      }
    }
    
    // Valeur par défaut en cas d'échec
    return DateTime.now().toUtc();
  }
}
