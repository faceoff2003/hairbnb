class Promotion {
  final int id;
  final int serviceId;
  final double pourcentage;
  final DateTime dateDebut;
  final DateTime dateFin;
  final bool isActiveValue; // Nouvelle propriété

  Promotion({
    required this.id,
    required this.serviceId,
    required this.pourcentage,
    required this.dateDebut,
    required this.dateFin,
    this.isActiveValue = true, // Par défaut à true pour les nouvelles promotions
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    print("DEBUG: Promotion JSON: $json"); // Pour vérifier le contenu du JSON
    return Promotion(
      id: int.tryParse(json['idPromotion']?.toString() ?? '') ?? 0,
      serviceId: int.tryParse(json['service_id']?.toString() ?? '') ?? 0,
      pourcentage: double.tryParse(json['discount_percentage']?.toString() ?? '') ?? 0.0,
      dateDebut: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      dateFin: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      isActiveValue: json['is_active'] == true, // Utiliser directement la valeur du backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "idPromotion": id,
      "service_id": serviceId,
      "discount_percentage": pourcentage,
      "start_date": dateDebut.toIso8601String().split('T')[0], // Envoyer uniquement la date
      "end_date": dateFin.toIso8601String().split('T')[0],     // Envoyer uniquement la date
    };
  }

  /// Utilise directement la valeur du backend si disponible
  bool isActive() {
    return isActiveValue;
  }
}




// class Promotion {
//   final int id;
//   final int serviceId;
//   final double pourcentage; // Même si on garde le nom "pourcentage" en interne
//   final DateTime dateDebut;
//   final DateTime dateFin;
//
//   Promotion({
//     required this.id,
//     required this.serviceId,
//     required this.pourcentage,
//     required this.dateDebut,
//     required this.dateFin,
//   });
//
//   // Convertir JSON vers Promotion
//   factory Promotion.fromJson(Map<String, dynamic> json) {
//     print("DEBUG: Promotion JSON: $json"); // Pour vérifier le contenu du JSON
//     return Promotion(
//       // Utilise les clés du JSON telles qu'elles sont
//       id: int.tryParse(json['idPromotion']?.toString() ?? '') ?? 0,
//       serviceId: int.tryParse(json['service_id']?.toString() ?? '') ?? 0,
//       // Ici on récupère la valeur depuis "discount_percentage"
//       pourcentage: double.tryParse(json['discount_percentage']?.toString() ?? '') ?? 0.0,
//       dateDebut: json['start_date'] != null
//           ? DateTime.parse(json['start_date'])
//           : DateTime.now(),
//       dateFin: json['end_date'] != null
//           ? DateTime.parse(json['end_date'])
//           : DateTime.now(),
//     );
//   }
//
//   // Convertir Promotion vers JSON
//   Map<String, dynamic> toJson() {
//     return {
//       "idPromotion": id,
//       "service_id": serviceId,
//       "discount_percentage": pourcentage,
//       "start_date": dateDebut.toIso8601String(),
//       "end_date": dateFin.toIso8601String(),
//     };
//   }
//
//   /// Vérifie si la promotion est encore valide
//   bool isActive() {
//     // On ne compare que les dates sans l'heure
//     final DateTime nowDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
//     final DateTime debutDate = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
//     final DateTime finDate = DateTime(dateFin.year, dateFin.month, dateFin.day);
//
//     // Déboguer
//     print("Vérification promotion: Aujourd'hui=$nowDate, Début=$debutDate, Fin=$finDate");
//     print("Comparaisons: nowDate >= debutDate: ${nowDate.isAtSameMomentAs(debutDate) || nowDate.isAfter(debutDate)}");
//     print("Comparaisons: nowDate <= finDate: ${nowDate.isAtSameMomentAs(finDate) || nowDate.isBefore(finDate)}");
//
//     // Une promotion est active si aujourd'hui est entre la date de début et la date de fin (incluses)
//     return (nowDate.isAtSameMomentAs(debutDate) || nowDate.isAfter(debutDate)) &&
//         (nowDate.isAtSameMomentAs(finDate) || nowDate.isBefore(finDate));
//   }
// ///
//   // bool isActive() {
//   //   DateTime now = DateTime.now();
//   //   return now.isAfter(dateDebut) && now.isBefore(dateFin);
//   // }
// }








// class Promotion {
//   final int id;
//   final int serviceId;
//   final double pourcentage;
//   final DateTime dateDebut;
//   final DateTime dateFin;
//
//   Promotion({
//     required this.id,
//     required this.serviceId,
//     required this.pourcentage,
//     required this.dateDebut,
//     required this.dateFin,
//   });
//
//   // Convertir JSON vers Promotion
//   factory Promotion.fromJson(Map<String, dynamic> json) {
//     return Promotion(
//       // Vous pouvez ajouter des vérifications pour id et serviceId si besoin
//       id: json['id'],
//       serviceId: json['service_id'],
//       // Convertit le pourcentage en double, avec 0.0 comme valeur par défaut si nécessaire
//       pourcentage: double.tryParse(json['discount_percentage']?.toString() ?? '') ?? 0.0,
//       dateDebut: DateTime.parse(json['date_debut']),
//       dateFin: DateTime.parse(json['date_fin']),
//     );
//   }
//
//   // Convertir Promotion vers JSON
//   Map<String, dynamic> toJson() {
//     return {
//       "id": id,
//       "service_id": serviceId,
//       "discount_percentage": pourcentage,
//       "date_debut": dateDebut.toIso8601String(),
//       "date_fin": dateFin.toIso8601String(),
//     };
//   }
//
//   /// Vérifie si la promotion est encore valide
//   bool isActive() {
//     DateTime now = DateTime.now();
//     return now.isAfter(dateDebut) && now.isBefore(dateFin);
//   }
// }










// class Promotion {
//   final int id;
//   final int serviceId;
//   final double pourcentage;
//   final DateTime dateDebut;
//   final DateTime dateFin;
//
//   Promotion({
//     required this.id,
//     required this.serviceId,
//     required this.pourcentage,
//     required this.dateDebut,
//     required this.dateFin,
//   });
//
//   // Convertir JSON vers PromotionModel
//   factory Promotion.fromJson(Map<String, dynamic> json) {
//     return Promotion(
//       id: json['id'],
//       serviceId: json['service_id'],
//       pourcentage: (json['pourcentage'] as num).toDouble(),
//       dateDebut: DateTime.parse(json['date_debut']),
//       dateFin: DateTime.parse(json['date_fin']),
//     );
//   }
//
//   // Convertir PromotionModel vers JSON
//   Map<String, dynamic> toJson() {
//     return {
//       "id": id,
//       "service_id": serviceId,
//       "pourcentage": pourcentage,
//       "date_debut": dateDebut.toIso8601String(),
//       "date_fin": dateFin.toIso8601String(),
//     };
//   }
//
//   /// Vérifie si la promotion est encore valide
//   bool isActive() {
//     DateTime now = DateTime.now();
//     return now.isAfter(dateDebut) && now.isBefore(dateFin);
//   }
// }
