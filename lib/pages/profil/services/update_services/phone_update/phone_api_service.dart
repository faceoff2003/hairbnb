import 'package:http/http.dart' as http;
import '../../../../../services/firebase_token/token_service.dart';

class PhoneApiService {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Met à jour uniquement le numéro de téléphone d'un utilisateur
  /// Inclut automatiquement le token d'authentification
  static Future<bool> updatePhone(String userUuid, String newPhone) async {
    try {
      final apiUrl = '$baseUrl/update_user_phone/$userUuid/';

      // Récupérer le token d'authentification
      final String? authToken = await TokenService.getAuthToken();

      if (authToken == null) {
        print('Erreur: Token d\'authentification non disponible');
        return false;
      }

      // Préparer les headers avec le token d'authentification
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken', // Ajout du token
      };

      // Créer la requête avec uniquement le champ du numéro de téléphone
      //final request = PhoneUpdateRequest(numeroTelephone: newPhone);

      // Envoyer la requête PATCH
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: headers, // Utiliser les headers avec le token
        //body: jsonEncode(request.toJson()),
      );

      // Vérifier le statut de la réponse
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erreur API: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de la mise à jour du téléphone: $e');
      return false;
    }
  }
}

class PhoneUpdateRequest {
}