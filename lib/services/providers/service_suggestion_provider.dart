import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../firebase_token/token_service.dart';

/// Modèle représentant un service optimisé pour les dropdowns
class ServiceSuggestion {
  final int id;
  final String intituleService;
  final int? categorieId;
  final String? categorieNom;

  ServiceSuggestion({
    required this.id,
    required this.intituleService,
    this.categorieId,
    this.categorieNom,
  });

  factory ServiceSuggestion.fromJson(Map<String, dynamic> json) {
    return ServiceSuggestion(
      id: json['idTblService'] ?? 0,
      intituleService: json['intitule_service'] ?? '',
      categorieId: json['categorie_id'],
      categorieNom: json['categorie_nom'],
    );
  }

  @override
  String toString() => intituleService;
}

/// Provider optimisé pour la gestion des services via la nouvelle API dropdown
class ServicesProvider with ChangeNotifier {
  static const String _baseUrl = 'https://www.hairbnb.site/api';
  static const int _searchDebounceMs = 500;
  static const int _maxResults = 10;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // ✅ État pour tous les services
  List<ServiceSuggestion> _allServices = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime? _lastFetch;

  // État de la recherche
  List<ServiceSuggestion> _searchResults = [];
  bool _isSearching = false;
  String _lastSearchTerm = '';
  String? _searchError;

  // Timer pour le debounce des recherches
  Timer? _searchDebounceTimer;

  // ✅ Getters
  /// Liste de tous les services disponibles
  List<ServiceSuggestion> get allServices => List.unmodifiable(_allServices);

  /// Indique si le chargement des services est en cours
  bool get isLoading => _isLoading;

  /// Indique s'il y a une erreur générale
  bool get hasError => _hasError;

  /// Message d'erreur général
  String get errorMessage => _errorMessage;

  /// Vérifie si le cache est encore valide
  bool get _isCacheValid {
    if (_lastFetch == null || _allServices.isEmpty) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheExpiry;
  }

  // Getters pour la recherche
  /// Liste des résultats de recherche actuels
  List<ServiceSuggestion> get searchResults => List.unmodifiable(_searchResults);

  /// Indique si une recherche est en cours
  bool get isSearching => _isSearching;

  /// Dernier terme de recherche utilisé
  String get lastSearchTerm => _lastSearchTerm;

  /// Message d'erreur de la dernière recherche (null si pas d'erreur)
  String? get searchError => _searchError;

  /// Indique s'il y a une erreur de recherche
  bool get hasSearchError => _searchError != null;

