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
      
      // 🔥 CORRECTION : Récupérer les informations du salon parent
      Map<String, dynamic> salonData;
      if (data.containsKey('results')) {
        salonData = data['results']['salon'];
      } else {
        salonData = data['salon'];
      }

      final int salonId = salonData['idTblSalon'] ?? salonData['id'] ?? 0;
      final String? salonNom = salonData['nom_salon'] ?? salonData['nom'] ?? salonData['name'];
      
      // 🔍 DEBUG
      print('🏢 Salon trouvé: ID=$salonId, Nom=$salonNom');
      
      final serviceList = salonData['services'] ?? [];
      
      // 🔥 CORRECTION : Passer salonId et salonNom lors du mapping
      final List<ServiceWithPromo> services = (serviceList as List)
          .map((json) => ServiceWithPromo.fromJson(
            json, 
            parentSalonId: salonId,
            parentSalonNom: salonNom
          ))
          .toList();

      return {
        'services': services,
        'totalCount': data['count'] ?? services.length,
        'error': null,
      };
    } catch (e) {
      print('❌ Erreur dans getServices: $e');
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
