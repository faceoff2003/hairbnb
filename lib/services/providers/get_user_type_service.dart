
import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> getIdAndTypeFromUuid(String uuid) async {
  final url = Uri.parse('https://www.hairbnb.site/api/get_id_and_type_from_uuid/$uuid/');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return {
          'idTblUser': data['idTblUser'],
          'type': data['type'],
        };
      } else {
        print("Erreur : ${data['error']}");
        return null;
      }
    } else {
      print("Erreur HTTP : ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Erreur réseau : $e");
    return null;
  }
}


