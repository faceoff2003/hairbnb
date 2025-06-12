// models/avis_models.dart
import 'package:intl/intl.dart';

/// 🎯 MODÈLE 1: RDV éligible aux avis
/// Utilisé par l'API /mes-rdv-avis-en-attente/
class RdvEligible {
  final int idRendezVous;
  final String salonNom;
  final String? salonLogo;
  final String? salonAdresse;
  final DateTime dateHeure;
  final double totalPrix;
  final List<String> servicesNoms;
  final String statusRendezVous;

  RdvEligible({
    required this.idRendezVous,
    required this.salonNom,
    this.salonLogo,
    this.salonAdresse,
    required this.dateHeure,
    required this.totalPrix,
    required this.servicesNoms,
    required this.statusRendezVous,
  });

  /// 🔄 Création depuis JSON (réponse API)
  factory RdvEligible.fromJson(Map<String, dynamic> json) {
    return RdvEligible(
      idRendezVous: json['idRendezVous'] ?? 0,
      salonNom: json['salon_nom'] ?? '',
      salonLogo: json['salon_logo'],
      salonAdresse: json['salon_adresse'],
      dateHeure: DateTime.parse(json['date_heure']),
      totalPrix: double.tryParse(json['total_prix'].toString()) ?? 0.0,
      servicesNoms: List<String>.from(json['services_noms'] ?? []),
      statusRendezVous: json['status_rendez_vous'] ?? '',
    );
  }

  /// 📅 Formatage de la date pour l'affichage
  String get dateFormatee => DateFormat('dd/MM/yyyy à HH:mm').format(dateHeure);

  /// 💰 Prix formaté
  String get prixFormate => '${totalPrix.toStringAsFixed(2)}€';

  /// 🏪 URL complète du logo salon
  String get logoUrl {
    if (salonLogo == null || salonLogo!.isEmpty) return '';
    if (salonLogo!.startsWith('http')) return salonLogo!;
    return 'https://www.hairbnb.site$salonLogo';
  }

  /// 🛍️ Services en format texte
  String get servicesTexte => servicesNoms.join(', ');

  @override
  String toString() {
    return 'RdvEligible{salon: $salonNom, date: $dateFormatee, prix: $prixFormate}';
  }
}

/// 🎯 MODÈLE 2: Avis créé/reçu
/// Utilisé pour créer un avis et récupérer des avis existants
class Avis {
  final int? id;
  final int idRendezVous;
  final int note;
  final String commentaire;
  final DateTime? dateCreation;
  final String? clientNom;
  final String? clientPrenom;
  final String? salonNom;
  final String? salonLogo;

  Avis({
    this.id,
    required this.idRendezVous,
    required this.note,
    required this.commentaire,
    this.dateCreation,
    this.clientNom,
    this.clientPrenom,
    this.salonNom,
    this.salonLogo,
  });

  /// 🔄 Création depuis JSON (réponse API)
  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['id'],
      idRendezVous: json['idRendezVous'] ?? json['rdv_id'] ?? 0,
      note: json['note'] ?? 5,
      commentaire: json['commentaire'] ?? '',
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : null,
      clientNom: json['client_nom'],
      clientPrenom: json['client_prenom'],
      salonNom: json['salon_nom'],
      salonLogo: json['salon_logo'],
    );
  }

  /// 🔄 Conversion vers JSON (envoi API)
  Map<String, dynamic> toJson() {
    return {
      'idRendezVous': idRendezVous,
      'note': note,
      'commentaire': commentaire,
      if (id != null) 'id': id,
    };
  }

  /// 📅 Date formatée pour l'affichage
  String get dateFormatee {
    if (dateCreation == null) return '';
    return DateFormat('dd/MM/yyyy').format(dateCreation!);
  }

  /// 👤 Nom complet du client
  String get clientNomComplet {
    if (clientNom == null && clientPrenom == null) return 'Client anonyme';
    return '${clientPrenom ?? ''} ${clientNom ?? ''}'.trim();
  }

  /// ⭐ Étoiles visuelles
  String get etoilesVisuelles => '⭐' * note + '☆' * (5 - note);

  /// 🏪 URL complète du logo salon
  String get logoUrl {
    if (salonLogo == null || salonLogo!.isEmpty) return '';
    if (salonLogo!.startsWith('http')) return salonLogo!;
    return 'https://www.hairbnb.site$salonLogo';
  }

  /// ✅ Validation de l'avis
  bool get isValid {
    return note >= 1 && note <= 5 && commentaire.trim().length >= 10;
  }

  @override
  String toString() {
    return 'Avis{id: $id, note: $note/5, salon: $salonNom}';
  }
}

