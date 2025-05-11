import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritesService {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  // Récupère les favoris d'un utilisateur
  static Future<List<dynamic>> getUserFavorites(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/?user=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la récupération des favoris: ${response.body}');
    }
  }

  // Vérifie si un salon est dans les favoris de l'utilisateur
  static Future<bool> isSalonFavorite(int userId, int salonId) async {
    try {
      final favorites = await getUserFavorites(userId);
      return favorites.any((favorite) => favorite['salon'] == salonId);
    } catch (e) {
      // En cas d'erreur, on considère que le salon n'est pas en favori
      return false;
    }
  }

  // Ajoute un salon aux favoris
  static Future<void> addToFavorites(int userId, int salonId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites/add/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user': userId,
        'salon': salonId,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
    }
  }

  // Supprime un salon des favoris
  static Future<void> removeFromFavorites(int userId, int salonId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/remove/$salonId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user': userId,
        'salon': salonId,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception('Échec de la suppression des favoris: ${response.body}');
    }
  }

  // Toggle favori - ajoute ou supprime selon l'état actuel
  static Future<bool> toggleFavorite(int userId, int salonId) async {
    final isFavorite = await isSalonFavorite(userId, salonId);

    if (isFavorite) {
      await removeFromFavorites(userId, salonId);
      return false; // Le salon n'est plus un favori
    } else {
      await addToFavorites(userId, salonId);
      return true; // Le salon est maintenant un favori
    }
  }
}