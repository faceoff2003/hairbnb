class SalonCreateModel {
  final int idTblUser;
  final String nomSalon;
  final String slogan;
  final dynamic logo; // Uint8List (Web) ou File (Mobile)

  SalonCreateModel({
    required this.idTblUser,
    required this.nomSalon,
    required this.slogan,
    required this.logo,
  });

  /// Convertir en champs texte pour la requête multipart
  Map<String, String> toFields() {
    return {
      'idTblUser': idTblUser.toString(),
      'nom_salon': nomSalon,
      'slogan': slogan,
    };
  }
}

