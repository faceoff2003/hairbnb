// class Adresse {
//   int? numero;
//   String? boitePostale;
//   Rue? rue;
//
//   Adresse({
//     this.numero,
//     this.boitePostale,
//     this.rue,
//   });
//
//   factory Adresse.fromJson(Map<String, dynamic> json) {
//     return Adresse(
//       numero: json['numero'],
//       boitePostale: json['boite_postale'],
//       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'numero': numero,
//       'boite_postale': boitePostale,
//       'rue': rue?.toJson(),
//     };
//   }
// }
//
// class Rue {
//   String? nomRue;
//   Localite? localite;
//
//   Rue({
//     this.nomRue,
//     this.localite,
//   });
//
//   factory Rue.fromJson(Map<String, dynamic> json) {
//     return Rue(
//       nomRue: json['nom_rue'],
//       localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'nom_rue': nomRue,
//       'localite': localite?.toJson(),
//     };
//   }
// }
//
// class Localite {
//   String? commune;
//   String? codePostal;
//
//   Localite({
//     this.commune,
//     this.codePostal,
//   });
//
//   factory Localite.fromJson(Map<String, dynamic> json) {
//     return Localite(
//       commune: json['commune'],
//       codePostal: json['code_postal'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'commune': commune,
//       'code_postal': codePostal,
//     };
//   }
// }