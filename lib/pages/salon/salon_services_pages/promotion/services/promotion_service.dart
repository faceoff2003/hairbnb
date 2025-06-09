// 📁 lib/services/promotion_service.dart

import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';
import '../api/promotion_api.dart';

class PromotionService {
  // ✅ Récupère tous les services et les mappe correctement
  static Future<Map<String, dynamic>> getServices(String coiffeuseId) async {
    try {
      final result = await PromotionApi.getServicesByCoiffeuse(coiffeuseId);

      if (result['error'] != null) {
        return {'services': null, 'error': result['error']};
      }

      final data = result['data'];
      final serviceList = data.containsKey('results')
          ? data['results']['salon']['services']
          : data['salon']['services'];

      final List<ServiceWithPromo> services = (serviceList as List)
          .map((json) => ServiceWithPromo.fromJson(json))
          .toList();

      return {
        'services': services,
        'totalCount': data['count'] ?? services.length,
        'error': null,
      };
    } catch (e) {
      return {'services': null, 'error': 'Erreur lors du traitement des services: $e'};
    }
  }

  // ✅ Supprimer une promotion
  static Future<Map<String, dynamic>> deletePromotion(int promotionId) async {
    try {
      final bool success = await PromotionApi.deletePromotion(promotionId);

      return success
          ? {'success': true, 'message': '✅ Promotion supprimée avec succès'}
          : {'success': false, 'error': '❌ Impossible de supprimer la promotion.'};

    } catch (e) {
      return {
        'success': false,
        'error': '🚨 Une erreur est survenue : ${e.toString()}',
      };
    }
  }

  // ✅ Fusionne toutes les promos dans un seul tableau pour le modal
  static Future<Map<String, dynamic>> getAllPromotionsForService(ServiceWithPromo service) async {
    try {
      List<PromotionFull> allPromotions = [];

      if (service.promotion_active != null) {
        allPromotions.add(service.promotion_active!);
      }
      if (service.promotions_a_venir.isNotEmpty) {
        allPromotions.addAll(service.promotions_a_venir);
      }
      if (service.promotions_expirees.isNotEmpty) {
        allPromotions.addAll(service.promotions_expirees);
      }

      _sortPromotions(allPromotions);

      return {'promotions': allPromotions, 'error': null};
    } catch (e) {
      return {'promotions': [], 'error': 'Erreur: $e'};
    }
  }

  // ✅ Statut actif
  static bool isPromotionActive(PromotionFull promotion) {
    final now = DateTime.now();
    return now.isAfter(promotion.dateDebut) && now.isBefore(promotion.dateFin);
  }

  // ✅ Statut à venir
  static bool isPromotionFuture(PromotionFull promotion) {
    return promotion.dateDebut.isAfter(DateTime.now());
  }

  // ✅ Tri : actives -> futures -> expirées
  static void _sortPromotions(List<PromotionFull> promotions) {
    promotions.sort((a, b) {
      final aActive = isPromotionActive(a);
      final bActive = isPromotionActive(b);

      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      final aFuture = isPromotionFuture(a);
      final bFuture = isPromotionFuture(b);

      if (aFuture && !bFuture) return -1;
      if (!aFuture && bFuture) return 1;

      return a.dateDebut.compareTo(b.dateDebut);
    });
  }
}








