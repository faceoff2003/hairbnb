import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void deleteService(
    BuildContext context,
    int serviceId,
    VoidCallback onServiceDeleted,
    VoidCallback onInstantDelete, // Nouvelle fonction pour suppression instantanée
    ) async {

  // Supprimer instantanément l'élément de l'UI
  onInstantDelete();

  final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');

  try {
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Service supprimé"), backgroundColor: Colors.green),
      );
    } else {
      _showError(context, "Erreur lors de la suppression.");
      onServiceDeleted(); // Ré-afficher les services si erreur
    }
  } catch (e) {
    _showError(context, "Erreur de connexion au serveur.");
    onServiceDeleted(); // Ré-afficher les services si erreur
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
  );
}



// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// void deleteService(BuildContext context, int serviceId, VoidCallback onServiceDeleted) async {
//   final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//
//   try {
//     final response = await http.delete(url);
//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("✅ Service supprimé"), backgroundColor: Colors.green),
//       );
//       onServiceDeleted(); // Rafraîchir la liste après suppression
//     } else {
//       _showError(context, "Erreur lors de la suppression.");
//     }
//   } catch (e) {
//     _showError(context, "Erreur de connexion au serveur.");
//   }
// }
//
// void _showError(BuildContext context, String message) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//   );
// }
