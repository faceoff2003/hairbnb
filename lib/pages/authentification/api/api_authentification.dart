// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../services/auth_services/auth_service.dart';
//
// class ApiAuthentification {
//   final String baseUrl = 'https://votre-backend-django.com/api'; // Remplacez par votre URL
//   final AuthService _authService = AuthService();
//
//   // Vérifier si l'utilisateur existe dans le backend
//   Future<Map<String, dynamic>> verifyUser() async {
//     // D'abord essayer de récupérer le token stocké
//     String? token = await _authService.getFirebaseToken();
//
//     // Si aucun token n'est stocké, essayer d'en obtenir un nouveau
//     if (token == null) {
//       token = await _authService.getFirebaseToken();
//       if (token == null) {
//         throw Exception('Token d\'authentification non disponible');
//       }
//     }
//
//     final response = await http.get(
//       Uri.parse('$baseUrl/user/verify/'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else if (response.statusCode == 401) {
//       // Token expiré ou invalide, essayer de rafraîchir
//       final newToken = await _authService.getFirebaseToken();
//       if (newToken != null) {
//         // Réessayer avec le nouveau token
//         return await _retryVerifyUser(newToken);
//       } else {
//         throw Exception('Session expirée');
//       }
//     } else {
//       throw Exception('Erreur lors de la vérification de l\'utilisateur: ${response.body}');
//     }
//   }
//
//   // Réessayer la vérification avec un nouveau token
//   Future<Map<String, dynamic>> _retryVerifyUser(String token) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/user/verify/'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Erreur lors de la vérification de l\'utilisateur: ${response.statusCode}');
//     }
//   }
//
//   // Enregistrer un nouvel utilisateur dans le backend
//   Future<Map<String, dynamic>> registerUser({
//     required String email,
//     String? displayName,
//     String? photoURL,
//     Map<String, dynamic>? additionalData,
//   }) async {
//     // D'abord essayer de récupérer le token stocké
//     String? token = await _authService.getFirebaseToken();
//
//     // Si aucun token n'est stocké, essayer d'en obtenir un nouveau
//     if (token == null) {
//       token = await _authService.getFirebaseToken();
//       if (token == null) {
//         throw Exception('Token d\'authentification non disponible');
//       }
//     }
//
//     final userData = {
//       'email': email,
//       if (displayName != null) 'display_name': displayName,
//       if (photoURL != null) 'photo_url': photoURL,
//       if (additionalData != null) ...additionalData,
//     };
//
//     final response = await http.post(
//       Uri.parse('$baseUrl/register/'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: json.encode(userData),
//     );
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Erreur lors de l\'enregistrement: ${response.body}');
//     }
//   }
// }