// // // // lib/services/api_service.dart
//
// // lib/services/api_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../../../models/services.dart';
//
// class ApiService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // Récupérer les services d'une coiffeuse avec pagination
//   static Future<Map<String, dynamic>> getServicesByCoiffeuse(String coiffeuseId, int currentPage, int pageSize, {required String coiffeuseId}) async {
//     try {
//       final url = Uri.parse(
//         '$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=$currentPage&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         // Informations de pagination
//         int totalServices = 0;
//         String? nextPageUrl;
//         String? previousPageUrl;
//
//         if (responseData.containsKey('count')) {
//           totalServices = responseData['count'];
//           nextPageUrl = responseData['next'];
//           previousPageUrl = responseData['previous'];
//         }
//
//         // Extraction des services selon la structure de la réponse
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> services = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         return {
//           'services': services,
//           'totalServices': totalServices,
//           'nextPageUrl': nextPageUrl,
//           'previousPageUrl': previousPageUrl,
//           'error': null
//         };
//       } else {
//         return {
//           'services': <Service>[],
//           'error': "Erreur serveur: Code ${response.statusCode}"
//         };
//       }
//     } catch (e) {
//       return {
//         'services': <Service>[],
//         'error': "Erreur de connexion au serveur : $e"
//       };
//     }
//   }
//
//   // Récupérer les promotions pour un service avec pagination optionnelle
//   static Future<Map<String, dynamic>> getPromotionsForService(int serviceId, {int? page, int? pageSize}) async {
//     try {
//       // Construction de l'URL avec les paramètres de pagination s'ils sont fournis
//       String urlString = '$baseUrl/services/$serviceId/promotions/';
//
//       if (page != null || pageSize != null) {
//         urlString += '?';
//         if (page != null) {
//           urlString += 'page=$page';
//         }
//         if (page != null && pageSize != null) {
//           urlString += '&';
//         }
//         if (pageSize != null) {
//           urlString += 'page_size=$pageSize';
//         }
//       }
//
//       final url = Uri.parse(urlString);
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(utf8.decode(response.bodyBytes));
//         return {
//           'data': data,
//           'error': null
//         };
//       } else {
//         return {
//           'data': null,
//           'error': "Erreur serveur: Code ${response.statusCode}"
//         };
//       }
//     } catch (e) {
//       return {
//         'data': null,
//         'error': "Erreur de connexion au serveur : $e"
//       };
//     }
//   }
//
//   // Ajouter au panier
//   static Future<Map<String, dynamic>> addToCart(int serviceId, String userId) async {
//     try {
//       final url = Uri.parse('$baseUrl/cart/add/');
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'service_id': serviceId,
//           'user_id': userId,
//         }),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return {
//           'success': true,
//           'data': data,
//           'error': null
//         };
//       } else {
//         return {
//           'success': false,
//           'error': "Erreur serveur: Code ${response.statusCode}"
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'error': "Erreur de connexion au serveur : $e"
//       };
//     }
//   }
//
//   // Supprimer un service (mise à jour avec l'URL correcte du delete_service.dart)
//   static Future<Map<String, dynamic>> deleteService(int serviceId) async {
//     try {
//       final url = Uri.parse('$baseUrl/delete_service/$serviceId/');
//       final response = await http.delete(url);
//
//       if (response.statusCode == 200) {
//         return {
//           'success': true,
//           'error': null
//         };
//       } else {
//         return {
//           'success': false,
//           'error': "Erreur lors de la suppression."
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'error': "Erreur de connexion au serveur."
//       };
//     }
//   }
// }
//
//
//
//
// // // lib/services/api_service.dart
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// // import '../../../../../models/services.dart';
// //
// // class ApiService {
// //   static const String baseUrl = 'https://www.hairbnb.site/api';
// //
// //   // Récupérer les services d'une coiffeuse avec pagination
// //   static Future<Map<String, dynamic>> getServicesByCoiffeuse(String coiffeuseId, int currentPage, int pageSize) async {
// //     try {
// //       final url = Uri.parse(
// //         '$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=$currentPage&page_size=$pageSize',
// //       );
// //       final response = await http.get(url);
// //
// //       if (response.statusCode == 200) {
// //         final responseData = json.decode(utf8.decode(response.bodyBytes));
// //
// //         // Informations de pagination
// //         int totalServices = 0;
// //         String? nextPageUrl;
// //         String? previousPageUrl;
// //
// //         if (responseData.containsKey('count')) {
// //           totalServices = responseData['count'];
// //           nextPageUrl = responseData['next'];
// //           previousPageUrl = responseData['previous'];
// //         }
// //
// //         // Extraction des services selon la structure de la réponse
// //         final serviceList = responseData.containsKey('results')
// //             ? responseData['results']['salon']['services']
// //             : responseData['salon']['services'];
// //
// //         final List<Service> services = (serviceList as List)
// //             .map((json) => Service.fromJson(json))
// //             .whereType<Service>()
// //             .toList();
// //
// //         return {
// //           'services': services,
// //           'totalServices': totalServices,
// //           'nextPageUrl': nextPageUrl,
// //           'previousPageUrl': previousPageUrl,
// //           'error': null
// //         };
// //       } else {
// //         return {
// //           'services': <Service>[],
// //           'error': "Erreur serveur: Code ${response.statusCode}"
// //         };
// //       }
// //     } catch (e) {
// //       return {
// //         'services': <Service>[],
// //         'error': "Erreur de connexion au serveur : $e"
// //       };
// //     }
// //   }
// //
// //   // Récupérer les promotions pour un service
// //   static Future<Map<String, dynamic>> getPromotionsForService(int serviceId) async {
// //     try {
// //       final url = Uri.parse('$baseUrl/services/$serviceId/promotions/');
// //       final response = await http.get(url);
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         return {
// //           'data': data,
// //           'error': null
// //         };
// //       } else {
// //         return {
// //           'data': null,
// //           'error': "Erreur serveur: Code ${response.statusCode}"
// //         };
// //       }
// //     } catch (e) {
// //       return {
// //         'data': null,
// //         'error': "Erreur de connexion au serveur : $e"
// //       };
// //     }
// //   }
// //
// //   // Ajouter au panier
// //   static Future<Map<String, dynamic>> addToCart(int serviceId, String userId) async {
// //     try {
// //       final url = Uri.parse('$baseUrl/cart/add/');
// //       final response = await http.post(
// //         url,
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'service_id': serviceId,
// //           'user_id': userId,
// //         }),
// //       );
// //
// //       if (response.statusCode == 200 || response.statusCode == 201) {
// //         final data = json.decode(response.body);
// //         return {
// //           'success': true,
// //           'data': data,
// //           'error': null
// //         };
// //       } else {
// //         return {
// //           'success': false,
// //           'error': "Erreur serveur: Code ${response.statusCode}"
// //         };
// //       }
// //     } catch (e) {
// //       return {
// //         'success': false,
// //         'error': "Erreur de connexion au serveur : $e"
// //       };
// //     }
// //   }
// //
// //   // Supprimer un service (mise à jour avec l'URL correcte du delete_service.dart)
// //   static Future<Map<String, dynamic>> deleteService(int serviceId) async {
// //     try {
// //       final url = Uri.parse('$baseUrl/delete_service/$serviceId/');
// //       final response = await http.delete(url);
// //
// //       if (response.statusCode == 200) {
// //         return {
// //           'success': true,
// //           'error': null
// //         };
// //       } else {
// //         return {
// //           'success': false,
// //           'error': "Erreur lors de la suppression."
// //         };
// //       }
// //     } catch (e) {
// //       return {
// //         'success': false,
// //         'error': "Erreur de connexion au serveur."
// //       };
// //     }
// //   }
// // }
// //
// //
// //
// //
// //
// // // import 'dart:convert';
// // // import 'package:http/http.dart' as http;
// // //
// // // import '../../../../../models/services.dart';
// // //
// // // class ApiService {
// // //   static const String baseUrl = 'https://www.hairbnb.site/api';
// // //
// // //   // Récupérer les services d'une coiffeuse avec pagination
// // //   static Future<Map<String, dynamic>> getServicesByCoiffeuse(String coiffeuseId, int currentPage, int pageSize) async {
// // //     try {
// // //       final url = Uri.parse(
// // //         '$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=$currentPage&page_size=$pageSize',
// // //       );
// // //       final response = await http.get(url);
// // //
// // //       if (response.statusCode == 200) {
// // //         final responseData = json.decode(utf8.decode(response.bodyBytes));
// // //
// // //         // Informations de pagination
// // //         int totalServices = 0;
// // //         String? nextPageUrl;
// // //         String? previousPageUrl;
// // //
// // //         if (responseData.containsKey('count')) {
// // //           totalServices = responseData['count'];
// // //           nextPageUrl = responseData['next'];
// // //           previousPageUrl = responseData['previous'];
// // //         }
// // //
// // //         // Extraction des services selon la structure de la réponse
// // //         final serviceList = responseData.containsKey('results')
// // //             ? responseData['results']['salon']['services']
// // //             : responseData['salon']['services'];
// // //
// // //         final List<Service> services = (serviceList as List)
// // //             .map((json) => Service.fromJson(json))
// // //             .whereType<Service>()
// // //             .toList();
// // //
// // //         return {
// // //           'services': services,
// // //           'totalServices': totalServices,
// // //           'nextPageUrl': nextPageUrl,
// // //           'previousPageUrl': previousPageUrl,
// // //           'error': null
// // //         };
// // //       } else {
// // //         return {
// // //           'services': <Service>[],
// // //           'error': "Erreur serveur: Code ${response.statusCode}"
// // //         };
// // //       }
// // //     } catch (e) {
// // //       return {
// // //         'services': <Service>[],
// // //         'error': "Erreur de connexion au serveur : $e"
// // //       };
// // //     }
// // //   }
// // //
// // //   // Récupérer les promotions pour un service
// // //   static Future<Map<String, dynamic>> getPromotionsForService(int serviceId) async {
// // //     try {
// // //       final url = Uri.parse('$baseUrl/services/$serviceId/promotions/');
// // //       final response = await http.get(url);
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //         return {
// // //           'data': data,
// // //           'error': null
// // //         };
// // //       } else {
// // //         return {
// // //           'data': null,
// // //           'error': "Erreur serveur: Code ${response.statusCode}"
// // //         };
// // //       }
// // //     } catch (e) {
// // //       return {
// // //         'data': null,
// // //         'error': "Erreur de connexion au serveur : $e"
// // //       };
// // //     }
// // //   }
// // //
// // //   // Ajouter au panier
// // //   static Future<Map<String, dynamic>> addToCart(int serviceId, String userId) async {
// // //     try {
// // //       final url = Uri.parse('$baseUrl/cart/add/');
// // //       final response = await http.post(
// // //         url,
// // //         headers: {'Content-Type': 'application/json'},
// // //         body: json.encode({
// // //           'service_id': serviceId,
// // //           'user_id': userId,
// // //         }),
// // //       );
// // //
// // //       if (response.statusCode == 200 || response.statusCode == 201) {
// // //         final data = json.decode(response.body);
// // //         return {
// // //           'success': true,
// // //           'data': data,
// // //           'error': null
// // //         };
// // //       } else {
// // //         return {
// // //           'success': false,
// // //           'error': "Erreur serveur: Code ${response.statusCode}"
// // //         };
// // //       }
// // //     } catch (e) {
// // //       return {
// // //         'success': false,
// // //         'error': "Erreur de connexion au serveur : $e"
// // //       };
// // //     }
// // //   }
// // //
// // //   // Supprimer un service
// // //   static Future<Map<String, dynamic>> deleteService(int serviceId) async {
// // //     try {
// // //       final url = Uri.parse('$baseUrl/services/$serviceId/');
// // //       final response = await http.delete(url);
// // //
// // //       if (response.statusCode == 204) {
// // //         return {
// // //           'success': true,
// // //           'error': null
// // //         };
// // //       } else {
// // //         return {
// // //           'success': false,
// // //           'error': "Erreur serveur: Code ${response.statusCode}"
// // //         };
// // //       }
// // //     } catch (e) {
// // //       return {
// // //         'success': false,
// // //         'error': "Erreur de connexion au serveur : $e"
// // //       };
// // //     }
// // //   }
// // // }