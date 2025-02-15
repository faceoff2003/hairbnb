import 'package:flutter/material.dart';
import 'package:hairbnb/pages/salon/salon_services_list/promotion/create_promotion_page.dart';
import 'package:hairbnb/services/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/Services.dart';
import '../../../services/providers/current_user_provider.dart';
import 'edit_service_page.dart';
import 'add_service_page.dart';

class ServicesListPage extends StatefulWidget {
  final String coiffeuseId;

  const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  List<Service> services = [];
  List<Service> filteredServices = [];
  TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool hasError = false;
  late String? currentUserId;
  late final Service service;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchServices();
    _searchController.addListener(() {
      _filterServices(_searchController.text);
    });
  }

  /// **📌 Récupérer l'ID de l'utilisateur actuel**
  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    setState(() {
      currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
    });

    debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
  }

  /// **📡 Charger les services de la coiffeuse**
  Future<void> _fetchServices() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
          setState(() {
            services = (responseData['salon']['services'] as List)
                .map((json) {
              try {
                return Service.fromJson(json);
              } catch (e) {
                //--------------------------------------------------------------
                debugPrint("❌ show services list : Erreur JSON -> Service : $e");
                //--------------------------------------------------------------
                //debugPrint("❌ Erreur JSON -> Service : $e");
                return null;
              }
            })
                .whereType<Service>()
                .toList();
            filteredServices = List.from(services);
          });
        } else {
          _showError("Format incorrect des données reçues.");
        }
      } else {
        _showError("Erreur serveur: Code ${response.statusCode}");
      }
    } catch (e) {
      _showError("Erreur de connexion au serveur : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// **🔍 Filtrer les services selon la recherche**
  void _filterServices(String query) {
    setState(() {
      filteredServices = services
          .where((service) =>
      service.intitule.toLowerCase().contains(query.toLowerCase()) ||
          (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// **🗑️ Supprimer un service**
  Future<void> _deleteService(int serviceId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        _fetchServices();
      } else {
        _showError("Erreur lors de la suppression.");
      }
    } catch (e) {
      _showError("Erreur de connexion au serveur.");
    }
  }

  /// **🛒 Ajouter un service au panier**
  void _ajouterAuPanier(Service service) {
    Provider.of<CartProvider>(context, listen: false).addToCart(service,currentUserId!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
    );
      //---------------------------------------------------------------------------------
      print('id service dans _ajouterAuPanier est : ${service.id}');
      //---------------------------------------------------------------------------------

  }

  /// **⚠️ Afficher une erreur**
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  void _showCreatePromotionModal(Service service) {
    final serviceId=service.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Pour permettre à la modal de prendre plus d'espace si nécessaire
      backgroundColor: Colors.transparent, // Pour que les coins arrondis du Container apparaissent
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Gérer le clavier
          child: CreatePromotionModal(serviceId: serviceId),
        );
      },
    ).then((value) {
      if (value == true) {
        _fetchServices();
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
          ).then((_) => _fetchServices());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
          : services.isEmpty
          ? const Center(child: Text("Aucun service trouvé."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: filteredServices.length,
          itemBuilder: (context, index) {
            final service = filteredServices[index];
            final color = Colors.primaries[index % Colors.primaries.length][100];
            return Card(
              color: color,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.cut, color: Colors.orange),
                ),
                title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Durée: ${service.temps} min"),
                    Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
                    if (service.promotion != null) ...[
                      Text("Prix: ${service.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
                      Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ] else ...[
                      Text("Prix: ${service.prix}€"),
                    ],
                  ],
                ),
                trailing: isOwner
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () {
                      _showCreatePromotionModal(service);
                    }),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => EditServicePage(service: service, onServiceUpdated: _fetchServices),
                      ));
                    }),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
                  ],
                )
                    : IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
              ),
            );
          },
        ),
      ),
    );
  }
}

















// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_list/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart'; // ✅ Page pour ajouter un service
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
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'ID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) {
//               try {
//                 return Service.fromJson(json);
//               } catch (e) {
//                 debugPrint("❌ Erreur JSON -> Service : $e");
//                 return null;
//               }
//             })
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//           ).then((_) => _fetchServices());
//         },
//         child: const Icon(Icons.add),
//         backgroundColor: Colors.orange,
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView.builder(
//           itemCount: filteredServices.length,
//           itemBuilder: (context, index) {
//             final service = filteredServices[index];
//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 8.0),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.white,
//                   child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                 ),
//                 title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (service.promotion != null) ...[
//                       Text("Prix: ${service.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                       Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                     ] else ...[
//                       Text("Prix: ${service.prix}€"),
//                     ],
//                   ],
//                 ),
//                 trailing: isOwner
//                     ? Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(
//                         builder: (context) => CreatePromotionPage(serviceId: service.id),
//                       )).then((_) => _fetchServices());
//                     }),
//                     IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(
//                         builder: (context) => EditServicePage(service: service, onServiceUpdated: _fetchServices),
//                       ));
//                     }),
//                     IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                   ],
//                 )
//                     : IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//

















//
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart'; // Import de la page d'ajout
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
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'ID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString(); // Assure que c'est bien un String
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       debugPrint("🔗 Envoi de la requête à : $url");
//
//       final response = await http.get(url);
//
//       debugPrint("🔍 Statut HTTP : ${response.statusCode}");
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//
//         debugPrint("📥 Réponse reçue : $responseData");
//
//         if (responseData['status'] == 'success') {
//           // ✅ Vérification de la structure des données
//           if (responseData.containsKey('salon') && responseData['salon'].containsKey('services')) {
//             setState(() {
//               services = (responseData['salon']['services'] as List)
//                   .map((json) {
//                 try {
//                   return Service.fromJson(json);
//                 } catch (e) {
//                   debugPrint("❌ Erreur lors de la conversion JSON -> Service : $e");
//                   return null; // Évite un crash si un service est invalide
//                 }
//               })
//                   .whereType<Service>() // Supprime les valeurs null
//                   .toList();
//
//               filteredServices = List.from(services);
//             });
//           } else {
//             _showError("Format incorrect des données reçues.");
//           }
//         } else {
//           _showError("Erreur API: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//       debugPrint("❌ Exception Flutter : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier ✅"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           service.promotion != null
//                               ? Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text("Prix: ${service.prix}€", style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                               Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                             ],
//                           )
//                               : Text("Prix: ${service.prix}€"),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? IconButton(icon: Icon(Icons.edit), onPressed: () => print("Modifier"))
//                           : IconButton(icon: Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










//------------------------ce code fonction mais il faut rajouter les promotions-----------------
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart'; // Import de la page d'ajout
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
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'ID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString(); // Assure que c'est bien un String
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier ✅"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       )
//                           : IconButton(
//                         icon: const Icon(Icons.shopping_cart, color: Colors.green),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(
//                 coiffeuseId: widget.coiffeuseId,
//                 onServiceAdded: _fetchServices, // 🔥 Correction ajoutée ici
//               ),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       )
//           : null,
//
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
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
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'UUID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString(); // Assure que c'est bien un String
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier ✅"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       )
//                           : IconButton(
//                         icon: const Icon(Icons.shopping_cart, color: Colors.green),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }








//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
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
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late int currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'UUID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser!.idTblUser; // Stocke l'UUID de l'utilisateur connecté
//     });
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     // 🔧 Ajouter ici la logique pour le panier (Exemple: appeler une API ou stocker localement)
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier !"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     print("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId.toString() == widget.coiffeuseId.toString();
//
//
//     //----------------------------------------------------------------------------------------
//     print('le id de current user est : '+currentUserId.toString());
//     print('le id de current la coiffeuse est : '+widget.coiffeuseId);
//
//     //-----------------------------------------------------------------------------------------
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: currentUserId == widget.coiffeuseId
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       )
//                           : IconButton(
//                         icon: const Icon(Icons.shopping_cart, color: Colors.green),
//                         //onPressed: () => _ajouterAuPanier(service),
//                           onPressed: ()
//                           {
//                             Provider.of<CartProvider>(context, listen: false).addToCart(service);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text("Service ajouté au panier ✅")),
//                             );
//                           },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//






















