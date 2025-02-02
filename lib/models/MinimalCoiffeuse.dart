class MinimalCoiffeuse {
  int idTblUser;
  String uuid;
  String nom;
  String prenom;
  String? photoProfil;

  MinimalCoiffeuse({
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    this.photoProfil,
  });

  // 🔹 Convertir depuis JSON
  factory MinimalCoiffeuse.fromJson(Map<String, dynamic> json) {
    return MinimalCoiffeuse(
      idTblUser: json['idTblUser'],
      uuid: json['uuid'],
      nom: json['nom'],
      prenom: json['prenom'],
      photoProfil: json['photo_profil'],
    );
  }

  // 🔹 Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'idTblUser': idTblUser,
      'uuid': uuid,
      'nom': nom,
      'prenom': prenom,
      'photo_profil': photoProfil,
    };
  }
}
