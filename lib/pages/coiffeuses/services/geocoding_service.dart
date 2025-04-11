import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';

  static Future<Position?> getCoordinatesFromCity(String city) async {
    try {
      final url = Uri.parse(
          'https://api.geoapify.com/v1/geocode/search?text=$city&apiKey=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;
        if (features.isNotEmpty) {
          final geometry = features[0]['geometry'];
          final lon = geometry['coordinates'][0];
          final lat = geometry['coordinates'][1];

          return Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 0.0,
            speedAccuracy: 1.0,
          );
        }
      }
    } catch (e) {
      print("❌ Erreur geocoding (Geoapify) : $e");
    }
    return null;
  }
}
