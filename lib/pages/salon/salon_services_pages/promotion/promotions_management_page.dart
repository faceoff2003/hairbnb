import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hairbnb/models/service_with_promo.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/promotion/services/promotion_service.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/bottom_nav_bar.dart';
import 'Widgets/promotion_widgets.dart';

class PromotionsManagementPage extends StatefulWidget {
  final String coiffeuseId;

  const PromotionsManagementPage({super.key, required this.coiffeuseId});

  @override
  State<PromotionsManagementPage> createState() => _PromotionsManagementPageState();
}

class _PromotionsManagementPageState extends State<PromotionsManagementPage> {
  List<ServiceWithPromo> services = [];
  List<ServiceWithPromo> filteredServices = [];
  int totalCount = 0;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int _currentIndex = 3;
  TextEditingController searchController = TextEditingController();
  bool showOnlyWithPromo = false;

  @override
  void initState() {
    super.initState();
    fetchServices();
    searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchServices() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final result = await PromotionService.getServices(widget.coiffeuseId);

    setState(() {
      if (result['error'] != null) {
        hasError = true;
        errorMessage = result['error'];
      } else {
        services = result['services'] ?? [];
        totalCount = result['totalCount'] ?? 0;
        _filterServices();
      }

      isLoading = false;
    });
  }

