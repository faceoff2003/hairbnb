import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hairbnb/services/messages/messages_page.dart';


class ServicesListPage extends StatefulWidget {
  final String coiffeuseId;

  const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  List<dynamic> services = [];
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.202:8000/api/coiffeuse_services/1/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          services = json.decode(response.body);
        });
      } else {
        setState(() {
          hasError = true;
        });
        showError("Erreur lors du chargement des services : ${response.body}", context);
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      showError("Erreur de connexion au serveur.", context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des services"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Erreur de chargement",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchServices,
              child: const Text("Réessayer"),
            ),
          ],
        ),
      )
          : services.isEmpty
          ? const Center(
        child: Text(
          "Aucun service trouvé.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['intitule_service'] ?? "Nom indisponible",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Prix : ${service['prix']?.toString() ?? 'Non défini'} €"),
                        Text("Temps : ${service['temps_minutes']?.toString() ?? 'Non défini'} min"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Modifier"),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditServicePage(
                                service: service,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchServices();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         //Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
//         //+++++++++++++++++++++++++++++++++++++A modifier (supprimer) plutard++++++++++++++++++++++++++++++++++++++
//         Uri.parse('http://192.168.0.202:8000/api/coiffeuse_services/1/'),
//         //+++++++++++++++++++++++++++++++++++++A modifier plutard++++++++++++++++++++++++++++++++++++++
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
//         showError("Erreur lors du chargement des services : ${response.body}",context);
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//       showError("Erreur de connexion au serveur.",context);
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   // void _showError(String message) {
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     SnackBar(
//   //       content: Text(
//   //         message,
//   //         style: const TextStyle(color: Colors.white),
//   //       ),
//   //       backgroundColor: Colors.red,
//   //     ),
//   //   );
//   // }
//
//   Future<void> _refreshData() async {
//     await _fetchServices();
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
//               onPressed: _fetchServices,
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
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             columns: const [
//               DataColumn(label: Text("Nom du service")),
//               DataColumn(label: Text("Prix (€)")),
//               DataColumn(label: Text("Temps (minutes)")),
//               DataColumn(label: Text("Actions")),
//             ],
//             rows: services.map((service) {
//               return DataRow(cells: [
//                 DataCell(
//                     Text(service['intitule_service'] ?? "Nom indisponible")),
//                 DataCell(Text(service['prix']?.toString() ?? "Non défini")),
//                 DataCell(Text(service['temps_minutes']?.toString() ??
//                     "Non défini")),
//                 DataCell(
//                   IconButton(
//                     icon: const Icon(Icons.edit),
//                     onPressed: () async {
//                       final result = await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               EditServicePage(
//                                 service: service,
//                               ),
//                         ),
//                       );
//                       if (result == true) {
//                         // Rafraîchir la liste après modification
//                         _fetchServices();
//                       }
//                     },
//                   ),
//                 ),
//               ]);
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }

class EditServicePage extends StatefulWidget {
  final dynamic service;

  const EditServicePage({Key? key, required this.service}) : super(key: key);

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController durationController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.service['intitule_service']);
    descriptionController =
        TextEditingController(text: widget.service['description']);
    priceController =
        TextEditingController(text: widget.service['prix']?.toString() ?? '');
    durationController = TextEditingController(
        text: widget.service['temps_minutes']?.toString() ?? '');
  }

  // Future<void> _saveChanges() async {
  //   if (nameController.text.isEmpty ||
  //       descriptionController.text.isEmpty ||
  //       priceController.text.isEmpty ||
  //       durationController.text.isEmpty) {
  //     _showError("Tous les champs sont obligatoires.");
  //     return;
  //   }
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     final response = await http.put(
  //       Uri.parse('http://127.0.0.1:8000/api/add_or_update_service/${widget
  //           .service['idTblService']}/'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({
  //         'intitule_service': nameController.text,
  //         'description': descriptionController.text,
  //         'prix': double.parse(priceController.text),
  //         'temps_minutes': int.parse(durationController.text),
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Service mis à jour avec succès."),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //       Navigator.pop(
  //           context, true); // Indique que les modifications ont été réussies
  //     } else {
  //       _showError("Erreur lors de la mise à jour : ${response.body}");
  //     }
  //   } catch (e) {
  //     _showError("Erreur de connexion au serveur.");
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  //
  // void _showError(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         message,
  //         style: const TextStyle(color: Colors.white),
  //       ),
  //       backgroundColor: Colors.red,
  //     ),
  //   );
  // }

  Future<void> _saveChanges() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty ||
        durationController.text.isEmpty) {
      showError("Tous les champs sont obligatoires.",context);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = widget.service['idTblService'] != null
          ? 'http://192.168.0.202:8000/api/add_or_update_service/${widget
          .service['idTblService']}/'
          : 'http://192.168.0.202:8000/api/add_or_update_service/';

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'intitule_service': nameController.text,
          'description': descriptionController.text,
          'temps_minutes': int.parse(durationController.text),
          'prix': double.parse(priceController.text),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Service mis à jour avec succès."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retour avec succès
      } else {
        showError("Erreur lors de la mise à jour : ${response.body}",context);
      }
    } catch (e) {
      showError("Erreur de connexion au serveur.",context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(
  title: const Text("Modifier le service"),
  ),
  body: isLoading
  ? const Center(child: CircularProgressIndicator())
      : Padding(
  padding: const EdgeInsets.all(16.0),
  child: SingleChildScrollView(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
  TextField(
  controller: nameController,
  decoration: const InputDecoration(
  labelText: "Nom du service",
  border: OutlineInputBorder(),
  ),
  ),
  const SizedBox(height: 10),
  TextField(
  controller: descriptionController,
  maxLines: 3,
  decoration: const InputDecoration(
  labelText: "Description",
  border: OutlineInputBorder(),
  ),
  ),
  const SizedBox(height: 10),
  TextField(
  controller: priceController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
  labelText: "Prix (€)",
  border: OutlineInputBorder(),
  ),
  ),
  const SizedBox(height: 10),
  TextField(
  controller: durationController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
  labelText: "Durée (minutes)",
  border: OutlineInputBorder(),
  ),
  ),
  const SizedBox(height: 20),
  ElevatedButton(
  onPressed: _saveChanges,
  child: const Text("Enregistrer les modifications"),
  ),
  ],
  ),
  ),
  ),
  );
  }
  }





// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
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
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
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
//               onPressed: _fetchServices,
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
//           : SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           columns: const [
//             DataColumn(label: Text("Nom du service")),
//             DataColumn(label: Text("Prix (€)")),
//             DataColumn(label: Text("Temps (minutes)")),
//             DataColumn(label: Text("Actions")),
//           ],
//           rows: services.map((service) {
//             return DataRow(cells: [
//               DataCell(Text(service['intitule_service'] ?? "Nom indisponible")),
//               DataCell(Text(service['prix']?.toString() ?? "Non défini")),
//               DataCell(Text(service['temps_minutes']?.toString() ?? "Non défini")),
//               DataCell(
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => EditServicePage(
//                           service: service,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ]);
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
//
// class EditServicePage extends StatefulWidget {
//   final dynamic service;
//
//   const EditServicePage({Key? key, required this.service}) : super(key: key);
//
//   @override
//   State<EditServicePage> createState() => _EditServicePageState();
// }
//
// class _EditServicePageState extends State<EditServicePage> {
//   late TextEditingController nameController;
//   late TextEditingController descriptionController;
//   late TextEditingController priceController;
//   late TextEditingController durationController;
//
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController(text: widget.service['intitule_service']);
//     descriptionController = TextEditingController(text: widget.service['description']);
//     priceController = TextEditingController(text: widget.service['prix']?.toString() ?? '');
//     durationController = TextEditingController(text: widget.service['temps_minutes']?.toString() ?? '');
//   }
//
//   Future<void> _saveChanges() async {
//     if (nameController.text.isEmpty ||
//         descriptionController.text.isEmpty ||
//         priceController.text.isEmpty ||
//         durationController.text.isEmpty) {
//       _showError("Tous les champs sont obligatoires.");
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       final response = await http.post(
//         Uri.parse('http://127.0.0.1:8000/api/update_service/${widget.service['idTblService']}/'),
//         body: json.encode({
//           'name': nameController.text,
//           'description': descriptionController.text,
//           'price': double.parse(priceController.text),
//           'minutes': int.parse(durationController.text),
//         }),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               "Service mis à jour avec succès.",
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       } else {
//         _showError("Erreur lors de la mise à jour : ${response.body}");
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
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           "Erreur : $message\nURL : http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/",
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Modifier le service"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(labelText: "Nom du service"),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: descriptionController,
//               maxLines: 3,
//               decoration: const InputDecoration(labelText: "Description"),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: priceController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: "Prix (€)"),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: durationController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: "Durée (minutes)"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _saveChanges,
//               child: const Text("Enregistrer les modifications"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, this.coiffeuseId = "1"}) : super(key: key);
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
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ServicesListPage(coiffeuseId: "1"), // Passer un ID valide
//         ),
//       );
//       //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'));
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
//   void _showError(String message) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => EditServicePage(service: null,),
//         ),
//       );
//     });
//   }
//
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
//               onPressed: _fetchServices,
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
//           : SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           columns: const [
//             DataColumn(label: Text("Nom du service")),
//             DataColumn(label: Text("Prix (€)")),
//             DataColumn(label: Text("Temps (minutes)")),
//             DataColumn(label: Text("Actions")),
//           ],
//           rows: services.map((service) {
//             return DataRow(cells: [
//               DataCell(Text(service['intitule_service'] ?? "Nom indisponible")),
//               DataCell(Text(service['prix'] ?? "Non défini")),
//               DataCell(Text(service['temps_minutes']?.toString() ?? "Non défini")),
//               DataCell(
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => EditServicePage(
//                           service: service,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ]);
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
//
//
//
// class EditServicePage extends StatefulWidget {
//   final dynamic service; // Les détails du service à modifier
//
//   const EditServicePage({Key? key, required this.service}) : super(key: key);
//
//   @override
//   State<EditServicePage> createState() => _EditServicePageState();
// }
//
// class _EditServicePageState extends State<EditServicePage> {
//   late TextEditingController nameController;
//   late TextEditingController descriptionController;
//   late TextEditingController priceController;
//   late TextEditingController durationController;
//
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController(text: widget.service['intitule_service']);
//     descriptionController = TextEditingController(text: widget.service['description']);
//     priceController = TextEditingController(text: widget.service['prix']?.toString() ?? '');
//     durationController = TextEditingController(text: widget.service['temps_minutes']?.toString() ?? '');
//   }
//
//   Future<void> _saveChanges() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       final response = await http.post(
//         Uri.parse('http://127.0.0.1:8000/api/update_service/${widget.service['idTblService']}/'),
//         body: json.encode({
//           'name': nameController.text,
//           'description': descriptionController.text,
//           'price': double.parse(priceController.text),
//           'minutes': int.parse(durationController.text),
//         }),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               "Service mis à jour avec succès.",
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       } else {
//         _showError("Erreur lors de la mise à jour : ${response.body}");
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Modifier le service"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(labelText: "Nom du service"),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: descriptionController,
//               maxLines: 3,
//               decoration: const InputDecoration(labelText: "Description"),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: priceController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: "Prix (€)"),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: durationController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: "Durée (minutes)"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _saveChanges,
//               child: const Text("Enregistrer les modifications"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId; // ID de la coiffeuse
//
//   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   // Changer plutard
//   //const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//   const ServicesListPage({Key? key, this.coiffeuseId="1"}) : super(key: key);
//   // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'));
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
//               onPressed: _fetchServices,
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
//           : ListView.builder(
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final service = services[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//             child: ListTile(
//               title: Text(
//                 service['intitule_service'] ?? "Nom indisponible",
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Description : ${service['description'] ?? 'Non disponible'}"),
//                   const SizedBox(height: 4),
//                   Text("Durée : ${service['temps']?['minutes'] ?? '-'} minutes"),
//                   Text("Prix : ${service['prix']?['prix'] ?? '-'} €"),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
