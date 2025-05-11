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


//   // ✅ Supprimer une promotion
//   static Future<bool> deletePromotion(int id) async {
//     try {
//       final res = await http.delete(Uri.parse('$baseUrl/delete_promotion/$id/'));
//       return res.statusCode == 204 || res.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }
// }








// // // 📁 lib/api/promotion_api.dart
//
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../../../../../models/services.dart';
// import '../../../../../models/promotion.dart';
//
// class PromotionApi {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // lib/api/promotion_api.dart (mise à jour de la méthode)
//
//   // lib/pages/salon/salon_services_pages/promotion/services/promotion_service.dart
//   static Future<Map<String, dynamic>> getPromotionsByService(int serviceId) async {
//     try {
//       final promotions = await getApiPromotionsByService(serviceId);
//       return {'promotions': promotions, 'error': null};
//     } catch (e) {
//       return {'promotions': [], 'error': 'Erreur: $e'};
//     }
//   }
//
// // Méthode d'API qui appelle réellement le backend
//   static Future<List<Promotion>> getApiPromotionsByService(int serviceId) async {
//     try {
//       print("API: Récupération des promotions pour service $serviceId");
//
//       // Ajoutez le paramètre include_all=true pour récupérer toutes les promotions
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_promotions_by_service/$serviceId'),
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
//         return data.map((json) => Promotion.fromJson(json)).toList();
//       } else {
//         return [];
//       }
//     } catch (e) {
//       print("Exception lors de la récupération des promotions: $e");
//       return [];
//     }
//   }
//
//   // lib/pages/salon/salon_services_pages/promotion/services/promotion_service.dart
//   static Future<Map<String, dynamic>> getServices(String coiffeuseId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/$coiffeuseId/?page=1&page_size=100'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> fetchedServices = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         return {
//           'services': fetchedServices,
//           'totalCount': responseData.containsKey('count') ? responseData['count'] : fetchedServices.length,
//           'error': null,
//         };
//       } else {
//         return {'services': null, 'error': 'Erreur serveur: ${response.statusCode}'};
//       }
//     } catch (e) {
//       return {'services': null, 'error': 'Erreur lors du traitement des services: $e'};
//     }
//   }






  // Récupérer toutes les promotions d'un service

  // static Future<List<Promotion>> getPromotionsByService(int serviceId) async {
  //   try {
  //     print("API: Récupération des promotions pour le service ID: $serviceId");
  //
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/get_promotions_by_service/$serviceId/'),
  //     );
  //
  //     // Log du résultat
  //     print("API: Réponse du serveur: Code ${response.statusCode}");
  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
  //       final promos = data.map((json) => Promotion.fromJson(json)).toList();
  //       print("API: Nombre de promotions récupérées: ${promos.length}");
  //
  //       // Ajouter des exemples si aucune promotion
  //       if (promos.isEmpty) {
  //         print("API: Aucune promotion trouvée, ajout de données de test");
  //         // Ajouter des promotions de test
  //         final now = DateTime.now();
  //
  //         // Promotion passée
  //         promos.add(Promotion(
  //           id: -1,
  //           serviceId: serviceId,
  //           pourcentage: 15.0,
  //           dateDebut: now.subtract(const Duration(days: 30)),
  //           dateFin: now.subtract(const Duration(days: 15)),
  //           isActiveValue: false,
  //         ));
  //
  //         // Promotion future
  //         promos.add(Promotion(
  //           id: -2,
  //           serviceId: serviceId,
  //           pourcentage: 25.0,
  //           dateDebut: now.add(const Duration(days: 15)),
  //           dateFin: now.add(const Duration(days: 30)),
  //           isActiveValue: false,
  //         ));
  //       }
  //
  //       return promos;
  //     } else {
  //       print("API: Erreur ${response.statusCode} - ${response.body}");
  //       return [];
  //     }
  //   } catch (e) {
  //     print("API: Exception pendant la récupération: $e");
  //     return [];
  //   }
  // }







  // static Future<List<Promotion>> getPromotionsByService(int serviceId) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/get_promotions_by_service/$serviceId/'),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
  //       return data.map((json) => Promotion.fromJson(json)).toList();
  //     } else {
  //       throw Exception('Erreur serveur: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Erreur de récupération des promotions: $e');
  //   }
  // }

  // // Supprimer une promotion
  // Future<bool> deletePromotion(int promotionId) async {
  //   try {
  //     final response = await http.delete(
  //       Uri.parse('$baseUrl/delete_promotion/$promotionId/'),
  //     );
  //
  //     return response.statusCode == 200 || response.statusCode == 204;
  //   } catch (e) {
  //     throw Exception('Erreur de suppression: $e');
  //   }
  // }
  //
  // // Récupérer tous les services avec leurs promotions
  // Future<Map<String, dynamic>> getServicesByCoiffeuse(String coiffeuseId, {int page = 1, int pageSize = 100}) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=$page&page_size=$pageSize'),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(utf8.decode(response.bodyBytes));
  //       return {'data': responseData, 'error': null};
  //     } else {
  //       return {'data': null, 'error': 'Erreur serveur: ${response.statusCode}'};
  //     }
  //   } catch (e) {
  //     return {'data': null, 'error': 'Erreur de connexion: $e'};
  //   }
  //}