// lib/pages/profil/services/update_services/adress_update/adress_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../chat/chat_services/user_service.dart';


class AddressApiService {
  static Future<Map<String, dynamic>> updateUserAddress({
    required String userUuid,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      final String url = 'https://www.hairbnb.site/api/users/$userUuid/address/';

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Ajoutez l'authentification si nécessaire
        },
        body: json.encode(addressData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Erreur ${response.statusCode}: ${response.body}");
      }

    } catch (e) {
      print("❌ Erreur: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserAddress(String userUuid) async {
    try {
      final url = Uri.parse('$baseUrl/users/$userUuid/address');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        print('❌ Erreur récupération: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception récupération: $e');
      return null;
    }
  }
}