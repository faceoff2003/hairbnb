// models/public_salon_details.dart
import 'dart:convert';

class PublicSalonDetails {
  final int idTblSalon;
  final String nomSalon;
  final String? slogan;
  final String? aPropos;
  final String? logoSalon;
  final String? numeroTva; // ✅ Ajouté - TVA maintenant dans le salon
  final Coiffeuse coiffeuse;
  final String? adresse;
  final String? horaires;
  final double noteMoyenne;
  final int nombreAvis;
  final List<SalonImage> images;
  final List<Avis> avis;
  final List<ServiceSalonDetails> serviceSalonDetailsList;

  PublicSalonDetails({
    required this.idTblSalon,
    required this.nomSalon,
    this.slogan,
    this.aPropos,
    this.logoSalon,
    this.numeroTva,
    required this.coiffeuse,
    this.adresse,
    this.horaires,
    required this.noteMoyenne,
    required this.nombreAvis,
    required this.images,
    required this.avis,
    required this.serviceSalonDetailsList,
  });

  factory PublicSalonDetails.fromJson(Map<String, dynamic> json) {
    return PublicSalonDetails(
      idTblSalon: json['idTblSalon'],
      nomSalon: json['nom_salon'],
      slogan: json['slogan'],
      aPropos: json['a_propos'],
      logoSalon: json['logo_salon'],
      numeroTva: json['numero_tva']?.toString(), // ✅ TVA du salon
      coiffeuse: Coiffeuse.fromJson(json['coiffeuse']),
      adresse: json['adresse'],
      horaires: json['horaires'],
      noteMoyenne: json['note_moyenne']?.toDouble() ?? 0.0,
      nombreAvis: json['nombre_avis'] ?? 0,
      images: (json['images'] as List)
          .map((image) => SalonImage.fromJson(image))
          .toList(),
      avis: (json['avis'] as List)
          .map((avis) => Avis.fromJson(avis))
          .toList(),
      serviceSalonDetailsList: (json['services'] as List)
          .map((serviceSalonDetails) => ServiceSalonDetails.fromJson(serviceSalonDetails))
          .toList(),
    );
  }

  static PublicSalonDetails fromRawJson(String str) =>
      PublicSalonDetails.fromJson(json.decode(str));
}

class Coiffeuse {
  final User idTblUser;
  final String? nomCommercial; // ✅ Changé de denominationSociale à nomCommercial
  final String? position;

  Coiffeuse({
    required this.idTblUser,
    this.nomCommercial,
    this.position,
  });

  factory Coiffeuse.fromJson(Map<String, dynamic> json) {
    return Coiffeuse(
      idTblUser: User.fromJson(json['idTblUser']),
      nomCommercial: json['nom_commercial'], // ✅ Mise à jour du champ
      position: json['position'],
    );
  }

  // ✅ Propriété pour maintenir la compatibilité avec l'ancien code
  String? get denominationSociale => nomCommercial;
}

class User {
  final int idTblUser;
  final String nom;
  final String prenom;
  final String? photoProfil;
  final String? numeroTelephone;

  User({
    required this.idTblUser,
    required this.nom,
    required this.prenom,
    this.photoProfil,
    this.numeroTelephone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nom: json['nom'],
      idTblUser: json['idTblUser'],
      prenom: json['prenom'],
      photoProfil: json['photo_profil'],
      numeroTelephone: json['numero_telephone'],
    );
  }
}

class SalonImage {
  final int id;
  final String image;

  SalonImage({required this.id, required this.image});

  factory SalonImage.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id') || !json.containsKey('image')) {
      throw Exception('Format JSON invalide pour SalonImage : $json');
    }

    final rawUrl = json['image'];
    final fullUrl = rawUrl.startsWith('http') ? rawUrl : 'https://www.hairbnb.site$rawUrl';

    return SalonImage(
        id: json['id'],
        image: fullUrl
    );
  }
}

class Avis {
  final int note;
  final String commentaire;
  final String clientNom;
  final String dateFormat;

  Avis({
    required this.note,
    required this.commentaire,
    required this.clientNom,
    required this.dateFormat,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      note: json['note'],
      commentaire: json['commentaire'],
      clientNom: json['client_nom'],
      dateFormat: json['date_format'],
    );
  }
}

class ServiceSalonDetails {
  final int idTblService;
  final String intituleService;
  final String description;
  final double? prix;
  final int? duree;
  final PromotionActive? promotionActive;

  ServiceSalonDetails({
    required this.idTblService,
    required this.intituleService,
    required this.description,
    this.prix,
    this.duree,
    this.promotionActive,
  });

  factory ServiceSalonDetails.fromJson(Map<String, dynamic> json) {
    return ServiceSalonDetails(
      idTblService: json['idTblService'],
      intituleService: json['intitule_service'],
      description: json['description'],
      prix: json['prix']?.toDouble(),
      duree: json['duree'],
      promotionActive: json['promotion_active'] != null
          ? PromotionActive.fromJson(json['promotion_active'])
          : null,
    );
  }
}

class PromotionActive {
  final String discountPercentage;
  final String startDate;
  final String endDate;

  PromotionActive({
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
  });

