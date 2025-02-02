import 'package:hairbnb/models/promotion.dart';

class Service {
  final int id;
  final String intitule;
  final String description;
  final double prix;
  final int temps;
  final Promotion? promotion; // Promotion peut être null
  final double prixFinal; // Prix après promotion

  Service({
    required this.id,
    required this.intitule,
    required this.description,
    required this.prix,
    required this.temps,
    this.promotion,
    required this.prixFinal,
  });

  /// **✅ Convertir une réponse JSON en objet Service**
  factory Service.fromJson(Map<String, dynamic> json) {
    print("DEBUG: JSON Service reçu: $json");

    // Conversion du prix
    double prixBase = 0.0;
    try {
      prixBase = (json['prix'] != null)
          ? double.parse(json['prix'].toString())
          : 0.0;
      print("DEBUG: Conversion prix: ${json['prix']} -> $prixBase");
    } catch (e) {
      print("❌ Erreur conversion prix: ${json['prix']}, error: $e");
    }

    // Vérification et conversion de la promotion
    Promotion? promo;
    if (json['promotion'] != null) {
      try {
        promo = Promotion.fromJson(json['promotion']);
        print("DEBUG: Conversion promotion réussie: ${json['promotion']}");
      } catch (e) {
        print("❌ ++Model services++ Erreur conversion Promotion : $e");
        promo = null;
      }
    } else {
      print("DEBUG: Aucun champ promotion présent dans le JSON.");
    }

    // Calcul du prix final avec réduction (si promotion existante)
    double prixReduit = (promo != null)
        ? prixBase * (1 - (promo.pourcentage / 100))
        : prixBase;
    print(
        "DEBUG: Calcul du prix final: prixBase = $prixBase, pourcentage = ${promo?.pourcentage}, prixFinal = $prixReduit");

    // Conversion de l'ID
    int idValue = 0;
    try {
      idValue = int.tryParse(json['idTblService']?.toString() ?? '0') ?? 0;
      print("DEBUG: Conversion id: ${json['id']} -> $idValue");
    } catch (e) {
      print("❌ Erreur conversion id: ${json['idTblService']}, error: $e");
    }

    // Conversion du temps (en minutes)
    int tempsValue = 0;
    try {
      tempsValue = int.tryParse(json['temps_minutes']?.toString() ?? '0') ?? 0;
      print("DEBUG: Conversion temps: ${json['temps_minutes']} -> $tempsValue");
    } catch (e) {
      print("❌ Erreur conversion temps: ${json['temps_minutes']}, error: $e");
    }

    return Service(
      id: idValue,
      intitule: json['intitule_service'] ?? 'Nom indisponible',
      description: json['description'] ?? 'Aucune description',
      prix: prixBase,
      temps: tempsValue,
      promotion: promo,
      prixFinal: prixReduit,
    );
  }

  /// **✅ Convertir un objet Service en JSON**
  Map<String, dynamic> toJson() {
    return {
      "intitule_service": intitule,
      "description": description,
      "prix": prix.toString(),
      "temps": temps.toString(),
      "promotion": promotion?.toJson(), // Inclure la promotion si présente
    };
  }

  /// **🔥 Retourne le prix après réduction si une promotion est active**
  double getPrixAvecReduction() {
    return prixFinal; // Utilisation du prix déjà calculé
  }
}







// import 'package:hairbnb/models/promotion.dart';
//
// class Service {
//   final int id;
//   final String intitule;
//   final String description;
//   final double prix;
//   final int temps;
//   final Promotion? promotion; // Promotion peut être null
//   final double prixFinal; // Prix après promotion
//
//   Service({
//     required this.id,
//     required this.intitule,
//     required this.description,
//     required this.prix,
//     required this.temps,
//     this.promotion,
//     required this.prixFinal,
//   });
//
//   /// **✅ Convertir une réponse JSON en objet Service**
//   factory Service.fromJson(Map<String, dynamic> json) {
//     double prixBase = (json['prix'] != null) ? double.parse(json['prix'].toString()) : 0.0;
//
//     // 🔥 Vérification si la promotion existe avant de la traiter
//     Promotion? promo;
//     if (json['promotion'] != null) {
//       try {
//         promo = Promotion.fromJson(json['promotion']);
//       } catch (e) {
//         //----------------------------------------------------------------------
//         print("❌ ++Model services++ Erreur conversion Promotion : $e");
//         //----------------------------------------------------------------------
//         //print("❌ Erreur conversion Promotion : $e");
//         promo = null;
//       }
//     }
//
//     // ✅ Calcul du prix final avec réduction (si promotion existante)
//     double prixReduit = (promo != null) ? prixBase * (1 - (promo.pourcentage / 100)) : prixBase;
//
//     return Service(
//       //id: json['idTblService'] ?? 0,
//       id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
//       intitule: json['intitule_service'] ?? 'Nom indisponible',
//       description: json['description'] ?? 'Aucune description',
//       prix: prixBase,
//       temps: json['temps_minutes'] ?? 0,
//       promotion: promo,
//       prixFinal: prixReduit, // Applique la réduction si nécessaire
//     );
//   }
//
//   /// **✅ Convertir un objet Service en JSON**
//   Map<String, dynamic> toJson() {
//     return {
//       "intitule_service": intitule,
//       "description": description,
//       "prix": prix.toString(),
//       "temps": temps.toString(),
//       "promotion": promotion?.toJson(), // Inclure la promotion si présente
//     };
//   }
//
//   /// **🔥 Retourne le prix après réduction si une promotion est active**
//   double getPrixAvecReduction() {
//     return prixFinal; // Utilisation du prix déjà calculé
//   }
// }

















