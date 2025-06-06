// salon_map_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SalonMapView extends StatelessWidget {
  final List<dynamic> salons;
  final Position currentPosition;
  final Function(dynamic) onSalonSelected;
  final String geoapifyApiKey;

  const SalonMapView({
    super.key,
    required this.salons,
    required this.currentPosition,
    required this.onSalonSelected,
    required this.geoapifyApiKey,
  });

  @override
  Widget build(BuildContext context) {
    // Convertir la position actuelle en LatLng pour la carte
    final currentLatLng = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: currentLatLng,
        initialZoom: 13.0,
      ),
      children: [
        // Couche de tuiles (fond de carte)
        TileLayer(
          urlTemplate:
          'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=$geoapifyApiKey',
          userAgentPackageName: 'com.hairbnb.app',
        ),
        // Marqueurs pour chaque salon
        MarkerLayer(
          markers: [
            // Marqueur pour la position actuelle
            Marker(
              point: currentLatLng,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
            // Marqueurs pour les salons
            ...salons.map(
                  (salon) => Marker(
                point: LatLng(
                  salon['latitude'] ?? 0.0,
                  salon['longitude'] ?? 0.0,
                ),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => onSalonSelected(salon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}