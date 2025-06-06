// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../profile_creation_api.dart';
//
// class PhoneApiDebugService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   /// Met à jour uniquement le numéro de téléphone avec des logs détaillés
//   static Future<bool> updatePhoneWithDebug(String userUuid, String newPhone) async {
//     final apiUrl = '$baseUrl/update_user_phone/$userUuid/';
//
//     // Logs pour le débogage
//     print('🔍 DEBUG: Tentative de mise à jour téléphone');
//     print('🔍 URL: $apiUrl');
//     print('🔍 UUID: $userUuid');
//     print('🔍 Nouveau téléphone: $newPhone');
//
//     try {
//       // Créer la requête avec uniquement le champ du numéro de téléphone
//       final request = PhoneUpdateRequest(numeroTelephone: newPhone);
//       final jsonBody = jsonEncode(request.toJson());
//
//       print('🔍 Corps de la requête: $jsonBody');
//
//       // Envoyer la requête PATCH
//       final response = await http.patch(
//         Uri.parse(apiUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonBody,
//       );
//
//       // Logs de la réponse
//       print('🔍 Statut réponse: ${response.statusCode}');
//       print('🔍 Corps réponse: ${response.body}');
//       print('🔍 Headers réponse: ${response.headers}');
//
//       // Retourner true si réussi, false sinon
//       return response.statusCode == 200;
//     } catch (e) {
//       print('❌ ERREUR: $e');
//       print('❌ Type d\'erreur: ${e.runtimeType}');
//       return false;
//     }
//   }
// }