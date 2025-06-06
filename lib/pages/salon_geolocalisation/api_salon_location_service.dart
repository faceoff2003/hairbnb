// lib/services/api_salon_location_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiSalonService {
  static Future<List<dynamic>> fetchNearbySalons(double lat, double lon, double distance) async {
    // URL adaptée pour appeler votre nouveau endpoint de salons
    final url = Uri.parse('https://www.hairbnb.site/api/salons-proches-public/?lat=$lat&lon=$lon&distance=$distance');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['salons']; // Adapté pour utiliser 'salons' au lieu de 'coiffeuses'
      } else {
        throw Exception('Erreur de chargement des salons');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchSalonDetails(int salonId) async {
    // URL pour récupérer les détails d'un salon spécifique
    final url = Uri.parse('https://www.hairbnb.site/api/salon-public/$salonId/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['salon']; // Retourne les détails du salon
      } else {
        throw Exception('Erreur de chargement des détails du salon');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }
}