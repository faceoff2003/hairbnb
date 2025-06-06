// Modèle pour les services existants trouvés
class ExistingService {
  final int id;
  final String nom;
  final String description;
  final List<double> prixPopulaires;
  final List<int> dureesPopulaires;
  final int nbSalonsUtilisant;

  ExistingService({
    required this.id,
    required this.nom,
    required this.description,
    required this.prixPopulaires,
    required this.dureesPopulaires,
    required this.nbSalonsUtilisant,
  });

  factory ExistingService.fromJson(Map<String, dynamic> json) {
    return ExistingService(
      id: json['idTblService'] ?? 0,
      nom: json['intitule_service'] ?? '',
      description: json['description'] ?? '',
      prixPopulaires: (json['prix_populaires'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? [],
      dureesPopulaires: (json['durees_populaires'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ?? [],
      nbSalonsUtilisant: json['nb_salons_utilisant'] ?? 0,
    );
  }
}