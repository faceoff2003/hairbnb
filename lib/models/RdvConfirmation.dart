class RdvConfirmation {
  final int idRendezVous;
  final Client client;
  final Coiffeuse coiffeuse;
  final Salon salon;
  final DateTime dateHeure;
  final String statut;
  final double totalPrix;
  final int dureeTotale;
  final List<ServiceRdv> services;

  RdvConfirmation({
    required this.idRendezVous,
    required this.client,
    required this.coiffeuse,
    required this.salon,
    required this.dateHeure,
    required this.statut,
    required this.totalPrix,
    required this.dureeTotale,
    required this.services,
  });

  /// **🟢 Convertir un JSON en objet `RdvConfirmation`**
  factory RdvConfirmation.fromJson(Map<String, dynamic> json) {
    return RdvConfirmation(
      idRendezVous: json['idRendezVous'],
      client: Client.fromJson(json['client']),
      coiffeuse: Coiffeuse.fromJson(json['coiffeuse']),
      salon: Salon.fromJson(json['salon']),
      dateHeure: DateTime.parse(json['date_heure']),
      statut: json['statut'],
      totalPrix: json['total_prix'].toDouble(),
      dureeTotale: json['duree_totale'],
      services: (json['services'] as List)
          .map((serviceJson) => ServiceRdv.fromJson(serviceJson))
          .toList(),
    );
  }

  /// **🔵 Convertir un objet `RdvConfirmation` en JSON**
  Map<String, dynamic> toJson() {
    return {
      'idRendezVous': idRendezVous,
      'client': client.toJson(),
      'coiffeuse': coiffeuse.toJson(),
      'salon': salon.toJson(),
      'date_heure': dateHeure.toIso8601String(),
      'statut': statut,
      'total_prix': totalPrix,
      'duree_totale': dureeTotale,
      'services': services.map((service) => service.toJson()).toList(),
    };
  }
}

/// **📌 Modèle pour le client**
class Client {
  final int id;
  final String nom;
  final String prenom;

  Client({required this.id, required this.nom, required this.prenom});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['idTblUser'],
      nom: json['nom'],
      prenom: json['prenom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'idTblUser': id, 'nom': nom, 'prenom': prenom};
  }
}

/// **📌 Modèle pour la coiffeuse**
class Coiffeuse {
  final int id;
  final String nom;
  final String prenom;

  Coiffeuse({required this.id, required this.nom, required this.prenom});

  factory Coiffeuse.fromJson(Map<String, dynamic> json) {
    return Coiffeuse(
      id: json['idTblUser'],
      nom: json['nom'],
      prenom: json['prenom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'idTblUser': id, 'nom': nom, 'prenom': prenom};
  }
}

/// **📌 Modèle pour le salon**
class Salon {
  final int id;
  final String nom;

  Salon({required this.id, required this.nom});

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['idTblSalon'],
      nom: json['nom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'idTblSalon': id, 'nom': nom};
  }
}

/// **📌 Modèle pour un service dans le RDV**
class ServiceRdv {
  final int id;
  final String intitule;
  final double prixApplique;

  ServiceRdv({required this.id, required this.intitule, required this.prixApplique});

  factory ServiceRdv.fromJson(Map<String, dynamic> json) {
    return ServiceRdv(
      id: json['idTblService'],
      intitule: json['intitule_service'],
      prixApplique: json['prix_applique'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblService': id,
      'intitule_service': intitule,
      'prix_applique': prixApplique,
    };
  }
}
