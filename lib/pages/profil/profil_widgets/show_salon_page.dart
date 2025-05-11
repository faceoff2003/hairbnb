import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/favorites.dart';
import '../../../models/public_salon_details.dart';
import '../../../public_salon_details/api/PublicSalonDetailsApi.dart';
import '../../../public_salon_details/modals/showHorairesModal.dart';
import '../../../public_salon_details/services/favorites_services.dart';
import '../../../public_salon_details/widgets/gallery_widget.dart';
import '../../../public_salon_details/widgets/service_price_widget.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/bottom_nav_bar.dart';

class SalonDetailsPage extends StatefulWidget {
  final int salonId;
  final int currentUserId;

  const SalonDetailsPage({super.key, required this.salonId, required this.currentUserId});

  @override
  _SalonDetailsPageState createState() => _SalonDetailsPageState();
}

class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
  late Future<PublicSalonDetails> _salonFuture;
  late TabController _tabController;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  FavoriteModel? _currentFavorite;

  @override
  void initState() {
    super.initState();
    _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
    _tabController = TabController(length: 4, vsync: this);
    _checkFavoriteStatus();
  }

  // Vérifier si le salon est déjà dans les favoris
  Future<void> _checkFavoriteStatus() async {
    if (widget.currentUserId <= 0) {
      // L'utilisateur n'est pas connecté
      setState(() {
        _isFavorite = false;
        _currentFavorite = null;
        _isLoadingFavorite = false;
      });
      return;
    }

    setState(() => _isLoadingFavorite = true);

    try {
      final favorite = await FavoritesService.getFavoriteForSalon(
          widget.currentUserId,
          widget.salonId
      );

      if (mounted) {
        setState(() {
          _currentFavorite = favorite;
          _isFavorite = favorite != null;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la vérification des favoris: $e')),
        );
      }
    }
  }

  // Gérer l'ajout/suppression des favoris
  Future<void> _toggleFavorite() async {
    if (widget.currentUserId <= 0) {
      // L'utilisateur n'est pas connecté
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour ajouter des favoris')),
      );
      return;
    }

    setState(() => _isLoadingFavorite = true);

    try {
      // Utiliser toggleFavorite au lieu d'une logique personnalisée
      final newFavoriteStatus = await FavoritesService.toggleFavorite(
          widget.currentUserId,
          widget.salonId
      );

      if (mounted) {
        setState(() {
          _isFavorite = newFavoriteStatus;
          _isLoadingFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? 'Salon ajouté aux favoris'
                : 'Salon retiré des favoris'
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          // facultatif : à gérer si besoin
        },
      ),
      body: SafeArea(
        child: FutureBuilder<PublicSalonDetails>(
          future: _salonFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('Erreur: ${snapshot.error}', style: GoogleFonts.poppins(fontSize: 16)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Aucune information disponible'));
            }

            final salonDetails = snapshot.data!;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: Colors.deepPurple,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        salonDetails.logoSalon != null && salonDetails.logoSalon!.isNotEmpty
                            ? Image.network(salonDetails.logoSalon!, fit: BoxFit.cover)
                            : salonDetails.images.isNotEmpty
                            ? Image.network(salonDetails.images.first.image, fit: BoxFit.cover)
                            : Container(color: Colors.grey[300]),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: _isLoadingFavorite
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                        )
                            : IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              body: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      salonDetails.nomSalon,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          salonDetails.noteMoyenne.toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _infoIcon(Icons.location_on),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      salonDetails.adresse ?? 'Adresse non disponible',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _infoIcon(Icons.access_time),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => showHorairesModal(context, salonDetails.horaires ?? ''),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Voir les horaires',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepPurple),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: DefaultTabController(
                            length: 4,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                TabBar(
                                  controller: _tabController,
                                  indicatorColor: Colors.deepPurple,
                                  labelColor: Colors.deepPurple,
                                  unselectedLabelColor: Colors.grey,
                                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  tabs: const [
                                    Tab(text: 'Services'),
                                    Tab(text: 'Équipements'),
                                    Tab(text: 'Spécialiste'),
                                    Tab(text: 'Galerie'),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildServicesTab(salonDetails),
                                      _buildEquipmentsTab(),
                                      _buildSpecialisteTab(salonDetails),
                                      GalleryWidget(
                                          salonDetails: salonDetails,
                                          currentUserId: widget.currentUserId
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.deepPurple, size: 20),
    );
  }


  Widget _buildServicesTab(PublicSalonDetails salon) {
    final services = salon.serviceSalonDetailsList;

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.healing_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun service disponible',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.intituleService,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    if (service.promotionActive != null)
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${service.promotionActive!.discountPercentage}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  service.description,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 10),
                ServicePriceWidget(serviceSalonDetails: service),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildEquipmentsTab() {
    final equipments = [
      {'icon': Icons.wifi, 'label': 'WIFI'},
      {'icon': Icons.local_parking, 'label': 'Parking'},
      {'icon': Icons.tv, 'label': 'TV'},
      {'icon': Icons.music_note, 'label': 'Musique'},
      {'icon': Icons.coffee, 'label': 'Café'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: equipments.length,
      itemBuilder: (context, index) {
        final equipment = equipments[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              child: Icon(equipment['icon'] as IconData, color: Colors.deepPurple),
            ),
            title: Text(equipment['label'] as String,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
        );
      },
    );
  }

  Widget _buildSpecialisteTab(PublicSalonDetails salon) {
    final user = salon.coiffeuse.idTblUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photoProfil != null ? NetworkImage(user.photoProfil!) : null,
            backgroundColor: Colors.grey[200],
            child: user.photoProfil == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
          ),
          const SizedBox(height: 16),
          Text('${user.prenom} ${user.nom}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(salon.coiffeuse.position ?? 'Coiffeuse professionnelle',
              style: GoogleFonts.poppins(color: Colors.grey[600])),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.deepPurple),
                  title: Text('Téléphone', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text(user.numeroTelephone ?? 'Non disponible'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.deepPurple),
                  title: Text('Dénomination', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text(salon.coiffeuse.denominationSociale ?? 'Non disponible'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../../models/favorites.dart';
// import '../../../models/public_salon_details.dart';
// import '../../../public_salon_details/api/PublicSalonDetailsApi.dart';
// import '../../../public_salon_details/modals/favorite_modal.dart';
// import '../../../public_salon_details/modals/showHorairesModal.dart';
// import '../../../public_salon_details/widgets/gallery_widget.dart';
// import '../../../public_salon_details/widgets/service_price_widget.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
//
// class SalonDetailsPage extends StatefulWidget {
//   final int salonId;
//   final int currentUserId;
//
//   const SalonDetailsPage({super.key, required this.salonId, required this.currentUserId});
//
//   @override
//   _SalonDetailsPageState createState() => _SalonDetailsPageState();
// }
//
// class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
//   late Future<PublicSalonDetails> _salonFuture;
//   late TabController _tabController;
//   bool _isFavorite = false;
//   bool _isLoadingFavorite = true;
//   FavoriteModel? _currentFavorite;
//
//   @override
//   void initState() {
//     super.initState();
//     _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//     _tabController = TabController(length: 4, vsync: this);
//     _checkFavoriteStatus();
//   }
//
//   // Vérifier si le salon est déjà dans les favoris
//   Future<void> _checkFavoriteStatus() async {
//     if (widget.currentUserId <= 0) {
//       // L'utilisateur n'est pas connecté
//       setState(() {
//         _isFavorite = false;
//         _isLoadingFavorite = false;
//       });
//       return;
//     }
//
//     setState(() => _isLoadingFavorite = true);
//
//     try {
//       final favorite = await FavoritesService.getFavoriteForSalon(
//           widget.currentUserId,
//           widget.salonId
//       );
//
//       if (mounted) {
//         setState(() {
//           _currentFavorite = favorite;
//           _isFavorite = favorite != null;
//           _isLoadingFavorite = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoadingFavorite = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur lors de la vérification des favoris: $e')),
//         );
//       }
//     }
//   }
//
//   // Gérer l'ajout/suppression des favoris
//   Future<void> _toggleFavorite() async {
//     if (widget.currentUserId <= 0) {
//       // L'utilisateur n'est pas connecté
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Vous devez être connecté pour ajouter des favoris')),
//       );
//       return;
//     }
//
//     setState(() => _isLoadingFavorite = true);
//
//     try {
//       if (_isFavorite && _currentFavorite != null) {
//         // Supprimer des favoris
//         final success = await FavoritesService.removeFavorite(_currentFavorite!.idTblFavorite);
//
//         if (mounted) {
//           if (success) {
//             setState(() {
//               _isFavorite = false;
//               _currentFavorite = null;
//               _isLoadingFavorite = false;
//             });
//
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Salon retiré des favoris'),
//                 duration: Duration(seconds: 1),
//               ),
//             );
//           } else {
//             setState(() => _isLoadingFavorite = false);
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Échec de la suppression du favori')),
//             );
//           }
//         }
//       } else {
//         // Ajouter aux favoris
//         final newFavorite = await FavoritesService.addToFavorites(
//             widget.currentUserId,
//             widget.salonId
//         );
//
//         if (mounted) {
//           if (newFavorite != null) {
//             setState(() {
//               _isFavorite = true;
//               _currentFavorite = newFavorite;
//               _isLoadingFavorite = false;
//             });
//
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Salon ajouté aux favoris'),
//                 duration: Duration(seconds: 1),
//               ),
//             );
//           } else {
//             setState(() => _isLoadingFavorite = false);
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Échec de l\'ajout aux favoris')),
//             );
//           }
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoadingFavorite = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9FB),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 1,
//         onTap: (index) {
//           // facultatif : à gérer si besoin
//         },
//       ),
//       body: SafeArea(
//         child: FutureBuilder<PublicSalonDetails>(
//           future: _salonFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(color: Colors.deepPurple),
//               );
//             } else if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 60),
//                     const SizedBox(height: 16),
//                     Text('Erreur: ${snapshot.error}', style: GoogleFonts.poppins(fontSize: 16)),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: const Text('Réessayer'),
//                     ),
//                   ],
//                 ),
//               );
//             } else if (!snapshot.hasData) {
//               return const Center(child: Text('Aucune information disponible'));
//             }
//
//             final salonDetails = snapshot.data!;
//
//             return NestedScrollView(
//               headerSliverBuilder: (context, innerBoxIsScrolled) => [
//                 SliverAppBar(
//                   expandedHeight: 220,
//                   pinned: true,
//                   backgroundColor: Colors.deepPurple,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         salonDetails.logoSalon != null && salonDetails.logoSalon!.isNotEmpty
//                             ? Image.network(salonDetails.logoSalon!, fit: BoxFit.cover)
//                             : salonDetails.images.isNotEmpty
//                             ? Image.network(salonDetails.images.first.image, fit: BoxFit.cover)
//                             : Container(color: Colors.grey[300]),
//                         Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   leading: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: CircleAvatar(
//                       backgroundColor: Colors.white,
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.black),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                   ),
//                   actions: [
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: _isLoadingFavorite
//                             ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
//                           ),
//                         )
//                             : IconButton(
//                           icon: Icon(
//                             _isFavorite ? Icons.favorite : Icons.favorite_border,
//                             color: _isFavorite ? Colors.red : Colors.grey,
//                           ),
//                           onPressed: _toggleFavorite,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               body: Column(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(20),
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: const BorderRadius.only(
//                               topLeft: Radius.circular(24),
//                               topRight: Radius.circular(24),
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, -4),
//                               )
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.nomSalon,
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.w700,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                   ),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.orange.shade600,
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.star, size: 16, color: Colors.white),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           salonDetails.noteMoyenne.toString(),
//                                           style: GoogleFonts.poppins(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.location_on),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.adresse ?? 'Adresse non disponible',
//                                       style: GoogleFonts.poppins(fontSize: 14),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.access_time),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: MouseRegion(
//                                       cursor: SystemMouseCursors.click,
//                                       child: GestureDetector(
//                                         onTap: () => showHorairesModal(context, salonDetails.horaires ?? ''),
//                                         child: Row(
//                                           children: [
//                                             Text(
//                                               'Voir les horaires',
//                                               style: GoogleFonts.poppins(
//                                                 fontSize: 14,
//                                                 color: Colors.deepPurple,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 6),
//                                             const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepPurple),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         Expanded(
//                           child: DefaultTabController(
//                             length: 4,
//                             child: Column(
//                               children: [
//                                 const SizedBox(height: 12),
//                                 TabBar(
//                                   controller: _tabController,
//                                   indicatorColor: Colors.deepPurple,
//                                   labelColor: Colors.deepPurple,
//                                   unselectedLabelColor: Colors.grey,
//                                   labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                                   tabs: const [
//                                     Tab(text: 'Services'),
//                                     Tab(text: 'Équipements'),
//                                     Tab(text: 'Spécialiste'),
//                                     Tab(text: 'Galerie'),
//                                   ],
//                                 ),
//                                 Expanded(
//                                   child: TabBarView(
//                                     controller: _tabController,
//                                     children: [
//                                       _buildServicesTab(salonDetails),
//                                       _buildEquipmentsTab(),
//                                       _buildSpecialisteTab(salonDetails),
//                                       GalleryWidget(
//                                           salonDetails: salonDetails,
//                                           currentUserId: widget.currentUserId
//                                       ),
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _infoIcon(IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: Colors.deepPurple.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(icon, color: Colors.deepPurple, size: 20),
//     );
//   }
//
//
//   Widget _buildServicesTab(PublicSalonDetails salon) {
//     final services = salon.serviceSalonDetailsList;
//
//     if (services.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.healing_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Aucun service disponible',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: services.length,
//       itemBuilder: (context, index) {
//         final service = services[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 2,
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         service.intituleService,
//                         style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600, fontSize: 16),
//                       ),
//                     ),
//                     if (service.promotionActive != null)
//                       Container(
//                         padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           '-${service.promotionActive!.discountPercentage}%',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red.shade800,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   service.description,
//                   style: GoogleFonts.poppins(
//                       fontSize: 14, color: Colors.grey[700]),
//                 ),
//                 const SizedBox(height: 10),
//                 ServicePriceWidget(serviceSalonDetails: service),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   Widget _buildEquipmentsTab() {
//     final equipments = [
//       {'icon': Icons.wifi, 'label': 'WIFI'},
//       {'icon': Icons.local_parking, 'label': 'Parking'},
//       {'icon': Icons.tv, 'label': 'TV'},
//       {'icon': Icons.music_note, 'label': 'Musique'},
//       {'icon': Icons.coffee, 'label': 'Café'},
//     ];
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: equipments.length,
//       itemBuilder: (context, index) {
//         final equipment = equipments[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 1,
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.deepPurple.withOpacity(0.1),
//               child: Icon(equipment['icon'] as IconData, color: Colors.deepPurple),
//             ),
//             title: Text(equipment['label'] as String,
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSpecialisteTab(PublicSalonDetails salon) {
//     final user = salon.coiffeuse.idTblUser;
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage: user.photoProfil != null ? NetworkImage(user.photoProfil!) : null,
//             backgroundColor: Colors.grey[200],
//             child: user.photoProfil == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
//           ),
//           const SizedBox(height: 16),
//           Text('${user.prenom} ${user.nom}',
//               style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
//           const SizedBox(height: 8),
//           Text(salon.coiffeuse.position ?? 'Coiffeuse professionnelle',
//               style: GoogleFonts.poppins(color: Colors.grey[600])),
//           const SizedBox(height: 20),
//           Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.phone, color: Colors.deepPurple),
//                   title: Text('Téléphone', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(user.numeroTelephone ?? 'Non disponible'),
//                 ),
//                 const Divider(),
//                 ListTile(
//                   leading: const Icon(Icons.business, color: Colors.deepPurple),
//                   title: Text('Dénomination', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(salon.coiffeuse.denominationSociale ?? 'Non disponible'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../../models/public_salon_details.dart';
// import '../../../public_salon_details/api/PublicSalonDetailsApi.dart';
// import '../../../public_salon_details/modals/favorite_modal.dart';
// import '../../../public_salon_details/modals/showHorairesModal.dart';
// import '../../../public_salon_details/widgets/gallery_widget.dart';
// import '../../../public_salon_details/widgets/service_price_widget.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
//
// class SalonDetailsPage extends StatefulWidget {
//   final int salonId;
//   final int currentUserId;
//
//   const SalonDetailsPage({super.key, required this.salonId, required this.currentUserId});
//
//   @override
//   _SalonDetailsPageState createState() => _SalonDetailsPageState();
// }
//
// class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
//   late Future<PublicSalonDetails> _salonFuture;
//   late TabController _tabController;
//   bool _isFavorite = false;
//   bool _isLoadingFavorite = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//     _tabController = TabController(length: 4, vsync: this);
//     _checkFavoriteStatus();
//   }
//
//   // Vérifier si le salon est déjà dans les favoris
//   Future<void> _checkFavoriteStatus() async {
//     setState(() => _isLoadingFavorite = true);
//
//     try {
//       final isFavorite = await FavoritesService.isSalonFavorite(
//           widget.currentUserId,
//           widget.salonId
//       );
//
//       if (mounted) {
//         setState(() {
//           _isFavorite = isFavorite;
//           _isLoadingFavorite = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoadingFavorite = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur lors de la vérification des favoris: $e')),
//         );
//       }
//     }
//   }
//
//   // Gérer l'ajout/suppression des favoris
//   Future<void> _toggleFavorite() async {
//     if (widget.currentUserId <= 0) {
//       // L'utilisateur n'est pas connecté
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Vous devez être connecté pour ajouter des favoris')),
//       );
//       return;
//     }
//
//     setState(() => _isLoadingFavorite = true);
//
//     try {
//       final newFavoriteStatus = await FavoritesService.toggleFavorite(
//           widget.currentUserId,
//           widget.salonId
//       );
//
//       if (mounted) {
//         setState(() {
//           _isFavorite = newFavoriteStatus;
//           _isLoadingFavorite = false;
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(_isFavorite
//                 ? 'Salon ajouté aux favoris'
//                 : 'Salon retiré des favoris'
//             ),
//             duration: const Duration(seconds: 1),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoadingFavorite = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9FB),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 1,
//         onTap: (index) {
//           // facultatif : à gérer si besoin
//         },
//       ),
//       body: SafeArea(
//         child: FutureBuilder<PublicSalonDetails>(
//           future: _salonFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(color: Colors.deepPurple),
//               );
//             } else if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 60),
//                     const SizedBox(height: 16),
//                     Text('Erreur: ${snapshot.error}', style: GoogleFonts.poppins(fontSize: 16)),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: const Text('Réessayer'),
//                     ),
//                   ],
//                 ),
//               );
//             } else if (!snapshot.hasData) {
//               return const Center(child: Text('Aucune information disponible'));
//             }
//
//             final salonDetails = snapshot.data!;
//
//             return NestedScrollView(
//               headerSliverBuilder: (context, innerBoxIsScrolled) => [
//                 SliverAppBar(
//                   expandedHeight: 220,
//                   pinned: true,
//                   backgroundColor: Colors.deepPurple,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         salonDetails.logoSalon != null && salonDetails.logoSalon!.isNotEmpty
//                             ? Image.network(salonDetails.logoSalon!, fit: BoxFit.cover)
//                             : salonDetails.images.isNotEmpty
//                             ? Image.network(salonDetails.images.first.image, fit: BoxFit.cover)
//                             : Container(color: Colors.grey[300]),
//                         Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   leading: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: CircleAvatar(
//                       backgroundColor: Colors.white,
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.black),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                   ),
//                   actions: [
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: _isLoadingFavorite
//                             ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
//                           ),
//                         )
//                             : IconButton(
//                           icon: Icon(
//                             _isFavorite ? Icons.favorite : Icons.favorite_border,
//                             color: _isFavorite ? Colors.red : Colors.grey,
//                           ),
//                           onPressed: _toggleFavorite,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               body: Column(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(20),
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: const BorderRadius.only(
//                               topLeft: Radius.circular(24),
//                               topRight: Radius.circular(24),
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, -4),
//                               )
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.nomSalon,
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.w700,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                   ),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.orange.shade600,
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.star, size: 16, color: Colors.white),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           salonDetails.noteMoyenne.toString(),
//                                           style: GoogleFonts.poppins(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.location_on),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.adresse ?? 'Adresse non disponible',
//                                       style: GoogleFonts.poppins(fontSize: 14),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.access_time),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: MouseRegion(
//                                       cursor: SystemMouseCursors.click,
//                                       child: GestureDetector(
//                                         onTap: () => showHorairesModal(context, salonDetails.horaires ?? ''),
//                                         child: Row(
//                                           children: [
//                                             Text(
//                                               'Voir les horaires',
//                                               style: GoogleFonts.poppins(
//                                                 fontSize: 14,
//                                                 color: Colors.deepPurple,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 6),
//                                             const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepPurple),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         Expanded(
//                           child: DefaultTabController(
//                             length: 4,
//                             child: Column(
//                               children: [
//                                 const SizedBox(height: 12),
//                                 TabBar(
//                                   controller: _tabController,
//                                   indicatorColor: Colors.deepPurple,
//                                   labelColor: Colors.deepPurple,
//                                   unselectedLabelColor: Colors.grey,
//                                   labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                                   tabs: const [
//                                     Tab(text: 'Services'),
//                                     Tab(text: 'Équipements'),
//                                     Tab(text: 'Spécialiste'),
//                                     Tab(text: 'Galerie'),
//                                   ],
//                                 ),
//                                 Expanded(
//                                   child: TabBarView(
//                                     controller: _tabController,
//                                     children: [
//                                       _buildServicesTab(salonDetails),
//                                       _buildEquipmentsTab(),
//                                       _buildSpecialisteTab(salonDetails),
//                                       GalleryWidget(
//                                           salonDetails: salonDetails,
//                                           currentUserId: widget.currentUserId
//                                       ),
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _infoIcon(IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: Colors.deepPurple.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(icon, color: Colors.deepPurple, size: 20),
//     );
//   }
//
//
//   Widget _buildServicesTab(PublicSalonDetails salon) {
//     final services = salon.serviceSalonDetailsList;
//
//     if (services.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.healing_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Aucun service disponible',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: services.length,
//       itemBuilder: (context, index) {
//         final service = services[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 2,
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         service.intituleService,
//                         style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600, fontSize: 16),
//                       ),
//                     ),
//                     if (service.promotionActive != null)
//                       Container(
//                         padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           '-${service.promotionActive!.discountPercentage}%',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red.shade800,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   service.description,
//                   style: GoogleFonts.poppins(
//                       fontSize: 14, color: Colors.grey[700]),
//                 ),
//                 const SizedBox(height: 10),
//                 ServicePriceWidget(serviceSalonDetails: service),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   Widget _buildEquipmentsTab() {
//     final equipments = [
//       {'icon': Icons.wifi, 'label': 'WIFI'},
//       {'icon': Icons.local_parking, 'label': 'Parking'},
//       {'icon': Icons.tv, 'label': 'TV'},
//       {'icon': Icons.music_note, 'label': 'Musique'},
//       {'icon': Icons.coffee, 'label': 'Café'},
//     ];
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: equipments.length,
//       itemBuilder: (context, index) {
//         final equipment = equipments[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 1,
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.deepPurple.withOpacity(0.1),
//               child: Icon(equipment['icon'] as IconData, color: Colors.deepPurple),
//             ),
//             title: Text(equipment['label'] as String,
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSpecialisteTab(PublicSalonDetails salon) {
//     final user = salon.coiffeuse.idTblUser;
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage: user.photoProfil != null ? NetworkImage(user.photoProfil!) : null,
//             backgroundColor: Colors.grey[200],
//             child: user.photoProfil == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
//           ),
//           const SizedBox(height: 16),
//           Text('${user.prenom} ${user.nom}',
//               style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
//           const SizedBox(height: 8),
//           Text(salon.coiffeuse.position ?? 'Coiffeuse professionnelle',
//               style: GoogleFonts.poppins(color: Colors.grey[600])),
//           const SizedBox(height: 20),
//           Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.phone, color: Colors.deepPurple),
//                   title: Text('Téléphone', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(user.numeroTelephone ?? 'Non disponible'),
//                 ),
//                 const Divider(),
//                 ListTile(
//                   leading: const Icon(Icons.business, color: Colors.deepPurple),
//                   title: Text('Dénomination', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(salon.coiffeuse.denominationSociale ?? 'Non disponible'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../../models/public_salon_details.dart';
// import '../../../public_salon_details/api/PublicSalonDetailsApi.dart';
// import '../../../public_salon_details/modals/showHorairesModal.dart';
// import '../../../public_salon_details/widgets/gallery_widget.dart';
// import '../../../public_salon_details/widgets/service_price_widget.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
//
// class SalonDetailsPage extends StatefulWidget {
//   final int salonId;
//   final int currentUserId;
//
//
//   const SalonDetailsPage({super.key, required this.salonId, required this.currentUserId});
//
//
//   @override
//   _SalonDetailsPageState createState() => _SalonDetailsPageState();
// }
//
// class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
//   late Future<PublicSalonDetails> _salonFuture;
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//     _tabController = TabController(length: 4, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9FB),
//     appBar: const CustomAppBar(),
//     bottomNavigationBar: BottomNavBar(
//     currentIndex: 1,
//     onTap: (index) {
//     // facultatif : à gérer si besoin
//     },
//     ),
//       body: SafeArea(
//         child: FutureBuilder<PublicSalonDetails>(
//           future: _salonFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(color: Colors.deepPurple),
//               );
//             } else if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 60),
//                     const SizedBox(height: 16),
//                     Text('Erreur: ${snapshot.error}', style: GoogleFonts.poppins(fontSize: 16)),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: const Text('Réessayer'),
//                     ),
//                   ],
//                 ),
//               );
//             } else if (!snapshot.hasData) {
//               return const Center(child: Text('Aucune information disponible'));
//             }
//
//             final salonDetails = snapshot.data!;
//             //----------------------------------------------------------------------
//             print('CurrentUserID: ${widget.currentUserId} - CoiffeuseID: ${salonDetails.coiffeuse.idTblUser.idTblUser} '
//                 '- EGAUX: ${widget.currentUserId == salonDetails.coiffeuse.idTblUser.idTblUser}');
//             //-----------------------------------------------------------------------
//             return NestedScrollView(
//               headerSliverBuilder: (context, innerBoxIsScrolled) => [
//                 SliverAppBar(
//                   expandedHeight: 220,
//                   pinned: true,
//                   backgroundColor: Colors.deepPurple,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         salonDetails.logoSalon != null && salonDetails.logoSalon!.isNotEmpty
//                             ? Image.network(salonDetails.logoSalon!, fit: BoxFit.cover)
//                             : salonDetails.images.isNotEmpty
//                             ? Image.network(salonDetails.images.first.image, fit: BoxFit.cover)
//                             : Container(color: Colors.grey[300]),
//                         Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   leading: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: CircleAvatar(
//                       backgroundColor: Colors.white,
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.black),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                   ),
//                   actions: [
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: IconButton(
//                           icon: const Icon(Icons.favorite, color: Colors.red),
//                           onPressed: () {},
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               body: Column(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(20),
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: const BorderRadius.only(
//                               topLeft: Radius.circular(24),
//                               topRight: Radius.circular(24),
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, -4),
//                               )
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.nomSalon,
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.w700,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                   ),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.orange.shade600,
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.star, size: 16, color: Colors.white),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           salonDetails.noteMoyenne.toString(),
//                                           style: GoogleFonts.poppins(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.location_on),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.adresse ?? 'Adresse non disponible',
//                                       style: GoogleFonts.poppins(fontSize: 14),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.access_time),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: MouseRegion(
//                                       cursor: SystemMouseCursors.click,
//                                       child: GestureDetector(
//                                         onTap: () => showHorairesModal(context, salonDetails.horaires ?? ''),
//                                         child: Row(
//                                           children: [
//                                             Text(
//                                               'Voir les horaires',
//                                               style: GoogleFonts.poppins(
//                                                 fontSize: 14,
//                                                 color: Colors.deepPurple,
//                                                 fontWeight: FontWeight.w500,
//                                                 //decoration: TextDecoration.underline, // optionnel
//                                               ),
//                                             ),
//                                             const SizedBox(width: 6),
//                                             const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepPurple),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         Expanded(
//
//                           child: DefaultTabController(
//                             length: 4,
//                             child: Column(
//                               children: [
//                                 const SizedBox(height: 12),
//                                 TabBar(
//                                   controller: _tabController,
//                                   indicatorColor: Colors.deepPurple,
//                                   labelColor: Colors.deepPurple,
//                                   unselectedLabelColor: Colors.grey,
//                                   labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                                   tabs: const [
//                                     Tab(text: 'Services'),
//                                     Tab(text: 'Équipements'),
//                                     Tab(text: 'Spécialiste'),
//                                     Tab(text: 'Galerie'),
//                                   ],
//                                 ),
//
//                                 Expanded(
//                                   child: TabBarView(
//                                     controller: _tabController,
//                                     children: [
//                                       _buildServicesTab(salonDetails),
//                                       _buildEquipmentsTab(),
//                                       _buildSpecialisteTab(salonDetails),
//                                       GalleryWidget(salonDetails: salonDetails,
//                                           currentUserId: widget.currentUserId),
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _infoIcon(IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: Colors.deepPurple.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(icon, color: Colors.deepPurple, size: 20),
//     );
//   }
//
//
//   Widget _buildServicesTab(PublicSalonDetails salon) {
//     final services = salon.serviceSalonDetailsList;
//
//     if (services.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.healing_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Aucun service disponible',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: services.length,
//       itemBuilder: (context, index) {
//         final service = services[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 2,
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         service.intituleService,
//                         style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600, fontSize: 16),
//                       ),
//                     ),
//                     if (service.promotionActive != null)
//                       Container(
//                         padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           '-${service.promotionActive!.discountPercentage}%',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red.shade800,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   service.description,
//                   style: GoogleFonts.poppins(
//                       fontSize: 14, color: Colors.grey[700]),
//                 ),
//                 const SizedBox(height: 10),
//                 ServicePriceWidget(serviceSalonDetails: service),
//
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   Widget _buildEquipmentsTab() {
//     final equipments = [
//       {'icon': Icons.wifi, 'label': 'WIFI'},
//       {'icon': Icons.local_parking, 'label': 'Parking'},
//       {'icon': Icons.tv, 'label': 'TV'},
//       {'icon': Icons.music_note, 'label': 'Musique'},
//       {'icon': Icons.coffee, 'label': 'Café'},
//     ];
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: equipments.length,
//       itemBuilder: (context, index) {
//         final equipment = equipments[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 1,
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.deepPurple.withOpacity(0.1),
//               child: Icon(equipment['icon'] as IconData, color: Colors.deepPurple),
//             ),
//             title: Text(equipment['label'] as String,
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSpecialisteTab(PublicSalonDetails salon) {
//     final user = salon.coiffeuse.idTblUser;
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage: user.photoProfil != null ? NetworkImage(user.photoProfil!) : null,
//             backgroundColor: Colors.grey[200],
//             child: user.photoProfil == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
//           ),
//           const SizedBox(height: 16),
//           Text('${user.prenom} ${user.nom}',
//               style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
//           const SizedBox(height: 8),
//           Text(salon.coiffeuse.position ?? 'Coiffeuse professionnelle',
//               style: GoogleFonts.poppins(color: Colors.grey[600])),
//           const SizedBox(height: 20),
//           Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.phone, color: Colors.deepPurple),
//                   title: Text('Téléphone', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(user.numeroTelephone ?? 'Non disponible'),
//                 ),
//                 const Divider(),
//                 ListTile(
//                   leading: const Icon(Icons.business, color: Colors.deepPurple),
//                   title: Text('Dénomination', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(salon.coiffeuse.denominationSociale ?? 'Non disponible'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../../../models/public_salon_details.dart';
// import '../../../public_salon_details/api/PublicSalonDetailsApi.dart';
//
// class SalonDetailsPage extends StatefulWidget {
//   final int salonId;
//
//   const SalonDetailsPage({Key? key, required this.salonId, required int currentUserId}) : super(key: key);
//
//   @override
//   _SalonDetailsPageState createState() => _SalonDetailsPageState();
// }
//
// class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
//   late Future<PublicSalonDetails> _salonFuture;
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//     _tabController = TabController(length: 4, vsync: this);
//   }
//
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
//             return const Center(
//               child: CircularProgressIndicator(
//                 color: Colors.purple,
//                 strokeWidth: 3,
//               ),
//             );
//           } else if (snapshot.hasError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, color: Colors.red, size: 60),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Erreur: ${snapshot.error}',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//                       });
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple,
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     child: const Text('Réessayer'),
//                   ),
//                 ],
//               ),
//             );
//           } else if (!snapshot.hasData) {
//             return const Center(child: Text('Aucune information disponible'));
//           }
//
//           final salon = snapshot.data!;
//           return CustomScrollView(
//             slivers: [
//               // Header avec image du salon
//               SliverAppBar(
//                 expandedHeight: 220,
//                 pinned: true,
//                 backgroundColor: Colors.purple,
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: salon.logoSalon != null && salon.logoSalon!.isNotEmpty
//                       ? Image.network(salon.logoSalon!, fit: BoxFit.cover)
//                       : salon.images.isNotEmpty
//                       ? Image.network(salon.images.first.image, fit: BoxFit.cover)
//                       : Container(
//                     color: Colors.grey[300],
//                     child: const Center(
//                       child: Icon(Icons.store, size: 60, color: Colors.white54),
//                     ),
//                   ),
//
//                 ),
//                 leading: Container(
//                   margin: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         spreadRadius: 1,
//                         blurRadius: 3,
//                         offset: const Offset(0, 1),
//                       ),
//                     ],
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.black),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ),
//                 actions: [
//                   Container(
//                     margin: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           spreadRadius: 1,
//                           blurRadius: 3,
//                           offset: const Offset(0, 1),
//                         ),
//                       ],
//                     ),
//                     child: IconButton(
//                       icon: const Icon(Icons.favorite, color: Colors.red),
//                       onPressed: () {},
//                     ),
//                   ),
//                 ],
//               ),
//
//               // Informations du salon
//               SliverToBoxAdapter(
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Nom du salon avec notation
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               salon.nomSalon,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: Colors.amber,
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.star, color: Colors.white, size: 18),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   salon.noteMoyenne.toString(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//
//                       // Adresse
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.purple.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(Icons.location_on, color: Colors.purple, size: 20),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               salon.adresse ?? 'Adresse non disponible',
//                               style: TextStyle(
//                                 color: Colors.grey[800],
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//
//                       // Horaires
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.purple.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(Icons.access_time, color: Colors.purple, size: 20),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: _formatHoraires(salon.horaires ?? ''),
//                             ),
//                           ),
//
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//
//                       // Actions rapides
//                       Card(
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: BorderSide(color: Colors.grey.shade200),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               _buildActionButton(Icons.share, 'Partager'),
//                               _buildActionButton(Icons.map, 'Direction'),
//                               _buildActionButton(Icons.message, 'Message'),
//                               _buildActionButton(Icons.phone, 'Téléphone'),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // À propos
//               if (salon.aPropos != null && salon.aPropos!.isNotEmpty)
//                 SliverToBoxAdapter(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
//                           salon.aPropos!,
//                           maxLines: 3,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: Colors.grey[700],
//                             height: 1.5,
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             // Afficher le texte complet
//                             showModalBottomSheet(
//                               context: context,
//                               shape: const RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                               ),
//                               builder: (context) => Padding(
//                                 padding: const EdgeInsets.all(20),
//                                 child: SingleChildScrollView(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'À propos',
//                                         style: TextStyle(
//                                           fontSize: 20,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 16),
//                                       Text(
//                                         salon.aPropos!,
//                                         style: TextStyle(
//                                           color: Colors.grey[800],
//                                           height: 1.6,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 30),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                           style: TextButton.styleFrom(
//                             foregroundColor: Colors.purple,
//                             padding: EdgeInsets.zero,
//                           ),
//                           child: const Text('Voir plus'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//               // Navigation par onglets
//               SliverPersistentHeader(
//                 delegate: _SliverAppBarDelegate(
//                   TabBar(
//                     controller: _tabController,
//                     labelColor: Colors.purple,
//                     unselectedLabelColor: Colors.grey,
//                     indicatorColor: Colors.purple,
//                     indicatorWeight: 3,
//                     labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//                     unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
//                     tabs: const [
//                       Tab(text: 'Services'),
//                       Tab(text: 'Équipements'),
//                       Tab(text: 'Spécialiste'),
//                       Tab(text: 'Galerie'),
//                     ],
//                   ),
//                 ),
//                 pinned: true,
//               ),
//
//               // Contenu des onglets
//               SliverFillRemaining(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     // Onglet Services
//                     _buildServicesTab(salon),
//
//                     // Onglet Équipements
//                     _buildEquipmentsTab(),
//
//                     // Onglet Spécialiste
//                     _buildSpecialisteTab(salon),
//
//                     // Onglet Galerie
//                     _buildGalerieTab(salon),
//                   ],
//                 ),
//               ),
//             ],
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
//         Container(
//           width: 48,
//           height: 48,
//           decoration: BoxDecoration(
//             color: Colors.purple.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: Colors.purple),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[800],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildServicesTab(PublicSalonDetails salon) {
//     return salon.services.isEmpty
//         ? Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.healing_outlined, size: 60, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'Aucun service disponible',
//             style: TextStyle(color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     )
//         : ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: salon.services.length,
//       itemBuilder: (context, index) {
//         final service = salon.services[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 2,
//           shadowColor: Colors.black.withOpacity(0.1),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         service.intituleService,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.purple,
//                         borderRadius: BorderRadius.circular(50),
//                       ),
//                       child: IconButton(
//                         constraints: const BoxConstraints(
//                           minWidth: 36,
//                           minHeight: 36,
//                         ),
//                         padding: EdgeInsets.zero,
//                         icon: const Icon(Icons.add, color: Colors.white, size: 20),
//                         onPressed: () {},
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         '${service.prix?.toStringAsFixed(1)}\$',
//                         style: const TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         '${service.duree}hrs',
//                         style: const TextStyle(
//                           color: Colors.blue,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   service.description,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.grey[700],
//                     fontSize: 14,
//                   ),
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
//         return Card(
//           margin: const EdgeInsets.only(bottom: 10),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 1,
//           child: ListTile(
//             leading: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.purple.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(equipment['icon'] as IconData, color: Colors.purple),
//             ),
//             title: Text(
//               equipment['name'] as String,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSpecialisteTab(PublicSalonDetails salon) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 60,
//             backgroundColor: Colors.grey[200],
//             backgroundImage: salon.coiffeuse.idTblUser.photoProfil != null
//                 ? NetworkImage(salon.coiffeuse.idTblUser.photoProfil!)
//                 : null,
//             child: salon.coiffeuse.idTblUser.photoProfil == null
//                 ? const Icon(Icons.person, size: 60, color: Colors.grey)
//                 : null,
//           ),
//           const SizedBox(height: 20),
//           Text(
//             '${salon.coiffeuse.idTblUser.prenom} ${salon.coiffeuse.idTblUser.nom}',
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             salon.coiffeuse.position ?? 'Coiffeuse professionnelle',
//             style: TextStyle(
//               color: Colors.grey[700],
//               fontSize: 16,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 20),
//           Card(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(Icons.phone, color: Colors.blue),
//                     ),
//                     title: const Text('Téléphone'),
//                     subtitle: Text(
//                       salon.coiffeuse.idTblUser.numeroTelephone ?? 'Non disponible',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const Divider(),
//                   ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(Icons.business, color: Colors.green),
//                     ),
//                     title: const Text('Dénomination sociale'),
//                     subtitle: Text(
//                       salon.coiffeuse.denominationSociale ?? 'Non disponible',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGalerieTab(PublicSalonDetails salon) {
//     return salon.images.isEmpty
//         ? Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'Aucune image disponible',
//             style: TextStyle(color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     )
//         : GridView.builder(
//       padding: const EdgeInsets.all(12),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 1.0,
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 10,
//       ),
//       itemCount: salon.images.length,
//       itemBuilder: (context, index) {
//         return GestureDetector(
//           onTap: () {
//             // Afficher l'image en plein écran
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => Scaffold(
//                   backgroundColor: Colors.black,
//                   appBar: AppBar(
//                     backgroundColor: Colors.black,
//                     elevation: 0,
//                     iconTheme: const IconThemeData(color: Colors.white),
//                   ),
//                   body: Center(
//                     child: InteractiveViewer(
//                       panEnabled: true,
//                       boundaryMargin: const EdgeInsets.all(20),
//                       minScale: 0.5,
//                       maxScale: 4,
//                       child: Image.network(
//                         salon.images[index].image,
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//           child: Hero(
//             tag: 'image_$index',
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.network(
//                   salon.images[index].image,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
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
//   }
//
// List<Widget> _formatHoraires(String horaires) {
//   final jours = {
//     'Mon': 'Lundi',
//     'Tue': 'Mardi',
//     'Wed': 'Mercredi',
//     'Thu': 'Jeudi',
//     'Fri': 'Vendredi',
//     'Sat': 'Samedi',
//     'Sun': 'Dimanche',
//   };
//
//   final parts = horaires.split(',').map((e) => e.trim()).toList();
//   final widgets = <Widget>[];
//
//   for (var part in parts) {
//     final split = part.split('/').map((e) => e.trim()).toList();
//     if (split.length == 2) {
//       final horaire = split[0];
//       final jourCode = split[1];
//       final jour = jours[jourCode] ?? jourCode;
//
//       widgets.add(
//         Container(
//           margin: const EdgeInsets.only(bottom: 6),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: Colors.purple.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.calendar_today_outlined, color: Colors.purple[400], size: 16),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   "$jour : $horaire",
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.black87,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//   }
//
//   return widgets;
// }