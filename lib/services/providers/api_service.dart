import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/services.dart';

class ServiceAPI {
  static const String baseUrl = "https://www.hairbnb.site/api";

  // Récupérer les services d'une coiffeuse
  static Future<List<Service>> fetchServices(String coiffeuseId) async {
    final response = await http.get(Uri.parse("$baseUrl/get_services/$coiffeuseId/"));
    if (response.statusCode == 200) {

      // ✅ Toujours décoder en UTF-8 pour éviter les problèmes d'accents
      final decodedBody = utf8.decode(response.bodyBytes);
      final List data = json.decode(decodedBody)["salon"]["services"];

      return data.map((e) => Service.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des services");
    }
  }


}
