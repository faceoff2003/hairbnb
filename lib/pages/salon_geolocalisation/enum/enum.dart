// ✅ ENUMS ET CLASSES DÉFINIES
import 'package:latlong2/latlong.dart';

enum TransportMode {
  drive,
  walk,
  bicycle,
  transit,
}

class RouteResult {
  final List<LatLng> points;
  final double distance; // en mètres
  final int duration; // en secondes

  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
  });

  String get distanceFormatted {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}

class POI {
  final LatLng location;
  final String name;
  final String type;

  POI({
    required this.location,
    required this.name,
    required this.type,
  });
}