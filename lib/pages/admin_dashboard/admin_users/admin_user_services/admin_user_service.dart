import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/admin_user.dart';

class AdminUserService {
  static const String baseUrl = "https://www.hairbnb.site";

  /// Récupère les headers avec le token Firebase (comme CurrentUserProvider)
  static Future<Map<String, String>> get _headers async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final token = await firebaseUser.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Récupère la liste de tous les utilisateurs
  static Future<List<AdminUser>> fetchAllUsers() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/api/administration/gestion-utilisateurs/'),
        headers: headers,
      );

      if (kDebugMode) {
        print('🔍 [AdminUserService] Status: ${response.statusCode}');
        print('🔍 [AdminUserService] Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        if (data['success'] == true) {
          final List<dynamic> usersJson = data['users'] ?? [];
          return usersJson.map((json) => AdminUser.fromJson(json)).toList();
        } else {
          throw Exception('Réponse API invalide: ${data}');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdminUserService] Erreur fetchAllUsers: $e');
      }
      throw Exception('Impossible de charger les utilisateurs: $e');
    }
  }

  /// Gère une action sur un utilisateur (activer/désactiver/changer rôle)
  static Future<String> manageUser({
    required int userId,
    required String action,
    int? newRoleId,
  }) async {
    try {
      final headers = await _headers;
      final body = {
        'user_id': userId,
        'action': action,
        if (newRoleId != null) 'new_role_id': newRoleId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/administration/gestion-utilisateurs/action/'),
        headers: headers,
        body: json.encode(body),
      );

      if (kDebugMode) {
        print('🔧 [AdminUserService] Action: $action, Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        if (data['success'] == true) {
          return data['message'] ?? 'Action effectuée avec succès';
        } else {
          throw Exception(data['message'] ?? 'Erreur serveur');
        }
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdminUserService] Erreur manageUser: $e');
      }
      throw Exception('Impossible d\'effectuer l\'action: $e');
    }
  }

  /// Désactive un utilisateur
  static Future<String> deactivateUser(int userId) async {
    return await manageUser(userId: userId, action: 'deactivate');
  }

  /// Active un utilisateur
  static Future<String> activateUser(int userId) async {
    return await manageUser(userId: userId, action: 'activate');
  }

  /// Change le rôle d'un utilisateur (1=user, 2=admin)
  static Future<String> changeUserRole(int userId, int newRoleId) async {
    return await manageUser(
      userId: userId,
      action: 'change_role',
      newRoleId: newRoleId,
    );
  }
}






// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../../models/admin_user.dart';
// import '../../../../services/api_services/api_service.dart';
//
// class AdminUserService {
//
//   // //-----------------------------------------------------------------------------------
//   // // Dans admin_user_service.dart, ajoutez des logs plus détaillés
//   // static Future<List<AdminUser>> fetchAllUsers() async {
//   //   try {
//   //     final headers = await APIService.headers;
//   //     final url = '${APIService.baseURL}/administration/gestion-utilisateurs/';
//   //
//   //     print('🌐 [DEBUG] URL complète: $url');
//   //     print('🔑 [DEBUG] Headers: $headers');
//   //
//   //     final response = await http.get(
//   //       Uri.parse(url),
//   //       headers: headers,
//   //     );
//   //
//   //     print('🔍 [DEBUG] Status Code: ${response.statusCode}');
//   //     print('🔍 [DEBUG] Response Headers: ${response.headers}');
//   //     print('🔍 [DEBUG] Response Body: ${response.body}');
//   //
//   //     if (response.statusCode == 200) {
//   //       final decodedBody = utf8.decode(response.bodyBytes);
//   //       final data = json.decode(decodedBody);
//   //
//   //       if (data['success'] == true) {
//   //         final List<dynamic> usersJson = data['users'] ?? [];
//   //         return usersJson.map((json) => AdminUser.fromJson(json)).toList();
//   //       } else {
//   //         throw Exception('Réponse API invalide: ${data}');
//   //       }
//   //     } else {
//   //       throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
//   //     }
//   //   } catch (e) {
//   //     print('❌ [AdminUserService] Erreur fetchAllUsers: $e');
//   //     throw Exception('Impossible de charger les utilisateurs: $e');
//   //   }
//   // }
//   // //-----------------------------------------------------------------------------------
//
//   // Récupère la liste de tous les utilisateurs
//   static Future<List<AdminUser>> fetchAllUsers() async {
//     try {
//       final headers = await APIService.headers;
//       final response = await http.get(
//         Uri.parse('${APIService.baseURL}/administration/gestion-utilisateurs/'),
//         headers: headers,
//       );
//
//       if (kDebugMode) {
//         print('🔍 [AdminUserService] Status: ${response.statusCode}');
//       }
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final data = json.decode(decodedBody);
//
//         if (data['success'] == true) {
//           final List<dynamic> usersJson = data['users'] ?? [];
//           return usersJson.map((json) => AdminUser.fromJson(json)).toList();
//         } else {
//           throw Exception('Réponse API invalide');
//         }
//       } else {
//         throw Exception('Erreur serveur: ${response.statusCode}');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ [AdminUserService] Erreur fetchAllUsers: $e');
//       }
//       throw Exception('Impossible de charger les utilisateurs: $e');
//     }
//   }
//
//   /// Gère une action sur un utilisateur (activer/désactiver/changer rôle)
//   static Future<String> manageUser({
//     required int userId,
//     required String action, // 'activate', 'deactivate', 'change_role'
//     int? newRoleId,
//   }) async {
//     try {
//       final headers = await APIService.headers;
//       final body = {
//         'user_id': userId,
//         'action': action,
//         if (newRoleId != null) 'new_role_id': newRoleId,
//       };
//
//       final response = await http.post(
//         Uri.parse('${APIService.baseURL}/administration/gestion-utilisateurs/action/'),
//         headers: headers,
//         body: json.encode(body),
//       );
//
//       if (kDebugMode) {
//         print('🔧 [AdminUserService] Action: $action, Status: ${response.statusCode}');
//       }
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final data = json.decode(decodedBody);
//
//         if (data['success'] == true) {
//           return data['message'] ?? 'Action effectuée avec succès';
//         } else {
//           throw Exception(data['message'] ?? 'Erreur serveur');
//         }
//       } else {
//         final errorData = json.decode(utf8.decode(response.bodyBytes));
//         throw Exception(errorData['message'] ?? 'Erreur ${response.statusCode}');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ [AdminUserService] Erreur manageUser: $e');
//       }
//       throw Exception('Impossible d\'effectuer l\'action: $e');
//     }
//   }
//
//   /// Désactive un utilisateur
//   static Future<String> deactivateUser(int userId) async {
//     return await manageUser(userId: userId, action: 'deactivate');
//   }
//
//   /// Active un utilisateur
//   static Future<String> activateUser(int userId) async {
//     return await manageUser(userId: userId, action: 'activate');
//   }
//
//   /// Change le rôle d'un utilisateur (1=user, 2=admin)
//   static Future<String> changeUserRole(int userId, int newRoleId) async {
//     return await manageUser(
//       userId: userId,
//       action: 'change_role',
//       newRoleId: newRoleId,
//     );
//   }
// }