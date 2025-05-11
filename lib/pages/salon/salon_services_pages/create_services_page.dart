// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'add_service_page.dart'; // Nouvelle page pour ajouter un service
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<dynamic> services = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchServices();
//   }
//
//   Future<void> fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/coiffeuse_services/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         setState(() {
//           services = json.decode(response.body);
//         });
//       } else {
//         setState(() {
//           hasError = true;
//         });
//         _showError("Erreur lors du chargement des services : ${response.body}");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _refreshData() async {
//     await fetchServices();
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Liste des services"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Erreur de chargement",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: fetchServices,
//               child: const Text("Réessayer"),
//             ),
//           ],
//         ),
//       )
//           : services.isEmpty
//           ? const Center(
//         child: Text(
//           "Aucun service trouvé.",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _refreshData,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(8),
//           itemCount: services.length,
//           itemBuilder: (context, index) {
//             final service = services[index];
//             return Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       service['intitule_service'] ?? "Nom indisponible",
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("Prix : ${service['prix']?.toString() ?? 'Non défini'} €"),
//                         Text("Temps : ${service['temps_minutes']?.toString() ?? 'Non défini'} min"),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//             ),
//           );
//
//           if (result == true) {
//             fetchServices();
//           }
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class CreateServicesPage extends StatefulWidget {
//   const CreateServicesPage({Key? key}) : super(key: key);
//
//   @override
//   State<CreateServicesPage> createState() => _CreateServicesPageState();
// }
//
// class _CreateServicesPageState extends State<CreateServicesPage> {
//   final TextEditingController durationController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController newServiceNameController = TextEditingController();
//   final TextEditingController newServiceDescriptionController = TextEditingController();
//
//   List<dynamic> services = [];
//   String? selectedService;
//   String? serviceDescription;
//   bool isAddingNewService = false;
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     try {
//       final response = await http.get(Uri.parse('http://192.168.0.248:8000/api/services/'));
//
//       if (response.statusCode == 200) {
//         final fetchedServices = json.decode(response.body);
//
//         setState(() {
//           services = fetchedServices;
//           selectedService = null; // Réinitialiser la sélection
//         });
//
//         print("Liste des services reçus : $services");
//       } else {
//         _showError("Erreur lors du chargement des services : ${response.body}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _onServiceSelected(String? serviceId) {
//     final service = services.firstWhere(
//           (s) => s['idTblService'].toString() == serviceId,
//       orElse: () => null,
//     );
//
//     if (service == null) {
//       _showError("Service introuvable.");
//       return;
//     }
//
//     setState(() {
//       selectedService = serviceId;
//       serviceDescription = service['description'] ?? "Description non disponible";
//       durationController.text = service['temps']?['minutes']?.toString() ?? '';
//       priceController.text = service['prix']?['prix']?.toString() ?? '';
//       // print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
//       // print('l id est :'+ serviceId!);
//       // print('l id est :'+ serviceDescription!);
//       // print('l id est :'+ durationController.text!);
//       // print('l id est :'+ priceController.text!);
//       // print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
//
//     });
//   }
//
//   Future<void> _saveService() async {
//     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
//       _showError("Tous les champs sont obligatoires.");
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       final requestBody = {
//         'salon_id': '1', // Remplacez par l'ID réel du salon
//         'service_id': selectedService,
//         'duration': int.parse(durationController.text),
//         'price': double.parse(priceController.text),
//       };
//
//       final response = await http.post(
//         Uri.parse('http://192.168.0.248:8000/api/link_salon_service/'),
//         body: json.encode(requestBody),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 201) {
//         _showSuccess("Service associé au salon avec succès !");
//       } else {
//         _showError("Erreur lors de l'association : ${response.body}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
//   // Future<void> _saveService() async {
//   //   if (isAddingNewService) {
//   //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
//   //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
//   //       return;
//   //     }
//   //   } else {
//   //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
//   //       _showError("Tous les champs sont obligatoires.");
//   //       return;
//   //     }
//   //   }
//   //
//   //   setState(() {
//   //     isLoading = true;
//   //   });
//   //
//   //   try {
//   //     final requestBody = isAddingNewService
//   //         ? {
//   //       'name': newServiceNameController.text,
//   //       'description': newServiceDescriptionController.text,
//   //       'minutes': int.parse(durationController.text),
//   //       'price': double.parse(priceController.text),
//   //     }
//   //         : {
//   //       'service_id': selectedService,
//   //       'minutes': int.parse(durationController.text),
//   //       'price': double.parse(priceController.text),
//   //     };
//   //
//   //     // Choisir la méthode HTTP et l'URL
//   //     final url = isAddingNewService
//   //         ? Uri.parse('http://192.168.0.248:8000/api/add_or_update_service/')
//   //         : Uri.parse('http://192.168.0.248:8000/api/add_or_update_service/$selectedService/');
//   //
//   //     final response = isAddingNewService
//   //         ? await http.post(
//   //       url,
//   //       body: json.encode(requestBody),
//   //       headers: {'Content-Type': 'application/json'},
//   //     )
//   //         : await http.put(
//   //       url,
//   //       body: json.encode(requestBody),
//   //       headers: {'Content-Type': 'application/json'},
//   //     );
//   //
//   //     if (response.statusCode == 201 || response.statusCode == 200) {
//   //       _showSuccess("Service ajouté ou mis à jour avec succès!");
//   //       setState(() {
//   //         newServiceNameController.clear();
//   //         newServiceDescriptionController.clear();
//   //         durationController.clear();
//   //         priceController.clear();
//   //         selectedService = null;
//   //         serviceDescription = null;
//   //         isAddingNewService = false;
//   //       });
//   //       await _fetchServices();
//   //     } else {
//   //       _showError("Erreur lors de l'ajout ou mise à jour : ${response.body}");
//   //     }
//   //   } catch (e) {
//   //     _showError("Erreur de connexion au serveur.");
//   //   } finally {
//   //     setState(() {
//   //       isLoading = false;
//   //     });
//   //   }
//   // }
//
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller,
//       {bool isNumeric = false, int maxLines = 1}) {
//     return TextField(
//       controller: controller,
//       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//       maxLines: maxLines,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer des services"),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Ajouter un service",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             if (!isAddingNewService)
//               DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: "Sélectionnez un service",
//                   border: OutlineInputBorder(),
//                 ),
//                 value: selectedService,
//                 items: [
//                   const DropdownMenuItem(
//                     value: null,
//                     child: Text("Aucun service sélectionné"),
//                   ),
//                   ...services.map<DropdownMenuItem<String>>((service) {
//                     return DropdownMenuItem(
//                       value: service['idTblService'].toString(),
//                       child: Text(service['intitule_service'] ?? "Nom indisponible"),
//                     );
//                   }).toList(),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     selectedService = value;
//                     _onServiceSelected(value);
//                   });
//                 },
//               ),
//             const SizedBox(height: 10),
//             if (!isAddingNewService && serviceDescription != null)
//               Text("Description : $serviceDescription"),
//             if (isAddingNewService)
//               Column(
//                 children: [
//                   _buildTextField("Nom du nouveau service", newServiceNameController),
//                   const SizedBox(height: 10),
//                   _buildTextField("Description du nouveau service", newServiceDescriptionController, maxLines: 3),
//                 ],
//               ),
//             const SizedBox(height: 10),
//             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
//             const SizedBox(height: 10),
//             _buildTextField("Prix (€)", priceController, isNumeric: true),
//             const SizedBox(height: 20),
//             isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ElevatedButton(
//               onPressed: _saveService,
//               child: Text(isAddingNewService ? "Créer et ajouter" : "Ajouter ou mettre à jour"),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   isAddingNewService = !isAddingNewService;
//                 });
//               },
//               child: Text(isAddingNewService ? "Sélectionner un service existant" : "Ajouter un nouveau service"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//----------------------------------------------------------------------------


//
//
//
//
// // Future<void> _saveService() async {
// //   if (isAddingNewService) {
// //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
// //       return;
// //     }
// //   } else {
// //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// //       _showError("Tous les champs sont obligatoires.");
// //
// //       return;
// //     }
// //   }
// //
// //   setState(() {
// //     isLoading = true;
// //   });
// //
// //   try {
// //     final requestBody = isAddingNewService
// //         ? {
// //       'id':selectedService,
// //       'name': newServiceNameController.text,
// //       'description': newServiceDescriptionController.text,
// //       'minutes': durationController.text,
// //       'price': priceController.text,
// //     }
// //         : {
// //       'service_id': selectedService,
// //       'minutes': durationController.text,
// //       'price': priceController.text,
// //     };
// //
// //     // Ajout du débogage
// //     print("Request Body : $requestBody");
// //     final response = await http.post(
// //       Uri.parse('http://127.0.0.1:8000/api/add_or_update_service/'),
// //       body: json.encode(requestBody),
// //       headers: {
// //         'Content-Type': 'application/json',
// //       },
// //     );
// //
// //     if (response.statusCode == 201) {
// //       _showSuccess("Service ajouté ou mis à jour avec succès!");
// //       setState(() {
// //         newServiceNameController.clear();
// //         newServiceDescriptionController.clear();
// //         durationController.clear();
// //         priceController.clear();
// //         selectedService = null;
// //         serviceDescription = null;
// //         isAddingNewService = false;
// //       });
// //       await _fetchServices();
// //     } else {
// //       _showError("Erreur lors de l'ajout ou mise à jour : ${response.body}");
// //     }
// //   } catch (e) {
// //     _showError("Erreur de connexion au serveur.");
// //   } finally {
// //     setState(() {
// //       isLoading = false;
// //     });
// //   }
// // }
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class CreateServicesPage extends StatefulWidget {
// //   const CreateServicesPage({Key? key}) : super(key: key);
// //
// //   @override
// //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // }
// //
// // class _CreateServicesPageState extends State<CreateServicesPage> {
// //   final TextEditingController durationController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController newServiceNameController = TextEditingController();
// //   final TextEditingController newServiceDescriptionController = TextEditingController();
// //
// //   List<dynamic> services = [];
// //   String? selectedService;
// //   String? serviceDescription;
// //   bool isAddingNewService = false;
// //   bool isLoading = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchServices();
// //   }
// //
// //   Future<void> _fetchServices() async {
// //     try {
// //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/services/'));
// //
// //       if (response.statusCode == 200) {
// //         final fetchedServices = json.decode(response.body);
// //
// //         setState(() {
// //           services = fetchedServices;
// //           selectedService = null; // Réinitialiser la sélection
// //         });
// //
// //         print("Liste des services reçus : $services");
// //       } else {
// //         _showError("Erreur lors du chargement des services : ${response.body}");
// //       }
// //     } catch (e) {
// //       _showError("Erreur de connexion au serveur.");
// //     }
// //   }
// //
// //
// //
// //   // Future<void> _fetchServices() async {
// //   //   try {
// //   //     final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/services/'));
// //   //
// //   //     if (response.statusCode == 200) {
// //   //       setState(() {
// //   //         services = json.decode(response.body);
// //   //       });
// //   //       print("Liste des services reçus : $services");
// //   //     } else {
// //   //       _showError("Erreur lors du chargement des services : ${response.body}");
// //   //     }
// //   //   } catch (e) {
// //   //     _showError("Erreur de connexion au serveur.");
// //   //   }
// //   // }
// //
// //   void _onServiceSelected(String? serviceId) {
// //     final service = services.firstWhere(
// //           (s) => s['idTblService'].toString() == serviceId,
// //       orElse: () => null,
// //     );
// //
// //     if (service == null) {
// //       _showError("Service introuvable.");
// //       return;
// //     }
// //
// //     setState(() {
// //       selectedService = serviceId;
// //       serviceDescription = service['description'] ?? "Description non disponible";
// //       durationController.clear();
// //       priceController.clear();
// //     });
// //   }
// //
// //   Future<void> _saveService() async {
// //     if (isAddingNewService) {
// //       // Vérifie que les champs pour un nouveau service sont remplis
// //       if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// //         _showError("Tous les champs pour le nouveau service sont obligatoires.");
// //         return;
// //       }
// //     } else {
// //       // Vérifie que les champs pour un service existant sont remplis
// //       if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// //         _showError("Tous les champs sont obligatoires.");
// //         return;
// //       }
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       // Prépare le corps de la requête
// //       final requestBody = isAddingNewService
// //           ? {
// //         'salon_id': '1', // ID du salon
// //         'name': newServiceNameController.text, // Nom du nouveau service
// //         'description': newServiceDescriptionController.text, // Description du nouveau service
// //         'duration': durationController.text, // Durée
// //         'price': priceController.text, // Prix
// //       }
// //           : {
// //         'salon_id': '1', // ID du salon
// //         'service_id': selectedService, // ID du service existant
// //         'duration': durationController.text, // Durée personnalisée
// //         'price': priceController.text, // Prix personnalisé
// //       };
// //
// //       // Effectue la requête POST
// //       final response = await http.post(
// //         Uri.parse('http://127.0.0.1:8000/api/add_salon_service/'),
// //         body: json.encode(requestBody),
// //         headers: {
// //           'Content-Type': 'application/json',
// //         },
// //       );
// //
// //       if (response.statusCode == 201) {
// //         _showSuccess("Service ajouté avec succès!");
// //
// //         // Réinitialiser les champs et l'état
// //         setState(() {
// //           newServiceNameController.clear();
// //           newServiceDescriptionController.clear();
// //           durationController.clear();
// //           priceController.clear();
// //           selectedService = null;
// //           serviceDescription = null;
// //           isAddingNewService = false;
// //         });
// //
// //         // Rafraîchir les services depuis l'API
// //         await _fetchServices();
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
// //
// //
// //
// //   // Future<void> _saveService() async {
// //   //   if (isAddingNewService) {
// //   //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// //   //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
// //   //       return;
// //   //     }
// //   //   } else {
// //   //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// //   //       _showError("Tous les champs sont obligatoires.");
// //   //       return;
// //   //     }
// //   //   }
// //   //
// //   //   setState(() {
// //   //     isLoading = true;
// //   //   });
// //   //
// //   //   try {
// //   //     final response = await http.post(
// //   //       Uri.parse('http://127.0.0.1:8000/api/add_salon_service/'),
// //   //       body: json.encode({
// //   //         'salon_id': '1', // ID du salon
// //   //         'service_id': selectedService, // ID du service existant
// //   //         'duration': durationController.text, // Durée personnalisée
// //   //         'price': priceController.text, // Prix personnalisé
// //   //       }),
// //   //       headers: {
// //   //         'Content-Type': 'application/json',
// //   //       },
// //   //     );
// //   //
// //   //
// //   //     if (response.statusCode == 201) {
// //   //       _showSuccess("Service ajouté avec succès!");
// //   //
// //   //       // Réinitialiser les champs et l'état
// //   //       setState(() {
// //   //         newServiceNameController.clear();
// //   //         newServiceDescriptionController.clear();
// //   //         durationController.clear();
// //   //         priceController.clear();
// //   //         selectedService = null;
// //   //         serviceDescription = null;
// //   //         isAddingNewService = false;
// //   //       });
// //   //
// //   //       // Rafraîchir les services depuis l'API
// //   //       await _fetchServices();
// //   //     } else {
// //   //       _showError("Erreur lors de l'ajout : ${response.body}");
// //   //     }
// //   //   } catch (e) {
// //   //     _showError("Erreur de connexion au serveur.");
// //   //   } finally {
// //   //     setState(() {
// //   //       isLoading = false;
// //   //     });
// //   //   }
// //   // }
// //
// //
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(
// //           message,
// //           style: const TextStyle(color: Colors.white),
// //         ),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   void _showSuccess(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(
// //           message,
// //           style: const TextStyle(color: Colors.white),
// //         ),
// //         backgroundColor: Colors.green,
// //       ),
// //     );
// //   }
// //
// //
// //
// //
// //   // Future<void> _saveService() async {
// //   //   if (isAddingNewService) {
// //   //     if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// //   //       _showError("Tous les champs pour le nouveau service sont obligatoires.");
// //   //       return;
// //   //     }
// //   //   } else {
// //   //     if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// //   //       _showError("Tous les champs sont obligatoires.");
// //   //       return;
// //   //     }
// //   //   }
// //   //
// //   //   setState(() {
// //   //     isLoading = true;
// //   //   });
// //   //
// //   //   try {
// //   //     final url = Uri.parse('http://127.0.0.1:8000/api/add_salon_service/');
// //   //     final response = await http.post(
// //   //       url,
// //   //       body: json.encode({
// //   //         'salon_id': "1",//salonId,
// //   //         'service_id': isAddingNewService ? null : selectedService,
// //   //         'duration': durationController.text,
// //   //         'price': priceController.text,
// //   //         if (isAddingNewService) 'name': newServiceNameController.text,
// //   //         if (isAddingNewService) 'description': newServiceDescriptionController.text,
// //   //       }),
// //   //       headers: {'Content-Type': 'application/json'},
// //   //     );
// //   //
// //   //     if (response.statusCode == 201) {
// //   //       _showSuccess("Service ajouté avec succès!");
// //   //       Navigator.pop(context); // Retourne ou vide les champs après succès
// //   //     } else {
// //   //       _showError("Erreur lors de l'ajout : ${response.body}");
// //   //     }
// //   //   } catch (e) {
// //   //     _showError("Erreur de connexion au serveur.");
// //   //   } finally {
// //   //     setState(() {
// //   //       isLoading = false;
// //   //     });
// //   //   }
// //   // }
// //   //
// //   // void _showError(String message) {
// //   //   ScaffoldMessenger.of(context).showSnackBar(
// //   //     SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
// //   //   );
// //   // }
// //   //
// //   // void _showSuccess(String message) {
// //   //   ScaffoldMessenger.of(context).showSnackBar(
// //   //     SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
// //   //   );
// //   // }
// //
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Créer des services"),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               "Ajouter un service",
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 20),
// //             if (!isAddingNewService)
// //               DropdownButtonFormField<String>(
// //                 decoration: const InputDecoration(
// //                   labelText: "Sélectionnez un service",
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 value: selectedService,
// //                 items: [
// //                   // Option par défaut
// //                   const DropdownMenuItem(
// //                     value: null,
// //                     child: Text("Aucun service sélectionné"),
// //                   ),
// //                   // Liste des services
// //                   ...services.map<DropdownMenuItem<String>>((service) {
// //                     return DropdownMenuItem(
// //                       value: service['idTblService'].toString(), // ID unique comme valeur
// //                       child: Text(service['intitule_service'] ?? "Nom indisponible"),
// //                     );
// //                   }).toList(),
// //                 ],
// //                 onChanged: (value) {
// //                   setState(() {
// //                     selectedService = value; // Mettre à jour la sélection
// //                   });
// //                 },
// //               ),
// //
// //
// //
// //             const SizedBox(height: 10),
// //             if (!isAddingNewService && serviceDescription != null)
// //               Text("Description : $serviceDescription"),
// //             if (isAddingNewService)
// //               Column(
// //                 children: [
// //                   _buildTextField("Nom du nouveau service", newServiceNameController),
// //                   const SizedBox(height: 10),
// //                   _buildTextField("Description du nouveau service", newServiceDescriptionController, maxLines: 3),
// //                 ],
// //               ),
// //             const SizedBox(height: 10),
// //             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
// //             const SizedBox(height: 10),
// //             _buildTextField("Prix (€)", priceController, isNumeric: true),
// //             const SizedBox(height: 20),
// //             isLoading
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : ElevatedButton(
// //               onPressed: _saveService,
// //               child: Text(isAddingNewService ? "Créer et ajouter" : "Ajouter le service"),
// //             ),
// //             const SizedBox(height: 10),
// //             TextButton(
// //               onPressed: () {
// //                 setState(() {
// //                   isAddingNewService = !isAddingNewService;
// //                 });
// //               },
// //               child: Text(isAddingNewService ? "Sélectionner un service existant" : "Ajouter un nouveau service"),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller,
// //       {bool isNumeric = false, int maxLines = 1}) {
// //     return TextField(
// //       controller: controller,
// //       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         border: const OutlineInputBorder(),
// //       ),
// //       maxLines: maxLines,
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
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class CreateServicesPage extends StatefulWidget {
// //   const CreateServicesPage({Key? key}) : super(key: key);
// //
// //   @override
// //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // }
// //
// // class _CreateServicesPageState extends State<CreateServicesPage> {
// //   final TextEditingController durationController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController newServiceNameController = TextEditingController();
// //   final TextEditingController newServiceDescriptionController = TextEditingController();
// //
// //   List<dynamic> services = [];
// //   String? selectedService;
// //   String? serviceDescription;
// //   bool isAddingNewService = false;
// //   bool isLoading = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchServices();
// //   }
// //
// //   Future<void> _fetchServices() async {
// //     try {
// //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/services/'));
// //
// //       if (response.statusCode == 200) {
// //         setState(() {
// //           services = json.decode(response.body);
// //         });
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Erreur lors du chargement des services : ${response.body}")),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// //       );
// //     }
// //   }
// //
// //   void _onServiceSelected(String? serviceId) {
// //     final service = services.firstWhere((s) => s['id'] == serviceId, orElse: () => null);
// //     setState(() {
// //       selectedService = serviceId;
// //       serviceDescription = service?['description'];
// //       durationController.clear();
// //       priceController.clear();
// //     });
// //   }
// //
// //   Future<void> _saveService() async {
// //     if (isAddingNewService) {
// //       if (newServiceNameController.text.isEmpty || newServiceDescriptionController.text.isEmpty) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Tous les champs pour le nouveau service sont obligatoires.")),
// //         );
// //         return;
// //       }
// //     } else {
// //       if (selectedService == null || durationController.text.isEmpty || priceController.text.isEmpty) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Tous les champs sont obligatoires.")),
// //         );
// //         return;
// //       }
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final url = Uri.parse('http://127.0.0.1:8000/api/add_salon_service/');
// //       final response = await http.post(
// //         url,
// //         body: json.encode({
// //           'service_id': isAddingNewService ? null : selectedService,
// //           'duration': durationController.text,
// //           'price': priceController.text,
// //           if (isAddingNewService) 'name': newServiceNameController.text,
// //           if (isAddingNewService) 'description': newServiceDescriptionController.text,
// //         }),
// //         headers: {'Content-Type': 'application/json'},
// //       );
// //
// //       if (response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Service ajouté avec succès!")),
// //         );
// //         Navigator.pop(context); // Retourner ou vider les champs après succès
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Erreur lors de l'ajout : ${response.body}")),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// //       );
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Créer des services"),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               "Ajouter un service",
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 20),
// //             if (!isAddingNewService)
// //               DropdownButtonFormField<String>(
// //                 decoration: const InputDecoration(
// //                   labelText: "Sélectionnez un service",
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 value: selectedService,
// //                 items: services
// //                     .map<DropdownMenuItem<String>>((service) => DropdownMenuItem(
// //                   value: service['id'].toString(),
// //                   child: Text(service['name']),
// //                 ))
// //                     .toList(),
// //                 onChanged: _onServiceSelected,
// //               ),
// //             const SizedBox(height: 10),
// //             if (!isAddingNewService && serviceDescription != null)
// //               Text("Description : $serviceDescription"),
// //             if (isAddingNewService)
// //               Column(
// //                 children: [
// //                   _buildTextField("Nom du nouveau service", newServiceNameController),
// //                   const SizedBox(height: 10),
// //                   _buildTextField("Description du nouveau service", newServiceDescriptionController, maxLines: 3),
// //                 ],
// //               ),
// //             const SizedBox(height: 10),
// //             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
// //             const SizedBox(height: 10),
// //             _buildTextField("Prix (€)", priceController, isNumeric: true),
// //             const SizedBox(height: 20),
// //             isLoading
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : ElevatedButton(
// //               onPressed: _saveService,
// //               child: Text(isAddingNewService ? "Créer et ajouter" : "Ajouter le service"),
// //             ),
// //             const SizedBox(height: 10),
// //             TextButton(
// //               onPressed: () {
// //                 setState(() {
// //                   isAddingNewService = !isAddingNewService;
// //                 });
// //               },
// //               child: Text(isAddingNewService ? "Sélectionner un service existant" : "Ajouter un nouveau service"),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller,
// //       {bool isNumeric = false, int maxLines = 1}) {
// //     return TextField(
// //       controller: controller,
// //       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         border: const OutlineInputBorder(),
// //       ),
// //       maxLines: maxLines,
// //     );
// //   }
// // }
//
//
//
//
// // import 'package:flutter/cupertino.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// //
// // class CreateServicesPage extends StatefulWidget {
// //   const CreateServicesPage({Key? key}) : super(key: key);
// //
// //   @override
// //   State<CreateServicesPage> createState() => _CreateServicesPageState();
// // }
// //
// // class _CreateServicesPageState extends State<CreateServicesPage> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   bool isLoading = false;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Créer des services"),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               "Ajouter un nouveau service",
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 20),
// //             _buildTextField("Nom du service", nameController),
// //             const SizedBox(height: 10),
// //             _buildTextField("Description", descriptionController, maxLines: 3),
// //             const SizedBox(height: 10),
// //             _buildTextField("Durée (en minutes)", durationController, isNumeric: true),
// //             const SizedBox(height: 10),
// //             _buildTextField("Prix (€)", priceController, isNumeric: true),
// //             const SizedBox(height: 20),
// //             isLoading
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : ElevatedButton(
// //               onPressed: _saveService,
// //               child: const Text("Enregistrer le service"),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField(String label, TextEditingController controller,
// //       {bool isNumeric = false, int maxLines = 1}) {
// //     return TextField(
// //       controller: controller,
// //       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         border: const OutlineInputBorder(),
// //       ),
// //       maxLines: maxLines,
// //     );
// //   }
// //
// //   Future<void> _saveService() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         durationController.text.isEmpty ||
// //         priceController.text.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Tous les champs sont obligatoires.")),
// //       );
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     final serviceData = {
// //       'name': nameController.text,
// //       'description': descriptionController.text,
// //       'duration': durationController.text,
// //       'price': priceController.text,
// //     };
// //
// //     try {
// //       // Envoyer les données au backend (URL à remplacer par la vôtre)
// //       final response = await http.post(
// //         Uri.parse('http://127.0.0.1:8000/api/create_service/'),
// //         body: serviceData,
// //       );
// //
// //       if (response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Service ajouté avec succès!")),
// //         );
// //         // Réinitialiser les champs après ajout
// //         nameController.clear();
// //         descriptionController.clear();
// //         durationController.clear();
// //         priceController.clear();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Erreur lors de l'ajout : ${response.body}")),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// //       );
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// // }
