import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 AJOUT

class DisponibilitesProvider with ChangeNotifier {
  List<DateTime> _joursDisponibles = [];
  bool _isLoaded = false;
  String? _lastError;

  bool get isLoaded => _isLoaded;
  String? get lastError => _lastError;
  List<DateTime> get joursDisponibles => _joursDisponibles;

  /// 🔑 Récupérer les headers d'authentification Firebase
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 🔥 TOKEN FIREBASE
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  /// 🔁 Charger les jours avec au moins un créneau disponible - VERSION AVEC AUTH
  Future<void> loadDisponibilites(String coiffeuseId, int duree) async {
    print("🔄 === DÉBUT CHARGEMENT DISPONIBILITÉS ===");
    print("🔄 CoiffeuseId: $coiffeuseId");
    print("🔄 Durée: $duree minutes");

    // 🛡️ Validation des paramètres d'entrée
    if (coiffeuseId.isEmpty || duree <= 0) {
      _lastError = "Paramètres invalides: coiffeuseId='$coiffeuseId', duree=$duree";
      print("❌ $_lastError");
      _isLoaded = false;
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final end = now.add(Duration(days: 14));
    List<DateTime> joursOK = [];

    _isLoaded = false;
    _lastError = null;
    notifyListeners(); // Informer que le chargement commence

    try {
      // 🔑 Récupérer les headers avec authentification
      final headers = await _getAuthHeaders();
      print("🔑 Headers d'authentification: ${headers.keys.toList()}");

      int joursAnalyses = 0;
      int joursAvecCreneaux = 0;

      for (int i = 0; i <= end.difference(now).inDays; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        joursAnalyses++;

        final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
        print("📡 API Call [$i/${end.difference(now).inDays}]: $url");

        try {
          // 🔥 APPEL AVEC HEADERS D'AUTH
          final response = await http.get(url, headers: headers);
          print("📡 Response [$dateStr]: Status ${response.statusCode}");

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print("📡 Response data [$dateStr]: $data");

            // 🛡️ Vérification robuste de la structure de réponse
            if (data is Map<String, dynamic> && data.containsKey('disponibilites')) {
              final disponibilites = data['disponibilites'];
              if (disponibilites is List && disponibilites.isNotEmpty) {
                joursOK.add(date);
                joursAvecCreneaux++;
                print("✅ Date $dateStr: ${disponibilites.length} créneaux trouvés");
              } else {
                print("📭 Date $dateStr: Aucun créneau disponible");
              }
            } else {
              print("⚠️ Date $dateStr: Structure de réponse inattendue: $data");
            }
          } else if (response.statusCode == 401) {
            print("🔐 Date $dateStr: Erreur d'authentification - ${response.body}");
            _lastError = "Erreur d'authentification. Veuillez vous reconnecter.";
            break; // Arrêter si problème d'auth
          } else {
            print("❌ Date $dateStr: Erreur HTTP ${response.statusCode} - ${response.body}");
          }
        } catch (apiError) {
          print("❌ Erreur API pour $dateStr: $apiError");
          // Continue avec les autres dates même si une échoue
        }

        // 🕐 Petit délai pour éviter de surcharger l'API
        if (i % 5 == 0 && i > 0) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      _joursDisponibles = joursOK;
      _isLoaded = true;
      if (_lastError == null) {
        _lastError = null; // Pas d'erreur d'auth
      }

      print("✅ === CHARGEMENT TERMINÉ ===");
      print("✅ Jours analysés: $joursAnalyses");
      print("✅ Jours avec créneaux: $joursAvecCreneaux");
      print("✅ Jours disponibles: ${_joursDisponibles.length}");

      notifyListeners();

      // 🎯 Si aucun jour disponible trouvé, log des informations de debug
      if (_joursDisponibles.isEmpty && _lastError == null) {
        print("⚠️ AUCUN JOUR DISPONIBLE - Causes possibles:");
        print("   1. La coiffeuse n'a pas configuré ses horaires");
        print("   2. Tous les créneaux sont déjà réservés");
        print("   3. La durée demandée ($duree min) est trop longue");
        print("   4. Problème côté serveur/base de données");
        _lastError = "Aucune disponibilité trouvée pour les 14 prochains jours";
      }

    } catch (e) {
      _lastError = "Erreur lors du chargement des disponibilités: $e";
      print("❌ ERREUR GLOBALE: $_lastError");
      _isLoaded = false;
      notifyListeners();
    }
  }

  /// 🔍 Récupérer les créneaux pour une date donnée - VERSION AVEC AUTH
  Future<List<Map<String, String>>> getCreneauxPourJour(String dateStr, String coiffeuseId, int duree) async {
    print("🔍 === RÉCUPÉRATION CRÉNEAUX ===");
    print("🔍 Date: $dateStr");
    print("🔍 CoiffeuseId: $coiffeuseId");
    print("🔍 Durée: $duree");

    final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
    print("🔍 URL: $url");

    try {
      // 🔑 Headers avec authentification
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);
      print("🔍 Status: ${response.statusCode}");
      print("🔍 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('disponibilites')) {
          final slots = data['disponibilites'] as List;
          final creneaux = slots.map<Map<String, String>>((slot) {
            return {
              'debut': slot['debut'].toString(),
              'fin': slot['fin'].toString(),
            };
          }).toList();

          print("✅ ${creneaux.length} créneaux récupérés:");
          for (var creneau in creneaux) {
            print("   - ${creneau['debut']} → ${creneau['fin']}");
          }

          return creneaux;
        } else {
          print("⚠️ Structure de réponse incorrecte: $data");
          return [];
        }
      } else if (response.statusCode == 401) {
        print("🔐 Erreur d'authentification: ${response.body}");
        return [];
      } else {
        print("❌ Erreur HTTP: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Erreur réseau: $e");
      return [];
    }
  }

