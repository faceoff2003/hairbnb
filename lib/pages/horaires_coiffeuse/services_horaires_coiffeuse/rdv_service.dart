import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/reservation_light.dart';

class RdvService {
  final baseUrl = "https://www.hairbnb.site/api";

  Future<List<ReservationLight>> fetchRendezVous({
    required int coiffeuseId,
    required bool archived,
  }) async {
    final endpoint = archived
        ? "/get_archived_rendezvous_by_coiffeuse_id/$coiffeuseId/"
        : "/get_rendezvous_by_coiffeuse_id/$coiffeuseId/";


    final response = await http.get(Uri.parse("$baseUrl$endpoint"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((e) => ReservationLight.fromJson(e)).toList();
    } else {
      throw Exception("Erreur serveur : ${response.statusCode}");
    }
  }
}





// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../../../models/RdvConfirmation.dart';
//
// class RdvService {
//   final String baseUrl = "https://www.hairbnb.site/api";
//
//   Future<List<RdvConfirmation>> fetchRendezVous({
//     required int coiffeuseId,
//     bool archived = false,
//     String? periode,
//     String? statut,
//   }) async {
//     final endpoint = archived
//         ? "/get_archived_rendezvous_by_coiffeuse_id/$coiffeuseId/"
//         : "/get_rendezvous_by_coiffeuse_id/$coiffeuseId/";
//
//     final uri = Uri.parse("$baseUrl$endpoint").replace(queryParameters: {
//       if (periode != null) 'periode': periode,
//       if (statut != null) 'statut': statut,
//     });
//
//     final response = await http.get(uri);
//
//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = jsonDecode(response.body);
//       final List<dynamic> results = data['results'];
//
//       return results.map((json) => RdvConfirmation.fromJson(json)).toList();
//     } else {
//       throw Exception("Erreur lors du chargement des rendez-vous");
//     }
//   }
//
//
// // Future<List<RdvConfirmation>> fetchRendezVous({
//   //   required int coiffeuseId,
//   //   bool archived = false,
//   //   String? periode,
//   //   String? statut,
//   // }) async {
//   //   final endpoint = archived
//   //       ? "/get_archived_rendezvous_by_coiffeuse_id/$coiffeuseId/"
//   //       : "/get_rendezvous_by_coiffeuse_id/$coiffeuseId/";
//   //
//   //   final uri = Uri.parse("$baseUrl$endpoint").replace(queryParameters: {
//   //     if (periode != null) 'periode': periode,
//   //     if (statut != null) 'statut': statut,
//   //   });
//   //
//   //   final response = await http.get(uri);
//   //
//   //   if (response.statusCode == 200) {
//   //     final List<dynamic> rawList = jsonDecode(response.body)['results'];
//   //     return rawList.map((json) => RdvConfirmation.fromJson(json)).toList();
//   //   } else {
//   //     throw Exception("Erreur lors du chargement des rendez-vous");
//   //   }
//   // }
// }
