import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../pages/authentification/login_page.dart';
import '../providers/current_user_provider.dart';

class LogoutService {
  static bool isProcessing = false;

  /// Affiche une boîte de dialogue pour confirmer la déconnexion
  static Future<void> confirmLogout(BuildContext context) async {
    if (isProcessing) return; // Empêche les appels multiples
    isProcessing = true;

    final bool shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    ) ?? false;

    if (shouldLogout) {
      await logout(context);
    }

    isProcessing = false;
  }

  /// 🔄 Déconnexion Firebase et réinitialisation du `UserProvider`
  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // 🔥 Réinitialiser `UserProvider`
      Provider.of<CurrentUserProvider>(context, listen: false).clearUser();

      // 🔄 Redirection vers `LoginPage`
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la déconnexion.")),
      );
    }
  }
}