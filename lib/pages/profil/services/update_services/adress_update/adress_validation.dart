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