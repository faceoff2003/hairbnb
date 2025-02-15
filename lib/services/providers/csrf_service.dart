import 'package:http/http.dart' as http;

class CSRFService {
  static String? csrfToken;

  static Future<void> fetchCSRFToken() async {
    final response = await http.get(Uri.parse('https://www.hairbnb.site/api/services/'));
    if (response.headers.containsKey('set-cookie')) {
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        final match = RegExp(r'csrftoken=([^;]+)').firstMatch(cookies);
        if (match != null) {
          csrfToken = match.group(1);
          print('CSRF Token fetched: $csrfToken');
        }
      }
    }
  }
}