/// 🎯 MODÈLE 3: Statistiques d'avis d'un salon
/// Utilisé par l'API /salon/{id}/avis/
class AvisStatistiques {
  final double moyenneNotes;
  final int totalAvis;
  final List<Avis> avisRecents;
  final Map<int, int> repartitionNotes; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  AvisStatistiques({
    required this.moyenneNotes,
    required this.totalAvis,
    required this.avisRecents,
    required this.repartitionNotes,
  });

  /// 🔄 Création depuis JSON (réponse API)
  factory AvisStatistiques.fromJson(Map<String, dynamic> json) {
    return AvisStatistiques(
      moyenneNotes: double.tryParse(json['moyenne_notes'].toString()) ?? 0.0,
      totalAvis: json['total_avis'] ?? 0,
      avisRecents: (json['avis_recents'] as List<dynamic>? ?? [])
          .map((avis) => Avis.fromJson(avis))
          .toList(),
      repartitionNotes: Map<int, int>.from(json['repartition_notes'] ?? {}),
    );
  }

  /// ⭐ Moyenne formatée
  String get moyenneFormatee => moyenneNotes.toStringAsFixed(1);

  /// 📊 Pourcentage pour chaque note
  double getPourcentageNote(int note) {
    if (totalAvis == 0) return 0.0;
    return ((repartitionNotes[note] ?? 0) / totalAvis) * 100;
  }

  /// ⭐ Étoiles visuelles pour la moyenne
  String get etoilesVisuelles {
    final etoilesCompletes = moyenneNotes.floor();
    final aFraction = moyenneNotes - etoilesCompletes;

    String result = '⭐' * etoilesCompletes;

    if (aFraction >= 0.5) {
      result += '⭐';
    } else if (aFraction > 0) {
      result += '☆';
    }

    final etoilesVides = 5 - result.length;
    result += '☆' * etoilesVides;

    return result;
  }

  @override
  String toString() {
    return 'AvisStatistiques{moyenne: $moyenneFormatee/5, total: $totalAvis}';
  }
}

/// 🎯 MODÈLE 4: Réponse API pour les RDV éligibles
/// Structure complète retournée par /mes-rdv-avis-en-attente/
class RdvEligiblesResponse {
  final int count;
  final List<RdvEligible> rdvEligibles;
  final String message;

  RdvEligiblesResponse({
    required this.count,
    required this.rdvEligibles,
    required this.message,
  });

  /// 🔄 Création depuis JSON (réponse API)
  factory RdvEligiblesResponse.fromJson(Map<String, dynamic> json) {
    return RdvEligiblesResponse(
      count: json['count'] ?? 0,
      rdvEligibles: (json['rdv_eligibles'] as List<dynamic>? ?? [])
          .map((rdv) => RdvEligible.fromJson(rdv))
          .toList(),
      message: json['message'] ?? '',
    );
  }

  /// 📊 Y a-t-il des avis en attente ?
  bool get hasAvisEnAttente => count > 0;

  @override
  String toString() {
    return 'RdvEligiblesResponse{count: $count, message: $message}';
  }
}

/// 🎯 MODÈLE 5: Réponse API générique
/// Pour les opérations CRUD (création, modification, suppression)
class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  /// 🔄 Création depuis JSON (réponse API)
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message}';
  }
}