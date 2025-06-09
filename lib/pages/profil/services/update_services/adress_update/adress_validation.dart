// lib/services/address_validation_service.dart
// Créer ce nouveau fichier

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../../models/adresse.dart';

class AddressValidationResult {
  final bool isValid;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final String? errorMessage;

  AddressValidationResult({
    required this.isValid,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.errorMessage,
  });
}

class AddressValidationService {
  static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
  static const String _baseUrl = 'https://api.geoapify.com/v1';

  static Future<AddressValidationResult> validateAddress(Adresse adresse) async {
    try {
      // Construire l'adresse complète
      String addressQuery = _buildAddressQuery(adresse);

      if (addressQuery.isEmpty) {
        return AddressValidationResult(
          isValid: false,
          errorMessage: "Adresse incomplète",
        );
      }

      print("🔍 Validation: $addressQuery");

      final url = Uri.parse(
          '$_baseUrl/geocode/search?text=${Uri.encodeComponent(addressQuery)}&filter=countrycode:be&limit=1&apiKey=$_apiKey'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final geometry = feature['geometry'];
          final properties = feature['properties'];

          print("✅ Adresse validée avec coordonnées");

          return AddressValidationResult(
            isValid: true,
            latitude: geometry['coordinates'][1].toDouble(),
            longitude: geometry['coordinates'][0].toDouble(),
            formattedAddress: properties['formatted']?.toString(),
          );
        } else {
          return AddressValidationResult(
            isValid: false,
            errorMessage: "Adresse non trouvée",
          );
        }
      } else {
        return AddressValidationResult(
          isValid: false,
          errorMessage: "Erreur de validation (${response.statusCode})",
        );
      }
    } catch (e) {
      print("❌ Erreur validation: $e");
      return AddressValidationResult(
        isValid: false,
        errorMessage: "Erreur de connexion",
      );
    }
  }

  static String _buildAddressQuery(Adresse adresse) {
    List<String> parts = [];

    if (adresse.numero != null) {
      parts.add(adresse.numero.toString());
    }

    if (adresse.rue?.nomRue != null && adresse.rue!.nomRue!.isNotEmpty) {
      parts.add(adresse.rue!.nomRue!);
    }

    if (adresse.rue?.localite?.codePostal != null && adresse.rue!.localite!.codePostal!.isNotEmpty) {
      parts.add(adresse.rue!.localite!.codePostal!);
    }

    if (adresse.rue?.localite?.commune != null && adresse.rue!.localite!.commune!.isNotEmpty) {
      parts.add(adresse.rue!.localite!.commune!);
    }

    parts.add("Belgium");

    return parts.join(" ");
  }
}














