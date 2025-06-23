// services/favorites_services.dart
import 'package:flutter/foundation.dart';
import '../../models/favorites.dart';
import '../api/favorites_api.dart';

class FavoritesService {
  // Récupère tous les favoris d'un utilisateur
  static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
    return await FavoritesApi.getUserFavorites(userId);
  }

  // Vérifie si un salon est dans les favoris de l'utilisateur et retourne l'objet favori
  static Future<FavoriteModel?> getFavoriteForSalon(int userId, int salonId) async {
    try {
      // Essayer d'abord avec l'endpoint spécifique de vérification
      final favorite = await FavoritesApi.checkFavorite(userId, salonId);
      if (favorite != null) {
        return favorite;
      }

      // // Sinon, rechercher dans la liste complète
      // final favorites = await FavoritesApi.getUserFavorites(userId);
      // for (var fav in favorites) {
      //   // Utiliser getSalonId pour gérer les différentes représentations possibles du salon
      //   if (fav.getSalonId() == salonId) {
      //     return fav;
      //   }
      // }
      // return null; // Salon pas trouvé dans les favoris
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification des favoris: $e');
      }
      return null;
    }
  }

  // Vérifie si un salon est dans les favoris (retourne true/false)
  static Future<bool> isSalonFavorite(int userId, int salonId) async {
    final favorite = await getFavoriteForSalon(userId, salonId);
    return favorite != null;
  }

  // Ajoute un salon aux favoris
  static Future<FavoriteModel?> addToFavorites(int userId, int salonId) async {
    try {
      return await FavoritesApi.addToFavorites(userId, salonId);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'ajout aux favoris: $e');
      }
      return null;
    }
  }

  // Supprime un favori par son ID
  static Future<bool> removeFavorite(int favoriteId) async {
    try {
      return await FavoritesApi.removeFavorite(favoriteId);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du favori: $e');
      }
      return false;
    }
  }

  // Toggle favori - ajoute ou supprime selon l'état actuel
  static Future<bool> toggleFavorite(int userId, int salonId) async {
    try {
      final favorite = await getFavoriteForSalon(userId, salonId);

      if (favorite != null) {
        // Le salon est déjà en favori, on le supprime
        final success = await removeFavorite(favorite.idTblFavorite);
        return !success; // Si suppression réussie, retourne false (plus en favori)
      } else {
        // Le salon n'est pas en favori, on l'ajoute
        final newFavorite = await addToFavorites(userId, salonId);
        return newFavorite != null; // Si ajout réussi, retourne true (maintenant en favori)
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du toggle favori: $e');
      }
      return false;
    }
  }
}






// import '../../models/favorites.dart';
// import '../api/favorites_api.dart';
//
// class FavoritesService {
//   // Récupère tous les favoris d'un utilisateur
//   static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
//     return await FavoritesApi.getUserFavorites(userId);
//   }
//
//   // Vérifie si un salon est dans les favoris de l'utilisateur et retourne l'objet favori
//   static Future<FavoriteModel?> getFavoriteForSalon(int userId, int salonId) async {
//     try {
//       final favorites = await FavoritesApi.getUserFavorites(userId);
//       for (var favorite in favorites) {
//         if (favorite.salon == salonId) {
//           return favorite;
//         }
//       }
//       return null; // Salon pas trouvé dans les favoris
//     } catch (e) {
//       print('Erreur lors de la vérification des favoris: $e');
//       return null;
//     }
//   }
//
//   // Vérifie si un salon est dans les favoris (retourne true/false)
//   static Future<bool> isSalonFavorite(int userId, int salonId) async {
//     final favorite = await getFavoriteForSalon(userId, salonId);
//     return favorite != null;
//   }
//
//   // Ajoute un salon aux favoris
//   static Future<FavoriteModel?> addToFavorites(int userId, int salonId) async {
//     try {
//       return await FavoritesApi.addToFavorites(userId, salonId);
//     } catch (e) {
//       print('Erreur lors de l\'ajout aux favoris: $e');
//       return null;
//     }
//   }
//
//   // Supprime un favori par son ID
//   static Future<bool> removeFavorite(int favoriteId) async {
//     try {
//       return await FavoritesApi.removeFavorite(favoriteId);
//     } catch (e) {
//       print('Erreur lors de la suppression du favori: $e');
//       return false;
//     }
//   }
//
//   // Toggle favori - ajoute ou supprime selon l'état actuel
//   static Future<bool> toggleFavorite(int userId, int salonId) async {
//     try {
//       final favorite = await getFavoriteForSalon(userId, salonId);
//
//       if (favorite != null) {
//         // Le salon est déjà en favori, on le supprime
//         final success = await removeFavorite(favorite.idTblFavorite);
//         return !success; // Si suppression réussie, retourne false (plus en favori)
//       } else {
//         // Le salon n'est pas en favori, on l'ajoute
//         final newFavorite = await addToFavorites(userId, salonId);
//         return newFavorite != null; // Si ajout réussi, retourne true (maintenant en favori)
//       }
//     } catch (e) {
//       print('Erreur lors du toggle favori: $e');
//       return false;
//     }
//   }
// }



