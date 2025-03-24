class HoraireCoiffeuse {
  final int id;
  final int coiffeuseId;
  final int jour; // Ex: 0 = Lundi
  final String jourLabel; // Ex: "Lundi"
  final String heureDebut; // Format: "08:00"
  final String heureFin;   // Format: "17:00"

  HoraireCoiffeuse({
    required this.id,
    required this.coiffeuseId,
    required this.jour,
    required this.jourLabel,
    required this.heureDebut,
    required this.heureFin,
  });

  factory HoraireCoiffeuse.fromJson(Map<String, dynamic> json) {
    return HoraireCoiffeuse(
      id: json['id'],
      coiffeuseId: json['coiffeuse_id'],
      jour: json['jour'],
      jourLabel: json['jour_label'],
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coiffeuse': coiffeuseId,
      'jour': jour,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
    };
  }
}
