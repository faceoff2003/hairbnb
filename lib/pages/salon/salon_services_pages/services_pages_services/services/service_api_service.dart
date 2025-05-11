// import 'dart:convert';
// import 'dart:developer';
// import 'package:http/http.dart' as http;
//
// import '../../../../../models/promotion.dart';
//
// class ServiceApi {
//   static const baseUrl = 'https://www.hairbnb.site/api';
//
//   // Récupération des services
//   static Future<Map<String, dynamic>> fetchServices({
//     required String coiffeuseId,
//     required int page,
//     required int pageSize,
//   }) async {
//     try {
//       final url = Uri.parse(
//         '$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=$page&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         final totalServices = responseData.containsKey('count') ? responseData['count'] : 0;
//         final nextPageUrl = responseData['next'];
//         final previousPageUrl = responseData['previous'];
//
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         // Création manuelle des objets Service
//         final List<Service> services = [];
//
//         for (var json in serviceList as List) {
//           try {
//             // Conversion du prix
//             double prixBase = 0.0;
//             try {
//               prixBase = (json['prix'] != null)
//                   ? double.parse(json['prix'].toString())
//                   : 0.0;
//             } catch (e) {
//               print("❌ Erreur conversion prix: ${json['prix']}, error: $e");
//             }
//
//             // Vérification et conversion de la promotion
//             Promotion? promo;
//             if (json['promotion'] != null) {
//               try {
//                 promo = Promotion.fromJson(json['promotion']);
//               } catch (e) {
//                 print("❌ Erreur conversion Promotion : $e");
//                 promo = null;
//               }
//             }
//
//             // Calcul du prix final avec réduction (si promotion existante)
//             double prixReduit = (promo != null)
//                 ? prixBase * (1 - (promo.pourcentage / 100))
//                 : prixBase;
//
//             // Conversion de l'ID
//             int idValue = 0;
//             try {
//               idValue = int.tryParse(json['idTblService']?.toString() ?? '0') ?? 0;
//             } catch (e) {
//               print("❌ Erreur conversion id: ${json['idTblService']}, error: $e");
//             }
//
//             // Conversion du temps (en minutes)
//             int tempsValue = 0;
//             try {
//               tempsValue = int.tryParse(json['temps_minutes']?.toString() ?? '0') ?? 0;
//             } catch (e) {
//               print("❌ Erreur conversion temps: ${json['temps_minutes']}, error: $e");
//             }
//
//             // Création de l'objet Service
//             services.add(Service(
//               id: idValue,
//               intitule: json['intitule_service'] ?? 'Nom indisponible',
//               description: json['description'] ?? 'Aucune description',
//               prix: prixBase,
//               temps: tempsValue,
//               promotion: promo,
//               prixFinal: prixReduit,
//             ));
//           } catch (e) {
//             print("❌ Erreur lors de la création du service: $e");
//           }
//         }
//
//         return {
//           'services': services,
//           'totalServices': totalServices,
//           'nextPageUrl': nextPageUrl,
//           'previousPageUrl': previousPageUrl,
//           'hasError': false,
//         };
//       } else {
//         throw Exception('Erreur serveur: Code ${response.statusCode}');
//       }
//     } catch (e) {
//       return {
//         'services': <Service>[],
//         'totalServices': 0,
//         'nextPageUrl': null,
//         'previousPageUrl': null,
//         'hasError': true,
//         'errorMessage': e.toString(),
//       };
//     }
//   }
//
//   // Reste du code inchangé...
//
//   // Suppression d'un service
//   static Future<bool> deleteService(int serviceId) async {
//     try {
//       final url = Uri.parse('$baseUrl/delete_service/$serviceId/');
//       final response = await http.delete(url);
//       return response.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Ajout d'un service
//   static Future<Map<String, dynamic>> addService({
//     required String coiffeuseId,
//     required String name,
//     required String description,
//     required String price,
//     required String duration,
//   }) async {
//     try {
//       final url = Uri.parse('$baseUrl/add_service_to_salon/');
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'userId': coiffeuseId,
//           'intitule_service': name,
//           'description': description,
//           'prix': price,
//           'temps_minutes': duration,
//         }),
//       );
//
//       return {
//         'success': response.statusCode == 201,
//         'errorMessage': response.statusCode != 201 ? response.body : null,
//       };
//     } catch (e) {
//       return {
//         'success': false,
//         'errorMessage': e.toString(),
//       };
//     }
//   }
// }