// import 'package:flutter/material.dart';
// import '../models/public_salon_details.dart';
// import 'api/PublicSalonDetailsApi.dart';
//
// class SalonDetailsPage extends StatefulWidget {
//   final int salonId;
//
//   const SalonDetailsPage({super.key, required this.salonId});
//
//   @override
//   _SalonDetailsPageState createState() => _SalonDetailsPageState();
// }
//
// class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
//   // Le reste du code reste identique
//   late Future<PublicSalonDetails> _salonFuture;
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//     _tabController = TabController(length: 4, vsync: this);
//   }
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<PublicSalonDetails>(
//         future: _salonFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Erreur: ${snapshot.error}'));
//           } else if (!snapshot.hasData) {
//             return const Center(child: Text('Aucune information disponible'));
//           }
//
//           final salon = snapshot.data!;
//           return NestedScrollView(
//             headerSliverBuilder: (context, innerBoxIsScrolled) {
//               return [
//                 // En-tête avec image du salon
//                 SliverAppBar(
//                   expandedHeight: 200,
//                   floating: false,
//                   pinned: true,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: salon.images.isNotEmpty
//                         ? Image.network(
//                       salon.images.first.image,
//                       fit: BoxFit.cover,
//                     )
//                         : Container(color: Colors.grey),
//                   ),
//                   leading: IconButton(
//                     icon: const CircleAvatar(
//                       backgroundColor: Colors.white,
//                       child: Icon(Icons.arrow_back, color: Colors.black),
//                     ),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   actions: [
//                     IconButton(
//                       icon: const CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: Icon(Icons.favorite, color: Colors.red),
//                       ),
//                       onPressed: () {},
//                     ),
//                   ],
//                 ),
//
//                 // Informations du salon
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           salon.nomSalon,
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             const Icon(Icons.star, color: Colors.amber),
//                             const SizedBox(width: 4),
//                             Text(
//                               salon.noteMoyenne.toString(),
//                               style: const TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             const Icon(Icons.location_on, color: Colors.purple),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(salon.adresse ?? 'Adresse non disponible'),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             const Icon(Icons.access_time, color: Colors.purple),
//                             const SizedBox(width: 4),
//                             Text(salon.horaires ?? 'Horaires non disponibles'),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Boutons d'action
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             _buildActionButton(Icons.share, 'Partager'),
//                             _buildActionButton(Icons.map, 'Direction'),
//                             _buildActionButton(Icons.message, 'message'),
//                             _buildActionButton(Icons.phone, 'Téléphone'),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // À propos
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'À propos',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           salon.aPropos ?? 'Aucune description disponible',
//                           maxLines: 3,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             // Afficher le texte complet
//                           },
//                           child: const Text('Voir plus'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // Tabs
//                 SliverPersistentHeader(
//                   delegate: _SliverAppBarDelegate(
//                     TabBar(
//                       controller: _tabController,
//                       labelColor: Colors.purple,
//                       unselectedLabelColor: Colors.grey,
//                       tabs: const [
//                         Tab(text: 'Services'),
//                         Tab(text: 'Équipements'),
//                         Tab(text: 'Spécialiste'),
//                         Tab(text: 'Galerie'),
//                       ],
//                     ),
//                   ),
//                   pinned: true,
//                 ),
//               ];
//             },
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 // Tab Services
//                 _buildServicesTab(salon),
//                 // Tab Équipements
//                 _buildEquipmentsTab(),
//                 // Tab Spécialiste
//                 _buildSpecialisteTab(salon),
//                 // Tab Galerie
//                 _buildGalerieTab(salon),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildActionButton(IconData icon, String label) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         CircleAvatar(
//           radius: 25,
//           backgroundColor: Colors.grey[200],
//           child: Icon(icon, color: Colors.purple),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }
//
//   Widget _buildServicesTab(PublicSalonDetails salon) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: salon.services.length,
//       itemBuilder: (context, index) {
//         final service = salon.services[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       service.intituleService,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                         shape: const CircleBorder(),
//                         padding: const EdgeInsets.all(0),
//                         minimumSize: const Size(40, 40),
//                       ),
//                       child: const Icon(Icons.add),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text('\$${service.prix?.toStringAsFixed(1)} • ${service.duree}hrs'),
//                 const SizedBox(height: 4),
//                 Text(
//                   service.description,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildEquipmentsTab() {
//     // Données codées en dur pour les équipements
//     final equipments = [
//       {'icon': Icons.wifi, 'name': 'WIFI'},
//       {'icon': Icons.local_parking, 'name': 'Free Parking'},
//       {'icon': Icons.tv, 'name': 'TV'},
//       {'icon': Icons.music_note, 'name': 'Music Choice'},
//       {'icon': Icons.coffee, 'name': 'Coffee Bar'},
//     ];
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: equipments.length,
//       itemBuilder: (context, index) {
//         final equipment = equipments[index];
//         return ListTile(
//           leading: Icon(equipment['icon'] as IconData, color: Colors.purple),
//           title: Text(equipment['name'] as String),
//         );
//       },
//     );
//   }
//
//   Widget _buildSpecialisteTab(PublicSalonDetails salon) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage: salon.coiffeuse.idTblUser.photoProfil != null
//                 ? NetworkImage(salon.coiffeuse.idTblUser.photoProfil!)
//                 : null,
//             child: salon.coiffeuse.idTblUser.photoProfil == null
//                 ? const Icon(Icons.person, size: 50)
//                 : null,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             '${salon.coiffeuse.idTblUser.prenom} ${salon.coiffeuse.idTblUser.nom}',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(salon.coiffeuse.position ?? 'Coiffeuse professionnelle'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGalerieTab(PublicSalonDetails salon) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(8),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 1.0,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: salon.images.length,
//       itemBuilder: (context, index) {
//         return ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.network(
//             salon.images[index].image,
//             fit: BoxFit.cover,
//           ),
//         );
//       },
//     );
//   }
// }
//
// // Helper class pour l'en-tête persistant
// class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
//   final TabBar _tabBar;
//
//   _SliverAppBarDelegate(this._tabBar);
//
//   @override
//   double get minExtent => _tabBar.preferredSize.height;
//
//   @override
//   double get maxExtent => _tabBar.preferredSize.height;
//
//   @override
//   Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return Container(
//       color: Colors.white,
//       child: _tabBar,
//     );
//   }
//
//   @override
//   bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
//     return false;
//   }
// }