// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../gallery/add_gallery_page.dart';
// import 'select_services_page.dart';
// import 'package:hairbnb/models/service_creation.dart'; // Import the ServiceCreation model
//
// class CreateServicesPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   final dynamic selectedCategoryId;
//
//   const CreateServicesPage({super.key, required this.currentUser, this.selectedCategoryId,});
//
//   @override
//   State<CreateServicesPage> createState() => _CreateServicesPageState();
// }
//
// class _CreateServicesPageState extends State<CreateServicesPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nomController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _prixController = TextEditingController();
//   final _dureeController = TextEditingController();
//
//   bool isSubmitting = false;
//   bool isSearching = false;
//   List<ExistingService> similarServices = [];
//   ExistingService? suggestedService;
//   bool showSuggestions = false;
//
//   @override
//   void dispose() {
//     _nomController.dispose();
//     _descriptionController.dispose();
//     _prixController.dispose();
//     _dureeController.dispose();
//     super.dispose();
//   }
//
//   // Recherche de services similaires pendant que l'utilisateur tape
//   void _onServiceNameChanged(String value) {
//     if (value.length >= 2) {
//       _searchSimilarServices(value);
//     } else {
//       setState(() {
//         similarServices.clear();
//         showSuggestions = false;
//         suggestedService = null;
//       });
//     }
//   }
//
//   Future<void> _searchSimilarServices(String searchTerm) async {
//     if (isSearching) return;
//
//     setState(() => isSearching = true);
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/services/search/?q=${Uri.encodeComponent(searchTerm)}&limit=5'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           final servicesJson = data['services'] as List;
//
//           setState(() {
//             similarServices = servicesJson
//                 .map((json) => ExistingService.fromJson(json))
//                 .toList();
//             showSuggestions = similarServices.isNotEmpty;
//           });
//         }
//       }
//     } catch (e) {
//       // Erreur silencieuse pour la recherche en temps réel
//       print('Erreur recherche: $e');
//     } finally {
//       setState(() => isSearching = false);
//     }
//   }
//
//   Future<void> _createNewService() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => isSubmitting = true);
//
//     try {
//       // Récupérer le token Firebase
//       final user = FirebaseAuth.instance.currentUser;
//       final firebaseToken = user != null ? await user.getIdToken() : null;
//
//       Map<String, String> headers = {'Content-Type': 'application/json'};
//       if (firebaseToken != null) {
//         headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       // Create a ServiceCreation object
//       final newService = ServiceCreation(
//         userId: int.parse(widget.currentUser.idTblUser.toString()),
//         intituleService: _nomController.text.trim(),
//         description: _descriptionController.text.trim(),
//         prix: double.parse(_prixController.text),
//         tempsMinutes: int.parse(_dureeController.text),
//         categorieId: _selectedCategoryId, // Use the selected category ID
//       );
//
//       // Validate the service creation data
//       final validationError = newService.validate();
//       if (validationError != null) {
//         _showError(validationError);
//         setState(() => isSubmitting = false);
//         return;
//       }
//
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
//         headers: headers,
//         body: json.encode(newService.toJson()), // Use the toJson method from ServiceCreation
//       );
//
//       final responseData = json.decode(response.body);
//
//       if (response.statusCode == 201) {
//         // ✅ Afficher le dialogue de choix au lieu de rediriger automatiquement
//         _afficherDialogueSucces();
//
//       } else if (response.statusCode == 409) {
//         // Conflit - service similaire existe
//         _showConflictDialog(responseData);
//
//       } else {
//         _showError(responseData['message'] ?? 'Erreur lors de la création du service');
//       }
//
//     } catch (e) {
//       _showError('Erreur lors de la création du service: $e');
//     } finally {
//       setState(() => isSubmitting = false);
//     }
//   }
//
//   /// ✅ NOUVEAU DIALOGUE DE CHOIX APRÈS CRÉATION RÉUSSIE
//   void _afficherDialogueSucces() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade100,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.check_circle,
//                   color: Colors.green.shade600,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Text(
//                   "Service créé !",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Le service '${_nomController.text}' a été créé et ajouté à votre salon avec succès.",
//                 style: const TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "Que souhaitez-vous faire maintenant ?",
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.grey,
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             // ✅ Bouton pour créer un autre service
//             TextButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Fermer le dialogue
//
//                 // Réinitialiser les champs pour permettre de créer un nouveau service
//                 setState(() {
//                   _nomController.clear();
//                   _descriptionController.clear();
//                   _prixController.clear();
//                   _dureeController.clear();
//                   similarServices.clear();
//                   showSuggestions = false;
//                 });
//
//                 // Afficher un message pour indiquer qu'on peut continuer
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text("Vous pouvez maintenant créer un autre service"),
//                     backgroundColor: Colors.blue,
//                     duration: Duration(seconds: 2),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.add_circle_outline),
//               label: const Text("Créer un autre service"),
//             ),
//
//             // ✅ Bouton pour passer à la galerie
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Fermer le dialogue
//
//                 // Rediriger vers la galerie
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const AddGalleryPage(),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.photo_library),
//               label: const Text("Passer à la galerie"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7B61FF),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showConflictDialog(Map<String, dynamic> responseData) {
//     final existingService = ExistingService.fromJson(responseData['existing_service']);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Service similaire trouvé'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(responseData['message'] ?? 'Un service similaire existe déjà'),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.blue.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     existingService.nom,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     existingService.description,
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Utilisé par ${existingService.nbSalonsUtilisant} salon(s)',
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                   if (existingService.prixPopulaires.isNotEmpty)
//                     Text(
//                       'Prix fréquents: ${existingService.prixPopulaires.join(', ')}€',
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Créer quand même'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _useExistingService(existingService);
//             },
//             child: const Text('Utiliser ce service'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _useExistingService(ExistingService service) {
//     // Rediriger vers SelectServicesPage avec ce service pré-sélectionné
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (context) => SelectServicesPage(
//           currentUser: widget.currentUser,
//         ),
//       ),
//     );
//
//     // Ou vous pouvez directement l'ajouter au salon ici
//     _addExistingServiceToSalon(service);
//   }
//
//   Future<void> _addExistingServiceToSalon(ExistingService service) async {
//     setState(() => isSubmitting = true);
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final firebaseToken = user != null ? await user.getIdToken() : null;
//
//       Map<String, String> headers = {'Content-Type': 'application/json'};
//       if (firebaseToken != null) {
//         headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       // Create a ServiceCreation object for adding an existing service
//       // Note: For 'add-existing' endpoint, the backend might expect slightly different data,
//       // but if it accepts a similar structure, you can adapt ServiceCreation or create a new model.
//       // For simplicity, let's assume it also takes userId, service_id, prix, temps_minutes.
//       final existingServiceToAdd = {
//         'userId': int.parse(widget.currentUser.idTblUser.toString()),
//         'service_id': service.id,
//         'prix': double.parse(_prixController.text),
//         'temps_minutes': int.parse(_dureeController.text),
//       };
//
//
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
//         headers: headers,
//         body: json.encode(existingServiceToAdd), // Use the map directly or a dedicated model
//       );
//
//       if (response.statusCode == 201) {
//         _showSuccess("Service existant ajouté à votre salon !");
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (context) => const AddGalleryPage(),
//           ),
//         );
//       } else {
//         final errorData = json.decode(response.body);
//         _showError(errorData['message'] ?? 'Erreur lors de l\'ajout du service');
//       }
//
//     } catch (e) {
//       _showError('Erreur: $e');
//     } finally {
//       setState(() => isSubmitting = false);
//     }
//   }
//
//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Créer un nouveau service"),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.of(context).pushReplacement(
//               MaterialPageRoute(
//                 builder: (context) => SelectServicesPage(
//                   currentUser: widget.currentUser,
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 600),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Créer un nouveau service",
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF333333),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Ce service sera disponible pour tous les salons sur Hairbnb",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Color(0xFF666666),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//
//                   // Champ nom du service
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Nom du service *",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF333333),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         controller: _nomController,
//                         decoration: InputDecoration(
//                           hintText: "Ex: Coupe femme, Balayage, Brushing...",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                           ),
//                           suffixIcon: isSearching
//                               ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                               : null,
//                         ),
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Le nom du service est obligatoire';
//                           }
//                           if (value.trim().length < 2) {
//                             return 'Le nom doit contenir au moins 2 caractères';
//                           }
//                           return null;
//                         },
//                         onChanged: _onServiceNameChanged,
//                       ),
//
//                       // Suggestions de services similaires
//                       if (showSuggestions && similarServices.isNotEmpty) ...[
//                         const SizedBox(height: 12),
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.orange.shade50,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.orange.shade200),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(Icons.warning_amber,
//                                       color: Colors.orange.shade600,
//                                       size: 20),
//                                   const SizedBox(width: 8),
//                                   const Text(
//                                     "Services similaires trouvés",
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.orange,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               ...similarServices.take(3).map((service) =>
//                                   _buildSuggestionCard(service)
//                               ),
//                               const SizedBox(height: 8),
//                               TextButton(
//                                 onPressed: () {
//                                   setState(() {
//                                     showSuggestions = false;
//                                   });
//                                 },
//                                 child: const Text("Créer un nouveau service quand même"),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Champ description
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Description",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF333333),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         controller: _descriptionController,
//                         maxLines: 3,
//                         decoration: InputDecoration(
//                           hintText: "Décrivez le service en détail...",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'La description est obligatoire';
//                           }
//                           return null;
//                         },
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Prix et durée
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Prix (€) *",
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF333333),
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             TextFormField(
//                               controller: _prixController,
//                               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                               decoration: InputDecoration(
//                                 hintText: "25.00",
//                                 prefixIcon: const Icon(Icons.euro),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide(color: Colors.grey.shade300),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                                 ),
//                               ),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Prix requis';
//                                 }
//                                 final prix = double.tryParse(value);
//                                 if (prix == null || prix <= 0) {
//                                   return 'Prix invalide';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Durée (min) *",
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF333333),
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             TextFormField(
//                               controller: _dureeController,
//                               keyboardType: TextInputType.number,
//                               decoration: InputDecoration(
//                                 hintText: "30",
//                                 prefixIcon: const Icon(Icons.timer),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide(color: Colors.grey.shade300),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                                 ),
//                               ),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Durée requise';
//                                 }
//                                 final duree = int.tryParse(value);
//                                 if (duree == null || duree <= 0) {
//                                   return 'Durée invalide';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 30),
//
//                   // Info box
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.blue.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.info_outline, color: Colors.blue.shade600),
//                         const SizedBox(width: 12),
//                         const Expanded(
//                           child: Text(
//                             "Ce service sera créé globalement et pourra être utilisé par d'autres salons avec leurs propres prix et durées.",
//                             style: TextStyle(fontSize: 14, color: Colors.blue),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 30),
//
//                   // Boutons d'action
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: isSubmitting ? null : () {
//                             Navigator.of(context).pushReplacement(
//                               MaterialPageRoute(
//                                 builder: (context) => SelectServicesPage(
//                                   currentUser: widget.currentUser,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             side: const BorderSide(color: Color(0xFF7B61FF)),
//                           ),
//                           child: const Text(
//                             "Retour",
//                             style: TextStyle(color: Color(0xFF7B61FF)),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         flex: 2,
//                         child: ElevatedButton.icon(
//                           onPressed: isSubmitting ? null : _createNewService,
//                           icon: isSubmitting
//                               ? const SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                               : const Icon(Icons.add),
//                           label: Text(isSubmitting
//                               ? "Création en cours..."
//                               : "Créer le service"),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7B61FF),
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSuggestionCard(ExistingService service) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   service.nom,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   service.description,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 Text(
//                   "Utilisé par ${service.nbSalonsUtilisant} salon(s)",
//                   style: const TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => _useExistingService(service),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//             child: const Text("Utiliser", style: TextStyle(fontSize: 12)),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Modèle pour les services existants trouvés
// class ExistingService {
//   final int id;
//   final String nom;
//   final String description;
//   final List<double> prixPopulaires;
//   final List<int> dureesPopulaires;
//   final int nbSalonsUtilisant;
//
//   ExistingService({
//     required this.id,
//     required this.nom,
//     required this.description,
//     required this.prixPopulaires,
//     required this.dureesPopulaires,
//     required this.nbSalonsUtilisant,
//   });
//
//   factory ExistingService.fromJson(Map<String, dynamic> json) {
//     return ExistingService(
//       id: json['idTblService'] ?? 0,
//       nom: json['intitule_service'] ?? '',
//       description: json['description'] ?? '',
//       prixPopulaires: (json['prix_populaires'] as List<dynamic>?)
//           ?.map((e) => (e as num).toDouble())
//           .toList() ?? [],
//       dureesPopulaires: (json['durees_populaires'] as List<dynamic>?)
//           ?.map((e) => (e as num).toInt())
//           .toList() ?? [],
//       nbSalonsUtilisant: json['nb_salons_utilisant'] ?? 0,
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // import '../gallery/add_gallery_page.dart';
// // import 'select_services_page.dart';
// //
// // class CreateServicesPage extends StatefulWidget {
// //   final CurrentUser currentUser;
// //
// //   const CreateServicesPage({super.key, required this.currentUser});
// //
// //   @override
// //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // }
// //
// // class _CreateServicesPageState extends State<CreateServicesPage> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _nomController = TextEditingController();
// //   final _descriptionController = TextEditingController();
// //   final _prixController = TextEditingController();
// //   final _dureeController = TextEditingController();
// //
// //   bool isSubmitting = false;
// //   bool isSearching = false;
// //   List<ExistingService> similarServices = [];
// //   ExistingService? suggestedService;
// //   bool showSuggestions = false;
// //
// //   @override
// //   void dispose() {
// //     _nomController.dispose();
// //     _descriptionController.dispose();
// //     _prixController.dispose();
// //     _dureeController.dispose();
// //     super.dispose();
// //   }
// //
// //   // Recherche de services similaires pendant que l'utilisateur tape
// //   void _onServiceNameChanged(String value) {
// //     if (value.length >= 2) {
// //       _searchSimilarServices(value);
// //     } else {
// //       setState(() {
// //         similarServices.clear();
// //         showSuggestions = false;
// //         suggestedService = null;
// //       });
// //     }
// //   }
// //
// //   Future<void> _searchSimilarServices(String searchTerm) async {
// //     if (isSearching) return;
// //
// //     setState(() => isSearching = true);
// //
// //     try {
// //       final response = await http.get(
// //         Uri.parse('https://www.hairbnb.site/api/services/search/?q=${Uri.encodeComponent(searchTerm)}&limit=5'),
// //         headers: {'Content-Type': 'application/json'},
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         if (data['status'] == 'success') {
// //           final servicesJson = data['services'] as List;
// //
// //           setState(() {
// //             similarServices = servicesJson
// //                 .map((json) => ExistingService.fromJson(json))
// //                 .toList();
// //             showSuggestions = similarServices.isNotEmpty;
// //           });
// //         }
// //       }
// //     } catch (e) {
// //       // Erreur silencieuse pour la recherche en temps réel
// //       print('Erreur recherche: $e');
// //     } finally {
// //       setState(() => isSearching = false);
// //     }
// //   }
// //
// //   Future<void> _createNewService() async {
// //     if (!_formKey.currentState!.validate()) return;
// //
// //     setState(() => isSubmitting = true);
// //
// //     try {
// //       // Récupérer le token Firebase
// //       final user = FirebaseAuth.instance.currentUser;
// //       final firebaseToken = user != null ? await user.getIdToken() : null;
// //
// //       Map<String, String> headers = {'Content-Type': 'application/json'};
// //       if (firebaseToken != null) {
// //         headers['Authorization'] = 'Bearer $firebaseToken';
// //       }
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// //         headers: headers,
// //         body: json.encode({
// //           'userId': int.parse(widget.currentUser.idTblUser.toString()),
// //           'intitule_service': _nomController.text.trim(),
// //           'description': _descriptionController.text.trim(),
// //           'prix': double.parse(_prixController.text),
// //           'temps_minutes': int.parse(_dureeController.text),
// //         }),
// //       );
// //
// //       final responseData = json.decode(response.body);
// //
// //       if (response.statusCode == 201) {
// //         // ✅ Afficher le dialogue de choix au lieu de rediriger automatiquement
// //         _afficherDialogueSucces();
// //
// //       } else if (response.statusCode == 409) {
// //         // Conflit - service similaire existe
// //         _showConflictDialog(responseData);
// //
// //       } else {
// //         _showError(responseData['message'] ?? 'Erreur lors de la création du service');
// //       }
// //
// //     } catch (e) {
// //       _showError('Erreur lors de la création du service: $e');
// //     } finally {
// //       setState(() => isSubmitting = false);
// //     }
// //   }
// //
// //   /// ✅ NOUVEAU DIALOGUE DE CHOIX APRÈS CRÉATION RÉUSSIE
// //   void _afficherDialogueSucces() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(20),
// //           ),
// //           title: Row(
// //             children: [
// //               Container(
// //                 padding: const EdgeInsets.all(8),
// //                 decoration: BoxDecoration(
// //                   color: Colors.green.shade100,
// //                   shape: BoxShape.circle,
// //                 ),
// //                 child: Icon(
// //                   Icons.check_circle,
// //                   color: Colors.green.shade600,
// //                   size: 24,
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               const Expanded(
// //                 child: Text(
// //                   "Service créé !",
// //                   style: TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           content: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 "Le service '${_nomController.text}' a été créé et ajouté à votre salon avec succès.",
// //                 style: const TextStyle(fontSize: 16),
// //               ),
// //               const SizedBox(height: 16),
// //               const Text(
// //                 "Que souhaitez-vous faire maintenant ?",
// //                 style: TextStyle(
// //                   fontSize: 14,
// //                   fontWeight: FontWeight.w500,
// //                   color: Colors.grey,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           actions: [
// //             // ✅ Bouton pour créer un autre service
// //             TextButton.icon(
// //               onPressed: () {
// //                 Navigator.of(context).pop(); // Fermer le dialogue
// //
// //                 // Réinitialiser les champs pour permettre de créer un nouveau service
// //                 setState(() {
// //                   _nomController.clear();
// //                   _descriptionController.clear();
// //                   _prixController.clear();
// //                   _dureeController.clear();
// //                   similarServices.clear();
// //                   showSuggestions = false;
// //                 });
// //
// //                 // Afficher un message pour indiquer qu'on peut continuer
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(
// //                     content: Text("Vous pouvez maintenant créer un autre service"),
// //                     backgroundColor: Colors.blue,
// //                     duration: Duration(seconds: 2),
// //                   ),
// //                 );
// //               },
// //               icon: const Icon(Icons.add_circle_outline),
// //               label: const Text("Créer un autre service"),
// //             ),
// //
// //             // ✅ Bouton pour passer à la galerie
// //             ElevatedButton.icon(
// //               onPressed: () {
// //                 Navigator.of(context).pop(); // Fermer le dialogue
// //
// //                 // Rediriger vers la galerie
// //                 Navigator.pushReplacement(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (context) => const AddGalleryPage(),
// //                   ),
// //                 );
// //               },
// //               icon: const Icon(Icons.photo_library),
// //               label: const Text("Passer à la galerie"),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: const Color(0xFF7B61FF),
// //                 foregroundColor: Colors.white,
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   void _showConflictDialog(Map<String, dynamic> responseData) {
// //     final existingService = ExistingService.fromJson(responseData['existing_service']);
// //
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Service similaire trouvé'),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(responseData['message'] ?? 'Un service similaire existe déjà'),
// //             const SizedBox(height: 16),
// //             Container(
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: Colors.blue.shade50,
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(color: Colors.blue.shade200),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     existingService.nom,
// //                     style: const TextStyle(fontWeight: FontWeight.bold),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(
// //                     existingService.description,
// //                     style: const TextStyle(fontSize: 14, color: Colors.grey),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Text(
// //                     'Utilisé par ${existingService.nbSalonsUtilisant} salon(s)',
// //                     style: const TextStyle(fontSize: 12, color: Colors.grey),
// //                   ),
// //                   if (existingService.prixPopulaires.isNotEmpty)
// //                     Text(
// //                       'Prix fréquents: ${existingService.prixPopulaires.join(', ')}€',
// //                       style: const TextStyle(fontSize: 12, color: Colors.grey),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.of(context).pop(),
// //             child: const Text('Créer quand même'),
// //           ),
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.of(context).pop();
// //               _useExistingService(existingService);
// //             },
// //             child: const Text('Utiliser ce service'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _useExistingService(ExistingService service) {
// //     // Rediriger vers SelectServicesPage avec ce service pré-sélectionné
// //     Navigator.of(context).pushReplacement(
// //       MaterialPageRoute(
// //         builder: (context) => SelectServicesPage(
// //           currentUser: widget.currentUser,
// //         ),
// //       ),
// //     );
// //
// //     // Ou vous pouvez directement l'ajouter au salon ici
// //     _addExistingServiceToSalon(service);
// //   }
// //
// //   Future<void> _addExistingServiceToSalon(ExistingService service) async {
// //     setState(() => isSubmitting = true);
// //
// //     try {
// //       final user = FirebaseAuth.instance.currentUser;
// //       final firebaseToken = user != null ? await user.getIdToken() : null;
// //
// //       Map<String, String> headers = {'Content-Type': 'application/json'};
// //       if (firebaseToken != null) {
// //         headers['Authorization'] = 'Bearer $firebaseToken';
// //       }
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// //         headers: headers,
// //         body: json.encode({
// //           'userId': int.parse(widget.currentUser.idTblUser.toString()),
// //           'service_id': service.id,
// //           'prix': double.parse(_prixController.text),
// //           'temps_minutes': int.parse(_dureeController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         _showSuccess("Service existant ajouté à votre salon !");
// //         Navigator.of(context).pushReplacement(
// //           MaterialPageRoute(
// //             builder: (context) => const AddGalleryPage(),
// //           ),
// //         );
// //       } else {
// //         final errorData = json.decode(response.body);
// //         _showError(errorData['message'] ?? 'Erreur lors de l\'ajout du service');
// //       }
// //
// //     } catch (e) {
// //       _showError('Erreur: $e');
// //     } finally {
// //       setState(() => isSubmitting = false);
// //     }
// //   }
// //
// //   void _showSuccess(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.green,
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.red,
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Créer un nouveau service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back),
// //           onPressed: () {
// //             Navigator.of(context).pushReplacement(
// //               MaterialPageRoute(
// //                 builder: (context) => SelectServicesPage(
// //                   currentUser: widget.currentUser,
// //                 ),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Center(
// //           child: ConstrainedBox(
// //             constraints: const BoxConstraints(maxWidth: 600),
// //             child: Form(
// //               key: _formKey,
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   const Text(
// //                     "Créer un nouveau service",
// //                     style: TextStyle(
// //                       fontSize: 26,
// //                       fontWeight: FontWeight.w700,
// //                       color: Color(0xFF333333),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   const Text(
// //                     "Ce service sera disponible pour tous les salons sur Hairbnb",
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       color: Color(0xFF666666),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 30),
// //
// //                   // Champ nom du service
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const Text(
// //                         "Nom du service *",
// //                         style: TextStyle(
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w600,
// //                           color: Color(0xFF333333),
// //                         ),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       TextFormField(
// //                         controller: _nomController,
// //                         decoration: InputDecoration(
// //                           hintText: "Ex: Coupe femme, Balayage, Brushing...",
// //                           border: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: BorderSide(color: Colors.grey.shade300),
// //                           ),
// //                           focusedBorder: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                           ),
// //                           suffixIcon: isSearching
// //                               ? const SizedBox(
// //                             width: 20,
// //                             height: 20,
// //                             child: CircularProgressIndicator(strokeWidth: 2),
// //                           )
// //                               : null,
// //                         ),
// //                         validator: (value) {
// //                           if (value == null || value.trim().isEmpty) {
// //                             return 'Le nom du service est obligatoire';
// //                           }
// //                           if (value.trim().length < 2) {
// //                             return 'Le nom doit contenir au moins 2 caractères';
// //                           }
// //                           return null;
// //                         },
// //                         onChanged: _onServiceNameChanged,
// //                       ),
// //
// //                       // Suggestions de services similaires
// //                       if (showSuggestions && similarServices.isNotEmpty) ...[
// //                         const SizedBox(height: 12),
// //                         Container(
// //                           padding: const EdgeInsets.all(16),
// //                           decoration: BoxDecoration(
// //                             color: Colors.orange.shade50,
// //                             borderRadius: BorderRadius.circular(12),
// //                             border: Border.all(color: Colors.orange.shade200),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Row(
// //                                 children: [
// //                                   Icon(Icons.warning_amber,
// //                                       color: Colors.orange.shade600,
// //                                       size: 20),
// //                                   const SizedBox(width: 8),
// //                                   const Text(
// //                                     "Services similaires trouvés",
// //                                     style: TextStyle(
// //                                       fontWeight: FontWeight.bold,
// //                                       color: Colors.orange,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 12),
// //                               ...similarServices.take(3).map((service) =>
// //                                   _buildSuggestionCard(service)
// //                               ),
// //                               const SizedBox(height: 8),
// //                               TextButton(
// //                                 onPressed: () {
// //                                   setState(() {
// //                                     showSuggestions = false;
// //                                   });
// //                                 },
// //                                 child: const Text("Créer un nouveau service quand même"),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ],
// //                     ],
// //                   ),
// //
// //                   const SizedBox(height: 24),
// //
// //                   // Champ description
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const Text(
// //                         "Description",
// //                         style: TextStyle(
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w600,
// //                           color: Color(0xFF333333),
// //                         ),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       TextFormField(
// //                         controller: _descriptionController,
// //                         maxLines: 3,
// //                         decoration: InputDecoration(
// //                           hintText: "Décrivez le service en détail...",
// //                           border: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: BorderSide(color: Colors.grey.shade300),
// //                           ),
// //                           focusedBorder: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                           ),
// //                         ),
// //                         validator: (value) {
// //                           if (value == null || value.trim().isEmpty) {
// //                             return 'La description est obligatoire';
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                     ],
// //                   ),
// //
// //                   const SizedBox(height: 24),
// //
// //                   // Prix et durée
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             const Text(
// //                               "Prix (€) *",
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Color(0xFF333333),
// //                               ),
// //                             ),
// //                             const SizedBox(height: 8),
// //                             TextFormField(
// //                               controller: _prixController,
// //                               keyboardType: const TextInputType.numberWithOptions(decimal: true),
// //                               decoration: InputDecoration(
// //                                 hintText: "25.00",
// //                                 prefixIcon: const Icon(Icons.euro),
// //                                 border: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: BorderSide(color: Colors.grey.shade300),
// //                                 ),
// //                                 focusedBorder: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                                 ),
// //                               ),
// //                               validator: (value) {
// //                                 if (value == null || value.isEmpty) {
// //                                   return 'Prix requis';
// //                                 }
// //                                 final prix = double.tryParse(value);
// //                                 if (prix == null || prix <= 0) {
// //                                   return 'Prix invalide';
// //                                 }
// //                                 return null;
// //                               },
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                       const SizedBox(width: 16),
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             const Text(
// //                               "Durée (min) *",
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Color(0xFF333333),
// //                               ),
// //                             ),
// //                             const SizedBox(height: 8),
// //                             TextFormField(
// //                               controller: _dureeController,
// //                               keyboardType: TextInputType.number,
// //                               decoration: InputDecoration(
// //                                 hintText: "30",
// //                                 prefixIcon: const Icon(Icons.timer),
// //                                 border: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: BorderSide(color: Colors.grey.shade300),
// //                                 ),
// //                                 focusedBorder: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                                 ),
// //                               ),
// //                               validator: (value) {
// //                                 if (value == null || value.isEmpty) {
// //                                   return 'Durée requise';
// //                                 }
// //                                 final duree = int.tryParse(value);
// //                                 if (duree == null || duree <= 0) {
// //                                   return 'Durée invalide';
// //                                 }
// //                                 return null;
// //                               },
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //
// //                   const SizedBox(height: 30),
// //
// //                   // Info box
// //                   Container(
// //                     padding: const EdgeInsets.all(16),
// //                     decoration: BoxDecoration(
// //                       color: Colors.blue.shade50,
// //                       borderRadius: BorderRadius.circular(12),
// //                       border: Border.all(color: Colors.blue.shade200),
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         Icon(Icons.info_outline, color: Colors.blue.shade600),
// //                         const SizedBox(width: 12),
// //                         const Expanded(
// //                           child: Text(
// //                             "Ce service sera créé globalement et pourra être utilisé par d'autres salons avec leurs propres prix et durées.",
// //                             style: TextStyle(fontSize: 14, color: Colors.blue),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //
// //                   const SizedBox(height: 30),
// //
// //                   // Boutons d'action
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: OutlinedButton(
// //                           onPressed: isSubmitting ? null : () {
// //                             Navigator.of(context).pushReplacement(
// //                               MaterialPageRoute(
// //                                 builder: (context) => SelectServicesPage(
// //                                   currentUser: widget.currentUser,
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                           style: OutlinedButton.styleFrom(
// //                             padding: const EdgeInsets.symmetric(vertical: 16),
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                             ),
// //                             side: const BorderSide(color: Color(0xFF7B61FF)),
// //                           ),
// //                           child: const Text(
// //                             "Retour",
// //                             style: TextStyle(color: Color(0xFF7B61FF)),
// //                           ),
// //                         ),
// //                       ),
// //                       const SizedBox(width: 16),
// //                       Expanded(
// //                         flex: 2,
// //                         child: ElevatedButton.icon(
// //                           onPressed: isSubmitting ? null : _createNewService,
// //                           icon: isSubmitting
// //                               ? const SizedBox(
// //                             width: 16,
// //                             height: 16,
// //                             child: CircularProgressIndicator(
// //                               strokeWidth: 2,
// //                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                             ),
// //                           )
// //                               : const Icon(Icons.add),
// //                           label: Text(isSubmitting
// //                               ? "Création en cours..."
// //                               : "Créer le service"),
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: const Color(0xFF7B61FF),
// //                             foregroundColor: Colors.white,
// //                             padding: const EdgeInsets.symmetric(vertical: 16),
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSuggestionCard(ExistingService service) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: Colors.grey.shade300),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   service.nom,
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 14,
// //                   ),
// //                 ),
// //                 Text(
// //                   service.description,
// //                   style: const TextStyle(
// //                     fontSize: 12,
// //                     color: Colors.grey,
// //                   ),
// //                   maxLines: 2,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 Text(
// //                   "Utilisé par ${service.nbSalonsUtilisant} salon(s)",
// //                   style: const TextStyle(
// //                     fontSize: 11,
// //                     color: Colors.grey,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           ElevatedButton(
// //             onPressed: () => _useExistingService(service),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: Colors.orange,
// //               foregroundColor: Colors.white,
// //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(6),
// //               ),
// //             ),
// //             child: const Text("Utiliser", style: TextStyle(fontSize: 12)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // Modèle pour les services existants trouvés
// // class ExistingService {
// //   final int id;
// //   final String nom;
// //   final String description;
// //   final List<double> prixPopulaires;
// //   final List<int> dureesPopulaires;
// //   final int nbSalonsUtilisant;
// //
// //   ExistingService({
// //     required this.id,
// //     required this.nom,
// //     required this.description,
// //     required this.prixPopulaires,
// //     required this.dureesPopulaires,
// //     required this.nbSalonsUtilisant,
// //   });
// //
// //   factory ExistingService.fromJson(Map<String, dynamic> json) {
// //     return ExistingService(
// //       id: json['idTblService'] ?? 0,
// //       nom: json['intitule_service'] ?? '',
// //       description: json['description'] ?? '',
// //       prixPopulaires: (json['prix_populaires'] as List<dynamic>?)
// //           ?.map((e) => (e as num).toDouble())
// //           .toList() ?? [],
// //       dureesPopulaires: (json['durees_populaires'] as List<dynamic>?)
// //           ?.map((e) => (e as num).toInt())
// //           .toList() ?? [],
// //       nbSalonsUtilisant: json['nb_salons_utilisant'] ?? 0,
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
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // import '../gallery/add_gallery_page.dart';
// // import 'select_services_page.dart';
// //
// // class CreateServicesPage extends StatefulWidget {
// //   final CurrentUser currentUser;
// //
// //   const CreateServicesPage({super.key, required this.currentUser});
// //
// //   @override
// //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // }
// //
// // class _CreateServicesPageState extends State<CreateServicesPage> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _nomController = TextEditingController();
// //   final _descriptionController = TextEditingController();
// //   final _prixController = TextEditingController();
// //   final _dureeController = TextEditingController();
// //
// //   bool isSubmitting = false;
// //   bool isSearching = false;
// //   List<ExistingService> similarServices = [];
// //   ExistingService? suggestedService;
// //   bool showSuggestions = false;
// //
// //   @override
// //   void dispose() {
// //     _nomController.dispose();
// //     _descriptionController.dispose();
// //     _prixController.dispose();
// //     _dureeController.dispose();
// //     super.dispose();
// //   }
// //
// //   // Recherche de services similaires pendant que l'utilisateur tape
// //   void _onServiceNameChanged(String value) {
// //     if (value.length >= 2) {
// //       _searchSimilarServices(value);
// //     } else {
// //       setState(() {
// //         similarServices.clear();
// //         showSuggestions = false;
// //         suggestedService = null;
// //       });
// //     }
// //   }
// //
// //   Future<void> _searchSimilarServices(String searchTerm) async {
// //     if (isSearching) return;
// //
// //     setState(() => isSearching = true);
// //
// //     try {
// //       final response = await http.get(
// //         Uri.parse('https://www.hairbnb.site/api/services/search/?q=${Uri.encodeComponent(searchTerm)}&limit=5'),
// //         headers: {'Content-Type': 'application/json'},
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         if (data['status'] == 'success') {
// //           final servicesJson = data['services'] as List;
// //
// //           setState(() {
// //             similarServices = servicesJson
// //                 .map((json) => ExistingService.fromJson(json))
// //                 .toList();
// //             showSuggestions = similarServices.isNotEmpty;
// //           });
// //         }
// //       }
// //     } catch (e) {
// //       // Erreur silencieuse pour la recherche en temps réel
// //       print('Erreur recherche: $e');
// //     } finally {
// //       setState(() => isSearching = false);
// //     }
// //   }
// //
// //   Future<void> _createNewService() async {
// //     if (!_formKey.currentState!.validate()) return;
// //
// //     setState(() => isSubmitting = true);
// //
// //     try {
// //       // Récupérer le token Firebase
// //       final user = FirebaseAuth.instance.currentUser;
// //       final firebaseToken = user != null ? await user.getIdToken() : null;
// //
// //       Map<String, String> headers = {'Content-Type': 'application/json'};
// //       if (firebaseToken != null) {
// //         headers['Authorization'] = 'Bearer $firebaseToken';
// //       }
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// //         headers: headers,
// //         body: json.encode({
// //           'userId': int.parse(widget.currentUser.idTblUser.toString()),
// //           'intitule_service': _nomController.text.trim(),
// //           'description': _descriptionController.text.trim(),
// //           'prix': double.parse(_prixController.text),
// //           'temps_minutes': int.parse(_dureeController.text),
// //         }),
// //       );
// //
// //       final responseData = json.decode(response.body);
// //
// //       if (response.statusCode == 201) {
// //         // Succès !
// //         _showSuccess("Nouveau service créé et ajouté à votre salon !");
// //
// //         // Retour à la page de sélection ou redirection vers galerie
// //         Navigator.of(context).pushReplacement(
// //           MaterialPageRoute(
// //             builder: (context) => const AddGalleryPage(),
// //           ),
// //         );
// //
// //       } else if (response.statusCode == 409) {
// //         // Conflit - service similaire existe
// //         _showConflictDialog(responseData);
// //
// //       } else {
// //         _showError(responseData['message'] ?? 'Erreur lors de la création du service');
// //       }
// //
// //     } catch (e) {
// //       _showError('Erreur lors de la création du service: $e');
// //     } finally {
// //       setState(() => isSubmitting = false);
// //     }
// //   }
// //
// //   void _showConflictDialog(Map<String, dynamic> responseData) {
// //     final existingService = ExistingService.fromJson(responseData['existing_service']);
// //
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Service similaire trouvé'),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(responseData['message'] ?? 'Un service similaire existe déjà'),
// //             const SizedBox(height: 16),
// //             Container(
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: Colors.blue.shade50,
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(color: Colors.blue.shade200),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     existingService.nom,
// //                     style: const TextStyle(fontWeight: FontWeight.bold),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(
// //                     existingService.description,
// //                     style: const TextStyle(fontSize: 14, color: Colors.grey),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Text(
// //                     'Utilisé par ${existingService.nbSalonsUtilisant} salon(s)',
// //                     style: const TextStyle(fontSize: 12, color: Colors.grey),
// //                   ),
// //                   if (existingService.prixPopulaires.isNotEmpty)
// //                     Text(
// //                       'Prix fréquents: ${existingService.prixPopulaires.join(', ')}€',
// //                       style: const TextStyle(fontSize: 12, color: Colors.grey),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.of(context).pop(),
// //             child: const Text('Créer quand même'),
// //           ),
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.of(context).pop();
// //               _useExistingService(existingService);
// //             },
// //             child: const Text('Utiliser ce service'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _useExistingService(ExistingService service) {
// //     // Rediriger vers SelectServicesPage avec ce service pré-sélectionné
// //     Navigator.of(context).pushReplacement(
// //       MaterialPageRoute(
// //         builder: (context) => SelectServicesPage(
// //           currentUser: widget.currentUser,
// //         ),
// //       ),
// //     );
// //
// //     // Ou vous pouvez directement l'ajouter au salon ici
// //     _addExistingServiceToSalon(service);
// //   }
// //
// //   Future<void> _addExistingServiceToSalon(ExistingService service) async {
// //     setState(() => isSubmitting = true);
// //
// //     try {
// //       final user = FirebaseAuth.instance.currentUser;
// //       final firebaseToken = user != null ? await user.getIdToken() : null;
// //
// //       Map<String, String> headers = {'Content-Type': 'application/json'};
// //       if (firebaseToken != null) {
// //         headers['Authorization'] = 'Bearer $firebaseToken';
// //       }
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// //         headers: headers,
// //         body: json.encode({
// //           'userId': int.parse(widget.currentUser.idTblUser.toString()),
// //           'service_id': service.id,
// //           'prix': double.parse(_prixController.text),
// //           'temps_minutes': int.parse(_dureeController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         _showSuccess("Service existant ajouté à votre salon !");
// //         Navigator.of(context).pushReplacement(
// //           MaterialPageRoute(
// //             builder: (context) => const AddGalleryPage(),
// //           ),
// //         );
// //       } else {
// //         final errorData = json.decode(response.body);
// //         _showError(errorData['message'] ?? 'Erreur lors de l\'ajout du service');
// //       }
// //
// //     } catch (e) {
// //       _showError('Erreur: $e');
// //     } finally {
// //       setState(() => isSubmitting = false);
// //     }
// //   }
// //
// //   void _showSuccess(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.green,
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.red,
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F9),
// //       appBar: AppBar(
// //         title: const Text("Créer un nouveau service"),
// //         centerTitle: true,
// //         backgroundColor: const Color(0xFF7B61FF),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back),
// //           onPressed: () {
// //             Navigator.of(context).pushReplacement(
// //               MaterialPageRoute(
// //                 builder: (context) => SelectServicesPage(
// //                   currentUser: widget.currentUser,
// //                 ),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Center(
// //           child: ConstrainedBox(
// //             constraints: const BoxConstraints(maxWidth: 600),
// //             child: Form(
// //               key: _formKey,
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   const Text(
// //                     "Créer un nouveau service",
// //                     style: TextStyle(
// //                       fontSize: 26,
// //                       fontWeight: FontWeight.w700,
// //                       color: Color(0xFF333333),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   const Text(
// //                     "Ce service sera disponible pour tous les salons sur Hairbnb",
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       color: Color(0xFF666666),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 30),
// //
// //                   // Champ nom du service
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const Text(
// //                         "Nom du service *",
// //                         style: TextStyle(
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w600,
// //                           color: Color(0xFF333333),
// //                         ),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       TextFormField(
// //                         controller: _nomController,
// //                         decoration: InputDecoration(
// //                           hintText: "Ex: Coupe femme, Balayage, Brushing...",
// //                           border: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: BorderSide(color: Colors.grey.shade300),
// //                           ),
// //                           focusedBorder: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                           ),
// //                           suffixIcon: isSearching
// //                               ? const SizedBox(
// //                             width: 20,
// //                             height: 20,
// //                             child: CircularProgressIndicator(strokeWidth: 2),
// //                           )
// //                               : null,
// //                         ),
// //                         validator: (value) {
// //                           if (value == null || value.trim().isEmpty) {
// //                             return 'Le nom du service est obligatoire';
// //                           }
// //                           if (value.trim().length < 2) {
// //                             return 'Le nom doit contenir au moins 2 caractères';
// //                           }
// //                           return null;
// //                         },
// //                         onChanged: _onServiceNameChanged,
// //                       ),
// //
// //                       // Suggestions de services similaires
// //                       if (showSuggestions && similarServices.isNotEmpty) ...[
// //                         const SizedBox(height: 12),
// //                         Container(
// //                           padding: const EdgeInsets.all(16),
// //                           decoration: BoxDecoration(
// //                             color: Colors.orange.shade50,
// //                             borderRadius: BorderRadius.circular(12),
// //                             border: Border.all(color: Colors.orange.shade200),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Row(
// //                                 children: [
// //                                   Icon(Icons.warning_amber,
// //                                       color: Colors.orange.shade600,
// //                                       size: 20),
// //                                   const SizedBox(width: 8),
// //                                   const Text(
// //                                     "Services similaires trouvés",
// //                                     style: TextStyle(
// //                                       fontWeight: FontWeight.bold,
// //                                       color: Colors.orange,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 12),
// //                               ...similarServices.take(3).map((service) =>
// //                                   _buildSuggestionCard(service)
// //                               ),
// //                               const SizedBox(height: 8),
// //                               TextButton(
// //                                 onPressed: () {
// //                                   setState(() {
// //                                     showSuggestions = false;
// //                                   });
// //                                 },
// //                                 child: const Text("Créer un nouveau service quand même"),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ],
// //                     ],
// //                   ),
// //
// //                   const SizedBox(height: 24),
// //
// //                   // Champ description
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const Text(
// //                         "Description",
// //                         style: TextStyle(
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w600,
// //                           color: Color(0xFF333333),
// //                         ),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       TextFormField(
// //                         controller: _descriptionController,
// //                         maxLines: 3,
// //                         decoration: InputDecoration(
// //                           hintText: "Décrivez le service en détail...",
// //                           border: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: BorderSide(color: Colors.grey.shade300),
// //                           ),
// //                           focusedBorder: OutlineInputBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                             borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                           ),
// //                         ),
// //                         validator: (value) {
// //                           if (value == null || value.trim().isEmpty) {
// //                             return 'La description est obligatoire';
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                     ],
// //                   ),
// //
// //                   const SizedBox(height: 24),
// //
// //                   // Prix et durée
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             const Text(
// //                               "Prix (€) *",
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Color(0xFF333333),
// //                               ),
// //                             ),
// //                             const SizedBox(height: 8),
// //                             TextFormField(
// //                               controller: _prixController,
// //                               keyboardType: const TextInputType.numberWithOptions(decimal: true),
// //                               decoration: InputDecoration(
// //                                 hintText: "25.00",
// //                                 prefixIcon: const Icon(Icons.euro),
// //                                 border: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: BorderSide(color: Colors.grey.shade300),
// //                                 ),
// //                                 focusedBorder: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                                 ),
// //                               ),
// //                               validator: (value) {
// //                                 if (value == null || value.isEmpty) {
// //                                   return 'Prix requis';
// //                                 }
// //                                 final prix = double.tryParse(value);
// //                                 if (prix == null || prix <= 0) {
// //                                   return 'Prix invalide';
// //                                 }
// //                                 return null;
// //                               },
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                       const SizedBox(width: 16),
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             const Text(
// //                               "Durée (min) *",
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Color(0xFF333333),
// //                               ),
// //                             ),
// //                             const SizedBox(height: 8),
// //                             TextFormField(
// //                               controller: _dureeController,
// //                               keyboardType: TextInputType.number,
// //                               decoration: InputDecoration(
// //                                 hintText: "30",
// //                                 prefixIcon: const Icon(Icons.timer),
// //                                 border: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: BorderSide(color: Colors.grey.shade300),
// //                                 ),
// //                                 focusedBorder: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
// //                                 ),
// //                               ),
// //                               validator: (value) {
// //                                 if (value == null || value.isEmpty) {
// //                                   return 'Durée requise';
// //                                 }
// //                                 final duree = int.tryParse(value);
// //                                 if (duree == null || duree <= 0) {
// //                                   return 'Durée invalide';
// //                                 }
// //                                 return null;
// //                               },
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //
// //                   const SizedBox(height: 30),
// //
// //                   // Info box
// //                   Container(
// //                     padding: const EdgeInsets.all(16),
// //                     decoration: BoxDecoration(
// //                       color: Colors.blue.shade50,
// //                       borderRadius: BorderRadius.circular(12),
// //                       border: Border.all(color: Colors.blue.shade200),
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         Icon(Icons.info_outline, color: Colors.blue.shade600),
// //                         const SizedBox(width: 12),
// //                         const Expanded(
// //                           child: Text(
// //                             "Ce service sera créé globalement et pourra être utilisé par d'autres salons avec leurs propres prix et durées.",
// //                             style: TextStyle(fontSize: 14, color: Colors.blue),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //
// //                   const SizedBox(height: 30),
// //
// //                   // Boutons d'action
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: OutlinedButton(
// //                           onPressed: isSubmitting ? null : () {
// //                             Navigator.of(context).pushReplacement(
// //                               MaterialPageRoute(
// //                                 builder: (context) => SelectServicesPage(
// //                                   currentUser: widget.currentUser,
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                           style: OutlinedButton.styleFrom(
// //                             padding: const EdgeInsets.symmetric(vertical: 16),
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                             ),
// //                             side: const BorderSide(color: Color(0xFF7B61FF)),
// //                           ),
// //                           child: const Text(
// //                             "Retour",
// //                             style: TextStyle(color: Color(0xFF7B61FF)),
// //                           ),
// //                         ),
// //                       ),
// //                       const SizedBox(width: 16),
// //                       Expanded(
// //                         flex: 2,
// //                         child: ElevatedButton.icon(
// //                           onPressed: isSubmitting ? null : _createNewService,
// //                           icon: isSubmitting
// //                               ? const SizedBox(
// //                             width: 16,
// //                             height: 16,
// //                             child: CircularProgressIndicator(
// //                               strokeWidth: 2,
// //                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                             ),
// //                           )
// //                               : const Icon(Icons.add),
// //                           label: Text(isSubmitting
// //                               ? "Création en cours..."
// //                               : "Créer le service"),
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: const Color(0xFF7B61FF),
// //                             foregroundColor: Colors.white,
// //                             padding: const EdgeInsets.symmetric(vertical: 16),
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSuggestionCard(ExistingService service) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: Colors.grey.shade300),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   service.nom,
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 14,
// //                   ),
// //                 ),
// //                 Text(
// //                   service.description,
// //                   style: const TextStyle(
// //                     fontSize: 12,
// //                     color: Colors.grey,
// //                   ),
// //                   maxLines: 2,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 Text(
// //                   "Utilisé par ${service.nbSalonsUtilisant} salon(s)",
// //                   style: const TextStyle(
// //                     fontSize: 11,
// //                     color: Colors.grey,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           ElevatedButton(
// //             onPressed: () => _useExistingService(service),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: Colors.orange,
// //               foregroundColor: Colors.white,
// //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(6),
// //               ),
// //             ),
// //             child: const Text("Utiliser", style: TextStyle(fontSize: 12)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // Modèle pour les services existants trouvés
// // class ExistingService {
// //   final int id;
// //   final String nom;
// //   final String description;
// //   final List<double> prixPopulaires;
// //   final List<int> dureesPopulaires;
// //   final int nbSalonsUtilisant;
// //
// //   ExistingService({
// //     required this.id,
// //     required this.nom,
// //     required this.description,
// //     required this.prixPopulaires,
// //     required this.dureesPopulaires,
// //     required this.nbSalonsUtilisant,
// //   });
// //
// //   factory ExistingService.fromJson(Map<String, dynamic> json) {
// //     return ExistingService(
// //       id: json['idTblService'] ?? 0,
// //       nom: json['intitule_service'] ?? '',
// //       description: json['description'] ?? '',
// //       prixPopulaires: (json['prix_populaires'] as List<dynamic>?)
// //           ?.map((e) => (e as num).toDouble())
// //           .toList() ?? [],
// //       dureesPopulaires: (json['durees_populaires'] as List<dynamic>?)
// //           ?.map((e) => (e as num).toInt())
// //           .toList() ?? [],
// //       nbSalonsUtilisant: json['nb_salons_utilisant'] ?? 0,
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import 'add_service_page.dart'; // Nouvelle page pour ajouter un service
// // //
// // // class ServicesListPage extends StatefulWidget {
// // //   final String coiffeuseId;
// // //
// // //   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
// // //
// // //   @override
// // //   State<ServicesListPage> createState() => _ServicesListPageState();
// // // }
// // //
// // // class _ServicesListPageState extends State<ServicesListPage> {
// // //   List<dynamic> services = [];
// // //   bool isLoading = false;
// // //   bool hasError = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     fetchServices();
// // //   }
// // //
// // //   Future<void> fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       final response = await http.get(
// // //         Uri.parse('https://www.hairbnb.site/api/coiffeuse_services/${widget.coiffeuseId}/'),
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         setState(() {
// // //           services = json.decode(response.body);
// // //         });
// // //       } else {
// // //         setState(() {
// // //           hasError = true;
// // //         });
// // //         _showError("Erreur lors du chargement des services : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         hasError = true;
// // //       });
// // //       _showError("Erreur de connexion au serveur.");
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   Future<void> _refreshData() async {
// // //     await fetchServices();
// // //   }
// // //
// // //   void _showError(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(message, style: const TextStyle(color: Colors.white)),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Liste des services"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : hasError
// // //           ? Center(
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             const Text(
// // //               "Erreur de chargement",
// // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             ElevatedButton(
// // //               onPressed: fetchServices,
// // //               child: const Text("Réessayer"),
// // //             ),
// // //           ],
// // //         ),
// // //       )
// // //           : services.isEmpty
// // //           ? const Center(
// // //         child: Text(
// // //           "Aucun service trouvé.",
// // //           style: TextStyle(fontSize: 16),
// // //         ),
// // //       )
// // //           : RefreshIndicator(
// // //         onRefresh: _refreshData,
// // //         child: ListView.builder(
// // //           padding: const EdgeInsets.all(8),
// // //           itemCount: services.length,
// // //           itemBuilder: (context, index) {
// // //             final service = services[index];
// // //             return Card(
// // //               elevation: 4,
// // //               margin: const EdgeInsets.symmetric(vertical: 8),
// // //               child: Padding(
// // //                 padding: const EdgeInsets.all(16.0),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Text(
// // //                       service['intitule_service'] ?? "Nom indisponible",
// // //                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //                     ),
// // //                     const SizedBox(height: 8),
// // //                     Row(
// // //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                       children: [
// // //                         Text("Prix : ${service['prix']?.toString() ?? 'Non défini'} €"),
// // //                         Text("Temps : ${service['temps_minutes']?.toString() ?? 'Non défini'} min"),
// // //                       ],
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             );
// // //           },
// // //         ),
// // //       ),
// // //       floatingActionButton: FloatingActionButton(
// // //         onPressed: () async {
// // //           final result = await Navigator.push(
// // //             context,
// // //             MaterialPageRoute(
// // //               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
// // //             ),
// // //           );
// // //
// // //           if (result == true) {
// // //             fetchServices();
// // //           }
// // //         },
// // //         child: const Icon(Icons.add),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // //
// // // class CreateServicesPage extends StatefulWidget {
// // //   const CreateServicesPage({Key? key}) : super(key: key);
// // //
// // //   @override
// // //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // // }
// // //
// // // class _CreateServicesPageState extends State<CreateServicesPage> {
// // //   final TextEditingController durationController = TextEditingController();
// // //   final TextEditingController priceController = TextEditingController();
// // //   final TextEditingController newServiceNameController = TextEditingController();
// // //   final TextEditingController newServiceDescriptionController = TextEditingController();
// // //
// // //   List<dynamic> services = [];
// // //   String? selectedService;
// // //   String? serviceDescription;
// // //   bool isAddingNewService = false;
// // //   bool isLoading = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     try {
// // //       final response = await http.get(Uri.parse('http://192.168.0.248:8000/api/services/'));
// // //
// // //       if (response.statusCode == 200) {
// // //         final fetchedServices = json.decode(response.body);
// // //
// // //         setState(() {
// // //           services = fetchedServices;
// // //           selectedService = null; // Réinitialiser la sélection
// // //         });
// // //
// // //         print("Liste des services reçus : $services");
// // //       } else {
// // //         _showError("Erreur lors du chargement des services : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       _showError("Erreur de connexion au serveur.");
// // //     }
// // //   }
// // //
// // //   void _onServiceSelected(String? serviceId) {
// // //     final service = services.firstWhere(
// // //           (s) => s['idTblService'].toString() == serviceId,
// // //       orElse: () => null,
// // //     );
// // //
// // //     if (service == null) {
// // //       _showError("Service introuvable.");
// // //       return;
// // //     }
// // //
// // //     setState(() {
// // //       selectedService = serviceId;
// // //       serviceDescription = service['description'] ?? "Description non disponible";
// // //       durationController.text = service['temps']?['minutes']?.toString() ?? '';
// // //       priceController.text = service['prix']?['prix']?.toString() ?? '';
// // //       // print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
// // //       // print('l id est :'+ serviceId!);
// // //       // print('l id est :'+ serviceDescription!);
// // //       // print('l id est :'+ durationController.text!);
// // //       // print('l id est :'+ priceController.text!);
// // //       // print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
// // //
// // //     });
// // //   }
// // //
// // //   Future<void> _saveService() async {
// // //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// // //       _showError("Tous les champs sont obligatoires.");
// // //       return;
// // //     }
// // //
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       final requestBody = {
// // //         'salon_id': '1', // Remplacez par l'ID réel du salon
// // //         'service_id': selectedService,
// // //         'duration': int.parse(durationController.text),
// // //         'price': double.parse(priceController.text),
// // //       };
// // //
// // //       final response = await http.post(
// // //         Uri.parse('http://192.168.0.248:8000/api/link_salon_service/'),
// // //         body: json.encode(requestBody),
// // //         headers: {'Content-Type': 'application/json'},
// // //       );
// // //
// // //       if (response.statusCode == 201) {
// // //         _showSuccess("Service associé au salon avec succès !");
// // //       } else {
// // //         _showError("Erreur lors de l'association : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       _showError("Erreur de connexion au serveur.");
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //
// // //   // Future<void> _saveService() async {
// // //   //   if (isAddingNewService) {
// // //   //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// // //   //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
// // //   //       return;
// // //   //     }
// // //   //   } else {
// // //   //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// // //   //       _showError("Tous les champs sont obligatoires.");
// // //   //       return;
// // //   //     }
// // //   //   }
// // //   //
// // //   //   setState(() {
// // //   //     isLoading = true;
// // //   //   });
// // //   //
// // //   //   try {
// // //   //     final requestBody = isAddingNewService
// // //   //         ? {
// // //   //       'name': newServiceNameController.text,
// // //   //       'description': newServiceDescriptionController.text,
// // //   //       'minutes': int.parse(durationController.text),
// // //   //       'price': double.parse(priceController.text),
// // //   //     }
// // //   //         : {
// // //   //       'service_id': selectedService,
// // //   //       'minutes': int.parse(durationController.text),
// // //   //       'price': double.parse(priceController.text),
// // //   //     };
// // //   //
// // //   //     // Choisir la méthode HTTP et l'URL
// // //   //     final url = isAddingNewService
// // //   //         ? Uri.parse('http://192.168.0.248:8000/api/add_or_update_service/')
// // //   //         : Uri.parse('http://192.168.0.248:8000/api/add_or_update_service/$selectedService/');
// // //   //
// // //   //     final response = isAddingNewService
// // //   //         ? await http.post(
// // //   //       url,
// // //   //       body: json.encode(requestBody),
// // //   //       headers: {'Content-Type': 'application/json'},
// // //   //     )
// // //   //         : await http.put(
// // //   //       url,
// // //   //       body: json.encode(requestBody),
// // //   //       headers: {'Content-Type': 'application/json'},
// // //   //     );
// // //   //
// // //   //     if (response.statusCode == 201 || response.statusCode == 200) {
// // //   //       _showSuccess("Service ajouté ou mis à jour avec succès!");
// // //   //       setState(() {
// // //   //         newServiceNameController.clear();
// // //   //         newServiceDescriptionController.clear();
// // //   //         durationController.clear();
// // //   //         priceController.clear();
// // //   //         selectedService = null;
// // //   //         serviceDescription = null;
// // //   //         isAddingNewService = false;
// // //   //       });
// // //   //       await _fetchServices();
// // //   //     } else {
// // //   //       _showError("Erreur lors de l'ajout ou mise à jour : ${response.body}");
// // //   //     }
// // //   //   } catch (e) {
// // //   //     _showError("Erreur de connexion au serveur.");
// // //   //   } finally {
// // //   //     setState(() {
// // //   //       isLoading = false;
// // //   //     });
// // //   //   }
// // //   // }
// // //
// // //
// // //   void _showError(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(
// // //           message,
// // //           style: const TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _showSuccess(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(
// // //           message,
// // //           style: const TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Colors.green,
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildTextField(String label, TextEditingController controller,
// // //       {bool isNumeric = false, int maxLines = 1}) {
// // //     return TextField(
// // //       controller: controller,
// // //       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
// // //       decoration: InputDecoration(
// // //         labelText: label,
// // //         border: const OutlineInputBorder(),
// // //       ),
// // //       maxLines: maxLines,
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Créer des services"),
// // //       ),
// // //       body: SingleChildScrollView(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             const Text(
// // //               "Ajouter un service",
// // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //             ),
// // //             const SizedBox(height: 20),
// // //             if (!isAddingNewService)
// // //               DropdownButtonFormField<String>(
// // //                 decoration: const InputDecoration(
// // //                   labelText: "Sélectionnez un service",
// // //                   border: OutlineInputBorder(),
// // //                 ),
// // //                 value: selectedService,
// // //                 items: [
// // //                   const DropdownMenuItem(
// // //                     value: null,
// // //                     child: Text("Aucun service sélectionné"),
// // //                   ),
// // //                   ...services.map<DropdownMenuItem<String>>((service) {
// // //                     return DropdownMenuItem(
// // //                       value: service['idTblService'].toString(),
// // //                       child: Text(service['intitule_service'] ?? "Nom indisponible"),
// // //                     );
// // //                   }).toList(),
// // //                 ],
// // //                 onChanged: (value) {
// // //                   setState(() {
// // //                     selectedService = value;
// // //                     _onServiceSelected(value);
// // //                   });
// // //                 },
// // //               ),
// // //             const SizedBox(height: 10),
// // //             if (!isAddingNewService && serviceDescription != null)
// // //               Text("Description : $serviceDescription"),
// // //             if (isAddingNewService)
// // //               Column(
// // //                 children: [
// // //                   _buildTextField("Nom du nouveau service", newServiceNameController),
// // //                   const SizedBox(height: 10),
// // //                   _buildTextField("Description du nouveau service", newServiceDescriptionController, maxLines: 3),
// // //                 ],
// // //               ),
// // //             const SizedBox(height: 10),
// // //             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
// // //             const SizedBox(height: 10),
// // //             _buildTextField("Prix (€)", priceController, isNumeric: true),
// // //             const SizedBox(height: 20),
// // //             isLoading
// // //                 ? const Center(child: CircularProgressIndicator())
// // //                 : ElevatedButton(
// // //               onPressed: _saveService,
// // //               child: Text(isAddingNewService ? "Créer et ajouter" : "Ajouter ou mettre à jour"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextButton(
// // //               onPressed: () {
// // //                 setState(() {
// // //                   isAddingNewService = !isAddingNewService;
// // //                 });
// // //               },
// // //               child: Text(isAddingNewService ? "Sélectionner un service existant" : "Ajouter un nouveau service"),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// // //----------------------------------------------------------------------------
// //
// //
// // //
// // //
// // //
// // //
// // // // Future<void> _saveService() async {
// // // //   if (isAddingNewService) {
// // // //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// // // //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
// // // //       return;
// // // //     }
// // // //   } else {
// // // //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// // // //       _showError("Tous les champs sont obligatoires.");
// // // //
// // // //       return;
// // // //     }
// // // //   }
// // // //
// // // //   setState(() {
// // // //     isLoading = true;
// // // //   });
// // // //
// // // //   try {
// // // //     final requestBody = isAddingNewService
// // // //         ? {
// // // //       'id':selectedService,
// // // //       'name': newServiceNameController.text,
// // // //       'description': newServiceDescriptionController.text,
// // // //       'minutes': durationController.text,
// // // //       'price': priceController.text,
// // // //     }
// // // //         : {
// // // //       'service_id': selectedService,
// // // //       'minutes': durationController.text,
// // // //       'price': priceController.text,
// // // //     };
// // // //
// // // //     // Ajout du débogage
// // // //     print("Request Body : $requestBody");
// // // //     final response = await http.post(
// // // //       Uri.parse('http://127.0.0.1:8000/api/add_or_update_service/'),
// // // //       body: json.encode(requestBody),
// // // //       headers: {
// // // //         'Content-Type': 'application/json',
// // // //       },
// // // //     );
// // // //
// // // //     if (response.statusCode == 201) {
// // // //       _showSuccess("Service ajouté ou mis à jour avec succès!");
// // // //       setState(() {
// // // //         newServiceNameController.clear();
// // // //         newServiceDescriptionController.clear();
// // // //         durationController.clear();
// // // //         priceController.clear();
// // // //         selectedService = null;
// // // //         serviceDescription = null;
// // // //         isAddingNewService = false;
// // // //       });
// // // //       await _fetchServices();
// // // //     } else {
// // // //       _showError("Erreur lors de l'ajout ou mise à jour : ${response.body}");
// // // //     }
// // // //   } catch (e) {
// // // //     _showError("Erreur de connexion au serveur.");
// // // //   } finally {
// // // //     setState(() {
// // // //       isLoading = false;
// // // //     });
// // // //   }
// // // // }
// // //
// // //
// // // // import 'package:flutter/material.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'dart:convert';
// // // //
// // // // class CreateServicesPage extends StatefulWidget {
// // // //   const CreateServicesPage({Key? key}) : super(key: key);
// // // //
// // // //   @override
// // // //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // // // }
// // // //
// // // // class _CreateServicesPageState extends State<CreateServicesPage> {
// // // //   final TextEditingController durationController = TextEditingController();
// // // //   final TextEditingController priceController = TextEditingController();
// // // //   final TextEditingController newServiceNameController = TextEditingController();
// // // //   final TextEditingController newServiceDescriptionController = TextEditingController();
// // // //
// // // //   List<dynamic> services = [];
// // // //   String? selectedService;
// // // //   String? serviceDescription;
// // // //   bool isAddingNewService = false;
// // // //   bool isLoading = false;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _fetchServices();
// // // //   }
// // // //
// // // //   Future<void> _fetchServices() async {
// // // //     try {
// // // //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/services/'));
// // // //
// // // //       if (response.statusCode == 200) {
// // // //         final fetchedServices = json.decode(response.body);
// // // //
// // // //         setState(() {
// // // //           services = fetchedServices;
// // // //           selectedService = null; // Réinitialiser la sélection
// // // //         });
// // // //
// // // //         print("Liste des services reçus : $services");
// // // //       } else {
// // // //         _showError("Erreur lors du chargement des services : ${response.body}");
// // // //       }
// // // //     } catch (e) {
// // // //       _showError("Erreur de connexion au serveur.");
// // // //     }
// // // //   }
// // // //
// // // //
// // // //
// // // //   // Future<void> _fetchServices() async {
// // // //   //   try {
// // // //   //     final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/services/'));
// // // //   //
// // // //   //     if (response.statusCode == 200) {
// // // //   //       setState(() {
// // // //   //         services = json.decode(response.body);
// // // //   //       });
// // // //   //       print("Liste des services reçus : $services");
// // // //   //     } else {
// // // //   //       _showError("Erreur lors du chargement des services : ${response.body}");
// // // //   //     }
// // // //   //   } catch (e) {
// // // //   //     _showError("Erreur de connexion au serveur.");
// // // //   //   }
// // // //   // }
// // // //
// // // //   void _onServiceSelected(String? serviceId) {
// // // //     final service = services.firstWhere(
// // // //           (s) => s['idTblService'].toString() == serviceId,
// // // //       orElse: () => null,
// // // //     );
// // // //
// // // //     if (service == null) {
// // // //       _showError("Service introuvable.");
// // // //       return;
// // // //     }
// // // //
// // // //     setState(() {
// // // //       selectedService = serviceId;
// // // //       serviceDescription = service['description'] ?? "Description non disponible";
// // // //       durationController.clear();
// // // //       priceController.clear();
// // // //     });
// // // //   }
// // // //
// // // //   Future<void> _saveService() async {
// // // //     if (isAddingNewService) {
// // // //       // Vérifie que les champs pour un nouveau service sont remplis
// // // //       if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// // // //         _showError("Tous les champs pour le nouveau service sont obligatoires.");
// // // //         return;
// // // //       }
// // // //     } else {
// // // //       // Vérifie que les champs pour un service existant sont remplis
// // // //       if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// // // //         _showError("Tous les champs sont obligatoires.");
// // // //         return;
// // // //       }
// // // //     }
// // // //
// // // //     setState(() {
// // // //       isLoading = true;
// // // //     });
// // // //
// // // //     try {
// // // //       // Prépare le corps de la requête
// // // //       final requestBody = isAddingNewService
// // // //           ? {
// // // //         'salon_id': '1', // ID du salon
// // // //         'name': newServiceNameController.text, // Nom du nouveau service
// // // //         'description': newServiceDescriptionController.text, // Description du nouveau service
// // // //         'duration': durationController.text, // Durée
// // // //         'price': priceController.text, // Prix
// // // //       }
// // // //           : {
// // // //         'salon_id': '1', // ID du salon
// // // //         'service_id': selectedService, // ID du service existant
// // // //         'duration': durationController.text, // Durée personnalisée
// // // //         'price': priceController.text, // Prix personnalisé
// // // //       };
// // // //
// // // //       // Effectue la requête POST
// // // //       final response = await http.post(
// // // //         Uri.parse('http://127.0.0.1:8000/api/add_salon_service/'),
// // // //         body: json.encode(requestBody),
// // // //         headers: {
// // // //           'Content-Type': 'application/json',
// // // //         },
// // // //       );
// // // //
// // // //       if (response.statusCode == 201) {
// // // //         _showSuccess("Service ajouté avec succès!");
// // // //
// // // //         // Réinitialiser les champs et l'état
// // // //         setState(() {
// // // //           newServiceNameController.clear();
// // // //           newServiceDescriptionController.clear();
// // // //           durationController.clear();
// // // //           priceController.clear();
// // // //           selectedService = null;
// // // //           serviceDescription = null;
// // // //           isAddingNewService = false;
// // // //         });
// // // //
// // // //         // Rafraîchir les services depuis l'API
// // // //         await _fetchServices();
// // // //       } else {
// // // //         _showError("Erreur lors de l'ajout : ${response.body}");
// // // //       }
// // // //     } catch (e) {
// // // //       _showError("Erreur de connexion au serveur.");
// // // //     } finally {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //     }
// // // //   }
// // // //
// // // //
// // // //
// // // //
// // // //   // Future<void> _saveService() async {
// // // //   //   if (isAddingNewService) {
// // // //   //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// // // //   //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
// // // //   //       return;
// // // //   //     }
// // // //   //   } else {
// // // //   //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// // // //   //       _showError("Tous les champs sont obligatoires.");
// // // //   //       return;
// // // //   //     }
// // // //   //   }
// // // //   //
// // // //   //   setState(() {
// // // //   //     isLoading = true;
// // // //   //   });
// // // //   //
// // // //   //   try {
// // // //   //     final response = await http.post(
// // // //   //       Uri.parse('http://127.0.0.1:8000/api/add_salon_service/'),
// // // //   //       body: json.encode({
// // // //   //         'salon_id': '1', // ID du salon
// // // //   //         'service_id': selectedService, // ID du service existant
// // // //   //         'duration': durationController.text, // Durée personnalisée
// // // //   //         'price': priceController.text, // Prix personnalisé
// // // //   //       }),
// // // //   //       headers: {
// // // //   //         'Content-Type': 'application/json',
// // // //   //       },
// // // //   //     );
// // // //   //
// // // //   //
// // // //   //     if (response.statusCode == 201) {
// // // //   //       _showSuccess("Service ajouté avec succès!");
// // // //   //
// // // //   //       // Réinitialiser les champs et l'état
// // // //   //       setState(() {
// // // //   //         newServiceNameController.clear();
// // // //   //         newServiceDescriptionController.clear();
// // // //   //         durationController.clear();
// // // //   //         priceController.clear();
// // // //   //         selectedService = null;
// // // //   //         serviceDescription = null;
// // // //   //         isAddingNewService = false;
// // // //   //       });
// // // //   //
// // // //   //       // Rafraîchir les services depuis l'API
// // // //   //       await _fetchServices();
// // // //   //     } else {
// // // //   //       _showError("Erreur lors de l'ajout : ${response.body}");
// // // //   //     }
// // // //   //   } catch (e) {
// // // //   //     _showError("Erreur de connexion au serveur.");
// // // //   //   } finally {
// // // //   //     setState(() {
// // // //   //       isLoading = false;
// // // //   //     });
// // // //   //   }
// // // //   // }
// // // //
// // // //
// // // //
// // // //   void _showError(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Text(
// // // //           message,
// // // //           style: const TextStyle(color: Colors.white),
// // // //         ),
// // // //         backgroundColor: Colors.red,
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _showSuccess(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Text(
// // // //           message,
// // // //           style: const TextStyle(color: Colors.white),
// // // //         ),
// // // //         backgroundColor: Colors.green,
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //
// // // //
// // // //
// // // //   // Future<void> _saveService() async {
// // // //   //   if (isAddingNewService) {
// // // //   //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// // // //   //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
// // // //   //       return;
// // // //   //     }
// // // //   //   } else {
// // // //   //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// // // //   //       _showError("Tous les champs sont obligatoires.");
// // // //   //       return;
// // // //   //     }
// // // //   //   }
// // // //   //
// // // //   //   setState(() {
// // // //   //     isLoading = true;
// // // //   //   });
// // // //   //
// // // //   //   try {
// // // //   //     final url = Uri.parse('http://127.0.0.1:8000/api/add_salon_service/');
// // // //   //     final response = await http.post(
// // // //   //       url,
// // // //   //       body: json.encode({
// // // //   //         'salon_id': "1",//salonId,
// // // //   //         'service_id': isAddingNewService ? null : selectedService,
// // // //   //         'duration': durationController.text,
// // // //   //         'price': priceController.text,
// // // //   //         if (isAddingNewService) 'name': newServiceNameController.text,
// // // //   //         if (isAddingNewService) 'description': newServiceDescriptionController.text,
// // // //   //       }),
// // // //   //       headers: {'Content-Type': 'application/json'},
// // // //   //     );
// // // //   //
// // // //   //     if (response.statusCode == 201) {
// // // //   //       _showSuccess("Service ajouté avec succès!");
// // // //   //       Navigator.pop(context); // Retourne ou vide les champs après succès
// // // //   //     } else {
// // // //   //       _showError("Erreur lors de l'ajout : ${response.body}");
// // // //   //     }
// // // //   //   } catch (e) {
// // // //   //     _showError("Erreur de connexion au serveur.");
// // // //   //   } finally {
// // // //   //     setState(() {
// // // //   //       isLoading = false;
// // // //   //     });
// // // //   //   }
// // // //   // }
// // // //   //
// // // //   // void _showError(String message) {
// // // //   //   ScaffoldMessenger.of(context).showSnackBar(
// // // //   //     SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
// // // //   //   );
// // // //   // }
// // // //   //
// // // //   // void _showSuccess(String message) {
// // // //   //   ScaffoldMessenger.of(context).showSnackBar(
// // // //   //     SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
// // // //   //   );
// // // //   // }
// // // //
// // // //
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text("Créer des services"),
// // // //       ),
// // // //       body: SingleChildScrollView(
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             const Text(
// // // //               "Ajouter un service",
// // // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // //             ),
// // // //             const SizedBox(height: 20),
// // // //             if (!isAddingNewService)
// // // //               DropdownButtonFormField<String>(
// // // //                 decoration: const InputDecoration(
// // // //                   labelText: "Sélectionnez un service",
// // // //                   border: OutlineInputBorder(),
// // // //                 ),
// // // //                 value: selectedService,
// // // //                 items: [
// // // //                   // Option par défaut
// // // //                   const DropdownMenuItem(
// // // //                     value: null,
// // // //                     child: Text("Aucun service sélectionné"),
// // // //                   ),
// // // //                   // Liste des services
// // // //                   ...services.map<DropdownMenuItem<String>>((service) {
// // // //                     return DropdownMenuItem(
// // // //                       value: service['idTblService'].toString(), // ID unique comme valeur
// // // //                       child: Text(service['intitule_service'] ?? "Nom indisponible"),
// // // //                     );
// // // //                   }).toList(),
// // // //                 ],
// // // //                 onChanged: (value) {
// // // //                   setState(() {
// // // //                     selectedService = value; // Mettre à jour la sélection
// // // //                   });
// // // //                 },
// // // //               ),
// // // //
// // // //
// // // //
// // // //             const SizedBox(height: 10),
// // // //             if (!isAddingNewService && serviceDescription != null)
// // // //               Text("Description : $serviceDescription"),
// // // //             if (isAddingNewService)
// // // //               Column(
// // // //                 children: [
// // // //                   _buildTextField("Nom du nouveau service", newServiceNameController),
// // // //                   const SizedBox(height: 10),
// // // //                   _buildTextField("Description du nouveau service", newServiceDescriptionController, maxLines: 3),
// // // //                 ],
// // // //               ),
// // // //             const SizedBox(height: 10),
// // // //             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
// // // //             const SizedBox(height: 10),
// // // //             _buildTextField("Prix (€)", priceController, isNumeric: true),
// // // //             const SizedBox(height: 20),
// // // //             isLoading
// // // //                 ? const Center(child: CircularProgressIndicator())
// // // //                 : ElevatedButton(
// // // //               onPressed: _saveService,
// // // //               child: Text(isAddingNewService ? "Créer et ajouter" : "Ajouter le service"),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             TextButton(
// // // //               onPressed: () {
// // // //                 setState(() {
// // // //                   isAddingNewService = !isAddingNewService;
// // // //                 });
// // // //               },
// // // //               child: Text(isAddingNewService ? "Sélectionner un service existant" : "Ajouter un nouveau service"),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildTextField(String label, TextEditingController controller,
// // // //       {bool isNumeric = false, int maxLines = 1}) {
// // // //     return TextField(
// // // //       controller: controller,
// // // //       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
// // // //       decoration: InputDecoration(
// // // //         labelText: label,
// // // //         border: const OutlineInputBorder(),
// // // //       ),
// // // //       maxLines: maxLines,
// // // //     );
// // // //   }
// // // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // // // import 'package:flutter/material.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'dart:convert';
// // // //
// // // // class CreateServicesPage extends StatefulWidget {
// // // //   const CreateServicesPage({Key? key}) : super(key: key);
// // // //
// // // //   @override
// // // //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // // // }
// // // //
// // // // class _CreateServicesPageState extends State<CreateServicesPage> {
// // // //   final TextEditingController durationController = TextEditingController();
// // // //   final TextEditingController priceController = TextEditingController();
// // // //   final TextEditingController newServiceNameController = TextEditingController();
// // // //   final TextEditingController newServiceDescriptionController = TextEditingController();
// // // //
// // // //   List<dynamic> services = [];
// // // //   String? selectedService;
// // // //   String? serviceDescription;
// // // //   bool isAddingNewService = false;
// // // //   bool isLoading = false;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _fetchServices();
// // // //   }
// // // //
// // // //   Future<void> _fetchServices() async {
// // // //     try {
// // // //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/services/'));
// // // //
// // // //       if (response.statusCode == 200) {
// // // //         setState(() {
// // // //           services = json.decode(response.body);
// // // //         });
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Erreur lors du chargement des services : ${response.body}")),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // // //       );
// // // //     }
// // // //   }
// // // //
// // // //   void _onServiceSelected(String? serviceId) {
// // // //     final service = services.firstWhere((s) => s['id'] == serviceId, orElse: () => null);
// // // //     setState(() {
// // // //       selectedService = serviceId;
// // // //       serviceDescription = service?['description'];
// // // //       durationController.clear();
// // // //       priceController.clear();
// // // //     });
// // // //   }
// // // //
// // // //   Future<void> _saveService() async {
// // // //     if (isAddingNewService) {
// // // //       if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Tous les champs pour le nouveau service sont obligatoires.")),
// // // //         );
// // // //         return;
// // // //       }
// // // //     } else {
// // // //       if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Tous les champs sont obligatoires.")),
// // // //         );
// // // //         return;
// // // //       }
// // // //     }
// // // //
// // // //     setState(() {
// // // //       isLoading = true;
// // // //     });
// // // //
// // // //     try {
// // // //       final url = Uri.parse('http://127.0.0.1:8000/api/add_salon_service/');
// // // //       final response = await http.post(
// // // //         url,
// // // //         body: json.encode({
// // // //           'service_id': isAddingNewService ? null : selectedService,
// // // //           'duration': durationController.text,
// // // //           'price': priceController.text,
// // // //           if (isAddingNewService) 'name': newServiceNameController.text,
// // // //           if (isAddingNewService) 'description': newServiceDescriptionController.text,
// // // //         }),
// // // //         headers: {'Content-Type': 'application/json'},
// // // //       );
// // // //
// // // //       if (response.statusCode == 201) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Service ajouté avec succès!")),
// // // //         );
// // // //         Navigator.pop(context); // Retourner ou vider les champs après succès
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Erreur lors de l'ajout : ${response.body}")),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // // //       );
// // // //     } finally {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //     }
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text("Créer des services"),
// // // //       ),
// // // //       body: SingleChildScrollView(
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             const Text(
// // // //               "Ajouter un service",
// // // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // //             ),
// // // //             const SizedBox(height: 20),
// // // //             if (!isAddingNewService)
// // // //               DropdownButtonFormField<String>(
// // // //                 decoration: const InputDecoration(
// // // //                   labelText: "Sélectionnez un service",
// // // //                   border: OutlineInputBorder(),
// // // //                 ),
// // // //                 value: selectedService,
// // // //                 items: services
// // // //                     .map<DropdownMenuItem<String>>((service) => DropdownMenuItem(
// // // //                   value: service['id'].toString(),
// // // //                   child: Text(service['name']),
// // // //                 ))
// // // //                     .toList(),
// // // //                 onChanged: _onServiceSelected,
// // // //               ),
// // // //             const SizedBox(height: 10),
// // // //             if (!isAddingNewService && serviceDescription != null)
// // // //               Text("Description : $serviceDescription"),
// // // //             if (isAddingNewService)
// // // //               Column(
// // // //                 children: [
// // // //                   _buildTextField("Nom du nouveau service", newServiceNameController),
// // // //                   const SizedBox(height: 10),
// // // //                   _buildTextField("Description du nouveau service", newServiceDescriptionController, maxLines: 3),
// // // //                 ],
// // // //               ),
// // // //             const SizedBox(height: 10),
// // // //             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
// // // //             const SizedBox(height: 10),
// // // //             _buildTextField("Prix (€)", priceController, isNumeric: true),
// // // //             const SizedBox(height: 20),
// // // //             isLoading
// // // //                 ? const Center(child: CircularProgressIndicator())
// // // //                 : ElevatedButton(
// // // //               onPressed: _saveService,
// // // //               child: Text(isAddingNewService ? "Créer et ajouter" : "Ajouter le service"),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             TextButton(
// // // //               onPressed: () {
// // // //                 setState(() {
// // // //                   isAddingNewService = !isAddingNewService;
// // // //                 });
// // // //               },
// // // //               child: Text(isAddingNewService ? "Sélectionner un service existant" : "Ajouter un nouveau service"),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildTextField(String label, TextEditingController controller,
// // // //       {bool isNumeric = false, int maxLines = 1}) {
// // // //     return TextField(
// // // //       controller: controller,
// // // //       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
// // // //       decoration: InputDecoration(
// // // //         labelText: label,
// // // //         border: const OutlineInputBorder(),
// // // //       ),
// // // //       maxLines: maxLines,
// // // //     );
// // // //   }
// // // // }
// // //
// // //
// // //
// // //
// // // // import 'package:flutter/cupertino.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:http/http.dart' as http;
// // // //
// // // // class CreateServicesPage extends StatefulWidget {
// // // //   const CreateServicesPage({Key? key}) : super(key: key);
// // // //
// // // //   @override
// // // //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // // // }
// // // //
// // // // class _CreateServicesPageState extends State<CreateServicesPage> {
// // // //   final TextEditingController nameController = TextEditingController();
// // // //   final TextEditingController descriptionController = TextEditingController();
// // // //   final TextEditingController durationController = TextEditingController();
// // // //   final TextEditingController priceController = TextEditingController();
// // // //   bool isLoading = false;
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text("Créer des services"),
// // // //       ),
// // // //       body: SingleChildScrollView(
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             const Text(
// // // //               "Ajouter un nouveau service",
// // // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // //             ),
// // // //             const SizedBox(height: 20),
// // // //             _buildTextField("Nom du service", nameController),
// // // //             const SizedBox(height: 10),
// // // //             _buildTextField("Description", descriptionController, maxLines: 3),
// // // //             const SizedBox(height: 10),
// // // //             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
// // // //             const SizedBox(height: 10),
// // // //             _buildTextField("Prix (€)", priceController, isNumeric: true),
// // // //             const SizedBox(height: 20),
// // // //             isLoading
// // // //                 ? const Center(child: CircularProgressIndicator())
// // // //                 : ElevatedButton(
// // // //               onPressed: _saveService,
// // // //               child: const Text("Enregistrer le service"),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildTextField(String label, TextEditingController controller,
// // // //       {bool isNumeric = false, int maxLines = 1}) {
// // // //     return TextField(
// // // //       controller: controller,
// // // //       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
// // // //       decoration: InputDecoration(
// // // //         labelText: label,
// // // //         border: const OutlineInputBorder(),
// // // //       ),
// // // //       maxLines: maxLines,
// // // //     );
// // // //   }
// // // //
// // // //   Future<void> _saveService() async {
// // // //     if (nameController.text.isEmpty ||
// // // //         descriptionController.text.isEmpty ||
// // // //         durationController.text.isEmpty ||
// // // //         priceController.text.isEmpty) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text("Tous les champs sont obligatoires.")),
// // // //       );
// // // //       return;
// // // //     }
// // // //
// // // //     setState(() {
// // // //       isLoading = true;
// // // //     });
// // // //
// // // //     final serviceData = {
// // // //       'name': nameController.text,
// // // //       'description': descriptionController.text,
// // // //       'duration': durationController.text,
// // // //       'price': priceController.text,
// // // //     };
// // // //
// // // //     try {
// // // //       // Envoyer les données au backend (URL à remplacer par la vôtre)
// // // //       final response = await http.post(
// // // //         Uri.parse('http://127.0.0.1:8000/api/create_service/'),
// // // //         body: serviceData,
// // // //       );
// // // //
// // // //       if (response.statusCode == 201) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Service ajouté avec succès!")),
// // // //         );
// // // //         // Réinitialiser les champs après ajout
// // // //         nameController.clear();
// // // //         descriptionController.clear();
// // // //         durationController.clear();
// // // //         priceController.clear();
// // // //       } else {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Erreur lors de l'ajout : ${response.body}")),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // // //       );
// // // //     } finally {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //     }
// // // //   }
// // // // }
