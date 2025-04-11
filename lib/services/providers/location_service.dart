// import 'package:geolocator/geolocator.dart';
//
// class LocationService {
//   static Future<Position?> getUserLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     // Vérifier si la localisation est activée
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return null;
//     }
//
//     // Vérifier les permissions
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) {
//         return null;
//       }
//     }
//
//     // Récupérer la position actuelle
//     return await Geolocator.getCurrentPosition();
//   }
// }
