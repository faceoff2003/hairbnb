// import 'package:flutter/material.dart';
//
// class EditServicePage extends StatelessWidget {
//   final Map<String, dynamic> service; // Données du service sélectionné
//
//   const EditServicePage({Key? key, required this.service}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Modifier le service"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Nom du service : ${service['intitule_service'] ?? 'Non disponible'}",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text("Description : ${service['description'] ?? 'Non disponible'}"),
//             const SizedBox(height: 8),
//             Text("Prix : ${service['prix'] ?? 'Non disponible'} €"),
//             const SizedBox(height: 8),
//             Text("Durée : ${service['temps_minutes'] ?? 'Non disponible'} minutes"),
//           ],
//         ),
//       ),
//     );
//   }
// }
