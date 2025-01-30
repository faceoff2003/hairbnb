class Service {
  final int id;
  final String intitule;
  final String description;
  final double prix;
  final int temps;

  Service({
    required this.id,
    required this.intitule,
    required this.description,
    required this.prix,
    required this.temps,
  });

  // Convertir une réponse JSON en objet ServiceModel
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['idTblService'] ?? 0,
      intitule: json['intitule_service'] ?? 'Nom indisponible',
      description: json['description'] ?? 'Aucune description',
      prix: (json['prix'] != null)
          ? double.parse(json['prix'].toString())
          : 0.0,
      temps: json['temps_minutes'] ?? 0,
    );
  }

// ✅ Convertir un objet Service en JSON (pour les requêtes POST)
  Map<String, dynamic> toJson() {
    return {
      "intitule_service": intitule,
      "description": description,
      "prix": prix.toString(),
      // Convertir en String pour éviter les erreurs de JSON
      "temps": temps.toString(),
      // Idem
    };
  }
}
