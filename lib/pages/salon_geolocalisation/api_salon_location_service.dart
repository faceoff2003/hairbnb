// lib/services/api_salon_location_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/salon_details_geo.dart';
import '../../services/firebase_token/token_service.dart'; // Import du nouveau modèle

class ApiSalonService {
  // Utilise maintenant SalonsResponse et SalonDetailsForGeo

  // Dans ton ApiSalonService
  static Future<SalonsResponse> fetchNearbySalons(double lat, double lon, double distance) async {
    final url = Uri.parse('https://www.hairbnb.site/api/salons-proches-public/?lat=$lat&lon=$lon&distance=$distance');

    try {
      final token = await TokenService.getAuthToken();
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return SalonsResponse.fromJson(responseData);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Retourne maintenant un seul modèle SalonDetailsForGeo
  static Future<SalonDetailsForGeo> fetchSalonDetails(int salonId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/salon-public/$salonId/');

    try {

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // On transforme le JSON du salon en un objet SalonDetailsForGeo
        return SalonDetailsForGeo.fromJson(responseData['salon']);
      } else {
        throw Exception('Erreur de chargement des détails du salon: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }

  // Méthode helper pour récupérer seulement la liste des salons
  static Future<List<SalonDetailsForGeo>> fetchNearbySalonsList(double lat, double lon, double distance) async {
    final salonsResponse = await fetchNearbySalons(lat, lon, distance);

    if (salonsResponse.isSuccess) {
      return salonsResponse.salons;
    } else {
      throw Exception('Échec de récupération des salons');
    }
  }

  // Méthode pour récupérer les salons triés par distance
  static Future<List<SalonDetailsForGeo>> fetchNearbySalonsSorted(double lat, double lon, double distance) async {
    final salonsResponse = await fetchNearbySalons(lat, lon, distance);

    if (salonsResponse.isSuccess) {
      return salonsResponse.salonsTries;
    } else {
      throw Exception('Échec de récupération des salons');
    }
  }

}