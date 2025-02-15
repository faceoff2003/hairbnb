import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/widgets/Custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../models/coiffeuse.dart';
import '../../services/providers/api_location_service.dart';
import '../../services/providers/current_user_provider.dart';
import '../../services/providers/location_service.dart';
import '../salon/salon_services_list/salon_coiffeuse_page.dart';
import '../chat/chat_page.dart';

class CoiffeusesListPage extends StatefulWidget {
  @override
  _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
}

class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
  List<dynamic> coiffeuses = [];
  Position? _currentPosition;
  double _searchRadius = 10.0; // Rayon de recherche par défaut en km
  late CurrentUser? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  /// 🔍 **Récupérer la position actuelle de l'utilisateur**
  Future<void> _loadUserLocation() async {
    try {
      Position? position = await LocationService.getUserLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        _fetchCoiffeuses();
        print("📍 Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
      }
    } catch (e) {
      print("❌ Erreur de récupération de la position : $e");
    }
  }

  /// 📡 **Charger la liste des coiffeuses à proximité**
  Future<void> _fetchCoiffeuses() async {
    if (_currentPosition == null) return;

    try {
      List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _searchRadius,
      );

      print("📡 Coiffeuses trouvées : ${nearbyCoiffeuses.length}");

      // Récupérer l'UUID du current user
      currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

      // Filtrer pour exclure l'utilisateur actuel s'il est coiffeuse
      nearbyCoiffeuses = nearbyCoiffeuses.where((coiffeuse) {
        return coiffeuse['user']['uuid'] != currentUser!.uuid;
      }).toList();

      setState(() {
        coiffeuses = nearbyCoiffeuses;
      });
    } catch (e) {
      print("❌ Erreur lors de la récupération des coiffeuses : $e");
    }
  }

  /// 🏁 **Calculer la distance entre l'utilisateur et une coiffeuse**
  double _calculateDistance(String coiffeusePosition) {
    try {
      List<String> pos = coiffeusePosition.split(',');
      double coiffeuseLat = double.parse(pos[0]);
      double coiffeuseLon = double.parse(pos[1]);

      if (_currentPosition == null) return 0.0;

      return Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        coiffeuseLat,
        coiffeuseLon,
      ) / 1000; // Convertir en km
    } catch (e) {
      print("❌ Erreur de calcul de distance : $e");
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🎛️ **Barre de filtre de distance**
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                const Text("Filtrer par distance (km) :"),
                Slider(
                  value: _searchRadius,
                  min: 1,
                  max: 50,
                  divisions: 10,
                  label: "${_searchRadius.toInt()} km",
                  onChanged: (value) {
                    setState(() {
                      _searchRadius = value;
                    });
                    _fetchCoiffeuses();
                  },
                ),
              ],
            ),
          ),

          // 📋 **Liste des coiffeuses**
          Expanded(
            child: coiffeuses.isEmpty
                ? const Center(child: Text("Aucune coiffeuse trouvée."))
                : ListView.builder(
              itemCount: coiffeuses.length,
              itemBuilder: (context, index) {
                final coiffeuse = coiffeuses[index];

                // 🔢 **Calcul de la distance entre la position actuelle et la coiffeuse**
                double distance = _calculateDistance(coiffeuse['position']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // 🟢 Avatar de la coiffeuse
                        CircleAvatar(
                          backgroundImage: coiffeuse['user']['photo_profil'] != null &&
                              coiffeuse['user']['photo_profil'].isNotEmpty
                              ? NetworkImage('https://www.hairbnb.site${coiffeuse['user']['photo_profil']}')
                              : const AssetImage('https://www.hairbnb.site/'+"media/photos/defaults/avatar.png") as ImageProvider,
                          onBackgroundImageError: (exception, stackTrace) {
                            print("❌ Erreur de chargement de l'image : $exception");
                          },
                        ),
                        const SizedBox(width: 10),

                        // 🟢 Informations de la coiffeuse
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${coiffeuse['user']['nom']} ${coiffeuse['user']['prenom']}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("Distance : ${distance.toStringAsFixed(1)} km"),
                            ],
                          ),
                        ),

                        // 🟢 Boutons sur PC, Icônes sur Android
                        Row(
                          children: [
                            if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)
                              ...[
                                // Icônes pour Android/iOS/Web
                                IconButton(
                                  icon: const Icon(Icons.person, color: Colors.orange),
                                  onPressed: () {
                                    final coiffeuseObj = Coiffeuse.fromJson(coiffeuse);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuseObj),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.message, color: Colors.blue),
                                  onPressed: () {
                                    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
                                    final currentUserUUID = currentUserProvider.currentUser?.uuid;

                                    if (currentUserUUID == null) {
                                      print("❌ Erreur : Aucun utilisateur connecté.");
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          currentUser: currentUser!,
                                          otherUserId: coiffeuse['user']['uuid'],
                                          //coiffeuseName: "${currentUserProvider.currentUser?.nom} ${currentUserProvider.currentUser?.prenom}",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ]
                            else
                              ...[
                                // Boutons pour d'autres plateformes
                                ElevatedButton(
                                  onPressed: () {
                                    final coiffeuseObj = Coiffeuse.fromJson(coiffeuse);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuseObj),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  child: const Text("Voir Profil"),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    //final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
                                    //final currentUserUUID = currentUserProvider.currentUser?.uuid;

                                    if (currentUser!.uuid == null) {
                                      print("❌ Erreur : Aucun utilisateur connecté.");
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          currentUser: currentUser!,
                                          otherUserId: coiffeuse['user']['uuid'],
                                          //coiffeuseName: "${currentUserProvider.currentUser?.nom} ${currentUserProvider.currentUser?.prenom}",
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Contacter"),
                                ),
                              ]
                          ],
                        )

                      ],
                    ),
                  ),
                );


              },
            ),
          ),
        ],
      ),
    );
  }
}

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

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:provider/provider.dart';
// import '../../models/coiffeuse.dart';
// import '../../services/providers/api_location_service.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../services/providers/location_service.dart';
// import '../salon/salon_services_list/salon_coiffeuse_page.dart';
//
// class CoiffeusesListPage extends StatefulWidget {
//   @override
//   _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
// }
//
// class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
//   List<dynamic> coiffeuses = [];
//   Position? _currentPosition;
//   double _searchRadius = 10.0; // Rayon par défaut en km
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserLocation();
//   }
//
//   /// 🔍 **Récupérer la position actuelle de l'utilisateur**
//   Future<void> _loadUserLocation() async {
//     try {
//       Position? position = await LocationService.getUserLocation();
//       if (position != null) {
//         setState(() {
//           _currentPosition = position;
//         });
//         _fetchCoiffeuses();
//         print("📍 Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
//       }
//     } catch (e) {
//       print("❌ Erreur de récupération de la position : $e");
//     }
//   }
//
//   /// 📡 **Charger la liste des coiffeuses à proximité en fonction de la position actuelle**
//   Future<void> _fetchCoiffeuses() async {
//     if (_currentPosition == null) return;
//
//     try {
//       List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
//         _searchRadius,
//       );
//
//       print("Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
//
//       // Récupérer l'identifiant du current user
//       final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//       final currentUserId = currentUserProvider.currentUser?.idTblUser;
//
//       // Filtrer pour exclure la coiffeuse qui est le current user
//       nearbyCoiffeuses = nearbyCoiffeuses.where((coiffeuse) {
//         return coiffeuse['idTblUser'] != currentUserId;
//       }).toList();
//
//       setState(() {
//         coiffeuses = nearbyCoiffeuses;
//       });
//     } catch (e) {
//       print("Erreur lors de la récupération des coiffeuses : $e");
//     }
//   }
//
//   /// 🏁 **Calculer la distance entre l'utilisateur et une coiffeuse**
//   double _calculateDistance(String coiffeusePosition) {
//     try {
//       List<String> pos = coiffeusePosition.split(',');
//       double coiffeuseLat = double.parse(pos[0]);
//       double coiffeuseLon = double.parse(pos[1]);
//
//       if (_currentPosition == null) return 0.0;
//
//       return Geolocator.distanceBetween(
//         _currentPosition!.latitude, // ✅ Position actuelle
//         _currentPosition!.longitude, // ✅ Position actuelle
//         coiffeuseLat,
//         coiffeuseLon,
//       ) / 1000; // Convertir en km
//     } catch (e) {
//       print("❌ Erreur de calcul de distance : $e");
//       return 0.0;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(), // Utilisation de la CustomAppBar
//       body: _currentPosition == null
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           // 🎛️ **Barre de filtre de distance**
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 const Text("Filtrer par distance (km) :"),
//                 Slider(
//                   value: _searchRadius,
//                   min: 1,
//                   max: 50,
//                   divisions: 10,
//                   label: "${_searchRadius.toInt()} km",
//                   onChanged: (value) {
//                     setState(() {
//                       _searchRadius = value;
//                     });
//                     _fetchCoiffeuses();
//                   },
//                 ),
//               ],
//             ),
//           ),
//
//           // 📋 **Liste des coiffeuses**
//           Expanded(
//             child: coiffeuses.isEmpty
//                 ? const Center(child: Text("Aucune coiffeuse trouvée."))
//                 : ListView.builder(
//               itemCount: coiffeuses.length,
//               itemBuilder: (context, index) {
//                 final coiffeuse = coiffeuses[index];
//
//                 // 🔢 **Calcul de la distance entre la position actuelle et la coiffeuse**
//                 double distance = _calculateDistance(coiffeuse['position']);
//
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: coiffeuse['user']['photo_profil'] != null &&
//                           coiffeuse['user']['photo_profil'].isNotEmpty
//                           ? NetworkImage('http://192.168.0.248:8000${coiffeuse['user']['photo_profil']}')
//                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                       onBackgroundImageError: (exception, stackTrace) {
//                         print("❌ Erreur de chargement de l'image : $exception");
//                       },
//                     ),
//                     title: Text(
//                       "${coiffeuse['user']['nom']} ${coiffeuse['user']['prenom']}",
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text("Distance : ${distance.toStringAsFixed(1)} km"),
//                     trailing: ElevatedButton(
//                       onPressed: () {
//                         // 🚀 Convertir la Map en instance de Coiffeuse
//                         final coiffeuseObj = Coiffeuse.fromJson(coiffeuse);
//
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuseObj),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                       ),
//                       child: const Text("Voir Profil"),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
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
// ///------------------------------Code fonctionnelle aprés update------------------------------------
// // import 'package:flutter/material.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:provider/provider.dart';
// // import '../../models/coiffeuse.dart';
// // import '../../services/providers/api_location_service.dart';
// // import '../../services/providers/current_user_provider.dart';
// // import '../../services/providers/location_service.dart';
// // import '../salon/salon_services_list/salon_coiffeuse_page.dart';
// //
// // class CoiffeusesListPage extends StatefulWidget {
// //   @override
// //   _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
// // }
// //
// // class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
// //   List<dynamic> coiffeuses = [];
// //   Position? _currentPosition;
// //   double _searchRadius = 10.0; // Rayon par défaut en km
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadUserLocation();
// //   }
// //
// //   /// 🔍 **Récupérer la position actuelle de l'utilisateur**
// //   Future<void> _loadUserLocation() async {
// //     try {
// //       Position? position = await LocationService.getUserLocation();
// //       if (position != null) {
// //         setState(() {
// //           _currentPosition = position;
// //         });
// //         _fetchCoiffeuses();
// //         print("📍 Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
// //       }
// //     } catch (e) {
// //       print("❌ Erreur de récupération de la position : $e");
// //     }
// //   }
// //
// //   /// 📡 **Charger la liste des coiffeuses à proximité en fonction de la position actuelle**
// //   Future<void> _fetchCoiffeuses() async {
// //     if (_currentPosition == null) return;
// //
// //     try {
// //       List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //         _searchRadius,
// //       );
// //
// //       print("Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
// //
// //       // Récupérer l'identifiant du current user
// //       final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// //       final currentUserId = currentUserProvider.currentUser?.idTblUser;
// //
// //       // Filtrer pour exclure la coiffeuse qui est le current user
// //       nearbyCoiffeuses = nearbyCoiffeuses.where((coiffeuse) {
// //         return coiffeuse['idTblUser'] != currentUserId;
// //       }).toList();
// //
// //       setState(() {
// //         coiffeuses = nearbyCoiffeuses;
// //       });
// //     } catch (e) {
// //       print("Erreur lors de la récupération des coiffeuses : $e");
// //     }
// //   }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //   // Future<void> _fetchCoiffeuses() async {
// //   //   if (_currentPosition == null) {
// //   //     print("⚠️ Position actuelle indisponible.");
// //   //     return;
// //   //   }
// //   //
// //   //   try {
// //   //     List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
// //   //       _currentPosition!.latitude,
// //   //       _currentPosition!.longitude,
// //   //       _searchRadius,
// //   //     );
// //   //
// //   //     setState(() {
// //   //       coiffeuses = nearbyCoiffeuses;
// //   //     });
// //   //
// //   //     print("📡 Coiffeuses trouvées : ${coiffeuses.length}");
// //   //   } catch (e) {
// //   //     print("❌ Erreur lors du chargement des coiffeuses : $e");
// //   //   }
// //   // }
// //
// //   /// 🏁 **Calculer la distance entre l'utilisateur et une coiffeuse**
// //   double _calculateDistance(String coiffeusePosition) {
// //     try {
// //       List<String> pos = coiffeusePosition.split(',');
// //       double coiffeuseLat = double.parse(pos[0]);
// //       double coiffeuseLon = double.parse(pos[1]);
// //
// //       if (_currentPosition == null) return 0.0;
// //
// //       return Geolocator.distanceBetween(
// //         _currentPosition!.latitude, // ✅ Position actuelle
// //         _currentPosition!.longitude, // ✅ Position actuelle
// //         coiffeuseLat,
// //         coiffeuseLon,
// //       ) / 1000; // Convertir en km
// //     } catch (e) {
// //       print("❌ Erreur de calcul de distance : $e");
// //       return 0.0;
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Coiffeuses à proximité"),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh),
// //             onPressed: _fetchCoiffeuses, // 🔄 Rafraîchir la liste
// //           ),
// //         ],
// //       ),
// //       body: _currentPosition == null
// //           ? const Center(child: CircularProgressIndicator())
// //           : Column(
// //         children: [
// //           // 🎛️ **Barre de filtre de distance**
// //           Padding(
// //             padding: const EdgeInsets.all(10.0),
// //             child: Column(
// //               children: [
// //                 const Text("Filtrer par distance (km) :"),
// //                 Slider(
// //                   value: _searchRadius,
// //                   min: 1,
// //                   max: 50,
// //                   divisions: 10,
// //                   label: "${_searchRadius.toInt()} km",
// //                   onChanged: (value) {
// //                     setState(() {
// //                       _searchRadius = value;
// //                     });
// //                     _fetchCoiffeuses();
// //                   },
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           // 📋 **Liste des coiffeuses**
// //           Expanded(
// //             child: coiffeuses.isEmpty
// //                 ? const Center(child: Text("Aucune coiffeuse trouvée."))
// //                 : ListView.builder(
// //               itemCount: coiffeuses.length,
// //               itemBuilder: (context, index) {
// //                 final coiffeuse = coiffeuses[index];
// //
// //                 // 🔢 **Calcul de la distance entre la position actuelle et la coiffeuse**
// //                 double distance = _calculateDistance(coiffeuse['position']);
// //
// //                 return Card(
// //                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   child: ListTile(
// //                     leading: CircleAvatar(
// //                       backgroundImage: coiffeuse['user']['photo_profil'] != null &&
// //                           coiffeuse['user']['photo_profil'].isNotEmpty
// //                           ? NetworkImage('http://192.168.0.248:8000${coiffeuse['user']['photo_profil']}')
// //                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
// //                       onBackgroundImageError: (exception, stackTrace) {
// //                         print("❌ Erreur de chargement de l'image : $exception");
// //                       },
// //                     ),
// //                     title: Text(
// //                       "${coiffeuse['user']['nom']} ${coiffeuse['user']['prenom']}",
// //                       style: const TextStyle(fontWeight: FontWeight.bold),
// //                     ),
// //                     subtitle: Text("Distance : ${distance.toStringAsFixed(1)} km"),
// //                     trailing: ElevatedButton(
// //                       onPressed: () {
// //                         // 🚀 Convertir la Map en instance de Coiffeuse
// //                         final coiffeuseObj = Coiffeuse.fromJson(coiffeuse);
// //
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuseObj),
// //                           ),
// //                         );
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.orange,
// //                       ),
// //                       child: const Text("Voir Profil"),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
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
// // import 'package:geolocator/geolocator.dart';
// // import '../../services/providers/api_location_service.dart';
// // import '../../services/providers/location_service.dart';
// // import '../../models/coiffeuse.dart';
// // import '../salon/salon_services_list/salon_coiffeuse_page.dart';
// //
// // class CoiffeusesListPage extends StatefulWidget {
// //   @override
// //   _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
// // }
// //
// // class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
// //   List<dynamic> coiffeuses = [];
// //   Position? _currentPosition;
// //   double _searchRadius = 10.0; // Distance par défaut en km
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadUserLocation();
// //   }
// //
// //   /// 🔍 Récupérer la position de l'utilisateur
// //   Future<void> _loadUserLocation() async {
// //     try {
// //       Position? position = await LocationService.getUserLocation();
// //       if (position != null) {
// //         setState(() {
// //           _currentPosition = position;
// //         });
// //         _fetchCoiffeuses();
// //
// //         print("Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
// //       }
// //     } catch (e) {
// //       print("Erreur lors de la récupération de la position : $e");
// //     }
// //   }
// //
// //   /// 📡 Charger la liste des coiffeuses à proximité
// //   Future<void> _fetchCoiffeuses() async {
// //     if (_currentPosition == null) return;
// //
// //     try {
// //       List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //         _searchRadius,
// //       );
// //
// //       setState(() {
// //         coiffeuses = nearbyCoiffeuses;
// //       });
// //     } catch (e) {
// //       print("Erreur lors de la récupération des coiffeuses : $e");
// //     }
// //   }
// //
// //   /// 🏁 Calculer la distance entre l'utilisateur et une coiffeuse
// //   double _calculateDistance(String position) {
// //     try {
// //       List<String> pos = position.split(',');
// //       double lat = double.parse(pos[0]);
// //       double lon = double.parse(pos[1]);
// //
// //       return Geolocator.distanceBetween(
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //         lat,
// //         lon,
// //       ) / 1000; // Convertir en km
// //     } catch (e) {
// //       print("Erreur de calcul de distance : $e");
// //       return 0.0;
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Coiffeuses à proximité"),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh),
// //             onPressed: _fetchCoiffeuses, // 🔄 Rafraîchir la liste
// //           ),
// //         ],
// //       ),
// //       body: _currentPosition == null
// //           ? const Center(child: CircularProgressIndicator())
// //           : Column(
// //         children: [
// //           // 🎛️ Barre de filtre de distance
// //           Padding(
// //             padding: const EdgeInsets.all(10.0),
// //             child: Column(
// //               children: [
// //                 const Text("Filtrer par distance (km) :"),
// //                 Slider(
// //                   value: _searchRadius,
// //                   min: 1,
// //                   max: 50,
// //                   divisions: 10,
// //                   label: "${_searchRadius.toInt()} km",
// //                   onChanged: (value) {
// //                     setState(() {
// //                       _searchRadius = value;
// //                     });
// //                     _fetchCoiffeuses();
// //                   },
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           // 📋 Liste des coiffeuses
// //           Expanded(
// //             child: coiffeuses.isEmpty
// //                 ? const Center(child: Text("Aucune coiffeuse trouvée."))
// //                 : ListView.builder(
// //               itemCount: coiffeuses.length,
// //               itemBuilder: (context, index) {
// //                 final coiffeuseJson = coiffeuses[index];
// //
// //                 // 🔄 Transformer en objet `Coiffeuse`
// //                 Coiffeuse coiffeuse = Coiffeuse.fromJson(coiffeuseJson);
// //
// //                 // // 📜 Extraire et transformer les services
// //                 // List<Service> services = [];
// //                 // if (coiffeuseJson['services'] != null) {
// //                 //   services = (coiffeuseJson['services'] as List)
// //                 //       .map((service) => Service.fromJson(service))
// //                 //       .toList();
// //                 // }
// //
// //                 // 🔢 Calculer la distance
// //                 double distance = _calculateDistance(coiffeuse.position ?? "");
// //
// //                 return Card(
// //                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   child: ListTile(
// //                     leading: CircleAvatar(
// //                       backgroundImage: coiffeuse.photoProfil != null &&
// //                           coiffeuse.photoProfil!.isNotEmpty
// //                           ? NetworkImage('http://192.168.0.248:8000${coiffeuse.photoProfil}')
// //                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
// //                       onBackgroundImageError: (exception, stackTrace) {
// //                         print("Erreur de chargement de l'image : $exception");
// //                       },
// //                     ),
// //                     title: Text(
// //                       "${coiffeuse.nom} ${coiffeuse.prenom}",
// //                       style: const TextStyle(fontWeight: FontWeight.bold),
// //                     ),
// //                     subtitle: Text("Distance : ${distance.toStringAsFixed(1)} km"),
// //                     trailing: ElevatedButton(
// //                       onPressed: () {
// //                         // 🚀 Aller vers la page du salon avec les objets `Coiffeuse` et `List<Service>`
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) => SalonCoiffeusePage(
// //                               coiffeuse: coiffeuse
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.orange,
// //                       ),
// //                       child: const Text("Voir Profil"),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
// //---------------------------------------------------------le code en bas est fonctionel-----------------------------------------------------
// // import 'package:flutter/material.dart';
// // import 'package:geolocator/geolocator.dart';
// // import '../../services/providers/api_location_service.dart';
// // import '../../services/providers/location_service.dart';
// // import '../salon/salon_services_list/salon_coiffeuse_page.dart';
// //
// // class CoiffeusesListPage extends StatefulWidget {
// //   @override
// //   _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
// // }
// //
// // class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
// //   List<dynamic> coiffeuses = [];
// //   Position? _currentPosition;
// //   double _searchRadius = 10.0; // Distance par défaut en km
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadUserLocation();
// //   }
// //
// //   /// 🔍 Récupérer la position de l'utilisateur
// //   Future<void> _loadUserLocation() async {
// //     try {
// //
// //       Position? position = await LocationService.getUserLocation();
// //       if (position != null) {
// //         setState(() {
// //           _currentPosition = position;
// //         });
// //         _fetchCoiffeuses();
// //
// //         print("Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
// //
// //       }
// //     } catch (e) {
// //       print("Erreur lors de la récupération de la position : $e");
// //     }
// //   }
// //
// //   /// 📡 Charger la liste des coiffeuses à proximité
// //   Future<void> _fetchCoiffeuses() async {
// //     if (_currentPosition == null) return;
// //
// //     try {
// //       List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //         _searchRadius,
// //       );
// //
// //       print("Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
// //
// //
// //       setState(() {
// //         coiffeuses = nearbyCoiffeuses;
// //       });
// //     } catch (e) {
// //       print("Erreur lors de la récupération des coiffeuses : $e");
// //     }
// //   }
// //
// //   /// 🏁 Calculer la distance entre l'utilisateur et une coiffeuse
// //   double _calculateDistance(String position) {
// //     try {
// //       List<String> pos = position.split(',');
// //       double lat = double.parse(pos[0]);
// //       double lon = double.parse(pos[1]);
// //
// //       return Geolocator.distanceBetween(
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //         lat,
// //         lon,
// //       ) /
// //           1000; // Convertir en km
// //     } catch (e) {
// //       print("Erreur de calcul de distance : $e");
// //       return 0.0;
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Coiffeuses à proximité"),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh),
// //             onPressed: _fetchCoiffeuses, // 🔄 Rafraîchir la liste
// //           ),
// //         ],
// //       ),
// //       body: _currentPosition == null
// //           ? const Center(child: CircularProgressIndicator())
// //           : Column(
// //         children: [
// //           // 🎛️ Barre de filtre de distance
// //           Padding(
// //             padding: const EdgeInsets.all(10.0),
// //             child: Column(
// //               children: [
// //                 const Text("Filtrer par distance (km) :"),
// //                 Slider(
// //                   value: _searchRadius,
// //                   min: 1,
// //                   max: 50,
// //                   divisions: 10,
// //                   label: "${_searchRadius.toInt()} km",
// //                   onChanged: (value) {
// //                     setState(() {
// //                       _searchRadius = value;
// //                     });
// //                     _fetchCoiffeuses();
// //                   },
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           // 📋 Liste des coiffeuses
// //           Expanded(
// //             child: coiffeuses.isEmpty
// //                 ? const Center(child: Text("Aucune coiffeuse trouvée."))
// //                 : ListView.builder(
// //               itemCount: coiffeuses.length,
// //               itemBuilder: (context, index) {
// //                 final coiffeuse = coiffeuses[index];
// //
// //                 // 🔢 Calculer la distance
// //                 double distance = _calculateDistance(coiffeuse['position']);
// //                 //-------------------------------------------------------------------------------------------
// //                 print("URL de l'image de la coiffeuse: ${coiffeuse['user']['photo_profil']}");
// //                 //--------------------------------------------------------------------------------------------
// //
// //                 return Card(
// //                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   child: ListTile(
// //                     leading: CircleAvatar(
// //                       backgroundImage: coiffeuse!['user']['photo_profil'] != null &&
// //                           coiffeuse!['user']['photo_profil'].isNotEmpty
// //                           ? NetworkImage('http://192.168.0.248:8000${coiffeuse['user']['photo_profil']}')
// //                             : const AssetImage('assets/default_avatar.png') as ImageProvider,
// //                     onBackgroundImageError: (exception, stackTrace) {
// //                       print("Erreur de chargement de l'image : $exception");
// //                     },
// //                     ),
// //                     title: Text(
// //                       "${coiffeuse['user']['nom']} ${coiffeuse['user']['prenom']}",
// //                       style: const TextStyle(fontWeight: FontWeight.bold),
// //                     ),
// //                     subtitle: Text("Distance : ${distance.toStringAsFixed(1)} km"),
// //                     trailing: ElevatedButton(
// //                       onPressed: () {
// //                         // 🚀 Aller vers le profil de la coiffeuse
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuse),
// //                           ),
// //                         );
// //
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.orange,
// //                       ),
// //                       child: const Text("Voir Profil"),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
