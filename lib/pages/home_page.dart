import 'package:flutter/material.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../services/providers/current_user_provider.dart';
import '../widgets/Custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: currentUser == null
            ? const CircularProgressIndicator()
            : Text("Bienvenue, ${currentUser.nom} ${currentUser.prenom}"),
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
// import 'package:hairbnb/models/current_user.dart';
//
// import '../widgets/Custom_app_bar.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);
//
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _currentIndex = 0;
//   CurrentUser? currentUser;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         onUserLoaded: (user) {
//           setState(() {
//             currentUser = user;
//           });
//         },
//       ),
//       body: Center(
//         child: currentUser == null
//             ? const CircularProgressIndicator()
//             : Text("Bienvenue, ${currentUser!.nom} ${currentUser!.prenom}"),
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
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // class HomePage extends StatefulWidget {
// //   const HomePage({Key? key}) : super(key: key);
// //
// //   @override
// //   _HomePageState createState() => _HomePageState();
// // }
// //
// // class _HomePageState extends State<HomePage> {
// //   int _currentIndex = 0;
// //   Map<String, dynamic>? currentUser;
// //   String userName = "Chargement...";
// //   String userPhoto = "";
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final String baseUrl = "http://192.168.0.248:8000"; // 🔥 URL de ton backend
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchCurrentUser();
// //   }
// //
// //   /// 🔹 Récupérer les infos utilisateur depuis Django
// //   Future<void> _fetchCurrentUser() async {
// //     try {
// //       User? firebaseUser = _auth.currentUser;
// //       if (firebaseUser == null) {
// //         setState(() {
// //           userName = "Utilisateur non connecté";
// //           userPhoto = "";
// //         });
// //         return;
// //       }
// //
// //       String firebaseUid = firebaseUser.uid; // Récupération de l'UUID Firebase
// //
// //       print("*************************************************");
// //       print("🔥 UUID Firebase envoyé: $firebaseUid");
// //       print("*************************************************");
// //
// //       final response = await http.get(
// //         Uri.parse('$baseUrl/api/get_current_user/$firebaseUid/'),
// //         headers: {'Content-Type': 'application/json'},
// //       );
// //
// //       print("*************************************************");
// //       print("Réponse de Django : ${response.body}");
// //       print("*************************************************");
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         setState(() {
// //           currentUser = data['user']; // Stocke l'utilisateur
// //           userName = "${currentUser!['nom']} ${currentUser!['prenom']} (${currentUser!['type']})";
// //
// //           // 🔥 Correction de l'image : Vérifier et compléter l'URL
// //           String imagePath = currentUser!['photo_profil'] ?? "";
// //           if (imagePath.isNotEmpty && !imagePath.startsWith("http")) {
// //             userPhoto = "$baseUrl$imagePath"; // Ajoute l'URL complète
// //           } else {
// //             userPhoto = imagePath;
// //           }
// //         });
// //       } else {
// //         setState(() {
// //           userName = "Utilisateur introuvable";
// //           userPhoto = "";
// //         });
// //       }
// //     } catch (error) {
// //       print("Erreur de connexion : $error");
// //       setState(() {
// //         userName = "Erreur de connexion";
// //         userPhoto = "";
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Row(
// //           children: [
// //             if (userPhoto.isNotEmpty)
// //               CircleAvatar(
// //                 backgroundImage: NetworkImage(userPhoto),
// //                 radius: 20,
// //               )
// //             else
// //               const CircleAvatar(
// //                 backgroundColor: Colors.grey,
// //                 radius: 20,
// //                 child: Icon(Icons.person, color: Colors.white),
// //               ),
// //             const SizedBox(width: 10),
// //             RichText(
// //               text: TextSpan(
// //                 style: const TextStyle(fontSize: 18, color: Colors.black), // 🔥 Style principal
// //                 children: [
// //                   TextSpan(
// //                     text: "${currentUser!['nom']} ${currentUser!['prenom']} ",
// //                     style: const TextStyle(fontWeight: FontWeight.bold), // 🔥 Texte principal en gras
// //                   ),
// //                   TextSpan(
// //                     text: "(${currentUser!['type']})",
// //                     style: const TextStyle(fontSize: 14), // 🔥 Texte plus petit
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //         backgroundColor: Colors.orange,
// //       ),
// //       body: Center(child: Text("Bienvenue, $userName")),
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
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // //
// // // class HomePage extends StatefulWidget {
// // //   const HomePage({Key? key}) : super(key: key);
// // //
// // //   @override
// // //   _HomePageState createState() => _HomePageState();
// // // }
// // //
// // // class _HomePageState extends State<HomePage> {
// // //   int _currentIndex = 0;
// // //   Map<String, dynamic>? currentUser; // Stocke l'utilisateur pour le réutiliser
// // //   String userName = "Chargement...";
// // //   String userPhoto = "";
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchCurrentUser();
// // //   }
// // //
// // //   /// 🔹 Fonction pour récupérer les infos de l'utilisateur depuis Django
// // //   Future<void> _fetchCurrentUser() async {
// // //     try {
// // //       User? firebaseUser = _auth.currentUser;
// // //       if (firebaseUser == null) {
// // //         setState(() {
// // //           userName = "Utilisateur non connecté";
// // //           userPhoto = "";
// // //         });
// // //         return;
// // //       }
// // //
// // //       String firebaseUid = firebaseUser.uid; // Récupération de l'UUID Firebase
// // //
// // //       print("*************************************************");
// // //       print("🔥 UUID Firebase envoyé: $firebaseUid");
// // //       print("*************************************************");
// // //
// // //       final response = await http.get(
// // //         Uri.parse('http://192.168.0.248:8000/api/get_current_user/$firebaseUid/'),
// // //         headers: {
// // //           'Content-Type': 'application/json',
// // //         },
// // //       );
// // //
// // //       print("*************************************************");
// // //       print("Réponse de Django : ${response.body}");
// // //       print("*************************************************");
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //
// // //         setState(() {
// // //           currentUser = data['user']; // Stocke l'objet utilisateur
// // //           userName = "${currentUser!['nom']} ${currentUser!['prenom']}";
// // //           userPhoto = currentUser!['photo_profil'] ?? ""; // Vérifie si la photo existe
// // //         });
// // //       } else {
// // //         setState(() {
// // //           userName = "Utilisateur introuvable";
// // //           userPhoto = "";
// // //         });
// // //       }
// // //     } catch (error) {
// // //       print("Erreur de connexion : $error");
// // //       setState(() {
// // //         userName = "Erreur de connexion";
// // //         userPhoto = "";
// // //       });
// // //     }
// // //   }
// // //
// // //   // 🔹 Liste des pages avec passage de l'objet utilisateur
// // //   final List<Widget> _pages = [];
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Row(
// // //           children: [
// // //             if (userPhoto.isNotEmpty)
// // //               CircleAvatar(
// // //                 backgroundImage: NetworkImage(userPhoto),
// // //                 radius: 20,
// // //               )
// // //             else
// // //               const CircleAvatar(
// // //                 backgroundColor: Colors.grey,
// // //                 radius: 20,
// // //                 child: Icon(Icons.person, color: Colors.white),
// // //               ),
// // //             const SizedBox(width: 10),
// // //             Text(userName, style: const TextStyle(fontSize: 18)),
// // //           ],
// // //         ),
// // //         backgroundColor: Colors.purple,
// // //       ),
// // //       body: _pages.isEmpty
// // //           ? Center(child: CircularProgressIndicator()) // Chargement
// // //           : _pages[_currentIndex], // Affiche la page sélectionnée
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
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // //
// // // class HomePage extends StatefulWidget {
// // //   const HomePage({Key? key}) : super(key: key);
// // //
// // //   @override
// // //   _HomePageState createState() => _HomePageState();
// // // }
// // //
// // // class _HomePageState extends State<HomePage> {
// // //   int _currentIndex = 0;
// // //   String userName = "Chargement...";
// // //   String userPhoto = "";
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchCurrentUser();
// // //   }
// // //
// // //   Future<void> _fetchCurrentUser() async {
// // //     try {
// // //       User? firebaseUser = _auth.currentUser;
// // //       if (firebaseUser == null) {
// // //         setState(() {
// // //           userName = "Utilisateur non connecté";
// // //           userPhoto = "";
// // //         });
// // //         return;
// // //       }
// // //
// // //       // Récupérer le token d'authentification Firebase
// // //       String? token = await firebaseUser.getIdToken();
// // //
// // //       print("*************************************************");
// // //       print("🔥 Token Firebase envoyé: $token");  // ✅ Vérifie que ce n'est pas `null`
// // //       print("*************************************************");
// // //
// // //       final response = await http.get(
// // //         Uri.parse('http://192.168.0.248:8000/api/get_current_user/'),
// // //         headers: {
// // //           'Authorization': 'Bearer $token',
// // //           'Content-Type': 'application/json',
// // //         },
// // //       );
// // //
// // //       print("*************************************************");
// // //       print("Réponse de Django : ${response.body}");
// // //       print("*************************************************");
// // //
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //         setState(() {
// // //           userName = "${data['user']['first_name']} ${data['user']['last_name']}";
// // //           userPhoto = data['user']['photo'] ?? ""; // Assurez-vous que l'API envoie une URL de photo
// // //         });
// // //       } else {
// // //         setState(() {
// // //           userName = "Utilisateur introuvable";
// // //           userPhoto = "";
// // //         });
// // //       }
// // //     } catch (error) {
// // //       setState(() {
// // //         userName = "Erreur de connexion";
// // //         userPhoto = "";
// // //       });
// // //     }
// // //   }
// // //
// // //   // Définir les widgets pour chaque page
// // //   final List<Widget> _pages = [
// // //     Center(child: Text('Page Accueil')),
// // //     Center(child: Text('Page Rechercher')),
// // //     Center(child: Text('Page Réservations')),
// // //     Center(child: Text('Page Messages')),
// // //     Center(child: Text('Page Profil')),
// // //   ];
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Row(
// // //           children: [
// // //             if (userPhoto.isNotEmpty)
// // //               CircleAvatar(
// // //                 backgroundImage: NetworkImage(userPhoto),
// // //                 radius: 20,
// // //               )
// // //             else
// // //               const CircleAvatar(
// // //                 backgroundColor: Colors.grey,
// // //                 radius: 20,
// // //                 child: Icon(Icons.person, color: Colors.white),
// // //               ),
// // //             const SizedBox(width: 10),
// // //             Text(userName, style: const TextStyle(fontSize: 18)),
// // //           ],
// // //         ),
// // //         backgroundColor: Colors.purple,
// // //       ),
// // //       body: _pages[_currentIndex],
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
