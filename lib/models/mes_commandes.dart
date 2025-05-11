// Modification du modèle mes_commandes.dart

class Commande {
  final int idRendezVous;
  final DateTime dateHeure;
  final String statut;
  final String nomSalon;
  final String nomCoiffeuse;
  final String prenomCoiffeuse;
  final double totalPrix;
  final int dureeTotale;
  final DateTime datePaiement;
  final double montantPaye;
  final String methodePaiement;
  final String? receiptUrl;
  final List<ServiceCommande> services;

  Commande({
    required this.idRendezVous,
    required this.dateHeure,
    required this.statut,
    required this.nomSalon,
    required this.nomCoiffeuse,
    required this.prenomCoiffeuse,
    required this.totalPrix,
    required this.dureeTotale,
    required this.datePaiement,
    required this.montantPaye,
    required this.methodePaiement,
    this.receiptUrl,
    required this.services,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    // Parser avec gestion des différents types possibles
    return Commande(
      idRendezVous: json['idRendezVous'],
      dateHeure: DateTime.parse(json['date_heure']),
      statut: json['statut'],
      nomSalon: json['nom_salon'],
      nomCoiffeuse: json['nom_coiffeuse'],
      prenomCoiffeuse: json['prenom_coiffeuse'],
      // Gérer correctement les nombres qui peuvent être des chaînes
      totalPrix: _parseDouble(json['total_prix']),
      dureeTotale: _parseInt(json['duree_totale']),
      datePaiement: DateTime.parse(json['date_paiement']),
      montantPaye: _parseDouble(json['montant_paye']),
      methodePaiement: json['methode_paiement'],
      receiptUrl: json['receipt_url'],
      services: (json['services'] as List)
          .map((s) => ServiceCommande.fromJson(s))
          .toList(),
    );
  }

  // Méthode statique pour traiter une liste de commandes
  static List<Commande> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Commande.fromJson(json)).toList();
  }

  // Méthodes d'aide pour gérer les conversions de types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ServiceCommande {
  final String intituleService;
  final double prixApplique;
  final int dureeEstimee;

  ServiceCommande({
    required this.intituleService,
    required this.prixApplique,
    required this.dureeEstimee,
  });

  factory ServiceCommande.fromJson(Map<String, dynamic> json) {
    return ServiceCommande(
      intituleService: json['intitule_service'],
      // Utiliser les méthodes helper pour gérer différents types
      prixApplique: Commande._parseDouble(json['prix_applique']),
      dureeEstimee: Commande._parseInt(json['duree_estimee']),
    );
  }
}