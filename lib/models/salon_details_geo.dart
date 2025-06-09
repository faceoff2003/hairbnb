// models/salon_details_for_geo.dart
class CoiffeuseDetailsForGeo {
  final int idTblCoiffeuse;
  final int idTblUser;
  final String uuid;
  final String nom;
  final String prenom;
  final String role;
  final String type;
  final bool estProprietaire;
  final String? nomCommercial;

  CoiffeuseDetailsForGeo({
    required this.idTblCoiffeuse,
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.type,
    required this.estProprietaire,
    this.nomCommercial,
  });

  factory CoiffeuseDetailsForGeo.fromJson(Map<String, dynamic> json) {
    return CoiffeuseDetailsForGeo(
      idTblCoiffeuse: json['idTblCoiffeuse'] ?? 0,
      idTblUser: json['idTblUser'] ?? 0,
      uuid: json['uuid'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role'] ?? '',
      type: json['type'] ?? '',
      estProprietaire: json['est_proprietaire'] ?? false,
      nomCommercial: json['nom_commercial'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblCoiffeuse': idTblCoiffeuse,
      'idTblUser': idTblUser,
      'uuid': uuid,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'type': type,
      'est_proprietaire': estProprietaire,
      'nom_commercial': nomCommercial,
    };
  }

  // Getter pour le nom complet
  String get nomComplet => '$prenom $nom';

  // Getter pour affichage commercial
  String get affichageNom => nomCommercial?.isNotEmpty == true ? nomCommercial! : nomComplet;
}

class SalonDetailsForGeo {
  final int idTblSalon;
  final String nom;
  final String? slogan;
  final String? logo;
  final String position;
  final double? latitude;
  final double? longitude;
  final List<int> coiffeuseIds;
  final List<CoiffeuseDetailsForGeo> coiffeusesDetails;
  final double distance;

  SalonDetailsForGeo({
    required this.idTblSalon,
    required this.nom,
    this.slogan,
    this.logo,
    required this.position,
    this.latitude,
    this.longitude,
    required this.coiffeuseIds,
    required this.coiffeusesDetails,
    required this.distance,
  });

  factory SalonDetailsForGeo.fromJson(Map<String, dynamic> json) {
    return SalonDetailsForGeo(
      idTblSalon: json['idTblSalon'] ?? 0,
      nom: json['nom'] ?? '',
      slogan: json['slogan'],
      logo: json['logo'],
      position: json['position'] ?? '0,0',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      coiffeuseIds: List<int>.from(json['coiffeuse_ids'] ?? []),
      coiffeusesDetails: (json['coiffeuses_details'] as List?)
          ?.map((x) => CoiffeuseDetailsForGeo.fromJson(x))
          .toList() ?? [],
      distance: json['distance']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblSalon': idTblSalon,
      'nom': nom,
      'slogan': slogan,
      'logo': logo,
      'position': position,
      'latitude': latitude,
      'longitude': longitude,
      'coiffeuse_ids': coiffeuseIds,
      'coiffeuses_details': coiffeusesDetails.map((x) => x.toJson()).toList(),
      'distance': distance,
    };
  }

  // Getter pour le propriétaire du salon
  CoiffeuseDetailsForGeo? get proprietaire {
    try {
      return coiffeusesDetails.firstWhere((c) => c.estProprietaire);
    } catch (e) {
      return null;
    }
  }

  // Getter pour le nombre de coiffeuses
  int get nombreCoiffeuses => coiffeusesDetails.length;

  // Getter pour savoir si le salon a un logo
  bool get hasLogo => logo != null && logo!.isNotEmpty;

  // Getter pour l'URL complète du logo (si besoin d'ajouter base URL)
  String? getLogoUrl(String? baseUrl) {
    if (!hasLogo || baseUrl == null) return logo;
    return logo!.startsWith('http') ? logo : '$baseUrl$logo';
  }

  // Getter pour la distance formatée
  String get distanceFormatee {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}

// models/salons_response.dart
class SalonsResponse {
  final String status;
  final int count;
  final List<SalonDetailsForGeo> salons;

  SalonsResponse({
    required this.status,
    required this.count,
    required this.salons,
  });

  factory SalonsResponse.fromJson(Map<String, dynamic> json) {
    return SalonsResponse(
      status: json['status'] ?? 'error',
      count: json['count'] ?? 0,
      salons: (json['salons'] as List?)
          ?.map((x) => SalonDetailsForGeo.fromJson(x))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'count': count,
      'salons': salons.map((x) => x.toJson()).toList(),
    };
  }

  // Getter pour vérifier si la requête a réussi
  bool get isSuccess => status == 'success';

  // Getter pour les salons triés par distance
  List<SalonDetailsForGeo> get salonsTries {
    final List<SalonDetailsForGeo> sorted = List.from(salons);
    sorted.sort((a, b) => a.distance.compareTo(b.distance));
    return sorted;
  }
}









// // lib/models/salon_details_geo.dart
//
// import 'dart:convert';
//
// SalonDetailsGeo salonDetailsGeoFromJson(String str) => SalonDetailsGeo.fromJson(json.decode(str)['salon']);
//
// class SalonDetailsGeo {
//   final int idTblSalon;
//   final String nom;
//   final String? slogan;
//   final String? logo;
//   final String position;
//   final double latitude;
//   final double longitude;
//   final List<int> coiffeuseIds;
//   final List<CoiffeuseDetailGeo> coiffeusesDetails;
//
//   SalonDetailsGeo({
//     required this.idTblSalon,
//     required this.nom,
//     this.slogan,
//     this.logo,
//     required this.position,
//     required this.latitude,
//     required this.longitude,
//     required this.coiffeuseIds,
//     required this.coiffeusesDetails,
//   });
//
//   factory SalonDetailsGeo.fromJson(Map<String, dynamic> json) => SalonDetailsGeo(
//     idTblSalon: json["idTblSalon"],
//     nom: json["nom"],
//     slogan: json["slogan"],
//     logo: json["logo"],
//     position: json["position"],
//     latitude: (json["latitude"] as num).toDouble(),
//     longitude: (json["longitude"] as num).toDouble(),
//     // MODIFIÉ : Ajout d'une protection contre les valeurs nulles pour les listes
//     coiffeuseIds: json["coiffeuse_ids"] == null ? [] : List<int>.from(json["coiffeuse_ids"].map((x) => x)),
//     coiffeusesDetails: json["coiffeuses_details"] == null ? [] : List<CoiffeuseDetailGeo>.from(json["coiffeuses_details"].map((x) => CoiffeuseDetailGeo.fromJson(x))),
//   );
// }
//
// class CoiffeuseDetailGeo {
//   final int idTblCoiffeuse;
//   final String nom;
//   final String prenom;
//   final String? photoProfil;
//   final bool estProprietaire;
//   final String? nomCommercial;
//
//   // J'ajoute un champ 'uuid' pour la compatibilité avec votre code de chat
//   String get uuid => idTblCoiffeuse.toString();
//
//   CoiffeuseDetailGeo({
//     required this.idTblCoiffeuse,
//     required this.nom,
//     required this.prenom,
//     this.photoProfil,
//     required this.estProprietaire,
//     this.nomCommercial,
//   });
//
//   factory CoiffeuseDetailGeo.fromJson(Map<String, dynamic> json) => CoiffeuseDetailGeo(
//     idTblCoiffeuse: json["idTblCoiffeuse"],
//     nom: json["nom"],
//     prenom: json["prenom"],
//     photoProfil: json["photo_profil"],
//     estProprietaire: json["est_proprietaire"] ?? false, // Protection ajoutée ici aussi
//     nomCommercial: json["nom_commercial"],
//   );
// }