  // Vérifier si un jour est disponible
  bool isJourDispo(DateTime day) {
    bool dispo = _joursDisponibles.any((d) =>
    d.year == day.year && d.month == day.month && d.day == day.day);
    print("🔍 isJourDispo(${DateFormat('yyyy-MM-dd').format(day)}): $dispo");
    return dispo;
  }

  // Méthode pour forcer le rechargement
  Future<void> reloadDisponibilites(String coiffeuseId, int duree) async {
    print("🔄 Rechargement forcé des disponibilités...");
    _joursDisponibles.clear();
    _isLoaded = false;
    _lastError = null;
    notifyListeners();

    await loadDisponibilites(coiffeuseId, duree);
  }

  // Méthode de diagnostic
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'isLoaded': _isLoaded,
      'joursDisponibles': _joursDisponibles.length,
      'lastError': _lastError,
      'dates': _joursDisponibles.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
    };
  }
}












// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
//
// class DisponibilitesProvider with ChangeNotifier {
//   List<DateTime> _joursDisponibles = [];
//   bool _isLoaded = false;
//   String? _lastError;
//
//   bool get isLoaded => _isLoaded;
//   String? get lastError => _lastError;
//   List<DateTime> get joursDisponibles => _joursDisponibles;
//
//   /// 🔁 Charger les jours avec au moins un créneau disponible - VERSION CORRIGÉE
//   Future<void> loadDisponibilites(String coiffeuseId, int duree) async {
//     print("🔄 === DÉBUT CHARGEMENT DISPONIBILITÉS ===");
//     print("🔄 CoiffeuseId: $coiffeuseId");
//     print("🔄 Durée: $duree minutes");
//
//     // 🛡️ Validation des paramètres d'entrée
//     if (coiffeuseId.isEmpty || duree <= 0) {
//       _lastError = "Paramètres invalides: coiffeuseId='$coiffeuseId', duree=$duree";
//       print("❌ $_lastError");
//       _isLoaded = false;
//       notifyListeners();
//       return;
//     }
//
//     final now = DateTime.now();
//     final end = now.add(Duration(days: 14));
//     List<DateTime> joursOK = [];
//
//     _isLoaded = false;
//     _lastError = null;
//     notifyListeners(); // Informer que le chargement commence
//
//     try {
//       int joursAnalyses = 0;
//       int joursAvecCreneaux = 0;
//
//       for (int i = 0; i <= end.difference(now).inDays; i++) {
//         final date = now.add(Duration(days: i));
//         final dateStr = DateFormat('yyyy-MM-dd').format(date);
//         joursAnalyses++;
//
//         final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
//         print("📡 API Call [$i/${end.difference(now).inDays}]: $url");
//
//         try {
//           final response = await http.get(url);
//           print("📡 Response [$dateStr]: Status ${response.statusCode}");
//
//           if (response.statusCode == 200) {
//             final data = json.decode(response.body);
//             print("📡 Response data [$dateStr]: $data");
//
//             // 🛡️ Vérification robuste de la structure de réponse
//             if (data is Map<String, dynamic> && data.containsKey('disponibilites')) {
//               final disponibilites = data['disponibilites'];
//               if (disponibilites is List && disponibilites.isNotEmpty) {
//                 joursOK.add(date);
//                 joursAvecCreneaux++;
//                 print("✅ Date $dateStr: ${disponibilites.length} créneaux trouvés");
//               } else {
//                 print("📭 Date $dateStr: Aucun créneau disponible");
//               }
//             } else {
//               print("⚠️ Date $dateStr: Structure de réponse inattendue: $data");
//             }
//           } else {
//             print("❌ Date $dateStr: Erreur HTTP ${response.statusCode} - ${response.body}");
//           }
//         } catch (apiError) {
//           print("❌ Erreur API pour $dateStr: $apiError");
//           // Continue avec les autres dates même si une échoue
//         }
//
//         // 🕐 Petit délai pour éviter de surcharger l'API
//         if (i % 5 == 0 && i > 0) {
//           await Future.delayed(Duration(milliseconds: 100));
//         }
//       }
//
//       _joursDisponibles = joursOK;
//       _isLoaded = true;
//       _lastError = null;
//
//       print("✅ === CHARGEMENT TERMINÉ ===");
//       print("✅ Jours analysés: $joursAnalyses");
//       print("✅ Jours avec créneaux: $joursAvecCreneaux");
//       print("✅ Jours disponibles: ${_joursDisponibles.length}");
//       for (var jour in _joursDisponibles) {
//         print("   - ${DateFormat('yyyy-MM-dd (EEEE)', 'fr_FR').format(jour)}");
//       }
//
//       notifyListeners();
//
//       // 🎯 Si aucun jour disponible trouvé, log des informations de debug
//       if (_joursDisponibles.isEmpty) {
//         print("⚠️ AUCUN JOUR DISPONIBLE - Causes possibles:");
//         print("   1. La coiffeuse n'a pas configuré ses horaires");
//         print("   2. Tous les créneaux sont déjà réservés");
//         print("   3. La durée demandée ($duree min) est trop longue");
//         print("   4. Problème côté serveur/base de données");
//         print("   5. API endpoint incorrect ou indisponible");
//         _lastError = "Aucune disponibilité trouvée pour les 14 prochains jours";
//       }
//
//     } catch (e) {
//       _lastError = "Erreur lors du chargement des disponibilités: $e";
//       print("❌ ERREUR GLOBALE: $_lastError");
//       _isLoaded = false;
//       notifyListeners();
//     }
//   }
//
//   /// 🔍 Vérifier si un jour est disponible
//   bool isJourDispo(DateTime day) {
//     bool dispo = _joursDisponibles.any((d) =>
//     d.year == day.year && d.month == day.month && d.day == day.day);
//     print("🔍 isJourDispo(${DateFormat('yyyy-MM-dd').format(day)}): $dispo");
//     return dispo;
//   }
//
//   /// 🔍 Récupérer les créneaux pour une date donnée - VERSION CORRIGÉE
//   Future<List<Map<String, String>>> getCreneauxPourJour(String dateStr, String coiffeuseId, int duree) async {
//     print("🔍 === RÉCUPÉRATION CRÉNEAUX ===");
//     print("🔍 Date: $dateStr");
//     print("🔍 CoiffeuseId: $coiffeuseId");
//     print("🔍 Durée: $duree");
//
//     final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
//     print("🔍 URL: $url");
//
//     try {
//       final response = await http.get(url);
//       print("🔍 Status: ${response.statusCode}");
//       print("🔍 Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data is Map<String, dynamic> && data.containsKey('disponibilites')) {
//           final slots = data['disponibilites'] as List;
//           final creneaux = slots.map<Map<String, String>>((slot) {
//             return {
//               'debut': slot['debut'].toString(),
//               'fin': slot['fin'].toString(),
//             };
//           }).toList();
//
//           print("✅ ${creneaux.length} créneaux récupérés:");
//           for (var creneau in creneaux) {
//             print("   - ${creneau['debut']} → ${creneau['fin']}");
//           }
//
//           return creneaux;
//         } else {
//           print("⚠️ Structure de réponse incorrecte: $data");
//           return [];
//         }
//       } else {
//         print("❌ Erreur HTTP: ${response.statusCode} - ${response.body}");
//         return [];
//       }
//     } catch (e) {
//       print("❌ Erreur réseau: $e");
//       return [];
//     }
//   }
//
//   /// 🔄 Méthode pour forcer le rechargement
//   Future<void> reloadDisponibilites(String coiffeuseId, int duree) async {
//     print("🔄 Rechargement forcé des disponibilités...");
//     _joursDisponibles.clear();
//     _isLoaded = false;
//     _lastError = null;
//     notifyListeners();
//
//     await loadDisponibilites(coiffeuseId, duree);
//   }
//
//   /// 📊 Méthode de diagnostic
//   Map<String, dynamic> getDiagnosticInfo() {
//     return {
//       'isLoaded': _isLoaded,
//       'joursDisponibles': _joursDisponibles.length,
//       'lastError': _lastError,
//       'dates': _joursDisponibles.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
//     };
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
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:intl/intl.dart';
// //
// // class DisponibilitesProvider with ChangeNotifier {
// //   List<DateTime> _joursDisponibles = [];
// //   bool _isLoaded = false;
// //   bool get isLoaded => _isLoaded;
// //
// //   List<DateTime> get joursDisponibles => _joursDisponibles;
// //
// //   /// 🔁 Charger les jours avec au moins un créneau disponible
// //   Future<void> loadDisponibilites(String coiffeuseId, int duree) async {
// //     final now = DateTime.now();
// //     final end = now.add(Duration(days: 14));
// //     List<DateTime> joursOK = [];
// //
// //     try {
// //       for (int i = 0; i <= end.difference(now).inDays; i++) {
// //         final date = now.add(Duration(days: i));
// //         final dateStr = DateFormat('yyyy-MM-dd').format(date);
// //
// //         final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
// //         final response = await http.get(url);
// //
// //         if (response.statusCode == 200) {
// //           final data = json.decode(response.body);
// //           if ((data['disponibilites'] as List).isNotEmpty) {
// //             joursOK.add(date);
// //           }
// //         }
// //       }
// //
// //       _joursDisponibles = joursOK;
// //       _isLoaded = true;
// //       notifyListeners();
// //     } catch (e) {
// //       print("Erreur lors du chargement des disponibilités : $e");
// //       _isLoaded = false;
// //       notifyListeners();
// //     }
// //   }
// //
// //   /// 🔍 Vérifier si un jour est disponible
// //   bool isJourDispo(DateTime day) {
// //     return _joursDisponibles.any((d) =>
// //     d.year == day.year && d.month == day.month && d.day == day.day);
// //   }
// //
// //   /// 🔍 Récupérer les créneaux pour une date donnée
// //   Future<List<Map<String, String>>> getCreneauxPourJour(String dateStr, String coiffeuseId, int duree) async {
// //     final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
// //     final response = await http.get(url);
// //
// //     if (response.statusCode == 200) {
// //       final data = json.decode(response.body);
// //       final slots = data['disponibilites'] as List;
// //       return slots.map<Map<String, String>>((slot) => {
// //         'debut': slot['debut'],
// //         'fin': slot['fin'],
// //       }).toList();
// //     }
// //
// //     return [];
// //   }
// // }
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
// // // import 'package:intl/intl.dart';
// // //
// // // class DisponibilitesProvider with ChangeNotifier {
// // //   List<DateTime> _joursDisponibles = [];
// // //
// // //   List<DateTime> get joursDisponibles => _joursDisponibles;
// // //
// // //   /// 🔁 Charger les jours avec au moins un créneau disponible
// // //   Future<void> loadDisponibilites(String coiffeuseId, int duree) async {
// // //     final now = DateTime.now();
// // //     final end = now.add(Duration(days: 14));
// // //     List<DateTime> joursOK = [];
// // //
// // //     for (int i = 0; i <= end.difference(now).inDays; i++) {
// // //       final date = now.add(Duration(days: i));
// // //       final dateStr = DateFormat('yyyy-MM-dd').format(date);
// // //
// // //       final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
// // //       final response = await http.get(url);
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //         if ((data['disponibilites'] as List).isNotEmpty) {
// // //           joursOK.add(date);
// // //         }
// // //       }
// // //     }
// // //
// // //     _joursDisponibles = joursOK;
// // //     notifyListeners();
// // //   }
// // //
// // //   /// 🔍 Récupérer les créneaux pour une date donnée
// // //   Future<List<Map<String, String>>> getCreneauxPourJour(String dateStr, String coiffeuseId, int duree) async {
// // //     final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
// // //     final response = await http.get(url);
// // //
// // //     if (response.statusCode == 200) {
// // //       final data = json.decode(response.body);
// // //       final slots = data['disponibilites'] as List;
// // //       return slots.map<Map<String, String>>((slot) => {
// // //         'debut': slot['debut'],
// // //         'fin': slot['fin'],
// // //       }).toList();
// // //     }
// // //
// // //     return [];
// // //   }
// // // }
