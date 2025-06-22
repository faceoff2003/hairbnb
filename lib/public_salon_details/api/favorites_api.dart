// api/favorites_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../models/favorites.dart';
import '../../services/api_services/api_service.dart';

class FavoritesApi {
  // Récupère les favoris d'un utilisateur
  static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
    final response = await http.get(
      Uri.parse('${APIService.baseURL}/get_user_favorites/?user=$userId'),
      headers: await APIService.headers, // 🎯 Token Firebase inclus automatiquement
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      if (kDebugMode) {
        print("Données reçues: ${jsonData.length} favoris");
        if (jsonData.isNotEmpty) {
          print("Premier favori: ${jsonData.first}");
        }
      }
      return jsonData.map((json) => FavoriteModel.fromJson(json)).toList();
    } else {
      throw Exception('Échec de la récupération des favoris: ${response.body}');
    }
  }

  // Ajoute un salon aux favoris
  static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
    final response = await http.post(
      Uri.parse('${APIService.baseURL}/favorites/add/'),
      headers: await APIService.headers, // 🎯 Auth Firebase automatique
      body: jsonEncode({
        'user': userId,
        'salon': salonId,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return FavoriteModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
    }
  }

  // Vérifie si un salon est en favori pour un utilisateur
  static Future<FavoriteModel?> checkFavorite(int userId, int salonId) async {
    try {
      final response = await http.get(
        Uri.parse('${APIService.baseURL}/check_favorite/?user=$userId&salon=$salonId'),
        headers: await APIService.headers, // 🎯 Headers automatiques avec auth
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FavoriteModel.fromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        if (kDebugMode) {
          print('Erreur check_favorite: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception dans checkFavorite: $e');
      }
      return null;
    }
  }

  // // Ajoute un salon aux favoris
  // static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
  //   final response = await http.post(
  //     Uri.parse('${APIService.baseURL}/favorites/add/'),
  //     headers: await APIService.headers, // 🎯 Token d'auth inclus automatiquement
  //     body: jsonEncode({
  //       'user': userId,
  //       'salon': salonId,
  //     }),
  //   );
  //
  //   if (response.statusCode == 201 || response.statusCode == 200) {
  //     return FavoriteModel.fromJson(jsonDecode(response.body));
  //   } else {
  //     throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
  //   }
  // }

  // Supprime un favori par son ID
  static Future<bool> removeFavorite(int favoriteId) async {
    final response = await http.delete(
      Uri.parse('${APIService.baseURL}/favorites/remove/'),
      headers: await APIService.headers, // 🎯 Auth + version app automatique
      body: jsonEncode({
        'id': favoriteId,
      }),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Échec de la suppression du favori: ${response.statusCode} - ${response.body}');
    }
  }
}







// // api/favorites_api.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
// import '../../models/favorites.dart';
//
// class FavoritesApi {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // Récupère les favoris d'un utilisateur
//   static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/get_user_favorites/?user=$userId'),
//       headers: {'Content-Type': 'application/json'},
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> jsonData = jsonDecode(response.body);
//       if (kDebugMode) {
//         print("Données reçues: ${jsonData.length} favoris");
//         if (jsonData.isNotEmpty) {
//           print("Premier favori: ${jsonData.first}");
//         }
//       }
//       return jsonData.map((json) => FavoriteModel.fromJson(json)).toList();
//     } else {
//       throw Exception('Échec de la récupération des favoris: ${response.body}');
//     }
//   }
//
//   // Vérifie si un salon est en favori pour un utilisateur
//   static Future<FavoriteModel?> checkFavorite(int userId, int salonId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/check_favorite/?user=$userId&salon=$salonId'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);
//         return FavoriteModel.fromJson(json);
//       } else if (response.statusCode == 404) {
//         return null;
//       } else {
//         if (kDebugMode) {
//           print('Erreur check_favorite: ${response.statusCode} - ${response.body}');
//         }
//         return null;
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Exception dans checkFavorite: $e');
//       }
//       return null;
//     }
//   }
//
//   // Ajoute un salon aux favoris
//   static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/favorites/add/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'user': userId,
//         'salon': salonId,
//       }),
//     );
//
//     if (response.statusCode == 201 || response.statusCode == 200) {
//       return FavoriteModel.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
//     }
//   }
//
//   // Supprime un favori par son ID
//   static Future<bool> removeFavorite(int favoriteId) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/favorites/remove/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'id': favoriteId,
//       }),
//     );
//
//     if (response.statusCode == 204) {
//       return true;
//     } else {
//       throw Exception('Échec de la suppression du favori: ${response.statusCode} - ${response.body}');
//     }
//   }
// }