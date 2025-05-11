// Fichier: models/services.dart

import 'package:hairbnb/models/promotion_full.dart';

class ServiceWithPromo {
  final int id;
  final String intitule;
  final String description;
  final int temps;
  final double prix;
  final PromotionFull? promotion_active; // Promotion active (ou null)
  final List<PromotionFull> promotions_a_venir; // Liste des promotions à venir
  final List<PromotionFull> promotions_expirees; // Liste des promotions expirées
  final double prix_final; // Prix avec réduction si promotion active

  ServiceWithPromo({
    required this.id,
    required this.intitule,
    required this.description,
    required this.temps,
    required this.prix,
    this.promotion_active,
    required this.promotions_a_venir,
    required this.promotions_expirees,
    required this.prix_final,
  });

  // Méthode pour obtenir le prix avec réduction si une promotion est active
  double getPrixAvecReduction() {
    return prix_final;
  }

  // Méthode pour obtenir toutes les promotions (active + à venir + expirées)
  List<PromotionFull> getAllPromotions() {
    List<PromotionFull> allPromotions = [];
    if (promotion_active != null) {
      allPromotions.add(promotion_active!);
    }
    allPromotions.addAll(promotions_a_venir);
    allPromotions.addAll(promotions_expirees);
    return allPromotions;
  }

  factory ServiceWithPromo.fromJson(Map<String, dynamic> json) {
    PromotionFull? activePromo;
    List<PromotionFull> futurePromos = [];
    List<PromotionFull> expiredPromos = [];

    // Traiter la promotion active si elle existe
    if (json['promotion_active'] != null) {
      activePromo = PromotionFull.fromJson(json['promotion_active']);
    }

    // Traiter les promotions à venir
    if (json['promotions_a_venir'] != null) {
      futurePromos = (json['promotions_a_venir'] as List)
          .map((promoJson) => PromotionFull.fromJson(promoJson))
          .toList();
    }

    // Traiter les promotions expirées
    if (json['promotions_expirees'] != null) {
      expiredPromos = (json['promotions_expirees'] as List)
          .map((promoJson) => PromotionFull.fromJson(promoJson))
          .toList();
    }

    return ServiceWithPromo(
      id: json['idTblService'],
      intitule: json['intitule_service'],
      description: json['description'] ?? '',
      temps: json['temps_minutes'] ?? 0,
      prix: json['prix'] != null ? double.parse(json['prix'].toString()) : 0.0,
      promotion_active: activePromo,
      promotions_a_venir: futurePromos,
      promotions_expirees: expiredPromos,
      prix_final: json['prix_final'] != null ? double.parse(json['prix_final'].toString()) : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblService': id,
      'intitule_service': intitule,
      'description': description,
      'temps_minutes': temps,
      'prix': prix,
      'promotion_active': promotion_active?.toJson(),
      'promotions_a_venir': promotions_a_venir.map((p) => p.toJson()).toList(),
      'promotions_expirees': promotions_expirees.map((p) => p.toJson()).toList(),
      'prix_final': prix_final,
    };
  }
}