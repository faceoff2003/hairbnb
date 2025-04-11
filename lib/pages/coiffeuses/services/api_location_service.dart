import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static Future<List<dynamic>> fetchNearbyCoiffeuses(double lat, double lon, double distance) async {
    final url = Uri.parse('https://www.hairbnb.site/api/coiffeuses_proches/?lat=$lat&lon=$lon&distance=$distance');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['coiffeuses'];
      } else {
        throw Exception('Erreur de chargement des coiffeuses');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur');
    }
  }
}
