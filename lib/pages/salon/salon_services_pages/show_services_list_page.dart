import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/page_size_selector.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/pagination_controls.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/search_field.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/create_promotion_modal.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/edit_service_modal.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/show_service_details_modal.dart';
import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
import 'package:hairbnb/services/providers/services_categories_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/service_with_promo.dart';
import '../../../services/firebase_token/token_service.dart';
import '../../../services/providers/current_user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/bottom_nav_bar.dart';
import 'services_pages_services/modals/add_service_modal.dart';
import 'services_pages_services/services/add_to_cart_service.dart';
import 'services_pages_services/services/delete_service.dart';

class ServicesListPage extends StatelessWidget {
  final String coiffeuseId;
  const ServicesListPage({super.key, required this.coiffeuseId});

  @override
  Widget build(BuildContext context) {
    // ✅ MultiProvider LOCAL - créé seulement pour cette page
    return MultiProvider(
      providers: [
        // ✅ CategoriesProvider existant
        ChangeNotifierProvider(
          create: (_) {
            final provider = CategoriesProvider();
            // ✅ Charge en arrière-plan sans bloquer l'affichage
            Future.microtask(() => provider.loadCategories());
            return provider;
          },
        ),
        // ✅ NOUVEAU : ServicesProvider pour la recherche - PRÉ-CHARGÉ
        ChangeNotifierProvider(
          create: (_) {
            final provider = ServicesProvider();
            // Pré-charger les services dès la création
            Future.microtask(() => provider.loadAllServices());
            return provider;
          },
        ),
      ],
      child: _ServicesListPageContent(coiffeuseId: coiffeuseId),
    );
  }
}

// ✅ CONTENU PRINCIPAL de la page
class _ServicesListPageContent extends StatefulWidget {
  final String coiffeuseId;
  const _ServicesListPageContent({required this.coiffeuseId});

  @override
  State<_ServicesListPageContent> createState() => _ServicesListPageContentState();
}

class _ServicesListPageContentState extends State<_ServicesListPageContent> with TickerProviderStateMixin {
  List<ServiceWithPromo> services = [];
  List<ServiceWithPromo> filteredServices = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool hasError = false;

  // ✅ CurrentUser via Provider
  CurrentUser? currentUser;
  String? currentUserId;

  int _currentIndex = 0;
  int currentPage = 1;
  int pageSize = 10;
  int totalServices = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool isLoadingMore = false;
  bool hasMore = true;

  // ✅ Gestion des catégories
  Map<String, List<ServiceWithPromo>> servicesByCategory = {};
  List<String> categoryNames = [];
  String selectedCategory = "Tous";
  late TabController _tabController;

