class Salon {
  final int idSalon;
  final String nomSalon;
  final String? slogan;
  final String? logo;
  final int coiffeuseId;

  // Propriétés pour la géolocalisation
  final String? position;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final List<int>? coiffeuseIds;
  final List<CoiffeuseDetails>? coiffeusesDetails;

  Salon({
    required this.idSalon,
    required this.nomSalon,
    this.slogan,
    this.logo,
    required this.coiffeuseId,
    this.position,
    this.latitude,
    this.longitude,
    this.distance,
    this.coiffeuseIds,
    this.coiffeusesDetails,
  });

  /// **🟢 Convertir JSON vers `Salon`**
  factory Salon.fromJson(Map<String, dynamic> json) {
    // Convertir la liste des IDs de coiffeuses si elle existe
    List<int>? coiffeuseIds;
    if (json['coiffeuse_ids'] != null) {
      coiffeuseIds = List<int>.from(json['coiffeuse_ids']);
    }

    // Convertir la liste détaillée des coiffeuses si elle existe
    List<CoiffeuseDetails>? coiffeusesDetails;
    if (json['coiffeuses_details'] != null) {
      coiffeusesDetails = (json['coiffeuses_details'] as List)
          .map((coiffeuseJson) => CoiffeuseDetails.fromJson(coiffeuseJson))
          .toList();
    }

    return Salon(
      idSalon: json['idTblSalon'],
      nomSalon: json['nom'] ?? json['nomSalon'] ?? "Salon sans nom",
      slogan: json['slogan'],
      logo: json['logo'] ?? json['logo_salon'],
      coiffeuseId: json['coiffeuse'] ?? 0,
      position: json['position'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distance: json['distance']?.toDouble(),
      coiffeuseIds: coiffeuseIds,
      coiffeusesDetails: coiffeusesDetails,
    );
  }

  /// **🟢 Convertir `Salon` en JSON**
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'idTblSalon': idSalon,
      'nom': nomSalon,          // Pour le nouveau sérialiseur backend
      'slogan': slogan,
      'logo': logo,             // Pour le nouveau sérialiseur backend
      'coiffeuse': coiffeuseId,
    };

    // Ajouter les propriétés de géolocalisation si elles existent
    if (position != null) data['position'] = position;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (distance != null) data['distance'] = distance;
    if (coiffeuseIds != null) data['coiffeuse_ids'] = coiffeuseIds;
    if (coiffeusesDetails != null) {
      data['coiffeuses_details'] = coiffeusesDetails!.map((c) => c.toJson()).toList();
    }

    return data;
  }
}

/// Modèle pour les détails d'une coiffeuse associée à un salon
class CoiffeuseDetails {
  final int idTblCoiffeuse;
  final String nom;
  final String prenom;
  final String? photoProfilUrl;
  final bool estProprietaire;
  final String? nomCommercial;

  CoiffeuseDetails({
    required this.idTblCoiffeuse,
    required this.nom,
    required this.prenom,
    this.photoProfilUrl,
    required this.estProprietaire,
    this.nomCommercial,
  });

  factory CoiffeuseDetails.fromJson(Map<String, dynamic> json) {
    return CoiffeuseDetails(
      idTblCoiffeuse: json['idTblCoiffeuse'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      photoProfilUrl: json['photo_profil'],
      estProprietaire: json['est_proprietaire'] ?? false,
      nomCommercial: json['nom_commercial'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'idTblCoiffeuse': idTblCoiffeuse,
      'nom': nom,
      'prenom': prenom,
      'est_proprietaire': estProprietaire,
    };

    if (photoProfilUrl != null) data['photo_profil'] = photoProfilUrl;
    if (nomCommercial != null) data['nom_commercial'] = nomCommercial;

    return data;
  }
}

/// Modèle pour la réponse de l'API salons-proches
class SalonsProchesResponse {
  final String status;
  final int count;
  final List<Salon> salons;

  SalonsProchesResponse({
    required this.status,
    required this.count,
    required this.salons,
  });

  factory SalonsProchesResponse.fromJson(Map<String, dynamic> json) {
    List<Salon> salons = [];
    if (json['salons'] != null) {
      salons = (json['salons'] as List)
          .map((salonJson) => Salon.fromJson(salonJson))
          .toList();
    }

    return SalonsProchesResponse(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      salons: salons,
    );
  }
}

/// Modèle pour la réponse de l'API salon/<id>
class SalonDetailsResponse {
  final String status;
  final Salon salon;

  SalonDetailsResponse({
    required this.status,
    required this.salon,
  });

  factory SalonDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SalonDetailsResponse(
      status: json['status'] ?? '',
      salon: Salon.fromJson(json['salon']),
    );
  }
}





// class Salon {
//   final int idSalon;
//   final String nomSalon;
//   final String? slogan;
//   final String? logo;
//   final int coiffeuseId;
//
//   Salon({
//     required this.idSalon,
//     required this.nomSalon,
//     this.slogan,
//     this.logo,
//     required this.coiffeuseId,
//   });
//
//   /// **🟢 Convertir JSON vers `Salon`**
//   factory Salon.fromJson(Map<String, dynamic> json) {
//     return Salon(
//       idSalon: json['idTblSalon'],
//       nomSalon: json['nomSalon'] ?? "Salon sans nom",
//       slogan: json['slogan'],
//       logo: json['logo_salon'],
//       coiffeuseId: json['coiffeuse'],
//     );
//   }
//
//   /// **🟢 Convertir `Salon` en JSON**
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblSalon': idSalon,
//       'nomSalon': nomSalon,
//       'slogan': slogan,
//       'logo_salon': logo,
//       'coiffeuse_id': coiffeuseId,
//     };
//   }
// }
