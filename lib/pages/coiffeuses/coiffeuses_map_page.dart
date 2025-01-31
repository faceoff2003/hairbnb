import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hairbnb/pages/salon/salon_services_list/salon_coiffeuse_page.dart';
import '../../services/providers/api_location_service.dart';
import '../../services/providers/location_service.dart';
import '../../models/coiffeuse.dart';

class CoiffeusesListPage extends StatefulWidget {
  @override
  _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
}

class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
  List<dynamic> coiffeuses = [];
  Position? _currentPosition;
  double _searchRadius = 10.0; // Distance par défaut en km

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  /// 🔍 Récupérer la position de l'utilisateur
  Future<void> _loadUserLocation() async {
    try {
      Position? position = await LocationService.getUserLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        _fetchCoiffeuses();

        print("Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
      }
    } catch (e) {
      print("Erreur lors de la récupération de la position : $e");
    }
  }

  /// 📡 Charger la liste des coiffeuses à proximité
  Future<void> _fetchCoiffeuses() async {
    if (_currentPosition == null) return;

    try {
      List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _searchRadius,
      );

      setState(() {
        coiffeuses = nearbyCoiffeuses;
      });
    } catch (e) {
      print("Erreur lors de la récupération des coiffeuses : $e");
    }
  }

  /// 🏁 Calculer la distance entre l'utilisateur et une coiffeuse
  double _calculateDistance(String position) {
    try {
      List<String> pos = position.split(',');
      double lat = double.parse(pos[0]);
      double lon = double.parse(pos[1]);

      return Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lon,
      ) / 1000; // Convertir en km
    } catch (e) {
      print("Erreur de calcul de distance : $e");
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coiffeuses à proximité"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCoiffeuses, // 🔄 Rafraîchir la liste
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🎛️ Barre de filtre de distance
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

          // 📋 Liste des coiffeuses
          Expanded(
            child: coiffeuses.isEmpty
                ? const Center(child: Text("Aucune coiffeuse trouvée."))
                : ListView.builder(
              itemCount: coiffeuses.length,
              itemBuilder: (context, index) {
                final coiffeuseJson = coiffeuses[index];

                // 🔄 Transformer en objet `Coiffeuse`
                Coiffeuse coiffeuse = Coiffeuse.fromJson(coiffeuseJson);

                // // 📜 Extraire et transformer les services
                // List<Service> services = [];
                // if (coiffeuseJson['services'] != null) {
                //   services = (coiffeuseJson['services'] as List)
                //       .map((service) => Service.fromJson(service))
                //       .toList();
                // }

                // 🔢 Calculer la distance
                double distance = _calculateDistance(coiffeuse.position ?? "");

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: coiffeuse.photoProfil != null &&
                          coiffeuse.photoProfil!.isNotEmpty
                          ? NetworkImage('http://192.168.0.248:8000${coiffeuse.photoProfil}')
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) {
                        print("Erreur de chargement de l'image : $exception");
                      },
                    ),
                    title: Text(
                      "${coiffeuse.nom} ${coiffeuse.prenom}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Distance : ${distance.toStringAsFixed(1)} km"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // 🚀 Aller vers la page du salon avec les objets `Coiffeuse` et `List<Service>`
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalonCoiffeusePage(
                              coiffeuse: coiffeuse
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text("Voir Profil"),
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



// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import '../../services/providers/api_location_service.dart';
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
//   double _searchRadius = 10.0; // Distance par défaut en km
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserLocation();
//   }
//
//   /// 🔍 Récupérer la position de l'utilisateur
//   Future<void> _loadUserLocation() async {
//     try {
//
//       Position? position = await LocationService.getUserLocation();
//       if (position != null) {
//         setState(() {
//           _currentPosition = position;
//         });
//         _fetchCoiffeuses();
//
//         print("Position actuelle : Latitude = ${_currentPosition?.latitude}, Longitude = ${_currentPosition?.longitude}");
//
//       }
//     } catch (e) {
//       print("Erreur lors de la récupération de la position : $e");
//     }
//   }
//
//   /// 📡 Charger la liste des coiffeuses à proximité
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
//
//       setState(() {
//         coiffeuses = nearbyCoiffeuses;
//       });
//     } catch (e) {
//       print("Erreur lors de la récupération des coiffeuses : $e");
//     }
//   }
//
//   /// 🏁 Calculer la distance entre l'utilisateur et une coiffeuse
//   double _calculateDistance(String position) {
//     try {
//       List<String> pos = position.split(',');
//       double lat = double.parse(pos[0]);
//       double lon = double.parse(pos[1]);
//
//       return Geolocator.distanceBetween(
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
//         lat,
//         lon,
//       ) /
//           1000; // Convertir en km
//     } catch (e) {
//       print("Erreur de calcul de distance : $e");
//       return 0.0;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Coiffeuses à proximité"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchCoiffeuses, // 🔄 Rafraîchir la liste
//           ),
//         ],
//       ),
//       body: _currentPosition == null
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           // 🎛️ Barre de filtre de distance
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
//           // 📋 Liste des coiffeuses
//           Expanded(
//             child: coiffeuses.isEmpty
//                 ? const Center(child: Text("Aucune coiffeuse trouvée."))
//                 : ListView.builder(
//               itemCount: coiffeuses.length,
//               itemBuilder: (context, index) {
//                 final coiffeuse = coiffeuses[index];
//
//                 // 🔢 Calculer la distance
//                 double distance = _calculateDistance(coiffeuse['position']);
//                 //-------------------------------------------------------------------------------------------
//                 print("URL de l'image de la coiffeuse: ${coiffeuse['user']['photo_profil']}");
//                 //--------------------------------------------------------------------------------------------
//
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: coiffeuse!['user']['photo_profil'] != null &&
//                           coiffeuse!['user']['photo_profil'].isNotEmpty
//                           ? NetworkImage('http://192.168.0.248:8000${coiffeuse['user']['photo_profil']}')
//                             : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                     onBackgroundImageError: (exception, stackTrace) {
//                       print("Erreur de chargement de l'image : $exception");
//                     },
//                     ),
//                     title: Text(
//                       "${coiffeuse['user']['nom']} ${coiffeuse['user']['prenom']}",
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text("Distance : ${distance.toStringAsFixed(1)} km"),
//                     trailing: ElevatedButton(
//                       onPressed: () {
//                         // 🚀 Aller vers le profil de la coiffeuse
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuse),
//                           ),
//                         );
//
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
