import 'package:hairbnb/models/coiffeuse.dart';

import 'client.dart' as client_model;

class CurrentUser {
  int idTblUser;
  String uuid;
  String nom;
  String prenom;
  String email;
  String numeroTelephone;
  String? dateNaissance;
  String sexe;
  bool isActive;
  String? photoProfil;
  String type;
  dynamic extraData; // 🔥 Peut être un `Client` ou une `Coiffeuse`

  CurrentUser({
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numeroTelephone,
    this.dateNaissance,
    required this.sexe,
    required this.isActive,
    this.photoProfil,
    required this.type,
    this.extraData,
  });

  // 🔹 Convertir depuis JSON
  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    dynamic extra;
    if (json['type'] == "coiffeuse" && json['extra_data'] != null) {
      extra = Coiffeuse.fromJson(json['extra_data']);
    } else if (json['type'] == "client" && json['extra_data'] != null) {
      extra = client_model.Client.fromJson(json['extra_data']);
    }

    return CurrentUser(
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
      type: json['type'],
      extraData: extra,
    );
  }

  // 🔹 Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'idTblUser' : idTblUser,
      'uuid': uuid,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numero_telephone': numeroTelephone,
      'date_naissance': dateNaissance,
      'sexe': sexe,
      'is_active': isActive,
      'photo_profil': photoProfil,
      'type': type,
      'extra_data': extraData?.toJson(),
    };
  }
}




// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:hairbnb/models/client.dart';
//
// import 'client.dart';
//
// class CurrentUser {
//   String uuid;
//   String nom;
//   String prenom;
//   String email;
//   String numeroTelephone;
//   String? dateNaissance;
//   String sexe;
//   bool isActive;
//   String? photoProfil;
//   String type;
//   dynamic extraData; // 🔥 Peut être un `Client` ou une `Coiffeuse`
//
//   CurrentUser({
//     required this.uuid,
//     required this.nom,
//     required this.prenom,
//     required this.email,
//     required this.numeroTelephone,
//     this.dateNaissance,
//     required this.sexe,
//     required this.isActive,
//     this.photoProfil,
//     required this.type,
//     this.extraData,
//   });
//
//   // 🔹 Convertir depuis JSON
//   factory CurrentUser.fromJson(Map<String, dynamic> json) {
//     dynamic extra;
//     if (json['type'] == "coiffeuse" && json['extra_data'] != null) {
//       extra = Coiffeuse.fromJson(json['extra_data']);
//     } else if (json['type'] == "client" && json['extra_data'] != null) {
//       extra = Client.fromJson(json['extra_data']);
//     }
//
//     return CurrentUser(
//       uuid: json['uuid'],
//       nom: json['nom'],
//       prenom: json['prenom'],
//       email: json['email'],
//       numeroTelephone: json['numero_telephone'],
//       dateNaissance: json['date_naissance'],
//       sexe: json['sexe'],
//       isActive: json['is_active'],
//       photoProfil: json['photo_profil'],
//       type: json['type'],
//       extraData: extra,
//     );
//   }
//
//   // 🔹 Convertir en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'uuid': uuid,
//       'nom': nom,
//       'prenom': prenom,
//       'email': email,
//       'numero_telephone': numeroTelephone,
//       'date_naissance': dateNaissance,
//       'sexe': sexe,
//       'is_active': isActive,
//       'photo_profil': photoProfil,
//       'type': type,
//       'extra_data': extraData != null ? extraData.toJson() : null,
//     };
//   }
// }