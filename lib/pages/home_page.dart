import 'package:flutter/material.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../services/my_drawer_service/hairbnb_scaffold.dart';
import '../services/providers/current_user_provider.dart';
import 'avis/mes_avis_en_attente_page.dart';
import 'avis/services/debug_avis_screen.dart';
import 'avis/widgets/avis_badge_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  /// 🔔 Fonction appelée quand on clique sur le badge d'avis
  void _navigateToAvisEnAttente() {
    //print("🔔 Navigation vers avis en attente");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MesAvisEnAttenteScreen(),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  /// 🧪 Navigation vers l'écran de debug
  void _navigateToDebug() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebugAvisScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;

    return HairbnbScaffold(
      body: Column(
        children: [
          // BADGE EN HAUT (s'affiche seulement s'il y a des avis)
          if (currentUser?.type == 'Client')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: AvisBadgeText(
              onTap: _navigateToAvisEnAttente,
            ),
          ),

          // 🎯 CONTENU PRINCIPAL (centré)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Bienvenue, ${currentUser?.nom ?? ''} ${currentUser?.prenom ?? ''}",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),

                  // 🧪 BOUTON DEBUG TEMPORAIRE
                  // Container(
                  //   padding: EdgeInsets.all(16),
                  //   margin: EdgeInsets.symmetric(horizontal: 20),
                  //   decoration: BoxDecoration(
                  //     color: Colors.red[50],
                  //     border: Border.all(color: Colors.red[200]!),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       Icon(Icons.bug_report, color: Colors.red, size: 30),
                  //       SizedBox(height: 8),
                  //       Text(
                  //         '🚨 PROBLÈME DÉTECTÉ',
                  //         style: TextStyle(
                  //           fontWeight: FontWeight.bold,
                  //           color: Colors.red[700],
                  //         ),
                  //       ),
                  //       SizedBox(height: 4),
                  //       Text(
                  //         'Erreur: "No TblClient matches"',
                  //         style: TextStyle(
                  //           fontSize: 12,
                  //           color: Colors.red[600],
                  //         ),
                  //       ),
                  //       SizedBox(height: 12),
                  //       ElevatedButton.icon(
                  //         onPressed: _navigateToDebug,
                  //         icon: Icon(Icons.build),
                  //         label: Text('🧪 DIAGNOSTIQUER'),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: Colors.red,
                  //           foregroundColor: Colors.white,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  const SizedBox(height: 20),

                  if (currentUser?.type == 'Client')
                  ElevatedButton.icon(
                    onPressed: _navigateToAvisEnAttente,
                    icon: Icon(Icons.rate_review),
                    label: Text("Voir mes avis en attente"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}











// import 'package:flutter/material.dart';
// import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// import 'package:provider/provider.dart';
// import '../services/my_drawer_service/hairbnb_scaffold.dart';
// import '../services/providers/current_user_provider.dart';
// import 'avis/mes_avis_en_attente_page.dart';
// import 'avis/widgets/avis_badge_widget.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _currentIndex = 0;
//
//   /// 🔔 Fonction appelée quand on clique sur le badge d'avis
//   void _navigateToAvisEnAttente() {
//     print("🔔 Navigation vers avis en attente");
//
//     // 🎯 Navigation vers l'écran des avis en attente
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MesAvisEnAttenteScreen(),
//       ),
//     ).then((result) {
//       // 🔄 Optionnel: Recharger le badge quand on revient
//       if (result == true) {
//         setState(() {}); // Force le rebuild du badge
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//
//     return HairbnbScaffold(
//       body: Column(
//         children: [
//           // 🎯 BADGE EN HAUT (s'affiche seulement s'il y a des avis)
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             child: AvisBadgeText(
//               onTap: _navigateToAvisEnAttente, // 🔗 Connecté à la vraie navigation
//             ),
//           ),
//
//           // 🎯 CONTENU PRINCIPAL (centré)
//           Expanded(
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "Bienvenue, ${currentUser?.nom ?? ''} ${currentUser?.prenom ?? ''}",
//                     style: const TextStyle(fontSize: 20),
//                   ),
//                   const SizedBox(height: 20),
//
//                   // 🎯 Optionnel: Bouton de test pour aller directement aux avis
//                   ElevatedButton.icon(
//                     onPressed: _navigateToAvisEnAttente,
//                     icon: Icon(Icons.rate_review),
//                     label: Text("Voir mes avis en attente"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//
//                   // Vos autres widgets...
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
// }
//
//
//
//
//
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // import 'package:provider/provider.dart';
// // import '../services/my_drawer_service/hairbnb_scaffold.dart';
// // import '../services/providers/current_user_provider.dart';
// // import 'avis/widgets/avis_badge_widget.dart';
// //
// // class HomePage extends StatefulWidget {
// //   const HomePage({super.key});
// //
// //   @override
// //   _HomePageState createState() => _HomePageState();
// // }
// //
// // class _HomePageState extends State<HomePage> {
// //   int _currentIndex = 0;
// //
// //   /// 🔔 Fonction appelée quand on clique sur le badge d'avis
// //   void _navigateToAvisEnAttente() {
// //     if (kDebugMode) {
// //       print("🔔 Navigation vers avis en attente");
// //     }
// //
// //     // 🚧 TODO: Remplacer par votre navigation vers l'écran des avis en attente
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text('Navigation vers avis en attente - À implémenter'),
// //         backgroundColor: Colors.orange,
// //         duration: Duration(seconds: 2),
// //       ),
// //     );
// //
// //     // Exemple de navigation (quand vous aurez créé l'écran) :
// //     // Navigator.push(
// //     //   context,
// //     //   MaterialPageRoute(builder: (context) => MesAvisEnAttenteScreen()),
// //     // );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
// //
// //     return HairbnbScaffold(
// //       body: Column(
// //         children: [
// //           // 🎯 BADGE EN HAUT (s'affiche seulement s'il y a des avis)
// //           Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.all(16),
// //             child: AvisBadgeText(
// //               onTap: _navigateToAvisEnAttente,
// //             ),
// //           ),
// //
// //           // 🎯 CONTENU PRINCIPAL (centré)
// //           Expanded(
// //             child: Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Text(
// //                     "Bienvenue, ${currentUser?.nom ?? ''} ${currentUser?.prenom ?? ''}",
// //                     style: const TextStyle(fontSize: 20),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   // ElevatedButton.icon(
// //                   //   onPressed: () {
// //                   //     Navigator.push(
// //                   //       context,
// //                   //       MaterialPageRoute(builder: (context) => RdvCoiffeusePage()),
// //                   //     );
// //                   //   },
// //                   //   icon: const Icon(Icons.calendar_today),
// //                   //   label: const Text("Voir mes RDVs"),
// //                   //   style: ElevatedButton.styleFrom(
// //                   //     backgroundColor: Colors.orange,
// //                   //     foregroundColor: Colors.white,
// //                   //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                   //     shape: RoundedRectangleBorder(
// //                   //       borderRadius: BorderRadius.circular(12),
// //                   //     ),
// //                   //   ),
// //                   // ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //       bottomNavigationBar: BottomNavBar(
// //         currentIndex: _currentIndex,
// //         onTap: (index) {
// //           setState(() {
// //             _currentIndex = index;
// //           });
// //         },
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // // import 'package:provider/provider.dart';
// // // import '../services/my_drawer_service/hairbnb_scaffold.dart';
// // // import '../services/providers/current_user_provider.dart';
// // //
// // // class HomePage extends StatefulWidget {
// // //   const HomePage({super.key});
// // //
// // //   @override
// // //   _HomePageState createState() => _HomePageState();
// // // }
// // //
// // // class _HomePageState extends State<HomePage> {
// // //   int _currentIndex = 0;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
// // //
// // //     return HairbnbScaffold(
// // //       body: Center(
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             Text(
// // //               "Bienvenue, ${currentUser?.nom ?? ''} ${currentUser?.prenom ?? ''}",
// // //               style: const TextStyle(fontSize: 20),
// // //             ),
// // //             const SizedBox(height: 20),
// // //             // ElevatedButton.icon(
// // //             //   onPressed: () {
// // //             //     Navigator.push(
// // //             //       context,
// // //             //       MaterialPageRoute(builder: (context) => RdvCoiffeusePage()),
// // //             //     );
// // //             //   },
// // //             //   icon: const Icon(Icons.calendar_today),
// // //             //   label: const Text("Voir mes RDVs"),
// // //             //   style: ElevatedButton.styleFrom(
// // //             //     backgroundColor: Colors.orange,
// // //             //     foregroundColor: Colors.white,
// // //             //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // //             //     shape: RoundedRectangleBorder(
// // //             //       borderRadius: BorderRadius.circular(12),
// // //             //     ),
// // //             //   ),
// // //             // ),
// // //           ],
// // //         ),
// // //       ),
// // //       bottomNavigationBar: BottomNavBar(
// // //         currentIndex: _currentIndex,
// // //         onTap: (index) {
// // //           setState(() {
// // //             _currentIndex = index;
// // //           });
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }