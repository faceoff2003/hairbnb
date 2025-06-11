class CurrentUser {
  final int idTblUser;
  final String uuid;
  final String nom;
  final String prenom;
  final String email;
  String? numeroTelephone;
  final String? dateNaissance;
  final bool isActive;
  final String? photoProfil;
  final Adresse? adresse;
  final String? role;
  final String? sexe;
  final String? type;
  final CoiffeuseData? extraData; // Changé de Coiffeuse à CoiffeuseData

  CurrentUser({
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numeroTelephone,
    this.dateNaissance,
    required this.isActive,
    this.photoProfil,
    this.adresse,
    this.role,
    this.sexe,
    this.type,
    this.extraData,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    // Si le JSON contient le champ "user", utilisez-le
    final userData = json.containsKey('user') ? json['user'] : json;

    // Nouveau traitement pour extraData basé sur la structure backend
    var extraDataJson;
    if (userData['extra_data'] != null) {
      extraDataJson = userData['extra_data'];
    } else if (userData['coiffeuse'] != null) {
      // Maintenir la compatibilité avec l'ancien format d'API
      extraDataJson = userData['coiffeuse'];
    }

    // Récupérer l'URL de la photo telle quelle, sans modification
    var photoProfilUrl = userData['photo_profil'];

    return CurrentUser(
      idTblUser: userData['idTblUser'],
      uuid: userData['uuid'],
      nom: userData['nom'],
      prenom: userData['prenom'],
      email: userData['email'],
      numeroTelephone: userData['numero_telephone'],
      dateNaissance: userData['date_naissance'],
      isActive: userData['is_active'] ?? true,
      photoProfil: photoProfilUrl,
      adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
      role: userData['role'],
      sexe: userData['sexe'],
      type: userData['type'],
      extraData: extraDataJson != null && userData['type']?.toLowerCase() == 'coiffeuse'
          ? CoiffeuseData.fromJson(extraDataJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblUser': idTblUser,
      'uuid': uuid,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numero_telephone': numeroTelephone,
      'date_naissance': dateNaissance,
      'is_active': isActive,
      'photo_profil': photoProfil,
      'adresse': adresse?.toJson(),
      'role': role,
      'sexe': sexe,
      'type': type,
      'extra_data': extraData?.toJson(),
    };
  }

  // Méthodes utilitaires
  bool isCoiffeuseUser() {
    return type?.toLowerCase() == 'coiffeuse' || extraData != null;
  }

  bool isClientUser() {
    return type?.toLowerCase() == 'client';
  }

  bool isAdminUser() {
    return role?.toLowerCase() == 'admin';
  }

  // Propriété pour maintenir la compatibilité avec l'ancien code
  CoiffeuseData? get coiffeuse => extraData;
}

class Adresse {
  String? numero;
  final Rue? rue;

  Adresse({
    this.numero,
    this.rue,
  });

  factory Adresse.fromJson(Map<String, dynamic> json) {
    return Adresse(
      numero: json['numero']?.toString(),
      rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'rue': rue?.toJson(),
    };
  }

  // Pour la compatibilité avec les formats différents d'adresses
  String getFullAddress() {
    if (rue == null) return numero ?? '';

    String address = '';
    if (numero != null) address += '$numero, ';
    if (rue?.nomRue != null) address += '${rue!.nomRue}';
    if (rue?.localite?.commune != null) {
      address += ', ${rue!.localite!.commune}';
      if (rue?.localite?.codePostal != null) {
        address += ' ${rue!.localite!.codePostal}';
      }
    }
    return address;
  }
}

class Rue {
  String? nomRue;
  final Localite? localite;

  Rue({
    this.nomRue,
    this.localite,
  });

  factory Rue.fromJson(Map<String, dynamic> json) {
    return Rue(
      nomRue: json['nom_rue'],
      localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_rue': nomRue,
      'localite': localite?.toJson(),
    };
  }
}

class Localite {
  String? commune;
  String? codePostal;

  Localite({
    this.commune,
    this.codePostal,
  });

  factory Localite.fromJson(Map<String, dynamic> json) {
    return Localite(
      commune: json['commune'],
      codePostal: json['code_postal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commune': commune,
      'code_postal': codePostal,
    };
  }
}

// ⚠️ SUPPRIMÉ - Plus besoin de NumeroTVA car c'est maintenant un champ direct
// La classe NumeroTVA a été supprimée car elle n'est plus utilisée

// Nouvelle classe qui match avec la structure backend
class CoiffeuseData {
  final String? nomCommercial;
  final SalonData? salonPrincipal;
  final List<SalonRelation>? tousSalons;

  CoiffeuseData({
    this.nomCommercial,
    this.salonPrincipal,
    this.tousSalons,
  });

  factory CoiffeuseData.fromJson(Map<String, dynamic> json) {
    List<SalonRelation>? salonsList;

    // Gérer les deux formats possibles pour les salons
    if (json['tous_salons'] != null && json['tous_salons'] is List) {
      salonsList = (json['tous_salons'] as List)
          .map((salon) => SalonRelation.fromJson(salon))
          .toList();
    } else if (json['salons'] != null && json['salons'] is List) {
      salonsList = (json['salons'] as List)
          .map((salon) => SalonRelation.fromJson(salon))
          .toList();
    }

    // Gérer les deux formats possibles pour salon principal
    var salonPrincipalJson = json['salon_principal'];

    return CoiffeuseData(
      nomCommercial: json['nom_commercial'],
      salonPrincipal: salonPrincipalJson != null ? SalonData.fromJson(salonPrincipalJson) : null,
      tousSalons: salonsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_commercial': nomCommercial,
      'salon_principal': salonPrincipal?.toJson(),
      'tous_salons': tousSalons?.map((salon) => salon.toJson()).toList(),
    };
  }

  // Propriétés pour compatibilité avec l'ancien code
  String? get denominationSociale => nomCommercial;
  String? get position => salonPrincipal?.position;
  SalonData? get salon => salonPrincipal;
  SalonData? get salonDirect => salonPrincipal;

  // ⚠️ MODIFIÉ - La TVA vient maintenant du salon principal
  String? get tva => salonPrincipal?.numeroTva;
  String? get numeroTva => salonPrincipal?.numeroTva;
}

// Mise à jour de SalonRelation pour inclure plus d'informations
class SalonRelation {
  final int idTblSalon;
  final String? nomSalon;
  final bool estProprietaire;
  final String? numeroTva; // ✅ Ajouté - TVA maintenant dans le salon

  SalonRelation({
    required this.idTblSalon,
    this.nomSalon,
    required this.estProprietaire,
    this.numeroTva,
  });

  factory SalonRelation.fromJson(Map<String, dynamic> json) {
    return SalonRelation(
      idTblSalon: json['idTblSalon'],
      nomSalon: json['nom_salon'],
      estProprietaire: json['est_proprietaire'] ?? false,
      numeroTva: json['numero_tva'], // ✅ Maintenant récupéré du salon
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblSalon': idTblSalon,
      'nom_salon': nomSalon,
      'est_proprietaire': estProprietaire,
      'numero_tva': numeroTva,
    };
  }
}

// Révisé pour correspondre à SalonData dans le backend
class SalonData {
  final int idTblSalon;
  final String? nomSalon;
  final String? slogan;
  final String? aPropos;
  final String? logoSalon;
  final String? position;
  final Adresse? adresse;
  final String? numeroTva; // ✅ Simplifié - maintenant directement une String

  SalonData({
    required this.idTblSalon,
    this.nomSalon,
    this.slogan,
    this.aPropos,
    this.logoSalon,
    this.position,
    this.adresse,
    this.numeroTva,
  });

  factory SalonData.fromJson(Map<String, dynamic> json) {
    // ✅ SIMPLIFIÉ - Plus besoin de gérer les objets complexes pour TVA
    String? tvaParsed = json['numero_tva']?.toString();

    // Récupérer l'URL du logo telle quelle, sans modification
    var logoUrl = json['logo_salon'];

    return SalonData(
      idTblSalon: json['idTblSalon'],
      nomSalon: json['nom_salon'],
      slogan: json['slogan'],
      aPropos: json['a_propos'],
      logoSalon: logoUrl,
      position: json['position'],
      adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
      numeroTva: tvaParsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblSalon': idTblSalon,
      'nom_salon': nomSalon,
      'slogan': slogan,
      'a_propos': aPropos,
      'logo_salon': logoSalon,
      'position': position,
      'adresse': adresse?.toJson(),
      'numero_tva': numeroTva,
    };
  }
}

// Maintenir la compatibilité avec l'ancien format de Salon
class Salon extends SalonData {
  Salon({
    required int idTblSalon,
    String? nomSalon,
    String? slogan,
    String? aPropos,
    String? logoSalon,
    String? position,
    Adresse? adresse,
    String? numeroTva,
  }) : super(
    idTblSalon: idTblSalon,
    nomSalon: nomSalon,
    slogan: slogan,
    aPropos: aPropos,
    logoSalon: logoSalon,
    position: position,
    adresse: adresse,
    numeroTva: numeroTva,
  );

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      idTblSalon: json['idTblSalon'],
      nomSalon: json['nom_salon'],
      slogan: json['slogan'],
      aPropos: json['a_propos'],
      logoSalon: json['logo_salon'],
      position: json['position'],
      adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
      numeroTva: json['numero_tva']?.toString(), // ✅ Simplifié
    );
  }
}

// Maintenir la compatibilité avec l'ancien format de Coiffeuse
class Coiffeuse extends CoiffeuseData {
  Coiffeuse({
    String? nomCommercial,
    SalonData? salonPrincipal,
    List<SalonRelation>? tousSalons,
  }) : super(
    nomCommercial: nomCommercial,
    salonPrincipal: salonPrincipal,
    tousSalons: tousSalons,
  );

  factory Coiffeuse.fromJson(Map<String, dynamic> json) {
    var data = CoiffeuseData.fromJson(json);
    return Coiffeuse(
      nomCommercial: data.nomCommercial,
      salonPrincipal: data.salonPrincipal,
      tousSalons: data.tousSalons,
    );
  }
}




// class CurrentUser {
//   final int idTblUser;
//   final String uuid;
//   final String nom;
//   final String prenom;
//   final String email;
//   String? numeroTelephone;
//   final String? dateNaissance;
//   final bool isActive;
//   final String? photoProfil;
//   final Adresse? adresse;
//   final String? role;
//   final String? sexe;
//   final String? type;
//   final CoiffeuseData? extraData;
//
//   CurrentUser({
//     required this.idTblUser,
//     required this.uuid,
//     required this.nom,
//     required this.prenom,
//     required this.email,
//     required this.numeroTelephone,
//     this.dateNaissance,
//     required this.isActive,
//     this.photoProfil,
//     this.adresse,
//     this.role,
//     this.sexe,
//     this.type,
//     this.extraData,
//   });
//
//   factory CurrentUser.fromJson(Map<String, dynamic> json) {
//     // Si le JSON contient le champ "user", utilisez-le
//     final userData = json.containsKey('user') ? json['user'] : json;
//
//     // Nouveau traitement pour extraData basé sur la structure backend
//     var extraDataJson;
//     if (userData['extra_data'] != null) {
//       extraDataJson = userData['extra_data'];
//     } else if (userData['coiffeuse'] != null) {
//       // Maintenir la compatibilité avec l'ancien format d'API
//       extraDataJson = userData['coiffeuse'];
//     }
//
//     // Récupérer l'URL de la photo telle quelle, sans modification
//     var photoProfilUrl = userData['photo_profil'];
//
//     return CurrentUser(
//       idTblUser: userData['idTblUser'],
//       uuid: userData['uuid'],
//       nom: userData['nom'],
//       prenom: userData['prenom'],
//       email: userData['email'],
//       numeroTelephone: userData['numero_telephone'],
//       dateNaissance: userData['date_naissance'],
//       isActive: userData['is_active'] ?? true,
//       photoProfil: photoProfilUrl,
//       adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
//       role: userData['role'],
//       sexe: userData['sexe'],
//       type: userData['type'],
//       extraData: extraDataJson != null && userData['type'] == 'coiffeuse'
//           ? CoiffeuseData.fromJson(extraDataJson)
//           : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblUser': idTblUser,
//       'uuid': uuid,
//       'nom': nom,
//       'prenom': prenom,
//       'email': email,
//       'numero_telephone': numeroTelephone,
//       'date_naissance': dateNaissance,
//       'is_active': isActive,
//       'photo_profil': photoProfil,
//       'adresse': adresse?.toJson(),
//       'role': role,
//       'sexe': sexe,
//       'type': type,
//       'extra_data': extraData?.toJson(),
//     };
//   }
//
//   // Méthodes utilitaires
//   bool isCoiffeuseUser() {
//     return type?.toLowerCase() == 'coiffeuse' || extraData != null;
//   }
//
//   bool isClientUser() {
//     return type?.toLowerCase() == 'client';
//   }
//
//   bool isAdminUser() {
//     return role?.toLowerCase() == 'admin';
//   }
//
//   // Propriété pour maintenir la compatibilité avec l'ancien code
//   CoiffeuseData? get coiffeuse => extraData;
// }
//
// class Adresse {
//   String? numero;
//   final Rue? rue;
//
//   Adresse({
//     this.numero,
//     this.rue,
//   });
//
//   factory Adresse.fromJson(Map<String, dynamic> json) {
//     return Adresse(
//       numero: json['numero']?.toString(),
//       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'numero': numero,
//       'rue': rue?.toJson(),
//     };
//   }
//
//   // Pour la compatibilité avec les formats différents d'adresses
//   String getFullAddress() {
//     if (rue == null) return numero ?? '';
//
//     String address = '';
//     if (numero != null) address += '$numero, ';
//     if (rue?.nomRue != null) address += '${rue!.nomRue}';
//     if (rue?.localite?.commune != null) {
//       address += ', ${rue!.localite!.commune}';
//       if (rue?.localite?.codePostal != null) {
//         address += ' ${rue!.localite!.codePostal}';
//       }
//     }
//     return address;
//   }
// }
//
// class Rue {
//   String? nomRue;
//   final Localite? localite;
//
//   Rue({
//     this.nomRue,
//     this.localite,
//   });
//
//   factory Rue.fromJson(Map<String, dynamic> json) {
//     return Rue(
//       nomRue: json['nom_rue'],
//       localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'nom_rue': nomRue,
//       'localite': localite?.toJson(),
//     };
//   }
// }
//
// class Localite {
//   String? commune;
//   String? codePostal;
//
//   Localite({
//     this.commune,
//     this.codePostal,
//   });
//
//   factory Localite.fromJson(Map<String, dynamic> json) {
//     return Localite(
//       commune: json['commune'],
//       codePostal: json['code_postal'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'commune': commune,
//       'code_postal': codePostal,
//     };
//   }
// }
//
// class NumeroTVA {
//   final String? numeroTva;
//
//   NumeroTVA({
//     this.numeroTva,
//   });
//
//   factory NumeroTVA.fromJson(dynamic json) {
//     if (json is String) {
//       return NumeroTVA(numeroTva: json);
//     } else if (json is Map) {
//       return NumeroTVA(
//         numeroTva: json['numero_tva'],
//       );
//     }
//     return NumeroTVA(numeroTva: null);
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'numero_tva': numeroTva,
//     };
//   }
// }
//
// // Nouvelle classe qui match avec la structure backend
// class CoiffeuseData {
//   final String? nomCommercial;
//   final String? numeroTva; // Simplifié pour correspondre au backend
//   final SalonData? salonPrincipal;
//   final List<SalonRelation>? tousSalons;
//
//   CoiffeuseData({
//     this.nomCommercial,
//     this.numeroTva,
//     this.salonPrincipal,
//     this.tousSalons,
//   });
//
//   factory CoiffeuseData.fromJson(Map<String, dynamic> json) {
//     List<SalonRelation>? salonsList;
//
//     // Gérer les deux formats possibles pour les salons
//     if (json['tous_salons'] != null && json['tous_salons'] is List) {
//       salonsList = (json['tous_salons'] as List)
//           .map((salon) => SalonRelation.fromJson(salon))
//           .toList();
//     } else if (json['salons'] != null && json['salons'] is List) {
//       salonsList = (json['salons'] as List)
//           .map((salon) => SalonRelation.fromJson(salon))
//           .toList();
//     }
//
//     // Gérer les deux formats possibles pour salon principal
//     var salonPrincipalJson = json['salon_principal'] ?? json['salon_direct'];
//
//     return CoiffeuseData(
//       nomCommercial: json['nom_commercial'] ?? json['denomination_sociale'],
//       numeroTva: json['numero_tva'] is Map ? json['numero_tva']['numero_tva'] : json['numero_tva'],
//       salonPrincipal: salonPrincipalJson != null ? SalonData.fromJson(salonPrincipalJson) : null,
//       tousSalons: salonsList,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'nom_commercial': nomCommercial,
//       'numero_tva': numeroTva,
//       'salon_principal': salonPrincipal?.toJson(),
//       'tous_salons': tousSalons?.map((salon) => salon.toJson()).toList(),
//     };
//   }
//
//   // Propriétés pour compatibilité avec l'ancien code
//   String? get denominationSociale => nomCommercial;
//   String? get tva => numeroTva;
//   String? get position => salonPrincipal?.position;
//   SalonData? get salon => salonPrincipal;
//   SalonData? get salonDirect => salonPrincipal;
// }
//
// // Nouvelle classe pour représenter une relation coiffeuse-salon
// class SalonRelation {
//   final int idTblSalon;
//   final String? nomSalon;
//   final bool estProprietaire;
//
//   SalonRelation({
//     required this.idTblSalon,
//     this.nomSalon,
//     required this.estProprietaire,
//   });
//
//   factory SalonRelation.fromJson(Map<String, dynamic> json) {
//     return SalonRelation(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       estProprietaire: json['est_proprietaire'] ?? false,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblSalon': idTblSalon,
//       'nom_salon': nomSalon,
//       'est_proprietaire': estProprietaire,
//     };
//   }
// }
//
// // Révisé pour correspondre à SalonData dans le backend
// class SalonData {
//   final int idTblSalon;
//   final String? nomSalon;
//   final String? slogan;
//   final String? aPropos;
//   final String? logoSalon;
//   final String? position;
//   final Adresse? adresse;
//   final String? numeroTva; // Simplifié
//
//   SalonData({
//     required this.idTblSalon,
//     this.nomSalon,
//     this.slogan,
//     this.aPropos,
//     this.logoSalon,
//     this.position,
//     this.adresse,
//     this.numeroTva,
//   });
//
//   factory SalonData.fromJson(Map<String, dynamic> json) {
//     // Pour gérer les cas où numeroTva est un objet ou une string
//     String? tvaParsed;
//     if (json['numero_tva'] != null) {
//       if (json['numero_tva'] is Map && json['numero_tva'].containsKey('numero_tva')) {
//         tvaParsed = json['numero_tva']['numero_tva'];
//       } else if (json['numero_tva'] is String) {
//         tvaParsed = json['numero_tva'];
//       }
//     }
//
//     // Récupérer l'URL du logo telle quelle, sans modification
//     var logoUrl = json['logo_salon'];
//
//     return SalonData(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       aPropos: json['a_propos'],
//       logoSalon: logoUrl,
//       position: json['position'],
//       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
//       numeroTva: tvaParsed,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblSalon': idTblSalon,
//       'nom_salon': nomSalon,
//       'slogan': slogan,
//       'a_propos': aPropos,
//       'logo_salon': logoSalon,
//       'position': position,
//       'adresse': adresse?.toJson(),
//       'numero_tva': numeroTva,
//     };
//   }
// }
//
// // Maintenir la compatibilité avec l'ancien format de Salon
// class Salon extends SalonData {
//   Salon({
//     required int idTblSalon,
//     String? nomSalon,
//     String? slogan,
//     String? aPropos,
//     String? logoSalon,
//     String? position,
//     Adresse? adresse,
//     String? numeroTva,
//   }) : super(
//     idTblSalon: idTblSalon,
//     nomSalon: nomSalon,
//     slogan: slogan,
//     aPropos: aPropos,
//     logoSalon: logoSalon,
//     position: position,
//     adresse: adresse,
//     numeroTva: numeroTva,
//   );
//
//   factory Salon.fromJson(Map<String, dynamic> json) {
//     return Salon(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       aPropos: json['a_propos'],
//       logoSalon: json['logo_salon'],
//       position: json['position'],
//       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
//       numeroTva: json['numero_tva'] is Map ? json['numero_tva']['numero_tva'] : json['numero_tva'],
//     );
//   }
// }
//
// // Maintenir la compatibilité avec l'ancien format de Coiffeuse
// class Coiffeuse extends CoiffeuseData {
//   Coiffeuse({
//     String? nomCommercial,
//     String? numeroTva,
//     SalonData? salonPrincipal,
//     List<SalonRelation>? tousSalons,
//   }) : super(
//     nomCommercial: nomCommercial,
//     numeroTva: numeroTva,
//     salonPrincipal: salonPrincipal,
//     tousSalons: tousSalons,
//   );
//
//   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
//     var data = CoiffeuseData.fromJson(json);
//     return Coiffeuse(
//       nomCommercial: data.nomCommercial,
//       numeroTva: data.numeroTva,
//       salonPrincipal: data.salonPrincipal,
//       tousSalons: data.tousSalons,
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
// // class CurrentUser {
// //   final int idTblUser;
// //   final String uuid;
// //   final String nom;
// //   final String prenom;
// //   final String email;
// //   String? numeroTelephone;
// //   final String? dateNaissance;
// //   final bool isActive;
// //   final String? photoProfil;
// //   final Adresse? adresse;
// //   final String? role;
// //   final String? sexe;
// //   final String? type;
// //   final CoiffeuseData? extraData; // Changé de Coiffeuse à CoiffeuseData
// //
// //   CurrentUser({
// //     required this.idTblUser,
// //     required this.uuid,
// //     required this.nom,
// //     required this.prenom,
// //     required this.email,
// //     required this.numeroTelephone,
// //     this.dateNaissance,
// //     required this.isActive,
// //     this.photoProfil,
// //     this.adresse,
// //     this.role,
// //     this.sexe,
// //     this.type,
// //     this.extraData,
// //   });
// //
// //   factory CurrentUser.fromJson(Map<String, dynamic> json) {
// //     // Si le JSON contient le champ "user", utilisez-le
// //     final userData = json.containsKey('user') ? json['user'] : json;
// //
// //     // Nouveau traitement pour extraData basé sur la structure backend
// //     var extraDataJson;
// //     if (userData['extra_data'] != null) {
// //       extraDataJson = userData['extra_data'];
// //     } else if (userData['coiffeuse'] != null) {
// //       // Maintenir la compatibilité avec l'ancien format d'API
// //       extraDataJson = userData['coiffeuse'];
// //     }
// //
// //     // Nettoyer les URLs pour éviter les duplications
// //     var photoProfilUrl = userData['photo_profil'];
// //     if (photoProfilUrl != null && photoProfilUrl.toString().contains('https://www.hairbnb.site/api')) {
// //       photoProfilUrl = photoProfilUrl.toString().replaceFirst('https://www.hairbnb.site/', '');
// //     }
// //
// //     return CurrentUser(
// //       idTblUser: userData['idTblUser'],
// //       uuid: userData['uuid'],
// //       nom: userData['nom'],
// //       prenom: userData['prenom'],
// //       email: userData['email'],
// //       numeroTelephone: userData['numero_telephone'],
// //       dateNaissance: userData['date_naissance'],
// //       isActive: userData['is_active'] ?? true,
// //       photoProfil: photoProfilUrl,
// //       adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
// //       role: userData['role'],
// //       sexe: userData['sexe'],
// //       type: userData['type'],
// //       extraData: extraDataJson != null && userData['type'] == 'coiffeuse'
// //           ? CoiffeuseData.fromJson(extraDataJson)
// //           : null,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'idTblUser': idTblUser,
// //       'uuid': uuid,
// //       'nom': nom,
// //       'prenom': prenom,
// //       'email': email,
// //       'numero_telephone': numeroTelephone,
// //       'date_naissance': dateNaissance,
// //       'is_active': isActive,
// //       'photo_profil': photoProfil,
// //       'adresse': adresse?.toJson(),
// //       'role': role,
// //       'sexe': sexe,
// //       'type': type,
// //       'extra_data': extraData?.toJson(),
// //     };
// //   }
// //
// //   // Méthodes utilitaires
// //   bool isCoiffeuseUser() {
// //     return type?.toLowerCase() == 'coiffeuse' || extraData != null;
// //   }
// //
// //   bool isClientUser() {
// //     return type?.toLowerCase() == 'client';
// //   }
// //
// //   bool isAdminUser() {
// //     return role?.toLowerCase() == 'admin';
// //   }
// //
// //   // Propriété pour maintenir la compatibilité avec l'ancien code
// //   CoiffeuseData? get coiffeuse => extraData;
// // }
// //
// // class Adresse {
// //   String? numero;
// //   final Rue? rue;
// //
// //   Adresse({
// //     this.numero,
// //     this.rue,
// //   });
// //
// //   factory Adresse.fromJson(Map<String, dynamic> json) {
// //     return Adresse(
// //       numero: json['numero']?.toString(),
// //       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'numero': numero,
// //       'rue': rue?.toJson(),
// //     };
// //   }
// //
// //   // Pour la compatibilité avec les formats différents d'adresses
// //   String getFullAddress() {
// //     if (rue == null) return numero ?? '';
// //
// //     String address = '';
// //     if (numero != null) address += '$numero, ';
// //     if (rue?.nomRue != null) address += '${rue!.nomRue}';
// //     if (rue?.localite?.commune != null) {
// //       address += ', ${rue!.localite!.commune}';
// //       if (rue?.localite?.codePostal != null) {
// //         address += ' ${rue!.localite!.codePostal}';
// //       }
// //     }
// //     return address;
// //   }
// // }
// //
// // class Rue {
// //   String? nomRue;
// //   final Localite? localite;
// //
// //   Rue({
// //     this.nomRue,
// //     this.localite,
// //   });
// //
// //   factory Rue.fromJson(Map<String, dynamic> json) {
// //     return Rue(
// //       nomRue: json['nom_rue'],
// //       localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'nom_rue': nomRue,
// //       'localite': localite?.toJson(),
// //     };
// //   }
// // }
// //
// // class Localite {
// //   String? commune;
// //   String? codePostal;
// //
// //   Localite({
// //     this.commune,
// //     this.codePostal,
// //   });
// //
// //   factory Localite.fromJson(Map<String, dynamic> json) {
// //     return Localite(
// //       commune: json['commune'],
// //       codePostal: json['code_postal'],
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'commune': commune,
// //       'code_postal': codePostal,
// //     };
// //   }
// // }
// //
// // class NumeroTVA {
// //   final String? numeroTva;
// //
// //   NumeroTVA({
// //     this.numeroTva,
// //   });
// //
// //   factory NumeroTVA.fromJson(dynamic json) {
// //     if (json is String) {
// //       return NumeroTVA(numeroTva: json);
// //     } else if (json is Map) {
// //       return NumeroTVA(
// //         numeroTva: json['numero_tva'],
// //       );
// //     }
// //     return NumeroTVA(numeroTva: null);
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'numero_tva': numeroTva,
// //     };
// //   }
// // }
// //
// // // Nouvelle classe qui match avec la structure backend
// // class CoiffeuseData {
// //   final String? nomCommercial;
// //   final String? numeroTva; // Simplifié pour correspondre au backend
// //   final SalonData? salonPrincipal;
// //   final List<SalonRelation>? tousSalons;
// //
// //   CoiffeuseData({
// //     this.nomCommercial,
// //     this.numeroTva,
// //     this.salonPrincipal,
// //     this.tousSalons,
// //   });
// //
// //   factory CoiffeuseData.fromJson(Map<String, dynamic> json) {
// //     List<SalonRelation>? salonsList;
// //
// //     // Gérer les deux formats possibles pour les salons
// //     if (json['tous_salons'] != null && json['tous_salons'] is List) {
// //       salonsList = (json['tous_salons'] as List)
// //           .map((salon) => SalonRelation.fromJson(salon))
// //           .toList();
// //     } else if (json['salons'] != null && json['salons'] is List) {
// //       salonsList = (json['salons'] as List)
// //           .map((salon) => SalonRelation.fromJson(salon))
// //           .toList();
// //     }
// //
// //     // Gérer les deux formats possibles pour salon principal
// //     var salonPrincipalJson = json['salon_principal'] ?? json['salon_direct'];
// //
// //     return CoiffeuseData(
// //       nomCommercial: json['nom_commercial'] ?? json['denomination_sociale'],
// //       numeroTva: json['numero_tva'] is Map ? json['numero_tva']['numero_tva'] : json['numero_tva'],
// //       salonPrincipal: salonPrincipalJson != null ? SalonData.fromJson(salonPrincipalJson) : null,
// //       tousSalons: salonsList,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'nom_commercial': nomCommercial,
// //       'numero_tva': numeroTva,
// //       'salon_principal': salonPrincipal?.toJson(),
// //       'tous_salons': tousSalons?.map((salon) => salon.toJson()).toList(),
// //     };
// //   }
// //
// //   // Propriétés pour compatibilité avec l'ancien code
// //   String? get denominationSociale => nomCommercial;
// //   String? get tva => numeroTva;
// //   String? get position => salonPrincipal?.position;
// //   SalonData? get salon => salonPrincipal;
// //   SalonData? get salonDirect => salonPrincipal;
// // }
// //
// // // Nouvelle classe pour représenter une relation coiffeuse-salon
// // class SalonRelation {
// //   final int idTblSalon;
// //   final String? nomSalon;
// //   final bool estProprietaire;
// //
// //   SalonRelation({
// //     required this.idTblSalon,
// //     this.nomSalon,
// //     required this.estProprietaire,
// //   });
// //
// //   factory SalonRelation.fromJson(Map<String, dynamic> json) {
// //     return SalonRelation(
// //       idTblSalon: json['idTblSalon'],
// //       nomSalon: json['nom_salon'],
// //       estProprietaire: json['est_proprietaire'] ?? false,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'idTblSalon': idTblSalon,
// //       'nom_salon': nomSalon,
// //       'est_proprietaire': estProprietaire,
// //     };
// //   }
// // }
// //
// // // Révisé pour correspondre à SalonData dans le backend
// // class SalonData {
// //   final int idTblSalon;
// //   final String? nomSalon;
// //   final String? slogan;
// //   final String? aPropos;
// //   final String? logoSalon;
// //   final String? position;
// //   final Adresse? adresse;
// //   final String? numeroTva; // Simplifié
// //
// //   SalonData({
// //     required this.idTblSalon,
// //     this.nomSalon,
// //     this.slogan,
// //     this.aPropos,
// //     this.logoSalon,
// //     this.position,
// //     this.adresse,
// //     this.numeroTva,
// //   });
// //
// //   factory SalonData.fromJson(Map<String, dynamic> json) {
// //     // Pour gérer les cas où numeroTva est un objet ou une string
// //     String? tvaParsed;
// //     if (json['numero_tva'] != null) {
// //       if (json['numero_tva'] is Map && json['numero_tva'].containsKey('numero_tva')) {
// //         tvaParsed = json['numero_tva']['numero_tva'];
// //       } else if (json['numero_tva'] is String) {
// //         tvaParsed = json['numero_tva'];
// //       }
// //     }
// //
// //     // Nettoyer l'URL du logo pour éviter les duplications
// //     var logoUrl = json['logo_salon'];
// //     if (logoUrl != null && logoUrl.toString().contains('https://www.hairbnb.site/https://')) {
// //       logoUrl = logoUrl.toString().replaceFirst('https://www.hairbnb.site/', '');
// //     }
// //
// //     return SalonData(
// //       idTblSalon: json['idTblSalon'],
// //       nomSalon: json['nom_salon'],
// //       slogan: json['slogan'],
// //       aPropos: json['a_propos'],
// //       logoSalon: logoUrl,
// //       position: json['position'],
// //       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
// //       numeroTva: tvaParsed,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'idTblSalon': idTblSalon,
// //       'nom_salon': nomSalon,
// //       'slogan': slogan,
// //       'a_propos': aPropos,
// //       'logo_salon': logoSalon,
// //       'position': position,
// //       'adresse': adresse?.toJson(),
// //       'numero_tva': numeroTva,
// //     };
// //   }
// // }
// //
// // // Maintenir la compatibilité avec l'ancien format de Salon
// // class Salon extends SalonData {
// //   Salon({
// //     required int idTblSalon,
// //     String? nomSalon,
// //     String? slogan,
// //     String? aPropos,
// //     String? logoSalon,
// //     String? position,
// //     Adresse? adresse,
// //     String? numeroTva,
// //   }) : super(
// //     idTblSalon: idTblSalon,
// //     nomSalon: nomSalon,
// //     slogan: slogan,
// //     aPropos: aPropos,
// //     logoSalon: logoSalon,
// //     position: position,
// //     adresse: adresse,
// //     numeroTva: numeroTva,
// //   );
// //
// //   factory Salon.fromJson(Map<String, dynamic> json) {
// //     return Salon(
// //       idTblSalon: json['idTblSalon'],
// //       nomSalon: json['nom_salon'],
// //       slogan: json['slogan'],
// //       aPropos: json['a_propos'],
// //       logoSalon: json['logo_salon'],
// //       position: json['position'],
// //       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
// //       numeroTva: json['numero_tva'] is Map ? json['numero_tva']['numero_tva'] : json['numero_tva'],
// //     );
// //   }
// // }
// //
// // // Maintenir la compatibilité avec l'ancien format de Coiffeuse
// // class Coiffeuse extends CoiffeuseData {
// //   Coiffeuse({
// //     String? nomCommercial,
// //     String? numeroTva,
// //     SalonData? salonPrincipal,
// //     List<SalonRelation>? tousSalons,
// //   }) : super(
// //     nomCommercial: nomCommercial,
// //     numeroTva: numeroTva,
// //     salonPrincipal: salonPrincipal,
// //     tousSalons: tousSalons,
// //   );
// //
// //   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
// //     var data = CoiffeuseData.fromJson(json);
// //     return Coiffeuse(
// //       nomCommercial: data.nomCommercial,
// //       numeroTva: data.numeroTva,
// //       salonPrincipal: data.salonPrincipal,
// //       tousSalons: data.tousSalons,
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // class CurrentUser {
// // //   final int idTblUser;
// // //   final String uuid;
// // //   final String nom;
// // //   final String prenom;
// // //   final String email;
// // //   String? numeroTelephone;
// // //   final String? dateNaissance;
// // //   final bool isActive;
// // //   final String? photoProfil;
// // //   final Adresse? adresse;
// // //   final String? role;
// // //   final String? sexe;
// // //   final String? type;
// // //   final CoiffeuseData? extraData; // Changé de Coiffeuse à CoiffeuseData
// // //
// // //   CurrentUser({
// // //     required this.idTblUser,
// // //     required this.uuid,
// // //     required this.nom,
// // //     required this.prenom,
// // //     required this.email,
// // //     required this.numeroTelephone,
// // //     this.dateNaissance,
// // //     required this.isActive,
// // //     this.photoProfil,
// // //     this.adresse,
// // //     this.role,
// // //     this.sexe,
// // //     this.type,
// // //     this.extraData,
// // //   });
// // //
// // //   factory CurrentUser.fromJson(Map<String, dynamic> json) {
// // //     // Si le JSON contient le champ "user", utilisez-le
// // //     final userData = json.containsKey('user') ? json['user'] : json;
// // //
// // //     // Nouveau traitement pour extraData basé sur la structure backend
// // //     var extraDataJson;
// // //     if (userData['extra_data'] != null) {
// // //       extraDataJson = userData['extra_data'];
// // //     } else if (userData['coiffeuse'] != null) {
// // //       // Maintenir la compatibilité avec l'ancien format d'API
// // //       extraDataJson = userData['coiffeuse'];
// // //     }
// // //
// // //     return CurrentUser(
// // //       idTblUser: userData['idTblUser'],
// // //       uuid: userData['uuid'],
// // //       nom: userData['nom'],
// // //       prenom: userData['prenom'],
// // //       email: userData['email'],
// // //       numeroTelephone: userData['numero_telephone'],
// // //       dateNaissance: userData['date_naissance'],
// // //       isActive: userData['is_active'] ?? true,
// // //       photoProfil: userData['photo_profil'],
// // //       adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
// // //       role: userData['role'],
// // //       sexe: userData['sexe'],
// // //       type: userData['type'],
// // //       extraData: extraDataJson != null && userData['type'] == 'coiffeuse'
// // //           ? CoiffeuseData.fromJson(extraDataJson)
// // //           : null,
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'idTblUser': idTblUser,
// // //       'uuid': uuid,
// // //       'nom': nom,
// // //       'prenom': prenom,
// // //       'email': email,
// // //       'numero_telephone': numeroTelephone,
// // //       'date_naissance': dateNaissance,
// // //       'is_active': isActive,
// // //       'photo_profil': photoProfil,
// // //       'adresse': adresse?.toJson(),
// // //       'role': role,
// // //       'sexe': sexe,
// // //       'type': type,
// // //       'extra_data': extraData?.toJson(),
// // //     };
// // //   }
// // //
// // //   // Méthodes utilitaires
// // //   bool isCoiffeuseUser() {
// // //     return type?.toLowerCase() == 'coiffeuse' || extraData != null;
// // //   }
// // //
// // //   bool isClientUser() {
// // //     return type?.toLowerCase() == 'client';
// // //   }
// // //
// // //   bool isAdminUser() {
// // //     return role?.toLowerCase() == 'admin';
// // //   }
// // //
// // //   // Propriété pour maintenir la compatibilité avec l'ancien code
// // //   CoiffeuseData? get coiffeuse => extraData;
// // // }
// // //
// // // class Adresse {
// // //   String? numero;
// // //   final Rue? rue;
// // //
// // //   Adresse({
// // //     this.numero,
// // //     this.rue,
// // //   });
// // //
// // //   factory Adresse.fromJson(Map<String, dynamic> json) {
// // //     return Adresse(
// // //       numero: json['numero']?.toString(),
// // //       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'numero': numero,
// // //       'rue': rue?.toJson(),
// // //     };
// // //   }
// // //
// // //   // Pour la compatibilité avec les formats différents d'adresses
// // //   String getFullAddress() {
// // //     if (rue == null) return numero ?? '';
// // //
// // //     String address = '';
// // //     if (numero != null) address += '$numero, ';
// // //     if (rue?.nomRue != null) address += '${rue!.nomRue}';
// // //     if (rue?.localite?.commune != null) {
// // //       address += ', ${rue!.localite!.commune}';
// // //       if (rue?.localite?.codePostal != null) {
// // //         address += ' ${rue!.localite!.codePostal}';
// // //       }
// // //     }
// // //     return address;
// // //   }
// // // }
// // //
// // // class Rue {
// // //   String? nomRue;
// // //   final Localite? localite;
// // //
// // //   Rue({
// // //     this.nomRue,
// // //     this.localite,
// // //   });
// // //
// // //   factory Rue.fromJson(Map<String, dynamic> json) {
// // //     return Rue(
// // //       nomRue: json['nom_rue'],
// // //       localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'nom_rue': nomRue,
// // //       'localite': localite?.toJson(),
// // //     };
// // //   }
// // // }
// // //
// // // class Localite {
// // //   String? commune;
// // //   String? codePostal;
// // //
// // //   Localite({
// // //     this.commune,
// // //     this.codePostal,
// // //   });
// // //
// // //   factory Localite.fromJson(Map<String, dynamic> json) {
// // //     return Localite(
// // //       commune: json['commune'],
// // //       codePostal: json['code_postal'],
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'commune': commune,
// // //       'code_postal': codePostal,
// // //     };
// // //   }
// // // }
// // //
// // // class NumeroTVA {
// // //   final String? numeroTva;
// // //
// // //   NumeroTVA({
// // //     this.numeroTva,
// // //   });
// // //
// // //   factory NumeroTVA.fromJson(dynamic json) {
// // //     if (json is String) {
// // //       return NumeroTVA(numeroTva: json);
// // //     } else if (json is Map) {
// // //       return NumeroTVA(
// // //         numeroTva: json['numero_tva'],
// // //       );
// // //     }
// // //     return NumeroTVA(numeroTva: null);
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'numero_tva': numeroTva,
// // //     };
// // //   }
// // // }
// // //
// // // // Nouvelle classe qui match avec la structure backend
// // // class CoiffeuseData {
// // //   final String? nomCommercial;
// // //   final String? numeroTva; // Simplifié pour correspondre au backend
// // //   final SalonData? salonPrincipal;
// // //   final List<SalonRelation>? tousSalons;
// // //
// // //   CoiffeuseData({
// // //     this.nomCommercial,
// // //     this.numeroTva,
// // //     this.salonPrincipal,
// // //     this.tousSalons,
// // //   });
// // //
// // //   factory CoiffeuseData.fromJson(Map<String, dynamic> json) {
// // //     List<SalonRelation>? salonsList;
// // //
// // //     // Gérer les deux formats possibles pour les salons
// // //     if (json['tous_salons'] != null && json['tous_salons'] is List) {
// // //       salonsList = (json['tous_salons'] as List)
// // //           .map((salon) => SalonRelation.fromJson(salon))
// // //           .toList();
// // //     } else if (json['salons'] != null && json['salons'] is List) {
// // //       salonsList = (json['salons'] as List)
// // //           .map((salon) => SalonRelation.fromJson(salon))
// // //           .toList();
// // //     }
// // //
// // //     // Gérer les deux formats possibles pour salon principal
// // //     var salonPrincipalJson = json['salon_principal'] ?? json['salon_direct'];
// // //
// // //     return CoiffeuseData(
// // //       nomCommercial: json['nom_commercial'] ?? json['denomination_sociale'],
// // //       numeroTva: json['numero_tva'] is Map ? json['numero_tva']['numero_tva'] : json['numero_tva'],
// // //       salonPrincipal: salonPrincipalJson != null ? SalonData.fromJson(salonPrincipalJson) : null,
// // //       tousSalons: salonsList,
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'nom_commercial': nomCommercial,
// // //       'numero_tva': numeroTva,
// // //       'salon_principal': salonPrincipal?.toJson(),
// // //       'tous_salons': tousSalons?.map((salon) => salon.toJson()).toList(),
// // //     };
// // //   }
// // //
// // //   // Propriétés pour compatibilité avec l'ancien code
// // //   String? get denominationSociale => nomCommercial;
// // //   String? get tva => numeroTva;
// // //   String? get position => salonPrincipal?.position;
// // //   SalonData? get salon => salonPrincipal;
// // //   SalonData? get salonDirect => salonPrincipal;
// // // }
// // //
// // // // Nouvelle classe pour représenter une relation coiffeuse-salon
// // // class SalonRelation {
// // //   final int idTblSalon;
// // //   final String? nomSalon;
// // //   final bool estProprietaire;
// // //
// // //   SalonRelation({
// // //     required this.idTblSalon,
// // //     this.nomSalon,
// // //     required this.estProprietaire,
// // //   });
// // //
// // //   factory SalonRelation.fromJson(Map<String, dynamic> json) {
// // //     return SalonRelation(
// // //       idTblSalon: json['idTblSalon'],
// // //       nomSalon: json['nom_salon'],
// // //       estProprietaire: json['est_proprietaire'] ?? false,
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'idTblSalon': idTblSalon,
// // //       'nom_salon': nomSalon,
// // //       'est_proprietaire': estProprietaire,
// // //     };
// // //   }
// // // }
// // //
// // // // Révisé pour correspondre à SalonData dans le backend
// // // class SalonData {
// // //   final int idTblSalon;
// // //   final String? nomSalon;
// // //   final String? slogan;
// // //   final String? aPropos;
// // //   final String? logoSalon;
// // //   final String? position;
// // //   final Adresse? adresse;
// // //   final String? numeroTva; // Simplifié
// // //
// // //   SalonData({
// // //     required this.idTblSalon,
// // //     this.nomSalon,
// // //     this.slogan,
// // //     this.aPropos,
// // //     this.logoSalon,
// // //     this.position,
// // //     this.adresse,
// // //     this.numeroTva,
// // //   });
// // //
// // //   factory SalonData.fromJson(Map<String, dynamic> json) {
// // //     // Pour gérer les cas où numeroTva est un objet ou une string
// // //     String? tvaParsed;
// // //     if (json['numero_tva'] != null) {
// // //       if (json['numero_tva'] is Map && json['numero_tva'].containsKey('numero_tva')) {
// // //         tvaParsed = json['numero_tva']['numero_tva'];
// // //       } else if (json['numero_tva'] is String) {
// // //         tvaParsed = json['numero_tva'];
// // //       }
// // //     }
// // //
// // //     return SalonData(
// // //       idTblSalon: json['idTblSalon'],
// // //       nomSalon: json['nom_salon'],
// // //       slogan: json['slogan'],
// // //       aPropos: json['a_propos'],
// // //       logoSalon: json['logo_salon'],
// // //       position: json['position'],
// // //       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
// // //       numeroTva: tvaParsed,
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'idTblSalon': idTblSalon,
// // //       'nom_salon': nomSalon,
// // //       'slogan': slogan,
// // //       'a_propos': aPropos,
// // //       'logo_salon': logoSalon,
// // //       'position': position,
// // //       'adresse': adresse?.toJson(),
// // //       'numero_tva': numeroTva,
// // //     };
// // //   }
// // // }
// // //
// // // // Maintenir la compatibilité avec l'ancien format de Salon
// // // class Salon extends SalonData {
// // //   Salon({
// // //     required int idTblSalon,
// // //     String? nomSalon,
// // //     String? slogan,
// // //     String? aPropos,
// // //     String? logoSalon,
// // //     String? position,
// // //     Adresse? adresse,
// // //     String? numeroTva,
// // //   }) : super(
// // //     idTblSalon: idTblSalon,
// // //     nomSalon: nomSalon,
// // //     slogan: slogan,
// // //     aPropos: aPropos,
// // //     logoSalon: logoSalon,
// // //     position: position,
// // //     adresse: adresse,
// // //     numeroTva: numeroTva,
// // //   );
// // //
// // //   factory Salon.fromJson(Map<String, dynamic> json) {
// // //     return Salon(
// // //       idTblSalon: json['idTblSalon'],
// // //       nomSalon: json['nom_salon'],
// // //       slogan: json['slogan'],
// // //       aPropos: json['a_propos'],
// // //       logoSalon: json['logo_salon'],
// // //       position: json['position'],
// // //       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
// // //       numeroTva: json['numero_tva'] is Map ? json['numero_tva']['numero_tva'] : json['numero_tva'],
// // //     );
// // //   }
// // // }
// // //
// // // // Maintenir la compatibilité avec l'ancien format de Coiffeuse
// // // class Coiffeuse extends CoiffeuseData {
// // //   Coiffeuse({
// // //     String? nomCommercial,
// // //     String? numeroTva,
// // //     SalonData? salonPrincipal,
// // //     List<SalonRelation>? tousSalons,
// // //   }) : super(
// // //     nomCommercial: nomCommercial,
// // //     numeroTva: numeroTva,
// // //     salonPrincipal: salonPrincipal,
// // //     tousSalons: tousSalons,
// // //   );
// // //
// // //   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
// // //     var data = CoiffeuseData.fromJson(json);
// // //     return Coiffeuse(
// // //       nomCommercial: data.nomCommercial,
// // //       numeroTva: data.numeroTva,
// // //       salonPrincipal: data.salonPrincipal,
// // //       tousSalons: data.tousSalons,
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // // // class CurrentUser {
// // // //   final int idTblUser;
// // // //   final String uuid;
// // // //   final String nom;
// // // //   final String prenom;
// // // //   final String email;
// // // //   String? numeroTelephone;
// // // //   final String? dateNaissance;
// // // //   final bool isActive;
// // // //   final String? photoProfil;
// // // //   final Adresse? adresse;
// // // //   final String? role;
// // // //   final String? sexe;
// // // //   final String? type;
// // // //   final Coiffeuse? coiffeuse;
// // // //
// // // //   CurrentUser({
// // // //     required this.idTblUser,
// // // //     required this.uuid,
// // // //     required this.nom,
// // // //     required this.prenom,
// // // //     required this.email,
// // // //     required this.numeroTelephone,
// // // //     this.dateNaissance,
// // // //     required this.isActive,
// // // //     this.photoProfil,
// // // //     this.adresse,
// // // //     this.role,
// // // //     this.sexe,
// // // //     this.type,
// // // //     this.coiffeuse,
// // // //   });
// // // //
// // // //   factory CurrentUser.fromJson(Map<String, dynamic> json) {
// // // //     // Si le JSON contient le champ "user", utilisez-le
// // // //     final userData = json.containsKey('user') ? json['user'] : json;
// // // //
// // // //     return CurrentUser(
// // // //       idTblUser: userData['idTblUser'],
// // // //       uuid: userData['uuid'],
// // // //       nom: userData['nom'],
// // // //       prenom: userData['prenom'],
// // // //       email: userData['email'],
// // // //       numeroTelephone: userData['numero_telephone'],
// // // //       dateNaissance: userData['date_naissance'],
// // // //       isActive: userData['is_active'] ?? true,
// // // //       photoProfil: userData['photo_profil'],
// // // //       adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
// // // //       role: userData['role'],
// // // //       sexe: userData['sexe'],
// // // //       type: userData['type'],
// // // //       coiffeuse: userData['coiffeuse'] != null ? Coiffeuse.fromJson(userData['coiffeuse']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'idTblUser': idTblUser,
// // // //       'uuid': uuid,
// // // //       'nom': nom,
// // // //       'prenom': prenom,
// // // //       'email': email,
// // // //       'numero_telephone': numeroTelephone,
// // // //       'date_naissance': dateNaissance,
// // // //       'is_active': isActive,
// // // //       'photo_profil': photoProfil,
// // // //       'adresse': adresse?.toJson(),
// // // //       'role': role,
// // // //       'sexe': sexe,
// // // //       'type': type,
// // // //       'coiffeuse': coiffeuse?.toJson(),
// // // //     };
// // // //   }
// // // //
// // // //   // Méthodes utilitaires
// // // //   bool isCoiffeuseUser() {
// // // //     return type?.toLowerCase() == 'coiffeuse' || coiffeuse != null;
// // // //   }
// // // //
// // // //   bool isClientUser() {
// // // //     return type?.toLowerCase() == 'client';
// // // //   }
// // // //
// // // //   bool isAdminUser() {
// // // //     return role?.toLowerCase() == 'admin';
// // // //   }
// // // // }
// // // //
// // // // class Adresse {
// // // //   String? numero;
// // // //   late final List<String>? boitesPostales;
// // // //   final Rue? rue;
// // // //
// // // //   Adresse({
// // // //     this.numero,
// // // //     this.boitesPostales,
// // // //     this.rue,
// // // //   });
// // // //
// // // //   factory Adresse.fromJson(Map<String, dynamic> json) {
// // // //     List<String>? boitesPostales;
// // // //
// // // //     // Traitement des boîtes postales
// // // //     if (json['boites_postales'] != null) {
// // // //       if (json['boites_postales'] is List) {
// // // //         // Si c'est déjà une liste d'objets ou de strings
// // // //         boitesPostales = [];
// // // //         for (var item in json['boites_postales']) {
// // // //           if (item is Map && item.containsKey('numero_bp')) {
// // // //             boitesPostales.add(item['numero_bp']);
// // // //           } else if (item is String) {
// // // //             boitesPostales.add(item);
// // // //           }
// // // //         }
// // // //       }
// // // //     }
// // // //
// // // //     return Adresse(
// // // //       numero: json['numero']?.toString(),
// // // //       boitesPostales: boitesPostales,
// // // //       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'numero': numero,
// // // //       'boites_postales': boitesPostales,
// // // //       'rue': rue?.toJson(),
// // // //     };
// // // //   }
// // // //
// // // //   // Pour la compatibilité avec l'ancien code
// // // //   String? get boitePostale => boitesPostales?.isNotEmpty == true ? boitesPostales!.first : null;
// // // //
// // // //   set boitePostale(String? value) {
// // // //     if (value == null) {
// // // //       boitesPostales = [];
// // // //     } else {
// // // //       boitesPostales = [value];
// // // //     }
// // // //   }
// // // // }
// // // //
// // // // class Rue {
// // // //   String? nomRue;
// // // //   final Localite? localite;
// // // //
// // // //   Rue({
// // // //     this.nomRue,
// // // //     this.localite,
// // // //   });
// // // //
// // // //   factory Rue.fromJson(Map<String, dynamic> json) {
// // // //     return Rue(
// // // //       nomRue: json['nom_rue'],
// // // //       localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'nom_rue': nomRue,
// // // //       'localite': localite?.toJson(),
// // // //     };
// // // //   }
// // // // }
// // // //
// // // // class Localite {
// // // //   String? commune;
// // // //   String? codePostal;
// // // //
// // // //   Localite({
// // // //     this.commune,
// // // //     this.codePostal,
// // // //   });
// // // //
// // // //   factory Localite.fromJson(Map<String, dynamic> json) {
// // // //     return Localite(
// // // //       commune: json['commune'],
// // // //       codePostal: json['code_postal'],
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'commune': commune,
// // // //       'code_postal': codePostal,
// // // //     };
// // // //   }
// // // // }
// // // //
// // // // class NumeroTVA {
// // // //   final String? numeroTva;
// // // //
// // // //   NumeroTVA({
// // // //     this.numeroTva,
// // // //   });
// // // //
// // // //   factory NumeroTVA.fromJson(dynamic json) {  // Changé Map<String, dynamic> en dynamic
// // // //     if (json is String) {
// // // //       return NumeroTVA(numeroTva: json);
// // // //     } else if (json is Map) {
// // // //       return NumeroTVA(
// // // //         numeroTva: json['numero_tva'],
// // // //       );
// // // //     }
// // // //     // Si json n'est ni une String ni une Map, retournez un objet vide
// // // //     return NumeroTVA(numeroTva: null);
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'numero_tva': numeroTva,
// // // //     };
// // // //   }
// // // // }
// // // //
// // // // class Coiffeuse {
// // // //   final String? nomCommercial;
// // // //   final NumeroTVA? numeroTva;
// // // //   final Salon? salonDirect;
// // // //   final List<Salon>? salons;
// // // //
// // // //   Coiffeuse({
// // // //     this.nomCommercial,
// // // //     this.numeroTva,
// // // //     this.salonDirect,
// // // //     this.salons,
// // // //   });
// // // //
// // // //   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
// // // //     List<Salon>? salonsList;
// // // //
// // // //     if (json['salons'] != null && json['salons'] is List) {
// // // //       salonsList = (json['salons'] as List)
// // // //           .map((salon) => Salon.fromJson(salon))
// // // //           .toList();
// // // //     }
// // // //
// // // //     return Coiffeuse(
// // // //       nomCommercial: json['nom_commercial'],
// // // //       numeroTva: json['numero_tva'] != null ? NumeroTVA.fromJson(json['numero_tva']) : null,
// // // //       salonDirect: json['salon_direct'] != null ? Salon.fromJson(json['salon_direct']) : null,
// // // //       salons: salonsList,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'nom_commercial': nomCommercial,
// // // //       'numero_tva': numeroTva?.toJson(),
// // // //       'salon_direct': salonDirect?.toJson(),
// // // //       'salons': salons?.map((salon) => salon.toJson()).toList(),
// // // //     };
// // // //   }
// // // //
// // // //   // Propriétés pour compatibilité avec l'ancien code
// // // //   String? get denominationSociale => nomCommercial;
// // // //   String? get tva => numeroTva?.numeroTva;
// // // //   String? get position => salonDirect?.position;
// // // //   Salon? get salon => salonDirect;
// // // // }
// // // //
// // // // class Salon {
// // // //   final int idTblSalon;
// // // //   final String? nomSalon;
// // // //   final String? slogan;
// // // //   final String? aPropos;
// // // //   final String? logoSalon;
// // // //   final String? position;
// // // //   final Adresse? adresse;
// // // //   final NumeroTVA? numeroTva;
// // // //
// // // //   Salon({
// // // //     required this.idTblSalon,
// // // //     this.nomSalon,
// // // //     this.slogan,
// // // //     this.aPropos,
// // // //     this.logoSalon,
// // // //     this.position,
// // // //     this.adresse,
// // // //     this.numeroTva,
// // // //   });
// // // //
// // // //   factory Salon.fromJson(Map<String, dynamic> json) {
// // // //     return Salon(
// // // //       idTblSalon: json['idTblSalon'],
// // // //       nomSalon: json['nom_salon'],
// // // //       slogan: json['slogan'],
// // // //       aPropos: json['a_propos'],
// // // //       logoSalon: json['logo_salon'],
// // // //       position: json['position'],
// // // //       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
// // // //       numeroTva: json['numero_tva'] != null ? NumeroTVA.fromJson(json['numero_tva']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'idTblSalon': idTblSalon,
// // // //       'nom_salon': nomSalon,
// // // //       'slogan': slogan,
// // // //       'a_propos': aPropos,
// // // //       'logo_salon': logoSalon,
// // // //       'position': position,
// // // //       'adresse': adresse?.toJson(),
// // // //       'numero_tva': numeroTva?.toJson(),
// // // //     };
// // // //   }
// // // // }
// // //
// // //
// // //
// // //
// // // // class CurrentUser {
// // // //   final int idTblUser;
// // // //   final String uuid;
// // // //   final String nom;
// // // //   final String prenom;
// // // //   final String email;
// // // //   String? numeroTelephone;
// // // //   final String? dateNaissance;
// // // //   final bool isActive;
// // // //   final String? photoProfil;
// // // //   final Adresse? adresse;
// // // //   final String? role;
// // // //   final String? sexe;
// // // //   final String? type;
// // // //   final Coiffeuse? coiffeuse;
// // // //
// // // //   CurrentUser({
// // // //     required this.idTblUser,
// // // //     required this.uuid,
// // // //     required this.nom,
// // // //     required this.prenom,
// // // //     required this.email,
// // // //     required this.numeroTelephone,
// // // //     this.dateNaissance,
// // // //     required this.isActive,
// // // //     this.photoProfil,
// // // //     this.adresse,
// // // //     this.role,
// // // //     this.sexe,
// // // //     this.type,
// // // //     this.coiffeuse,
// // // //   });
// // // //
// // // //   factory CurrentUser.fromJson(Map<String, dynamic> json) {
// // // //     // Si le JSON contient le champ "user", utilisez-le
// // // //     final userData = json.containsKey('user') ? json['user'] : json;
// // // //
// // // //     return CurrentUser(
// // // //       idTblUser: userData['idTblUser'],
// // // //       uuid: userData['uuid'],
// // // //       nom: userData['nom'],
// // // //       prenom: userData['prenom'],
// // // //       email: userData['email'],
// // // //       numeroTelephone: userData['numero_telephone'],
// // // //       dateNaissance: userData['date_naissance'],
// // // //       isActive: userData['is_active'] ?? true,
// // // //       photoProfil: userData['photo_profil'],
// // // //       adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
// // // //       role: userData['role'],
// // // //       sexe: userData['sexe'],
// // // //       type: userData['type'],
// // // //       coiffeuse: userData['coiffeuse'] != null ? Coiffeuse.fromJson(userData['coiffeuse']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'idTblUser': idTblUser,
// // // //       'uuid': uuid,
// // // //       'nom': nom,
// // // //       'prenom': prenom,
// // // //       'email': email,
// // // //       'numero_telephone': numeroTelephone,
// // // //       'date_naissance': dateNaissance,
// // // //       'is_active': isActive,
// // // //       'photo_profil': photoProfil,
// // // //       'adresse': adresse?.toJson(),
// // // //       'role': role,
// // // //       'sexe': sexe,
// // // //       'type': type,
// // // //       'coiffeuse': coiffeuse?.toJson(),
// // // //     };
// // // //   }
// // // //
// // // //   // Méthodes utilitaires
// // // //   bool isCoiffeuseUser() {
// // // //     return type?.toLowerCase() == 'coiffeuse' || coiffeuse != null;
// // // //   }
// // // //
// // // //   bool isClientUser() {
// // // //     return type?.toLowerCase() == 'client';
// // // //   }
// // // //
// // // //   bool isAdminUser() {
// // // //     return role?.toLowerCase() == 'admin';
// // // //   }
// // // // }
// // // //
// // // // class Adresse {
// // // //   late final String? numero;
// // // //   late final String? boitePostale;
// // // //   final Rue? rue;
// // // //
// // // //   Adresse({
// // // //     this.numero,
// // // //     this.boitePostale,
// // // //     this.rue,
// // // //   });
// // // //
// // // //   factory Adresse.fromJson(Map<String, dynamic> json) {
// // // //     return Adresse(
// // // //       numero: json['numero']?.toString(),
// // // //       boitePostale: json['boite_postale'],
// // // //       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'numero': numero,
// // // //       'boite_postale': boitePostale,
// // // //       'rue': rue?.toJson(),
// // // //     };
// // // //   }
// // // // }
// // // //
// // // // class Rue {
// // // //   late final String? nomRue;
// // // //   final Localite? localite;
// // // //
// // // //   Rue({
// // // //     this.nomRue,
// // // //     this.localite,
// // // //   });
// // // //
// // // //   factory Rue.fromJson(Map<String, dynamic> json) {
// // // //     return Rue(
// // // //       nomRue: json['nom_rue'],
// // // //       localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'nom_rue': nomRue,
// // // //       'localite': localite?.toJson(),
// // // //     };
// // // //   }
// // // // }
// // // //
// // // // class Localite {
// // // //   late final String? commune;
// // // //   late final String? codePostal;
// // // //
// // // //   Localite({
// // // //     this.commune,
// // // //     this.codePostal,
// // // //   });
// // // //
// // // //   factory Localite.fromJson(Map<String, dynamic> json) {
// // // //     return Localite(
// // // //       commune: json['commune'],
// // // //       codePostal: json['code_postal'],
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'commune': commune,
// // // //       'code_postal': codePostal,
// // // //     };
// // // //   }
// // // // }
// // // //
// // // // class Coiffeuse {
// // // //   final String? denominationSociale;
// // // //   final String? tva;
// // // //   final String? position;
// // // //   final Salon? salon;
// // // //
// // // //   Coiffeuse({
// // // //     this.denominationSociale,
// // // //     this.tva,
// // // //     this.position,
// // // //     this.salon,
// // // //   });
// // // //
// // // //   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
// // // //     return Coiffeuse(
// // // //       denominationSociale: json['denomination_sociale'],
// // // //       tva: json['tva'],
// // // //       position: json['position'],
// // // //       salon: json['salon'] != null ? Salon.fromJson(json['salon']) : null,
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'denomination_sociale': denominationSociale,
// // // //       'tva': tva,
// // // //       'position': position,
// // // //       'salon': salon?.toJson(),
// // // //     };
// // // //   }
// // // // }
// // // //
// // // // class Salon {
// // // //   final int idTblSalon;
// // // //   final String? nomSalon;
// // // //   final String? slogan;
// // // //   final String? aPropos;
// // // //   final String? logoSalon;
// // // //
// // // //   Salon({
// // // //     required this.idTblSalon,
// // // //     this.nomSalon,
// // // //     this.slogan,
// // // //     this.aPropos,
// // // //     this.logoSalon,
// // // //   });
// // // //
// // // //   factory Salon.fromJson(Map<String, dynamic> json) {
// // // //     return Salon(
// // // //       idTblSalon: json['idTblSalon'],
// // // //       nomSalon: json['nom_salon'],
// // // //       slogan: json['slogan'],
// // // //       aPropos: json['a_propos'],
// // // //       logoSalon: json['logo_salon'],
// // // //     );
// // // //   }
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'idTblSalon': idTblSalon,
// // // //       'nom_salon': nomSalon,
// // // //       'slogan': slogan,
// // // //       'a_propos': aPropos,
// // // //       'logo_salon': logoSalon,
// // // //     };
// // // //   }
// // // // }
