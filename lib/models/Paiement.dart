class Paiement {
  final double montantPaye;
  final DateTime datePaiement;
  final String methode;
  final String statut;

  Paiement({
    required this.montantPaye,
    required this.datePaiement,
    required this.methode,
    required this.statut,
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      montantPaye: json['montant_paye'].toDouble(),
      datePaiement: DateTime.parse(json['date_paiement']),
      methode: json['methode'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'montant_paye': montantPaye,
      'date_paiement': datePaiement.toIso8601String(),
      'methode': methode,
      'statut': statut,
    };
  }
}
