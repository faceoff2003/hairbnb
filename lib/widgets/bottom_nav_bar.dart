import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hairbnb/pages/coiffeuses/coiffeuses_map_page.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/models/current_user.dart';
import '../services/auth_services/logout_service.dart';
import '../pages/chat/messages_page.dart';
import '../pages/profil/show_profile_page.dart';
import '../services/providers/get_user_type_service.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);


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
      //final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {

        // Récupérer les détails de l'utilisateur depuis le backend
        //final userDetails = await getIdAndTypeFromUuid(currentUser.uid);
        //final usertype = userDetails?['type'];

        //print('the usertype is :' + usertype);

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
    } else {
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









// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/auth_services/logout_service.dart';
// import '../pages/chat/messages_page.dart';
// import '../pages/coiffeuses/search_coiffeuse_page.dart';
// import '../pages/profil/show_profile_page.dart';
//
// class BottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const BottomNavBar({
//     Key? key,
//     required this.currentIndex,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: (index) async {
//         if (index == 5) {
//           // Si l'utilisateur appuie sur Déconnexion
//           await LogoutService.confirmLogout(context);
//         } else if (index == 1) {
//           // Si l'utilisateur appuie sur "Rechercher"
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const SearchCoiffeusePage()),
//           );
//         } else if (index == 3) {
//           // Si l'utilisateur appuie sur messages
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const MessagesPage(clientId: 'clientId')),
//           );
//         } else if (index == 4) {
//           final currentUser = FirebaseAuth.instance.currentUser;
//           if (currentUser != null) {
//             // Si l'utilisateur appuie sur "Profile"
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => ProfileScreen(userUuid: currentUser.uid),
//               ),
//             );
//           }
//         } else {
//           onTap(index); // Appel de la méthode pour gérer la navigation
//         }
//       },
//       type: BottomNavigationBarType.fixed,
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: 'Accueil',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.search),
//           label: 'Rechercher',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.calendar_today),
//           label: 'Réservations',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.message),
//           label: 'Messages',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Profil',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.logout),
//           label: 'Déconnexion',
//         ),
//       ],
//       selectedItemColor: Colors.purple,
//       unselectedItemColor: Colors.grey,
//     );
//   }
// }


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/auth_services/logout_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../pages/chat/messages_page.dart';
// import '../pages/coiffeuses/search_coiffeuse_page.dart';
// import '../pages/profil/show_profile_page.dart';
//
// class BottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const BottomNavBar({
//     Key? key,
//     required this.currentIndex,
//     required this.onTap,
//   }) : super(key: key);
//
//   // /// Méthode pour afficher une boîte de dialogue de confirmation de déconnexion
//   // Future<void> _confirmLogout(BuildContext context) async {
//   //   final bool shouldLogout = await showDialog<bool>(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return AlertDialog(
//   //         title: const Text('Déconnexion'),
//   //         content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
//   //         actions: [
//   //           TextButton(
//   //             onPressed: () => Navigator.of(context).pop(false), // Annuler
//   //             child: const Text('Annuler'),
//   //           ),
//   //           TextButton(
//   //             onPressed: () => Navigator.of(context).pop(true), // Confirmer
//   //             child: const Text('Déconnexion'),// Effacez les données Hive
//   //
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   ) ??
//   //       false;
//   //
//   //   if (shouldLogout) {
//   //     await _logout(context);
//   //   }
//   // }
//   //
//   // /// Méthode de déconnexion avec suppression des données locales
//   // Future<void> _logout(BuildContext context) async {
//   //   try {
//   //     // Efface les données stockées localement
//   //     final prefs = await SharedPreferences.getInstance();
//   //     await prefs.clear(); // Supprime toutes les données de SharedPreferences
//   //
//   //     // Déconnexion Firebase
//   //     await FirebaseAuth.instance.signOut();
//   //
//   //     // Redirige vers la LoginPage
//   //     Navigator.pushAndRemoveUntil(
//   //       context,
//   //       MaterialPageRoute(builder: (context) => const LoginPage()),
//   //           (route) => false, // Supprime toutes les routes précédentes
//   //     );
//   //   } catch (e) {
//   //     debugPrint("Erreur lors de la déconnexion : $e");
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Erreur lors de la déconnexion.")),
//   //     );
//   //   }
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: (index) {
//         if (index == 5) {
//           // Si l'utilisateur appuie sur Déconnexion
//           confirmLogout(context); // Affiche une boîte de dialogue de confirmation
//         }
//         if(index == 1)
//         {
//           // Si l'utilisateur appuie sur "Rechercher"
//           Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const SearchCoiffeusePage()),
//           );
//         }
//         if(index == 3)
//         {
//           // Si l'utilisateur appuie sur messages
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const MessagesPage(clientId: 'clientId',)),
//           );
//         }
//         if(index == 4)
//         {
//           final currentUser = FirebaseAuth.instance.currentUser;
//           // Si l'utilisateur appuie sur "Profile"
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => ProfileScreen(userUuid: currentUser!.uid)),
//             //MaterialPageRoute(builder: (context) => UserGreetingPage(userUuid: currentUser!.uid)),
//           );
//         }
//         else {
//           onTap(index); // Appel de la méthode pour gérer la navigation
//         }
//       },
//       type: BottomNavigationBarType.fixed,
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: 'Accueil',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.search),
//           label: 'Rechercher',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.calendar_today),
//           label: 'Réservations',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.message),
//           label: 'Messages',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Profil',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.logout),
//           label: 'Déconnexion',
//         ),
//       ],
//       selectedItemColor: Colors.purple,
//       unselectedItemColor: Colors.grey,
//     );
//   }
// }
