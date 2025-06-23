// lib/providers/revenus_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hairbnb/models/revenus_model.dart';

import '../../pages/revenus/revenus_services/revenus_service.dart';

class RevenusProvider with ChangeNotifier {
  // État des données
  RevenusCoiffeuseModel? _revenus;
  RevenusErrorModel? _error;
  bool _isLoading = false;

  // Filtres actuels
  PeriodeRevenu _periodeActuelle = PeriodeRevenu.mois;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  int? _salonId;

  // Getters publics
  RevenusCoiffeuseModel? get revenus => _revenus;
  RevenusErrorModel? get error => _error;
  bool get isLoading => _isLoading;
  bool get hasData => _revenus != null && _error == null;
  bool get hasError => _error != null;

  // Getters pour les filtres
  PeriodeRevenu get periodeActuelle => _periodeActuelle;
  DateTime? get dateDebut => _dateDebut;
  DateTime? get dateFin => _dateFin;
  int? get salonId => _salonId;

  /// Charge les revenus selon les filtres actuels
  Future<void> loadRevenus({
    PeriodeRevenu? periode,
    DateTime? dateDebut,
    DateTime? dateFin,
    int? salonId,
    bool forceRefresh = false,
  }) async {
    // Éviter les requêtes multiples simultanées
    if (_isLoading && !forceRefresh) return;

    // Mise à jour des filtres si fournis
    if (periode != null) _periodeActuelle = periode;
    if (dateDebut != null) _dateDebut = dateDebut;
    if (dateFin != null) _dateFin = dateFin;
    if (salonId != null) _salonId = salonId;

    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print("🔄 Chargement revenus - Période: ${_periodeActuelle.value}");
      }

      final result = await RevenusService.getRevenusCoiffeuse(
        periode: _periodeActuelle,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        salonId: _salonId,
      );

      if (result is RevenusCoiffeuseModel) {
        _revenus = result;
        _error = null;
        if (kDebugMode) {
          print("✅ Revenus chargés - ${_revenus!.resume.nbRdvPayes} RDV");
        }
      } else if (result is RevenusErrorModel) {
        _revenus = null;
        _error = result;
        if (kDebugMode) {
          print("❌ Erreur revenus: ${_error!.error}");
        }
      }
    } catch (e) {
      _revenus = null;
      _error = RevenusErrorModel(
          success: false,
          error: 'Erreur inattendue: ${e.toString()}'
      );
      if (kDebugMode) {
        print("❌ Exception revenus: $e");
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Charge les revenus pour une période spécifique
  Future<void> loadRevenusParPeriode(PeriodeRevenu periode) {
    return loadRevenus(periode: periode);
  }

  /// Charge les revenus pour une période personnalisée
  Future<void> loadRevenusPersonnalises({
    required DateTime dateDebut,
    required DateTime dateFin,
    int? salonId,
  }) {
    return loadRevenus(
      periode: PeriodeRevenu.custom,
      dateDebut: dateDebut,
      dateFin: dateFin,
      salonId: salonId,
    );
  }

  /// Actualise les données (force refresh)
  Future<void> refresh() {
    return loadRevenus(forceRefresh: true);
  }

  /// Filtre par salon
  Future<void> filterBySalon(int? salonId) {
    return loadRevenus(salonId: salonId);
  }

  /// Remet les filtres à zéro et charge le mois courant
  Future<void> resetFilters() {
    _periodeActuelle = PeriodeRevenu.mois;
    _dateDebut = null;
    _dateFin = null;
    _salonId = null;
    return loadRevenus();
  }

  /// Efface toutes les données (utile à la déconnexion)
  void clearData() {
    _revenus = null;
    _error = null;
    _isLoading = false;
    _periodeActuelle = PeriodeRevenu.mois;
    _dateDebut = null;
    _dateFin = null;
    _salonId = null;
    notifyListeners();
  }

  // MÉTHODES UTILITAIRES POUR L'INTERFACE

  /// Récupère le total TTC formaté
  String get totalTtcFormate {
    if (_revenus == null) return '0,00 €';
    return '${_revenus!.resume.totalTtc.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  /// Récupère le total HT formaté
  String get totalHtFormate {
    if (_revenus == null) return '0,00 €';
    return '${_revenus!.resume.totalHt.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  /// Récupère le montant TVA formaté
  String get tvaFormate {
    if (_revenus == null) return '0,00 €';
    return '${_revenus!.resume.tva.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  /// Récupère la période formatée pour l'affichage
  String get periodeFormatee {
    if (_revenus == null) return '';

    switch (_periodeActuelle) {
      case PeriodeRevenu.jour:
        return 'Aujourd\'hui';
      case PeriodeRevenu.semaine:
        return 'Cette semaine';
      case PeriodeRevenu.mois:
        return 'Ce mois';
      case PeriodeRevenu.annee:
        return 'Cette année';
      case PeriodeRevenu.custom:
        if (_dateDebut != null && _dateFin != null) {
          return 'Du ${_formatDate(_dateDebut!)} au ${_formatDate(_dateFin!)}';
        }
        return 'Période personnalisée';
    }
  }

  /// Récupère le nombre de RDV payés
  int get nombreRdvPayes {
    return _revenus?.resume.nbRdvPayes ?? 0;
  }

  /// Récupère le nombre de clients uniques
  int get nombreClientsUniques {
    return _revenus?.resume.nbClientsUniques ?? 0;
  }

  /// Récupère le service le plus vendu
  String get servicePlusVendu {
    return _revenus?.statistiques.servicePlusVendu ?? 'Aucun';
  }

  /// Vérifie si des données sont disponibles pour la période
  bool get hasRevenusData {
    return _revenus != null && _revenus!.resume.nbRdvPayes > 0;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}