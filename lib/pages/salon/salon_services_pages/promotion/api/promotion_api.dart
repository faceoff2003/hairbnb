// 📁 lib/api/promotion_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class PromotionApi {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  // ✅ Récupérer tous les services avec promo
  static Future<Map<String, dynamic>> getServicesByCoiffeuse(
      String coiffeuseId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=1&page_size=100'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        return {'data': decoded, 'error': null};
      } else {
        return {
          'data': null,
          'error': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'data': null, 'error': 'Erreur lors de l\'appel API: $e'};
    }
  }

  // ✅ Supprimer une promotion
  static Future<bool> deletePromotion(int promotionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete_promotion/$promotionId/'),
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}