  // ✅ NOUVEAU : Méthode pour charger tous les services via la nouvelle API optimisée
  /// Charge tous les services disponibles (avec cache intelligent)
  Future<void> loadAllServices({bool forceRefresh = false}) async {
    // Si cache valide et pas de force refresh, ne rien faire
    if (_isCacheValid && !forceRefresh) {
      if (kDebugMode) {
        print('📦 ServicesProvider: Utilisation du cache (${_allServices.length} services)');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 ServicesProvider: Chargement de tous les services depuis l\'API optimisée...');
    }

    _setLoading(true);
    _clearError();

    try {
      final String? token = await TokenService.getAuthToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      // ✅ NOUVEAU : Utilise la nouvelle API optimisée
      final uri = Uri.parse('$_baseUrl/services/dropdown/');

      if (kDebugMode) {
        print('📡 ServicesProvider: Requête vers ${uri.toString()}');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        if (data['status'] == 'success') {
          final List<dynamic> servicesJson = data['services'] ?? [];

          _allServices = servicesJson
              .map((json) => ServiceSuggestion.fromJson(json))
              .toList();

          _lastFetch = DateTime.now();

          if (kDebugMode) {
            print('✅ ServicesProvider: ${_allServices.length} services chargés via API optimisée');
          }
        } else {
          throw Exception(data['message'] ?? 'Erreur inconnue du serveur');
        }
      } else if (response.statusCode == 401) {
        await TokenService.clearAuthToken();
        throw Exception('Session expirée, veuillez vous reconnecter');
      } else {
        final errorData = _tryParseErrorResponse(response.body);
        throw Exception(errorData['message'] ?? 'Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      _setError('Erreur lors du chargement des services: $e');
      if (kDebugMode) {
        print('❌ ServicesProvider: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Rafraîchit la liste des services (force le rechargement)
  Future<void> refreshAllServices() async {
    await loadAllServices(forceRefresh: true);
  }

  /// Recherche des services existants avec debounce automatique
  ///
  /// [query] : Terme de recherche (minimum 2 caractères)
  /// [forceSearch] : Force la recherche même si le terme n'a pas changé
  Future<void> searchServices(String query, {bool forceSearch = false}) async {
    final trimmedQuery = query.trim();

    // Validation de base
    if (trimmedQuery.length < 2) {
      _clearSearchResults();
      return;
    }

    // Éviter les recherches identiques
    if (!forceSearch && trimmedQuery == _lastSearchTerm) {
      return;
    }

    // Annuler la recherche précédente si elle existe
    _searchDebounceTimer?.cancel();

    // ✅ AMÉLIORATION : Rechercher d'abord dans le cache local
    if (_allServices.isNotEmpty) {
      _performLocalSearch(trimmedQuery);
      return;
    }

    // Si pas de cache, charger d'abord tous les services puis rechercher localement
    _searchDebounceTimer = Timer(
      const Duration(milliseconds: _searchDebounceMs),
          () => _performSearchWithLoad(trimmedQuery),
    );
  }

  /// ✅ NOUVEAU : Recherche avec chargement si nécessaire
  Future<void> _performSearchWithLoad(String query) async {
    try {
      // Charger les services si pas encore fait
      if (_allServices.isEmpty) {
        await loadAllServices();
      }

      // Puis rechercher localement
      _performLocalSearch(query);
    } catch (e) {
      _handleSearchError(e, query);
    }
  }

  /// ✅ AMÉLIORATION : Recherche locale dans les services déjà chargés
  void _performLocalSearch(String query) {
    if (kDebugMode) {
      print('🔍 ServicesProvider: Recherche locale pour "$query"');
    }

    _isSearching = true;
    _searchError = null;
    _lastSearchTerm = query;
    notifyListeners();

    final String searchLower = query.toLowerCase();
    _searchResults = _allServices
        .where((service) =>
    service.intituleService.toLowerCase().contains(searchLower) ||
        (service.categorieNom?.toLowerCase().contains(searchLower) ?? false))
        .take(_maxResults)
        .toList();

    if (kDebugMode) {
      print('✅ ServicesProvider: ${_searchResults.length} services trouvés localement pour "$query"');
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Gère les erreurs de recherche
  void _handleSearchError(dynamic error, String query) {
    _searchError = 'Erreur lors de la recherche: ${error.toString()}';
    _searchResults = [];
    _isSearching = false;

    if (kDebugMode) {
      print('❌ ServicesProvider: $_searchError');
    }

    notifyListeners();
  }

  /// Tente de parser une réponse d'erreur JSON
  Map<String, dynamic> _tryParseErrorResponse(String responseBody) {
    try {
      return json.decode(responseBody);
    } catch (e) {
      return {'message': 'Réponse non parsable du serveur'};
    }
  }

  /// Efface les résultats de recherche actuels
  void _clearSearchResults() {
    if (_searchResults.isNotEmpty || _searchError != null) {
      _searchResults = [];
      _searchError = null;
      _lastSearchTerm = '';
      notifyListeners();
    }
  }

  /// Remet à zéro l'état du provider
  void resetSearch() {
    _searchDebounceTimer?.cancel();
    _clearSearchResults();
    _isSearching = false;
  }

  /// Recherche forcée (sans debounce) - utile pour les boutons refresh
  Future<void> forceSearch(String query) async {
    _searchDebounceTimer?.cancel();
    await _performSearchWithLoad(query);
  }

  /// Récupère un service spécifique par son ID
  ServiceSuggestion? getServiceById(int serviceId) {
    try {
      return _allServices.firstWhere((service) => service.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si un terme de recherche donnerait des résultats
  bool hasResultsFor(String query) {
    return query.trim() == _lastSearchTerm && _searchResults.isNotEmpty;
  }

  /// ✅ NOUVEAU : Filtre les services par catégorie
  List<ServiceSuggestion> getServicesByCategory(int? categorieId) {
    if (categorieId == null) return _allServices;

    return _allServices
        .where((service) => service.categorieId == categorieId)
        .toList();
  }

  /// ✅ NOUVEAU : Retourne les catégories uniques avec nombre de services
  Map<String, int> getCategoriesWithCount() {
    final Map<String, int> categories = {};

    for (var service in _allServices) {
      final categoryName = service.categorieNom ?? "Sans catégorie";
      categories[categoryName] = (categories[categoryName] ?? 0) + 1;
    }

    return categories;
  }

  // ✅ Méthodes privées pour gérer l'état général
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_hasError) {
      _hasError = false;
      _errorMessage = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _allServices.clear();
    _lastFetch = null;
    _clearError();
    if (kDebugMode) {
      print('🗑️ ServicesProvider: Dispose - Cache vidé');
    }
    super.dispose();
  }

  @override
  String toString() {
    return 'ServicesProvider(${_allServices.length} services, loading: $_isLoading, error: $_hasError)';
  }
}