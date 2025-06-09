// ✅ SERVICE GEOAPIFY SIMPLIFIÉ
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../pages/salon_geolocalisation/enum/enum.dart';

class GeoapifyService {
  static const String apiKey = 'b097f188b11f46d2a02eb55021d168c1';
  static const String baseUrl = 'https://api.geoapify.com/v1';

  static Future<RouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
    required TransportMode mode,
  }) async {
    try {
      String modeStr;
      switch (mode) {
        case TransportMode.drive:
          modeStr = 'drive';
          break;
        case TransportMode.walk:
          modeStr = 'walk';
          break;
        case TransportMode.bicycle:
          modeStr = 'bicycle';
          break;
        case TransportMode.transit:
          modeStr = 'transit';
          break;
      }

      final url = '$baseUrl/routing?waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&mode=$modeStr&apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final geometry = feature['geometry'];
          final properties = feature['properties'];

          List<LatLng> points = [];
          if (geometry['coordinates'] != null) {
            // Updated logic to handle different geometry types (e.g., LineString, MultiLineString)
            _parseCoordinates(geometry['coordinates'], points);
          }

          return RouteResult(
            points: points,
            distance: properties['distance']?.toDouble() ?? 0.0,
            duration: properties['time']?.toInt() ?? 0,
          );
        }
      }
    } catch (e) {
      print('❌ Erreur Geoapify routing: $e');
    }

    return null;
  }

  // Helper function to recursively parse coordinates
  static void _parseCoordinates(dynamic coords, List<LatLng> points) {
    if (coords is List && coords.isNotEmpty) {
      // Check if the first element is a list (nested coordinates)
      if (coords[0] is List) {
        // If it's a list of lists, recurse
        if (coords[0][0] is List) { // Likely a MultiLineString [[[]]]
          for (var subList in coords) {
            _parseCoordinates(subList, points);
          }
        } else { // Likely a LineString [[]]
          for (var coord in coords) {
            if (coord is List && coord.length >= 2) {
              points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
            }
          }
        }
      }
    }
  }

  static Future<List<POI>> findNearbyParking(LatLng location) async {
    try {
      final url = '$baseUrl/places?categories=parking&filter=circle:${location.longitude},${location.latitude},1000&limit=10&apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<POI> parkings = [];

        if (data['features'] != null) {
          for (var feature in data['features']) {
            final geometry = feature['geometry'];
            final properties = feature['properties'];

            if (geometry['coordinates'] != null) {
              parkings.add(POI(
                location: LatLng(
                  geometry['coordinates'][1],
                  geometry['coordinates'][0],
                ),
                name: properties['name'] ?? 'Parking',
                type: 'parking',
              ));
            }
          }
        }

        return parkings;
      }
    } catch (e) {
      print('❌ Erreur Geoapify parking: $e');
    }

    return [];
  }
}








