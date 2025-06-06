class MinimalCoiffeuse {
  final int idTblUser;
  final String uuid;
  final String nom;
  final String prenom;
  final String? photoProfil;
  final String? nomCommercial;
  final Map<String, dynamic>? salon;
  final List<dynamic>? autresSalons;

  MinimalCoiffeuse({
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    this.photoProfil,
    this.nomCommercial,
    this.salon,
    this.autresSalons,
  });

  factory MinimalCoiffeuse.fromJson(Map<String, dynamic> json) {
    return MinimalCoiffeuse(
      idTblUser: json['idTblUser'] ?? 0,
      uuid: json['uuid'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      photoProfil: json['photo_profil'],
      nomCommercial: json['nom_commercial'],
      salon: json['salon'],
      autresSalons: json['autres_salons'],
    );
  }

// Quelques accesseurs utiles
  String? get nomSalon => salon?['nom_salon'];

  String? get salonSlogan => salon?['slogan'];

  String? get logoSalon => salon?['logo_salon'];

  String? get salonPosition => salon?['position'];

  int? get idSalon => salon?['idTblSalon'];
}



// class MinimalCoiffeuse {
//   int idTblUser;
//   String uuid;
//   String nom;
//   String prenom;
//   String? photoProfil;
//   String position;
//
//   MinimalCoiffeuse({
//     required this.idTblUser,
//     required this.uuid,
//     required this.nom,
//     required this.prenom,
//     this.photoProfil,
//     required this.position
//   });
//
//   // 🔹 Convertir depuis JSON
//   factory MinimalCoiffeuse.fromJson(Map<String, dynamic> json) {
//     return MinimalCoiffeuse(
//       idTblUser: json['idTblUser'],
//       uuid: json['uuid'],
//       nom: json['nom'],
//       prenom: json['prenom'],
//       photoProfil: json['photo_profil'],
//       position: json['position'],
//     );
//   }
//
//   // 🔹 Convertir en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblUser': idTblUser,
//       'uuid': uuid,
//       'nom': nom,
//       'prenom': prenom,
//       'photo_profil': photoProfil,
//       'position':position,
//     };
//   }
// }
