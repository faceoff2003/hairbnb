import 'package:flutter/foundation.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../firebase_token/fcm_token_service.dart';

class CurrentUserProvider with ChangeNotifier {
  CurrentUser? _currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = "https://www.hairbnb.site";

  CurrentUser? get currentUser => _currentUser;

  /// 🔄 Récupérer l'utilisateur depuis Django via token sécurisé
  Future<void> fetchCurrentUser() async {
    // ✅ CACHE : Si déjà chargé, ne pas recharger
    if (_currentUser != null) {
      if (kDebugMode) print("✅ User déjà en cache");
      return;
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      final token = await firebaseUser.getIdToken();

      // ✅ TIMEOUT : Limite à 10 secondes
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_current_user/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10)); // ← AJOUT TIMEOUT

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        _currentUser = CurrentUser.fromJson(data['user']);

        // ✅ NOTIFICATION TOKEN : En arrière-plan (non-bloquant)
        if (!kIsWeb) {
          FCMTokenService.saveTokenToFirebase(firebaseUser.uid).catchError((e) {
            if (kDebugMode) print("⚠️ FCM Token error (non-bloquant): $e");
          });
        }

        notifyListeners();
        if (kDebugMode) print("✅ User chargé avec succès");
      } else {
        if (kDebugMode) print("⚠️ User non trouvé (${response.statusCode})");
      }
    } catch (error) {
      if (kDebugMode) print("❌ Erreur chargement user : $error");
      // ✅ NE PAS CRASH : Continuer même en cas d'erreur réseau
    }
  }

  // Future<void> fetchCurrentUser() async {
  //   if (_currentUser != null) return;
  //
  //   final firebaseUser = _auth.currentUser;
  //   if (firebaseUser == null) return;
  //
  //   try {
  //     final token = await firebaseUser.getIdToken();
  //
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/api/get_current_user/'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final decodedBody = utf8.decode(response.bodyBytes);
  //       final data = json.decode(decodedBody);
  //       _currentUser = CurrentUser.fromJson(data['user']);
  //
  //       // Sauvegarder le token FCM après connexion réussie
  //       //await FCMTokenService.saveTokenToFirebase(firebaseUser.uid);
  //       if (!kIsWeb) {
  //         await FCMTokenService.saveTokenToFirebase(firebaseUser.uid);
  //       }
  //
  //       notifyListeners();
  //     } else {
  //       print("⚠️ Utilisateur non trouvé ou non autorisé (${response.statusCode})");
  //     }
  //   } catch (error) {
  //     print("❌ Erreur lors du chargement du current user : $error");
  //   }
  // }

  /// 🔄 Réinitialiser l'utilisateur après déconnexion
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  /// 🔄 Recharger l'utilisateur après une modification
  Future<void> refreshCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      final token = await firebaseUser.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/get_current_user/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        // ✅ Utiliser la même structure que fetchCurrentUser
        _currentUser = CurrentUser.fromJson(data['user']);

        // Sauvegarder le token FCM après connexion réussie
        //await FCMTokenService.saveTokenToFirebase(firebaseUser.uid);
        if (!kIsWeb) {
          await FCMTokenService.saveTokenToFirebase(firebaseUser.uid);
        }

        notifyListeners();
        if (kDebugMode) {
          print("✅ Utilisateur rechargé avec succès");
        }
      } else {
        if (kDebugMode) {
          print("⚠️ Erreur rechargement utilisateur (${response.statusCode})");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Erreur lors du rechargement : $error");
      }
    }
  }
}