// models/admin_avis.dart
import 'package:intl/intl.dart';

/// 🎯 MODÈLE 1: Client dans l'interface admin
class AdminClient {
  final String nom;
  final String prenom;
  final String email;
  final String? photoProfileUrl;
  final String uuid;
  final int idTblUser;

  AdminClient({
    required this.nom,
    required this.prenom,
    required this.email,
    this.photoProfileUrl,
    required this.uuid,
    required this.idTblUser,
  });

  /// 🔄 Création depuis JSON (réponse API admin)
  factory AdminClient.fromJson(Map<String, dynamic> json) {
    return AdminClient(
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      photoProfileUrl: json['photo_profil'],
      uuid: json['uuid'] ?? '',
      idTblUser: json['idTblUser'] ?? 0,
    );
  }

  /// 👤 Nom complet
  String get nomComplet => '$prenom $nom'.trim();

  String get photoUrl {
    if (photoProfileUrl == null || photoProfileUrl!.isEmpty) {
      return ''; // Retourne vide au lieu de construire une URL invalide
    }

    // Si l'URL est déjà complète
    if (photoProfileUrl!.startsWith('http')) {
      return photoProfileUrl!;
    }

    // Si c'est juste un chemin, construire l'URL complète
    if (photoProfileUrl!.startsWith('/')) {
      return 'https://www.hairbnb.site$photoProfileUrl';
    } else {
      return 'https://www.hairbnb.site/media/$photoProfileUrl';
    }
  }

  /// 📧 Email masqué pour affichage
  String get emailMasque {
    if (email.length <= 6) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    final maskedLocal = local.length > 3
        ? '${local.substring(0, 2)}***${local.substring(local.length - 1)}'
        : local;
    return '$maskedLocal@$domain';
  }

  @override
  String toString() => 'AdminClient{$nomComplet, $email}';
}

/// 🎯 MODÈLE 2: Salon dans l'interface admin
class AdminSalon {
  final int idTblSalon;
  final String nomSalon;
  final String? logoSalon;

  AdminSalon({
    required this.idTblSalon,
    required this.nomSalon,
    this.logoSalon,
  });

  /// 🔄 Création depuis JSON
  factory AdminSalon.fromJson(Map<String, dynamic> json) {
    return AdminSalon(
      idTblSalon: json['idTblSalon'] ?? 0,
      nomSalon: json['nom_salon'] ?? '',
      logoSalon: json['logo_salon'],
    );
  }

  /// 🏪 URL complète du logo
  String get logoUrl {
    if (logoSalon == null || logoSalon!.isEmpty) return '';
    if (logoSalon!.startsWith('http')) return logoSalon!;
    return 'https://www.hairbnb.site$logoSalon';
  }

  @override
  String toString() => 'AdminSalon{$nomSalon}';
}

/// 🎯 MODÈLE 3: Avis pour modération admin
class AdminAvis {
  final int id;
  final int note;
  final String commentaire;
  final DateTime date;
  final AdminClient client;
  final AdminSalon salon;
  final String statutLibelle;
  final String statutCode;
  final int? rdvId;

  AdminAvis({
    required this.id,
    required this.note,
    required this.commentaire,
    required this.date,
    required this.client,
    required this.salon,
    required this.statutLibelle,
    required this.statutCode,
    this.rdvId,
  });

  /// 🔄 Création depuis JSON (réponse API admin)
  factory AdminAvis.fromJson(Map<String, dynamic> json) {
    return AdminAvis(
      id: json['id'] ?? 0,
      note: json['note'] ?? 0,
      commentaire: json['commentaire'] ?? '',
      date: DateTime.parse(json['date']),
      client: AdminClient.fromJson(json['client'] ?? {}),
      salon: AdminSalon.fromJson(json['salon'] ?? {}),
      statutLibelle: json['statut_libelle'] ?? '',
      statutCode: json['statut_code'] ?? '',
      rdvId: json['rdv_id'],
    );
  }

  /// 📅 Date formatée
  String get dateFormatee => DateFormat('dd/MM/yyyy à HH:mm').format(date);

  /// 📅 Date courte
  String get dateCourte => DateFormat('dd/MM/yyyy').format(date);

  /// ⭐ Étoiles visuelles
  String get etoilesVisuelles => '⭐' * note + '☆' * (5 - note);

  /// 🎨 Couleur selon la note
  String get couleurNote {
    if (note <= 2) return 'rouge';
    if (note == 3) return 'orange';
    if (note == 4) return 'bleu';
    return 'vert';
  }

