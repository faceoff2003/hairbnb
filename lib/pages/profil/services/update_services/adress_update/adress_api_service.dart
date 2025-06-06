// lib/pages/profil/services/update_services/adress_update/adress_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hairbnb/services/firebase_token/token_service.dart';
import 'package:http/http.dart' as http;

class AddressApiService {
  static Future<bool> updateAddress(String uuid, Map<String, dynamic> addressData) async {
    const String baseUrl = 'https://www.hairbnb.site/api';
    final String endpoint = '$baseUrl/update_user_address/$uuid/';

    try {
      // Récupérer le token d'authentification
      String? authToken = await TokenService.getAuthToken();

      if (authToken == null || authToken.isEmpty) {
        if (kDebugMode) {
          print('Erreur d\'authentification: Token non disponible');
        }
        return false;
      }

      // Préparer la requête
      final response = await http.patch(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken'
        },
        body: jsonEncode(addressData),
      );

      // Vérifier si la requête a réussi (code 200)
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Adresse mise à jour avec succès');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Échec de la mise à jour de l\'adresse: ${response.statusCode}');
          print('Réponse: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de l\'adresse: $e');
      }
      return false;
    }
  }
}