// // lib/services/address_validation_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../../../models/current_user.dart';
//
// class AddressValidationResult {
//   final bool isValid;
//   final double? latitude;
//   final double? longitude;
//   final String? formattedAddress;
//   final String? errorMessage;
//
//   AddressValidationResult({
//     required this.isValid,
//     this.latitude,
//     this.longitude,
//     this.formattedAddress,
//     this.errorMessage,
//   });
// }
//
// class AddressValidationService {
//   static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
//   static const String _baseUrl = 'https://api.geoapify.com/v1';
//
//   /// Valide une adresse complète et récupère ses coordonnées GPS
//   static Future<AddressValidationResult> validateAddress(Adresse adresse) async {
//     try {
//       // Construire l'adresse complète pour la validation
//       String addressQuery = _buildAddressQuery(adresse);
//
//       if (addressQuery.isEmpty) {
//         return AddressValidationResult(
//           isValid: false,
//           errorMessage: "Adresse incomplète pour la validation",
//         );
//       }
//
//       final url = Uri.parse(
//           '$_baseUrl/geocode/search?text=${Uri.encodeComponent(addressQuery)}&filter=countrycode:be&limit=1&apiKey=$_apiKey'
//       );
//
//       print("🌐 Validation adresse: $addressQuery");
//       print("🌐 URL Geoapify: $url");
//
//       final response = await http.get(url).timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           throw Exception("Timeout lors de la validation d'adresse");
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           final feature = data['features'][0];
//           final geometry = feature['geometry'];
//           final properties = feature['properties'];
//
//           print("✅ Adresse validée avec succès");
//           print("📍 Coordonnées: ${geometry['coordinates'][1]}, ${geometry['coordinates'][0]}");
//
//           return AddressValidationResult(
//             isValid: true,
//             latitude: geometry['coordinates'][1].toDouble(),
//             longitude: geometry['coordinates'][0].toDouble(),
//             formattedAddress: properties['formatted']?.toString(),
//           );
//         } else {
//           return AddressValidationResult(
//             isValid: false,
//             errorMessage: "Adresse non trouvée dans la base de données Geoapify",
//           );
//         }
//       } else {
//         print("❌ Erreur API Geoapify: ${response.statusCode}");
//         print("❌ Corps réponse: ${response.body}");
//
//         return AddressValidationResult(
//           isValid: false,
//           errorMessage: "Erreur de validation (Code: ${response.statusCode})",
//         );
//       }
//     } catch (e) {
//       print("❌ Exception validation adresse: $e");
//
//       return AddressValidationResult(
//         isValid: false,
//         errorMessage: "Erreur de connexion : $e",
//       );
//     }
//   }
//
//   /// Construit la requête d'adresse pour l'API
//   static String _buildAddressQuery(Adresse adresse) {
//     List<String> parts = [];
//
//     if (adresse.numero != null) {
//       parts.add(adresse.numero.toString());
//     }
//
//     if (adresse.rue?.nomRue != null && adresse.rue!.nomRue!.isNotEmpty) {
//       parts.add(adresse.rue!.nomRue!);
//     }
//
//     if (adresse.rue?.localite?.codePostal != null && adresse.rue!.localite!.codePostal!.isNotEmpty) {
//       parts.add(adresse.rue!.localite!.codePostal!);
//     }
//
//     if (adresse.rue?.localite?.commune != null && adresse.rue!.localite!.commune!.isNotEmpty) {
//       parts.add(adresse.rue!.localite!.commune!);
//     }
//
//     // Ajouter "Belgium" pour améliorer la précision
//     parts.add("Belgium");
//
//     return parts.join(" ");
//   }
//
//   /// Validation rapide d'une adresse avec autocomplétion
//   static Future<List<AddressSuggestion>> getAddressSuggestions(String query) async {
//     if (query.length < 3) return [];
//
//     try {
//       final url = Uri.parse(
//           '$_baseUrl/geocode/autocomplete?text=${Uri.encodeComponent(query)}&filter=countrycode:be&limit=5&apiKey=$_apiKey'
//       );
//
//       final response = await http.get(url).timeout(
//         const Duration(seconds: 5),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['features'] != null) {
//           return (data['features'] as List)
//               .map((feature) => AddressSuggestion.fromGeoapifyFeature(feature))
//               .where((suggestion) => suggestion.formattedAddress.isNotEmpty)
//               .toList();
//         }
//       }
//     } catch (e) {
//       print("❌ Erreur suggestions d'adresse : $e");
//     }
//
//     return [];
//   }
//
//   /// Valide les coordonnées GPS (utile pour vérifier si elles sont en Belgique)
//   static bool areCoordinatesInBelgium(double latitude, double longitude) {
//     // Limites approximatives de la Belgique
//     return latitude >= 49.5 && latitude <= 51.5 &&
//         longitude >= 2.5 && longitude <= 6.4;
//   }
// }
//
// class AddressSuggestion {
//   final String formattedAddress;
//   final double latitude;
//   final double longitude;
//   final String? street;
//   final String? city;
//   final String? postcode;
//
//   AddressSuggestion({
//     required this.formattedAddress,
//     required this.latitude,
//     required this.longitude,
//     this.street,
//     this.city,
//     this.postcode,
//   });
//
//   factory AddressSuggestion.fromGeoapifyFeature(Map<String, dynamic> feature) {
//     final properties = feature['properties'];
//     final geometry = feature['geometry'];
//     final coordinates = geometry['coordinates'];
//
//     return AddressSuggestion(
//       formattedAddress: properties['formatted']?.toString() ?? '',
//       latitude: coordinates[1].toDouble(),
//       longitude: coordinates[0].toDouble(),
//       street: properties['street']?.toString(),
//       city: properties['city']?.toString(),
//       postcode: properties['postcode']?.toString(),
//     );
//   }
// }