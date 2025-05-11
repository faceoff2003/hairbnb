// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/profil/profil_widgets/show_salon_page.dart';
// import 'package:hairbnb/pages/horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/show_services_list_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/promotions_management_page.dart';
// import 'package:hairbnb/services/auth_services/logout_service.dart';
// import 'package:hairbnb/services/providers/get_user_type_service.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../public_salon_details/favorites_salons_page.dart';
// import '../../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
//
// class MyDrawer extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MyDrawer({Key? key, required this.currentUser}) : super(key: key);
//
//   @override
//   State<MyDrawer> createState() => _MyDrawerState();
// }
//
// class _MyDrawerState extends State<MyDrawer> {
//   Map<String, dynamic>? userData;
//   bool isLoading = true;
//
//   // Couleurs de l'application
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color lightBackground = const Color(0xFFF7F7F9);
//   final Color successGreen = Colors.green;
//   final Color errorRed = Colors.red;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUserProfile();
//   }
//
//   Future<void> fetchUserProfile() async {
//     final baseUrl = 'https://www.hairbnb.site/api/get_user_profile/${widget.currentUser.uuid}/';
//
//     try {
//       final response = await http.get(Uri.parse(baseUrl));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           userData = data['data'];
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";
//
//   @override
//   Widget build(BuildContext context) {
//     // Obtenir les dimensions de l'écran
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 360 || screenHeight < 600;
//
//     return Drawer(
//       width: isSmallScreen ? screenWidth * 0.85 : null, // Adapter la largeur pour les petits écrans
//       child: isLoading
//           ? Center(child: CircularProgressIndicator(color: primaryViolet))
//           : ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: primaryViolet),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     radius: isSmallScreen ? 30 : 40,
//                     backgroundImage: widget.currentUser.photoProfil != null &&
//                         widget.currentUser.photoProfil!.isNotEmpty
//                         ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
//                         : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                   ),
//                   SizedBox(height: isSmallScreen ? 6 : 10),
//                   Text(
//                     "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: isSmallScreen ? 16 : 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   Text(
//                     widget.currentUser.email ?? "Pas d'email",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: isSmallScreen ? 12 : 14,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           ListTile(
//             dense: isSmallScreen, // Plus compact sur petit écran
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 4.0,
//             ),
//             leading: Icon(Icons.home, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Accueil",
//               style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//             ),
//             onTap: () {
//               Navigator.pushNamed(context, "/home");
//             },
//           ),
//           ListTile(
//             dense: isSmallScreen, // Plus compact sur petit écran
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 4.0,
//             ),
//             leading: Icon(Icons.person, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Profil",
//               style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//             ),
//             onTap: () {
//               Navigator.pushNamed(context, "/profil");
//             },
//           ),
//
//           // Menu spécifique pour les coiffeuses
//           if (widget.currentUser.type == 'coiffeuse') ...[
//             const Divider(height: 1),
//             Padding(
//               padding: EdgeInsets.only(
//                 left: isSmallScreen ? 12.0 : 16.0,
//                 top: isSmallScreen ? 6.0 : 8.0,
//                 bottom: isSmallScreen ? 2.0 : 4.0,
//               ),
//               child: Text(
//                 "MENU COIFFEUSE",
//                 style: TextStyle(
//                   color: primaryViolet,
//                   fontSize: isSmallScreen ? 10 : 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.build, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Services",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final idTblUser = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Erreur lors de la récupération des services."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.local_offer, color: Colors.orange, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Promotions",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 14 : 16,
//                 ),
//               ),
//               tileColor: Colors.orange.withOpacity(0.05),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final idTblUser = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PromotionsManagementPage(coiffeuseId: idTblUser.toString()),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Erreur lors de la récupération des promotions."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.store, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mon salon",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final coiffeuseId = userDetails['idTblUser'];
//
//                   // Afficher un indicateur de chargement
//                   showDialog(
//                     context: context,
//                     barrierDismissible: false,
//                     builder: (context) => const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//
//                   try {
//                     // Appel au service pour récupérer le salon
//                     final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(coiffeuseId);
//                     final currentUserId = widget.currentUser.idTblUser;
//
//                     // Fermer l'indicateur de chargement
//                     Navigator.pop(context);
//
//                     if (salon != null) {
//                       // Naviguer vers la page de détails du salon
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => SalonDetailsPage(
//                             salonId: salon.idSalon,
//                             currentUserId: currentUserId,
//                           ),
//                         ),
//                       );
//                     } else {
//                       // Si aucun salon n'est trouvé
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: const Text("Vous n'avez pas encore de salon."),
//                           backgroundColor: Colors.orange,
//                         ),
//                       );
//                     }
//                   } catch (e) {
//                     // Fermer l'indicateur de chargement en cas d'erreur
//                     Navigator.pop(context);
//
//                     // Afficher un message d'erreur
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text("Erreur lors du chargement du salon: $e"),
//                         backgroundColor: errorRed,
//                       ),
//                     );
//                   }
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Impossible de charger les données du salon."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             // Nouveau bouton "Mes favoris"
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.favorite, color: Colors.pink, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mes favoris",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => FavoriteSalonsPage(
//                       currentUserId: widget.currentUser.idTblUser,
//                     ),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.calendar_today, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mes disponibilités",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final coiffeuseId = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => HoraireIndispoPage(coiffeuseId: coiffeuseId),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Impossible de charger vos horaires."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//           ],
//
//           const Divider(),
//           ListTile(
//             dense: isSmallScreen,
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 2.0,
//             ),
//             leading: Icon(Icons.logout, color: Colors.red, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Déconnexion",
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: isSmallScreen ? 14 : 16,
//               ),
//             ),
//             onTap: () async {
//               await LogoutService.confirmLogout(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }





// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/profil/profil_widgets/show_salon_page.dart';
// import 'package:hairbnb/pages/horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/show_services_list_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/promotions_management_page.dart';
// import 'package:hairbnb/services/auth_services/logout_service.dart';
// import 'package:hairbnb/services/providers/get_user_type_service.dart';
// import 'package:http/http.dart' as http;
//
// import '../../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
//
// class MyDrawer extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MyDrawer({Key? key, required this.currentUser}) : super(key: key);
//
//   @override
//   State<MyDrawer> createState() => _MyDrawerState();
// }
//
// class _MyDrawerState extends State<MyDrawer> {
//   Map<String, dynamic>? userData;
//   bool isLoading = true;
//
//   // Couleurs de l'application
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color lightBackground = const Color(0xFFF7F7F9);
//   final Color successGreen = Colors.green;
//   final Color errorRed = Colors.red;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUserProfile();
//   }
//
//   Future<void> fetchUserProfile() async {
//     final baseUrl = 'https://www.hairbnb.site/api/get_user_profile/${widget.currentUser.uuid}/';
//
//     try {
//       final response = await http.get(Uri.parse(baseUrl));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           userData = data['data'];
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";
//
//   @override
//   Widget build(BuildContext context) {
//     // Obtenir les dimensions de l'écran
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 360 || screenHeight < 600;
//
//     return Drawer(
//       width: isSmallScreen ? screenWidth * 0.85 : null, // Adapter la largeur pour les petits écrans
//       child: isLoading
//           ? Center(child: CircularProgressIndicator(color: primaryViolet))
//           : ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: primaryViolet),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     radius: isSmallScreen ? 30 : 40,
//                     backgroundImage: widget.currentUser.photoProfil != null &&
//                         widget.currentUser.photoProfil!.isNotEmpty
//                         ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
//                         : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                   ),
//                   SizedBox(height: isSmallScreen ? 6 : 10),
//                   Text(
//                     "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: isSmallScreen ? 16 : 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   Text(
//                     widget.currentUser.email ?? "Pas d'email",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: isSmallScreen ? 12 : 14,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//
//
//
//           // DrawerHeader(
//           //   decoration: BoxDecoration(
//           //     color: primaryViolet,
//           //   ),
//           //   padding: EdgeInsets.symmetric(
//           //       vertical: isSmallScreen ? 12.0 : 16.0,
//           //       horizontal: 16.0
//           //   ),
//           //   child: Column(
//           //     crossAxisAlignment: CrossAxisAlignment.start,
//           //     children: [
//           //       CircleAvatar(
//           //         radius: isSmallScreen ? 30 : 40,
//           //         backgroundImage: widget.currentUser.photoProfil != null &&
//           //             widget.currentUser.photoProfil!.isNotEmpty
//           //             ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
//           //             : const AssetImage('assets/default_avatar.png') as ImageProvider,
//           //         onBackgroundImageError: (exception, stackTrace) {
//           //           print("Erreur de chargement de l'image : $exception");
//           //         },
//           //       ),
//           //       SizedBox(height: isSmallScreen ? 6 : 10),
//           //       Text(
//           //         "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
//           //         style: TextStyle(
//           //           color: Colors.white,
//           //           fontSize: isSmallScreen ? 16 : 18,
//           //           fontWeight: FontWeight.bold,
//           //         ),
//           //         overflow: TextOverflow.ellipsis,
//           //       ),
//           //       Text(
//           //         widget.currentUser.email ?? "Pas d'email",
//           //         style: TextStyle(
//           //           color: Colors.white70,
//           //           fontSize: isSmallScreen ? 12 : 14,
//           //         ),
//           //         overflow: TextOverflow.ellipsis,
//           //       ),
//           //     ],
//           //   ),
//           // ),
//           ListTile(
//             dense: isSmallScreen, // Plus compact sur petit écran
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 4.0,
//             ),
//             leading: Icon(Icons.home, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Accueil",
//               style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//             ),
//             onTap: () {
//               Navigator.pushNamed(context, "/home");
//             },
//           ),
//           ListTile(
//             dense: isSmallScreen, // Plus compact sur petit écran
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 4.0,
//             ),
//             leading: Icon(Icons.person, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Profil",
//               style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//             ),
//             onTap: () {
//               Navigator.pushNamed(context, "/profil");
//             },
//           ),
//
//           // Menu spécifique pour les coiffeuses
//           if (widget.currentUser.type == 'coiffeuse') ...[
//             const Divider(height: 1),
//             Padding(
//               padding: EdgeInsets.only(
//                 left: isSmallScreen ? 12.0 : 16.0,
//                 top: isSmallScreen ? 6.0 : 8.0,
//                 bottom: isSmallScreen ? 2.0 : 4.0,
//               ),
//               child: Text(
//                 "MENU COIFFEUSE",
//                 style: TextStyle(
//                   color: primaryViolet,
//                   fontSize: isSmallScreen ? 10 : 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.build, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Services",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final idTblUser = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Erreur lors de la récupération des services."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.local_offer, color: Colors.orange, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Promotions",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 14 : 16,
//                 ),
//               ),
//               tileColor: Colors.orange.withOpacity(0.05),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final idTblUser = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PromotionsManagementPage(coiffeuseId: idTblUser.toString()),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Erreur lors de la récupération des promotions."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.store, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mon salon",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final coiffeuseId = userDetails['idTblUser'];
//
//                   // Afficher un indicateur de chargement
//                   showDialog(
//                     context: context,
//                     barrierDismissible: false,
//                     builder: (context) => const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//
//                   try {
//                     // Appel au service pour récupérer le salon
//                     final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(coiffeuseId);
//                     final currentUserId = widget.currentUser.idTblUser;
//
//                     // Fermer l'indicateur de chargement
//                     Navigator.pop(context);
//
//                     if (salon != null) {
//                       // Naviguer vers la page de détails du salon
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => SalonDetailsPage(
//                             salonId: salon.idSalon,
//                             currentUserId: currentUserId,
//                           ),
//                         ),
//                       );
//                     } else {
//                       // Si aucun salon n'est trouvé
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: const Text("Vous n'avez pas encore de salon."),
//                           backgroundColor: Colors.orange,
//                         ),
//                       );
//                     }
//                   } catch (e) {
//                     // Fermer l'indicateur de chargement en cas d'erreur
//                     Navigator.pop(context);
//
//                     // Afficher un message d'erreur
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text("Erreur lors du chargement du salon: $e"),
//                         backgroundColor: errorRed,
//                       ),
//                     );
//                   }
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Impossible de charger les données du salon."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.calendar_today, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mes disponibilités",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final coiffeuseId = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => HoraireIndispoPage(coiffeuseId: coiffeuseId),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Impossible de charger vos horaires."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//           ],
//
//           const Divider(),
//           ListTile(
//             dense: isSmallScreen,
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 2.0,
//             ),
//             leading: Icon(Icons.logout, color: Colors.red, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Déconnexion",
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: isSmallScreen ? 14 : 16,
//               ),
//             ),
//             onTap: () async {
//               await LogoutService.confirmLogout(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
//
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:hairbnb/pages/profil/profil_widgets/show_salon_page.dart';
// // import 'package:hairbnb/pages/horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
// // import 'package:hairbnb/pages/salon/salon_services_pages/show_services_list_page.dart';
// // import 'package:hairbnb/pages/salon/salon_services_pages/promotion/promotions_management_page.dart';
// // import 'package:hairbnb/services/auth_services/logout_service.dart';
// // import 'package:hairbnb/services/providers/get_user_type_service.dart';
// // import 'package:http/http.dart' as http;
// //
// // import '../../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
// //
// // class MyDrawer extends StatefulWidget {
// //   final CurrentUser currentUser;
// //
// //   const MyDrawer({Key? key, required this.currentUser}) : super(key: key);
// //
// //   @override
// //   State<MyDrawer> createState() => _MyDrawerState();
// // }
// //
// // class _MyDrawerState extends State<MyDrawer> {
// //   Map<String, dynamic>? userData;
// //   bool isLoading = true;
// //
// //   // Couleurs de l'application
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //   final Color lightBackground = const Color(0xFFF7F7F9);
// //   final Color successGreen = Colors.green;
// //   final Color errorRed = Colors.red;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchUserProfile();
// //   }
// //
// //   Future<void> fetchUserProfile() async {
// //     final baseUrl = 'https://www.hairbnb.site/api/get_user_profile/${widget.currentUser.uuid}/';
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
// //           isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Drawer(
// //       child: isLoading
// //           ? Center(child: CircularProgressIndicator(color: primaryViolet))
// //           : ListView(
// //         padding: EdgeInsets.zero,
// //         children: [
// //           DrawerHeader(
// //             decoration: BoxDecoration(
// //               color: primaryViolet,
// //             ),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 CircleAvatar(
// //                   radius: 40,
// //                   backgroundImage: widget.currentUser.photoProfil != null &&
// //                       widget.currentUser.photoProfil!.isNotEmpty
// //                       ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
// //                       : const AssetImage('assets/default_avatar.png') as ImageProvider,
// //                   onBackgroundImageError: (exception, stackTrace) {
// //                     print("Erreur de chargement de l'image : $exception");
// //                   },
// //                 ),
// //                 const SizedBox(height: 10),
// //                 Text(
// //                   "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 Text(
// //                   widget.currentUser.email ?? "Pas d'email",
// //                   style: const TextStyle(
// //                     color: Colors.white70,
// //                     fontSize: 14,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.home, color: primaryViolet),
// //             title: const Text("Accueil"),
// //             onTap: () {
// //               Navigator.pushNamed(context, "/home");
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.person, color: primaryViolet),
// //             title: const Text("Profil"),
// //             onTap: () {
// //               Navigator.pushNamed(context, "/profil");
// //             },
// //           ),
// //
// //           // Menu spécifique pour les coiffeuses
// //           if (widget.currentUser.type == 'coiffeuse') ...[
// //             const Divider(),
// //             Padding(
// //               padding: const EdgeInsets.only(left: 16.0, top: 8.0),
// //               child: Text(
// //                 "MENU COIFFEUSE",
// //                 style: TextStyle(
// //                   color: primaryViolet,
// //                   fontSize: 12,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.build, color: primaryViolet),
// //               title: const Text("Services"),
// //               onTap: () async {
// //                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
// //                 if (userDetails != null) {
// //                   final idTblUser = userDetails['idTblUser'];
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
// //                     ),
// //                   );
// //                 } else {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(
// //                       content: const Text("Erreur lors de la récupération des services."),
// //                       backgroundColor: errorRed,
// //                     ),
// //                   );
// //                 }
// //               },
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.local_offer, color: Colors.orange),
// //               title: const Text(
// //                 "Promotions",
// //                 style: TextStyle(fontWeight: FontWeight.bold),
// //               ),
// //               tileColor: Colors.orange.withOpacity(0.05),
// //               onTap: () async {
// //                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
// //                 if (userDetails != null) {
// //                   final idTblUser = userDetails['idTblUser'];
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => PromotionsManagementPage(coiffeuseId: idTblUser.toString()),
// //                     ),
// //                   );
// //                 } else {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(
// //                       content: const Text("Erreur lors de la récupération des promotions."),
// //                       backgroundColor: errorRed,
// //                     ),
// //                   );
// //                 }
// //               },
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.store, color: primaryViolet),
// //               title: const Text("Mon salon"),
// //               onTap: () async {
// //                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
// //                 if (userDetails != null) {
// //                   final coiffeuseId = userDetails['idTblUser'];
// //
// //                   // Afficher un indicateur de chargement
// //                   showDialog(
// //                     context: context,
// //                     barrierDismissible: false,
// //                     builder: (context) => const Center(
// //                       child: CircularProgressIndicator(),
// //                     ),
// //                   );
// //
// //                   try {
// //                     // Appel au service pour récupérer le salon
// //                     final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(coiffeuseId);
// //                     final currentUserId = widget.currentUser.idTblUser;
// //
// //                     // Fermer l'indicateur de chargement
// //                     Navigator.pop(context);
// //
// //                     if (salon != null) {
// //                       // Naviguer vers la page de détails du salon
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (context) => SalonDetailsPage(
// //                             salonId: salon.idSalon,
// //                             currentUserId: currentUserId,
// //                           ),
// //                         ),
// //                       );
// //                     } else {
// //                       // Si aucun salon n'est trouvé
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         SnackBar(
// //                           content: const Text("Vous n'avez pas encore de salon."),
// //                           backgroundColor: Colors.orange,
// //                         ),
// //                       );
// //                     }
// //                   } catch (e) {
// //                     // Fermer l'indicateur de chargement en cas d'erreur
// //                     Navigator.pop(context);
// //
// //                     // Afficher un message d'erreur
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       SnackBar(
// //                         content: Text("Erreur lors du chargement du salon: $e"),
// //                         backgroundColor: errorRed,
// //                       ),
// //                     );
// //                   }
// //                 } else {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(
// //                       content: const Text("Impossible de charger les données du salon."),
// //                       backgroundColor: errorRed,
// //                     ),
// //                   );
// //                 }
// //               },
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.calendar_today, color: primaryViolet),
// //               title: const Text("Mes disponibilités"),
// //               onTap: () async {
// //                 final userDetails = await getIdAndTypeFromUuid(widget.currentUser.uuid);
// //                 if (userDetails != null) {
// //                   final coiffeuseId = userDetails['idTblUser'];
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => HoraireIndispoPage(coiffeuseId: coiffeuseId),
// //                     ),
// //                   );
// //                 } else {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(
// //                       content: const Text("Impossible de charger vos horaires."),
// //                       backgroundColor: errorRed,
// //                     ),
// //                   );
// //                 }
// //               },
// //             ),
// //           ],
// //
// //           const Divider(),
// //           ListTile(
// //             leading: Icon(Icons.logout, color: Colors.red),
// //             title: const Text(
// //               "Déconnexion",
// //               style: TextStyle(color: Colors.red),
// //             ),
// //             onTap: () async {
// //               await LogoutService.confirmLogout(context);
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/current_user.dart';
// //
// // class MyDrawer extends StatelessWidget {
// //   final CurrentUser currentUser;
// //
// //   const MyDrawer({Key? key, required this.currentUser}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Drawer(
// //       child: ListView(
// //         children: [
// //           UserAccountsDrawerHeader(
// //             accountName: Text("${currentUser.prenom} ${currentUser.nom}"),
// //             accountEmail: Text(currentUser.email ?? "Pas d'email"),
// //             currentAccountPicture: CircleAvatar(
// //               backgroundImage: currentUser.photoProfil != null
// //                   ? NetworkImage("https://www.hairbnb.site/${currentUser.photoProfil}")
// //                   : AssetImage("logo_login/avatar.png") as ImageProvider,
// //             ),
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.home),
// //             title: Text("Accueil"),
// //             onTap: () {
// //               Navigator.pushNamed(context, "/home");
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.person),
// //             title: Text("Profil"),
// //             onTap: () {
// //               Navigator.pushNamed(context, "/profil");
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.logout),
// //             title: Text("Déconnexion"),
// //             onTap: () {
// //               // Ajoute ici ta logique de logout
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
