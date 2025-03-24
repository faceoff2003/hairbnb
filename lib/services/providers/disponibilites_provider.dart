import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DisponibilitesProvider with ChangeNotifier {
  List<DateTime> _joursDisponibles = [];
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<DateTime> get joursDisponibles => _joursDisponibles;

  /// 🔁 Charger les jours avec au moins un créneau disponible
  Future<void> loadDisponibilites(String coiffeuseId, int duree) async {
    final now = DateTime.now();
    final end = now.add(Duration(days: 14));
    List<DateTime> joursOK = [];

    try {
      for (int i = 0; i <= end.difference(now).inDays; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if ((data['disponibilites'] as List).isNotEmpty) {
            joursOK.add(date);
          }
        }
      }

      _joursDisponibles = joursOK;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement des disponibilités : $e");
      _isLoaded = false;
      notifyListeners();
    }
  }

  /// 🔍 Vérifier si un jour est disponible
  bool isJourDispo(DateTime day) {
    return _joursDisponibles.any((d) =>
    d.year == day.year && d.month == day.month && d.day == day.day);
  }

  /// 🔍 Récupérer les créneaux pour une date donnée
  Future<List<Map<String, String>>> getCreneauxPourJour(String dateStr, String coiffeuseId, int duree) async {
    final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final slots = data['disponibilites'] as List;
      return slots.map<Map<String, String>>((slot) => {
        'debut': slot['debut'],
        'fin': slot['fin'],
      }).toList();
    }

    return [];
  }
}







// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
//
// class DisponibilitesProvider with ChangeNotifier {
//   List<DateTime> _joursDisponibles = [];
//
//   List<DateTime> get joursDisponibles => _joursDisponibles;
//
//   /// 🔁 Charger les jours avec au moins un créneau disponible
//   Future<void> loadDisponibilites(String coiffeuseId, int duree) async {
//     final now = DateTime.now();
//     final end = now.add(Duration(days: 14));
//     List<DateTime> joursOK = [];
//
//     for (int i = 0; i <= end.difference(now).inDays; i++) {
//       final date = now.add(Duration(days: i));
//       final dateStr = DateFormat('yyyy-MM-dd').format(date);
//
//       final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if ((data['disponibilites'] as List).isNotEmpty) {
//           joursOK.add(date);
//         }
//       }
//     }
//
//     _joursDisponibles = joursOK;
//     notifyListeners();
//   }
//
//   /// 🔍 Récupérer les créneaux pour une date donnée
//   Future<List<Map<String, String>>> getCreneauxPourJour(String dateStr, String coiffeuseId, int duree) async {
//     final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final slots = data['disponibilites'] as List;
//       return slots.map<Map<String, String>>((slot) => {
//         'debut': slot['debut'],
//         'fin': slot['fin'],
//       }).toList();
//     }
//
//     return [];
//   }
// }