  factory PromotionActive.fromJson(Map<String, dynamic> json) {
    return PromotionActive(
      discountPercentage: json['discount_percentage'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}





// // // models/public_salon_details.dart
// import 'dart:convert';
//
// class PublicSalonDetails {
//   final int idTblSalon;
//   final String nomSalon;
//   final String? slogan;
//   final String? aPropos;
//   final String? logoSalon;
//   final Coiffeuse coiffeuse;
//   final String? adresse;
//   final String? horaires;
//   final double noteMoyenne;
//   final int nombreAvis;
//   final List<SalonImage> images;
//   final List<Avis> avis;
//   final List<ServiceSalonDetails> serviceSalonDetailsList;
//
//   PublicSalonDetails({
//     required this.idTblSalon,
//     required this.nomSalon,
//     this.slogan,
//     this.aPropos,
//     this.logoSalon,
//     required this.coiffeuse,
//     this.adresse,
//     this.horaires,
//     required this.noteMoyenne,
//     required this.nombreAvis,
//     required this.images,
//     required this.avis,
//     required this.serviceSalonDetailsList,
//   });
//
//   factory PublicSalonDetails.fromJson(Map<String, dynamic> json) {
//     return PublicSalonDetails(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       aPropos: json['a_propos'],
//       logoSalon: json['logo_salon'], //!= null
//           //? 'https://www.hairbnb.site${json['logo_salon']}'
//           //: null,
//       coiffeuse: Coiffeuse.fromJson(json['coiffeuse']),
//       adresse: json['adresse'],
//       horaires: json['horaires'],
//       noteMoyenne: json['note_moyenne']?.toDouble() ?? 0.0,
//       nombreAvis: json['nombre_avis'] ?? 0,
//       images: (json['images'] as List)
//           .map((image) => SalonImage.fromJson(image))
//           .toList(),
//       avis: (json['avis'] as List)
//           .map((avis) => Avis.fromJson(avis))
//           .toList(),
//       serviceSalonDetailsList: (json['services'] as List)
//           .map((serviceSalonDetails) => ServiceSalonDetails.fromJson(serviceSalonDetails))
//           .toList(),
//     );
//   }
//
//   static PublicSalonDetails fromRawJson(String str) =>
//       PublicSalonDetails.fromJson(json.decode(str));
// }
//
// class Coiffeuse {
//   final User idTblUser;
//   final String? denominationSociale;
//   final String? position;
//
//   Coiffeuse({
//     required this.idTblUser,
//     this.denominationSociale,
//     this.position,
//   });
//
//   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
//     return Coiffeuse(
//       idTblUser: User.fromJson(json['idTblUser']),
//       denominationSociale: json['denomination_sociale'],
//       position: json['position'],
//     );
//   }
// }
//
// class User {
//   final int idTblUser;
//   final String nom;
//   final String prenom;
//   final String? photoProfil;
//   final String? numeroTelephone;
//
//   User({
//     required this.idTblUser,
//     required this.nom,
//     required this.prenom,
//     this.photoProfil,
//     this.numeroTelephone,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       nom: json['nom'],
//       idTblUser: json['idTblUser'],
//       prenom: json['prenom'],
//       photoProfil: json['photo_profil'],// != null
//           //? 'https://www.hairbnb.site${json['photo_profil']}'
//           //: null,
//       numeroTelephone: json['numero_telephone'],
//     );
//   }
// }
//
// class SalonImage {
//   final int id;
//   final String image;
//
//   SalonImage({required this.id,required this.image});
//
//   factory SalonImage.fromJson(Map<String, dynamic> json) {
//
//     if (!json.containsKey('id') || !json.containsKey('image')) {
//       throw Exception('Format JSON invalide pour SalonImage : $json');
//     }
//     final rawUrl = json['image'];
//     final fullUrl =
//     rawUrl.startsWith('http') ? rawUrl : 'https://www.hairbnb.site$rawUrl';
//
//     return SalonImage(
//       id: json['id'],
//       image: fullUrl
//     );
//   }
// }
//
// class Avis {
//   final int note;
//   final String commentaire;
//   final String clientNom;
//   final String dateFormat;
//
//   Avis({
//     required this.note,
//     required this.commentaire,
//     required this.clientNom,
//     required this.dateFormat,
//   });
//
//   factory Avis.fromJson(Map<String, dynamic> json) {
//     return Avis(
//       note: json['note'],
//       commentaire: json['commentaire'],
//       clientNom: json['client_nom'],
//       dateFormat: json['date_format'],
//     );
//   }
// }
//
// class ServiceSalonDetails {
//   final int idTblService;
//   final String intituleService;
//   final String description;
//   final double? prix;
//   final int? duree;
//   final PromotionActive? promotionActive;
//
//   ServiceSalonDetails({
//     required this.idTblService,
//     required this.intituleService,
//     required this.description,
//     this.prix,
//     this.duree,
//     this.promotionActive,
//   });
//
//   factory ServiceSalonDetails.fromJson(Map<String, dynamic> json) {
//     return ServiceSalonDetails(
//       idTblService: json['idTblService'],
//       intituleService: json['intitule_service'],
//       description: json['description'],
//       prix: json['prix']?.toDouble(),
//       duree: json['duree'],
//       promotionActive: json['promotion_active'] != null
//           ? PromotionActive.fromJson(json['promotion_active'])
//           : null,
//     );
//   }
// }
//
// class PromotionActive {
//   final String discountPercentage;
//   final String startDate;
//   final String endDate;
//
//   PromotionActive({
//     required this.discountPercentage,
//     required this.startDate,
//     required this.endDate,
//   });
//
//   factory PromotionActive.fromJson(Map<String, dynamic> json) {
//     return PromotionActive(
//       discountPercentage: json['discount_percentage'],
//       startDate: json['start_date'],
//       endDate: json['end_date'],
//     );
//   }
// }




// import 'dart:convert';
//
// class PublicSalonDetails {
//   final int idTblSalon;
//   final String nomSalon;
//   final String? slogan;
//   final String? aPropos;
//   final String? logoSalon;
//   final Coiffeuse coiffeuse;
//   final String? adresse;
//   final String? horaires;
//   final double noteMoyenne;
//   final int nombreAvis;
//   final List<SalonImage> images;
//   final List<Avis> avis;
//   final List<Service> services;
//
//   PublicSalonDetails({
//     required this.idTblSalon,
//     required this.nomSalon,
//     this.slogan,
//     this.aPropos,
//     this.logoSalon,
//     required this.coiffeuse,
//     this.adresse,
//     this.horaires,
//     required this.noteMoyenne,
//     required this.nombreAvis,
//     required this.images,
//     required this.avis,
//     required this.services,
//   });
//
//   factory PublicSalonDetails.fromJson(Map<String, dynamic> json) {
//     return PublicSalonDetails(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       aPropos: json['a_propos'],
//       // logoSalon: json['logo_salon'],
//
//       logoSalon: json['logo_salon'] != null
//           ? 'https://www.hairbnb.site${json['logo_salon']}'
//           : null,
//
//       coiffeuse: Coiffeuse.fromJson(json['coiffeuse']),
//       adresse: json['adresse'],
//       horaires: json['horaires'],
//       noteMoyenne: json['note_moyenne']?.toDouble() ?? 0.0,
//       nombreAvis: json['nombre_avis'] ?? 0,
//       images: (json['images']  as List).map((image) => SalonImage.fromJson(image)).toList(),
//       avis: (json['avis'] as List).map((avis) => Avis.fromJson(avis)).toList(),
//       services: (json['services'] as List).map((service) => Service.fromJson(service)).toList(),
//     );
//   }
//
//   static PublicSalonDetails fromRawJson(String str) =>
//       PublicSalonDetails.fromJson(json.decode(str));
// }
//
// class Coiffeuse {
//   final User idTblUser;
//   final String? denominationSociale;
//   final String? position;
//
//   Coiffeuse({
//     required this.idTblUser,
//     this.denominationSociale,
//     this.position,
//   });
//
//   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
//     return Coiffeuse(
//       idTblUser: User.fromJson(json['idTblUser']),
//       denominationSociale: json['denomination_sociale'],
//       position: json['position'],
//     );
//   }
// }
//
// class User {
//   final String nom;
//   final String prenom;
//   final String? photoProfil;
//   final String? numeroTelephone;
//
//   User({
//     required this.nom,
//     required this.prenom,
//     this.photoProfil,
//     this.numeroTelephone,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       nom: json['nom'],
//       prenom: json['prenom'],
//       photoProfil: json['photo_profil'],
//       numeroTelephone: json['numero_telephone'],
//     );
//   }
// }
//
// class SalonImage {
//   final String image;
//
//   SalonImage({
//     required this.image,
//   });
//
//   factory SalonImage.fromJson(Map<String, dynamic> json) {
//     final rawUrl = json['image'];
//     final fullUrl = rawUrl.startsWith('http')
//         ? rawUrl
//         : 'https://www.hairbnb.site$rawUrl';
//
//     return SalonImage(
//       image: fullUrl,
//     );
//   }
// }
//
//
// class Avis {
//   final int note;
//   final String commentaire;
//   final String clientNom;
//   final String dateFormat;
//
//   Avis({
//     required this.note,
//     required this.commentaire,
//     required this.clientNom,
//     required this.dateFormat,
//   });
//
//   factory Avis.fromJson(Map<String, dynamic> json) {
//     return Avis(
//       note: json['note'],
//       commentaire: json['commentaire'],
//       clientNom: json['client_nom'],
//       dateFormat: json['date_format'],
//     );
//   }
// }
//
// class Service {
//   final int idTblService;
//   final String intituleService;
//   final String description;
//   final double? prix;
//   final int? duree;
//
//   Service({
//     required this.idTblService,
//     required this.intituleService,
//     required this.description,
//     this.prix,
//     this.duree,
//   });
//
//   factory Service.fromJson(Map<String, dynamic> json) {
//     return Service(
//       idTblService: json['idTblService'],
//       intituleService: json['intitule_service'],
//       description: json['description'],
//       prix: json['prix']?.toDouble(),
//       duree: json['duree'],
//     );
//   }
// }