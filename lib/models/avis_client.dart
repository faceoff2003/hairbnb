// models/avis_client.dart
class AvisClient {
  final int id;
  final int note;
  final String commentaire;
  final DateTime date;
  final String dateFormatee;

  // Informations client complètes
  final String clientNom;
  final String clientPrenom;
  final String clientEmail;
  final String? clientPhoto;
  final String clientUuid;
  final int clientId;

  // Informations RDV
  final int? rdvId;
  final DateTime? rdvDate;
  final String? rdvDateFormatee;

  // Statut
  final String statutLibelle;

  AvisClient({
    required this.id,
    required this.note,
    required this.commentaire,
    required this.date,
    required this.dateFormatee,
    required this.clientNom,
    required this.clientPrenom,
    required this.clientEmail,
    this.clientPhoto,
    required this.clientUuid,
    required this.clientId,
    this.rdvId,
    this.rdvDate,
    this.rdvDateFormatee,
    required this.statutLibelle,
  });

  // Factory pour créer depuis JSON
  factory AvisClient.fromJson(Map<String, dynamic> json) {
    return AvisClient(
      id: json['id'] as int,
      note: json['note'] as int,
      commentaire: json['commentaire'] as String,
      date: DateTime.parse(json['date'] as String),
      dateFormatee: json['date_formatted'] as String,
      clientNom: json['client_nom'] as String,
      clientPrenom: json['client_prenom'] as String,
      clientEmail: json['client_email'] as String,
      clientPhoto: json['client_photo'] as String?,
      clientUuid: json['client_uuid'] as String,
      clientId: json['client_id'] as int,
      rdvId: json['rdv_id'] as int?,
      rdvDate: json['rdv_date'] != null ? DateTime.parse(json['rdv_date'] as String) : null,
      rdvDateFormatee: json['rdv_date_formatted'] as String?,
      statutLibelle: json['statut_libelle'] as String,
    );
  }

  // Méthode pour convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'commentaire': commentaire,
      'date': date.toIso8601String(),
      'date_formatted': dateFormatee,
      'client_nom': clientNom,
      'client_prenom': clientPrenom,
      'client_email': clientEmail,
      'client_photo': clientPhoto,
      'client_uuid': clientUuid,
      'client_id': clientId,
      'rdv_id': rdvId,
      'rdv_date': rdvDate?.toIso8601String(),
      'rdv_date_formatted': rdvDateFormatee,
      'statut_libelle': statutLibelle,
    };
  }

  // Propriétés utiles
  String get clientNomComplet => '$clientPrenom $clientNom';

  bool get hasPhoto => clientPhoto != null && clientPhoto!.isNotEmpty;

  String get photoUrl => hasPhoto ? clientPhoto! : 'assets/logo_login/avatar.png';

  bool get hasRdv => rdvId != null;

  @override
  String toString() {
    return 'AvisClient(id: $id, note: $note, client: $clientNomComplet, rdv: $rdvId)';
  }
}