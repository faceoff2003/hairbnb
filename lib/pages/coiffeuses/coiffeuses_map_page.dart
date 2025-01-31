import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/providers/api_location_service.dart';
import '../../services/providers/location_service.dart';

class CoiffeusesMapPage extends StatefulWidget {
  @override
  _CoiffeusesMapPageState createState() => _CoiffeusesMapPageState();
}

class _CoiffeusesMapPageState extends State<CoiffeusesMapPage> {
  List<dynamic> coiffeuses = [];
  Position? _currentPosition;
  double _searchRadius = 10.0; // Distance par défaut en km

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
      print("Erreur lors de la récupération de la position : $e");
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

      setState(() {
        coiffeuses = nearbyCoiffeuses;
      });
    } catch (e) {
      print("Erreur lors de la récupération des coiffeuses : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Coiffeuses à proximité")),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Barre de recherche par distance
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                const Text("Rayon de recherche :"),
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
          // Affichage de la carte
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition == null
                    ? LatLng(0, 0)
                    : LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    // 🔵 Marqueur du client
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.person_pin, color: Colors.blue, size: 40),
                    ),
                    // 🔴 Marqueurs des coiffeuses
                    ...coiffeuses.map((coiffeuse) {
                      try {
                        if (coiffeuse['position'] == null || !coiffeuse['position'].contains(',')) {
                          return null; // Évite les erreurs si la position est mal formatée
                        }

                        List<String> pos = coiffeuse['position'].split(',');
                        double lat = double.parse(pos[0]);
                        double lon = double.parse(pos[1]);

                        return Marker(
                          point: LatLng(lat, lon),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        );
                      } catch (e) {
                        print("Erreur de parsing de position : $e");
                        return null; // Ignore les données corrompues
                      }
                    }).whereType<Marker>().toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
