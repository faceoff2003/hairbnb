class Salon {
  final int idSalon;
  final String nomSalon;
  final String? slogan;
  final String? logo;
  final int coiffeuseId; // 🔥 Permet de lier le salon à une coiffeuse

  Salon({
    required this.idSalon,
    required this.nomSalon,
    this.slogan,
    this.logo,
    required this.coiffeuseId,
  });

  /// **🟢 Convertir JSON vers `Salon`**
  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      idSalon: json['idTblSalon'],
      nomSalon: json['nomSalon'] ?? "Salon sans nom",
      slogan: json['slogan'],
      logo: json['logo_salon'],
      coiffeuseId: json['coiffeuse']['idTblUser'], // 🔥 Récupération de l'ID de la coiffeuse
    );
  }

  /// **🟢 Convertir `Salon` en JSON**
  Map<String, dynamic> toJson() {
    return {
      'idTblSalon': idSalon,
      'nomSalon': nomSalon,
      'slogan': slogan,
      'logo_salon': logo,
      'coiffeuse_id': coiffeuseId,
    };
  }
}
