class IndisponibiliteCoiffeuse {
  final int id;
  final int coiffeuseId;
  final String date;       // Format: "2025-05-01"
  final String heureDebut; // Format: "10:00"
  final String heureFin;   // Format: "16:00"
  final String? motif;

  IndisponibiliteCoiffeuse({
    required this.id,
    required this.coiffeuseId,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    this.motif,
  });

  factory IndisponibiliteCoiffeuse.fromJson(Map<String, dynamic> json) {
    return IndisponibiliteCoiffeuse(
      id: json['id'],
      coiffeuseId: json['coiffeuse_id'],
      date: json['date'],
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
      motif: json['motif'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coiffeuse': coiffeuseId,
      'date': date,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'motif': motif,
    };
  }
}
