class CommandeClient {
  final int idRendezVous;
  final String dateHeure;
  final String statut;
  final String nomClient;
  final String prenomClient;
  final String telephoneClient;
  final String emailClient; // Ajout du champ email
  final String nomSalon;
  final double totalPrix;
  final int dureeTotale;
  final String? statutPaiement;
  final String? datePaiement;
  final double? montantPaye;
  final List<ServiceCommande> services;
  final bool estArchive;

  CommandeClient({
    required this.idRendezVous,
    required this.dateHeure,
    required this.statut,
    required this.nomClient,
    required this.prenomClient,
    required this.telephoneClient,
    required this.emailClient, // Paramètre pour l'email
    required this.nomSalon,
    required this.totalPrix,
    required this.dureeTotale,
    this.statutPaiement,
    this.datePaiement,
    this.montantPaye,
    required this.services,
    required this.estArchive,
  });

  // Création à partir d'un JSON
  factory CommandeClient.fromJson(Map<String, dynamic> json) {
    return CommandeClient(
      idRendezVous: json['idRendezVous'],
      dateHeure: json['date_heure'],
      statut: json['statut'],
      nomClient: json['nom_client'],
      prenomClient: json['prenom_client'],
      telephoneClient: json['telephone_client'] ?? 'Non renseigné',
      emailClient: json['email_client'], // Récupération de l'email depuis le JSON
      nomSalon: json['nom_salon'],
      totalPrix: double.parse(json['total_prix'].toString()),
      dureeTotale: json['duree_totale'] ?? 0,
      statutPaiement: json['statut_paiement'],
      datePaiement: json['date_paiement'],
      montantPaye: json['montant_paye'] != null
          ? double.parse(json['montant_paye'].toString())
          : null,
      services: (json['services'] as List)
          .map((service) => ServiceCommande.fromJson(service))
          .toList(),
      estArchive: json['est_archive'] ?? false,
    );
  }

  // Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'idRendezVous': idRendezVous,
      'date_heure': dateHeure,
      'statut': statut,
      'nom_client': nomClient,
      'prenom_client': prenomClient,
      'telephone_client': telephoneClient,
      'email_client': emailClient, // Ajout de l'email dans le JSON
      'nom_salon': nomSalon,
      'total_prix': totalPrix,
      'duree_totale': dureeTotale,
      'statut_paiement': statutPaiement,
      'date_paiement': datePaiement,
      'montant_paye': montantPaye,
      'services': services.map((service) => service.toJson()).toList(),
      'est_archive': estArchive,
    };
  }

  // Pour mettre à jour le statut
  CommandeClient copyWith({
    int? idRendezVous,
    String? dateHeure,
    String? statut,
    String? nomClient,
    String? prenomClient,
    String? telephoneClient,
    String? emailClient, // Ajout du paramètre email
    String? nomSalon,
    double? totalPrix,
    int? dureeTotale,
    String? statutPaiement,
    String? datePaiement,
    double? montantPaye,
    List<ServiceCommande>? services,
    bool? estArchive,
  }) {
    return CommandeClient(
      idRendezVous: idRendezVous ?? this.idRendezVous,
      dateHeure: dateHeure ?? this.dateHeure,
      statut: statut ?? this.statut,
      nomClient: nomClient ?? this.nomClient,
      prenomClient: prenomClient ?? this.prenomClient,
      telephoneClient: telephoneClient ?? this.telephoneClient,
      emailClient: emailClient ?? this.emailClient, // Gestion de la copie de l'email
      nomSalon: nomSalon ?? this.nomSalon,
      totalPrix: totalPrix ?? this.totalPrix,
      dureeTotale: dureeTotale ?? this.dureeTotale,
      statutPaiement: statutPaiement ?? this.statutPaiement,
      datePaiement: datePaiement ?? this.datePaiement,
      montantPaye: montantPaye ?? this.montantPaye,
      services: services ?? this.services,
      estArchive: estArchive ?? this.estArchive,
    );
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

  // Création à partir d'un JSON
  factory ServiceCommande.fromJson(Map<String, dynamic> json) {
    return ServiceCommande(
      intituleService: json['intitule_service'],
      prixApplique: double.parse(json['prix_applique'].toString()),
      dureeEstimee: json['duree_estimee'] ?? 0,
    );
  }

  // Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'intitule_service': intituleService,
      'prix_applique': prixApplique,
      'duree_estimee': dureeEstimee,
    };
  }
}






