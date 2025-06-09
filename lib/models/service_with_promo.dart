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
      // Utiliser le salonId du parent (recommandé)
      finalSalonId = parentSalonId;
      finalSalonNom = parentSalonNom;
    } else {
      // Fallback : chercher dans le JSON du service
      finalSalonId = json['salon_id'] ?? json['idTblSalon'] ?? 0;
      finalSalonNom = json['salon_nom'] ?? json['nom_salon'];

      if (finalSalonId == 0) {
        print('⚠️ WARNING: Aucun salonId valide trouvé pour le service ${json['idTblService']}');
      }
    }

    return ServiceWithPromo(
      id: json['idTblService'] ?? 0,
      intitule: json['intitule_service'] ?? '',
      description: json['description'] ?? '',
      temps: json['temps_minutes'] ?? 0,
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












// // Fichier: models/service_with_promo.dart
// import 'package:hairbnb/models/promotion_full.dart';
//
// class ServiceWithPromo {
//   final int id;
//   final String intitule;
//   final String description;
//   final int temps;
//   final double prix;
//   final int? categoryId;
//   final String? categoryName;
//   final int salonId;
//   final String? salonNom;
//   final PromotionFull? promotion_active;
//   final List<PromotionFull> promotions_a_venir;
//   final List<PromotionFull> promotions_expirees;
//   final double prix_final;
//
//   ServiceWithPromo({
//     required this.id,
//     required this.intitule,
//     required this.description,
//     required this.temps,
//     required this.prix,
//     this.categoryId,
//     this.categoryName,
//     required this.salonId,
//     this.salonNom,
//     this.promotion_active,
//     required this.promotions_a_venir,
//     required this.promotions_expirees,
//     required this.prix_final,
//   });
//
//   double getPrixAvecReduction() => prix_final;
//   double getMontantEconomise() => prix - prix_final;
//   bool hasActivePromotion() => promotion_active != null;
//   double? getCurrentDiscountPercentage() => promotion_active?.pourcentage;
//
//   List<PromotionFull> getAllPromotions() {
//     List<PromotionFull> allPromotions = [];
//     if (promotion_active != null) {
//       allPromotions.add(promotion_active!);
//     }
//     allPromotions.addAll(promotions_a_venir);
//     allPromotions.addAll(promotions_expirees);
//     return allPromotions;
//   }
//
//   int getTotalPromotionsCount() => getAllPromotions().length;
//   bool hasFuturePromotions() => promotions_a_venir.isNotEmpty;
//
//   PromotionFull? getNextPromotion() {
//     if (promotions_a_venir.isEmpty) return null;
//     promotions_a_venir.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
//     return promotions_a_venir.first;
//   }
//
//   bool belongsToCategory(int categoryIdToCheck) => categoryId == categoryIdToCheck;
//   bool hasCategory() => categoryId != null;
//   bool belongsToSalon(int salonIdToCheck) => salonId == salonIdToCheck;
//
//   // 🔥 MODIFICATION SIMPLE : Ajouter salonId optionnel en paramètre
//   factory ServiceWithPromo.fromJson(Map<String, dynamic> json, {int? parentSalonId, String? parentSalonNom}) {
//     PromotionFull? activePromo;
//     List<PromotionFull> futurePromos = [];
//     List<PromotionFull> expiredPromos = [];
//
//     if (json['promotion_active'] != null) {
//       try {
//         activePromo = PromotionFull.fromJson(json['promotion_active']);
//       } catch (e) {
//         print('❌ Erreur promotion_active: $e');
//       }
//     }
//
//     if (json['promotions_a_venir'] != null) {
//       try {
//         futurePromos = (json['promotions_a_venir'] as List)
//             .map((promoJson) => PromotionFull.fromJson(promoJson))
//             .toList();
//       } catch (e) {
//         print('❌ Erreur promotions_a_venir: $e');
//       }
//     }
//
//     if (json['promotions_expirees'] != null) {
//       try {
//         expiredPromos = (json['promotions_expirees'] as List)
//             .map((promoJson) => PromotionFull.fromJson(promoJson))
//             .toList();
//       } catch (e) {
//         print('❌ Erreur promotions_expirees: $e');
//       }
//     }
//
//     // 🔥 LOGIQUE SIMPLE : Utiliser parentSalonId si fourni, sinon chercher dans le JSON
//     int finalSalonId;
//     String? finalSalonNom;
//
//     if (parentSalonId != null) {
//       // Utiliser le salonId du parent (recommandé)
//       finalSalonId = parentSalonId;
//       finalSalonNom = parentSalonNom;
//     } else {
//       // Fallback : chercher dans le JSON du service
//       finalSalonId = json['salon_id'] ?? json['idTblSalon'] ?? 0;
//       finalSalonNom = json['salon_nom'] ?? json['nom_salon'];
//
//       if (finalSalonId == 0) {
//         print('⚠️ WARNING: Aucun salonId valide trouvé pour le service ${json['idTblService']}');
//       }
//     }
//
//     return ServiceWithPromo(
//       id: json['idTblService'] ?? 0,
//       intitule: json['intitule_service'] ?? '',
//       description: json['description'] ?? '',
//       temps: json['temps_minutes'] ?? 0,
//       prix: json['prix'] != null ? double.tryParse(json['prix'].toString()) ?? 0.0 : 0.0,
//       categoryId: json['category_id'],
//       categoryName: json['category_name'],
//       salonId: finalSalonId,
//       salonNom: finalSalonNom,
//       promotion_active: activePromo,
//       promotions_a_venir: futurePromos,
//       promotions_expirees: expiredPromos,
//       prix_final: json['prix_final'] != null ? double.tryParse(json['prix_final'].toString()) ?? 0.0 : 0.0,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblService': id,
//       'intitule_service': intitule,
//       'description': description,
//       'temps_minutes': temps,
//       'prix': prix,
//       'category_id': categoryId,
//       'category_name': categoryName,
//       'salon_id': salonId,
//       'salon_nom': salonNom,
//       'promotion_active': promotion_active?.toJson(),
//       'promotions_a_venir': promotions_a_venir.map((p) => p.toJson()).toList(),
//       'promotions_expirees': promotions_expirees.map((p) => p.toJson()).toList(),
//       'prix_final': prix_final,
//     };
//   }
//
//   ServiceWithPromo copyWith({
//     int? id,
//     String? intitule,
//     String? description,
//     int? temps,
//     double? prix,
//     int? categoryId,
//     String? categoryName,
//     int? salonId,
//     String? salonNom,
//     PromotionFull? promotion_active,
//     List<PromotionFull>? promotions_a_venir,
//     List<PromotionFull>? promotions_expirees,
//     double? prix_final,
//   }) {
//     return ServiceWithPromo(
//       id: id ?? this.id,
//       intitule: intitule ?? this.intitule,
//       description: description ?? this.description,
//       temps: temps ?? this.temps,
//       prix: prix ?? this.prix,
//       categoryId: categoryId ?? this.categoryId,
//       categoryName: categoryName ?? this.categoryName,
//       salonId: salonId ?? this.salonId,
//       salonNom: salonNom ?? this.salonNom,
//       promotion_active: promotion_active ?? this.promotion_active,
//       promotions_a_venir: promotions_a_venir ?? this.promotions_a_venir,
//       promotions_expirees: promotions_expirees ?? this.promotions_expirees,
//       prix_final: prix_final ?? this.prix_final,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'ServiceWithPromo(id: $id, intitule: $intitule, salonId: $salonId, prix: $prix, prix_final: $prix_final)';
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is ServiceWithPromo && other.id == id && other.salonId == salonId;
//   }
//
//   @override
//   int get hashCode => id.hashCode ^ salonId.hashCode;
// }
//
//
//
//
//
//
//
//
//
//
//
// // // Fichier: models/services.dart
// // import 'package:hairbnb/models/promotion_full.dart';
// //
// // class ServiceWithPromo {
// //   final int id;
// //   final String intitule;
// //   final String description;
// //   final int temps;
// //   final double prix;
// //   final int? categoryId;
// //   final String? categoryName;
// //   final int salonId; // 🔥 NOUVEAU : ID du salon (obligatoire maintenant)
// //   final String? salonNom; // 🔥 NOUVEAU : Nom du salon (optionnel pour affichage)
// //   final PromotionFull? promotion_active; // Promotion active (ou null)
// //   final List<PromotionFull> promotions_a_venir; // Liste des promotions à venir
// //   final List<PromotionFull> promotions_expirees; // Liste des promotions expirées
// //   final double prix_final; // Prix avec réduction si promotion active
// //
// //   ServiceWithPromo({
// //     required this.id,
// //     required this.intitule,
// //     required this.description,
// //     required this.temps,
// //     required this.prix,
// //     this.categoryId,
// //     this.categoryName,
// //     required this.salonId, // 🔥 NOUVEAU : Obligatoire
// //     this.salonNom, // 🔥 NOUVEAU : Optionnel
// //     this.promotion_active,
// //     required this.promotions_a_venir,
// //     required this.promotions_expirees,
// //     required this.prix_final,
// //   });
// //
// //   // Méthode pour obtenir le prix avec réduction si une promotion est active
// //   double getPrixAvecReduction() {
// //     return prix_final;
// //   }
// //
// //   // 🔥 NOUVEAU : Méthode pour obtenir le montant économisé
// //   double getMontantEconomise() {
// //     return prix - prix_final;
// //   }
// //
// //   // 🔥 NOUVEAU : Méthode pour vérifier si le service a une promotion active
// //   bool hasActivePromotion() {
// //     return promotion_active != null;
// //   }
// //
// //   // 🔥 NOUVEAU : Méthode pour obtenir le pourcentage de réduction actuel
// //   double? getCurrentDiscountPercentage() {
// //     return promotion_active?.pourcentage;
// //   }
// //
// //   // Méthode pour obtenir toutes les promotions (active + à venir + expirées)
// //   List<PromotionFull> getAllPromotions() {
// //     List<PromotionFull> allPromotions = [];
// //     if (promotion_active != null) {
// //       allPromotions.add(promotion_active!);
// //     }
// //     allPromotions.addAll(promotions_a_venir);
// //     allPromotions.addAll(promotions_expirees);
// //     return allPromotions;
// //   }
// //
// //   // 🔥 AMÉLIORATION : Méthode pour obtenir le nombre total de promotions
// //   int getTotalPromotionsCount() {
// //     return getAllPromotions().length;
// //   }
// //
// //   // 🔥 NOUVEAU : Méthode pour vérifier s'il y a des promotions à venir
// //   bool hasFuturePromotions() {
// //     return promotions_a_venir.isNotEmpty;
// //   }
// //
// //   // 🔥 NOUVEAU : Méthode pour obtenir la prochaine promotion
// //   PromotionFull? getNextPromotion() {
// //     if (promotions_a_venir.isEmpty) return null;
// //
// //     // Trier par date de début et retourner la première
// //     promotions_a_venir.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
// //     return promotions_a_venir.first;
// //   }
// //
// //   // Méthode pour vérifier si le service appartient à une catégorie
// //   bool belongsToCategory(int categoryIdToCheck) {
// //     return categoryId == categoryIdToCheck;
// //   }
// //
// //   // Méthode pour vérifier si le service a une catégorie
// //   bool hasCategory() {
// //     return categoryId != null;
// //   }
// //
// //   // 🔥 NOUVEAU : Méthode pour vérifier si le service appartient à un salon
// //   bool belongsToSalon(int salonIdToCheck) {
// //     return salonId == salonIdToCheck;
// //   }
// //
// //   factory ServiceWithPromo.fromJson(Map<String, dynamic> json) {
// //     PromotionFull? activePromo;
// //     List<PromotionFull> futurePromos = [];
// //     List<PromotionFull> expiredPromos = [];
// //
// //     // Traiter la promotion active si elle existe
// //     if (json['promotion_active'] != null) {
// //       activePromo = PromotionFull.fromJson(json['promotion_active']);
// //     }
// //
// //     // Traiter les promotions à venir
// //     if (json['promotions_a_venir'] != null) {
// //       futurePromos = (json['promotions_a_venir'] as List)
// //           .map((promoJson) => PromotionFull.fromJson(promoJson))
// //           .toList();
// //     }
// //
// //     // Traiter les promotions expirées
// //     if (json['promotions_expirees'] != null) {
// //       expiredPromos = (json['promotions_expirees'] as List)
// //           .map((promoJson) => PromotionFull.fromJson(promoJson))
// //           .toList();
// //     }
// //
// //     return ServiceWithPromo(
// //       id: json['idTblService'],
// //       intitule: json['intitule_service'],
// //       description: json['description'] ?? '',
// //       temps: json['temps_minutes'] ?? 0,
// //       prix: json['prix'] != null ? double.parse(json['prix'].toString()) : 0.0,
// //       categoryId: json['category_id'],
// //       categoryName: json['category_name'],
// //       salonId: json['salon_id'] ?? json['idTblSalon'], // 🔥 NOUVEAU : Support des deux formats
// //       salonNom: json['salon_nom'] ?? json['nom_salon'], // 🔥 NOUVEAU : Support des deux formats
// //       promotion_active: activePromo,
// //       promotions_a_venir: futurePromos,
// //       promotions_expirees: expiredPromos,
// //       prix_final: json['prix_final'] != null ? double.parse(json['prix_final'].toString()) : 0.0,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'idTblService': id,
// //       'intitule_service': intitule,
// //       'description': description,
// //       'temps_minutes': temps,
// //       'prix': prix,
// //       'category_id': categoryId,
// //       'category_name': categoryName,
// //       'salon_id': salonId, // 🔥 NOUVEAU
// //       'salon_nom': salonNom, // 🔥 NOUVEAU
// //       'promotion_active': promotion_active?.toJson(),
// //       'promotions_a_venir': promotions_a_venir.map((p) => p.toJson()).toList(),
// //       'promotions_expirees': promotions_expirees.map((p) => p.toJson()).toList(),
// //       'prix_final': prix_final,
// //     };
// //   }
// //
// //   // 🔥 NOUVEAU : Méthode pour créer une copie avec des modifications
// //   ServiceWithPromo copyWith({
// //     int? id,
// //     String? intitule,
// //     String? description,
// //     int? temps,
// //     double? prix,
// //     int? categoryId,
// //     String? categoryName,
// //     int? salonId,
// //     String? salonNom,
// //     PromotionFull? promotion_active,
// //     List<PromotionFull>? promotions_a_venir,
// //     List<PromotionFull>? promotions_expirees,
// //     double? prix_final,
// //   }) {
// //     return ServiceWithPromo(
// //       id: id ?? this.id,
// //       intitule: intitule ?? this.intitule,
// //       description: description ?? this.description,
// //       temps: temps ?? this.temps,
// //       prix: prix ?? this.prix,
// //       categoryId: categoryId ?? this.categoryId,
// //       categoryName: categoryName ?? this.categoryName,
// //       salonId: salonId ?? this.salonId,
// //       salonNom: salonNom ?? this.salonNom,
// //       promotion_active: promotion_active ?? this.promotion_active,
// //       promotions_a_venir: promotions_a_venir ?? this.promotions_a_venir,
// //       promotions_expirees: promotions_expirees ?? this.promotions_expirees,
// //       prix_final: prix_final ?? this.prix_final,
// //     );
// //   }
// //
// //   // 🔥 NOUVEAU : Override toString pour un debug plus facile
// //   @override
// //   String toString() {
// //     return 'ServiceWithPromo(id: $id, intitule: $intitule, salonId: $salonId, prix: $prix, prix_final: $prix_final, hasActivePromo: ${hasActivePromotion()})';
// //   }
// //
// //   // 🔥 NOUVEAU : Override equality et hashCode
// //   @override
// //   bool operator ==(Object other) {
// //     if (identical(this, other)) return true;
// //     return other is ServiceWithPromo &&
// //         other.id == id &&
// //         other.salonId == salonId;
// //   }
// //
// //   @override
// //   int get hashCode => id.hashCode ^ salonId.hashCode;
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// // // // Fichier: models/services.dart
// // // import 'package:hairbnb/models/promotion_full.dart';
// // //
// // // class ServiceWithPromo {
// // //   final int id;
// // //   final String intitule;
// // //   final String description;
// // //   final int temps;
// // //   final double prix;
// // //   final int? categoryId;
// // //   final String? categoryName;
// // //   final PromotionFull? promotion_active; // Promotion active (ou null)
// // //   final List<PromotionFull> promotions_a_venir; // Liste des promotions à venir
// // //   final List<PromotionFull> promotions_expirees; // Liste des promotions expirées
// // //   final double prix_final; // Prix avec réduction si promotion active
// // //
// // //   ServiceWithPromo({
// // //     required this.id,
// // //     required this.intitule,
// // //     required this.description,
// // //     required this.temps,
// // //     required this.prix,
// // //     this.categoryId,
// // //     this.categoryName,
// // //     this.promotion_active,
// // //     required this.promotions_a_venir,
// // //     required this.promotions_expirees,
// // //     required this.prix_final,
// // //   });
// // //
// // //   // Méthode pour obtenir le prix avec réduction si une promotion est active
// // //   double getPrixAvecReduction() {
// // //     return prix_final;
// // //   }
// // //
// // //   // Méthode pour obtenir toutes les promotions (active + à venir + expirées)
// // //   List<PromotionFull> getAllPromotions() {
// // //     List<PromotionFull> allPromotions = [];
// // //     if (promotion_active != null) {
// // //       allPromotions.add(promotion_active!);
// // //     }
// // //     allPromotions.addAll(promotions_a_venir);
// // //     allPromotions.addAll(promotions_expirees);
// // //     return allPromotions;
// // //   }
// // //
// // //   // Méthode pour vérifier si le service appartient à une catégorie
// // //   bool belongsToCategory(int categoryIdToCheck) {
// // //     return categoryId == categoryIdToCheck;
// // //   }
// // //
// // //   // Méthode pour vérifier si le service a une catégorie
// // //   bool hasCategory() {
// // //     return categoryId != null;
// // //   }
// // //
// // //   factory ServiceWithPromo.fromJson(Map<String, dynamic> json) {
// // //     PromotionFull? activePromo;
// // //     List<PromotionFull> futurePromos = [];
// // //     List<PromotionFull> expiredPromos = [];
// // //
// // //     // Traiter la promotion active si elle existe
// // //     if (json['promotion_active'] != null) {
// // //       activePromo = PromotionFull.fromJson(json['promotion_active']);
// // //     }
// // //
// // //     // Traiter les promotions à venir
// // //     if (json['promotions_a_venir'] != null) {
// // //       futurePromos = (json['promotions_a_venir'] as List)
// // //           .map((promoJson) => PromotionFull.fromJson(promoJson))
// // //           .toList();
// // //     }
// // //
// // //     // Traiter les promotions expirées
// // //     if (json['promotions_expirees'] != null) {
// // //       expiredPromos = (json['promotions_expirees'] as List)
// // //           .map((promoJson) => PromotionFull.fromJson(promoJson))
// // //           .toList();
// // //     }
// // //
// // //     return ServiceWithPromo(
// // //       id: json['idTblService'],
// // //       intitule: json['intitule_service'],
// // //       description: json['description'] ?? '',
// // //       temps: json['temps_minutes'] ?? 0,
// // //       prix: json['prix'] != null ? double.parse(json['prix'].toString()) : 0.0,
// // //       categoryId: json['category_id'],
// // //       categoryName: json['category_name'],
// // //       promotion_active: activePromo,
// // //       promotions_a_venir: futurePromos,
// // //       promotions_expirees: expiredPromos,
// // //       prix_final: json['prix_final'] != null ? double.parse(json['prix_final'].toString()) : 0.0,
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'idTblService': id,
// // //       'intitule_service': intitule,
// // //       'description': description,
// // //       'temps_minutes': temps,
// // //       'prix': prix,
// // //       'category_id': categoryId,
// // //       'category_name': categoryName,
// // //       'promotion_active': promotion_active?.toJson(),
// // //       'promotions_a_venir': promotions_a_venir.map((p) => p.toJson()).toList(),
// // //       'promotions_expirees': promotions_expirees.map((p) => p.toJson()).toList(),
// // //       'prix_final': prix_final,
// // //     };
// // //   }
// // // }