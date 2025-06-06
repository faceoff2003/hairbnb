// hairbnb/lib/models/salon_create.dart
class SalonCreateModel {
  final int idTblUser;
  final String nomSalon;
  final String slogan;
  final dynamic logo; // File ou XFile pour le logo
  final String aPropos;     // ✅ OBLIGATOIRE maintenant
  final String numeroTva;   // ✅ OBLIGATOIRE maintenant
  final String position;    // ✅ OBLIGATOIRE maintenant
  final int adresse;        // ✅ OBLIGATOIRE et AJOUTÉ (ID de TblAdresse)

  SalonCreateModel({
    required this.idTblUser,
    required this.nomSalon,
    required this.slogan,
    required this.logo,
    required this.aPropos,     // ✅ Plus optionnel
    required this.numeroTva,   // ✅ Plus optionnel
    required this.position,    // ✅ Plus optionnel
    required this.adresse,     // ✅ Nouveau champ obligatoire
  });

  /// Convertir en champs texte pour la requête multipart
  Map<String, String> toFields() {
    return {
      'idTblUser': idTblUser.toString(),
      'nom_salon': nomSalon,
      'slogan': slogan,
      'a_propos': aPropos,           // ✅ Toujours inclus
      'numero_tva': numeroTva,       // ✅ Toujours inclus
      'position': position,          // ✅ Toujours inclus
      'adresse': adresse.toString(), // ✅ Nouveau champ obligatoire
    };
  }
}






// // hairbnb/lib/models/salon_create.dart
//
// class SalonCreateModel {
//   final int idTblUser;
//   final String nomSalon;
//   final String slogan;
//   final dynamic logo;
//   final String? aPropos;
//   final String? numeroTva;
//   final String? position;
//
//   SalonCreateModel({
//     required this.idTblUser,
//     required this.nomSalon,
//     required this.slogan,
//     required this.logo,
//     this.aPropos,
//     this.numeroTva,
//     this.position,
//   });
//
//   /// Convertir en champs texte pour la requête multipart
//   Map<String, String> toFields() {
//     final Map<String, String> fields = {
//       'idTblUser': idTblUser.toString(),
//       'nom_salon': nomSalon,
//       'slogan': slogan,
//     };
//
//     if (aPropos != null) {
//       fields['a_propos'] = aPropos!;
//     }
//     if (numeroTva != null) {
//       fields['numero_tva'] = numeroTva!;
//     }
//     if (position != null) {
//       fields['position'] = position!;
//     }
//
//     return fields;
//   }
// }