// import '../../models/favorites.dart';
// import '../api/favorites_api.dart';
//
// class FavoritesService {
//   // Récupère tous les favoris d'un utilisateur
//   static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
//     return await FavoritesApi.getUserFavorites(userId);
//   }
//
//   // Vérifie si un salon est dans les favoris de l'utilisateur
//   static Future<FavoriteModel?> getFavoriteForSalon(int userId, int salonId) async {
//     try {
//       final favorites = await FavoritesApi.getUserFavorites(userId);
//       for (var favorite in favorites) {
//         if (favorite.salon == salonId) {
//           return favorite;
//         }
//       }
//       return null; // Salon pas trouvé dans les favoris
//     } catch (e) {
//       print('Erreur lors de la vérification des favoris: $e');
//       return null;
//     }
//   }
//
//   // Vérifie si un salon est dans les favoris (retourne true/false)
//   static Future<bool> isSalonFavorite(int userId, int salonId) async {
//     final favorite = await getFavoriteForSalon(userId, salonId);
//     return favorite != null;
//   }
//
//   // Ajoute un salon aux favoris
//   static Future<FavoriteModel?> addToFavorites(int userId, int salonId) async {
//     try {
//       return await FavoritesApi.addToFavorites(userId, salonId);
//     } catch (e) {
//       print('Erreur lors de l\'ajout aux favoris: $e');
//       return null;
//     }
//   }
//
//   // Supprime un favori par son ID
//   static Future<bool> removeFavorite(int favoriteId) async {
//     try {
//       return await FavoritesApi.removeFavorite(favoriteId);
//     } catch (e) {
//       print('Erreur lors de la suppression du favori: $e');
//       return false;
//     }
//   }
//
//   // Toggle favori - ajoute ou supprime selon l'état actuel
//   static Future<bool> toggleFavorite(int userId, int salonId) async {
//     try {
//       final favorite = await getFavoriteForSalon(userId, salonId);
//
//       if (favorite != null) {
//         // Le salon est déjà en favori, on le supprime
//         final success = await removeFavorite(favorite.idTblFavorite);
//         return !success; // Si suppression réussie, retourne false (plus en favori)
//       } else {
//         // Le salon n'est pas en favori, on l'ajoute
//         final newFavorite = await addToFavorites(userId, salonId);
//         return newFavorite != null; // Si ajout réussi, retourne true (maintenant en favori)
//       }
//     } catch (e) {
//       print('Erreur lors du toggle favori: $e');
//       return false;
//     }
//   }
// }





// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class FavoritesService {
//   static const String baseUrl = 'https://votre-api-url.com/api'; // À remplacer par votre URL d'API
//
//   // Récupère les favoris d'un utilisateur
//   static Future<List<dynamic>> getUserFavorites(int userId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/favorites/?user=$userId'),
//       headers: {'Content-Type': 'application/json'},
//     );
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Échec de la récupération des favoris: ${response.body}');
//     }
//   }
//
//   // Vérifie si un salon est dans les favoris de l'utilisateur
//   static Future<bool> isSalonFavorite(int userId, int salonId) async {
//     try {
//       final favorites = await getUserFavorites(userId);
//       return favorites.any((favorite) => favorite['salon'] == salonId);
//     } catch (e) {
//       // En cas d'erreur, on considère que le salon n'est pas en favori
//       return false;
//     }
//   }
//
//   // Ajoute un salon aux favoris
//   static Future<void> addToFavorites(int userId, int salonId) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/favorites/add/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'user': userId,
//         'salon': salonId,
//       }),
//     );
//
//     if (response.statusCode != 201 && response.statusCode != 200) {
//       throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
//     }
//   }
//
//   // Supprime un salon des favoris
//   static Future<void> removeFromFavorites(int userId, int salonId) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/favorites/remove/$salonId/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'user': userId,
//         'salon': salonId,
//       }),
//     );
//
//     if (response.statusCode != 204) {
//       throw Exception('Échec de la suppression des favoris: ${response.body}');
//     }
//   }
//
//   // Toggle favori - ajoute ou supprime selon l'état actuel
//   static Future<bool> toggleFavorite(int userId, int salonId) async {
//     final isFavorite = await isSalonFavorite(userId, salonId);
//
//     if (isFavorite) {
//       await removeFromFavorites(userId, salonId);
//       return false; // Le salon n'est plus un favori
//     } else {
//       await addToFavorites(userId, salonId);
//       return true; // Le salon est maintenant un favori
//     }
//   }
// }