// // 📁 lib/services/promotion_service.dart
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
// import '../api/promotion_api.dart';
//
// class PromotionService {
//   // Récupérer tous les services avec leurs promotions
//   static Future<Map<String, dynamic>> getServices(String coiffeuseId) async {
//     try {
//       final result = await PromotionApi.getServicesByCoiffeuse(coiffeuseId);
//
//       if (result['error'] != null) {
//         return {'services': null, 'error': result['error']};
//       }
//
//       final responseData = result['data'];
//
//       final serviceList = responseData.containsKey('results')
//           ? responseData['results']['salon']['services']
//           : responseData['salon']['services'];
//
//       final List<ServiceWithPromo> fetchedServices = (serviceList as List)
//           .map((json) => ServiceWithPromo.fromJson(json))
//           .toList();
//
//       return {
//         'services': fetchedServices,
//         'totalCount': responseData.containsKey('count') ? responseData['count'] : fetchedServices.length,
//         'error': null,
//       };
//     } catch (e) {
//       return {'services': null, 'error': 'Erreur lors du traitement des services: $e'};
//     }
//   }
//
//   // Récupérer toutes les promotions d'un service (depuis l'API)
//   static Future<Map<String, dynamic>> getPromotionsByService(int serviceId) async {
//     try {
//       final promotions = await PromotionApi.getPromotionsByService(serviceId);
//       final List<PromotionFull> promoList = (promotions as List)
//           .map((json) => PromotionFull.fromJson(json))
//           .toList();
//
//       return {'promotions': promoList, 'error': null};
//     } catch (e) {
//       return {'promotions': [], 'error': 'Erreur: $e'};
//     }
//   }
//
//   // Supprimer une promotion
//   static Future<Map<String, dynamic>> deletePromotion(int promotionId) async {
//     try {
//       final success = await PromotionApi.deletePromotion(promotionId);
//       if (success) {
//         return {'success': true, 'message': 'Promotion supprimée avec succès'};
//       } else {
//         return {'success': false, 'error': 'Échec de la suppression'};
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Erreur: $e'};
//     }
//   }
//
//   // Obtenir toutes les promotions et les trier
//   static Future<Map<String, dynamic>> getAllPromotionsForService(ServiceWithPromo service) async {
//     try {
//       final result = await getPromotionsByService(service.id);
//
//       if (result['error'] != null) {
//         if (service.promotion_active != null) {
//           return {'promotions': [service.promotion_active!], 'error': null};
//         }
//         return result;
//       }
//
//       List<PromotionFull> allPromotions = result['promotions'];
//
//       // Ajouter la promotion active s’il y en a une et qu’elle n’est pas déjà dans la liste
//       if (service.promotion_active != null) {
//         bool found = allPromotions.any((p) => p.id == service.promotion_active!.id);
//         if (!found) {
//           allPromotions.add(service.promotion_active!);
//         }
//       }
//
//       _sortPromotions(allPromotions);
//
//       return {'promotions': allPromotions, 'error': null};
//     } catch (e) {
//       if (service.promotion_active != null) {
//         return {'promotions': [service.promotion_active!], 'error': 'Erreur partielle: $e'};
//       }
//       return {'promotions': [], 'error': 'Erreur: $e'};
//     }
//   }
//
//   // Vérifier si une promotion est active
//   static bool isPromotionActive(PromotionFull promotion) {
//     final DateTime now = DateTime.now();
//     return now.isAfter(promotion.dateDebut) && now.isBefore(promotion.dateFin);
//   }
//
//   // Vérifier si une promotion est future
//   static bool isPromotionFuture(PromotionFull promotion) {
//     final DateTime now = DateTime.now();
//     return promotion.dateDebut.isAfter(now);
//   }
//
//   // Trier les promotions : actives d'abord, puis futures, puis expirées
//   static void _sortPromotions(List<PromotionFull> promotions) {
//     promotions.sort((a, b) {
//       final bool aIsActive = isPromotionActive(a);
//       final bool bIsActive = isPromotionActive(b);
//
//       if (aIsActive && !bIsActive) return -1;
//       if (!aIsActive && bIsActive) return 1;
//
//       final bool aIsFuture = isPromotionFuture(a);
//       final bool bIsFuture = isPromotionFuture(b);
//
//       if (aIsFuture && !bIsFuture) return -1;
//       if (!aIsFuture && bIsFuture) return 1;
//
//       return a.dateDebut.compareTo(b.dateDebut);
//     });
//   }
// }








