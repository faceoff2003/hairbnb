import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:hairbnb/models/current_user.dart';

// ✅ Cache pour éviter de recharger les mêmes utilisateurs
Map<String, CurrentUser?> usersCache = {};

final String baseUrl = "http://192.168.0.248:8000"; // ⚠️ Met à jour selon ton backend

/// 🔄 Récupérer les informations d'un utilisateur via son UUID
Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
  if (usersCache.containsKey(otherUserId)) {
    return usersCache[otherUserId]; // ✅ Retour immédiat si déjà en cache
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/get_current_user/$otherUserId/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedBody);
      final user = CurrentUser.fromJson(data['user']);

      usersCache[otherUserId] = user; // ✅ Stocker en cache
      return user;
    }
  } catch (error) {
    print("Erreur lors de la récupération de l'autre utilisateur: $error");
  }

  return null; // 🔴 En cas d'échec
}

Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
  final databaseRef = FirebaseDatabase.instance.ref();
  List<String> coiffeusesUUIDs = [];

  try {
    final snapshot = await databaseRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};

      for (var entry in data.entries) {
        final participants = entry.key.split("_");
        if (participants.contains(userUuid)) {
          final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
          if (!coiffeusesUUIDs.contains(otherUserId)) {
            coiffeusesUUIDs.add(otherUserId);
          }
        }
      }
    }
  } catch (error) {
    print("Erreur lors de la récupération des coiffeuses UUIDs : $error");
  }

  return coiffeusesUUIDs;
}
