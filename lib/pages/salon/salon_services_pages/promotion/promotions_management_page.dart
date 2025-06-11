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