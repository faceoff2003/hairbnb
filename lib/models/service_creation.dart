// Modèle pour la création d'un nouveau service
class ServiceCreation {
  final int userId;
  final String intituleService;
  final String description;
  final double prix;
  final int tempsMinutes;
  final int categorieId;

  ServiceCreation({
    required this.userId,
    required this.intituleService,
    required this.description,
    required this.prix,
    required this.tempsMinutes,
    required this.categorieId,
  });

  /// Convertit l'objet en Map pour l'envoi à l'API
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'intitule_service': intituleService,
      'description': description,
      'prix': prix,
      'temps_minutes': tempsMinutes,
      'categorie_id': categorieId,
    };
  }

  /// Crée un objet ServiceCreation depuis un Map JSON
  factory ServiceCreation.fromJson(Map<String, dynamic> json) {
    return ServiceCreation(
      userId: json['userId'] ?? 0,
      intituleService: json['intitule_service'] ?? '',
      description: json['description'] ?? '',
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      tempsMinutes: json['temps_minutes'] ?? 0,
      categorieId: json['categorie_id'] ?? 0,
    );
  }

  /// Validation des données avant envoi
  String? validate() {
    if (intituleService.trim().isEmpty) {
      return 'Le nom du service est obligatoire';
    }
    if (intituleService.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    if (description.trim().isEmpty) {
      return 'La description est obligatoire';
    }
    if (prix <= 0) {
      return 'Le prix doit être supérieur à 0';
    }
    if (tempsMinutes <= 0) {
      return 'La durée doit être supérieure à 0';
    }
    if (categorieId <= 0) {
      return 'Une catégorie doit être sélectionnée';
    }
    return null; // Pas d'erreur
  }

  /// Méthode pour créer une copie avec des valeurs modifiées
  ServiceCreation copyWith({
    int? userId,
    String? intituleService,
    String? description,
    double? prix,
    int? tempsMinutes,
    int? categorieId,
  }) {
    return ServiceCreation(
      userId: userId ?? this.userId,
      intituleService: intituleService ?? this.intituleService,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      tempsMinutes: tempsMinutes ?? this.tempsMinutes,
      categorieId: categorieId ?? this.categorieId,
    );
  }

  @override
  String toString() {
    return 'ServiceCreation(userId: $userId, intituleService: $intituleService, description: $description, prix: $prix, tempsMinutes: $tempsMinutes, categorieId: $categorieId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceCreation &&
        other.userId == userId &&
        other.intituleService == intituleService &&
        other.description == description &&
        other.prix == prix &&
        other.tempsMinutes == tempsMinutes &&
        other.categorieId == categorieId;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
    intituleService.hashCode ^
    description.hashCode ^
    prix.hashCode ^
    tempsMinutes.hashCode ^
    categorieId.hashCode;
  }
}

// Modèle pour les catégories de services
class Categorie {
  final int id;
  final String intituleCategorie;

  Categorie({
    required this.id,
    required this.intituleCategorie,
  });

  /// Crée un objet Categorie depuis un Map JSON
  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['idTblCategorie'] ?? json['id'] ?? 0,
      intituleCategorie: json['intitule_categorie'] ?? json['nom'] ?? json['libelle'] ?? '',
    );
  }

  /// Convertit l'objet en Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intitule_categorie': intituleCategorie,
    };
  }

  @override
  String toString() {
    return intituleCategorie;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categorie &&
        other.id == id &&
        other.intituleCategorie == intituleCategorie;
  }

  @override
  int get hashCode => id.hashCode ^ intituleCategorie.hashCode;
}