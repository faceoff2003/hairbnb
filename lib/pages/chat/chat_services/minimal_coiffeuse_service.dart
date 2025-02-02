import 'dart:convert';
import 'package:hairbnb/models/MinimalCoiffeuse.dart';
import 'package:http/http.dart' as http;

class CoiffeuseService {
  static const String baseUrl = "http://192.168.0.248:8000";

  static Future<List<MinimalCoiffeuse>> fetchCoiffeuses(List<String> uuids) async {
    final url = Uri.parse('$baseUrl/api/get_coiffeuses_info/');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": uuids}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == "success") {
          return (data['coiffeuses'] as List)
              .map((json) => MinimalCoiffeuse.fromJson(json))
              .toList();
        } else {
          throw Exception("Erreur : ${data['message']}");
        }
      } else {
        throw Exception("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur lors de la récupération des coiffeuses : $e");
    }
  }
}
