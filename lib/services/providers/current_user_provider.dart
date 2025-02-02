import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrentUserProvider with ChangeNotifier {
  CurrentUser? _currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = "http://192.168.0.248:8000";

  CurrentUser? get currentUser => _currentUser;

  /// 🔄 Récupérer l'utilisateur depuis Django
  Future<void> fetchCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_current_user/${firebaseUser.uid}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUser = CurrentUser.fromJson(data['user']);
        notifyListeners(); // 🔥 Met à jour toutes les pages utilisant `UserProvider`
      }
    } catch (error) {
      print("Erreur de connexion : $error");
    }
  }

  /// 🔄 Réinitialiser `CurrentUser` après déconnexion
  void clearUser() {
    _currentUser = null;
    notifyListeners(); // 🔥 Met à jour toutes les pages
  }
}





















// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class CurrentUserProvider with ChangeNotifier {
//   CurrentUser? _currentUser;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final String baseUrl = "http://192.168.0.248:8000";
//
//   CurrentUser? get currentUser => _currentUser;
//
//   /// 🔄 Récupérer l'utilisateur depuis Django
//   Future<void> fetchCurrentUser() async {
//     User? firebaseUser = _auth.currentUser;
//     if (firebaseUser == null) return;
//
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/get_current_user/${firebaseUser.uid}/'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _currentUser = CurrentUser.fromJson(data['user']);
//         notifyListeners(); // 🔥 Met à jour toutes les pages utilisant `UserProvider`
//       }
//     } catch (error) {
//       print("Erreur de connexion : $error");
//     }
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class CurrentUserProvider with ChangeNotifier {
//   CurrentUser? _currentUser;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final String baseUrl = "http://192.168.0.248:8000";
//
//   CurrentUser? get currentUser => _currentUser;
//
//   /// 🔹 Récupère les infos utilisateur au démarrage de l'app
//   Future<void> fetchCurrentUser() async {
//     User? firebaseUser = _auth.currentUser;
//     if (firebaseUser == null) return;
//
//     await _loadUserFromBackend(firebaseUser.uid);
//   }
//
//   /// 🔄 Rafraîchir `CurrentUser` après connexion
//   Future<void> refreshUser() async {
//     User? firebaseUser = _auth.currentUser;
//     if (firebaseUser != null) {
//       await _loadUserFromBackend(firebaseUser.uid);
//     }
//   }
//
//   /// 🔹 Fonction pour charger l'utilisateur depuis Django
//   Future<void> _loadUserFromBackend(String uuid) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/get_current_user/$uuid/'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _currentUser = CurrentUser.fromJson(data['user']);
//         notifyListeners(); // 🔥 Met à jour toutes les pages
//       }
//     } catch (error) {
//       print("Erreur de connexion : $error");
//     }
//   }
// }
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class CurrentUserProvider with ChangeNotifier {
// //   CurrentUser? _currentUser;
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final String baseUrl = "http://192.168.0.248:8000";
// //
// //   CurrentUser? get currentUser => _currentUser;
// //
// //   Future<void> fetchCurrentUser() async {
// //     try {
// //       User? firebaseUser = _auth.currentUser;
// //       if (firebaseUser == null) return;
// //
// //       String firebaseUid = firebaseUser.uid;
// //       final response = await http.get(
// //         Uri.parse('$baseUrl/api/get_current_user/$firebaseUid/'),
// //         headers: {'Content-Type': 'application/json'},
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         _currentUser = CurrentUser.fromJson(data['user']);
// //         notifyListeners(); // 🔥 Met à jour toutes les pages qui écoutent `UserProvider`
// //       }
// //     } catch (error) {
// //       print("Erreur de connexion : $error");
// //     }
// //   }
// // }