  // ✅ Mode d'affichage
  bool isGridView = false;

  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color accentColor = const Color(0xFF6C5CE7);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _fetchServices();
    _searchController.addListener(_onSearchChanged);
    // ✅ Les providers se chargent automatiquement dans le MultiProvider
  }

  @override
  void dispose() {
    if (categoryNames.isNotEmpty) {
      _tabController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Initialisation via CurrentUserProvider
  void _initializeUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);

    if (currentUserProvider.currentUser != null) {
      setState(() {
        currentUser = currentUserProvider.currentUser;
        currentUserId = currentUser?.idTblUser.toString();
      });
    } else {
      currentUserProvider.fetchCurrentUser().then((_) {
        if (mounted) {
          setState(() {
            currentUser = currentUserProvider.currentUser;
            currentUserId = currentUser?.idTblUser.toString();
          });
        }
      });
    }
  }

  Future<void> _fetchServices({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        hasError = false;
        if (!loadMore) {
          services.clear();
          filteredServices.clear();
        }
      });
    }

    try {
      final token = await TokenService.getAuthToken();
      if (token == null) {
        _showError("Token d'authentification manquant");
        return;
      }

      final url = Uri.parse(
        'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData.containsKey('count')) {
          setState(() {
            totalServices = responseData['count'];
            nextPageUrl = responseData['next'];
            previousPageUrl = responseData['previous'];
          });
        }

        // 🔥 RÉCUPÉRER les infos du salon parent
        final salonData = responseData.containsKey('results')
            ? responseData['results']['salon']
            : responseData['salon'];

        final int salonId = salonData['idTblSalon'];
        final String? salonNom = salonData['nom'];

        final serviceList = salonData['services'];

        // 🔥 PARSER chaque service en passant le salonId du parent
        final List<ServiceWithPromo> fetched = [];

        for (int i = 0; i < (serviceList as List).length; i++) {
          try {
            final serviceJson = serviceList[i];

            // 🔥 PASSER le salonId du parent en paramètre
            final service = ServiceWithPromo.fromJson(
              serviceJson,
              parentSalonId: salonId,
              parentSalonNom: salonNom,
            );

            fetched.add(service);

          } catch (e) {
            continue;
          }
        }

        setState(() {
          if (loadMore) {
            services.addAll(fetched);
          } else {
            services = fetched;
          }

          _organizeServicesByCategory();
          _applyCurrentFilters();
          hasMore = nextPageUrl != null;
        });

      } else if (response.statusCode == 401) {
        _showError("Session expirée, veuillez vous reconnecter");
      } else {
        _showError("Erreur serveur: Code ${response.statusCode}");
      }
    } catch (e) {
      _showError("Erreur de connexion: $e");
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _organizeServicesByCategory() {
    servicesByCategory.clear();
    categoryNames.clear();

    for (var service in services) {
      String categoryName = service.categoryName ?? "Sans catégorie";

      if (!servicesByCategory.containsKey(categoryName)) {
        servicesByCategory[categoryName] = [];
        categoryNames.add(categoryName);
      }
      servicesByCategory[categoryName]!.add(service);
    }

    categoryNames.sort();
    categoryNames.insert(0, "Tous");

    if (categoryNames.length > 1) {
      _tabController = TabController(length: categoryNames.length, vsync: this);
      _tabController.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        selectedCategory = categoryNames[_tabController.index];
        _applyCurrentFilters();
      });
    }
  }

  void _onSearchChanged() {
    _applyCurrentFilters();
  }

  void _applyCurrentFilters() {
    setState(() {
      List<ServiceWithPromo> servicesToFilter;

      if (selectedCategory == "Tous") {
        servicesToFilter = services;
      } else {
        servicesToFilter = servicesByCategory[selectedCategory] ?? [];
      }

      String query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        filteredServices = servicesToFilter.where((service) {
          return service.intitule.toLowerCase().contains(query) ||
              service.description.toLowerCase().contains(query) ||
              (service.categoryName?.toLowerCase().contains(query) ?? false);
        }).toList();
      } else {
        filteredServices = servicesToFilter;
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _goToNextPage() {
    if (nextPageUrl != null) {
      setState(() {
        currentPage++;
        isLoading = true;
        services.clear();
        filteredServices.clear();
      });
      _fetchServices(loadMore: false);
    }
  }

  void _goToPreviousPage() {
    if (previousPageUrl != null && currentPage > 1) {
      setState(() {
        currentPage--;
        isLoading = true;
        services.clear();
        filteredServices.clear();
      });
      _fetchServices(loadMore: false);
    }
  }

  // 🔥 MODIFICATION à apporter dans la méthode _buildServiceCard

  Widget _buildServiceCard(ServiceWithPromo service, bool isOwner) {
    final hasPromo = service.promotion_active != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 3 : 4,
        horizontal: 2,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showServiceDetailsModal(
          context: context,
          serviceWithPromo: service,
          isOwner: isOwner,
          onEdit: () => showEditServiceModal(context, service, _fetchServices),
          onAddToCart: () => addToCart(
            context: context,
            serviceWithPromo: service,
            userId: currentUserId ?? "",
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      service.intitule,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 17,
                        fontWeight: FontWeight.bold,
                        color: primaryViolet,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (service.categoryName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withAlpha((255 * 0.1).round())),
                      ),
                      child: Text(
                        service.categoryName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              if (service.description.isNotEmpty && !isSmallScreen) ...[
                const SizedBox(height: 6),
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryViolet.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: primaryViolet),
                        const SizedBox(width: 3),
                        Text(
                          "${service.temps}min",
                          style: TextStyle(
                            color: primaryViolet,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: hasPromo
                          ? Row(
                        key: ValueKey("promo_${service.id}"),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${service.prix}€",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${service.prix_final}€🔥",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                            ),
                          ),
                        ],
                      )
                          : Container(
                        key: ValueKey("normal_${service.id}"),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${service.prix}€",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (isOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactIconButton(
                          Icons.local_offer,
                          Colors.purple,
                              () {

                            // Vérifier salonId avant d'ouvrir le modal
                            if (service.salonId <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ID du salon invalide (${service.salonId}) pour le service "${service.intitule}"'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                              return;
                            }

                            // Si tout est OK, ouvrir le modal
                            showCreatePromotionModal(
                              context: context,
                              serviceId: service.id,
                              salonId: service.salonId,
                              onPromoAdded: _fetchServices,
                            );
                          },
                        ),
                        _buildCompactIconButton(
                          Icons.edit,
                          Colors.blue,
                              () => showEditServiceModal(context, service, _fetchServices),
                        ),
                        _buildCompactIconButton(
                          Icons.delete,
                          Colors.red,
                              () => deleteService(
                            service.id,
                            context,
                            _showError,
                            setState,
                            services,
                            filteredServices,
                            totalServices,
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => addToCart(
                          context: context,
                          serviceWithPromo: service,
                          userId: currentUserId ?? "",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_shopping_cart, size: 16),
                            if (!isSmallScreen) ...[
                              const SizedBox(width: 4),
                              const Text("Ajouter", style: TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: color),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentUserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        final isOwner = user?.idTblUser.toString() == widget.coiffeuseId;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: const CustomAppBar(),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
          // ✅ FloatingActionButton avec les DEUX providers PRÉ-CHARGÉS
          floatingActionButton: isOwner
              ? Consumer2<CategoriesProvider, ServicesProvider>(
            builder: (context, categoriesProvider, servicesProvider, child) {

              return FloatingActionButton.extended(
                backgroundColor: primaryViolet,
                onPressed: () => showAddServiceModal(
                  context,
                  widget.coiffeuseId,
                  _fetchServices,
                  categoriesProvider,
                  servicesProvider,
                ),
                icon: const Icon(Icons.add),
                label: const Text("Nouveau service"),
              );
            },
          )
              : null,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: SearchField(controller: _searchController)),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => setState(() => isGridView = !isGridView),
                          icon: Icon(
                            isGridView ? Icons.list : Icons.grid_view,
                            color: primaryViolet,
                          ),
                        ),
                        PageSizeSelector(
                          currentSize: pageSize,
                          onChanged: (newSize) {
                            setState(() {
                              pageSize = newSize;
                              currentPage = 1;
                              services.clear();
                              filteredServices.clear();
                            });
                            _fetchServices();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (totalServices > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${filteredServices.length} service(s) affiché(s)",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Page $currentPage/${(totalServices / pageSize).ceil()}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              if (categoryNames.length > 1)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: primaryViolet,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryViolet,
                    indicatorWeight: 3,
                    tabs: categoryNames.map((category) {
                      int count = category == "Tous"
                          ? services.length
                          : (servicesByCategory[category]?.length ?? 0);
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryViolet.withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryViolet,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : hasError
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text("Une erreur s'est produite"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchServices,
                        child: const Text("Réessayer"),
                      ),
                    ],
                  ),
                )
                    : filteredServices.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucun service trouvé",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        Text(
                          "pour \"${_searchController.text}\"",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.all(12),
                  child: isGridView
                      ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 1.0,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      return _buildServiceCard(filteredServices[index], isOwner);
                    },
                  )
                      : ListView.builder(
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      return _buildServiceCard(filteredServices[index], isOwner);
                    },
                  ),
                ),
              ),

              if (totalServices > pageSize)
                Container(
                  color: Colors.white,
                  child: PaginationControls(
                    currentPage: currentPage,
                    totalItems: totalServices,
                    pageSize: pageSize,
                    previousPageUrl: previousPageUrl,
                    nextPageUrl: nextPageUrl,
                    onPrevious: _goToPreviousPage,
                    onNext: _goToNextPage,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}