// services/salon_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/public_salon_details.dart';

class PublicSalonDetailsApi {
  static const String baseUrl = 'https://hairbnb.site/api'; // Remplacez par votre URL d'API

  static Future<PublicSalonDetails> getSalonDetails(int salonId) async {
    final response = await http.get(Uri.parse('$baseUrl/salons/$salonId/'));

    if (response.statusCode == 200) {
      return PublicSalonDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec du chargement des détails du salon');
    }
  }
}