// import 'package:flutter/cupertino.dart';
// import 'package:hairbnb/models/promotion.dart';
//
// class Service {
//   final int id;
//   final String intitule;
//   final String description;
//   final double prix;
//   final int temps;
//   final Promotion? promotion; // Ajout de la promotion (peut être null)
//   final double prixFinal; // Prix après application de la réduction
//
//   Service({
//     required this.id,
//     required this.intitule,
//     required this.description,
//     required this.prix,
//     required this.temps,
//     this.promotion,
//     required this.prixFinal, // Nouveau champ pour stocker le prix final
//   });
//
//   /// **✅ Convertir une réponse JSON en objet Service**
//   factory Service.fromJson(Map<String, dynamic> json) {
//     debugPrint("🔍 Conversion JSON -> Service : $json"); // ✅ Debug
//
//     try {
//       // ✅ Vérifie que prix est bien un nombre
//       double prixBase = (json['prix'] != null) ? double.parse(
//           json['prix'].toString()) : 0.0;
//
//       // ✅ Vérifie la présence de la promotion
//       Promotion? promo;
//       if (json.containsKey('promotion') && json['promotion'] != null) {
//         try {
//           promo = Promotion.fromJson(json['promotion']);
//         } catch (e) {
//           debugPrint("❌ Erreur conversion Promotion : $e");
//           promo = null;
//         }
//       } else {
//         promo = null;
//       }
//
//       // ✅ Calcule le prix final avec la promo
//       double prixReduit = (promo != null) ? prixBase *
//           (1 - (promo.pourcentage / 100)) : prixBase;
//
//       return Service(
//         id: json['idTblService'] ?? 0,
//         intitule: json['intitule_service'] ?? 'Nom indisponible',
//         description: json['description'] ?? 'Aucune description',
//         prix: prixBase,
//         temps: json['temps_minutes'] ?? 0,
//         promotion: promo,
//         prixFinal: prixReduit, // ✅ Applique la réduction si nécessaire
//       );
//     } catch (e) {
//       debugPrint("❌ Erreur Service.fromJson : $e");
//       return Service(
//         id: 0,
//         intitule: "Erreur",
//         description: "Impossible de charger ce service",
//         prix: 0.0,
//         temps: 0,
//         prixFinal: 0.0,
//       );
//     }
//   }
// // ✅ Convertir un objet Service en JSON (pour les requêtes POST)
//   Map<String, dynamic> toJson() {
//     return {
//       "intitule_service": intitule,
//       "description": description,
//       "prix": prix.toString(),
//       // Convertir en String pour éviter les erreurs de JSON
//       "temps": temps.toString(),
//       "promotion": promotion?.toJson(),
//       // Idem
//     };
//   }
//
//   /// 🔥 Retourne le prix après réduction si une promotion est active.
//   double getPrixAvecReduction() {
//     if (promotion != null) {
//       return prix - (prix * promotion!.pourcentage / 100);
//     }
//     return prix;
//   }
// }











// import 'package:hairbnb/models/promotion.dart';
//
// class Service {
//   final int id;
//   final String intitule;
//   final String description;
//   final double prix;
//   final int temps;
//   final Promotion? promotion; // Ajout de la promotion (peut être null)
//
//   Service({
//     required this.id,
//     required this.intitule,
//     required this.description,
//     required this.prix,
//     required this.temps,
//     this.promotion,
//   });
//
//   // Convertir une réponse JSON en objet ServiceModel
//   factory Service.fromJson(Map<String, dynamic> json) {
//     return Service(
//       id: json['idTblService'] ?? 0,
//       intitule: json['intitule_service'] ?? 'Nom indisponible',
//       description: json['description'] ?? 'Aucune description',
//       prix: (json['prix'] != null)
//           ? double.parse(json['prix'].toString())
//           : 0.0,
//       temps: json['temps_minutes'] ?? 0,
//       promotion: json['promotion'] != null ? Promotion.fromJson(json['promotion']) : null,
//     );
//   }
//
// // ✅ Convertir un objet Service en JSON (pour les requêtes POST)
//   Map<String, dynamic> toJson() {
//     return {
//       "intitule_service": intitule,
//       "description": description,
//       "prix": prix.toString(),
//       // Convertir en String pour éviter les erreurs de JSON
//       "temps": temps.toString(),
//       "promotion": promotion?.toJson(),
//       // Idem
//     };
//   }
//
//   /// 🔥 Retourne le prix après réduction si une promotion est active.
//   double getPrixAvecReduction() {
//     if (promotion != null) {
//       return prix - (prix * promotion!.pourcentage / 100);
//     }
//     return prix;
//   }
// }
