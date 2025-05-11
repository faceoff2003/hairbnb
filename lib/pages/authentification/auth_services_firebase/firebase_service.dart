import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // État de l'initialisation
  bool get isInitialized => _isInitialized;
  bool _isInitialized = !kIsWeb; // Déjà initialisé pour mobile

  // Méthode pour vérifier si Firebase est initialisé (pour le web)
  Future<bool> waitForInitialization() async {
    // Si on est sur mobile ou si Firebase est déjà initialisé, on retourne immédiatement
    if (!kIsWeb || _isInitialized) {
      return true;
    }

    // Sur le web, on attend au maximum 5 secondes pour l'initialisation
    int attempts = 0;
    while (!_isInitialized && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    return _isInitialized;
  }

  // Méthode appelée quand Firebase est initialisé
  void setInitialized() {
    _isInitialized = true;
  }

  // Méthode pour se connecter qui vérifie d'abord l'initialisation
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    await waitForInitialization();
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Autres méthodes Firebase qui nécessitent l'initialisation
  Future<User?> getCurrentUser() async {
    await waitForInitialization();
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> signOut() async {
    await waitForInitialization();
    return FirebaseAuth.instance.signOut();
  }

// Vous pouvez ajouter d'autres méthodes Firebase ici
}