//--------------------------------------------Code fonctionel il faut l'updater----------------------------------
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import 'edit_service_page.dart';
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
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
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
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services); // Initialise la liste affichée
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index); // Suppression instantanée dans l'UI
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices(); // Recharge si erreur
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices(); // Recharge si erreur
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId, onServiceAdded: _fetchServices),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import 'delete_service_page.dart';
// import 'edit_service_page.dart';
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
//   List<Service> services = [];
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
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Catégories", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Barre de recherche
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: "Rechercher un service...",
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.filter_list, size: 18),
//                   label: const Text("Filtrer"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Titre
//             const Text(
//               "Catégories de services",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             // Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: services.length,
//                 itemBuilder: (context, index) {
//                   final service = services[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () {
//                               setState(() {
//                                 services.removeAt(index); // 🔥 Suppression instantanée dans l'UI
//                               });
//
//                               deleteService(
//                                 context,
//                                 service.id,
//                                 _fetchServices, // 🔁 Rafraîchir en cas d'erreur
//                                     () {}, // 👌 Plus besoin de rafraîchir après suppression
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId, onServiceAdded: _fetchServices),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../../../models/Services.dart';
//
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/Services.dart';
// import 'edit_service_page.dart';
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
//   List<Service> services = [];
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
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ Service supprimé"), backgroundColor: Colors.green),
//         );
//         _fetchServices(); // Rafraîchir la liste après suppression
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Catégories")),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : ListView.builder(
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final service = services[index];
//
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
//             child: ListTile(
//               title: Text(service.intitule),
//               subtitle: Text("Prix: ${service.prix}€ | Temps: ${service.temps} min"),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.edit, color: Colors.blue),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => EditServicePage(
//                             service: service,
//                             onServiceUpdated: _fetchServices,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.red),
//                     onPressed: () => _deleteService(service.id),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }













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
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = responseData['salon']['services'];
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//         title: const Text("Catégories", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
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
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Barre de recherche
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: "Rechercher un service...",
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.filter_list, size: 18),
//                   label: const Text("Filtrer"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Titre
//             const Text(
//               "Catégories de services",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             // Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: services.length,
//                 itemBuilder: (context, index) {
//                   final service = services[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service['intitule_service'],
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Text("Prix: ${service['prix']} € | Temps: ${service['temps_minutes']} min"),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId,onServiceAdded: _fetchServices,),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }






//------------------------------------------------------------------------------

