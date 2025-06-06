// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../gallery/add_gallery_page.dart';
//
// class AddServicePage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const AddServicePage({super.key, required this.coiffeuseId});
//
//   @override
//   State<AddServicePage> createState() => _AddServicePageState();
// }
//
// class _AddServicePageState extends State<AddServicePage> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController durationController = TextEditingController();
//   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
//
//   bool isLoading = false;
//   final List<Map<String, String>> addedServices = [];
//
//   Future<void> _addService() async {
//     if (nameController.text.isEmpty ||
//         descriptionController.text.isEmpty ||
//         priceController.text.isEmpty ||
//         durationController.text.isEmpty) {
//       _showError("Tous les champs sont obligatoires.");
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'userId': widget.coiffeuseId,
//           'intitule_service': nameController.text,
//           'description': descriptionController.text,
//           'prix': double.parse(priceController.text),
//           'temps_minutes': int.parse(durationController.text),
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         final newService = {
//           'nom': nameController.text,
//           'prix': priceController.text,
//           'duree': durationController.text,
//         };
//
//         setState(() {
//           addedServices.insert(0, newService);
//           _listKey.currentState?.insertItem(0);
//         });
//
//         nameController.clear();
//         descriptionController.clear();
//         priceController.clear();
//         durationController.clear();
//       } else {
//         _showError("Erreur lors de l'ajout : ${response.body}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _removeService(int index) {
//     final removed = addedServices.removeAt(index);
//     _listKey.currentState?.removeItem(
//       index,
//           (context, animation) => _buildServiceCard(removed, animation, index),
//       duration: const Duration(milliseconds: 300),
//     );
//     setState(() {}); // force rebuild to hide button if needed
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg, style: const TextStyle(color: Colors.white)),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller, IconData icon,
//       {TextInputType? keyboardType, int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         onSubmitted: (_) => _addService(),
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
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
//   Widget _buildServiceCard(Map<String, String> service, Animation<double> animation, int index) {
//     return SizeTransition(
//       sizeFactor: animation,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: const Color(0xFF7B61FF),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 service['nom'] ?? '',
//                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Text("€${service['prix']}", style: const TextStyle(fontSize: 13, color: Colors.white)),
//             const SizedBox(width: 16),
//             Text("${service['duree']} min", style: const TextStyle(fontSize: 13, color: Colors.white)),
//             IconButton(
//               icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
//               tooltip: 'Supprimer',
//               onPressed: () => _removeService(index),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Ajouter un service"),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 600),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text("Détails du service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
//                 const SizedBox(height: 30),
//                 _buildTextField("Nom du service", nameController, Icons.design_services),
//                 _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
//                 _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
//                 _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
//                 const SizedBox(height: 20),
//                 MouseRegion(
//                   cursor: SystemMouseCursors.click,
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     curve: Curves.easeInOut,
//                     child: SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : _addService,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF7B61FF),
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                           elevation: 4,
//                           shadowColor: const Color(0x887B61FF),
//                         ).copyWith(
//                           overlayColor: WidgetStateProperty.all(const Color(0xFF674ED1)),
//                         ),
//                         child: isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 if (addedServices.isNotEmpty) ...[
//                   const Text("Services ajoutés :", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
//                   const SizedBox(height: 12),
//                   AnimatedList(
//                     key: _listKey,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     initialItemCount: addedServices.length,
//                     itemBuilder: (context, index, animation) {
//                       return _buildServiceCard(addedServices[index], animation, index);
//                     },
//                   ),
//                   const SizedBox(height: 40),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: ElevatedButton.icon(
//                       onPressed: () => Navigator.push(
//                           context, MaterialPageRoute(
//                           builder: (context) => const AddGalleryPage()
//                       )),
//                       icon: const Icon(Icons.arrow_forward),
//                       label: const Text("Suivant : Ajouter des photos"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                       ),
//                     ),
//                   )
//                 ]
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
// //
// //   bool isLoading = false;
// //   final List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() => isLoading = true);
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         final newService = {
// //           'nom': nameController.text,
// //           'prix': priceController.text,
// //           'duree': durationController.text,
// //         };
// //
// //         addedServices.insert(0, newService);
// //         _listKey.currentState?.insertItem(0);
// //
// //         nameController.clear();
// //         descriptionController.clear();
// //         priceController.clear();
// //         durationController.clear();
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() => isLoading = false);
// //     }
// //   }
// //
// //   void _removeService(int index) {
// //     final removed = addedServices.removeAt(index);
// //     _listKey.currentState?.removeItem(
// //       index,
// //           (context, animation) => _buildServiceCard(removed, animation, index),
// //       duration: const Duration(milliseconds: 300),
// //     );
// //   }
// //
// //   void _showError(String msg) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(msg, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon,
// //       {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         onSubmitted: (_) => _addService(),
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service, Animation<double> animation, int index) {
// //     return SizeTransition(
// //       sizeFactor: animation,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(vertical: 6),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF7B61FF),
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           children: [
// //             Expanded(
// //               child: Text(
// //                 service['nom'] ?? '',
// //                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             Text("€${service['prix']}", style: const TextStyle(fontSize: 13, color: Colors.white)),
// //             const SizedBox(width: 16),
// //             Text("${service['duree']} min", style: const TextStyle(fontSize: 13, color: Colors.white)),
// //             IconButton(
// //               icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
// //               tooltip: 'Supprimer',
// //               onPressed: () => _removeService(index),
// //             )
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //         backgroundColor: const Color(0xFFF7F7F9),
// //         appBar: AppBar(
// //           title: const Text("Ajouter un service"),
// //           centerTitle: true,
// //           backgroundColor: const Color(0xFF7B61FF),
// //           foregroundColor: Colors.white,
// //           elevation: 0,
// //           automaticallyImplyLeading: false,
// //         ),
// //         body: SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //                 child: ConstrainedBox(
// //                     constraints: const BoxConstraints(maxWidth: 600),
// //                     child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                         const Text("Détails du service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                 const Text("Services ajoutés :", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
// //             const SizedBox(height: 12),
// //             AnimatedList(
// //               key: _listKey,
// //               shrinkWrap: true,
// //               physics: const NeverScrollableScrollPhysics(),
// //               initialItemCount: addedServices.length,
// //               itemBuilder: (context, index, animation) {
// //                 return _buildServiceCard(addedServices[index], animation, index);
// //               },
// //             )
// //             ],
// //             if (addedServices.isNotEmpty) ...[
// //         if (addedServices.isNotEmpty) ...[
// //           const SizedBox(height: 40),
// //           Builder(
// //             builder: (_) {
// //               if (addedServices.isEmpty) return const SizedBox.shrink();
// //               return Align(
// //                 alignment: Alignment.centerRight,
// //                 child: ElevatedButton.icon(
// //                   onPressed: () => Navigator.pushNamed(context, '/add_gallery'),
// //                   icon: const Icon(Icons.arrow_forward),
// //                   label: const Text("Suivant : Ajouter des photos"),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.deepPurple,
// //                     foregroundColor: Colors.white,
// //                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                   ),
// //                 ),
// //               );
// //             },
// //           ),
// //
// //
// //         ],
// //
// //     ]])
// //                 )
// //             )
// //         )
// //     );
// //
// //   }
// // }
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> with SingleTickerProviderStateMixin {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
// //   final List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         final newService = {
// //           'nom': nameController.text,
// //           'prix': priceController.text,
// //           'duree': durationController.text,
// //         };
// //
// //         setState(() {
// //           addedServices.insert(0, newService);
// //         });
// //         _listKey.currentState?.insertItem(0);
// //
// //         nameController.clear();
// //         descriptionController.clear();
// //         priceController.clear();
// //         durationController.clear();
// //
// //
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _removeService(int index) {
// //     final removedService = addedServices.removeAt(index);
// //     _listKey.currentState?.removeItem(
// //       index,
// //           (context, animation) => _buildServiceCard(removedService, animation, index),
// //       duration: const Duration(milliseconds: 300),
// //     );
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         onSubmitted: (_) => _addService(),
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service, Animation<double> animation, int index) {
// //     return SizeTransition(
// //       sizeFactor: animation,
// //       axis: Axis.vertical,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(vertical: 6),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF7B61FF),
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           children: [
// //             Expanded(
// //               child: Text(
// //                 service['nom'] ?? '',
// //                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             Text(
// //               "€${service['prix']}",
// //               style: const TextStyle(fontSize: 13, color: Colors.white),
// //             ),
// //             const SizedBox(width: 16),
// //             Text(
// //               "${service['duree']} min",
// //               style: const TextStyle(fontSize: 13, color: Colors.white),
// //             ),
// //             IconButton(
// //               onPressed: () => _removeService(index),
// //               icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
// //               tooltip: 'Supprimer',
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //               padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //               child: Center(
// //                 child: ConstrainedBox(
// //                     constraints: const BoxConstraints(maxWidth: 600),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                       const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                 const Text(
// //                 "Services ajoutés :",
// //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //               ),
// //               const SizedBox(height: 12),
// //               AnimatedList(
// //                 key: _listKey,
// //                 shrinkWrap: true,
// //                 physics: const NeverScrollableScrollPhysics(),
// //                 initialItemCount: addedServices.length,
// //                 itemBuilder: (context, index, animation) {
// //                   return _buildServiceCard(addedServices[index], animation, index);
// //                 },
// //               ),
// //               const SizedBox(height: 40),
// //           Align(
// //           alignment: Alignment.centerRight,
// //           child: ElevatedButton.icon(
// //           onPressed: () {
// //           // Naviguer vers la page Galerie (à remplacer par ta route réelle)
// //           Navigator.pushNamed(context, '/add_gallery');
// //           },
// //           icon: const Icon(Icons.arrow_forward),
// //           label: const Text("Suivant : Ajouter des photos"),
// //           style: ElevatedButton.styleFrom(
// //           backgroundColor: Colors.deepPurple,
// //           foregroundColor: Colors.white,
// //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// //           shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(14),
// //           ),
// //           ),
// //           ),
// //           ),
// //           ],
// //           ],
// //           ),
// //           ),
// //           ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> with SingleTickerProviderStateMixin {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
// //   final List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         final newService = {
// //           'nom': nameController.text,
// //           'prix': priceController.text,
// //           'duree': durationController.text,
// //         };
// //
// //         setState(() {
// //           addedServices.insert(0, newService);
// //         });
// //         _listKey.currentState?.insertItem(0);
// //
// //         nameController.clear();
// //         descriptionController.clear();
// //         priceController.clear();
// //         durationController.clear();
// //
// //         // ScaffoldMessenger.of(context).showSnackBar(
// //         //   const SnackBar(
// //         //     content: Text("Service ajouté avec succès."),
// //         //     backgroundColor: Colors.green,
// //         //   ),
// //         // );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         onSubmitted: (_) => _addService(),
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service, Animation<double> animation) {
// //     return SizeTransition(
// //       sizeFactor: animation,
// //       axis: Axis.vertical,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(vertical: 6),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF7B61FF),
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           children: [
// //             Expanded(
// //               child: Text(
// //                 service['nom'] ?? '',
// //                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             const SizedBox(width: 16),
// //             Text(
// //               "€${service['prix']}",
// //               style: const TextStyle(fontSize: 13, color: Colors.white),
// //             ),
// //             const SizedBox(width: 16),
// //             Text(
// //               "${service['duree']} min",
// //               style: const TextStyle(fontSize: 13, color: Colors.white),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       AnimatedList(
// //                         key: _listKey,
// //                         shrinkWrap: true,
// //                         physics: const NeverScrollableScrollPhysics(),
// //                         initialItemCount: addedServices.length,
// //                         itemBuilder: (context, index, animation) {
// //                           return _buildServiceCard(addedServices[index], animation);
// //                         },
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> with SingleTickerProviderStateMixin {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
// //   final List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         final newService = {
// //           'nom': nameController.text,
// //           'prix': priceController.text,
// //           'duree': durationController.text,
// //         };
// //
// //         setState(() {
// //           addedServices.insert(0, newService);
// //         });
// //         _listKey.currentState?.insertItem(0);
// //
// //         nameController.clear();
// //         descriptionController.clear();
// //         priceController.clear();
// //         durationController.clear();
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service, Animation<double> animation) {
// //     return SizeTransition(
// //       sizeFactor: animation,
// //       axis: Axis.vertical,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(vertical: 6),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF7B61FF),
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           children: [
// //             Expanded(
// //               child: Text(
// //                 service['nom'] ?? '',
// //                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             const SizedBox(width: 16),
// //             Text(
// //               "€${service['prix']}",
// //               style: const TextStyle(fontSize: 13, color: Colors.white),
// //             ),
// //             const SizedBox(width: 16),
// //             Text(
// //               "${service['duree']} min",
// //               style: const TextStyle(fontSize: 13, color: Colors.white),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       AnimatedList(
// //                         key: _listKey,
// //                         shrinkWrap: true,
// //                         physics: const NeverScrollableScrollPhysics(),
// //                         initialItemCount: addedServices.length,
// //                         itemBuilder: (context, index, animation) {
// //                           return _buildServiceCard(addedServices[index], animation);
// //                         },
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         setState(() {
// //           addedServices.insert(0, {
// //             'nom': nameController.text,
// //             'prix': priceController.text,
// //             'duree': durationController.text,
// //           });
// //
// //           nameController.clear();
// //           descriptionController.clear();
// //           priceController.clear();
// //           durationController.clear();
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service) {
// //     return Container(
// //       margin: const EdgeInsets.symmetric(vertical: 6),
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF7B61FF),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Text(
// //               service['nom'] ?? '',
// //               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //           ),
// //           const SizedBox(width: 16),
// //           Text(
// //             "€${service['prix']}",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //           const SizedBox(width: 16),
// //           Text(
// //             "${service['duree']} min",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Column(
// //                         children: addedServices.map(_buildServiceCard).toList(),
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         setState(() {
// //           addedServices.add({
// //             'nom': nameController.text,
// //             'prix': priceController.text,
// //             'duree': durationController.text,
// //           });
// //
// //           nameController.clear();
// //           descriptionController.clear();
// //           priceController.clear();
// //           durationController.clear();
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service) {
// //     return Container(
// //       margin: const EdgeInsets.symmetric(vertical: 6),
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF7B61FF),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Text(
// //               service['nom'] ?? '',
// //               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //           ),
// //           const SizedBox(width: 16),
// //           Text(
// //             "€${service['prix']}",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //           const SizedBox(width: 16),
// //           Text(
// //             "${service['duree']} min",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Column(
// //                         children: addedServices.map(_buildServiceCard).toList(),
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:animated_text_kit/animated_text_kit.dart';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         setState(() {
// //           addedServices.add({
// //             'nom': nameController.text,
// //             'prix': priceController.text,
// //             'duree': durationController.text,
// //           });
// //
// //           nameController.clear();
// //           descriptionController.clear();
// //           priceController.clear();
// //           durationController.clear();
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service) {
// //     return Container(
// //       margin: const EdgeInsets.all(8),
// //       padding: const EdgeInsets.all(12),
// //       width: 160,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF7B61FF),
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           ClipRect(
// //             child: SizedBox(
// //               height: 20,
// //               width: double.infinity,
// //               child: LayoutBuilder(
// //                 builder: (context, constraints) {
// //                   return TweenAnimationBuilder(
// //                     tween: Tween<Offset>(
// //                       begin: const Offset(0, 0),
// //                       end: const Offset(-1, 0),
// //                     ),
// //                     duration: const Duration(seconds: 6),
// //                     curve: Curves.linear,
// //                     builder: (context, Offset offset, child) {
// //                       return FractionalTranslation(
// //                         translation: offset,
// //                         child: child,
// //                       );
// //                     },
// //                     child: Text(
// //                       service['nom'] ?? '',
// //                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //                       maxLines: 1,
// //                       overflow: TextOverflow.visible,
// //                       softWrap: false,
// //                     ),
// //                     onEnd: () {
// //                       setState(() {}); // reboucle
// //                     },
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             "Prix: €${service['prix']}",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //           Text(
// //             "Durée: ${service['duree']} min",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Wrap(
// //                         spacing: 12,
// //                         runSpacing: 12,
// //                         children: addedServices.map(_buildServiceCard).toList(),
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         setState(() {
// //           addedServices.add({
// //             'nom': nameController.text,
// //             'prix': priceController.text,
// //             'duree': durationController.text,
// //           });
// //
// //           nameController.clear();
// //           descriptionController.clear();
// //           priceController.clear();
// //           durationController.clear();
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service) {
// //     return Container(
// //       margin: const EdgeInsets.all(8),
// //       padding: const EdgeInsets.all(12),
// //       width: 160,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF7B61FF),
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           SingleChildScrollView(
// //             scrollDirection: Axis.horizontal,
// //             child: Text(
// //               service['nom'] ?? '',
// //               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             "Prix: €${service['prix']}",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //           Text(
// //             "Durée: ${service['duree']} min",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Wrap(
// //                         spacing: 12,
// //                         runSpacing: 12,
// //                         children: addedServices.map(_buildServiceCard).toList(),
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         setState(() {
// //           addedServices.add({
// //             'nom': nameController.text,
// //             'prix': priceController.text,
// //             'duree': durationController.text,
// //           });
// //
// //           nameController.clear();
// //           descriptionController.clear();
// //           priceController.clear();
// //           durationController.clear();
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service) {
// //     return Container(
// //       margin: const EdgeInsets.all(8),
// //       padding: const EdgeInsets.all(12),
// //       width: 160,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF7B61FF),
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             service['nom'] ?? '',
// //             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             "Prix: €${service['prix']}",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //           Text(
// //             "Durée: ${service['duree']} min",
// //             style: const TextStyle(fontSize: 13, color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Wrap(
// //                         spacing: 12,
// //                         runSpacing: 12,
// //                         children: addedServices.map(_buildServiceCard).toList(),
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         setState(() {
// //           addedServices.add({
// //             'nom': nameController.text,
// //             'prix': priceController.text,
// //             'duree': durationController.text,
// //           });
// //
// //           nameController.clear();
// //           descriptionController.clear();
// //           priceController.clear();
// //           durationController.clear();
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service) {
// //     return Container(
// //       margin: const EdgeInsets.all(8),
// //       padding: const EdgeInsets.all(12),
// //       width: 160,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF7B61FF),
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Icon(Icons.image_outlined, color: Colors.white, size: 48),
// //           const SizedBox(height: 8),
// //           Text(
// //             service['nom'] ?? '',
// //             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             "€${service['prix']}",
// //             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Wrap(
// //                         spacing: 12,
// //                         runSpacing: 12,
// //                         children: addedServices.map(_buildServiceCard).toList(),
// //                       ),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   List<Map<String, String>> addedServices = [];
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         setState(() {
// //           addedServices.add({
// //             'nom': nameController.text,
// //             'description': descriptionController.text,
// //             'prix': priceController.text,
// //             'duree': durationController.text,
// //           });
// //
// //           nameController.clear();
// //           descriptionController.clear();
// //           priceController.clear();
// //           durationController.clear();
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildServiceCard(Map<String, String> service) {
// //     return Container(
// //       margin: const EdgeInsets.only(top: 12),
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black12,
// //             blurRadius: 6,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(service['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
// //           const SizedBox(height: 4),
// //           Text(service['description'] ?? '', style: const TextStyle(color: Colors.black54)),
// //           const SizedBox(height: 8),
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               Text("Prix: €${service['prix'] ?? ''}"),
// //               Text("Durée: ${service['duree'] ?? ''} min"),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     if (addedServices.isNotEmpty) ...[
// //                       const Text(
// //                         "Services ajoutés :",
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       ...addedServices.map(_buildServiceCard).toList(),
// //                     ]
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
// //============================================100%================================================================
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //         Navigator.pop(context, true);
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (kDebugMode) {
// //       print('${nameController.text}--${descriptionController.text}--${priceController.text}--${durationController.text}');
// //     }
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //         Navigator.pop(context, true);
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
// //           labelText: label,
// //           labelStyle: const TextStyle(color: Color(0xFF555555)),
// //           filled: true,
// //           fillColor: Colors.white,
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (kDebugMode) {
// //       print('${nameController.text}--${descriptionController.text}--${priceController.text}--${durationController.text}');
// //     }
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Center(
// //               child: ConstrainedBox(
// //                 constraints: const BoxConstraints(maxWidth: 600),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Détails du service",
// //                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     _buildTextField("Nom du service", nameController, Icons.design_services),
// //                     _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// //                     _buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     _buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// //                     const SizedBox(height: 20),
// //                     MouseRegion(
// //                       cursor: SystemMouseCursors.click,
// //                       child: AnimatedContainer(
// //                         duration: const Duration(milliseconds: 200),
// //                         curve: Curves.easeInOut,
// //                         child: SizedBox(
// //                           width: double.infinity,
// //                           child: ElevatedButton(
// //                             onPressed: isLoading ? null : _addService,
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(vertical: 16),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                               elevation: 4,
// //                               shadowColor: const Color(0x887B61FF),
// //                             ).copyWith(
// //                               overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
// //                             ),
// //                             child: isLoading
// //                                 ? const CircularProgressIndicator(color: Colors.white)
// //                                 : const Text("Ajouter le service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class AddServicePage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<AddServicePage> createState() => _AddServicePageState();
// // }
// //
// // class _AddServicePageState extends State<AddServicePage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   bool isLoading = false;
// //
// //   Future<void> _addService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'userId': widget.coiffeuseId,
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'prix': double.parse(priceController.text),
// //           'temps_minutes': int.parse(durationController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service ajouté avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //         Navigator.pop(context, true);
// //       } else {
// //         _showError("Erreur lors de l'ajout : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     //------------------------------------------------------------------------------------------------------------------------------------
// //     if (kDebugMode) {
// //       print('${nameController.text}--${descriptionController.text}--${priceController.text}--${durationController.text}');
// //     }
// //     //-------------------------------------------------------------------------------------------------------------------------------------
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Ajouter un service"),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           children: [
// //             TextField(
// //               controller: nameController,
// //               decoration: const InputDecoration(labelText: "Nom du service"),
// //             ),
// //             TextField(
// //               controller: descriptionController,
// //               decoration: const InputDecoration(labelText: "Description"),
// //               maxLines: 3,
// //             ),
// //             TextField(
// //               controller: priceController,
// //               decoration: const InputDecoration(labelText: "Prix (€)"),
// //               keyboardType: TextInputType.number,
// //             ),
// //             TextField(
// //               controller: durationController,
// //               decoration: const InputDecoration(labelText: "Durée (minutes)"),
// //               keyboardType: TextInputType.number,
// //             ),
// //             const SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: _addService,
// //               child: isLoading ? const CircularProgressIndicator() : const Text("Ajouter"),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
