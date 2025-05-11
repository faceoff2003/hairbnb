// services/salon_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../models/salon.dart';

class SalonByCoiffeuseApi {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  // Récupérer le salon associé à une coiffeuse
  static Future<Salon?> getSalonByCoiffeuseId(int coiffeuseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_salon_by_coiffeuse/$coiffeuseId/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['exists'] == true && data['salon'] != null) {
          return Salon.fromJson(data['salon']);
        } else {
          return null;
        }
      } else {
        // Si le statut n'est pas 200, on retourne null
        print('Erreur API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // En cas d'erreur réseau ou autre
      print('Exception lors de la récupération du salon: $e');
      return null;
    }
  }
}