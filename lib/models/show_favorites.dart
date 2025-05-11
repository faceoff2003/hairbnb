class ShowFavorite {
  final int idTblFavorite;
  final Salon salon;

  ShowFavorite({
    required this.idTblFavorite,
    required this.salon,
  });

  factory ShowFavorite.fromJson(Map<String, dynamic> json) {
    return ShowFavorite(
      idTblFavorite: json['idTblFavorite'],
      salon: Salon.fromJson(json['salon']),
    );
  }
}

class Salon {
  final int idTblSalon;
  final int coiffeuse;
  final String nomSalon;
  final String slogan;
  final String logoSalon;

  Salon({
    required this.idTblSalon,
    required this.coiffeuse,
    required this.nomSalon,
    required this.slogan,
    required this.logoSalon,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      idTblSalon: json['idTblSalon'],
      coiffeuse: json['coiffeuse'],
      nomSalon: json['nom_salon'],
      slogan: json['slogan'],
      logoSalon: json['logo_salon'],
    );
  }
}





// class ShowFavorite {
//   final int idTblFavorite;
//   final Salon salon;
//   final DateTime addedAt;
//
//   ShowFavorite({
//     required this.idTblFavorite,
//     required this.salon,
//     required this.addedAt,
//   });
//
//   factory ShowFavorite.fromJson(Map<String, dynamic> json) {
//     return ShowFavorite(
//       idTblFavorite: json['idTblFavorite'],
//       salon: Salon.fromJson(json['salon']),
//       addedAt: DateTime.parse(json['added_at']),
//     );
//   }
// }
//
// class Salon {
//   final int idTblSalon;
//   final int coiffeuse;
//   final String nomSalon;
//   final String slogan;
//   final String logoSalon;
//
//   Salon({
//     required this.idTblSalon,
//     required this.coiffeuse,
//     required this.nomSalon,
//     required this.slogan,
//     required this.logoSalon,
//   });
//
//   factory Salon.fromJson(Map<String, dynamic> json) {
//     return Salon(
//       idTblSalon: json['idTblSalon'],
//       coiffeuse: json['coiffeuse'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       logoSalon: json['logo_salon'],
//     );
//   }
// }