// class CommandeClient {
//   final int idRendezVous;
//   final String dateHeure;
//   final String statut;
//   final String nomClient;
//   final String prenomClient;
//   final String telephoneClient;
//   final String nomSalon;
//   final double totalPrix;
//   final int dureeTotale;
//   final String? statutPaiement;
//   final String? datePaiement;
//   final double? montantPaye;
//   final List<ServiceCommande> services;
//   final bool estArchive;
//
//   CommandeClient({
//     required this.idRendezVous,
//     required this.dateHeure,
//     required this.statut,
//     required this.nomClient,
//     required this.prenomClient,
//     required this.telephoneClient,
//     required this.nomSalon,
//     required this.totalPrix,
//     required this.dureeTotale,
//     this.statutPaiement,
//     this.datePaiement,
//     this.montantPaye,
//     required this.services,
//     required this.estArchive,
//   });
//
//   // Création à partir d'un JSON
//   factory CommandeClient.fromJson(Map<String, dynamic> json) {
//     return CommandeClient(
//       idRendezVous: json['idRendezVous'],
//       dateHeure: json['date_heure'],
//       statut: json['statut'],
//       nomClient: json['nom_client'],
//       prenomClient: json['prenom_client'],
//       telephoneClient: json['telephone_client'] ?? 'Non renseigné',
//       nomSalon: json['nom_salon'],
//       totalPrix: double.parse(json['total_prix'].toString()),
//       dureeTotale: json['duree_totale'] ?? 0,
//       statutPaiement: json['statut_paiement'],
//       datePaiement: json['date_paiement'],
//       montantPaye: json['montant_paye'] != null
//           ? double.parse(json['montant_paye'].toString())
//           : null,
//       services: (json['services'] as List)
//           .map((service) => ServiceCommande.fromJson(service))
//           .toList(),
//       estArchive: json['est_archive'] ?? false,
//     );
//   }
//
//   // Conversion en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'idRendezVous': idRendezVous,
//       'date_heure': dateHeure,
//       'statut': statut,
//       'nom_client': nomClient,
//       'prenom_client': prenomClient,
//       'telephone_client': telephoneClient,
//       'nom_salon': nomSalon,
//       'total_prix': totalPrix,
//       'duree_totale': dureeTotale,
//       'statut_paiement': statutPaiement,
//       'date_paiement': datePaiement,
//       'montant_paye': montantPaye,
//       'services': services.map((service) => service.toJson()).toList(),
//       'est_archive': estArchive,
//     };
//   }
//
//   // Pour mettre à jour le statut
//   CommandeClient copyWith({
//     int? idRendezVous,
//     String? dateHeure,
//     String? statut,
//     String? nomClient,
//     String? prenomClient,
//     String? telephoneClient,
//     String? nomSalon,
//     double? totalPrix,
//     int? dureeTotale,
//     String? statutPaiement,
//     String? datePaiement,
//     double? montantPaye,
//     List<ServiceCommande>? services,
//     bool? estArchive,
//   }) {
//     return CommandeClient(
//       idRendezVous: idRendezVous ?? this.idRendezVous,
//       dateHeure: dateHeure ?? this.dateHeure,
//       statut: statut ?? this.statut,
//       nomClient: nomClient ?? this.nomClient,
//       prenomClient: prenomClient ?? this.prenomClient,
//       telephoneClient: telephoneClient ?? this.telephoneClient,
//       nomSalon: nomSalon ?? this.nomSalon,
//       totalPrix: totalPrix ?? this.totalPrix,
//       dureeTotale: dureeTotale ?? this.dureeTotale,
//       statutPaiement: statutPaiement ?? this.statutPaiement,
//       datePaiement: datePaiement ?? this.datePaiement,
//       montantPaye: montantPaye ?? this.montantPaye,
//       services: services ?? this.services,
//       estArchive: estArchive ?? this.estArchive,
//     );
//   }
// }
//
// class ServiceCommande {
//   final String intituleService;
//   final double prixApplique;
//   final int dureeEstimee;
//
//   ServiceCommande({
//     required this.intituleService,
//     required this.prixApplique,
//     required this.dureeEstimee,
//   });
//
//   // Création à partir d'un JSON
//   factory ServiceCommande.fromJson(Map<String, dynamic> json) {
//     return ServiceCommande(
//       intituleService: json['intitule_service'],
//       prixApplique: double.parse(json['prix_applique'].toString()),
//       dureeEstimee: json['duree_estimee'] ?? 0,
//     );
//   }
//
//   // Conversion en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'intitule_service': intituleService,
//       'prix_applique': prixApplique,
//       'duree_estimee': dureeEstimee,
//     };
//   }
// }