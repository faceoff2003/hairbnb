// Fichier: models/service_with_promo.dart
import 'package:hairbnb/models/promotion_full.dart';

class ServiceWithPromo {
  final int id;
  final String intitule;
  final String description;
  final int temps;
  final double prix;
  final int? categoryId;
  final String? categoryName;
  final int salonId;
  final String? salonNom;
  final PromotionFull? promotion_active;
  final List<PromotionFull> promotions_a_venir;
  final List<PromotionFull> promotions_expirees;
  final double prix_final;

  ServiceWithPromo({
    required this.id,
    required this.intitule,
    required this.description,
    required this.temps,
    required this.prix,
    this.categoryId,
    this.categoryName,
    required this.salonId,
    this.salonNom,
    this.promotion_active,
    required this.promotions_a_venir,
    required this.promotions_expirees,
    required this.prix_final,
  });

  double getPrixAvecReduction() => prix_final;
  double getMontantEconomise() => prix - prix_final;
  bool hasActivePromotion() => promotion_active != null;
  double? getCurrentDiscountPercentage() => promotion_active?.pourcentage;

  List<PromotionFull> getAllPromotions() {
    List<PromotionFull> allPromotions = [];
    if (promotion_active != null) {
      allPromotions.add(promotion_active!);
    }
    allPromotions.addAll(promotions_a_venir);
    allPromotions.addAll(promotions_expirees);
    return allPromotions;
  }

  int getTotalPromotionsCount() => getAllPromotions().length;
  bool hasFuturePromotions() => promotions_a_venir.isNotEmpty;

  PromotionFull? getNextPromotion() {
    if (promotions_a_venir.isEmpty) return null;
    promotions_a_venir.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
    return promotions_a_venir.first;
  }

  bool belongsToCategory(int categoryIdToCheck) => categoryId == categoryIdToCheck;
  bool hasCategory() => categoryId != null;
  bool belongsToSalon(int salonIdToCheck) => salonId == salonIdToCheck;

