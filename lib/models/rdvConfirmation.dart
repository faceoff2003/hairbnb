import 'package:hairbnb/models/salon.dart';

import 'client.dart';
import 'coiffeuse.dart';

class RdvConfirmation {
  final int idRendezVous;
  final ClientLite client;
  final CoiffeuseLite coiffeuse;
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

  factory RdvConfirmation.fromJson(Map<String, dynamic> json) {
    print("DEBUG RDV JSON: $json");

    return RdvConfirmation(
      idRendezVous: json['idRendezVous'],
      client: ClientLite.fromJson(json['client']),
      coiffeuse: CoiffeuseLite.fromJson(json['coiffeuse']),
      salon: Salon.fromJson(json['salon']),
      dateHeure: DateTime.parse(json['date_heure']),
      statut: json['statut'] ?? '',
      totalPrix: (json['total_prix'] as num).toDouble(),
      dureeTotale: json['duree_totale'],
      services: (json['services'] as List)
          .map((s) => ServiceRdv.fromJson(s))
          .toList(),
    );
  }
}





//------------------------------------------------------------------------------
class ClientLite extends Client {
  ClientLite({
    required super.idTblUser,
    required super.uuid,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.numeroTelephone,
    required super.sexe,
    required super.isActive,
    super.dateNaissance,
    super.photoProfil,
    super.numero,
    super.boitePostale,
    super.nomRue,
    super.commune,
    super.codePostal,
  });

  factory ClientLite.fromJson(Map<String, dynamic> json) {
    return ClientLite(
      idTblUser: json['idTblUser'],
      uuid: json['uuid'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      numeroTelephone: json['numero_telephone'],
      dateNaissance: json['date_naissance'],
      sexe: json['sexe'],
      isActive: json['is_active'],
      photoProfil: json['photo_profil'],
      numero: json['numero'],
      boitePostale: json['boite_postale'],
      nomRue: json['nom_rue'],
      commune: json['commune'],
      codePostal: json['code_postal'],
    );
  }
}






//------------------------------------------------------------------------------
class CoiffeuseLite extends Coiffeuse {
  CoiffeuseLite({
    required super.idTblUser,
    required super.id,
    super.nomCommercial,
    super.position,
    required super.uuid,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.numeroTelephone,
    super.dateNaissance,
    required super.sexe,
    required super.isActive,
    super.photoProfil,
    super.numero,
    super.nomRue,
    super.commune,
    super.codePostal,
  });

  factory CoiffeuseLite.fromJson(Map<String, dynamic> json) {
    return CoiffeuseLite(
      idTblUser: json['idTblUser'],
      id: json['id'],
      nomCommercial: json['nom_commercial'],
      position: json['position'],
      uuid: json['uuid'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      numeroTelephone: json['numero_telephone'],
      dateNaissance: json['date_naissance'],
      sexe: json['sexe'],
      isActive: json['is_active'],
      photoProfil: json['photo_profil'],
      numero: json['numero'],
      nomRue: json['nom_rue'],
      commune: json['commune'],
      codePostal: json['code_postal'],
    );
  }
}











// import 'package:hairbnb/models/salon.dart';
// import 'package:hairbnb/models/service_rdv.dart';
// import 'client.dart';
// import 'coiffeuse.dart';
//
// class RdvConfirmation {
//   final int idRendezVous;
//   final Client client;
//   final Coiffeuse coiffeuse;
//   final Salon salon;
//   final DateTime dateHeure;
//   final String statut;
//   final double totalPrix;
//   final int dureeTotale;
//   final List<ServiceRdv> services;
//
//   RdvConfirmation({
//     required this.idRendezVous,
//     required this.client,
//     required this.coiffeuse,
//     required this.salon,
//     required this.dateHeure,
//     required this.statut,
//     required this.totalPrix,
//     required this.dureeTotale,
//     required this.services,
//   });
//
//   /// **🟢 Convertir un JSON en objet `RdvConfirmation`**
//   factory RdvConfirmation.fromJson(Map<String, dynamic> json) {
//
//     //---------------------------------------------------------------------
//     print("DEBUG RDV JSON: $json"); // 👈 Ajoute cette ligne
//     //---------------------------------------------------------------------
//
//     return RdvConfirmation(
//       idRendezVous: json['idRendezVous'],
//       client: Client.fromJson(json['client']),
//       coiffeuse: Coiffeuse.fromJson(json['coiffeuse']),
//       salon: Salon.fromJson(json['salon']),
//       dateHeure: DateTime.parse(json['date_heure']),
//       statut: json['statut']  ?? '',
//       totalPrix: json['total_prix'].toDouble()  ?? '',
//       dureeTotale: json['duree_totale']  ?? '',
//       services: (json['services'] as List)
//           .map((serviceJson) => ServiceRdv.fromJson(serviceJson))
//           .toList(),
//     );
//   }
//
//   /// **🔵 Convertir un objet `RdvConfirmation` en JSON**
//   Map<String, dynamic> toJson() {
//     return {
//       'idRendezVous': idRendezVous,
//       'client': client.toJson(),
//       'coiffeuse': coiffeuse.toJson(),
//       'salon': salon.toJson(),
//       'date_heure': dateHeure.toIso8601String(),
//       'statut': statut,
//       'total_prix': totalPrix,
//       'duree_totale': dureeTotale,
//       'services': services.map((service) => service.toJson()).toList(),
//     };
//   }
// }

// /// **📌 Modèle pour le client**
// class Client {
//   final int id;
//   final String nom;
//   final String prenom;
//
//   Client({required this.id, required this.nom, required this.prenom});
//
//   factory Client.fromJson(Map<String, dynamic> json) {
//     return Client(
//       id: json['idTblUser'],
//       nom: json['nom'],
//       prenom: json['prenom'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {'idTblUser': id, 'nom': nom, 'prenom': prenom};
//   }
// }
//
// /// **📌 Modèle pour la coiffeuse**
// class Coiffeuse {
//   final int id;
//   final String nom;
//   final String prenom;
//
//   Coiffeuse({required this.id, required this.nom, required this.prenom});
//
//   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
//     return Coiffeuse(
//       id: json['idTblUser'],
//       nom: json['nom'],
//       prenom: json['prenom'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {'idTblUser': id, 'nom': nom, 'prenom': prenom};
//   }
// }
//
// /// **📌 Modèle pour le salon**
// class Salon {
//   final int id;
//   final String nom;
//
//   Salon({required this.id, required this.nom});
//
//   factory Salon.fromJson(Map<String, dynamic> json) {
//     return Salon(
//       id: json['idTblSalon'],
//       nom: json['nom'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {'idTblSalon': id, 'nom': nom};
//   }
// }
//
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
