// Fichier: models/promotion.dart
class PromotionFull {
  final int id;
  final int serviceId;
  final double pourcentage;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String status; // "active", "future", ou "expired"

  PromotionFull({
    required this.id,
    required this.serviceId,
    required this.pourcentage,
    required this.dateDebut,
    required this.dateFin,
    this.status = "", // Valeur par défaut pour compatibilité avec le code existant
  });

  // Détermine si la promotion est active à la date actuelle
  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(dateDebut) && now.isBefore(dateFin);
  }

  // Détermine si la promotion est future
  bool isFuture() {
    final now = DateTime.now();
    return dateDebut.isAfter(now);
  }

  // Détermine si la promotion est expirée
  bool isExpired() {
    final now = DateTime.now();
    return dateFin.isBefore(now);
  }

  // Obtient le statut actuel de la promotion
  String getCurrentStatus() {
    if (status.isNotEmpty) {
      return status; // Utiliser le statut fourni par l'API
    }

    // Sinon, calculer le statut
    if (isActive()) {
      return "active";
    } else if (isFuture()) {
      return "future";
    } else {
      return "expired";
    }
  }

  factory PromotionFull.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(String dateStr) {
      // Gérer les formats de date avec ou sans fuseau horaire
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        // En cas d'erreur, essayer d'autres formats
        return DateTime.parse(dateStr.split('T')[0]);
      }
    }

    return PromotionFull(
      id: json['idPromotion'],
      serviceId: json['service_id'],
      pourcentage: json['discount_percentage'] != null
          ? double.parse(json['discount_percentage'].toString())
          : 0.0,
      dateDebut: json['start_date'] != null ? parseDateTime(json['start_date']) : DateTime.now(),
      dateFin: json['end_date'] != null ? parseDateTime(json['end_date']) : DateTime.now(),
      status: json['status'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'discount_percentage': pourcentage,
      'start_date': dateDebut.toIso8601String().split('T')[0],
      'end_date': dateFin.toIso8601String().split('T')[0],
    };
  }
}