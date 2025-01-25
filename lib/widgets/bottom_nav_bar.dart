import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/chat/messages_page.dart';
import '../pages/coiffeuses/search_coiffeuse_page.dart';
import '../pages/profil/show_profile_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  /// Méthode pour afficher une boîte de dialogue de confirmation de déconnexion
  Future<void> _confirmLogout(BuildContext context) async {
    final bool shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Annuler
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirmer
              child: const Text('Déconnexion'),// Effacez les données Hive

            ),
          ],
        );
      },
    ) ??
        false;

    if (shouldLogout) {
      await _logout(context);
    }
  }

  /// Méthode de déconnexion avec suppression des données locales
  Future<void> _logout(BuildContext context) async {
    try {
      // Efface les données stockées localement
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Supprime toutes les données de SharedPreferences

      // Déconnexion Firebase
      await FirebaseAuth.instance.signOut();

      // Redirige vers la LoginPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false, // Supprime toutes les routes précédentes
      );
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la déconnexion.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 5) {
          // Si l'utilisateur appuie sur Déconnexion
          _confirmLogout(context); // Affiche une boîte de dialogue de confirmation
        }
        if(index == 1)
        {
          // Si l'utilisateur appuie sur "Rechercher"
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchCoiffeusePage()),
          );
        }
        if(index == 3)
        {
          // Si l'utilisateur appuie sur "Rechercher"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MessagesPage(clientId: 'clientId',)),
          );
        }
        if(index == 4)
        {
          // Si l'utilisateur appuie sur "Rechercher"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserProfilePage(userUuid: 'userUuid',)),
          );
        }
        else {
          onTap(index); // Appel de la méthode pour gérer la navigation
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Rechercher',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Réservations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Déconnexion',
        ),
      ],
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.grey,
    );
  }
}
