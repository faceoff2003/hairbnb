import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/Services.dart';

class ServiceAPI {
  static const String baseUrl = "http://192.168.0.248:8000/api";

  // Récupérer les services d'une coiffeuse
  static Future<List<Service>> fetchServices(String coiffeuseId) async {
    final response = await http.get(Uri.parse("$baseUrl/get_services/$coiffeuseId/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)["salon"]["services"];
      return data.map((e) => Service.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des services");
    }
  }


}
