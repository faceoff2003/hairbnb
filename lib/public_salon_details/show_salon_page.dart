import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/favorites.dart';
import '../models/public_salon_details.dart';
import 'api/PublicSalonDetailsApi.dart';
import 'modals/showHorairesModal.dart';
import 'services/favorites_services.dart';
import 'widgets/gallery_widget.dart';
import 'widgets/service_price_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';

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