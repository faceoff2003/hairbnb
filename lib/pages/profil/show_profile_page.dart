import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/auth_services/logout_service.dart';
import '../../services/providers/get_user_type_service.dart';
import '../salon/salon_services_list/show_services_list_page.dart';

class ProfileScreen extends StatefulWidget {
  final CurrentUser currentUser;
  //final bool isCoiffeuse;

  const ProfileScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = "";
  String baseUrl = "";
  //late CurrentUser currentUser;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    //final currentUser = Provider.of<CurrentUserProvider>(context, listen: false);

    baseUrl = 'http://192.168.0.248:8000/api/get_user_profile/${widget.currentUser.uuid}/';

    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Erreur : ${response.statusCode} ${response.reasonPhrase}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur réseau : $e";
        isLoading = false;
      });
    }
  }

  String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";

  void _editField(String fieldName, String currentValue) {
    final TextEditingController fieldController = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Modifier $fieldName"),
          content: TextField(
            controller: fieldController,
            decoration: InputDecoration(hintText: "Nouvelle valeur pour $fieldName"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (fieldController.text.isNotEmpty && fieldController.text != currentValue) {
                  await updateUserProfile(widget.currentUser.uuid, {fieldName: fieldController.text});
                  fetchUserProfile();
                }
              },
              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
        title: const Text("Profil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
          : userData == null
          ? const Center(child: Text("Aucune donnée à afficher."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // -- Image de profil
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: widget.currentUser.photoProfil != null &&
                      widget.currentUser.photoProfil!.isNotEmpty
                      ? NetworkImage('http://192.168.0.248:8000${widget.currentUser.photoProfil}')
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  onBackgroundImageError: (exception, stackTrace) {
                    print("Erreur de chargement de l'image : $exception");
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text("Type : ${userData!['type']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 10),

            // Informations générales
            const Text("Informations générales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _infoTile(Icons.email, "Email", widget.currentUser.email),
            _infoTile(Icons.phone, "Téléphone", widget.currentUser.numeroTelephone),

            // Adresse complète
            if (userData!['adresse'] != null) _infoTile(Icons.home, "Adresse", userData!['adresse']),
            if (userData!['rue'] != null) _infoTile(Icons.location_on, "Rue", userData!['rue']),
            if (userData!['commune'] != null) _infoTile(Icons.location_city, "Commune", userData!['commune']),
            if (userData!['code_postal'] != null) _infoTile(Icons.local_post_office, "Code postal", userData!['code_postal']),

            const Divider(),
            const SizedBox(height: 10),

            // Informations professionnelles (Coiffeuse uniquement)
            if (widget.currentUser.type=='coiffeuse') ...[
              const Text("Informations professionnelles", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _infoTile(Icons.business, "Dénomination Sociale", userData!['denomination_sociale']),
              _infoTile(Icons.money, "TVA", userData!['tva']),
              _infoTile(Icons.map, "Position", userData!['position']),
            ],

            const Divider(),
            const SizedBox(height: 10),

            // Bouton Services (pour coiffeuse uniquement)
            if (widget.currentUser.type=='coiffeuse')
              _actionTile(Icons.build, "Services", () async {
                final userDetails = await getIdAndTypeFromUuid(userData?['uuid']);
                if (userDetails != null) {
                  final idTblUser = userDetails['idTblUser'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Erreur lors de la récupération des services.")),
                  );
                }
              }),

            _actionTile(Icons.settings, "Paramètres", () {}),
            _actionTile(Icons.logout, "Déconnexion", () async {
              await LogoutService.confirmLogout(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, dynamic value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(value != null && value.toString().isNotEmpty ? value.toString() : "Non spécifié"),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _editField(label, value ?? ""),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  Future<void> updateUserProfile(String userUuid, Map<String, dynamic> updatedData) async {
    final String apiUrl = 'http://192.168.0.248:8000/api/update_user_profile/$userUuid/';
    try {
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mis à jour avec succès"), backgroundColor: Colors.green));
      } else {
        throw Exception("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur réseau : $e"), backgroundColor: Colors.red));
    }
  }
}

















// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../../services/auth_services/logout_service.dart';
// import '../../services/providers/get_user_type_service.dart';
// import '../salon/salon_services_list/show_services_list_page.dart';
//
// class ProfileScreen extends StatefulWidget {
//   final String userUuid;
//   final bool isCoiffeuse;
//
//   const ProfileScreen({Key? key, required this.userUuid, required this.isCoiffeuse}) : super(key: key);
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   Map<String, dynamic>? userData;
//   bool isLoading = true;
//   String errorMessage = "";
//   String baseUrl = "";
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUserProfile();
//   }
//
//   Future<void> fetchUserProfile() async {
//     baseUrl = 'http://192.168.0.248:8000/api/get_user_profile/${widget.userUuid}/';
//     try {
//       final response = await http.get(Uri.parse(baseUrl));
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           userData = data['data'];
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           errorMessage = "Erreur : ${response.statusCode} ${response.reasonPhrase}";
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = "Erreur réseau : $e";
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back),
//         ),
//         title: const Text("Profil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : errorMessage.isNotEmpty
//           ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
//           : userData == null
//           ? const Center(child: Text("Aucune donnée à afficher."))
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // -- Image et Nom
//             CircleAvatar(
//               radius: 60,
//               backgroundImage: userData!['photo_profil'] != null && userData!['photo_profil'].isNotEmpty
//                   ? NetworkImage('http://192.168.0.248:8000${userData!['photo_profil']}')
//                   : const AssetImage('assets/default_avatar.png') as ImageProvider,
//             ),
//             const SizedBox(height: 10),
//             Text("${userData!['prenom']} ${userData!['nom']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 5),
//             Text("Type : ${userData!['type']}", style: const TextStyle(fontSize: 16)),
//             const Divider(),
//
//             // Informations générales
//             ListTile(
//               leading: const Icon(Icons.email),
//               title: Text(userData!['email'] ?? "Non spécifié"),
//             ),
//             ListTile(
//               leading: const Icon(Icons.phone),
//               title: Text(userData!['numero_telephone'] ?? "Non spécifié"),
//             ),
//             ListTile(
//               leading: const Icon(Icons.home),
//               title: Text(
//                 "${userData!['adresse']}, ${userData!['rue']}, ${userData!['commune']} - ${userData!['code_postal']}",
//               ),
//             ),
//
//             const Divider(),
//             if (userData!['type'] == 'coiffeuse') ...[
//               ListTile(
//                 leading: const Icon(Icons.business),
//                 title: Text("Dénomination sociale : ${userData!['denomination_sociale'] ?? "Non spécifiée"}"),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.money),
//                 title: Text("TVA : ${userData!['tva'] ?? "Non spécifiée"}"),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.location_on),
//                 title: Text("Position : ${userData!['position'] ?? "Non spécifiée"}"),
//               ),
//             ],
//
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.settings),
//               title: const Text("Services"),
//               onTap: () async {
//                 if (widget.isCoiffeuse) {
//                   final userDetails = await getIdAndTypeFromUuid(userData?['uuid']);
//                   if (userDetails != null) {
//                     final idTblUser = userDetails['idTblUser'];
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
//                       ),
//                     );
//                   }
//                 }
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Déconnexion"),
//               textColor: Colors.red,
//               onTap: () async {
//                 await LogoutService.confirmLogout(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // import '../../services/auth_services/logout_service.dart';
// // import '../../services/providers/get_user_type_service.dart';
// // import '../salon/salon_services_list/show_services_list_page.dart';
// //
// // class ProfileScreen extends StatefulWidget {
// //   final String userUuid;
// //   final bool isCoiffeuse;
// //
// //   const ProfileScreen({Key? key, required this.userUuid,required this.isCoiffeuse}) : super(key: key);
// //
// //   @override
// //   State<ProfileScreen> createState() => _ProfileScreenState();
// // }
// //
// // class _ProfileScreenState extends State<ProfileScreen> {
// //   Map<String, dynamic>? userData;
// //   bool isLoading = true;
// //   String errorMessage = "";
// //   String baseUrl = "";
// //   bool isLoadingServices = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchUserProfile();
// //   }
// //
// //   Future<void> fetchUserProfile() async {
// //     baseUrl =
// //     'http://192.168.0.248:8000/api/get_user_profile/${widget.userUuid}/';
// //
// //     try {
// //       final response = await http.get(Uri.parse(baseUrl));
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         setState(() {
// //           userData = data['data'];
// //           isLoading = false;
// //         });
// //       } else {
// //         setState(() {
// //           errorMessage =
// //           "Erreur : ${response.statusCode} ${response.reasonPhrase}";
// //           isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       setState(() {
// //         errorMessage = "Erreur réseau : $e";
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   String capitalize(String s) =>
// //       s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";
// //
// //   void _editField(String fieldName, String currentValue) {
// //     final TextEditingController fieldController = TextEditingController(
// //         text: currentValue);
// //
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: Text("Modifier $fieldName"),
// //           content: TextField(
// //             controller: fieldController,
// //             decoration: InputDecoration(
// //                 hintText: "Nouvelle valeur pour $fieldName"),
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: const Text("Annuler"),
// //             ),
// //             TextButton(
// //               onPressed: () async {
// //                 Navigator.pop(context); // Ferme le dialogue
// //                 if (fieldController.text.isNotEmpty &&
// //                     fieldController.text != currentValue) {
// //                   // Met à jour le champ via l'API
// //                   await updateUserProfile(
// //                       widget.userUuid, {fieldName: fieldController.text});
// //                   // Rafraîchit les données après la mise à jour
// //                   fetchUserProfile();
// //                 }
// //               },
// //               child: const Text("Sauvegarder"),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     var isDark = MediaQuery
// //         .of(context)
// //         .platformBrightness == Brightness.dark;
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         leading: IconButton(
// //           onPressed: () => Navigator.pop(context),
// //           icon: const Icon(Icons.arrow_back),
// //         ),
// //         title: const Text(
// //           "Profil",
// //           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //         ),
// //         actions: [
// //           IconButton(
// //             onPressed: () {
// //
// //             },
// //             icon: Icon(isDark ? Icons.sunny : Icons.nightlight_round),
// //           )
// //         ],
// //       ),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : errorMessage.isNotEmpty
// //           ? Center(
// //         child: Text(
// //           errorMessage,
// //           style: const TextStyle(color: Colors.red, fontSize: 16),
// //         ),
// //       )
// //           : userData == null
// //           ? const Center(child: Text("Aucune donnée à afficher."))
// //           : SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           children: [
// //             // -- Image et Nom
// //             Stack(
// //               children: [
// //                 SizedBox(
// //                   width: 120,
// //                   height: 120,
// //                   child: ClipRRect(
// //                     borderRadius: BorderRadius.circular(100),
// //                     child: userData!['photo_profil'] != null &&
// //                         userData!['photo_profil'].isNotEmpty
// //                         ? Image.network(
// //                       userData!['photo_profil'].startsWith('http://') ||
// //                           userData!['photo_profil'].startsWith('https://')
// //                           ? userData!['photo_profil']
// //                           : 'http://192.168.0.248:8000${userData!['photo_profil']}',
// //                       fit: BoxFit.cover,
// //                       errorBuilder: (context, error, stackTrace) {
// //                         return const Icon(Icons.person, size: 50);
// //                       },
// //                     )
// //                         : const Image(
// //                       image: AssetImage('assets/default_avatar.png'),
// //                       fit: BoxFit.cover,
// //                     ),
// //                   ),
// //                 ),
// //                 Positioned(
// //                   bottom: 0,
// //                   right: 0,
// //                   child: Container(
// //                     width: 35,
// //                     height: 35,
// //                     decoration: BoxDecoration(
// //                       borderRadius: BorderRadius.circular(100),
// //                       color: Colors.purple,
// //                     ),
// //                     child: const Icon(
// //                       Icons.edit,
// //                       color: Colors.white,
// //                       size: 20,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //
// //             const SizedBox(height: 10),
// //             Text(
// //               "${capitalize(userData!['prenom'])} ${capitalize(
// //                   userData!['nom'])}",
// //               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 5),
// //             Text(
// //               "Type : ${userData!['type']}",
// //               style: const TextStyle(fontSize: 16),
// //             ),
// //             const SizedBox(height: 20),
// //
// //             const Divider(),
// //             const SizedBox(height: 10),
// //
// //             // Informations générales
// //             const Text(
// //               "Informations générales",
// //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 10),
// //             ListTile(
// //               leading: const Icon(Icons.email),
// //               title: Text("${userData!['email']}"),
// //               trailing: IconButton(
// //                 icon: const Icon(Icons.edit),
// //                 onPressed: () => _editField("Email", userData!['email'] ?? ""),
// //               ),
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.phone),
// //               title: Text("${userData!['numero_telephone']}"),
// //               trailing: IconButton(
// //                 icon: const Icon(Icons.edit),
// //                 onPressed: () =>
// //                     _editField(
// //                         "Téléphone", userData!['numero_telephone'] ?? ""),
// //               ),
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.home),
// //               title: Text(
// //                   "${userData!['adresse'] ??
// //                       'Non spécifiée'},\n ${userData!['code_postal'] ??
// //                       'Non spécifié'}, ${userData!['commune'] ??
// //                       'Non spécifiée'}"),
// //               trailing: IconButton(
// //                 icon: const Icon(Icons.edit),
// //                 onPressed: () =>
// //                     _editField("Adresse", userData!['Adresse'] ?? ""),
// //               ),
// //             ),
// //
// //             const Divider(),
// //             const SizedBox(height: 10),
// //
// //             // Informations professionnelles (si applicable)
// //             if (userData!['type'] == 'coiffeuse') ...[
// //               const Text(
// //                 "Informations professionnelles",
// //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 10),
// //               ListTile(
// //                 leading: const Icon(Icons.business),
// //                 title: Text(
// //                     "${userData!['denomination_sociale'] ?? 'Non spécifiée'}"),
// //                 trailing: IconButton(
// //                   icon: const Icon(Icons.edit),
// //                   onPressed: () =>
// //                       _editField("Dénomination sociale",
// //                           userData!['Dénomination sociale'] ?? ""),
// //                 ),
// //               ),
// //               ListTile(
// //                 leading: const Icon(Icons.money),
// //                 title: Text("TVA : ${userData!['tva'] ?? 'Non spécifiée'}"),
// //                 trailing: IconButton(
// //                   icon: const Icon(Icons.edit),
// //                   onPressed: () => _editField("TVA", userData!['TVA'] ?? ""),
// //                 ),
// //               ),
// //               ListTile(
// //                 leading: const Icon(Icons.location_on),
// //                 title: Text(
// //                     "Position : ${userData!['position'] ?? 'Non spécifiée'}"),
// //                 trailing: IconButton(
// //                   icon: const Icon(Icons.edit),
// //                   onPressed: () =>
// //                       _editField("Position", userData!['Position'] ?? ""),
// //                 ),
// //               ),
// //             ],
// //
// //             const Divider(),
// //             const SizedBox(height: 10),
// //
// //             ListTile(
// //               leading: const Icon(Icons.settings),
// //               title: const Text("Services"),
// //               onTap: () async {
// //                 if (widget.isCoiffeuse) {
// //                   // Assurez-vous d'utiliser le 'uuid' correct
// //                   final userDetails = await getIdAndTypeFromUuid(userData?['uuid']);
// //                   print("Détails utilisateur récupérés : $userDetails"); // Log pour vérifier les données
// //
// //                                 if (userDetails != null) {
// //                     final idTblUser = userDetails['idTblUser'];
// //
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
// //
// //                       ),
// //                     );
// //                   } else {
// //                     // Gérer les erreurs lorsque l'utilisateur n'est pas trouvé
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       const SnackBar(
// //                         content: Text("Erreur lors de la récupération des services."),
// //                       ),
// //                     );
// //                   }
// //                 } else {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     const SnackBar(
// //                       content: Text("Seules les coiffeuses ont accès aux services."),
// //
// //                     ),
// //                   );
// //                 }
// //               },
// //             ),
// //
// //
// //             ListTile(
// //               leading: const Icon(Icons.info),
// //               title: const Text("Paramètres"),
// //               onTap: () {},
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.logout),
// //               title: const Text("Déconnexion"),
// //               textColor: Colors.red,
// //               onTap: () async {
// //                 await LogoutService.confirmLogout(context);
// //               },
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Future<void> updateUserProfile(String userUuid,
// //       Map<String, dynamic> updatedData) async {
// //     final String apiUrl = 'http://192.168.0.248:8000/api/update_user_profile/$userUuid/';
// //     try {
// //       //-------------------------------------------------------------
// //       print("Envoi des données à l'API : $updatedData");
// //       //----------------------------------------------------------------
// //       final response = await http.patch(
// //         Uri.parse(apiUrl),
// //         headers: {'Content-Type': 'application/json'},
// //         body: jsonEncode(updatedData),
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final responseData = jsonDecode(response.body);
// //         if (responseData['success']) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(content: Text("Profil mis à jour avec succès"),
// //                 backgroundColor: Colors.green),
// //           );
// //         } else {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(content: Text("Erreur : ${responseData['message']}"),
// //                 backgroundColor: Colors.red),
// //           );
// //         }
// //       } else {
// //         throw Exception("Erreur serveur : ${response.statusCode}");
// //       }
// //       //--------------------------------------------------------------
// //       print("Réponse : ${response.body}");
// //       //--------------------------------------------------------------
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //             content: Text("Erreur réseau : $e"), backgroundColor: Colors.red),
// //       );
// //     }
// //   }
// // }