// // 📁 lib/services/promotion_service.dart
// import '../../../../../models/services.dart';
// import '../../../../../models/promotion.dart';
// import '../api/promotion_api.dart';
//
// class PromotionService {
//   // Récupérer tous les services avec leurs promotions
//   static Future<Map<String, dynamic>> getServices(String coiffeuseId) async {
//     try {
//       final result = await PromotionApi.getServicesByCoiffeuse(coiffeuseId);
//
//       if (result['error'] != null) {
//         return {'services': null, 'error': result['error']};
//       }
//
//       final responseData = result['data'];
//
//       final serviceList = responseData.containsKey('results')
//           ? responseData['results']['salon']['services']
//           : responseData['salon']['services'];
//
//       final List<Service> fetchedServices = (serviceList as List)
//           .map((json) => Service.fromJson(json))
//           .whereType<Service>()
//           .toList();
//
//       return {
//         'services': fetchedServices,
//         'totalCount': responseData.containsKey('count') ? responseData['count'] : fetchedServices.length,
//         'error': null,
//       };
//     } catch (e) {
//       return {'services': null, 'error': 'Erreur lors du traitement des services: $e'};
//     }
//   }
//
//   // Récupérer toutes les promotions d'un service
//   static Future<Map<String, dynamic>> getPromotionsByService(int serviceId) async {
//     try {
//       final promotions = await PromotionApi.getPromotionsByService(serviceId);
//       return {'promotions': promotions, 'error': null};
//     } catch (e) {
//       return {'promotions': [], 'error': 'Erreur: $e'};
//     }
//   }
//
//   // Supprimer une promotion
//   static Future<Map<String, dynamic>> deletePromotion(int promotionId) async {
//     try {
//       final success = await PromotionApi.deletePromotion(promotionId);
//       if (success) {
//         return {'success': true, 'message': 'Promotion supprimée avec succès'};
//       } else {
//         return {'success': false, 'error': 'Échec de la suppression'};
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Erreur: $e'};
//     }
//   }
//
//   // Obtenir toutes les promotions et les trier
//   static Future<Map<String, dynamic>> getAllPromotionsForService(Service service) async {
//     try {
//       // Récupérer les promotions de l'API
//       final result = await getPromotionsByService(service.id);
//
//       if (result['error'] != null) {
//         // Si erreur mais promotion active disponible
//         if (service.promotion != null) {
//           return {'promotions': [service.promotion!], 'error': null};
//         }
//         return result;
//       }
//
//       List<Promotion> allPromotions = List<Promotion>.from(result['promotions']);
//
//       // Ajouter la promotion active si elle n'est pas déjà incluse
//       if (service.promotion != null) {
//         bool found = false;
//         for (var promo in allPromotions) {
//           if (promo.id == service.promotion!.id) {
//             found = true;
//             break;
//           }
//         }
//
//         if (!found) {
//           allPromotions.add(service.promotion!);
//         }
//       }
//
//       // Trier les promotions
//       _sortPromotions(allPromotions);
//
//       return {'promotions': allPromotions, 'error': null};
//     } catch (e) {
//       // En cas d'erreur, retourner au moins la promotion active
//       if (service.promotion != null) {
//         return {'promotions': [service.promotion!], 'error': 'Erreur partielle: $e'};
//       }
//
//       return {'promotions': [], 'error': 'Erreur: $e'};
//     }
//   }
//
//   // Vérifier si une promotion est active
//   static bool isPromotionActive(Promotion promotion) {
//     if (promotion.isActiveValue) return true;
//
//     final DateTime now = DateTime.now();
//     return now.isAfter(promotion.dateDebut) && now.isBefore(promotion.dateFin);
//   }
//
//   // Vérifier si une promotion est future
//   static bool isPromotionFuture(Promotion promotion) {
//     final DateTime now = DateTime.now();
//     return promotion.dateDebut.isAfter(now);
//   }
//
//   // Trier les promotions : actives d'abord, puis futures, puis passées
//   static void _sortPromotions(List<Promotion> promotions) {
//     promotions.sort((a, b) {
//       final bool aIsActive = isPromotionActive(a);
//       final bool bIsActive = isPromotionActive(b);
//
//       if (aIsActive && !bIsActive) return -1;
//       if (!aIsActive && bIsActive) return 1;
//
//       final bool aIsFuture = isPromotionFuture(a);
//       final bool bIsFuture = isPromotionFuture(b);
//
//       if (aIsFuture && !bIsFuture) return -1;
//       if (!aIsFuture && bIsFuture) return 1;
//
//       return a.dateDebut.compareTo(b.dateDebut);
//     });
//   }
// }