class Client {
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

  // Adresse
  String? numero;
  String? boitePostale;
  String? nomRue;
  String? commune;
  String? codePostal;

  Client({
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
    this.numero,
    this.boitePostale,
    this.nomRue,
    this.commune,
    this.codePostal,
  });

  // 🔹 Convertir depuis JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      idTblUser: json['idTblUser'],
      uuid: json['user']['uuid'],
      nom: json['user']['nom'],
      prenom: json['user']['prenom'],
      email: json['user']['email'],
      numeroTelephone: json['user']['numero_telephone'],
      dateNaissance: json['user']['date_naissance'],
      sexe: json['user']['sexe'],
      isActive: json['user']['is_active'],
      photoProfil: json['user']['photo_profil'],
      numero: json['user']['adresse']?['numero'],
      boitePostale: json['user']['adresse']?['boite_postale'],
      nomRue: json['user']['adresse']?['rue']?['nom_rue'],
      commune: json['user']['adresse']?['rue']?['localite']?['commune'],
      codePostal: json['user']['adresse']?['rue']?['localite']?['code_postal'],
    );
  }

  // 🔹 Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'idTblUser': idTblUser,
      'user': {
        'uuid': uuid,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'numero_telephone': numeroTelephone,
        'date_naissance': dateNaissance,
        'sexe': sexe,
        'is_active': isActive,
        'photo_profil': photoProfil,
        'adresse': {
          'numero': numero,
          'boite_postale': boitePostale,
          'rue': {
            'nom_rue': nomRue,
            'localite': {
              'commune': commune,
              'code_postal': codePostal,
            }
          }
        }
      }
    };
  }
}