  // 🔥 MODIFICATION SIMPLE : Ajouter salonId optionnel en paramètre
  factory ServiceWithPromo.fromJson(Map<String, dynamic> json, {int? parentSalonId, String? parentSalonNom}) {
    PromotionFull? activePromo;
    List<PromotionFull> futurePromos = [];
    List<PromotionFull> expiredPromos = [];

    // 🔍 DEBUG - Affichage du JSON pour diagnostic
    print("🧩 ServiceWithPromo.fromJson - JSON reçu: $json");

    if (json['promotion_active'] != null) {
      try {
        activePromo = PromotionFull.fromJson(json['promotion_active']);
      } catch (e) {
        print('❌ Erreur promotion_active: $e');
      }
    }

    if (json['promotions_a_venir'] != null) {
      try {
        futurePromos = (json['promotions_a_venir'] as List)
            .map((promoJson) => PromotionFull.fromJson(promoJson))
            .toList();
      } catch (e) {
        print('❌ Erreur promotions_a_venir: $e');
      }
    }

    if (json['promotions_expirees'] != null) {
      try {
        expiredPromos = (json['promotions_expirees'] as List)
            .map((promoJson) => PromotionFull.fromJson(promoJson))
            .toList();
      } catch (e) {
        print('❌ Erreur promotions_expirees: $e');
      }
    }

    // 🔥 LOGIQUE SIMPLE : Utiliser parentSalonId si fourni, sinon chercher dans le JSON
    int finalSalonId;
    String? finalSalonNom;

    if (parentSalonId != null) {
      finalSalonId = parentSalonId;
      finalSalonNom = parentSalonNom;
    } else {
      finalSalonId = json['salon_id'] ?? json['idTblSalon'] ?? 0;
      finalSalonNom = json['salon_nom'] ?? json['nom_salon'];

      if (finalSalonId == 0) {
        print('⚠️ WARNING: Aucun salonId valide trouvé pour le service ${json['idTblService']}');
      }
    }

    // 🛡️ CORRECTION PRINCIPALE - Gestion robuste du temps
    int finalTemps = 0;

    // Essayer plusieurs noms de champs possibles pour la durée
    var tempsValue = json['temps_minutes'] ??
        json['temps'] ??
        json['duree'] ??
        json['duration'] ??
        json['duree_minutes'] ??
        json['temps_service'] ??
        json['duree_service'];

    if (tempsValue != null) {
      if (tempsValue is int) {
        finalTemps = tempsValue;
      } else if (tempsValue is String) {
        finalTemps = int.tryParse(tempsValue) ?? 0;
      } else {
        finalTemps = 0;
      }
    }

    // 🔍 DEBUG - Log des valeurs trouvées
    print("🕒 Temps pour service ${json['intitule_service'] ?? 'Unknown'}: $finalTemps minutes");
    print("   - Champs temps trouvés dans JSON: ${json.keys.where((k) => k.toLowerCase().contains('temps') || k.toLowerCase().contains('duree')).toList()}");

    // Si aucune durée trouvée, utiliser une valeur par défaut basée sur le type de service
    if (finalTemps <= 0) {
      String serviceName = (json['intitule_service'] ?? '').toLowerCase();

      // Estimation intelligente basée sur le nom du service
      if (serviceName.contains('coupe') || serviceName.contains('shampooing')) {
        finalTemps = 30;
      } else if (serviceName.contains('couleur') || serviceName.contains('coloration')) {
        finalTemps = 120;
      } else if (serviceName.contains('permanente') || serviceName.contains('lissage')) {
        finalTemps = 180;
      } else if (serviceName.contains('brushing')) {
        finalTemps = 45;
      } else if (serviceName.contains('massage')) {
        finalTemps = 60;
      } else {
        finalTemps = 45; // Valeur par défaut générale
      }

      print("⚠️ Temps non trouvé pour '${json['intitule_service']}', utilisation de $finalTemps min par défaut");
    }

    return ServiceWithPromo(
      id: json['idTblService'] ?? 0,
      intitule: json['intitule_service'] ?? '',
      description: json['description'] ?? '',
      temps: finalTemps, // 🛡️ Utilisation de la valeur calculée
      prix: json['prix'] != null ? double.tryParse(json['prix'].toString()) ?? 0.0 : 0.0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      salonId: finalSalonId,
      salonNom: finalSalonNom,
      promotion_active: activePromo,
      promotions_a_venir: futurePromos,
      promotions_expirees: expiredPromos,
      prix_final: json['prix_final'] != null ? double.tryParse(json['prix_final'].toString()) ?? 0.0 : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblService': id,
      'intitule_service': intitule,
      'description': description,
      'temps_minutes': temps,
      'prix': prix,
      'category_id': categoryId,
      'category_name': categoryName,
      'salon_id': salonId,
      'salon_nom': salonNom,
      'promotion_active': promotion_active?.toJson(),
      'promotions_a_venir': promotions_a_venir.map((p) => p.toJson()).toList(),
      'promotions_expirees': promotions_expirees.map((p) => p.toJson()).toList(),
      'prix_final': prix_final,
    };
  }

  ServiceWithPromo copyWith({
    int? id,
    String? intitule,
    String? description,
    int? temps,
    double? prix,
    int? categoryId,
    String? categoryName,
    int? salonId,
    String? salonNom,
    PromotionFull? promotion_active,
    List<PromotionFull>? promotions_a_venir,
    List<PromotionFull>? promotions_expirees,
    double? prix_final,
  }) {
    return ServiceWithPromo(
      id: id ?? this.id,
      intitule: intitule ?? this.intitule,
      description: description ?? this.description,
      temps: temps ?? this.temps,
      prix: prix ?? this.prix,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      salonId: salonId ?? this.salonId,
      salonNom: salonNom ?? this.salonNom,
      promotion_active: promotion_active ?? this.promotion_active,
      promotions_a_venir: promotions_a_venir ?? this.promotions_a_venir,
      promotions_expirees: promotions_expirees ?? this.promotions_expirees,
      prix_final: prix_final ?? this.prix_final,
    );
  }

  @override
  String toString() {
    return 'ServiceWithPromo(id: $id, intitule: $intitule, salonId: $salonId, prix: $prix, prix_final: $prix_final)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceWithPromo && other.id == id && other.salonId == salonId;
  }

  @override
  int get hashCode => id.hashCode ^ salonId.hashCode;
}
