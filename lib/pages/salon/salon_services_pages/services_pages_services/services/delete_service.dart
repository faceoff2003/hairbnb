// Importations nécessaires
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> deleteService(int serviceId, BuildContext context, Function(String) showError,
    Function(void Function()) setState, List services, List filteredServices, int totalServices) async {
  final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
  try {
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      setState(() {
        services.removeWhere((s) => s.id == serviceId);
        filteredServices.removeWhere((s) => s.id == serviceId);
        totalServices--; // mise à jour du total
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service supprimé avec succès ✅"), backgroundColor: Colors.green),
      );
    } else {
      showError("Erreur lors de la suppression.");
    }
  } catch (e) {
    showError("Erreur de connexion au serveur.");
  }
}