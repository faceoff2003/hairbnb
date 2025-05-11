// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import '../../services/providers/current_user_provider.dart';
//
// /// **Page pour afficher les RDVs d'une coiffeuse**
// class RdvCoiffeusePage extends StatefulWidget {
//   @override
//   _RdvCoiffeusePageState createState() => _RdvCoiffeusePageState();
// }
//
// class _RdvCoiffeusePageState extends State<RdvCoiffeusePage> {
//   List<dynamic> rdvs = [];
//   bool isLoading = true;
//   bool hasError = false;
//   String? coiffeuseId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       coiffeuseId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//     if (coiffeuseId != null) {
//       _fetchRdvCoiffeuse();
//     }
//   }
//
//   Future<void> _fetchRdvCoiffeuse() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//     try {
//       final response = await http.get(Uri.parse('https://www.hairbnb.site/api/get_rendez_vous_coiffeuse/$coiffeuseId/'));
//       if (response.statusCode == 200) {
//         setState(() {
//           rdvs = json.decode(response.body)['rendez_vous'];
//           isLoading = false;
//         });
//       } else {
//         throw Exception("Erreur lors du chargement des RDVs.");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("📅 Mes RDVs"), backgroundColor: Colors.orange),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: ElevatedButton(
//           onPressed: _fetchRdvCoiffeuse,
//           child: const Text("Réessayer"),
//         ),
//       )
//           : rdvs.isEmpty
//           ? const Center(child: Text("Aucun rendez-vous trouvé."))
//           : ListView.builder(
//         itemCount: rdvs.length,
//         itemBuilder: (context, index) {
//           final rdv = rdvs[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//             child: ListTile(
//               leading: const Icon(Icons.person, color: Colors.blue),
//               title: Text("Client: ${rdv['client']['nom']} ${rdv['client']['prenom']}",
//                   style: const TextStyle(fontWeight: FontWeight.bold)),
//               subtitle: Text("📅 ${rdv['date_heure']} - 💰 ${rdv['total_prix']}€ - ⏳ ${rdv['duree_totale']} min"),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
