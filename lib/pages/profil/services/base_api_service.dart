// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// /// Classe de base pour tous les services API
// /// Fournit des méthodes communes et la gestion des erreurs
// class BaseApiService {
//   // URL de base pour toutes les requêtes API
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // Headers communs pour toutes les requêtes
//   static Map<String, String> get headers => {
//     'Content-Type': 'application/json',
//     // Ajoutez d'autres headers communs ici, comme le token d'authentification
//   };
//
//   // GET request
//   static Future<dynamic> get(
//       String endpoint, {
//         Map<String, String>? additionalHeaders,
//         Function(String)? onError,
//       }) async {
//     final Uri url = Uri.parse('$baseUrl/$endpoint');
//
//     try {
//       final response = await http.get(
//         url,
//         headers: {...headers, ...?additionalHeaders},
//       );
//
//       return _handleResponse(response, onError);
//     } catch (e) {
//       if (onError != null) onError("Erreur réseau : $e");
//       return null;
//     }
//   }
//
//   // POST request
//   static Future<dynamic> post(
//       String endpoint,
//       dynamic body, {
//         Map<String, String>? additionalHeaders,
//         Function(String)? onError,
//       }) async {
//     final Uri url = Uri.parse('$baseUrl/$endpoint');
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {...headers, ...?additionalHeaders},
//         body: jsonEncode(body),
//       );
//
//       return _handleResponse(response, onError);
//     } catch (e) {
//       if (onError != null) onError("Erreur réseau : $e");
//       return null;
//     }
//   }
//
//   // PUT request
//   static Future<dynamic> put(
//       String endpoint,
//       dynamic body, {
//         Map<String, String>? additionalHeaders,
//         Function(String)? onError,
//       }) async {
//     final Uri url = Uri.parse('$baseUrl/$endpoint');
//
//     try {
//       final response = await http.put(
//         url,
//         headers: {...headers, ...?additionalHeaders},
//         body: jsonEncode(body),
//       );
//
//       return _handleResponse(response, onError);
//     } catch (e) {
//       if (onError != null) onError("Erreur réseau : $e");
//       return null;
//     }
//   }
//
//   // PATCH request
//   static Future<dynamic> patch(
//       String endpoint,
//       dynamic body, {
//         Map<String, String>? additionalHeaders,
//         Function(String)? onError,
//       }) async {
//     final Uri url = Uri.parse('$baseUrl/$endpoint');
//
//     try {
//       final response = await http.patch(
//         url,
//         headers: {...headers, ...?additionalHeaders},
//         body: jsonEncode(body),
//       );
//
//       return _handleResponse(response, onError);
//     } catch (e) {
//       if (onError != null) onError("Erreur réseau : $e");
//       return null;
//     }
//   }
//
//   // DELETE request
//   static Future<dynamic> delete(
//       String endpoint, {
//         Map<String, String>? additionalHeaders,
//         Function(String)? onError,
//       }) async {
//     final Uri url = Uri.parse('$baseUrl/$endpoint');
//
//     try {
//       final response = await http.delete(
//         url,
//         headers: {...headers, ...?additionalHeaders},
//       );
//
//       return _handleResponse(response, onError);
//     } catch (e) {
//       if (onError != null) onError("Erreur réseau : $e");
//       return null;
//     }
//   }
//
//   // Méthode utilitaire pour gérer les réponses
//   static dynamic _handleResponse(http.Response response, Function(String)? onError) {
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       // Succès
//       if (response.body.isEmpty) return true;
//       return jsonDecode(response.body);
//     } else {
//       // Erreur
//       final errorMessage = "Erreur serveur : ${response.statusCode}";
//       if (onError != null) onError(errorMessage);
//       return null;
//     }
//   }
// }