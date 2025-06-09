import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/categorie.dart';
import '../firebase_token/token_service.dart';

class CategoriesProvider with ChangeNotifier {
  // État des catégories
  List<Categorie> _categories = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime? _lastFetch;

  // Configuration du cache
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const String _baseUrl = "https://www.hairbnb.site";

  // Getters
  List<Categorie> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get hasCategories => _categories.isNotEmpty;

  /// Vérifie si le cache est encore valide
  bool get _isCacheValid {
    if (_lastFetch == null || _categories.isEmpty) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheExpiry;
  }

  /// Charge les catégories (avec cache intelligent)
  Future<void> loadCategories({bool forceRefresh = false}) async {
    // Si cache valide et pas de force refresh, ne rien faire
    if (_isCacheValid && !forceRefresh) {
      debugPrint('📦 CategoriesProvider: Utilisation du cache (${_categories.length} catégories)');
      return;
    }

    debugPrint('🔄 CategoriesProvider: Chargement des catégories depuis l\'API...');

    _setLoading(true);
    _clearError();

    try {
      final token = await TokenService.getAuthToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/categories/?with_count=true'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['status'] == 'success') {
          final List<dynamic> categoriesData = responseData['categories'];

          _categories = categoriesData
              .map((json) => Categorie.fromJson(json))
              .toList();

          _lastFetch = DateTime.now();

          debugPrint('✅ CategoriesProvider: ${_categories.length} catégories chargées');

        } else {
          throw Exception(responseData['message'] ?? 'Erreur inconnue');
        }

      } else if (response.statusCode == 401) {
        await TokenService.clearAuthToken();
        throw Exception('Session expirée, veuillez vous reconnecter');
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }

    } catch (e) {
      _setError('Erreur lors du chargement des catégories: $e');
      debugPrint('❌ CategoriesProvider: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Rafraîchit les catégories (force le rechargement)
  Future<void> refreshCategories() async {
    await loadCategories(forceRefresh: true);
  }

  /// Trouve une catégorie par son ID
  Categorie? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Trouve une catégorie par son nom
  Categorie? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
            (cat) => cat.nom.toLowerCase() == name.toLowerCase(),  // ✅ Utilisé 'nom'
      );
    } catch (e) {
      return null;
    }
  }

  /// Retourne les catégories triées par nom
  List<Categorie> get categoriesSorted {
    final sorted = List<Categorie>.from(_categories);
    sorted.sort((a, b) => a.nom.compareTo(b.nom));  // ✅ Utilisé 'nom'
    return sorted;
  }

  /// Vide le cache (appelé quand on quitte la page)
  @override
  void dispose() {
    _categories.clear();
    _lastFetch = null;
    _clearError();
    debugPrint('🗑️ CategoriesProvider: Dispose - Cache vidé');
    super.dispose();
  }

  /// Ajoute une catégorie au cache (après création)
  void addCategory(Categorie category) {
    _categories.add(category);
    _categories.sort((a, b) => a.nom.compareTo(b.nom));
    debugPrint('➕ CategoriesProvider: Catégorie "${category.nom}" ajoutée au cache');
    notifyListeners();
  }

  /// Met à jour une catégorie dans le cache
  void updateCategory(Categorie updatedCategory) {
    final index = _categories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index != -1) {
      _categories[index] = updatedCategory;
      debugPrint('🔄 CategoriesProvider: Catégorie "${updatedCategory.nom}" mise à jour');
      notifyListeners();
    }
  }

  /// Supprime une catégorie du cache
  void removeCategory(int categoryId) {
    _categories.removeWhere((cat) => cat.id == categoryId);
    debugPrint('🗑️ CategoriesProvider: Catégorie ID $categoryId supprimée du cache');
    notifyListeners();
  }

  // Méthodes privées pour gérer l'état
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
  String toString() {
    return 'CategoriesProvider(${_categories.length} catégories, loading: $_isLoading, error: $_hasError)';
  }
}