// import 'dart:developer';
//
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class EditServiceModal extends StatefulWidget {
//   final Service service;
//   final Function onServiceUpdated;
//   final Function(String) onError;
//
//   const EditServiceModal({
//     Key? key,
//     required this.service,
//     required this.onServiceUpdated,
//     required this.onError
//   }) : super(key: key);
//
//   @override
//   State<EditServiceModal> createState() => _EditServiceModalState();
// }
//
// class _EditServiceModalState extends State<EditServiceModal> {
//   late TextEditingController nameController;
//   late TextEditingController descriptionController;
//   late TextEditingController priceController;
//   late TextEditingController durationController;
//   bool isLoading = false;
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController(text: widget.service.intitule);
//     descriptionController = TextEditingController(text: widget.service.description);
//     priceController = TextEditingController(text: widget.service.prix.toString());
//     durationController = TextEditingController(text: widget.service.temps.toString());
//   }
//
//   @override
//   void dispose() {
//     nameController.dispose();
//     descriptionController.dispose();
//     priceController.dispose();
//     durationController.dispose();
//     super.dispose();
//   }
//
//   Widget buildTextField(String label, TextEditingController controller, IconData icon,
//       {TextInputType? keyboardType, int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: primaryViolet),
//           labelText: label,
//           labelStyle: const TextStyle(color: Color(0xFF555555)),
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> updateService() async {
//     if (nameController.text.isEmpty ||
//         descriptionController.text.isEmpty ||
//         priceController.text.isEmpty ||
//         durationController.text.isEmpty) {
//       widget.onError("Tous les champs sont obligatoires.");
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final response = await http.put(
//         Uri.parse('https://www.hairbnb.site/api/update_service/${widget.service.id}/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'intitule_service': nameController.text,
//           'description': descriptionController.text,
//           'prix': double.parse(priceController.text),
//           'temps_minutes': int.parse(durationController.text),
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         Navigator.pop(context, true); // Ferme le modal avec succès
//         widget.onServiceUpdated(); // Actualise la liste des services
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Service modifié avec succès ✅"),
//               backgroundColor: Colors.green
//           ),
//         );
//       } else {
//         widget.onError("Erreur lors de la modification : ${response.body}");
//       }
//     } catch (e) {
//       widget.onError("Erreur de connexion au serveur: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return StatefulBuilder(
//       builder: (BuildContext context, StateSetter setModalState) {
//         return AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//           padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             initialChildSize: 0.85,
//             maxChildSize: 0.95,
//             minChildSize: 0.5,
//             expand: false,
//             builder: (context, scrollController) => Container(
//               decoration: const BoxDecoration(
//                 color: Color(0xFFF7F7F9),
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: ListView(
//                 controller: scrollController,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   const Text(
//                     "Modifier le service",
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF333333),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   buildTextField("Nom du service", nameController, Icons.design_services),
//                   buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
//                   buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
//                   buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: isLoading
//                           ? null
//                           : () {
//                         setModalState(() {
//                           isLoading = true;
//                         });
//                         updateService().then((_) {
//                           setModalState(() {
//                             isLoading = false;
//                           });
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryViolet,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                         elevation: 4,
//                         shadowColor: const Color(0x887B61FF),
//                       ),
//                       child: isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text(
//                         "Enregistrer les modifications",
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// // Fonction pour afficher le modal
// void showEditServiceModal(
//     BuildContext context,
//     Service service,
//     Function onServiceUpdated,
//     Function(String) onError,
//     ) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => EditServiceModal(
//       service: service,
//       onServiceUpdated: onServiceUpdated,
//       onError: onError,
//     ),
//   ).then((value) {
//     if (value == true) {
//       onServiceUpdated();
//     }
//   });
// }