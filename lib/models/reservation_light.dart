class ReservationLight {
  final int idRendezVous;
  final String clientNom;
  final String clientPrenom;
  final String? photoProfil;
  final DateTime dateHeure;
  final String statut;
  final double totalPrix;
  final int dureeTotale;

  ReservationLight({
    required this.idRendezVous,
    required this.clientNom,
    required this.clientPrenom,
    this.photoProfil,
    required this.dateHeure,
    required this.statut,
    required this.totalPrix,
    required this.dureeTotale,
  });

  factory ReservationLight.fromJson(Map<String, dynamic> json) {
    return ReservationLight(
      idRendezVous: json['idRendezVous'],
      clientNom: json['client_nom'],
      clientPrenom: json['client_prenom'],
      photoProfil: json['client_photo'],
      dateHeure: DateTime.parse(json['date_heure']),
      statut: json['statut'],
      totalPrix: (json['total_prix'] as num).toDouble(),
      dureeTotale: json['duree_totale'],
    );
  }
}