// class AddServicePage extends StatefulWidget {
//   final String coiffeuseId;
//   final Function onServiceAdded; // Ajout d'un callback pour la mise à jour
//
//   const AddServicePage({Key? key, required this.coiffeuseId, required this.onServiceAdded}) : super(key: key);
//
//   @override
//   _AddServicePageState createState() => _AddServicePageState();
// }
//
// class _AddServicePageState extends State<AddServicePage> {
//   final TextEditingController _serviceController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _prixController = TextEditingController();
//   final TextEditingController _tempsController = TextEditingController();
//   bool _isLoading = false;
//
//   Future<void> _addService() async {
//     if (_serviceController.text.isEmpty ||
//         _prixController.text.isEmpty ||
//         _tempsController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez remplir tous les champs")),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final url = Uri.parse(
//         'http://192.168.0.248:8000/api/add_service_to_coiffeuse/${widget.coiffeuseId}/');
//
//     // ✅ Utilisation de la classe Service
//     Service newService = Service(
//       id: 0, // L'ID sera défini par la base de données
//       intitule: _serviceController.text,
//       description: _descriptionController.text,
//       prix: double.parse(_prixController.text),
//       temps: int.parse(_tempsController.text), prixFinal: 0,
//     );
//
//     final body = json.encode(newService.toJson()); // ✅ Conversion en JSON
//
//     print("🚀 Envoi de la requête POST à : $url");
//     print("📩 Données envoyées : $body");
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: body,
//       );
//
//       print("✅ Réponse reçue : ${response.statusCode}");
//       print("📩 Corps de la réponse : ${response.body}");
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("✅ Service ajouté avec succès !"),
//             backgroundColor: Colors.green, // ✅ MESSAGE EN VERT
//           ),
//         );
//
//         // ✅ Mettre à jour la liste avec le nouvel objet Service
//         widget.onServiceAdded();
//
//         // Fermer la page après succès
//         Navigator.pop(context);
//       } else {
//         final responseData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("❌ Erreur: ${responseData['message']}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       print("❌ Erreur de connexion : $e");
//       ScaffoldMessenger.of(context)
//       .showSnackBar(
//         const SnackBar(
//           content: Text("Erreur de connexion au serveur."),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Ajouter un service")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//                 controller: _serviceController,
//                 decoration: const InputDecoration(labelText: "Nom du service")),
//             TextField(
//                 controller: _descriptionController,
//                 decoration: const InputDecoration(labelText: "Description")),
//             TextField(
//                 controller: _prixController,
//                 decoration: const InputDecoration(labelText: "Prix (€)"),
//                 keyboardType: TextInputType.number),
//             TextField(
//                 controller: _tempsController,
//                 decoration: const InputDecoration(labelText: "Temps (min)"),
//                 keyboardType: TextInputType.number),
//             const SizedBox(height: 20),
//             _isLoading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                 onPressed: _addService, child: const Text("Ajouter")),
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
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = responseData['salon']['services'];
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
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
//         title: const Text("Categories", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
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
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Barre de recherche
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: "Search for services...",
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.filter_list, size: 18),
//                   label: const Text("Filter"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Titre
//             const Text(
//               "Categories of services",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             // Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: services.length,
//                 itemBuilder: (context, index) {
//                   final service = services[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service['intitule_service'],
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Text("Prix: ${service['prix']} € | Temps: ${service['temps_minutes']} min"),
//                     ),
//                   );
//                 },
//               ),
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
// import 'add_service_page.dart'; // Page pour ajouter un service
// import 'package:hairbnb/models/Services.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPage();
// }
//
// class _ServicesListPage extends State<ServicesListPage> {
//   List<Service> services = [];
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
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((serviceJson) => Service.fromJson(serviceJson))
//                 .toList();
//           });
//         } else {
//           setState(() {
//             hasError = true;
//           });
//           _showError("Erreur : ${responseData['message']}");
//         }
//       } else {
//         setState(() {
//           hasError = true;
//         });
//         _showError("Erreur lors du chargement des services.");
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
//     await _fetchServices();
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
//                       service.intitule,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Description : ${service.description}"),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("Prix : ${service.prix} €"),
//                         Text("Temps : ${service.temps} min"),
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
//             _fetchServices();
//           }
//         },
//         child: const Icon(Icons.add),
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
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import '../../../services/messages/messages_page.dart';
// // import 'add_service_page.dart'; // Nouvelle page pour ajouter un service
// //
// // class ServicesListPage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<ServicesListPage> createState() => _ServicesListPageState();
// // }
// //
// // class _ServicesListPageState extends State<ServicesListPage> {
// //   List<dynamic> services = [];
// //   bool isLoading = false;
// //   bool hasError = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchServices();
// //   }
// //
// //   Future<void> _fetchServices() async {
// //     setState(() {
// //       isLoading = true;
// //       hasError = false;
// //     });
// //
// //     try {
// //       print('je suis la  ' + widget.coiffeuseId);
// //       final response = await http.get(
// //         Uri.parse('http://192.168.0.248:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
// //       );
// //
// //       if (response.statusCode == 200) {
// //         setState(() {
// //           services = json.decode(response.body);
// //         });
// //       } else {
// //         setState(() {
// //           hasError = true;
// //         });
// //         _showError("Erreur lors du chargement des services : ${response.body}");
// //       }
// //     } catch (e) {
// //       setState(() {
// //         hasError = true;
// //       });
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   Future<void> _refreshData() async {
// //     await _fetchServices();
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
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Liste des services"),
// //       ),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : hasError
// //           ? Center(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text(
// //               "Erreur de chargement",
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 10),
// //             ElevatedButton(
// //               onPressed: _fetchServices,
// //               child: const Text("Réessayer"),
// //             ),
// //           ],
// //         ),
// //       )
// //           : services.isEmpty
// //           ? const Center(
// //         child: Text(
// //           "Aucun service trouvé.",
// //           style: TextStyle(fontSize: 16),
// //         ),
// //       )
// //           : RefreshIndicator(
// //         onRefresh: _refreshData,
// //         child: ListView.builder(
// //           padding: const EdgeInsets.all(8),
// //           itemCount: services.length,
// //           itemBuilder: (context, index) {
// //             final service = services[index];
// //             return Card(
// //               elevation: 4,
// //               margin: const EdgeInsets.symmetric(vertical: 8),
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       service['intitule_service'] ?? "Nom indisponible",
// //                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text("Prix : ${service['prix']?.toString() ?? 'Non défini'} €"),
// //                         Text("Temps : ${service['temps_minutes']?.toString() ?? 'Non défini'} min"),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () async {
// //           final result = await Navigator.push(
// //             context,
// //             MaterialPageRoute(
// //               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
// //             ),
// //           );
// //
// //           if (result == true) {
// //             _fetchServices();
// //           }
// //         },
// //         child: const Icon(Icons.add),
// //       ),
// //     );
// //   }
// // }
// //
// //
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
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       final response = await http.get(
// // //         //Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
// // //         //+++++++++++++++++++++++++++++++++++++A modifier (supprimer) plutard++++++++++++++++++++++++++++++++++++++
// // //         Uri.parse('http://192.168.0.202:8000/api/coiffeuse_services/1/'),
// // //         //+++++++++++++++++++++++++++++++++++++A modifier plutard++++++++++++++++++++++++++++++++++++++
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
// // //         showError("Erreur lors du chargement des services : ${response.body}",context);
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         hasError = true;
// // //       });
// // //       showError("Erreur de connexion au serveur.",context);
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   // void _showError(String message) {
// // //   //   ScaffoldMessenger.of(context).showSnackBar(
// // //   //     SnackBar(
// // //   //       content: Text(
// // //   //         message,
// // //   //         style: const TextStyle(color: Colors.white),
// // //   //       ),
// // //   //       backgroundColor: Colors.red,
// // //   //     ),
// // //   //   );
// // //   // }
// // //
// // //   Future<void> _refreshData() async {
// // //     await _fetchServices();
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
// // //               onPressed: _fetchServices,
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
// // //         child: SingleChildScrollView(
// // //           scrollDirection: Axis.horizontal,
// // //           child: DataTable(
// // //             columns: const [
// // //               DataColumn(label: Text("Nom du service")),
// // //               DataColumn(label: Text("Prix (€)")),
// // //               DataColumn(label: Text("Temps (minutes)")),
// // //               DataColumn(label: Text("Actions")),
// // //             ],
// // //             rows: services.map((service) {
// // //               return DataRow(cells: [
// // //                 DataCell(
// // //                     Text(service['intitule_service'] ?? "Nom indisponible")),
// // //                 DataCell(Text(service['prix']?.toString() ?? "Non défini")),
// // //                 DataCell(Text(service['temps_minutes']?.toString() ??
// // //                     "Non défini")),
// // //                 DataCell(
// // //                   IconButton(
// // //                     icon: const Icon(Icons.edit),
// // //                     onPressed: () async {
// // //                       final result = await Navigator.push(
// // //                         context,
// // //                         MaterialPageRoute(
// // //                           builder: (context) =>
// // //                               EditServicePage(
// // //                                 service: service,
// // //                               ),
// // //                         ),
// // //                       );
// // //                       if (result == true) {
// // //                         // Rafraîchir la liste après modification
// // //                         _fetchServices();
// // //                       }
// // //                     },
// // //                   ),
// // //                 ),
// // //               ]);
// // //             }).toList(),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// // class EditServicePage extends StatefulWidget {
// //   final dynamic service;
// //
// //   const EditServicePage({Key? key, required this.service}) : super(key: key);
// //
// //   @override
// //   State<EditServicePage> createState() => _EditServicePageState();
// // }
// //
// // class _EditServicePageState extends State<EditServicePage> {
// //   late TextEditingController nameController;
// //   late TextEditingController descriptionController;
// //   late TextEditingController priceController;
// //   late TextEditingController durationController;
// //   bool isLoading = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     nameController =
// //         TextEditingController(text: widget.service['intitule_service']);
// //     descriptionController =
// //         TextEditingController(text: widget.service['description']);
// //     priceController =
// //         TextEditingController(text: widget.service['prix']?.toString() ?? '');
// //     durationController = TextEditingController(
// //         text: widget.service['temps_minutes']?.toString() ?? '');
// //   }
// //
// //   // Future<void> _saveChanges() async {
// //   //   if (nameController.text.isEmpty ||
// //   //       descriptionController.text.isEmpty ||
// //   //       priceController.text.isEmpty ||
// //   //       durationController.text.isEmpty) {
// //   //     _showError("Tous les champs sont obligatoires.");
// //   //     return;
// //   //   }
// //   //
// //   //   setState(() {
// //   //     isLoading = true;
// //   //   });
// //   //
// //   //   try {
// //   //     final response = await http.put(
// //   //       Uri.parse('http://127.0.0.1:8000/api/add_or_update_service/${widget
// //   //           .service['idTblService']}/'),
// //   //       headers: {'Content-Type': 'application/json'},
// //   //       body: json.encode({
// //   //         'intitule_service': nameController.text,
// //   //         'description': descriptionController.text,
// //   //         'prix': double.parse(priceController.text),
// //   //         'temps_minutes': int.parse(durationController.text),
// //   //       }),
// //   //     );
// //   //
// //   //     if (response.statusCode == 200) {
// //   //       ScaffoldMessenger.of(context).showSnackBar(
// //   //         const SnackBar(
// //   //           content: Text("Service mis à jour avec succès."),
// //   //           backgroundColor: Colors.green,
// //   //         ),
// //   //       );
// //   //       Navigator.pop(
// //   //           context, true); // Indique que les modifications ont été réussies
// //   //     } else {
// //   //       _showError("Erreur lors de la mise à jour : ${response.body}");
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
// //   //     SnackBar(
// //   //       content: Text(
// //   //         message,
// //   //         style: const TextStyle(color: Colors.white),
// //   //       ),
// //   //       backgroundColor: Colors.red,
// //   //     ),
// //   //   );
// //   // }
// //
// //   Future<void> _saveChanges() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       showError("Tous les champs sont obligatoires je ss dans show services pages.",context);
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final url = widget.service['idTblService'] != null
// //           ? 'http://192.168.0.248:8000/api/add_or_update_service/${widget
// //           .service['idTblService']}/'
// //           : 'http://192.168.0.248:8000/api/add_or_update_service/';
// //
// //       final response = await http.put(
// //         Uri.parse(url),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'temps_minutes': int.parse(durationController.text),
// //           'prix': double.parse(priceController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 200 || response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service mis à jour avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //         Navigator.pop(context, true); // Retour avec succès
// //       } else {
// //         showError("Erreur lors de la mise à jour : ${response.body}",context);
// //       }
// //     } catch (e) {
// //       showError("Erreur de connexion au serveur.",context);
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //   return Scaffold(
// //   appBar: AppBar(
// //   title: const Text("Modifier le service"),
// //   ),
// //   body: isLoading
// //   ? const Center(child: CircularProgressIndicator())
// //       : Padding(
// //   padding: const EdgeInsets.all(16.0),
// //   child: SingleChildScrollView(
// //   child: Column(
// //   crossAxisAlignment: CrossAxisAlignment.stretch,
// //   children: [
// //   TextField(
// //   controller: nameController,
// //   decoration: const InputDecoration(
// //   labelText: "Nom du service",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 10),
// //   TextField(
// //   controller: descriptionController,
// //   maxLines: 3,
// //   decoration: const InputDecoration(
// //   labelText: "Description",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 10),
// //   TextField(
// //   controller: priceController,
// //   keyboardType: TextInputType.number,
// //   decoration: const InputDecoration(
// //   labelText: "Prix (€)",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 10),
// //   TextField(
// //   controller: durationController,
// //   keyboardType: TextInputType.number,
// //   decoration: const InputDecoration(
// //   labelText: "Durée (minutes)",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 20),
// //   ElevatedButton(
// //   onPressed: _saveChanges,
// //   child: const Text("Enregistrer les modifications"),
// //   ),
// //   ],
// //   ),
// //   ),
// //   ),
// //   );
// //   }
// //   }
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
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
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       final response = await http.get(
// // //         Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
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
// // //               onPressed: _fetchServices,
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
// // //           : SingleChildScrollView(
// // //         scrollDirection: Axis.horizontal,
// // //         child: DataTable(
// // //           columns: const [
// // //             DataColumn(label: Text("Nom du service")),
// // //             DataColumn(label: Text("Prix (€)")),
// // //             DataColumn(label: Text("Temps (minutes)")),
// // //             DataColumn(label: Text("Actions")),
// // //           ],
// // //           rows: services.map((service) {
// // //             return DataRow(cells: [
// // //               DataCell(Text(service['intitule_service'] ?? "Nom indisponible")),
// // //               DataCell(Text(service['prix']?.toString() ?? "Non défini")),
// // //               DataCell(Text(service['temps_minutes']?.toString() ?? "Non défini")),
// // //               DataCell(
// // //                 IconButton(
// // //                   icon: const Icon(Icons.edit),
// // //                   onPressed: () {
// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                         builder: (context) => EditServicePage(
// // //                           service: service,
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //             ]);
// // //           }).toList(),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class EditServicePage extends StatefulWidget {
// // //   final dynamic service;
// // //
// // //   const EditServicePage({Key? key, required this.service}) : super(key: key);
// // //
// // //   @override
// // //   State<EditServicePage> createState() => _EditServicePageState();
// // // }
// // //
// // // class _EditServicePageState extends State<EditServicePage> {
// // //   late TextEditingController nameController;
// // //   late TextEditingController descriptionController;
// // //   late TextEditingController priceController;
// // //   late TextEditingController durationController;
// // //
// // //   bool isLoading = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     nameController = TextEditingController(text: widget.service['intitule_service']);
// // //     descriptionController = TextEditingController(text: widget.service['description']);
// // //     priceController = TextEditingController(text: widget.service['prix']?.toString() ?? '');
// // //     durationController = TextEditingController(text: widget.service['temps_minutes']?.toString() ?? '');
// // //   }
// // //
// // //   Future<void> _saveChanges() async {
// // //     if (nameController.text.isEmpty ||
// // //         descriptionController.text.isEmpty ||
// // //         priceController.text.isEmpty ||
// // //         durationController.text.isEmpty) {
// // //       _showError("Tous les champs sont obligatoires.");
// // //       return;
// // //     }
// // //
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('http://127.0.0.1:8000/api/update_service/${widget.service['idTblService']}/'),
// // //         body: json.encode({
// // //           'name': nameController.text,
// // //           'description': descriptionController.text,
// // //           'price': double.parse(priceController.text),
// // //           'minutes': int.parse(durationController.text),
// // //         }),
// // //         headers: {'Content-Type': 'application/json'},
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text(
// // //               "Service mis à jour avec succès.",
// // //               style: TextStyle(color: Colors.white),
// // //             ),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         Navigator.pop(context);
// // //       } else {
// // //         _showError("Erreur lors de la mise à jour : ${response.body}");
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
// // //   void _showError(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(
// // //           "Erreur : $message\nURL : http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/",
// // //           style: const TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }
// // //
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Modifier le service"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           children: [
// // //             TextField(
// // //               controller: nameController,
// // //               decoration: const InputDecoration(labelText: "Nom du service"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: descriptionController,
// // //               maxLines: 3,
// // //               decoration: const InputDecoration(labelText: "Description"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: priceController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Prix (€)"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: durationController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Durée (minutes)"),
// // //             ),
// // //             const SizedBox(height: 20),
// // //             ElevatedButton(
// // //               onPressed: _saveChanges,
// // //               child: const Text("Enregistrer les modifications"),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // //
// // // class ServicesListPage extends StatefulWidget {
// // //   final String coiffeuseId;
// // //
// // //   const ServicesListPage({Key? key, this.coiffeuseId = "1"}) : super(key: key);
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
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// // //       Navigator.push(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (context) => ServicesListPage(coiffeuseId: "1"), // Passer un ID valide
// // //         ),
// // //       );
// // //       //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// // //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'));
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
// // //   void _showError(String message) {
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       Navigator.push(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (context) => EditServicePage(service: null,),
// // //         ),
// // //       );
// // //     });
// // //   }
// // //
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
// // //               onPressed: _fetchServices,
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
// // //           : SingleChildScrollView(
// // //         scrollDirection: Axis.horizontal,
// // //         child: DataTable(
// // //           columns: const [
// // //             DataColumn(label: Text("Nom du service")),
// // //             DataColumn(label: Text("Prix (€)")),
// // //             DataColumn(label: Text("Temps (minutes)")),
// // //             DataColumn(label: Text("Actions")),
// // //           ],
// // //           rows: services.map((service) {
// // //             return DataRow(cells: [
// // //               DataCell(Text(service['intitule_service'] ?? "Nom indisponible")),
// // //               DataCell(Text(service['prix'] ?? "Non défini")),
// // //               DataCell(Text(service['temps_minutes']?.toString() ?? "Non défini")),
// // //               DataCell(
// // //                 IconButton(
// // //                   icon: const Icon(Icons.edit),
// // //                   onPressed: () {
// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                         builder: (context) => EditServicePage(
// // //                           service: service,
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //             ]);
// // //           }).toList(),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // // class EditServicePage extends StatefulWidget {
// // //   final dynamic service; // Les détails du service à modifier
// // //
// // //   const EditServicePage({Key? key, required this.service}) : super(key: key);
// // //
// // //   @override
// // //   State<EditServicePage> createState() => _EditServicePageState();
// // // }
// // //
// // // class _EditServicePageState extends State<EditServicePage> {
// // //   late TextEditingController nameController;
// // //   late TextEditingController descriptionController;
// // //   late TextEditingController priceController;
// // //   late TextEditingController durationController;
// // //
// // //   bool isLoading = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     nameController = TextEditingController(text: widget.service['intitule_service']);
// // //     descriptionController = TextEditingController(text: widget.service['description']);
// // //     priceController = TextEditingController(text: widget.service['prix']?.toString() ?? '');
// // //     durationController = TextEditingController(text: widget.service['temps_minutes']?.toString() ?? '');
// // //   }
// // //
// // //   Future<void> _saveChanges() async {
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('http://127.0.0.1:8000/api/update_service/${widget.service['idTblService']}/'),
// // //         body: json.encode({
// // //           'name': nameController.text,
// // //           'description': descriptionController.text,
// // //           'price': double.parse(priceController.text),
// // //           'minutes': int.parse(durationController.text),
// // //         }),
// // //         headers: {'Content-Type': 'application/json'},
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text(
// // //               "Service mis à jour avec succès.",
// // //               style: TextStyle(color: Colors.white),
// // //             ),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         Navigator.pop(context);
// // //       } else {
// // //         _showError("Erreur lors de la mise à jour : ${response.body}");
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
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Modifier le service"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           children: [
// // //             TextField(
// // //               controller: nameController,
// // //               decoration: const InputDecoration(labelText: "Nom du service"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: descriptionController,
// // //               maxLines: 3,
// // //               decoration: const InputDecoration(labelText: "Description"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: priceController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Prix (€)"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: durationController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Durée (minutes)"),
// // //             ),
// // //             const SizedBox(height: 20),
// // //             ElevatedButton(
// // //               onPressed: _saveChanges,
// // //               child: const Text("Enregistrer les modifications"),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // //
// // // class ServicesListPage extends StatefulWidget {
// // //   final String coiffeuseId; // ID de la coiffeuse
// // //
// // //   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// // //   // Changer plutard
// // //   //const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
// // //   const ServicesListPage({Key? key, this.coiffeuseId="1"}) : super(key: key);
// // //   // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'));
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
// // //               onPressed: _fetchServices,
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
// // //           : ListView.builder(
// // //         itemCount: services.length,
// // //         itemBuilder: (context, index) {
// // //           final service = services[index];
// // //           return Card(
// // //             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
// // //             child: ListTile(
// // //               title: Text(
// // //                 service['intitule_service'] ?? "Nom indisponible",
// // //                 style: const TextStyle(fontWeight: FontWeight.bold),
// // //               ),
// // //               subtitle: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text("Description : ${service['description'] ?? 'Non disponible'}"),
// // //                   const SizedBox(height: 4),
// // //                   Text("Durée : ${service['temps']?['minutes'] ?? '-'} minutes"),
// // //                   Text("Prix : ${service['prix']?['prix'] ?? '-'} €"),
// // //                 ],
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }
