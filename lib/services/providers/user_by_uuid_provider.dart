// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/services/providers/user_service.dart';
//
// class UserByUuidProvider with ChangeNotifier {
//   Map<String, CurrentUser?> _users = {};
//
//   CurrentUser? getUser(String uuid) => _users[uuid];
//
//   Future<void> loadUser(String uuid) async {
//     if (_users.containsKey(uuid)) return; // ✅ Évite un chargement inutile
//
//     CurrentUser? user = await fetchOtherUser(uuid); // ✅ Utiliser la version avec cache
//     if (user != null) {
//       _users[uuid] = user;
//       notifyListeners(); // 🔄 Met à jour les widgets dépendants
//     }
//   }
// }
//
//
// // import 'dart:convert';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:http/http.dart' as http;
// //
// //
// //
// // final String baseUrl = "http://192.168.0.248:8000";
// //
// // /// 🔄 Récupérer les informations d'un utilisateur via son UUID
// // Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
// //   try {
// //     final response = await http.get(
// //       Uri.parse('$baseUrl/api/get_current_user/$otherUserId/'),
// //       headers: {'Content-Type': 'application/json'},
// //     );
// //
// //     if (response.statusCode == 200) {
// //
// //       // final decodedBody = utf8.decode(response.bodyBytes);
// //       // final responseData = json.decode(decodedBody);
// //
// //       final decodedBody = utf8.decode(response.bodyBytes);
// //       final data = json.decode(decodedBody);
// //       return CurrentUser.fromJson(data['user']); // ✅ Retourne l'utilisateur
// //     }
// //   } catch (error) {
// //     print("Erreur lors de la récupération de l'autre utilisateur: $error");
// //   }
// //
// //   return null; // 🔴 En cas d'échec
// // }
