import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/favorites.dart';

class FavoritesApi {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  // Récupère les favoris d'un utilisateur
  static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/?user=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => FavoriteModel.fromJson(json)).toList();
    } else {
      throw Exception('Échec de la récupération des favoris: ${response.body}');
    }
  }


  // Ajoute un salon aux favoris
  static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites/add/'),
      headers: {'Content-Type': 'application/json'},
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

  // Supprime un favori par son ID
  static Future<bool> removeFavorite(int favoriteId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/remove/'),
      headers: {'Content-Type': 'application/json'},
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





// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../../models/favorites.dart';
//
// class FavoritesApi {
//   static const String baseUrl = 'https://votre-api-url.com/api'; // À remplacer par votre URL d'API
//
//   // Récupère les favoris d'un utilisateur
//   static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/favorites/?user=$userId'),
//       headers: {'Content-Type': 'application/json'},
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> jsonData = jsonDecode(response.body);
//       return jsonData.map((json) => FavoriteModel.fromJson(json)).toList();
//     } else {
//       throw Exception('Échec de la récupération des favoris: ${response.body}');
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
//
//
//
//
//
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// // import '../../models/favorites.dart';
// //
// // class FavoritesApi {
// //   static const String baseUrl = 'https://votre-api-url.com/api'; // À remplacer par votre URL d'API
// //
// //   // Récupère les favoris d'un utilisateur
// //   static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
// //     final response = await http.get(
// //       Uri.parse('$baseUrl/favorites/?user=$userId'),
// //       headers: {'Content-Type': 'application/json'},
// //     );
// //
// //     if (response.statusCode == 200) {
// //       final List<dynamic> jsonData = jsonDecode(response.body);
// //       return jsonData.map((json) => FavoriteModel.fromJson(json)).toList();
// //     } else {
// //       throw Exception('Échec de la récupération des favoris: ${response.body}');
// //     }
// //   }
// //
// //   // Ajoute un salon aux favoris
// //   static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
// //     final response = await http.post(
// //       Uri.parse('$baseUrl/favorites/add/'),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({
// //         'user': userId,
// //         'salon': salonId,
// //       }),
// //     );
// //
// //     if (response.statusCode == 201 || response.statusCode == 200) {
// //       return FavoriteModel.fromJson(jsonDecode(response.body));
// //     } else {
// //       throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
// //     }
// //   }
// //
// //   // Supprime un favori par son ID
// //   static Future<bool> removeFavorite(int favoriteId) async {
// //     final response = await http.delete(
// //       Uri.parse('$baseUrl/favorites/remove/'),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({
// //         'id': favoriteId,
// //       }),
// //     );
// //
// //     if (response.statusCode == 204) {
// //       return true;
// //     } else {
// //       throw Exception('Échec de la suppression du favori: ${response.statusCode} - ${response.body}');
// //     }
// //   }
// // }
// //
// //
//
//
//
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// //
// // class FavoritesApi {
// //   static const String baseUrl = 'https://www.hairbnb.site/api'; // À remplacer par votre URL d'API
// //
// //   // Récupère les favoris d'un utilisateur
// //   static Future<List<dynamic>> getUserFavorites(int userId) async {
// //     final response = await http.get(
// //       Uri.parse('$baseUrl/favorites/?user=$userId'),
// //       headers: {'Content-Type': 'application/json'},
// //     );
// //
// //     if (response.statusCode == 200) {
// //       return jsonDecode(response.body);
// //     } else {
// //       throw Exception('Échec de la récupération des favoris: ${response.body}');
// //     }
// //   }
// //
// //   // Ajoute un salon aux favoris
// //   static Future<Map<String, dynamic>> addToFavorites(int userId, int salonId) async {
// //     final response = await http.post(
// //       Uri.parse('$baseUrl/favorites/add/'),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({
// //         'user': userId,
// //         'salon': salonId,
// //       }),
// //     );
// //
// //     if (response.statusCode == 201 || response.statusCode == 200) {
// //       return jsonDecode(response.body);
// //     } else {
// //       throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
// //     }
// //   }
// //
// //   // Supprime un salon des favoris
// //   static Future<bool> removeFromFavorites(int userId, int salonId) async {
// //     final response = await http.delete(
// //       Uri.parse('$baseUrl/favorites/remove/$salonId/'),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({
// //         'user': userId,
// //         'salon': salonId,
// //       }),
// //     );
// //
// //     if (response.statusCode == 204) {
// //       return true;
// //     } else {
// //       throw Exception('Échec de la suppression des favoris: ${response.body}');
// //     }
// //   }
// // }