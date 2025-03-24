import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/services/providers/api_location_service.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/services/providers/location_service.dart';
import 'package:hairbnb/widgets/Custom_app_bar.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import '../salon/salon_services_list/salon_coiffeuse_page.dart';
import '../chat/chat_page.dart';
import '../../models/coiffeuse.dart';

class CoiffeusesListPage extends StatefulWidget {
  @override
  _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
}

class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
  List<dynamic> coiffeuses = [];
  Position? _currentPosition;
  double _searchRadius = 10.0;
  late CurrentUser? currentUser;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      Position? position = await LocationService.getUserLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        _fetchCoiffeuses();
      }
    } catch (e) {
      print("❌ Erreur de récupération de la position : $e");
    }
  }

  Future<void> _fetchCoiffeuses() async {
    if (_currentPosition == null) return;

    try {
      List<dynamic> nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _searchRadius,
      );

      currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

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

  double _calculateDistance(String coiffeusePosition) {
    try {
      List<String> pos = coiffeusePosition.split(',');
      double lat = double.parse(pos[0]);
      double lon = double.parse(pos[1]);

      return _currentPosition == null
          ? 0.0
          : Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lon) /
          1000;
    } catch (e) {
      print("❌ Erreur de calcul de distance : $e");
      return 0.0;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
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
          Expanded(
            child: coiffeuses.isEmpty
                ? const Center(child: Text("Aucune coiffeuse trouvée."))
                : ListView.builder(
              itemCount: coiffeuses.length,
              itemBuilder: (context, index) {
                final coiffeuse = coiffeuses[index];
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
                        CircleAvatar(
                          backgroundImage:
                          coiffeuse['user']['photo_profil'] != null &&
                              coiffeuse['user']['photo_profil'].isNotEmpty
                              ? NetworkImage('https://www.hairbnb.site${coiffeuse['user']['photo_profil']}')
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          onBackgroundImageError: (_, __) =>
                              print("Erreur de chargement d'image"),
                        ),
                        const SizedBox(width: 10),
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
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.person, color: Colors.orange),
                              onPressed: () {
                                final coiffeuseObj = Coiffeuse.fromJson(coiffeuse);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SalonCoiffeusePage(coiffeuse: coiffeuseObj),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.blue),
                              onPressed: () {
                                final uuid = currentUser?.uuid;
                                if (uuid == null) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      currentUser: currentUser!,
                                      otherUserId: coiffeuse['user']['uuid'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}














// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:provider/provider.dart';
// import '../../models/coiffeuse.dart';
// import '../../services/providers/api_location_service.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../services/providers/location_service.dart';
// import '../salon/salon_services_list/salon_coiffeuse_page.dart';
// import '../chat/chat_page.dart';
//
// class CoiffeusesListPage extends StatefulWidget {
//   @override
//   _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
// }
//
// class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
//   List<dynamic> coiffeuses = [];
//   Position? _currentPosition;
//   double _searchRadius = 10.0; // Rayon de recherche par défaut en km
//   late CurrentUser? currentUser;
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
//   /// 📡 **Charger la liste des coiffeuses à proximité**
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
//       print("📡 Coiffeuses trouvées : ${nearbyCoiffeuses.length}");
//
//       // Récupérer l'UUID du current user
//       currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//       // Filtrer pour exclure l'utilisateur actuel s'il est coiffeuse
//       nearbyCoiffeuses = nearbyCoiffeuses.where((coiffeuse) {
//         return coiffeuse['user']['uuid'] != currentUser!.uuid;
//       }).toList();
//
//       setState(() {
//         coiffeuses = nearbyCoiffeuses;
//       });
//     } catch (e) {
//       print("❌ Erreur lors de la récupération des coiffeuses : $e");
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
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
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
//       appBar: CustomAppBar(),
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
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Row(
//                       children: [
//                         // 🟢 Avatar de la coiffeuse
//                         CircleAvatar(
//                           backgroundImage: coiffeuse['user']['photo_profil'] != null &&
//                               coiffeuse['user']['photo_profil'].isNotEmpty
//                               ? NetworkImage('https://www.hairbnb.site${coiffeuse['user']['photo_profil']}')
//                               : const AssetImage('https://www.hairbnb.site/'+"media/photos/defaults/avatar.png") as ImageProvider,
//                           onBackgroundImageError: (exception, stackTrace) {
//                             print("❌ Erreur de chargement de l'image : $exception");
//                           },
//                         ),
//                         const SizedBox(width: 10),
//
//                         // 🟢 Informations de la coiffeuse
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "${coiffeuse['user']['nom']} ${coiffeuse['user']['prenom']}",
//                                 style: const TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               Text("Distance : ${distance.toStringAsFixed(1)} km"),
//                             ],
//                           ),
//                         ),
//
//                         // 🟢 Boutons sur PC, Icônes sur Android
//                         Row(
//                           children: [
//                             if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)
//                               ...[
//                                 // Icônes pour Android/iOS/Web
//                                 IconButton(
//                                   icon: const Icon(Icons.person, color: Colors.orange),
//                                   onPressed: () {
//                                     final coiffeuseObj = Coiffeuse.fromJson(coiffeuse);
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuseObj),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.message, color: Colors.blue),
//                                   onPressed: () {
//                                     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//                                     final currentUserUUID = currentUserProvider.currentUser?.uuid;
//
//                                     if (currentUserUUID == null) {
//                                       print("❌ Erreur : Aucun utilisateur connecté.");
//                                       return;
//                                     }
//
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => ChatPage(
//                                           currentUser: currentUser!,
//                                           otherUserId: coiffeuse['user']['uuid'],
//                                           //coiffeuseName: "${currentUserProvider.currentUser?.nom} ${currentUserProvider.currentUser?.prenom}",
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ]
//                             else
//                               ...[
//                                 // Boutons pour d'autres plateformes
//                                 ElevatedButton(
//                                   onPressed: () {
//                                     final coiffeuseObj = Coiffeuse.fromJson(coiffeuse);
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => SalonCoiffeusePage(coiffeuse: coiffeuseObj),
//                                       ),
//                                     );
//                                   },
//                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//                                   child: const Text("Voir Profil"),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 ElevatedButton(
//                                   onPressed: () {
//                                     //final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//                                     //final currentUserUUID = currentUserProvider.currentUser?.uuid;
//
//                                     if (currentUser!.uuid == null) {
//                                       print("❌ Erreur : Aucun utilisateur connecté.");
//                                       return;
//                                     }
//
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => ChatPage(
//                                           currentUser: currentUser!,
//                                           otherUserId: coiffeuse['user']['uuid'],
//                                           //coiffeuseName: "${currentUserProvider.currentUser?.nom} ${currentUserProvider.currentUser?.prenom}",
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   child: const Text("Contacter"),
//                                 ),
//                               ]
//                           ],
//                         )
//
//                       ],
//                     ),
//                   ),
//                 );
//
//
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }