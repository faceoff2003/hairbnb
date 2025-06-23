// lib/models/revenus_model.dart

class ClientModel {
  final String nom;
  final String prenom;
  final String? email;

  ClientModel({
    required this.nom,
    required this.prenom,
    this.email,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
    };
  }
}

class ServiceRdvModel {
  final String nom;
  final String description;
  final double prixHt;
  final double prixTtc;
  final int? dureeMinutes;

  ServiceRdvModel({
    required this.nom,
    required this.description,
    required this.prixHt,
    required this.prixTtc,
    this.dureeMinutes,
  });

  factory ServiceRdvModel.fromJson(Map<String, dynamic> json) {
    return ServiceRdvModel(
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      prixHt: _parseToDouble(json['prix_ht']),
      prixTtc: _parseToDouble(json['prix_ttc']),
      dureeMinutes: json['duree_minutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'prix_ht': prixHt,
      'prix_ttc': prixTtc,
      'duree_minutes': dureeMinutes,
    };
  }

  // Méthode utilitaire pour convertir en double
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class DetailRdvModel {
  final int rdvId;
  final DateTime date;
  final ClientModel? client;
  final List<ServiceRdvModel> services;
  final double totalHt;
  final double totalTtc;
  final String statutRdv;
  final String? salon;

  DetailRdvModel({
    required this.rdvId,
    required this.date,
    this.client,
    required this.services,
    required this.totalHt,
    required this.totalTtc,
    required this.statutRdv,
    this.salon,
  });

  factory DetailRdvModel.fromJson(Map<String, dynamic> json) {
    return DetailRdvModel(
      rdvId: json['rdv_id'] ?? 0,
      date: DateTime.parse(json['date']),
      client: json['client'] != null ? ClientModel.fromJson(json['client']) : null,
      services: (json['services'] as List<dynamic>? ?? [])
          .map((service) => ServiceRdvModel.fromJson(service))
          .toList(),
      totalHt: ServiceRdvModel._parseToDouble(json['total_ht']),
      totalTtc: ServiceRdvModel._parseToDouble(json['total_ttc']),
      statutRdv: json['statut_rdv'] ?? '',
      salon: json['salon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rdv_id': rdvId,
      'date': date.toIso8601String(),
      'client': client?.toJson(),
      'services': services.map((service) => service.toJson()).toList(),
      'total_ht': totalHt,
      'total_ttc': totalTtc,
      'statut_rdv': statutRdv,
      'salon': salon,
    };
  }
}

class ResumeRevenusModel {
  final int nbRdvPayes;
  final int nbClientsUniques;
  final double totalHt;
  final double totalTtc;
  final double tva;
  final double tauxTva;

  ResumeRevenusModel({
    required this.nbRdvPayes,
    required this.nbClientsUniques,
    required this.totalHt,
    required this.totalTtc,
    required this.tva,
    required this.tauxTva,
  });

  factory ResumeRevenusModel.fromJson(Map<String, dynamic> json) {
    return ResumeRevenusModel(
      nbRdvPayes: json['nb_rdv_payes'] ?? 0,
      nbClientsUniques: json['nb_clients_uniques'] ?? 0,
      totalHt: ServiceRdvModel._parseToDouble(json['total_ht']),
      totalTtc: ServiceRdvModel._parseToDouble(json['total_ttc']),
      tva: ServiceRdvModel._parseToDouble(json['tva']),
      tauxTva: ServiceRdvModel._parseToDouble(json['taux_tva']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nb_rdv_payes': nbRdvPayes,
      'nb_clients_uniques': nbClientsUniques,
      'total_ht': totalHt,
      'total_ttc': totalTtc,
      'tva': tva,
      'taux_tva': tauxTva,
    };
  }
}

class StatistiquesRevenusModel {
  final String? servicePlusVendu;
  final String? jourLePlusRentable;
  final Map<String, double> revenusParJour;
  final int nbServicesDifferents;

  StatistiquesRevenusModel({
    this.servicePlusVendu,
    this.jourLePlusRentable,
    required this.revenusParJour,
    required this.nbServicesDifferents,
  });

  factory StatistiquesRevenusModel.fromJson(Map<String, dynamic> json) {
    // Conversion du Map des revenus par jour
    Map<String, double> revenus = {};
    if (json['revenus_par_jour'] != null) {
      Map<String, dynamic> revenusJson = json['revenus_par_jour'];
      revenusJson.forEach((key, value) {
        revenus[key] = ServiceRdvModel._parseToDouble(value);
      });
    }

    return StatistiquesRevenusModel(
      servicePlusVendu: json['service_plus_vendu'],
      jourLePlusRentable: json['jour_le_plus_rentable'],
      revenusParJour: revenus,
      nbServicesDifferents: json['nb_services_differents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_plus_vendu': servicePlusVendu,
      'jour_le_plus_rentable': jourLePlusRentable,
      'revenus_par_jour': revenusParJour,
      'nb_services_differents': nbServicesDifferents,
    };
  }
}

class RevenusCoiffeuseModel {
  final bool success;
  final String periode;
  final DateTime dateDebut;
  final DateTime dateFin;
  final ResumeRevenusModel resume;
  final List<DetailRdvModel> detailsRdv;
  final StatistiquesRevenusModel statistiques;

  RevenusCoiffeuseModel({
    required this.success,
    required this.periode,
    required this.dateDebut,
    required this.dateFin,
    required this.resume,
    required this.detailsRdv,
    required this.statistiques,
  });

  factory RevenusCoiffeuseModel.fromJson(Map<String, dynamic> json) {
    return RevenusCoiffeuseModel(
      success: json['success'] ?? false,
      periode: json['periode'] ?? '',
      dateDebut: DateTime.parse(json['date_debut']),
      dateFin: DateTime.parse(json['date_fin']),
      resume: ResumeRevenusModel.fromJson(json['resume'] ?? {}),
      detailsRdv: (json['details_rdv'] as List<dynamic>? ?? [])
          .map((rdv) => DetailRdvModel.fromJson(rdv))
          .toList(),
      statistiques: StatistiquesRevenusModel.fromJson(json['statistiques'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'periode': periode,
      'date_debut': dateDebut.toIso8601String().split('T')[0],
      'date_fin': dateFin.toIso8601String().split('T')[0],
      'resume': resume.toJson(),
      'details_rdv': detailsRdv.map((rdv) => rdv.toJson()).toList(),
      'statistiques': statistiques.toJson(),
    };
  }
}

class RevenusErrorModel {
  final bool success;
  final String error;

  RevenusErrorModel({
    required this.success,
    required this.error,
  });

  factory RevenusErrorModel.fromJson(Map<String, dynamic> json) {
    return RevenusErrorModel(
      success: json['success'] ?? false,
      error: json['error'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
    };
  }
}

// Enum pour les périodes disponibles
enum PeriodeRevenu {
  jour,
  semaine,
  mois,
  annee,
  custom,
}

extension PeriodeRevenueExtension on PeriodeRevenu {
  String get value {
    switch (this) {
      case PeriodeRevenu.jour:
        return 'jour';
      case PeriodeRevenu.semaine:
        return 'semaine';
      case PeriodeRevenu.mois:
        return 'mois';
      case PeriodeRevenu.annee:
        return 'annee';
      case PeriodeRevenu.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case PeriodeRevenu.jour:
        return 'Aujourd\'hui';
      case PeriodeRevenu.semaine:
        return 'Cette semaine';
      case PeriodeRevenu.mois:
        return 'Ce mois';
      case PeriodeRevenu.annee:
        return 'Cette année';
      case PeriodeRevenu.custom:
        return 'Période personnalisée';
    }
  }
}