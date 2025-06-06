import 'package:hairbnb/models/services.dart';

class ServicesStorage {

  // Stockage en mémoire (simple Map)
  static final Map<int, List<Service>> _cache = {};

  /// Sauvegarder les services ajoutés pour un utilisateur
  static void sauvegarderServices(int userId, List<Service> services) {
    _cache[userId] = List.from(services);
    print("💾 Services sauvegardés localement pour user $userId: ${services.length}");
  }

  /// Charger les services ajoutés pour un utilisateur
  static List<Service> chargerServices(int userId) {
    final services = _cache[userId] ?? [];
    print("📖 Services chargés localement pour user $userId: ${services.length}");
    return List.from(services);
  }

  /// Ajouter un service à la liste existante
  static void ajouterService(int userId, Service service) {
    if (_cache[userId] == null) {
      _cache[userId] = [];
    }

    // Vérifier qu'il n'existe pas déjà
    if (!_cache[userId]!.any((s) => s.id == service.id)) {
      _cache[userId]!.add(service);
      print("➕ Service ajouté localement: ${service.intitule}");
    }
  }

  /// Supprimer un service de la liste
  static void supprimerService(int userId, int serviceId) {
    if (_cache[userId] != null) {
      _cache[userId]!.removeWhere((s) => s.id == serviceId);
      print("🗑️ Service supprimé localement: $serviceId");
    }
  }

  /// Vider le cache pour un utilisateur
  static void viderServices(int userId) {
    _cache[userId] = [];
    print("🧹 Cache vidé pour user $userId");
  }
}