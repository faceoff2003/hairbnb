import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrentUserProvider with ChangeNotifier {
  CurrentUser? _currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = "https://www.hairbnb.site";

  CurrentUser? get currentUser => _currentUser;

  /// 🔄 Récupérer l'utilisateur depuis Django via token sécurisé
  Future<void> fetchCurrentUser() async {
    if (_currentUser != null) return; // ✅ Déjà chargé

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
        _currentUser = CurrentUser.fromJson(data['user']);
        notifyListeners();
      } else {
        print("⚠️ Utilisateur non trouvé ou non autorisé (${response.statusCode})");
      }
    } catch (error) {
      print("❌ Erreur lors du chargement du current user : $error");
    }
  }

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
        notifyListeners();
        print("✅ Utilisateur rechargé avec succès");
      } else {
        print("⚠️ Erreur rechargement utilisateur (${response.statusCode})");
      }
    } catch (error) {
      print("❌ Erreur lors du rechargement : $error");
    }
  }
}