// lib/models/adresse.dart

import 'dart:math' as math; // ✅ Import nécessaire pour les fonctions mathématiques

class Adresse {
  int? numero;
  String? boitePostale;
  Rue? rue;
  double? latitude;
  double? longitude;
  bool? isValidated;
  DateTime? validationDate;

  Adresse({
    this.numero,
    this.boitePostale,
    this.rue,
    this.latitude,
    this.longitude,
    this.isValidated,
    this.validationDate,
  });

  factory Adresse.fromJson(Map<String, dynamic> json) {
    return Adresse(
      numero: json['numero'],
      boitePostale: json['boite_postale'],
      rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isValidated: json['is_validated'],
      validationDate: json['validation_date'] != null
          ? DateTime.parse(json['validation_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'boite_postale': boitePostale,
      'rue': rue?.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'is_validated': isValidated,
      'validation_date': validationDate?.toIso8601String(),
    };
  }

  /// Méthode pour obtenir l'adresse complète formatée
  String get adresseComplete {
    List<String> parts = [];

    if (numero != null) parts.add(numero.toString());
    if (boitePostale != null && boitePostale!.isNotEmpty) {
      parts.add("Boîte ${boitePostale!}");
    }
    if (rue?.nomRue != null) parts.add(rue!.nomRue!);
    if (rue?.localite?.codePostal != null && rue?.localite?.commune != null) {
      parts.add('${rue!.localite!.codePostal!} ${rue!.localite!.commune!}');
    }

    return parts.join(', ');
  }

  /// Adresse courte (sans boîte postale et coordonnées)
  String get adresseSimple {
    List<String> parts = [];

    if (numero != null) parts.add(numero.toString());
    if (rue?.nomRue != null) parts.add(rue!.nomRue!);

    return parts.join(' ');
  }

  /// Localité complète (code postal + commune)
  String get localiteComplete {
    if (rue?.localite?.codePostal != null && rue?.localite?.commune != null) {
      return '${rue!.localite!.codePostal!} ${rue!.localite!.commune!}';
    }
    return '';
  }

  /// Vérifier si l'adresse a des coordonnées GPS
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Vérifier si l'adresse est complète
  bool get isComplete {
    return numero != null &&
        rue?.nomRue != null && rue!.nomRue!.isNotEmpty &&
        rue?.localite?.commune != null && rue!.localite!.commune!.isNotEmpty &&
        rue?.localite?.codePostal != null && rue!.localite!.codePostal!.isNotEmpty;
  }

  /// Vérifier si l'adresse est validée et récente (moins de 30 jours)
  bool get isRecentlyValidated {
    // ✅ Correction: éviter l'exception si isValidated est null
    if (isValidated != true || validationDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(validationDate!);
    return difference.inDays <= 30;
  }

  /// Distance entre cette adresse et une autre (en mètres)
  double? distanceTo(Adresse other) {
    if (!hasCoordinates || !other.hasCoordinates) return null;

    // ✅ Formule de Haversine corrigée avec import dart:math
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    double lat1Rad = latitude! * (math.pi / 180);
    double lat2Rad = other.latitude! * (math.pi / 180);
    double deltaLatRad = (other.latitude! - latitude!) * (math.pi / 180);
    double deltaLngRad = (other.longitude! - longitude!) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Copier l'adresse avec de nouvelles valeurs
  Adresse copyWith({
    int? numero,
    String? boitePostale,
    Rue? rue,
    double? latitude,
    double? longitude,
    bool? isValidated,
    DateTime? validationDate,
  }) {
    return Adresse(
      numero: numero ?? this.numero,
      boitePostale: boitePostale ?? this.boitePostale,
      rue: rue ?? this.rue,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isValidated: isValidated ?? this.isValidated,
      validationDate: validationDate ?? this.validationDate,
    );
  }

  /// Marquer l'adresse comme validée avec coordonnées
  void markAsValidated(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    isValidated = true;
    validationDate = DateTime.now();
  }

  @override
  String toString() {
    return adresseComplete;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Adresse &&
        other.numero == numero &&
        other.boitePostale == boitePostale &&
        other.rue == rue &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return numero.hashCode ^
    boitePostale.hashCode ^
    rue.hashCode ^
    latitude.hashCode ^
    longitude.hashCode;
  }
}

class Rue {
  String? nomRue;
  Localite? localite;

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rue &&
        other.nomRue == nomRue &&
        other.localite == localite;
  }

  @override
  int get hashCode => nomRue.hashCode ^ localite.hashCode;
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

  /// Vérifier si le code postal est valide pour la Belgique
  bool get isValidBelgianPostcode {
    if (codePostal == null) return false;
    return RegExp(r'^\d{4}$').hasMatch(codePostal!);
  }

  @override
  String toString() {
    return '${codePostal ?? ''} ${commune ?? ''}'.trim();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Localite &&
        other.commune == commune &&
        other.codePostal == codePostal;
  }

  @override
  int get hashCode => commune.hashCode ^ codePostal.hashCode;
}