  void _filterServices() {
    setState(() {
      if (searchController.text.isEmpty && !showOnlyWithPromo) {
        filteredServices = List.from(services);
      } else {
        filteredServices = services.where((service) {
          final matchesSearch = searchController.text.isEmpty ||
              service.intitule.toLowerCase().contains(searchController.text.toLowerCase()) ||
              service.description.toLowerCase().contains(searchController.text.toLowerCase());

          final matchesPromoFilter = !showOnlyWithPromo || service.promotion_active != null;

          return matchesSearch && matchesPromoFilter;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryViolet = const Color(0xFF7B61FF);
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      body: isLoading
          ? _buildLoading(primaryViolet)
          : hasError
          ? _buildError(primaryViolet)
          : services.isEmpty
          ? _buildEmptyState(primaryViolet)
          : RefreshIndicator(
        onRefresh: fetchServices,
        color: primaryViolet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(primaryViolet, isSmallScreen),
            _buildFilterSummary(),
            Expanded(
              child: filteredServices.isEmpty
                  ? _buildNoResults()
                  : AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: ServicePromotionCard(
                            service: service,
                            onRefresh: fetchServices,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text('Chargement des services...',
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildError(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          Text('Erreur: $errorMessage', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: fetchServices,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/empty_state.svg', height: 120),
          const SizedBox(height: 20),
          const Text('Aucun service trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          const Text('Ajoutez des services pour commencer à créer des promotions', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryViolet, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Gestion des promotions',
                    style: TextStyle(fontSize: isSmallScreen ? 20 : 24, fontWeight: FontWeight.bold, color: primaryViolet)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('Total: $totalCount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryViolet)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un service...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  searchController.clear();
                  _filterServices();
                })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Filtres:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Avec promotion'),
                selected: showOnlyWithPromo,
                onSelected: (bool selected) {
                  setState(() {
                    showOnlyWithPromo = selected;
                    _filterServices();
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: primaryViolet.withOpacity(0.2),
                checkmarkColor: primaryViolet,
                labelStyle: TextStyle(
                  color: showOnlyWithPromo ? primaryViolet : Colors.black87,
                  fontWeight: showOnlyWithPromo ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${filteredServices.length} service${filteredServices.length > 1 ? 's' : ''} trouvé${filteredServices.length > 1 ? 's' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (searchController.text.isNotEmpty || showOnlyWithPromo)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  searchController.clear();
                  showOnlyWithPromo = false;
                  _filterServices();
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Effacer les filtres'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Aucun résultat trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Essayez avec d\'autres termes de recherche', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}






// // 📁 lib/pages/salon/salon_services_pages/promotion/promotions_management_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/api/promotion_api.dart';
// import '../../../../models/services.dart';
// import '../../../../widgets/custom_app_bar.dart';
// import '../../../../widgets/bottom_nav_bar.dart';
// import 'Widgets/promotion_widgets.dart';
//
// class PromotionsManagementPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const PromotionsManagementPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<PromotionsManagementPage> createState() => _PromotionsManagementPageState();
// }
//
// class _PromotionsManagementPageState extends State<PromotionsManagementPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   int totalCount = 0;
//   bool isLoading = true;
//   bool hasError = false;
//   String errorMessage = '';
//   int _currentIndex = 3; // Index pour le menu "Profils"
//   TextEditingController searchController = TextEditingController();
//   bool showOnlyWithPromo = false;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchServices();
//     searchController.addListener(_filterServices);
//   }
//
//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     final result = await PromotionApi.getServices(widget.coiffeuseId);
//
//     setState(() {
//       if (result['error'] != null) {
//         hasError = true;
//         errorMessage = result['error'];
//       } else {
//         services = result['services'] ?? [];
//         totalCount = result['totalCount'] ?? 0;
//         _filterServices(); // Applique le filtre actuel
//       }
//
//       isLoading = false;
//     });
//   }
//
//   void _filterServices() {
//     setState(() {
//       if (searchController.text.isEmpty && !showOnlyWithPromo) {
//         filteredServices = List.from(services);
//       } else {
//         filteredServices = services.where((service) {
//           // Filtre de recherche par texte
//           final matchesSearch = searchController.text.isEmpty ||
//               service.intitule.toLowerCase().contains(searchController.text.toLowerCase()) ||
//               service.description.toLowerCase().contains(searchController.text.toLowerCase());
//
//           // Filtre par présence de promotion
//           final matchesPromoFilter = !showOnlyWithPromo || service.promotion != null;
//
//           return matchesSearch && matchesPromoFilter;
//         }).toList();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Color primaryViolet = const Color(0xFF7B61FF);
//     final Size screenSize = MediaQuery.of(context).size;
//     final bool isSmallScreen = screenSize.width < 600;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//       ),
//       body: isLoading
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(
//               width: 60,
//               height: 60,
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(primaryViolet),
//                 strokeWidth: 3,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Chargement des services...',
//               style: TextStyle(
//                 color: primaryViolet,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       )
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.error_outline, color: Colors.red, size: 60),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Text(
//                 'Erreur: $errorMessage',
//                 style: const TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: fetchServices,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryViolet,
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//               ),
//             ),
//           ],
//         ),
//       )
//           : services.isEmpty
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SvgPicture.asset(
//               'assets/empty_state.svg', // Ajoutez cette ressource ou remplacez par une icône
//               height: 120,
//               width: 120,
//               // Si vous n'avez pas de SVG, utilisez plutôt:
//               // Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey)
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Aucun service trouvé',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Ajoutez des services pour commencer à créer des promotions',
//               style: TextStyle(color: Colors.grey),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: () {
//                 // Navigation vers la page d'ajout de service
//               },
//               icon: const Icon(Icons.add),
//               label: const Text('Ajouter un service'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryViolet,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//               ),
//             ),
//           ],
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: fetchServices,
//         color: primaryViolet,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // En-tête avec titre et recherche
//             Container(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//               color: Colors.white,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'Gestion des promotions',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 20 : 24,
//                             fontWeight: FontWeight.bold,
//                             color: primaryViolet,
//                           ),
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: primaryViolet.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           'Total: $totalCount',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: primaryViolet,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Barre de recherche
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     child: TextField(
//                       controller: searchController,
//                       decoration: InputDecoration(
//                         hintText: 'Rechercher un service...',
//                         prefixIcon: const Icon(Icons.search),
//                         suffixIcon: searchController.text.isNotEmpty
//                             ? IconButton(
//                           icon: const Icon(Icons.clear),
//                           onPressed: () {
//                             searchController.clear();
//                             _filterServices();
//                           },
//                         )
//                             : null,
//                         border: InputBorder.none,
//                         contentPadding: const EdgeInsets.symmetric(vertical: 12),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Filtre pour les promotions
//                   Row(
//                     children: [
//                       const Text(
//                         'Filtres:',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       FilterChip(
//                         label: const Text('Avec promotion'),
//                         selected: showOnlyWithPromo,
//                         onSelected: (bool selected) {
//                           setState(() {
//                             showOnlyWithPromo = selected;
//                             _filterServices();
//                           });
//                         },
//                         backgroundColor: Colors.white,
//                         selectedColor: primaryViolet.withOpacity(0.2),
//                         checkmarkColor: primaryViolet,
//                         labelStyle: TextStyle(
//                           color: showOnlyWithPromo ? primaryViolet : Colors.black87,
//                           fontWeight: showOnlyWithPromo ? FontWeight.bold : FontWeight.normal,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             // Résumé des résultats de recherche
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               color: Colors.grey.withOpacity(0.1),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     '${filteredServices.length} service${filteredServices.length > 1 ? 's' : ''} trouvé${filteredServices.length > 1 ? 's' : ''}',
//                     style: const TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   if (searchController.text.isNotEmpty || showOnlyWithPromo)
//                     TextButton.icon(
//                       onPressed: () {
//                         setState(() {
//                           searchController.clear();
//                           showOnlyWithPromo = false;
//                           _filterServices();
//                         });
//                       },
//                       icon: const Icon(Icons.clear, size: 16),
//                       label: const Text('Effacer les filtres'),
//                       style: TextButton.styleFrom(
//                         padding: EdgeInsets.zero,
//                         minimumSize: Size.zero,
//                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             // Liste des services avec animations
//             Expanded(
//               child: filteredServices.isEmpty
//                   ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Aucun résultat trouvé',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Essayez avec d\'autres termes de recherche',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               )
//                   : AnimationLimiter(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: filteredServices.length,
//                   itemBuilder: (context, index) {
//                     final service = filteredServices[index];
//                     return AnimationConfiguration.staggeredList(
//                       position: index,
//                       duration: const Duration(milliseconds: 375),
//                       child: SlideAnimation(
//                         verticalOffset: 50.0,
//                         child: FadeInAnimation(
//                           child: ServicePromotionCard(
//                             service: service,
//                             onRefresh: fetchServices,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Méthode pour obtenir uniquement les services avec des promotions actives
//   List<Service> _getServicesWithActivePromotion() {
//     return services.where((service) => service.promotion != null).toList();
//   }
// }


// // 📁 lib/pages/salon/salon_services_pages/promotion/promotions_management_page.dart
//
// // 📁 lib/pages/salon/salon_services_pages/promotion/promotions_management_page.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:hairbnb/models/service_with_promo.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/services/promotion_service.dart';
// import '../../../../widgets/custom_app_bar.dart';
// import '../../../../widgets/bottom_nav_bar.dart';
// import 'Widgets/promotion_widgets.dart';
//
// class PromotionsManagementPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const PromotionsManagementPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<PromotionsManagementPage> createState() => _PromotionsManagementPageState();
// }
//
// class _PromotionsManagementPageState extends State<PromotionsManagementPage> {
//   List<ServiceWithPromo> services = [];
//   List<ServiceWithPromo> filteredServices = [];
//   int totalCount = 0;
//   bool isLoading = true;
//   bool hasError = false;
//   String errorMessage = '';
//   int _currentIndex = 3;
//   TextEditingController searchController = TextEditingController();
//   bool showOnlyWithPromo = false;
//   bool showOnlyWithoutPromo = false;  // Nouveau filtre pour services sans promotion
//
//   @override
//   void initState() {
//     super.initState();
//     fetchServices();
//     searchController.addListener(_filterServices);
//   }
//
//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     final result = await PromotionService.getServices(widget.coiffeuseId);
//
//     setState(() {
//       if (result['error'] != null) {
//         hasError = true;
//         errorMessage = result['error'];
//       } else {
//         services = result['services'] ?? [];
//         totalCount = result['totalCount'] ?? 0;
//         _filterServices();
//       }
//
//       isLoading = false;
//     });
//   }
//
//   void _filterServices() {
//     setState(() {
//       filteredServices = services.where((service) {
//         // Vérifier le terme de recherche
//         final matchesSearch = searchController.text.isEmpty ||
//             service.intitule.toLowerCase().contains(searchController.text.toLowerCase()) ||
//             service.description.toLowerCase().contains(searchController.text.toLowerCase());
//
//         // Vérifier les filtres de promotion
//         bool matchesPromoFilter = true;
//
//         if (showOnlyWithPromo) {
//           // Services avec promotion active
//           matchesPromoFilter = service.promotion_active != null;
//         } else if (showOnlyWithoutPromo) {
//           // Services sans promotion active
//           matchesPromoFilter = service.promotion_active == null;
//         }
//
//         return matchesSearch && matchesPromoFilter;
//       }).toList();
//     });
//   }
//
//   // Fonction pour basculer le filtre "Sans promotion"
//   void _toggleWithoutPromoFilter() {
//     setState(() {
//       // Si on active "Sans promotion", on désactive "Avec promotion"
//       if (!showOnlyWithoutPromo) {
//         showOnlyWithPromo = false;
//         showOnlyWithoutPromo = true;
//       } else {
//         showOnlyWithoutPromo = false;
//       }
//       _filterServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Color primaryViolet = const Color(0xFF7B61FF);
//     final Size screenSize = MediaQuery.of(context).size;
//     final bool isSmallScreen = screenSize.width < 600;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//       ),
//       body: isLoading
//           ? _buildLoading(primaryViolet)
//           : hasError
//           ? _buildError(primaryViolet)
//           : services.isEmpty
//           ? _buildEmptyState(primaryViolet)
//           : RefreshIndicator(
//         onRefresh: fetchServices,
//         color: primaryViolet,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeader(primaryViolet, isSmallScreen),
//             _buildFilterSummary(),
//             Expanded(
//               child: filteredServices.isEmpty
//                   ? _buildNoResults()
//                   : AnimationLimiter(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: filteredServices.length,
//                   itemBuilder: (context, index) {
//                     final service = filteredServices[index];
//                     return AnimationConfiguration.staggeredList(
//                       position: index,
//                       duration: const Duration(milliseconds: 375),
//                       child: SlideAnimation(
//                         verticalOffset: 50.0,
//                         child: FadeInAnimation(
//                           child: ServicePromotionCard(
//                             service: service,
//                             onRefresh: fetchServices,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoading(Color color) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(color),
//             strokeWidth: 3,
//           ),
//           const SizedBox(height: 20),
//           Text('Chargement des services...',
//               style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildError(Color color) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red, size: 60),
//           const SizedBox(height: 20),
//           Text('Erreur: $errorMessage', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
//           const SizedBox(height: 20),
//           ElevatedButton.icon(
//             onPressed: fetchServices,
//             icon: const Icon(Icons.refresh),
//             label: const Text('Réessayer'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: color,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(Color color) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SvgPicture.asset('assets/empty_state.svg', height: 120),
//           const SizedBox(height: 20),
//           const Text('Aucun service trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
//           const SizedBox(height: 10),
//           const Text('Ajoutez des services pour commencer à créer des promotions', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
//           const SizedBox(height: 20),
//           ElevatedButton.icon(
//             onPressed: () {},
//             icon: const Icon(Icons.add),
//             label: const Text('Ajouter un service'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: color,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader(Color primaryViolet, bool isSmallScreen) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text('Gestion des promotions',
//                     style: TextStyle(fontSize: isSmallScreen ? 20 : 24, fontWeight: FontWeight.bold, color: primaryViolet)),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(color: primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
//                 child: Text('Total: $totalCount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryViolet)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 hintText: 'Rechercher un service...',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: searchController.text.isNotEmpty
//                     ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
//                   searchController.clear();
//                   _filterServices();
//                 })
//                     : null,
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               const Text('Filtres:', style: TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(width: 12),
//               FilterChip(
//                 label: const Text('Avec promotion'),
//                 selected: showOnlyWithPromo,
//                 onSelected: (bool selected) {
//                   setState(() {
//                     showOnlyWithPromo = selected;
//                     if (selected) {
//                       // Si on active "Avec promotion", on désactive "Sans promotion"
//                       showOnlyWithoutPromo = false;
//                     }
//                     _filterServices();
//                   });
//                 },
//                 backgroundColor: Colors.white,
//                 selectedColor: primaryViolet.withOpacity(0.2),
//                 checkmarkColor: primaryViolet,
//                 labelStyle: TextStyle(
//                   color: showOnlyWithPromo ? primaryViolet : Colors.black87,
//                   fontWeight: showOnlyWithPromo ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               // Nouveau filtre pour services sans promotion
//               FilterChip(
//                 label: const Text('Sans promotion'),
//                 selected: showOnlyWithoutPromo,
//                 onSelected: (bool selected) {
//                   setState(() {
//                     showOnlyWithoutPromo = selected;
//                     if (selected) {
//                       // Si on active "Sans promotion", on désactive "Avec promotion"
//                       showOnlyWithPromo = false;
//                     }
//                     _filterServices();
//                   });
//                 },
//                 backgroundColor: Colors.white,
//                 selectedColor: Colors.red.withOpacity(0.2),
//                 checkmarkColor: Colors.red,
//                 labelStyle: TextStyle(
//                   color: showOnlyWithoutPromo ? Colors.red : Colors.black87,
//                   fontWeight: showOnlyWithoutPromo ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterSummary() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       color: Colors.grey.withOpacity(0.1),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '${filteredServices.length} service${filteredServices.length > 1 ? 's' : ''} trouvé${filteredServices.length > 1 ? 's' : ''}',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           if (searchController.text.isNotEmpty || showOnlyWithPromo || showOnlyWithoutPromo)
//             TextButton.icon(
//               onPressed: () {
//                 setState(() {
//                   searchController.clear();
//                   showOnlyWithPromo = false;
//                   showOnlyWithoutPromo = false;
//                   _filterServices();
//                 });
//               },
//               icon: const Icon(Icons.clear, size: 16),
//               label: const Text('Effacer les filtres'),
//               style: TextButton.styleFrom(
//                 padding: EdgeInsets.zero,
//                 minimumSize: Size.zero,
//                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNoResults() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
//           const SizedBox(height: 16),
//           const Text('Aucun résultat trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
//           const SizedBox(height: 8),
//           const Text('Essayez avec d\'autres termes de recherche', style: TextStyle(color: Colors.grey)),
//         ],
//       ),
//     );
//   }
// }






// // 📁 lib/pages/salon/salon_services_pages/promotion/promotions_management_page.dart
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/services/promotion_service.dart';
// import '../../../../models/services.dart';
// import '../../../../widgets/custom_app_bar.dart';
// import '../../../../widgets/bottom_nav_bar.dart';
// import 'Widgets/promotion_widgets.dart';
//
// class PromotionsManagementPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const PromotionsManagementPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<PromotionsManagementPage> createState() => _PromotionsManagementPageState();
// }
//
// class _PromotionsManagementPageState extends State<PromotionsManagementPage> {
//   List<Service> services = [];
//   int totalCount = 0;
//   bool isLoading = true;
//   bool hasError = false;
//   String errorMessage = '';
//   int _currentIndex = 3; // Index pour le menu "Profils"
//
//   @override
//   void initState() {
//     super.initState();
//     fetchServices();
//   }
//
//   Future<void> fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     final result = await PromotionService.getServices(widget.coiffeuseId);
//
//     setState(() {
//       if (result['error'] != null) {
//         hasError = true;
//         errorMessage = result['error'];
//       } else {
//         services = result['services'] ?? [];
//         totalCount = result['totalCount'] ?? 0;
//       }
//
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Color primaryViolet = const Color(0xFF7B61FF);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//       ),
//
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, color: Colors.red, size: 60),
//             const SizedBox(height: 20),
//             Text('Erreur: $errorMessage', style: const TextStyle(color: Colors.red)),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: fetchServices,
//               style: ElevatedButton.styleFrom(backgroundColor: primaryViolet),
//               child: const Text('Réessayer'),
//             ),
//           ],
//         ),
//       )
//           : services.isEmpty
//           ? const Center(child: Text('Aucun service trouvé.'))
//           : RefreshIndicator(
//         onRefresh: fetchServices,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // En-tête fixe - ne fait pas partie de la zone défilante
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Gestion des promotions',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: primaryViolet,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Total: $totalCount services',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Séparateur
//             const Divider(height: 16),
//
//             // Section avec les promotions actives - uniquement si disponibles
//             if (_getServicesWithActivePromotion().isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//                 child: Text(
//                   'Promotions actives',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//               ),
//
//             // Contenu principal défilant
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   // Liste des services avec promotions actives
//                   if (_getServicesWithActivePromotion().isNotEmpty) ...[
//                     ..._getServicesWithActivePromotion().map(
//                           (service) => ServicePromotionCard(
//                         service: service,
//                         onRefresh: fetchServices,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     const Divider(),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Tous les services',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryViolet,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//
//                   // Liste de tous les services
//                   ...services.map(
//                         (service) => ServicePromotionCard(
//                       service: service,
//                       onRefresh: fetchServices,
//                     ),
//                   ),
//
//                   // Espace au bas de la liste pour éviter que le dernier élément
//                   // soit caché par la barre de navigation
//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Méthode pour obtenir uniquement les services avec des promotions actives
//   List<Service> _getServicesWithActivePromotion() {
//     return services.where((service) => service.promotion != null).toList();
//   }
// }








// // 📁 lib/ui/pages/promotions_management_page.dart
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/services/promotion_service.dart';
// import '../../../../models/services.dart';
// import '../../../../widgets/custom_app_bar.dart';
// import '../../../../widgets/bottom_nav_bar.dart';
// import 'Widgets/promotion_widgets.dart';
//
// class PromotionsManagementPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const PromotionsManagementPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<PromotionsManagementPage> createState() => _PromotionsManagementPageState();
// }
//
// class _PromotionsManagementPageState extends State<PromotionsManagementPage> {
//   List<Service> services = [];
//   int totalCount = 0;
//   bool isLoading = true;
//   bool hasError = false;
//   String errorMessage = '';
//   int _currentIndex = 3; // Index pour le menu "Profils"
//
//   @override
//   void initState() {
//     super.initState();
//     fetchServices();
//   }
//
//   Future<void> fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     final result = await PromotionService.getServices(widget.coiffeuseId);
//
//     setState(() {
//       if (result['error'] != null) {
//         hasError = true;
//         errorMessage = result['error'];
//       } else {
//         services = result['services'] ?? [];
//         totalCount = result['totalCount'] ?? 0;
//       }
//
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//       ),
//
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Erreur: $errorMessage', style: const TextStyle(color: Colors.red)),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: fetchServices,
//               child: const Text('Réessayer'),
//             ),
//           ],
//         ),
//       )
//           : services.isEmpty
//           ? const Center(child: Text('Aucun service trouvé.'))
//           : RefreshIndicator(
//         onRefresh: fetchServices,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Gestion des promotions',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF7B61FF),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Total: $totalCount services',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Section des promotions actives
//               if (_getServicesWithActivePromotion().isNotEmpty) ...[
//                 const Text(
//                   'Promotions actives',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 ..._getServicesWithActivePromotion().map(
//                       (service) => ServicePromotionCard(
//                     service: service,
//                     onRefresh: fetchServices,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//               ],
//
//               // Tous les services
//               const Text(
//                 'Tous les services',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: services.length,
//                   itemBuilder: (context, index) {
//                     final service = services[index];
//                     return ServicePromotionCard(
//                       service: service,
//                       onRefresh: fetchServices,
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Méthode pour obtenir uniquement les services avec des promotions actives
//   List<Service> _getServicesWithActivePromotion() {
//     return services.where((service) => service.promotion != null).toList();
//   }
// }