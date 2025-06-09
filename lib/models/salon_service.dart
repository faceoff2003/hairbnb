
/// Modèle pour les promotions d'un service dans un salon
class SalonServicePromotion {
  final int id;
  final double pourcentage;
  final double prixOriginal;
  final double prixFinal;
  final double economie;
  final String dateDebut;
  final String dateFin;
  final bool estActive;

  const SalonServicePromotion({
    required this.id,
    required this.pourcentage,
    required this.prixOriginal,
    required this.prixFinal,
    required this.economie,
    required this.dateDebut,
    required this.dateFin,
    required this.estActive,
  });

  factory SalonServicePromotion.fromJson(Map<String, dynamic> json) {
    return SalonServicePromotion(
      id: _parseIntSafe(json['id']),
      pourcentage: _parseDoubleSafe(json['pourcentage']),
      prixOriginal: _parseDoubleSafe(json['prix_original']),
      prixFinal: _parseDoubleSafe(json['prix_final']),
      economie: _parseDoubleSafe(json['economie']),
      dateDebut: json['date_debut']?.toString() ?? '',  // ✅ AJOUT
      dateFin: json['date_fin']?.toString() ?? '',
      estActive: json['est_active'] == true,
    );
  }

  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Formatage du pourcentage pour l'affichage
  String get pourcentageFormate => "-${pourcentage.toStringAsFixed(0)}%";

  /// Formatage de l'économie pour l'affichage
  String get economieFormatee => "Économisez ${economie.toStringAsFixed(0)}€";

  @override
  String toString() {
    return 'Promotion ${pourcentageFormate} (${economieFormatee})';
  }
}

/// Modèle pour les services d'un salon spécifique avec gestion des promotions
class SalonService {
  final int idTblService;
  final String intituleService;
  final String description;
  final int categorieId;
  final String categorieNom;
  final int salonServiceId;
  final double prix;
  final double prixFinal;
  final int dureeMinutes;
  final SalonServicePromotion? promotion;

  const SalonService({
    required this.idTblService,
    required this.intituleService,
    required this.description,
    required this.categorieId,
    required this.categorieNom,
    required this.salonServiceId,
    required this.prix,
    required this.prixFinal,
    required this.dureeMinutes,
    this.promotion,
  });

  /// Créer un SalonService depuis la réponse JSON de l'API
  factory SalonService.fromJson(Map<String, dynamic> json) {
    try {
      // Parser la promotion si elle existe
      SalonServicePromotion? promo;
      if (json['promotion'] != null) {
        promo = SalonServicePromotion.fromJson(json['promotion']);
      }

      return SalonService(
        idTblService: _parseIntSafe(json['idTblService']),
        intituleService: json['intitule_service']?.toString() ?? 'Service sans nom',
        description: json['description']?.toString() ?? 'Aucune description',
        categorieId: _parseIntSafe(json['categorie_id']),
        categorieNom: json['categorie_nom']?.toString() ?? 'Sans catégorie',
        salonServiceId: _parseIntSafe(json['salon_service_id']),
        prix: _parseDoubleSafe(json['prix']),
        prixFinal: _parseDoubleSafe(json['prix_final']),
        dureeMinutes: _parseIntSafe(json['duree_minutes']),
        promotion: promo,
      );
    } catch (e) {
      print("❌ Erreur parsing SalonService: $e");
      print("🔍 JSON reçu: $json");
      rethrow;
    }
  }

  /// Helper pour parser les entiers de manière sécurisée
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper pour parser les doubles de manière sécurisée
  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convertir en JSON pour les appels API
  Map<String, dynamic> toJson() {
    return {
      'idTblService': idTblService,
      'intitule_service': intituleService,
      'description': description,
      'categorie_id': categorieId,
      'categorie_nom': categorieNom,
      'salon_service_id': salonServiceId,
      'prix': prix,
      'prix_final': prixFinal,
      'duree_minutes': dureeMinutes,
      'promotion': promotion != null ? {
        'pourcentage': promotion!.pourcentage,
        'economie': promotion!.economie,
        'date_debut': promotion!.dateDebut,  // ✅ AJOUT
        'date_fin': promotion!.dateFin,
      } : null,
    };
  }

  /// Vérifier si le service a une promotion active
  bool get hasPromotion => promotion != null && promotion!.estActive;

  /// Formatage du prix original pour l'affichage
  String get prixFormate => "${prix.toStringAsFixed(0)}€";

  /// Formatage du prix final pour l'affichage (avec ou sans promotion)
  String get prixFinalFormate => "${prixFinal.toStringAsFixed(0)}€";

  /// Formatage de la durée pour l'affichage
  String get dureeFormatee {
    if (dureeMinutes < 60) {
      return "${dureeMinutes}min";
    } else {
      final heures = dureeMinutes ~/ 60;
      final minutes = dureeMinutes % 60;
      if (minutes == 0) {
        return "${heures}h";
      } else {
        return "${heures}h${minutes}min";
      }
    }
  }



  /// Vérifier si le service est valide
  bool get isValid {
    return idTblService > 0 &&
        intituleService.isNotEmpty &&
        prix > 0 &&
        dureeMinutes > 0;
  }

  @override
  String toString() {
    String promoInfo = hasPromotion ? " (${promotion!.pourcentageFormate})" : "";
    return 'SalonService(id: $idTblService, nom: "$intituleService", prix: $prixFinalFormate$promoInfo, durée: ${dureeMinutes}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalonService &&
        other.idTblService == idTblService &&
        other.salonServiceId == salonServiceId;
  }

  @override
  int get hashCode => Object.hash(idTblService, salonServiceId);
}