import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/coiffeuse.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.248:8000/api";

  Future<Coiffeuse?> fetchCoiffeuseByUuid(String uuid) async {
    final response = await http.get(Uri.parse("$baseUrl/get_coiffeuse_by_uuid/$uuid/"));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Coiffeuse.fromJson(jsonData["data"]);
    } else {
      return null;
    }
  }
}
