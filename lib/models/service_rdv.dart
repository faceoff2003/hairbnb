// /// **📌 Modèle pour un service dans le RDV**


import 'dart:convert';

import 'package:http/http.dart' as http;

import 'RdvConfirmation.dart';

class RdvService {
  final String baseUrl = "https://www.hairbnb.site/api";

  Future<List<RdvConfirmation>> fetchRendezVous({
    required int coiffeuseId,
    bool archived = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rendezvous/?coiffeuse_id=$coiffeuseId&archived=$archived"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rdvList = data['results'];

        return rdvList.map((rdv) => RdvConfirmation.fromJson(rdv)).toList();
      } else {
        throw Exception("Erreur ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("Erreur fetchRendezVous: $e");
      rethrow;
    }
  }
}


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'RdvConfirmation.dart';
//
// class RdvService {
//   Future<List<RdvConfirmation>> fetchRendezVous({
//     required int coiffeuseId,
//     required bool archived,
//   }) async {
//     final url = Uri.parse('https://tonapi.com/rendezvous?coiffeuseId=$coiffeuseId&archived=$archived');
//
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final List<dynamic> results = data['results'];
//
//       // 🔥 Utilise bien le modèle corrigé ici
//       return results.map((rdvJson) => RdvConfirmation.fromJson(rdvJson)).toList();
//     } else {
//       throw Exception('Échec de chargement des rendez-vous');
//     }
//   }
// }


// class ServiceRdv {
//   final int id;
//   final String intitule;
//   final double prixApplique;
//
//   ServiceRdv({required this.id, required this.intitule, required this.prixApplique});
//
//   factory ServiceRdv.fromJson(Map<String, dynamic> json) {
//     return ServiceRdv(
//       id: json['idTblService'],
//       intitule: json['intitule_service'],
//       prixApplique: json['prix_applique'].toDouble(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblService': id,
//       'intitule_service': intitule,
//       'prix_applique': prixApplique,
//     };
//   }
// }