  /// 📝 Texte selon la note
  String get texteNote {
    switch (note) {
      case 1: return 'Très décevant';
      case 2: return 'Décevant';
      case 3: return 'Correct';
      case 4: return 'Très bien';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  /// 👁️ Avis visible publiquement ?
  bool get estVisible => statutCode == 'visible';

  /// 🚫 Avis masqué ?
  bool get estMasque => statutCode == 'masque';

  /// 💬 Commentaire tronqué pour aperçu
  String get commentaireApercu {
    if (commentaire.length <= 100) return commentaire;
    return '${commentaire.substring(0, 97)}...';
  }

  /// 🚨 Avis problématique (note faible) ?
  bool get estProblematique => note <= 2;

  @override
  String toString() => 'AdminAvis{id: $id, client: ${client.nomComplet}, salon: ${salon.nomSalon}, note: $note/5}';
}

/// 🎯 MODÈLE 4: Réponse API pour liste admin des avis
class AdminAvisListeResponse {
  final bool success;
  final String message;
  final List<AdminAvis> avis;
  final AdminPagination pagination;

  AdminAvisListeResponse({
    required this.success,
    required this.message,
    required this.avis,
    required this.pagination,
  });

  /// 🔄 Création depuis JSON
  factory AdminAvisListeResponse.fromJson(Map<String, dynamic> json) {
    return AdminAvisListeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      avis: (json['avis'] as List<dynamic>? ?? [])
          .map((avis) => AdminAvis.fromJson(avis))
          .toList(),
      pagination: AdminPagination.fromJson(json['pagination'] ?? {}),
    );
  }

  /// 📊 Nombre d'avis
  int get nombreAvis => avis.length;

  /// 📊 Statistiques rapides
  Map<String, int> get statistiques {
    int visibles = 0, masques = 0, problematiques = 0;

    for (var avis in this.avis) {
      if (avis.estVisible) visibles++;
      if (avis.estMasque) masques++;
      if (avis.estProblematique) problematiques++;
    }

    return {
      'visibles': visibles,
      'masques': masques,
      'problematiques': problematiques,
      'total': avis.length,
    };
  }

  @override
  String toString() => 'AdminAvisListeResponse{${avis.length} avis, page ${pagination.page}}';
}

/// 🎯 MODÈLE 5: Pagination pour l'admin
class AdminPagination {
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;
  final bool hasPrevious;

  AdminPagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// 🔄 Création depuis JSON
  factory AdminPagination.fromJson(Map<String, dynamic> json) {
    return AdminPagination(
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      total: json['total'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }

  /// 📊 Nombre total de pages
  int get totalPages => (total / pageSize).ceil();

  /// 📊 Index de début pour cette page
  int get startIndex => (page - 1) * pageSize + 1;

  /// 📊 Index de fin pour cette page
  int get endIndex {
    final end = page * pageSize;
    return end > total ? total : end;
  }

  /// 📊 Texte de pagination
  String get texteInfo => 'Page $page sur $totalPages ($startIndex-$endIndex sur $total)';

  @override
  String toString() => 'AdminPagination{page $page/$totalPages, total: $total}';
}

/// 🎯 MODÈLE 6: Filtres pour la recherche admin
class AdminAvisFilters {
  final String? statut;
  final int? salonId;
  final int? note;
  final String? search;
  final int page;
  final int pageSize;

  AdminAvisFilters({
    this.statut,
    this.salonId,
    this.note,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  /// 🔄 Copie avec modifications
  AdminAvisFilters copyWith({
    String? statut,
    int? salonId,
    int? note,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return AdminAvisFilters(
      statut: statut ?? this.statut,
      salonId: salonId ?? this.salonId,
      note: note ?? this.note,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// 🔄 Conversion en paramètres URL
  Map<String, String> toUrlParams() {
    final params = <String, String>{};

    if (statut != null && statut!.isNotEmpty) params['statut'] = statut!;
    if (salonId != null) params['salon_id'] = salonId.toString();
    if (note != null) params['note'] = note.toString();
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    params['page'] = page.toString();
    params['page_size'] = pageSize.toString();

    return params;
  }

  /// 🔄 Réinitialiser les filtres
  AdminAvisFilters reset() {
    return AdminAvisFilters(page: 1, pageSize: pageSize);
  }

  /// 📊 Y a-t-il des filtres actifs ?
  bool get hasActiveFilters {
    return (statut != null && statut!.isNotEmpty) ||
        salonId != null ||
        note != null ||
        (search != null && search!.isNotEmpty);
  }

  @override
  String toString() => 'AdminAvisFilters{statut: $statut, salon: $salonId, note: $note, search: $search, page: $page}';
}

/// 🎯 MODÈLE 7: Réponse API pour actions admin
class AdminActionResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? nouveauStatut;

  AdminActionResponse({
    required this.success,
    required this.message,
    this.nouveauStatut,
  });

  /// 🔄 Création depuis JSON
  factory AdminActionResponse.fromJson(Map<String, dynamic> json) {
    return AdminActionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      nouveauStatut: json['nouveau_statut'],
    );
  }

  @override
  String toString() => 'AdminActionResponse{success: $success, message: $message}';
}