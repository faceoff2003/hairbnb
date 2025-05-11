import 'package:flutter/material.dart';
import 'package:hairbnb/pages/coiffeuses/coiffeuses_map_page.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/models/current_user.dart';
import '../pages/home_page.dart';
import '../pages/horaires_coiffeuse/afficher_rdvs_coiffeuse_page.dart';
import '../pages/mes_commandes/mes_commandes_page.dart';
import '../services/auth_services/logout_service.dart';
import '../pages/chat/messages_page.dart';
import '../pages/profil/show_profile_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });


  /// Gestion de la navigation en fonction de l'index
  Future<void> _handleTap(BuildContext context, int index) async {

    final CurrentUser? currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

    if (index == 5) {
      // Déconnexion
      await LogoutService.confirmLogout(context);
    } else if (index == 1) {
      // Rechercher
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CoiffeusesListPage()),
      );
    }else if (index == 2) {
      // Réservation
      if (currentUser?.type == "coiffeuse") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RendezVousPage(coiffeuseId: currentUser!.idTblUser,)),
        );
      }
      else if (currentUser?.type == "client") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MesCommandesPage(currentUser: currentUser!)),
        );
      }
    } else if (index == 3) {
      // Messages
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MessagesPage(),
        ),
      );
    } else if (index == 4) {
      // Profil
      if (currentUser != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(currentUser: currentUser,),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur : Utilisateur non connecté."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    else if (index == 0) {
      // Messages
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
    else {
      // Navigation normale
      onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleTap(context, index),
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
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.shopping_cart_checkout),
        //   label: 'Panier',
        // ),
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