// // ✅ SERVICE GEOAPIFY SIMPLIFIÉ
// import 'dart:convert';
//
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
//
// import '../../pages/salon_geolocalisation/enum/enum.dart';
//
// class GeoapifyService {
//   static const String apiKey = 'b097f188b11f46d2a02eb55021d168c1';
//   static const String baseUrl = 'https://api.geoapify.com/v1';
//
//   static Future<RouteResult?> getRoute({
//     required LatLng start,
//     required LatLng end,
//     required TransportMode mode,
//   }) async {
//     try {
//       String modeStr;
//       switch (mode) {
//         case TransportMode.drive:
//           modeStr = 'drive';
//           break;
//         case TransportMode.walk:
//           modeStr = 'walk';
//           break;
//         case TransportMode.bicycle:
//           modeStr = 'bicycle';
//           break;
//         case TransportMode.transit:
//           modeStr = 'transit';
//           break;
//       }
//
//       final url = '$baseUrl/routing?waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&mode=$modeStr&apiKey=$apiKey';
//
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           final feature = data['features'][0];
//           final geometry = feature['geometry'];
//           final properties = feature['properties'];
//
//           // Décoder les points de la route
//           List<LatLng> points = [];
//           if (geometry['coordinates'] != null) {
//             for (var coord in geometry['coordinates']) {
//               points.add(LatLng(coord[1], coord[0]));
//             }
//           }
//
//           return RouteResult(
//             points: points,
//             distance: properties['distance']?.toDouble() ?? 0.0,
//             duration: properties['time']?.toInt() ?? 0,
//           );
//         }
//       }
//     } catch (e) {
//       print('❌ Erreur Geoapify routing: $e');
//     }
//
//     return null;
//   }
//
//   static Future<List<POI>> findNearbyParking(LatLng location) async {
//     try {
//       final url = '$baseUrl/places?categories=parking&filter=circle:${location.longitude},${location.latitude},1000&limit=10&apiKey=$apiKey';
//
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         List<POI> parkings = [];
//
//         if (data['features'] != null) {
//           for (var feature in data['features']) {
//             final geometry = feature['geometry'];
//             final properties = feature['properties'];
//
//             if (geometry['coordinates'] != null) {
//               parkings.add(POI(
//                 location: LatLng(
//                   geometry['coordinates'][1],
//                   geometry['coordinates'][0],
//                 ),
//                 name: properties['name'] ?? 'Parking',
//                 type: 'parking',
//               ));
//             }
//           }
//         }
//
//         return parkings;
//       }
//     } catch (e) {
//       print('❌ Erreur Geoapify parking: $e');
//     }
//
//     return [];
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
// // // lib/pages/salon_geolocalisation/salon_map_page.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:hairbnb/models/salon_details_geo.dart';
// // import 'package:hairbnb/models/service_with_promo.dart';
// // import 'package:hairbnb/pages/coiffeuses/services/city_autocomplete.dart';
// // import 'package:hairbnb/pages/coiffeuses/services/geocoding_service.dart';
// // import 'package:provider/provider.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:hairbnb/services/providers/current_user_provider.dart';
// // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // import '../../pages/chat/chat_page.dart';
// // import '../../pages/coiffeuses/services/location_service.dart';
// // import '../../pages/salon_geolocalisation/api_salon_location_service.dart';
// // import '../../pages/salon_geolocalisation/itineraire_page.dart';
// // import '../../pages/salon_geolocalisation/modals/show_salon_details_modal.dart';
// // import '../../pages/salon_geolocalisation/modals/show_salon_services_modal_service/show_salon_services_modal_service.dart';
// // import '../../pages/salon_geolocalisation/widgets/build_team_preview.dart';
// // import '../../services/providers/cart_provider.dart';
// //
// // class SalonsListPage extends StatefulWidget {
// //   const SalonsListPage({super.key});
// //
// //   @override
// //   _SalonsListPageState createState() => _SalonsListPageState();
// // }
// //
// // class _SalonsListPageState extends State<SalonsListPage> {
// //   // ✅ CONSTANTE API KEY TEMPORAIRE
// //   static const String _geoapifyApiKey = 'b097f188b11f46d2a02eb55021d168c1';
// //
// //   // MODIFIÉ: Utilisation du nouveau modèle
// //   List<SalonDetailsForGeo> salons = [];
// //   Position? _currentPosition;
// //   Position? _gpsPosition;
// //   double _gpsRadius = 10.0;
// //   final TextEditingController cityController = TextEditingController();
// //   final TextEditingController distanceController = TextEditingController();
// //   bool showCitySearch = false;
// //   late CurrentUser? currentUser;
// //   int _currentIndex = 1;
// //   String? activeSearchLabel;
// //   bool isLoading = true;
// //
// //   int _itemsPerPage = 10;
// //   int _currentPage = 1;
// //
// //   final Color primaryColor = Color(0xFF8E44AD);
// //   final Color accentColor = Color(0xFFE67E22);
// //   final Color backgroundColor = Color(0xFFF5F5F5);
// //   final Color cardColor = Colors.white;
// //
// //   // MODIFIÉ: Getter avec le nouveau type
// //   List<SalonDetailsForGeo> get _paginatedSalons {
// //     if (salons.isEmpty) return [];
// //     final start = (_currentPage - 1) * _itemsPerPage;
// //     final end = _currentPage * _itemsPerPage;
// //     return salons.sublist(start, end > salons.length ? salons.length : end);
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadUserLocation();
// //   }
// //
// //   Future<void> _loadUserLocation() async {
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final position = await LocationService.getUserLocation();
// //       if (position != null) {
// //         setState(() {
// //           _gpsPosition = position;
// //           _currentPosition = position;
// //           activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
// //         });
// //         await _fetchSalons(position, _gpsRadius);
// //       }
// //     } catch (e) {
// //       print("❌ Erreur de localisation : $e");
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   Future<void> _fetchSalons(Position position, double radius) async {
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       // Utilisation de la nouvelle méthode qui retourne SalonsResponse
// //       final salonsResponse = await ApiSalonService.fetchNearbySalons(
// //         position.latitude,
// //         position.longitude,
// //         radius,
// //       );
// //
// //       currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
// //
// //       setState(() {
// //         // Récupération des salons depuis la response
// //         salons = salonsResponse.salons;
// //         _currentPage = 1;
// //         isLoading = false;
// //       });
// //     } catch (e) {
// //       print("❌ Erreur API : $e");
// //       setState(() {
// //         isLoading = false;
// //       });
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text("Impossible de charger les salons: $e"),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     }
// //   }
// //
// //   Future<void> _searchByCity() async {
// //     final city = cityController.text.trim();
// //     final distanceText = distanceController.text.trim();
// //
// //     if (city.isEmpty || distanceText.isEmpty) return;
// //
// //     final parsedDistance = double.tryParse(distanceText);
// //     if (parsedDistance == null || parsedDistance > 150) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text("Distance invalide. Maximum 150 km."),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //       return;
// //     }
// //
// //     final position = await GeocodingService.getCoordinatesFromCity(city);
// //     if (position != null) {
// //       setState(() {
// //         _currentPosition = position;
// //         activeSearchLabel = "🏙️ Autour de $city (${parsedDistance.toInt()} km)";
// //         showCitySearch = false;
// //       });
// //       await _fetchSalons(position, parsedDistance);
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text("Ville introuvable."),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     }
// //   }
// //
// //   // MODIFIÉ: Utilisation directe de la distance du modèle ou calcul si nécessaire
// //   double _calculateDistance(SalonDetailsForGeo salon) {
// //     // On utilise d'abord la distance déjà calculée par l'API
// //     return salon.distance;
// //   }
// //
// //   void _onTabTapped(int index) => setState(() => _currentIndex = index);
// //
// //   // dans le fichier salon_map_page.dart
// //   void _viewSalonDetails(SalonDetailsForGeo salon) {
// //     if (currentUser != null) {
// //       showDialog(
// //         context: context,
// //         builder: (context) => Dialog(
// //           backgroundColor: Colors.transparent,
// //           insetPadding: EdgeInsets.all(20),
// //           child: SalonDetailsModal(
// //             currentUser: currentUser!,
// //             salon: salon,
// //             calculateDistance: _calculateDistance,
// //             primaryColor: primaryColor,
// //             accentColor: accentColor,
// //           ),
// //         ),
// //       );
// //     } else {
// //       // Optionnel : Afficher un message si l'utilisateur n'est pas connecté
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text("Veuillez vous connecter pour voir les détails du salon."),
// //           backgroundColor: Colors.orange,
// //         ),
// //       );
// //     }
// //   }
// //
// //   // ✅ NOUVELLE MÉTHODE : Ouvrir la page d'itinéraire
// //   void _openItineraire(SalonDetailsForGeo salon) {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => ItinerairePage(
// //           salon: salon,
// //           primaryColor: primaryColor,
// //           accentColor: accentColor,
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: backgroundColor,
// //       appBar: AppBar(
// //         backgroundColor: primaryColor,
// //         elevation: 0,
// //         title: Text(
// //           "Salons à proximité",
// //           style: GoogleFonts.poppins(
// //             fontSize: 20,
// //             fontWeight: FontWeight.w600,
// //             color: Colors.white,
// //           ),
// //         ),
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.map_outlined, color: Colors.white),
// //             onPressed: () {
// //               // Navigator.push(
// //               //   context,
// //               //   MaterialPageRoute(builder: (context) => SalonMapView()),
// //               // );
// //             },
// //           ),
// //         ],
// //       ),
// //       body: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //             colors: [primaryColor, backgroundColor],
// //             stops: [0.0, 0.3],
// //           ),
// //         ),
// //         child: Column(
// //           children: [
// //             _buildSearchHeader(),
// //             Expanded(
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: backgroundColor,
// //                   borderRadius: BorderRadius.only(
// //                     topLeft: Radius.circular(24),
// //                     topRight: Radius.circular(24),
// //                   ),
// //                 ),
// //                 child: _buildSalonsList(),
// //               ),
// //             ),
// //             if (salons.length > _itemsPerPage) _buildPagination(),
// //           ],
// //         ),
// //       ),
// //       bottomNavigationBar: BottomNavBar(
// //         currentIndex: _currentIndex,
// //         onTap: _onTabTapped,
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSearchHeader() {
// //     return Container(
// //       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           if (activeSearchLabel != null)
// //             Container(
// //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //               margin: EdgeInsets.only(bottom: 16),
// //               decoration: BoxDecoration(
// //                 color: Colors.white30,
// //                 borderRadius: BorderRadius.circular(20),
// //               ),
// //               child: Text(
// //                 activeSearchLabel!,
// //                 style: GoogleFonts.poppins(
// //                   fontSize: 14,
// //                   fontWeight: FontWeight.w500,
// //                   color: Colors.white,
// //                 ),
// //               ),
// //             ),
// //           showCitySearch ? _buildCitySearch() : _buildGpsSearch(),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildCitySearch() {
// //     return Column(
// //       children: [
// //         Row(
// //           children: [
// //             Expanded(
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 padding: EdgeInsets.symmetric(horizontal: 8),
// //                 child: CityAutocompleteField(
// //                   controller: cityController,
// //                   // ✅ UTILISATION DE LA CONSTANTE
// //                   apiKey: _geoapifyApiKey,
// //                   onCitySelected: (ville) {},
// //                 ),
// //               ),
// //             ),
// //             SizedBox(width: 8),
// //             Container(
// //               width: 70,
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               padding: EdgeInsets.symmetric(horizontal: 8),
// //               child: TextField(
// //                 controller: distanceController,
// //                 keyboardType: TextInputType.number,
// //                 textAlign: TextAlign.center,
// //                 decoration: InputDecoration(
// //                   hintText: 'km',
// //                   border: InputBorder.none,
// //                 ),
// //               ),
// //             ),
// //             SizedBox(width: 8),
// //             CircleAvatar(
// //               backgroundColor: accentColor,
// //               child: IconButton(
// //                 icon: Icon(Icons.search, color: Colors.white),
// //                 onPressed: _searchByCity,
// //               ),
// //             ),
// //           ],
// //         ),
// //         SizedBox(height: 8),
// //         TextButton.icon(
// //           icon: Icon(Icons.my_location),
// //           label: Text("Revenir à ma position"),
// //           onPressed: () {
// //             setState(() {
// //               showCitySearch = false;
// //               if (_gpsPosition != null) {
// //                 _currentPosition = _gpsPosition;
// //                 activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
// //                 _fetchSalons(_gpsPosition!, _gpsRadius);
// //               }
// //             });
// //           },
// //           style: TextButton.styleFrom(
// //             foregroundColor: Colors.white,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildGpsSearch() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Row(
// //           children: [
// //             Text(
// //               "Rayon de recherche",
// //               style: GoogleFonts.poppins(
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.white,
// //               ),
// //             ),
// //             Expanded(
// //               child: Slider(
// //                 value: _gpsRadius,
// //                 min: 1,
// //                 max: 50,
// //                 divisions: 10,
// //                 label: "${_gpsRadius.toInt()} km",
// //                 onChanged: (val) {
// //                   setState(() {
// //                     _gpsRadius = val;
// //                     activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
// //                   });
// //                   if (_gpsPosition != null) {
// //                     _fetchSalons(_gpsPosition!, _gpsRadius);
// //                   }
// //                 },
// //                 activeColor: Colors.white,
// //                 inactiveColor: Colors.white30,
// //               ),
// //             ),
// //             Container(
// //               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //               decoration: BoxDecoration(
// //                 color: Colors.white30,
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: Text(
// //                 "${_gpsRadius.toInt()} km",
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //         SizedBox(height: 8),
// //         Center(
// //           child: TextButton.icon(
// //             icon: Icon(Icons.location_city),
// //             label: Text("Rechercher par ville"),
// //             onPressed: () {
// //               setState(() {
// //                 showCitySearch = true;
// //                 cityController.clear();
// //                 distanceController.clear();
// //               });
// //             },
// //             style: TextButton.styleFrom(
// //               foregroundColor: Colors.white,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildSalonsList() {
// //     if (isLoading) {
// //       return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
// //     }
// //
// //     if (salons.isEmpty) {
// //       return Center(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
// //             SizedBox(height: 16),
// //             Text(
// //               "Aucun salon trouvé",
// //               style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               "Essayez d'augmenter la distance ou de rechercher dans une autre zone",
// //               textAlign: TextAlign.center,
// //               style: TextStyle(color: Colors.grey[500]),
// //             ),
// //             SizedBox(height: 24),
// //             ElevatedButton.icon(
// //               onPressed: () {
// //                 if (_currentPosition != null) {
// //                   _fetchSalons(_currentPosition!, _gpsRadius);
// //                 }
// //               },
// //               icon: Icon(Icons.refresh),
// //               label: Text("Actualiser"),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: primaryColor,
// //                 foregroundColor: Colors.white,
// //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     return ListView.builder(
// //       padding: EdgeInsets.all(16),
// //       itemCount: _paginatedSalons.length,
// //       itemBuilder: (context, index) => _buildSalonCard(_paginatedSalons[index]),
// //     );
// //   }
// //
// //   // Utilisation du nouveau modèle
// //   Widget _buildSalonCard(SalonDetailsForGeo salon) {
// //     // Utilisation directe de la distance du modèle
// //     final distance = salon.distance;
// //     final coiffeuses = salon.coiffeusesDetails;
// //
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 16),
// //       decoration: BoxDecoration(
// //         color: cardColor,
// //         borderRadius: BorderRadius.circular(16),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.05),
// //             blurRadius: 10,
// //             offset: Offset(0, 4),
// //           ),
// //         ],
// //       ),
// //       child: Material(
// //         color: Colors.transparent,
// //         borderRadius: BorderRadius.circular(16),
// //         child: InkWell(
// //           onTap: () => _viewSalonDetails(salon),
// //           borderRadius: BorderRadius.circular(16),
// //           child: Padding(
// //             padding: EdgeInsets.all(16),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 _buildSalonCardHeader(salon, distance),
// //                 if (coiffeuses.isNotEmpty) buildTeamPreview(coiffeuses),
// //                 _buildCardActions(salon),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSalonCardHeader(SalonDetailsForGeo salon, double distance) {
// //     return Row(
// //       children: [
// //         Container(
// //           width: 70,
// //           height: 70,
// //           decoration: BoxDecoration(
// //             color: primaryColor.withOpacity(0.1),
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: salon.hasLogo
// //               ? ClipRRect(
// //             borderRadius: BorderRadius.circular(12),
// //             child: Image.network(
// //               salon.getLogoUrl("https://www.hairbnb.site") ?? "",
// //               fit: BoxFit.cover,
// //               errorBuilder: (ctx, obj, st) => Icon(Icons.spa, color: primaryColor, size: 30),
// //             ),
// //           )
// //               : Icon(Icons.spa, color: primaryColor, size: 30),
// //         ),
// //         SizedBox(width: 16),
// //         Expanded(
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 salon.nom,
// //                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
// //               ),
// //               if (salon.slogan != null && salon.slogan!.isNotEmpty)
// //                 Text(
// //                   salon.slogan!,
// //                   style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               SizedBox(height: 8),
// //               Container(
// //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //                 decoration: BoxDecoration(
// //                   color: accentColor.withOpacity(0.1),
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: Text(
// //                   // MODIFIÉ: Utilisation du getter distanceFormatee
// //                   salon.distanceFormatee,
// //                   style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //         Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildCardActions(SalonDetailsForGeo salon) {
// //     final coiffeuses = salon.coiffeusesDetails;
// //     CoiffeuseDetailsForGeo? contactPersonne = salon.proprietaire;
// //
// //     if (contactPersonne == null && coiffeuses.isNotEmpty) {
// //       contactPersonne = coiffeuses.first;
// //     }
// //
// //     return Padding(
// //       padding: const EdgeInsets.only(top: 16),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.end,
// //         children: [
// //           // ✅ BOUTON ITINÉRAIRE - FONCTIONNEL
// //           OutlinedButton.icon(
// //             onPressed: () => _openItineraire(salon),
// //             icon: Icon(Icons.directions, size: 16),
// //             label: Text("Itinéraire"),
// //             style: OutlinedButton.styleFrom(
// //               foregroundColor: accentColor,
// //               side: BorderSide(color: accentColor),
// //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //               visualDensity: VisualDensity.compact,
// //               textStyle: TextStyle(fontSize: 12),
// //             ),
// //           ),
// //           SizedBox(width: 8),
// //           OutlinedButton.icon(
// //             onPressed: () {
// //               if (contactPersonne != null && currentUser != null) {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (context) => ChatPage(
// //                       currentUser: currentUser!,
// //                       otherUserId: contactPersonne!.uuid,
// //                     ),
// //                   ),
// //                 );
// //               } else {
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   SnackBar(
// //                     content: Text("Aucun contact disponible pour ce salon."),
// //                     backgroundColor: Colors.red,
// //                   ),
// //                 );
// //               }
// //             },
// //             icon: Icon(Icons.chat_bubble_outline, size: 16),
// //             label: Text("Contacter"),
// //             style: OutlinedButton.styleFrom(
// //               foregroundColor: Colors.green,
// //               side: BorderSide(color: Colors.green),
// //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //               visualDensity: VisualDensity.compact,
// //               textStyle: TextStyle(fontSize: 12),
// //             ),
// //           ),
// //           SizedBox(width: 8),
// //           // 🎯 BOUTON SERVICES - VERSION CORRIGÉE avec intégration panier
// //           ElevatedButton.icon(
// //             onPressed: () async {
// //               try {
// //                 // 🔄 Afficher le modal et récupérer les services sélectionnés
// //                 final selectedServices = await SalonServicesModalService.afficherServicesModal(
// //                   context,
// //                   salon: salon,
// //                   primaryColor: primaryColor,
// //                   accentColor: accentColor,
// //                 );
// //
// //                 // ✅ Si des services ont été sélectionnés, les ajouter au panier
// //                 if (selectedServices != null && selectedServices.isNotEmpty && currentUser != null) {
// //                   final cartProvider = Provider.of<CartProvider>(context, listen: false);
// //
// //                   // 📦 Ajouter chaque service au panier via l'API
// //                   for (var service in selectedServices) {
// //                     await cartProvider.addToCart(service, currentUser!.idTblUser.toString());
// //                   }
// //
// //                   // 🎉 Afficher une notification de succès
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(
// //                       content: Text("✅ ${selectedServices.length} service(s) ajouté(s) au panier !"),
// //                       backgroundColor: Colors.green,
// //                       duration: Duration(seconds: 3),
// //                       action: SnackBarAction(
// //                         label: "Voir le panier",
// //                         textColor: Colors.white,
// //                         onPressed: () {
// //                           // 🛒 Naviguer vers la page du panier
// //                           Navigator.pushNamed(context, '/cart'); // Adaptez selon vos routes
// //                         },
// //                       ),
// //                       behavior: SnackBarBehavior.floating,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(10),
// //                       ),
// //                     ),
// //                   );
// //
// //                   print("✅ ${selectedServices.length} services ajoutés au panier pour ${salon.nom}");
// //                 } else if (currentUser == null) {
// //                   // ⚠️ Utilisateur non connecté
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(
// //                       content: Text("Veuillez vous connecter pour ajouter des services au panier."),
// //                       backgroundColor: Colors.orange,
// //                     ),
// //                   );
// //                 }
// //               } catch (e) {
// //                 // ❌ Gestion des erreurs
// //                 print("❌ Erreur lors de l'ajout au panier : $e");
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   SnackBar(
// //                     content: Text("Erreur lors de l'ajout au panier. Veuillez réessayer."),
// //                     backgroundColor: Colors.red,
// //                   ),
// //                 );
// //               }
// //             },
// //             icon: Icon(Icons.design_services, size: 16),
// //             label: Text("Services"),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: primaryColor,
// //               foregroundColor: Colors.white,
// //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //               visualDensity: VisualDensity.compact,
// //               textStyle: TextStyle(fontSize: 12),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildPagination() {
// //     return Container(
// //       color: backgroundColor,
// //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Row(
// //             children: [
// //               IconButton(
// //                 icon: Icon(Icons.arrow_back_ios, size: 16),
// //                 onPressed: _currentPage > 1
// //                     ? () => setState(() => _currentPage--)
// //                     : null,
// //                 color: primaryColor,
// //                 disabledColor: Colors.grey[300],
// //               ),
// //               Text(
// //                 "Page $_currentPage/${((salons.length - 1) / _itemsPerPage + 1).floor()}",
// //                 style: TextStyle(
// //                   color: Colors.grey[700],
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //               ),
// //               IconButton(
// //                 icon: Icon(Icons.arrow_forward_ios, size: 16),
// //                 onPressed: _currentPage * _itemsPerPage < salons.length
// //                     ? () => setState(() => _currentPage++)
// //                     : null,
// //                 color: primaryColor,
// //                 disabledColor: Colors.grey[300],
// //               ),
// //             ],
// //           ),
// //           Row(
// //             children: [
// //               Text(
// //                 "Afficher:",
// //                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// //               ),
// //               SizedBox(width: 4),
// //               Container(
// //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
// //                 decoration: BoxDecoration(
// //                   border: Border.all(color: Colors.grey[300]!),
// //                   borderRadius: BorderRadius.circular(4),
// //                 ),
// //                 child: DropdownButton<int>(
// //                   value: _itemsPerPage,
// //                   items: [5, 10, 20].map((value) {
// //                     return DropdownMenuItem<int>(
// //                       value: value,
// //                       child: Text(
// //                         '$value',
// //                         style: TextStyle(fontSize: 12),
// //                       ),
// //                     );
// //                   }).toList(),
// //                   onChanged: (value) {
// //                     if (value != null) {
// //                       setState(() {
// //                         _itemsPerPage = value;
// //                         _currentPage = 1;
// //                       });
// //                     }
// //                   },
// //                   underline: SizedBox(),
// //                   icon: Icon(Icons.arrow_drop_down, size: 18),
// //                   isDense: true,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
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
// // // // lib/pages/salon_geolocalisation/salon_map_page.dart
// // //
// // // import 'package:flutter/material.dart';
// // // import 'package:geolocator/geolocator.dart';
// // // import 'package:google_fonts/google_fonts.dart';
// // // import 'package:hairbnb/models/salon_details_geo.dart';
// // // import 'package:hairbnb/models/service_with_promo.dart';
// // // import 'package:hairbnb/pages/coiffeuses/services/city_autocomplete.dart';
// // // import 'package:hairbnb/pages/coiffeuses/services/geocoding_service.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:hairbnb/models/current_user.dart';
// // // import 'package:hairbnb/services/providers/current_user_provider.dart';
// // // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // // import '../../pages/chat/chat_page.dart';
// // // import '../../pages/coiffeuses/services/location_service.dart';
// // // import '../../pages/salon_geolocalisation/api_salon_location_service.dart';
// // // import '../../pages/salon_geolocalisation/itineraire_page.dart';
// // // import '../../pages/salon_geolocalisation/modals/show_salon_details_modal.dart';
// // // import '../../pages/salon_geolocalisation/modals/show_salon_services_modal_service/show_salon_services_modal_service.dart';
// // // import '../../pages/salon_geolocalisation/widgets/build_team_preview.dart';
// // // import '../../services/providers/cart_provider.dart';
// // // import '../../services/geoapify_service/geoapify_service.dart';
// // //
// // // class SalonsListPage extends StatefulWidget {
// // //   const SalonsListPage({super.key});
// // //
// // //   @override
// // //   _SalonsListPageState createState() => _SalonsListPageState();
// // // }
// // //
// // // class _SalonsListPageState extends State<SalonsListPage> {
// // //   // MODIFIÉ: Utilisation du nouveau modèle
// // //   List<SalonDetailsForGeo> salons = [];
// // //   Position? _currentPosition;
// // //   Position? _gpsPosition;
// // //   double _gpsRadius = 10.0;
// // //   final TextEditingController cityController = TextEditingController();
// // //   final TextEditingController distanceController = TextEditingController();
// // //   bool showCitySearch = false;
// // //   late CurrentUser? currentUser;
// // //   int _currentIndex = 1;
// // //   String? activeSearchLabel;
// // //   bool isLoading = true;
// // //
// // //   int _itemsPerPage = 10;
// // //   int _currentPage = 1;
// // //
// // //   final Color primaryColor = Color(0xFF8E44AD);
// // //   final Color accentColor = Color(0xFFE67E22);
// // //   final Color backgroundColor = Color(0xFFF5F5F5);
// // //   final Color cardColor = Colors.white;
// // //
// // //   // MODIFIÉ: Getter avec le nouveau type
// // //   List<SalonDetailsForGeo> get _paginatedSalons {
// // //     if (salons.isEmpty) return [];
// // //     final start = (_currentPage - 1) * _itemsPerPage;
// // //     final end = _currentPage * _itemsPerPage;
// // //     return salons.sublist(start, end > salons.length ? salons.length : end);
// // //   }
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadUserLocation();
// // //   }
// // //
// // //   Future<void> _loadUserLocation() async {
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       final position = await LocationService.getUserLocation();
// // //       if (position != null) {
// // //         setState(() {
// // //           _gpsPosition = position;
// // //           _currentPosition = position;
// // //           activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
// // //         });
// // //         await _fetchSalons(position, _gpsRadius);
// // //       }
// // //     } catch (e) {
// // //       print("❌ Erreur de localisation : $e");
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   Future<void> _fetchSalons(Position position, double radius) async {
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       // Utilisation de la nouvelle méthode qui retourne SalonsResponse
// // //       final salonsResponse = await ApiSalonService.fetchNearbySalons(
// // //         position.latitude,
// // //         position.longitude,
// // //         radius,
// // //       );
// // //
// // //       currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
// // //
// // //       setState(() {
// // //         // Récupération des salons depuis la response
// // //         salons = salonsResponse.salons;
// // //         _currentPage = 1;
// // //         isLoading = false;
// // //       });
// // //     } catch (e) {
// // //       print("❌ Erreur API : $e");
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Impossible de charger les salons: $e"),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //   Future<void> _searchByCity() async {
// // //     final city = cityController.text.trim();
// // //     final distanceText = distanceController.text.trim();
// // //
// // //     if (city.isEmpty || distanceText.isEmpty) return;
// // //
// // //     final parsedDistance = double.tryParse(distanceText);
// // //     if (parsedDistance == null || parsedDistance > 150) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Distance invalide. Maximum 150 km."),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //       return;
// // //     }
// // //
// // //     final position = await GeocodingService.getCoordinatesFromCity(city);
// // //     if (position != null) {
// // //       setState(() {
// // //         _currentPosition = position;
// // //         activeSearchLabel = "🏙️ Autour de $city (${parsedDistance.toInt()} km)";
// // //         showCitySearch = false;
// // //       });
// // //       await _fetchSalons(position, parsedDistance);
// // //     } else {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Ville introuvable."),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //   // MODIFIÉ: Utilisation directe de la distance du modèle ou calcul si nécessaire
// // //   double _calculateDistance(SalonDetailsForGeo salon) {
// // //     // On utilise d'abord la distance déjà calculée par l'API
// // //     return salon.distance;
// // //   }
// // //
// // //   void _onTabTapped(int index) => setState(() => _currentIndex = index);
// // //
// // //   // dans le fichier salon_map_page.dart
// // //   void _viewSalonDetails(SalonDetailsForGeo salon) {
// // //     if (currentUser != null) {
// // //       showDialog(
// // //         context: context,
// // //         builder: (context) => Dialog(
// // //           backgroundColor: Colors.transparent,
// // //           insetPadding: EdgeInsets.all(20),
// // //           child: SalonDetailsModal(
// // //             currentUser: currentUser!,
// // //             salon: salon,
// // //             calculateDistance: _calculateDistance,
// // //             primaryColor: primaryColor,
// // //             accentColor: accentColor,
// // //           ),
// // //         ),
// // //       );
// // //     } else {
// // //       // Optionnel : Afficher un message si l'utilisateur n'est pas connecté
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Veuillez vous connecter pour voir les détails du salon."),
// // //           backgroundColor: Colors.orange,
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //   // ✅ NOUVELLE MÉTHODE : Ouvrir la page d'itinéraire
// // //   void _openItineraire(SalonDetailsForGeo salon) {
// // //     Navigator.push(
// // //       context,
// // //       MaterialPageRoute(
// // //         builder: (context) => ItinerairePage(
// // //           salon: salon,
// // //           primaryColor: primaryColor,
// // //           accentColor: accentColor,
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: backgroundColor,
// // //       appBar: AppBar(
// // //         backgroundColor: primaryColor,
// // //         elevation: 0,
// // //         title: Text(
// // //           "Salons à proximité",
// // //           style: GoogleFonts.poppins(
// // //             fontSize: 20,
// // //             fontWeight: FontWeight.w600,
// // //             color: Colors.white,
// // //           ),
// // //         ),
// // //         actions: [
// // //           IconButton(
// // //             icon: Icon(Icons.map_outlined, color: Colors.white),
// // //             onPressed: () {
// // //               // Navigator.push(
// // //               //   context,
// // //               //   MaterialPageRoute(builder: (context) => SalonMapView()),
// // //               // );
// // //             },
// // //           ),
// // //         ],
// // //       ),
// // //       body: Container(
// // //         decoration: BoxDecoration(
// // //           gradient: LinearGradient(
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //             colors: [primaryColor, backgroundColor],
// // //             stops: [0.0, 0.3],
// // //           ),
// // //         ),
// // //         child: Column(
// // //           children: [
// // //             _buildSearchHeader(),
// // //             Expanded(
// // //               child: Container(
// // //                 decoration: BoxDecoration(
// // //                   color: backgroundColor,
// // //                   borderRadius: BorderRadius.only(
// // //                     topLeft: Radius.circular(24),
// // //                     topRight: Radius.circular(24),
// // //                   ),
// // //                 ),
// // //                 child: _buildSalonsList(),
// // //               ),
// // //             ),
// // //             if (salons.length > _itemsPerPage) _buildPagination(),
// // //           ],
// // //         ),
// // //       ),
// // //       bottomNavigationBar: BottomNavBar(
// // //         currentIndex: _currentIndex,
// // //         onTap: _onTabTapped,
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildSearchHeader() {
// // //     return Container(
// // //       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           if (activeSearchLabel != null)
// // //             Container(
// // //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // //               margin: EdgeInsets.only(bottom: 16),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white30,
// // //                 borderRadius: BorderRadius.circular(20),
// // //               ),
// // //               child: Text(
// // //                 activeSearchLabel!,
// // //                 style: GoogleFonts.poppins(
// // //                   fontSize: 14,
// // //                   fontWeight: FontWeight.w500,
// // //                   color: Colors.white,
// // //                 ),
// // //               ),
// // //             ),
// // //           showCitySearch ? _buildCitySearch() : _buildGpsSearch(),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildCitySearch() {
// // //     return Column(
// // //       children: [
// // //         Row(
// // //           children: [
// // //             Expanded(
// // //               child: Container(
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white,
// // //                   borderRadius: BorderRadius.circular(12),
// // //                 ),
// // //                 padding: EdgeInsets.symmetric(horizontal: 8),
// // //                 child: CityAutocompleteField(
// // //                   controller: cityController,
// // //                   apiKey: GeoapifyService.apiKey,
// // //                   onCitySelected: (ville) {},
// // //                 ),
// // //               ),
// // //             ),
// // //             SizedBox(width: 8),
// // //             Container(
// // //               width: 70,
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white,
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               padding: EdgeInsets.symmetric(horizontal: 8),
// // //               child: TextField(
// // //                 controller: distanceController,
// // //                 keyboardType: TextInputType.number,
// // //                 textAlign: TextAlign.center,
// // //                 decoration: InputDecoration(
// // //                   hintText: 'km',
// // //                   border: InputBorder.none,
// // //                 ),
// // //               ),
// // //             ),
// // //             SizedBox(width: 8),
// // //             CircleAvatar(
// // //               backgroundColor: accentColor,
// // //               child: IconButton(
// // //                 icon: Icon(Icons.search, color: Colors.white),
// // //                 onPressed: _searchByCity,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //         SizedBox(height: 8),
// // //         TextButton.icon(
// // //           icon: Icon(Icons.my_location),
// // //           label: Text("Revenir à ma position"),
// // //           onPressed: () {
// // //             setState(() {
// // //               showCitySearch = false;
// // //               if (_gpsPosition != null) {
// // //                 _currentPosition = _gpsPosition;
// // //                 activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
// // //                 _fetchSalons(_gpsPosition!, _gpsRadius);
// // //               }
// // //             });
// // //           },
// // //           style: TextButton.styleFrom(
// // //             foregroundColor: Colors.white,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildGpsSearch() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Row(
// // //           children: [
// // //             Text(
// // //               "Rayon de recherche",
// // //               style: GoogleFonts.poppins(
// // //                 fontSize: 14,
// // //                 fontWeight: FontWeight.w500,
// // //                 color: Colors.white,
// // //               ),
// // //             ),
// // //             Expanded(
// // //               child: Slider(
// // //                 value: _gpsRadius,
// // //                 min: 1,
// // //                 max: 50,
// // //                 divisions: 10,
// // //                 label: "${_gpsRadius.toInt()} km",
// // //                 onChanged: (val) {
// // //                   setState(() {
// // //                     _gpsRadius = val;
// // //                     activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
// // //                   });
// // //                   if (_gpsPosition != null) {
// // //                     _fetchSalons(_gpsPosition!, _gpsRadius);
// // //                   }
// // //                 },
// // //                 activeColor: Colors.white,
// // //                 inactiveColor: Colors.white30,
// // //               ),
// // //             ),
// // //             Container(
// // //               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white30,
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               child: Text(
// // //                 "${_gpsRadius.toInt()} km",
// // //                 style: TextStyle(
// // //                   color: Colors.white,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //         SizedBox(height: 8),
// // //         Center(
// // //           child: TextButton.icon(
// // //             icon: Icon(Icons.location_city),
// // //             label: Text("Rechercher par ville"),
// // //             onPressed: () {
// // //               setState(() {
// // //                 showCitySearch = true;
// // //                 cityController.clear();
// // //                 distanceController.clear();
// // //               });
// // //             },
// // //             style: TextButton.styleFrom(
// // //               foregroundColor: Colors.white,
// // //             ),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildSalonsList() {
// // //     if (isLoading) {
// // //       return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
// // //     }
// // //
// // //     if (salons.isEmpty) {
// // //       return Center(
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
// // //             SizedBox(height: 16),
// // //             Text(
// // //               "Aucun salon trouvé",
// // //               style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
// // //             ),
// // //             SizedBox(height: 8),
// // //             Text(
// // //               "Essayez d'augmenter la distance ou de rechercher dans une autre zone",
// // //               textAlign: TextAlign.center,
// // //               style: TextStyle(color: Colors.grey[500]),
// // //             ),
// // //             SizedBox(height: 24),
// // //             ElevatedButton.icon(
// // //               onPressed: () {
// // //                 if (_currentPosition != null) {
// // //                   _fetchSalons(_currentPosition!, _gpsRadius);
// // //                 }
// // //               },
// // //               icon: Icon(Icons.refresh),
// // //               label: Text("Actualiser"),
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: primaryColor,
// // //                 foregroundColor: Colors.white,
// // //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //     }
// // //
// // //     return ListView.builder(
// // //       padding: EdgeInsets.all(16),
// // //       itemCount: _paginatedSalons.length,
// // //       itemBuilder: (context, index) => _buildSalonCard(_paginatedSalons[index]),
// // //     );
// // //   }
// // //
// // //   // Utilisation du nouveau modèle
// // //   Widget _buildSalonCard(SalonDetailsForGeo salon) {
// // //     // Utilisation directe de la distance du modèle
// // //     final distance = salon.distance;
// // //     final coiffeuses = salon.coiffeusesDetails;
// // //
// // //     return Container(
// // //       margin: EdgeInsets.only(bottom: 16),
// // //       decoration: BoxDecoration(
// // //         color: cardColor,
// // //         borderRadius: BorderRadius.circular(16),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.05),
// // //             blurRadius: 10,
// // //             offset: Offset(0, 4),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Material(
// // //         color: Colors.transparent,
// // //         borderRadius: BorderRadius.circular(16),
// // //         child: InkWell(
// // //           onTap: () => _viewSalonDetails(salon),
// // //           borderRadius: BorderRadius.circular(16),
// // //           child: Padding(
// // //             padding: EdgeInsets.all(16),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 _buildSalonCardHeader(salon, distance),
// // //                 if (coiffeuses.isNotEmpty) buildTeamPreview(coiffeuses),
// // //                 _buildCardActions(salon),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildSalonCardHeader(SalonDetailsForGeo salon, double distance) {
// // //     return Row(
// // //       children: [
// // //         Container(
// // //           width: 70,
// // //           height: 70,
// // //           decoration: BoxDecoration(
// // //             color: primaryColor.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(12),
// // //           ),
// // //           child: salon.hasLogo
// // //               ? ClipRRect(
// // //             borderRadius: BorderRadius.circular(12),
// // //             child: Image.network(
// // //               salon.getLogoUrl("https://www.hairbnb.site") ?? "",
// // //               fit: BoxFit.cover,
// // //               errorBuilder: (ctx, obj, st) => Icon(Icons.spa, color: primaryColor, size: 30),
// // //             ),
// // //           )
// // //               : Icon(Icons.spa, color: primaryColor, size: 30),
// // //         ),
// // //         SizedBox(width: 16),
// // //         Expanded(
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Text(
// // //                 salon.nom,
// // //                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
// // //               ),
// // //               if (salon.slogan != null && salon.slogan!.isNotEmpty)
// // //                 Text(
// // //                   salon.slogan!,
// // //                   style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
// // //                   maxLines: 1,
// // //                   overflow: TextOverflow.ellipsis,
// // //                 ),
// // //               SizedBox(height: 8),
// // //               Container(
// // //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// // //                 decoration: BoxDecoration(
// // //                   color: accentColor.withOpacity(0.1),
// // //                   borderRadius: BorderRadius.circular(12),
// // //                 ),
// // //                 child: Text(
// // //                   // MODIFIÉ: Utilisation du getter distanceFormatee
// // //                   salon.distanceFormatee,
// // //                   style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //         Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildCardActions(SalonDetailsForGeo salon) {
// // //     final coiffeuses = salon.coiffeusesDetails;
// // //     CoiffeuseDetailsForGeo? contactPersonne = salon.proprietaire;
// // //
// // //     if (contactPersonne == null && coiffeuses.isNotEmpty) {
// // //       contactPersonne = coiffeuses.first;
// // //     }
// // //
// // //     return Padding(
// // //       padding: const EdgeInsets.only(top: 16),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.end,
// // //         children: [
// // //           // ✅ BOUTON ITINÉRAIRE - FONCTIONNEL
// // //           OutlinedButton.icon(
// // //             onPressed: () => _openItineraire(salon),
// // //             icon: Icon(Icons.directions, size: 16),
// // //             label: Text("Itinéraire"),
// // //             style: OutlinedButton.styleFrom(
// // //               foregroundColor: accentColor,
// // //               side: BorderSide(color: accentColor),
// // //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // //               visualDensity: VisualDensity.compact,
// // //               textStyle: TextStyle(fontSize: 12),
// // //             ),
// // //           ),
// // //           SizedBox(width: 8),
// // //           OutlinedButton.icon(
// // //             onPressed: () {
// // //               if (contactPersonne != null && currentUser != null) {
// // //                 Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(
// // //                     builder: (context) => ChatPage(
// // //                       currentUser: currentUser!,
// // //                       otherUserId: contactPersonne!.uuid,
// // //                     ),
// // //                   ),
// // //                 );
// // //               } else {
// // //                 ScaffoldMessenger.of(context).showSnackBar(
// // //                   SnackBar(
// // //                     content: Text("Aucun contact disponible pour ce salon."),
// // //                     backgroundColor: Colors.red,
// // //                   ),
// // //                 );
// // //               }
// // //             },
// // //             icon: Icon(Icons.chat_bubble_outline, size: 16),
// // //             label: Text("Contacter"),
// // //             style: OutlinedButton.styleFrom(
// // //               foregroundColor: Colors.green,
// // //               side: BorderSide(color: Colors.green),
// // //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // //               visualDensity: VisualDensity.compact,
// // //               textStyle: TextStyle(fontSize: 12),
// // //             ),
// // //           ),
// // //           SizedBox(width: 8),
// // //           // 🎯 BOUTON SERVICES - VERSION CORRIGÉE avec intégration panier
// // //           ElevatedButton.icon(
// // //             onPressed: () async {
// // //               try {
// // //                 // 🔄 Afficher le modal et récupérer les services sélectionnés
// // //                 final selectedServices = await SalonServicesModalService.afficherServicesModal(
// // //                   context,
// // //                   salon: salon,
// // //                   primaryColor: primaryColor,
// // //                   accentColor: accentColor,
// // //                 );
// // //
// // //                 // ✅ Si des services ont été sélectionnés, les ajouter au panier
// // //                 if (selectedServices != null && selectedServices.isNotEmpty && currentUser != null) {
// // //                   final cartProvider = Provider.of<CartProvider>(context, listen: false);
// // //
// // //                   // 📦 Ajouter chaque service au panier via l'API
// // //                   for (var service in selectedServices) {
// // //                     await cartProvider.addToCart(service as ServiceWithPromo, currentUser!.idTblUser.toString());
// // //                   }
// // //
// // //                   // 🎉 Afficher une notification de succès
// // //                   ScaffoldMessenger.of(context).showSnackBar(
// // //                     SnackBar(
// // //                       content: Text("✅ ${selectedServices.length} service(s) ajouté(s) au panier !"),
// // //                       backgroundColor: Colors.green,
// // //                       duration: Duration(seconds: 3),
// // //                       action: SnackBarAction(
// // //                         label: "Voir le panier",
// // //                         textColor: Colors.white,
// // //                         onPressed: () {
// // //                           // 🛒 Naviguer vers la page du panier
// // //                           Navigator.pushNamed(context, '/cart'); // Adaptez selon vos routes
// // //                         },
// // //                       ),
// // //                       behavior: SnackBarBehavior.floating,
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(10),
// // //                       ),
// // //                     ),
// // //                   );
// // //
// // //                   print("✅ ${selectedServices.length} services ajoutés au panier pour ${salon.nom}");
// // //                 } else if (currentUser == null) {
// // //                   // ⚠️ Utilisateur non connecté
// // //                   ScaffoldMessenger.of(context).showSnackBar(
// // //                     SnackBar(
// // //                       content: Text("Veuillez vous connecter pour ajouter des services au panier."),
// // //                       backgroundColor: Colors.orange,
// // //                     ),
// // //                   );
// // //                 }
// // //               } catch (e) {
// // //                 // ❌ Gestion des erreurs
// // //                 print("❌ Erreur lors de l'ajout au panier : $e");
// // //                 ScaffoldMessenger.of(context).showSnackBar(
// // //                   SnackBar(
// // //                     content: Text("Erreur lors de l'ajout au panier. Veuillez réessayer."),
// // //                     backgroundColor: Colors.red,
// // //                   ),
// // //                 );
// // //               }
// // //             },
// // //             icon: Icon(Icons.design_services, size: 16),
// // //             label: Text("Services"),
// // //             style: ElevatedButton.styleFrom(
// // //               backgroundColor: primaryColor,
// // //               foregroundColor: Colors.white,
// // //               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // //               visualDensity: VisualDensity.compact,
// // //               textStyle: TextStyle(fontSize: 12),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildPagination() {
// // //     return Container(
// // //       color: backgroundColor,
// // //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //         children: [
// // //           Row(
// // //             children: [
// // //               IconButton(
// // //                 icon: Icon(Icons.arrow_back_ios, size: 16),
// // //                 onPressed: _currentPage > 1
// // //                     ? () => setState(() => _currentPage--)
// // //                     : null,
// // //                 color: primaryColor,
// // //                 disabledColor: Colors.grey[300],
// // //               ),
// // //               Text(
// // //                 "Page $_currentPage/${((salons.length - 1) / _itemsPerPage + 1).floor()}",
// // //                 style: TextStyle(
// // //                   color: Colors.grey[700],
// // //                   fontWeight: FontWeight.w500,
// // //                 ),
// // //               ),
// // //               IconButton(
// // //                 icon: Icon(Icons.arrow_forward_ios, size: 16),
// // //                 onPressed: _currentPage * _itemsPerPage < salons.length
// // //                     ? () => setState(() => _currentPage++)
// // //                     : null,
// // //                 color: primaryColor,
// // //                 disabledColor: Colors.grey[300],
// // //               ),
// // //             ],
// // //           ),
// // //           Row(
// // //             children: [
// // //               Text(
// // //                 "Afficher:",
// // //                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// // //               ),
// // //               SizedBox(width: 4),
// // //               Container(
// // //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
// // //                 decoration: BoxDecoration(
// // //                   border: Border.all(color: Colors.grey[300]!),
// // //                   borderRadius: BorderRadius.circular(4),
// // //                 ),
// // //                 child: DropdownButton<int>(
// // //                   value: _itemsPerPage,
// // //                   items: [5, 10, 20].map((value) {
// // //                     return DropdownMenuItem<int>(
// // //                       value: value,
// // //                       child: Text(
// // //                         '$value',
// // //                         style: TextStyle(fontSize: 12),
// // //                       ),
// // //                     );
// // //                   }).toList(),
// // //                   onChanged: (value) {
// // //                     if (value != null) {
// // //                       setState(() {
// // //                         _itemsPerPage = value;
// // //                         _currentPage = 1;
// // //                       });
// // //                     }
// // //                   },
// // //                   underline: SizedBox(),
// // //                   icon: Icon(Icons.arrow_drop_down, size: 18),
// // //                   isDense: true,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // // // services/geoapify_service/geoapify_service.dart
// // // // import 'dart:convert';
// // // // import 'package:flutter/foundation.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'package:latlong2/latlong.dart';
// // // //
// // // // class GeoapifyService {
// // // //   // 🔑 REMPLACEZ par votre clé API Geoapify (gratuite sur geoapify.com)
// // // //   static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
// // // //   static const String _baseUrl = 'https://api.geoapify.com/v1';
// // // //
// // // //   // ✅ GETTER PUBLIC pour accéder à la clé API
// // // //   static String get apiKey => _apiKey;
// // // //
// // // //   /// 🛣️ Calculer un itinéraire entre deux points
// // // //   static Future<RouteResult?> getRoute({
// // // //     required LatLng start,
// // // //     required LatLng end,
// // // //     TransportMode mode = TransportMode.drive,
// // // //     bool avoidTolls = false,
// // // //     bool avoidFerries = false,
// // // //   }) async {
// // // //     try {
// // // //       final url = Uri.parse(
// // // //           '$_baseUrl/routing?'
// // // //               'waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&'
// // // //               'mode=${_getModeString(mode)}&'
// // // //               'details=instruction_details&'
// // // //               'apiKey=$_apiKey'
// // // //       );
// // // //
// // // //       if (kDebugMode) {
// // // //         print("🌐 Requête Geoapify: $url");
// // // //       }
// // // //
// // // //       final response = await http.get(url);
// // // //
// // // //       if (response.statusCode == 200) {
// // // //         final data = json.decode(response.body);
// // // //
// // // //         if (data['features'] != null && data['features'].isNotEmpty) {
// // // //           return RouteResult.fromJson(data['features'][0]);
// // // //         } else {
// // // //           print("❌ Aucun itinéraire trouvé");
// // // //           return null;
// // // //         }
// // // //       } else {
// // // //         print("❌ Erreur API Geoapify: ${response.statusCode} - ${response.body}");
// // // //         return null;
// // // //       }
// // // //     } catch (e) {
// // // //       print("❌ Exception Geoapify: $e");
// // // //       return null;
// // // //     }
// // // //   }
// // // //
// // // //   /// 📍 Rechercher une adresse (geocoding)
// // // //   static Future<List<PlaceResult>> searchAddress(String query) async {
// // // //     try {
// // // //       final url = Uri.parse(
// // // //           '$_baseUrl/geocode/search?'
// // // //               'text=${Uri.encodeComponent(query)}&'
// // // //               'limit=5&'
// // // //               'apiKey=$_apiKey'
// // // //       );
// // // //
// // // //       final response = await http.get(url);
// // // //
// // // //       if (response.statusCode == 200) {
// // // //         final data = json.decode(response.body);
// // // //         return (data['features'] as List)
// // // //             .map((feature) => PlaceResult.fromJson(feature))
// // // //             .toList();
// // // //       }
// // // //     } catch (e) {
// // // //       print("❌ Erreur geocoding: $e");
// // // //     }
// // // //
// // // //     return [];
// // // //   }
// // // //
// // // //   /// 🅿️ Trouver des parkings près d'un point
// // // //   static Future<List<POI>> findNearbyParking(LatLng center) async {
// // // //     try {
// // // //       final url = Uri.parse(
// // // //           '$_baseUrl/places?'
// // // //               'categories=parking&'
// // // //               'filter=circle:${center.longitude},${center.latitude},500&'
// // // //               'limit=10&'
// // // //               'apiKey=$_apiKey'
// // // //       );
// // // //
// // // //       final response = await http.get(url);
// // // //
// // // //       if (response.statusCode == 200) {
// // // //         final data = json.decode(response.body);
// // // //         return (data['features'] as List)
// // // //             .map((feature) => POI.fromJson(feature))
// // // //             .toList();
// // // //       }
// // // //     } catch (e) {
// // // //       print("❌ Erreur POI: $e");
// // // //     }
// // // //
// // // //     return [];
// // // //   }
// // // //
// // // //   /// 🔧 Helper : Convertir le mode de transport en string API
// // // //   static String _getModeString(TransportMode mode) {
// // // //     switch (mode) {
// // // //       case TransportMode.drive:
// // // //         return 'drive';
// // // //       case TransportMode.walk:
// // // //         return 'walk';
// // // //       case TransportMode.bicycle:
// // // //         return 'bicycle';
// // // //       case TransportMode.transit:
// // // //         return 'transit';
// // // //     }
// // // //   }
// // // // }
// // // //
// // // // /// 🚗 Modes de transport disponibles
// // // // enum TransportMode {
// // // //   drive,    // Voiture
// // // //   walk,     // Marche
// // // //   bicycle,  // Vélo
// // // //   transit,  // Transport public
// // // // }
// // // //
// // // // /// 🛣️ Résultat d'un itinéraire
// // // // class RouteResult {
// // // //   final double distance;           // Distance en mètres
// // // //   final int duration;             // Durée en secondes
// // // //   final List<LatLng> points;      // Points de la route
// // // //   final List<Instruction> instructions; // Instructions turn-by-turn
// // // //   final LatLng startPoint;
// // // //   final LatLng endPoint;
// // // //
// // // //   RouteResult({
// // // //     required this.distance,
// // // //     required this.duration,
// // // //     required this.points,
// // // //     required this.instructions,
// // // //     required this.startPoint,
// // // //     required this.endPoint,
// // // //   });
// // // //
// // // //   factory RouteResult.fromJson(Map<String, dynamic> json) {
// // // //     final properties = json['properties'];
// // // //     final geometry = json['geometry'];
// // // //
// // // //     // 📍 Extraire les coordonnées de la route - AMÉLIORÉ
// // // //     List<LatLng> routePoints = [];
// // // //     if (geometry['type'] == 'LineString') {
// // // //       final coordinates = geometry['coordinates'] as List;
// // // //       routePoints = coordinates
// // // //           .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
// // // //           .toList();
// // // //
// // // //       // ✅ DEBUG: Afficher les infos de parsing
// // // //       print("🛣️ Parsing itinéraire: ${routePoints.length} points extraits");
// // // //       print("🛣️ Premier point: ${routePoints.isNotEmpty ? routePoints.first : 'Aucun'}");
// // // //       print("🛣️ Dernier point: ${routePoints.isNotEmpty ? routePoints.last : 'Aucun'}");
// // // //     } else {
// // // //       print("❌ Type de géométrie non supporté: ${geometry['type']}");
// // // //     }
// // // //
// // // //     // 📋 Extraire les instructions
// // // //     List<Instruction> instructions = [];
// // // //     if (properties['legs'] != null) {
// // // //       final legs = properties['legs'] as List;
// // // //       for (var leg in legs) {
// // // //         if (leg['steps'] != null) {
// // // //           final steps = leg['steps'] as List;
// // // //           for (var step in steps) {
// // // //             instructions.add(Instruction.fromJson(step));
// // // //           }
// // // //         }
// // // //       }
// // // //     }
// // // //
// // // //     final result = RouteResult(
// // // //       distance: properties['distance']?.toDouble() ?? 0.0,
// // // //       duration: properties['time']?.toInt() ?? 0,
// // // //       points: routePoints,
// // // //       instructions: instructions,
// // // //       startPoint: routePoints.isNotEmpty ? routePoints.first : LatLng(0, 0),
// // // //       endPoint: routePoints.isNotEmpty ? routePoints.last : LatLng(0, 0),
// // // //     );
// // // //
// // // //     // ✅ DEBUG: Infos finales
// // // //     print("🛣️ RouteResult créé: ${result.distanceFormatted}, ${result.durationFormatted}, ${result.points.length} points");
// // // //
// // // //     return result;
// // // //   }
// // // //
// // // //   /// 📏 Distance formatée
// // // //   String get distanceFormatted {
// // // //     if (distance < 1000) {
// // // //       return '${distance.round()} m';
// // // //     }
// // // //     return '${(distance / 1000).toStringAsFixed(1)} km';
// // // //   }
// // // //
// // // //   /// ⏰ Durée formatée
// // // //   String get durationFormatted {
// // // //     final minutes = duration ~/ 60;
// // // //     if (minutes < 60) {
// // // //       return '$minutes min';
// // // //     }
// // // //     final hours = minutes ~/ 60;
// // // //     final remainingMinutes = minutes % 60;
// // // //     return '${hours}h ${remainingMinutes}min';
// // // //   }
// // // // }
// // // //
// // // // /// 📋 Instruction de navigation
// // // // class Instruction {
// // // //   final String text;
// // // //   final double distance;
// // // //   final int duration;
// // // //   final String type;
// // // //
// // // //   Instruction({
// // // //     required this.text,
// // // //     required this.distance,
// // // //     required this.duration,
// // // //     required this.type,
// // // //   });
// // // //
// // // //   factory Instruction.fromJson(Map<String, dynamic> json) {
// // // //     return Instruction(
// // // //       text: json['instruction']?.toString() ?? '',
// // // //       distance: json['distance']?.toDouble() ?? 0.0,
// // // //       duration: json['time']?.toInt() ?? 0,
// // // //       type: json['type']?.toString() ?? '',
// // // //     );
// // // //   }
// // // // }
// // // //
// // // // /// 📍 Résultat de recherche d'adresse
// // // // class PlaceResult {
// // // //   final String name;
// // // //   final String address;
// // // //   final LatLng location;
// // // //
// // // //   PlaceResult({
// // // //     required this.name,
// // // //     required this.address,
// // // //     required this.location,
// // // //   });
// // // //
// // // //   factory PlaceResult.fromJson(Map<String, dynamic> json) {
// // // //     final properties = json['properties'];
// // // //     final geometry = json['geometry'];
// // // //     final coordinates = geometry['coordinates'];
// // // //
// // // //     return PlaceResult(
// // // //       name: properties['name']?.toString() ?? '',
// // // //       address: properties['formatted']?.toString() ?? '',
// // // //       location: LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
// // // //     );
// // // //   }
// // // // }
// // // //
// // // // /// 🅿️ Point d'intérêt (parking, etc.)
// // // // class POI {
// // // //   final String name;
// // // //   final String category;
// // // //   final LatLng location;
// // // //   final double? distance;
// // // //
// // // //   POI({
// // // //     required this.name,
// // // //     required this.category,
// // // //     required this.location,
// // // //     this.distance,
// // // //   });
// // // //
// // // //   factory POI.fromJson(Map<String, dynamic> json) {
// // // //     final properties = json['properties'];
// // // //     final geometry = json['geometry'];
// // // //     final coordinates = geometry['coordinates'];
// // // //
// // // //     return POI(
// // // //       name: properties['name']?.toString() ?? 'Sans nom',
// // // //       category: properties['categories']?.first?.toString() ?? '',
// // // //       location: LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
// // // //       distance: properties['distance']?.toDouble(),
// // // //     );
// // // //   }
// // // // }
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // // // // services/geoapify_service/geoapify_service.dart
// // // // // import 'dart:convert';
// // // // // import 'package:http/http.dart' as http;
// // // // // import 'package:latlong2/latlong.dart';
// // // // //
// // // // // class GeoapifyService {
// // // // //   // 🔑 REMPLACEZ par votre clé API Geoapify (gratuite sur geoapify.com)
// // // // //   static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
// // // // //   static const String _baseUrl = 'https://api.geoapify.com/v1';
// // // // //
// // // // //   // ✅ GETTER PUBLIC pour accéder à la clé API
// // // // //   static String get apiKey => _apiKey;
// // // // //
// // // // //   /// 🛣️ Calculer un itinéraire entre deux points
// // // // //   static Future<RouteResult?> getRoute({
// // // // //     required LatLng start,
// // // // //     required LatLng end,
// // // // //     TransportMode mode = TransportMode.drive,
// // // // //     bool avoidTolls = false,
// // // // //     bool avoidFerries = false,
// // // // //   }) async {
// // // // //     try {
// // // // //       final url = Uri.parse(
// // // // //           '$_baseUrl/routing?'
// // // // //               'waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&'
// // // // //               'mode=${_getModeString(mode)}&'
// // // // //               'details=instruction_details&'
// // // // //               'apiKey=$_apiKey'
// // // // //       );
// // // // //
// // // // //       print("🌐 Requête Geoapify: $url");
// // // // //
// // // // //       final response = await http.get(url);
// // // // //
// // // // //       if (response.statusCode == 200) {
// // // // //         final data = json.decode(response.body);
// // // // //
// // // // //         if (data['features'] != null && data['features'].isNotEmpty) {
// // // // //           return RouteResult.fromJson(data['features'][0]);
// // // // //         } else {
// // // // //           print("❌ Aucun itinéraire trouvé");
// // // // //           return null;
// // // // //         }
// // // // //       } else {
// // // // //         print("❌ Erreur API Geoapify: ${response.statusCode} - ${response.body}");
// // // // //         return null;
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("❌ Exception Geoapify: $e");
// // // // //       return null;
// // // // //     }
// // // // //   }
// // // // //
// // // // //   /// 📍 Rechercher une adresse (geocoding)
// // // // //   static Future<List<PlaceResult>> searchAddress(String query) async {
// // // // //     try {
// // // // //       final url = Uri.parse(
// // // // //           '$_baseUrl/geocode/search?'
// // // // //               'text=${Uri.encodeComponent(query)}&'
// // // // //               'limit=5&'
// // // // //               'apiKey=$_apiKey'
// // // // //       );
// // // // //
// // // // //       final response = await http.get(url);
// // // // //
// // // // //       if (response.statusCode == 200) {
// // // // //         final data = json.decode(response.body);
// // // // //         return (data['features'] as List)
// // // // //             .map((feature) => PlaceResult.fromJson(feature))
// // // // //             .toList();
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("❌ Erreur geocoding: $e");
// // // // //     }
// // // // //
// // // // //     return [];
// // // // //   }
// // // // //
// // // // //   /// 🅿️ Trouver des parkings près d'un point
// // // // //   static Future<List<POI>> findNearbyParking(LatLng center) async {
// // // // //     try {
// // // // //       final url = Uri.parse(
// // // // //           '$_baseUrl/places?'
// // // // //               'categories=parking&'
// // // // //               'filter=circle:${center.longitude},${center.latitude},500&'
// // // // //               'limit=10&'
// // // // //               'apiKey=$_apiKey'
// // // // //       );
// // // // //
// // // // //       final response = await http.get(url);
// // // // //
// // // // //       if (response.statusCode == 200) {
// // // // //         final data = json.decode(response.body);
// // // // //         return (data['features'] as List)
// // // // //             .map((feature) => POI.fromJson(feature))
// // // // //             .toList();
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("❌ Erreur POI: $e");
// // // // //     }
// // // // //
// // // // //     return [];
// // // // //   }
// // // // //
// // // // //   /// 🔧 Helper : Convertir le mode de transport en string API
// // // // //   static String _getModeString(TransportMode mode) {
// // // // //     switch (mode) {
// // // // //       case TransportMode.drive:
// // // // //         return 'drive';
// // // // //       case TransportMode.walk:
// // // // //         return 'walk';
// // // // //       case TransportMode.bicycle:
// // // // //         return 'bicycle';
// // // // //       case TransportMode.transit:
// // // // //         return 'transit';
// // // // //     }
// // // // //   }
// // // // // }
// // // // //
// // // // // /// 🚗 Modes de transport disponibles
// // // // // enum TransportMode {
// // // // //   drive,    // Voiture
// // // // //   walk,     // Marche
// // // // //   bicycle,  // Vélo
// // // // //   transit,  // Transport public
// // // // // }
// // // // //
// // // // // /// 🛣️ Résultat d'un itinéraire
// // // // // class RouteResult {
// // // // //   final double distance;           // Distance en mètres
// // // // //   final int duration;             // Durée en secondes
// // // // //   final List<LatLng> points;      // Points de la route
// // // // //   final List<Instruction> instructions; // Instructions turn-by-turn
// // // // //   final LatLng startPoint;
// // // // //   final LatLng endPoint;
// // // // //
// // // // //   RouteResult({
// // // // //     required this.distance,
// // // // //     required this.duration,
// // // // //     required this.points,
// // // // //     required this.instructions,
// // // // //     required this.startPoint,
// // // // //     required this.endPoint,
// // // // //   });
// // // // //
// // // // //   factory RouteResult.fromJson(Map<String, dynamic> json) {
// // // // //     final properties = json['properties'];
// // // // //     final geometry = json['geometry'];
// // // // //
// // // // //     // 📍 Extraire les coordonnées de la route
// // // // //     List<LatLng> routePoints = [];
// // // // //     if (geometry['type'] == 'LineString') {
// // // // //       final coordinates = geometry['coordinates'] as List;
// // // // //       routePoints = coordinates
// // // // //           .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
// // // // //           .toList();
// // // // //     }
// // // // //
// // // // //     // 📋 Extraire les instructions
// // // // //     List<Instruction> instructions = [];
// // // // //     if (properties['legs'] != null) {
// // // // //       final legs = properties['legs'] as List;
// // // // //       for (var leg in legs) {
// // // // //         if (leg['steps'] != null) {
// // // // //           final steps = leg['steps'] as List;
// // // // //           for (var step in steps) {
// // // // //             instructions.add(Instruction.fromJson(step));
// // // // //           }
// // // // //         }
// // // // //       }
// // // // //     }
// // // // //
// // // // //     return RouteResult(
// // // // //       distance: properties['distance']?.toDouble() ?? 0.0,
// // // // //       duration: properties['time']?.toInt() ?? 0,
// // // // //       points: routePoints,
// // // // //       instructions: instructions,
// // // // //       startPoint: routePoints.isNotEmpty ? routePoints.first : LatLng(0, 0),
// // // // //       endPoint: routePoints.isNotEmpty ? routePoints.last : LatLng(0, 0),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   /// 📏 Distance formatée
// // // // //   String get distanceFormatted {
// // // // //     if (distance < 1000) {
// // // // //       return '${distance.round()} m';
// // // // //     }
// // // // //     return '${(distance / 1000).toStringAsFixed(1)} km';
// // // // //   }
// // // // //
// // // // //   /// ⏰ Durée formatée
// // // // //   String get durationFormatted {
// // // // //     final minutes = duration ~/ 60;
// // // // //     if (minutes < 60) {
// // // // //       return '$minutes min';
// // // // //     }
// // // // //     final hours = minutes ~/ 60;
// // // // //     final remainingMinutes = minutes % 60;
// // // // //     return '${hours}h ${remainingMinutes}min';
// // // // //   }
// // // // // }
// // // // //
// // // // // /// 📋 Instruction de navigation
// // // // // class Instruction {
// // // // //   final String text;
// // // // //   final double distance;
// // // // //   final int duration;
// // // // //   final String type;
// // // // //
// // // // //   Instruction({
// // // // //     required this.text,
// // // // //     required this.distance,
// // // // //     required this.duration,
// // // // //     required this.type,
// // // // //   });
// // // // //
// // // // //   factory Instruction.fromJson(Map<String, dynamic> json) {
// // // // //     return Instruction(
// // // // //       text: json['instruction']?.toString() ?? '',
// // // // //       distance: json['distance']?.toDouble() ?? 0.0,
// // // // //       duration: json['time']?.toInt() ?? 0,
// // // // //       type: json['type']?.toString() ?? '',
// // // // //     );
// // // // //   }
// // // // // }
// // // // //
// // // // // /// 📍 Résultat de recherche d'adresse
// // // // // class PlaceResult {
// // // // //   final String name;
// // // // //   final String address;
// // // // //   final LatLng location;
// // // // //
// // // // //   PlaceResult({
// // // // //     required this.name,
// // // // //     required this.address,
// // // // //     required this.location,
// // // // //   });
// // // // //
// // // // //   factory PlaceResult.fromJson(Map<String, dynamic> json) {
// // // // //     final properties = json['properties'];
// // // // //     final geometry = json['geometry'];
// // // // //     final coordinates = geometry['coordinates'];
// // // // //
// // // // //     return PlaceResult(
// // // // //       name: properties['name']?.toString() ?? '',
// // // // //       address: properties['formatted']?.toString() ?? '',
// // // // //       location: LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
// // // // //     );
// // // // //   }
// // // // // }
// // // // //
// // // // // /// 🅿️ Point d'intérêt (parking, etc.)
// // // // // class POI {
// // // // //   final String name;
// // // // //   final String category;
// // // // //   final LatLng location;
// // // // //   final double? distance;
// // // // //
// // // // //   POI({
// // // // //     required this.name,
// // // // //     required this.category,
// // // // //     required this.location,
// // // // //     this.distance,
// // // // //   });
// // // // //
// // // // //   factory POI.fromJson(Map<String, dynamic> json) {
// // // // //     final properties = json['properties'];
// // // // //     final geometry = json['geometry'];
// // // // //     final coordinates = geometry['coordinates'];
// // // // //
// // // // //     return POI(
// // // // //       name: properties['name']?.toString() ?? 'Sans nom',
// // // // //       category: properties['categories']?.first?.toString() ?? '',
// // // // //       location: LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
// // // // //       distance: properties['distance']?.toDouble(),
// // // // //     );
// // // // //   }
// // // // // }
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // // // // services/geoapify_service.dart
// // // // // // import 'dart:convert';
// // // // // // import 'package:http/http.dart' as http;
// // // // // // import 'package:latlong2/latlong.dart';
// // // // // //
// // // // // // class GeoapifyService {
// // // // // //   // 🔑 REMPLACEZ par votre clé API Geoapify (gratuite sur geoapify.com)
// // // // // //   static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
// // // // // //   static const String _baseUrl = 'https://api.geoapify.com/v1';
// // // // // //
// // // // // //   /// 🛣️ Calculer un itinéraire entre deux points
// // // // // //   static Future<RouteResult?> getRoute({
// // // // // //     required LatLng start,
// // // // // //     required LatLng end,
// // // // // //     TransportMode mode = TransportMode.drive,
// // // // // //     bool avoidTolls = false,
// // // // // //     bool avoidFerries = false,
// // // // // //   }) async {
// // // // // //     try {
// // // // // //       final url = Uri.parse(
// // // // // //           '$_baseUrl/routing?'
// // // // // //               'waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&'
// // // // // //               'mode=${_getModeString(mode)}&'
// // // // // //               'details=instruction_details&'
// // // // // //               'apiKey=$_apiKey'
// // // // // //       );
// // // // // //
// // // // // //       print("🌐 Requête Geoapify: $url");
// // // // // //
// // // // // //       final response = await http.get(url);
// // // // // //
// // // // // //       if (response.statusCode == 200) {
// // // // // //         final data = json.decode(response.body);
// // // // // //
// // // // // //         if (data['features'] != null && data['features'].isNotEmpty) {
// // // // // //           return RouteResult.fromJson(data['features'][0]);
// // // // // //         } else {
// // // // // //           print("❌ Aucun itinéraire trouvé");
// // // // // //           return null;
// // // // // //         }
// // // // // //       } else {
// // // // // //         print("❌ Erreur API Geoapify: ${response.statusCode} - ${response.body}");
// // // // // //         return null;
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       print("❌ Exception Geoapify: $e");
// // // // // //       return null;
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   /// 📍 Rechercher une adresse (geocoding)
// // // // // //   static Future<List<PlaceResult>> searchAddress(String query) async {
// // // // // //     try {
// // // // // //       final url = Uri.parse(
// // // // // //           '$_baseUrl/geocode/search?'
// // // // // //               'text=${Uri.encodeComponent(query)}&'
// // // // // //               'limit=5&'
// // // // // //               'apiKey=$_apiKey'
// // // // // //       );
// // // // // //
// // // // // //       final response = await http.get(url);
// // // // // //
// // // // // //       if (response.statusCode == 200) {
// // // // // //         final data = json.decode(response.body);
// // // // // //         return (data['features'] as List)
// // // // // //             .map((feature) => PlaceResult.fromJson(feature))
// // // // // //             .toList();
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       print("❌ Erreur geocoding: $e");
// // // // // //     }
// // // // // //
// // // // // //     return [];
// // // // // //   }
// // // // // //
// // // // // //   /// 🅿️ Trouver des parkings près d'un point
// // // // // //   static Future<List<POI>> findNearbyParking(LatLng center) async {
// // // // // //     try {
// // // // // //       final url = Uri.parse(
// // // // // //           '$_baseUrl/places?'
// // // // // //               'categories=parking&'
// // // // // //               'filter=circle:${center.longitude},${center.latitude},500&'
// // // // // //               'limit=10&'
// // // // // //               'apiKey=$_apiKey'
// // // // // //       );
// // // // // //
// // // // // //       final response = await http.get(url);
// // // // // //
// // // // // //       if (response.statusCode == 200) {
// // // // // //         final data = json.decode(response.body);
// // // // // //         return (data['features'] as List)
// // // // // //             .map((feature) => POI.fromJson(feature))
// // // // // //             .toList();
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       print("❌ Erreur POI: $e");
// // // // // //     }
// // // // // //
// // // // // //     return [];
// // // // // //   }
// // // // // //
// // // // // //   /// 🔧 Helper : Convertir le mode de transport en string API
// // // // // //   static String _getModeString(TransportMode mode) {
// // // // // //     switch (mode) {
// // // // // //       case TransportMode.drive:
// // // // // //         return 'drive';
// // // // // //       case TransportMode.walk:
// // // // // //         return 'walk';
// // // // // //       case TransportMode.bicycle:
// // // // // //         return 'bicycle';
// // // // // //       case TransportMode.transit:
// // // // // //         return 'transit';
// // // // // //     }
// // // // // //   }
// // // // // // }
// // // // // //
// // // // // // /// 🚗 Modes de transport disponibles
// // // // // // enum TransportMode {
// // // // // //   drive,    // Voiture
// // // // // //   walk,     // Marche
// // // // // //   bicycle,  // Vélo
// // // // // //   transit,  // Transport public
// // // // // // }
// // // // // //
// // // // // // /// 🛣️ Résultat d'un itinéraire
// // // // // // class RouteResult {
// // // // // //   final double distance;           // Distance en mètres
// // // // // //   final int duration;             // Durée en secondes
// // // // // //   final List<LatLng> points;      // Points de la route
// // // // // //   final List<Instruction> instructions; // Instructions turn-by-turn
// // // // // //   final LatLng startPoint;
// // // // // //   final LatLng endPoint;
// // // // // //
// // // // // //   RouteResult({
// // // // // //     required this.distance,
// // // // // //     required this.duration,
// // // // // //     required this.points,
// // // // // //     required this.instructions,
// // // // // //     required this.startPoint,
// // // // // //     required this.endPoint,
// // // // // //   });
// // // // // //
// // // // // //   factory RouteResult.fromJson(Map<String, dynamic> json) {
// // // // // //     final properties = json['properties'];
// // // // // //     final geometry = json['geometry'];
// // // // // //
// // // // // //     // 📍 Extraire les coordonnées de la route
// // // // // //     List<LatLng> routePoints = [];
// // // // // //     if (geometry['type'] == 'LineString') {
// // // // // //       final coordinates = geometry['coordinates'] as List;
// // // // // //       routePoints = coordinates
// // // // // //           .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
// // // // // //           .toList();
// // // // // //     }
// // // // // //
// // // // // //     // 📋 Extraire les instructions
// // // // // //     List<Instruction> instructions = [];
// // // // // //     if (properties['legs'] != null) {
// // // // // //       final legs = properties['legs'] as List;
// // // // // //       for (var leg in legs) {
// // // // // //         if (leg['steps'] != null) {
// // // // // //           final steps = leg['steps'] as List;
// // // // // //           for (var step in steps) {
// // // // // //             instructions.add(Instruction.fromJson(step));
// // // // // //           }
// // // // // //         }
// // // // // //       }
// // // // // //     }
// // // // // //
// // // // // //     return RouteResult(
// // // // // //       distance: properties['distance']?.toDouble() ?? 0.0,
// // // // // //       duration: properties['time']?.toInt() ?? 0,
// // // // // //       points: routePoints,
// // // // // //       instructions: instructions,
// // // // // //       startPoint: routePoints.isNotEmpty ? routePoints.first : LatLng(0, 0),
// // // // // //       endPoint: routePoints.isNotEmpty ? routePoints.last : LatLng(0, 0),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   /// 📏 Distance formatée
// // // // // //   String get distanceFormatted {
// // // // // //     if (distance < 1000) {
// // // // // //       return '${distance.round()} m';
// // // // // //     }
// // // // // //     return '${(distance / 1000).toStringAsFixed(1)} km';
// // // // // //   }
// // // // // //
// // // // // //   /// ⏰ Durée formatée
// // // // // //   String get durationFormatted {
// // // // // //     final minutes = duration ~/ 60;
// // // // // //     if (minutes < 60) {
// // // // // //       return '$minutes min';
// // // // // //     }
// // // // // //     final hours = minutes ~/ 60;
// // // // // //     final remainingMinutes = minutes % 60;
// // // // // //     return '${hours}h ${remainingMinutes}min';
// // // // // //   }
// // // // // // }
// // // // // //
// // // // // // /// 📋 Instruction de navigation
// // // // // // class Instruction {
// // // // // //   final String text;
// // // // // //   final double distance;
// // // // // //   final int duration;
// // // // // //   final String type;
// // // // // //
// // // // // //   Instruction({
// // // // // //     required this.text,
// // // // // //     required this.distance,
// // // // // //     required this.duration,
// // // // // //     required this.type,
// // // // // //   });
// // // // // //
// // // // // //   factory Instruction.fromJson(Map<String, dynamic> json) {
// // // // // //     return Instruction(
// // // // // //       text: json['instruction']?.toString() ?? '',
// // // // // //       distance: json['distance']?.toDouble() ?? 0.0,
// // // // // //       duration: json['time']?.toInt() ?? 0,
// // // // // //       type: json['type']?.toString() ?? '',
// // // // // //     );
// // // // // //   }
// // // // // // }
// // // // // //
// // // // // // /// 📍 Résultat de recherche d'adresse
// // // // // // class PlaceResult {
// // // // // //   final String name;
// // // // // //   final String address;
// // // // // //   final LatLng location;
// // // // // //
// // // // // //   PlaceResult({
// // // // // //     required this.name,
// // // // // //     required this.address,
// // // // // //     required this.location,
// // // // // //   });
// // // // // //
// // // // // //   factory PlaceResult.fromJson(Map<String, dynamic> json) {
// // // // // //     final properties = json['properties'];
// // // // // //     final geometry = json['geometry'];
// // // // // //     final coordinates = geometry['coordinates'];
// // // // // //
// // // // // //     return PlaceResult(
// // // // // //       name: properties['name']?.toString() ?? '',
// // // // // //       address: properties['formatted']?.toString() ?? '',
// // // // // //       location: LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
// // // // // //     );
// // // // // //   }
// // // // // // }
// // // // // //
// // // // // // /// 🅿️ Point d'intérêt (parking, etc.)
// // // // // // class POI {
// // // // // //   final String name;
// // // // // //   final String category;
// // // // // //   final LatLng location;
// // // // // //   final double? distance;
// // // // // //
// // // // // //   POI({
// // // // // //     required this.name,
// // // // // //     required this.category,
// // // // // //     required this.location,
// // // // // //     this.distance,
// // // // // //   });
// // // // // //
// // // // // //   factory POI.fromJson(Map<String, dynamic> json) {
// // // // // //     final properties = json['properties'];
// // // // // //     final geometry = json['geometry'];
// // // // // //     final coordinates = geometry['coordinates'];
// // // // // //
// // // // // //     return POI(
// // // // // //       name: properties['name']?.toString() ?? 'Sans nom',
// // // // // //       category: properties['categories']?.first?.toString() ?? '',
// // // // // //       location: LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
// // // // // //       distance: properties['distance']?.toDouble(),
// // // // // //     );
// // // // // //   }
// // // // // // }