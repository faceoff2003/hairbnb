// 🚀 SOLUTION : Modifier show_salon_services_modal.dart pour utiliser l'API avec promotions

import 'package:flutter/material.dart';
import 'package:hairbnb/models/salon_details_geo.dart';
import 'package:hairbnb/models/service_with_promo.dart'; // ✅ Utiliser ServiceWithPromo
import 'package:hairbnb/pages/salon/salon_services_pages/promotion/services/promotion_service.dart'; // ✅ Utiliser PromotionService

class SalonServicesModal extends StatefulWidget {
  final SalonDetailsForGeo salon;
  final Color primaryColor;
  final Color accentColor;

  const SalonServicesModal({
    super.key,
    required this.salon,
    this.primaryColor = const Color(0xFF7B61FF),
    this.accentColor = const Color(0xFFE67E22),
  });

  @override
  State<SalonServicesModal> createState() => _SalonServicesModalState();
}

class _SalonServicesModalState extends State<SalonServicesModal> {
  // ✅ Utiliser ServiceWithPromo au lieu de SalonService
  List<ServiceWithPromo> allServices = [];
  List<ServiceWithPromo> selectedServices = [];
  Map<String, List<ServiceWithPromo>> servicesByCategory = {};

  // États de chargement
  bool isLoading = false;
  String? errorMessage;
  String? categorieSelectionnee;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }



  /// ✅ MODIFICATION : Utiliser PromotionService au lieu de ServicesApiService
  Future<void> _chargerDonnees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print("🚀 Chargement des services avec promotions pour le salon: ${widget.salon.nom}");

      // ✅ NOUVEAU : Utiliser l'API qui retourne les promotions
      final result = await PromotionService.getServices(
        widget.salon.proprietaire!.idTblUser.toString(), // ID du salon en string
      );

      if (result['error'] != null) {
        throw Exception(result['error']);
      }

      final List<ServiceWithPromo> services = result['services'] ?? [];

      // ✅ Grouper les services par catégorie
      final groupedServices = <String, List<ServiceWithPromo>>{};
      for (var service in services) {
        final categoryName = service.categoryName ?? 'Sans catégorie';
        if (!groupedServices.containsKey(categoryName)) {
          groupedServices[categoryName] = [];
        }
        groupedServices[categoryName]!.add(service);
      }

      setState(() {
        allServices = services;
        servicesByCategory = groupedServices;

        // Sélectionner la première catégorie si disponible
        if (groupedServices.isNotEmpty) {
          categorieSelectionnee = groupedServices.keys.first;
        }
      });

      print("✅ ${services.length} services chargés en ${groupedServices.length} catégories");
      print("🎯 Services avec promotions actives: ${services.where((s) => s.hasActivePromotion()).length}");

    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      print("❌ Erreur chargement: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Récupérer les services de la catégorie sélectionnée
  List<ServiceWithPromo> _getServicesCategorie() {
    if (categorieSelectionnee == null) return [];
    return servicesByCategory[categorieSelectionnee] ?? [];
  }

  /// Filtrer les services selon la recherche
  List<ServiceWithPromo> _getServicesFiltered() {
    final servicesCategorie = _getServicesCategorie();
    if (searchQuery.isEmpty) return servicesCategorie;

    return servicesCategorie.where((service) =>
    service.intitule.toLowerCase().contains(searchQuery.toLowerCase()) ||
        service.description.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  /// Calculer les statistiques d'une catégorie
  Map<String, dynamic> _getCategorieStats(String categoryName) {
    final services = servicesByCategory[categoryName] ?? [];
    if (services.isEmpty) {
      return {
        'count': 0,
        'prixMin': 0.0,
        'prixMax': 0.0,
      };
    }

    // ✅ Utiliser prix_final (avec promotions appliquées)
    final prices = services.map((s) => s.prix_final).toList()..sort();
    return {
      'count': services.length,
      'prixMin': prices.first,
      'prixMax': prices.last,
    };
  }

  void _toggleServiceSelection(ServiceWithPromo service) {
    setState(() {
      if (selectedServices.any((s) => s.id == service.id)) {
        selectedServices.removeWhere((s) => s.id == service.id);
      } else {
        selectedServices.add(service);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée du modal
              Container(
                width: 40,
                height: 5,
                margin: EdgeInsets.only(top: 15, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // En-tête
              _construireEntete(),

              // Corps du modal
              Expanded(
                child: _construireCorps(scrollController),
              ),

              // Boutons d'action en bas
              if (selectedServices.isNotEmpty)
                _construireBarreInferieure(),
            ],
          ),
        );
      },
    );
  }

  Widget _construireEntete() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Services disponibles",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "${widget.salon.nom} • ${allServices.length} services",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          if (selectedServices.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${selectedServices.length} service(s) sélectionné(s)",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _getTotalPrixSelectionnees(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // ✅ Badge économies si promotions
                  if (_getTotalEconomies() > 0) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "-${_getTotalEconomies().toStringAsFixed(0)}€",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ✅ Calcule le total des prix avec promotions appliquées
  String _getTotalPrixSelectionnees() {
    if (selectedServices.isEmpty) return "";
    final total = selectedServices.fold<double>(0, (sum, service) => sum + service.prix_final);
    return "${total.toStringAsFixed(0)}€";
  }

  /// ✅ Calcule le total des économies
  double _getTotalEconomies() {
    return selectedServices.fold<double>(0, (sum, service) {
      if (service.hasActivePromotion()) {
        return sum + service.getMontantEconomise();
      }
      return sum;
    });
  }

  /// ✅ Calcule le prix original total (sans promotions)
  String _getTotalPrixOriginaux() {
    if (selectedServices.isEmpty) return "";
    final total = selectedServices.fold<double>(0, (sum, service) => sum + service.prix);
    return "${total.toStringAsFixed(0)}€";
  }

  Widget _construireCorps([ScrollController? scrollController]) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: widget.primaryColor),
            SizedBox(height: 16),
            Text("Chargement des services..."),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            SizedBox(height: 16),
            Text("Erreur de chargement",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(errorMessage!, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _chargerDonnees,
              icon: Icon(Icons.refresh),
              label: Text("Réessayer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (servicesByCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa, size: 64, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text("Aucun service disponible",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Ce salon n'a pas encore configuré ses services",
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sélecteur de catégories
        _construireSelecteurCategories(),

        // Zone des services
        Expanded(child: _construireZoneServices(scrollController)),
      ],
    );
  }

  Widget _construireSelecteurCategories() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: servicesByCategory.keys.map((categoryName) {
          final estActive = categorieSelectionnee == categoryName;
          final couleurCategorie = _getCouleurCategorie(servicesByCategory.keys.toList().indexOf(categoryName));
          final stats = _getCategorieStats(categoryName);

          return GestureDetector(
            onTap: () {
              setState(() {
                categorieSelectionnee = categoryName;
                searchQuery = '';
                searchController.clear();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estActive ? couleurCategorie : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: couleurCategorie, width: 1.5),
                boxShadow: estActive ? [
                  BoxShadow(
                    color: couleurCategorie.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconeCategorie(categoryName),
                    color: estActive ? Colors.white : couleurCategorie,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: estActive ? Colors.white : couleurCategorie,
                    ),
                  ),
                  if (estActive) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${stats['count']}",
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _construireZoneServices([ScrollController? scrollController]) {
    if (categorieSelectionnee == null) {
      return Center(child: Text("Sélectionnez une catégorie"));
    }

    final servicesFiltered = _getServicesFiltered();
    final stats = _getCategorieStats(categorieSelectionnee!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête de catégorie avec recherche
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconeCategorie(categorieSelectionnee!),
                      color: widget.primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(categorieSelectionnee!,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (stats['count'] > 0)
                          Text("${stats['count']} service(s) • ${stats['prixMin'].toStringAsFixed(0)}€ - ${stats['prixMax'].toStringAsFixed(0)}€",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Rechercher un service...",
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        searchController.clear();
                        searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ],
          ),
        ),

        // Liste des services
        Expanded(
          child: servicesFiltered.isEmpty
              ? _construireEtatVide()
              : ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: servicesFiltered.length,
            itemBuilder: (context, index) => _construireCarteService(servicesFiltered[index]),
          ),
        ),
      ],
    );
  }

  Widget _construireEtatVide() {
    final bool isSearching = searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              isSearching
                  ? "Aucun service trouvé pour \"$searchQuery\""
                  : "Aucun service dans cette catégorie",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              isSearching
                  ? "Essayez avec d'autres mots-clés"
                  : "Ce salon n'a pas encore ajouté de services dans cette catégorie",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    searchController.clear();
                    searchQuery = '';
                  });
                },
                icon: Icon(Icons.clear),
                label: Text("Effacer la recherche"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construireCarteService(ServiceWithPromo service) {
    final estSelectionne = selectedServices.any((s) => s.id == service.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estSelectionne ? widget.primaryColor : Colors.grey.shade200,
          width: estSelectionne ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: estSelectionne
                ? widget.primaryColor.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: estSelectionne ? 12 : 6,
            spreadRadius: estSelectionne ? 2 : 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // ✅ Badge promotion en haut à droite
          if (service.hasActivePromotion())
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "-${service.getCurrentDiscountPercentage()?.toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _toggleServiceSelection(service),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: estSelectionne ? widget.primaryColor : Colors.transparent,
                        border: Border.all(
                          color: estSelectionne ? widget.primaryColor : Colors.grey.shade400,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: estSelectionne
                          ? Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),

                    SizedBox(width: 16),

                    // Informations du service
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.intitule,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: estSelectionne ? widget.primaryColor : Color(0xFF333333),
                            ),
                          ),
                          SizedBox(height: 6),
                          // Text(
                          //   service.description,
                          //   style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                          //   maxLines: 2,
                          //   overflow: TextOverflow.ellipsis,
                          // ),
                          // SizedBox(height: 12),

                          // ✅ Prix avec gestion des promotions
                          Row(
                            children: [
                              // Prix principal (avec ou sans promotion)
                              if (service.hasActivePromotion()) ...[
                                // Prix barré (prix original)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    "${service.prix.toStringAsFixed(0)}€",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4),
                                // Prix promotionnel
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${service.prix_final.toStringAsFixed(0)}€",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Prix normal (sans promotion)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${service.prix_final.toStringAsFixed(0)}€",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.accentColor,
                                    ),
                                  ),
                                ),
                              ],

                              SizedBox(width: 8),

                              // Durée
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${service.temps}min",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ✅ Affichage des économies si promotion
                          if (service.hasActivePromotion()) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.savings, color: Colors.green, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    "Économisez ${service.getMontantEconomise().toStringAsFixed(0)}€",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Icône de sélection
                    if (estSelectionne)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Sélectionné",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireBarreInferieure() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Récapitulatif des économies si promotions
            if (_getTotalEconomies() > 0) ...[
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Vous économisez ${_getTotalEconomies().toStringAsFixed(0)}€ !",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            "Prix avant promotions : ${_getTotalPrixOriginaux()}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedServices.clear();
                      });
                    },
                    icon: Icon(Icons.clear_all),
                    label: Text("Effacer"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // ✅ Retourner directement les ServiceWithPromo sélectionnés
                      Navigator.of(context).pop(selectedServices);
                    },
                    icon: Icon(Icons.shopping_cart),
                    label: Text("Ajouter (${selectedServices.length}) • ${_getTotalPrixSelectionnees()}"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthode helper pour obtenir des couleurs uniques par catégorie
  Color _getCouleurCategorie(int index) {
    final couleurs = [
      const Color(0xFF7B61FF), // Violet
      const Color(0xFFE67E22), // Orange
      const Color(0xFF2ECC71), // Vert
      const Color(0xFFE74C3C), // Rouge
      const Color(0xFF3498DB), // Bleu
      const Color(0xFF9B59B6), // Violet foncé
      const Color(0xFF1ABC9C), // Turquoise
      const Color(0xFFF39C12), // Jaune orangé
    ];
    return couleurs[index % couleurs.length];
  }

  // Obtenir l'icône appropriée pour chaque catégorie
  IconData _getIconeCategorie(String nomCategorie) {
    switch (nomCategorie.toLowerCase()) {
      case 'coiffure':
      case 'cheveux':
        return Icons.content_cut;
      case 'esthétique':
      case 'beauté':
      case 'soin':
        return Icons.spa;
      case 'manucure':
      case 'ongles':
        return Icons.back_hand;
      case 'massage':
        return Icons.healing;
      case 'maquillage':
        return Icons.brush;
      case 'barbier':
      case 'homme':
        return Icons.face_retouching_natural;
      case 'lissage & défrisage':
      case 'lissage':
        return Icons.straighten;
      case 'mèches & balayage':
      case 'mèches':
        return Icons.brush;
      case 'autre':
        return Icons.miscellaneous_services;
      default:
        return Icons.star;
    }
  }
}







// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/salon_details_geo.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/select_services/create_firsts_services_api/services_api_service.dart';
//
// import '../../../models/salon_service.dart';
//
// class SalonServicesModal extends StatefulWidget {
//   final SalonDetailsForGeo salon;
//   final Color primaryColor;
//   final Color accentColor;
//
//   const SalonServicesModal({
//     super.key,
//     required this.salon,
//     this.primaryColor = const Color(0xFF7B61FF),
//     this.accentColor = const Color(0xFFE67E22),
//   });
//
//   @override
//   State<SalonServicesModal> createState() => _SalonServicesModalState();
// }
//
// class _SalonServicesModalState extends State<SalonServicesModal> {
//   // États simplifiés avec le nouveau modèle
//   List<SalonService> allServices = [];
//   List<SalonService> selectedServices = [];
//   Map<String, List<SalonService>> servicesByCategory = {};
//
//   // États de chargement
//   bool isLoading = false;
//   String? errorMessage;
//   String? categorieSelectionnee;
//   TextEditingController searchController = TextEditingController();
//   String searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerDonnees();
//   }
//
//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
//
//   /// Charger toutes les données du salon en un seul appel
//   Future<void> _chargerDonnees() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       print("🚀 Chargement des services pour le salon: ${widget.salon.nom}");
//
//       // UN SEUL APPEL API ! 🎯
//       final data = await ServicesApiService.chargerServicesParCategoriePourSalon(
//         widget.salon.proprietaire!.idTblUser, // ID du salon directement
//       );
//
//       final servicesByCategory = data['services_by_category'] as List;
//
//       // ✅ Conversion directe en List<SalonService>
//       List<SalonService> services = [];
//       for (var categoryJson in servicesByCategory) {
//         final categoryServices = categoryJson['services'] as List;
//         for (var serviceJson in categoryServices) {
//           services.add(SalonService.fromJson(serviceJson));
//         }
//       }
//
//       // ✅ Grouper les services par catégorie
//       final groupedServices = <String, List<SalonService>>{};
//       for (var service in services) {
//         final categoryName = service.categorieNom;
//         if (!groupedServices.containsKey(categoryName)) {
//           groupedServices[categoryName] = [];
//         }
//         groupedServices[categoryName]!.add(service);
//       }
//
//       setState(() {
//         allServices = services;
//         this.servicesByCategory = groupedServices;
//
//         // Sélectionner la première catégorie si disponible
//         if (groupedServices.isNotEmpty) {
//           categorieSelectionnee = groupedServices.keys.first;
//         }
//       });
//
//       print("✅ ${services.length} services chargés en ${groupedServices.length} catégories");
//
//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString();
//       });
//       print("❌ Erreur chargement: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   /// Récupérer les services de la catégorie sélectionnée
//   List<SalonService> _getServicesCategorie() {
//     if (categorieSelectionnee == null) return [];
//     return servicesByCategory[categorieSelectionnee] ?? [];
//   }
//
//   /// Filtrer les services selon la recherche
//   List<SalonService> _getServicesFiltered() {
//     final servicesCategorie = _getServicesCategorie();
//     if (searchQuery.isEmpty) return servicesCategorie;
//
//     return servicesCategorie.where((service) =>
//     service.intituleService.toLowerCase().contains(searchQuery.toLowerCase()) ||
//         service.description.toLowerCase().contains(searchQuery.toLowerCase())
//     ).toList();
//   }
//
//   /// Calculer les statistiques d'une catégorie
//   Map<String, dynamic> _getCategorieStats(String categoryName) {
//     final services = servicesByCategory[categoryName] ?? [];
//     if (services.isEmpty) {
//       return {
//         'count': 0,
//         'prixMin': 0.0,
//         'prixMax': 0.0,
//       };
//     }
//
//     final prices = services.map((s) => s.prixFinal).toList()..sort();
//     return {
//       'count': services.length,
//       'prixMin': prices.first,
//       'prixMax': prices.last,
//     };
//   }
//
//   void _toggleServiceSelection(SalonService service) {
//     setState(() {
//       if (selectedServices.any((s) => s.idTblService == service.idTblService)) {
//         selectedServices.removeWhere((s) => s.idTblService == service.idTblService);
//       } else {
//         selectedServices.add(service);
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.9,
//       minChildSize: 0.5,
//       maxChildSize: 0.95,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFF7F7F9),
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Poignée du modal
//               Container(
//                 width: 40,
//                 height: 5,
//                 margin: EdgeInsets.only(top: 15, bottom: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//
//               // En-tête
//               _construireEntete(),
//
//               // Corps du modal
//               Expanded(
//                 child: _construireCorps(scrollController),
//               ),
//
//               // Boutons d'action en bas
//               if (selectedServices.isNotEmpty)
//                 _construireBarreInferieure(),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _construireEntete() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: widget.primaryColor,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       "Services disponibles",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Text(
//                       "${widget.salon.nom} • ${allServices.length} services",
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.normal,
//                         color: Colors.white70,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 icon: Icon(Icons.close, color: Colors.white),
//               ),
//             ],
//           ),
//           if (selectedServices.isNotEmpty) ...[
//             SizedBox(height: 16),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.shopping_cart, color: Colors.white, size: 20),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "${selectedServices.length} service(s) sélectionné(s)",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   Text(
//                     _getTotalPrixSelectionnees(),
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   // ✅ Badge économies si promotions
//                   if (_getTotalEconomies() > 0) ...[
//                     SizedBox(width: 8),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         "-${_getTotalEconomies().toStringAsFixed(0)}€",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   /// Calcule le total des prix avec promotions appliquées
//   String _getTotalPrixSelectionnees() {
//     if (selectedServices.isEmpty) return "";
//     final total = selectedServices.fold<double>(0, (sum, service) => sum + service.prixFinal);
//     return "${total.toStringAsFixed(0)}€";
//   }
//
//   /// Calcule le total des économies
//   double _getTotalEconomies() {
//     return selectedServices.fold<double>(0, (sum, service) {
//       if (service.hasPromotion) {
//         return sum + service.promotion!.economie;
//       }
//       return sum;
//     });
//   }
//
//   /// Calcule le prix original total (sans promotions)
//   String _getTotalPrixOriginaux() {
//     if (selectedServices.isEmpty) return "";
//     final total = selectedServices.fold<double>(0, (sum, service) => sum + service.prix);
//     return "${total.toStringAsFixed(0)}€";
//   }
//
//   Widget _construireCorps([ScrollController? scrollController]) {
//     if (isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(color: widget.primaryColor),
//             SizedBox(height: 16),
//             Text("Chargement des services..."),
//           ],
//         ),
//       );
//     }
//
//     if (errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
//             SizedBox(height: 16),
//             Text("Erreur de chargement",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             SizedBox(height: 8),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 32),
//               child: Text(errorMessage!, textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey.shade600)),
//             ),
//             SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerDonnees,
//               icon: Icon(Icons.refresh),
//               label: Text("Réessayer"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: widget.primaryColor,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (servicesByCategory.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.spa, size: 64, color: Colors.grey.shade300),
//             SizedBox(height: 16),
//             Text("Aucun service disponible",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             SizedBox(height: 8),
//             Text("Ce salon n'a pas encore configuré ses services",
//                 style: TextStyle(color: Colors.grey.shade600)),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Sélecteur de catégories
//         _construireSelecteurCategories(),
//
//         // Zone des services
//         Expanded(child: _construireZoneServices(scrollController)),
//       ],
//     );
//   }
//
//   Widget _construireSelecteurCategories() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         alignment: WrapAlignment.start,
//         children: servicesByCategory.keys.map((categoryName) {
//           final estActive = categorieSelectionnee == categoryName;
//           final couleurCategorie = _getCouleurCategorie(servicesByCategory.keys.toList().indexOf(categoryName));
//           final stats = _getCategorieStats(categoryName);
//
//           return GestureDetector(
//             onTap: () {
//               setState(() {
//                 categorieSelectionnee = categoryName;
//                 searchQuery = '';
//                 searchController.clear();
//               });
//             },
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 250),
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: estActive ? couleurCategorie : Colors.white,
//                 borderRadius: BorderRadius.circular(18),
//                 border: Border.all(color: couleurCategorie, width: 1.5),
//                 boxShadow: estActive ? [
//                   BoxShadow(
//                     color: couleurCategorie.withOpacity(0.25),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   ),
//                 ] : [],
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     _getIconeCategorie(categoryName),
//                     color: estActive ? Colors.white : couleurCategorie,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     categoryName,
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: estActive ? Colors.white : couleurCategorie,
//                     ),
//                   ),
//                   if (estActive) ...[
//                     const SizedBox(width: 4),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         "${stats['count']}",
//                         style: const TextStyle(
//                           fontSize: 8,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _construireZoneServices([ScrollController? scrollController]) {
//     if (categorieSelectionnee == null) {
//       return Center(child: Text("Sélectionnez une catégorie"));
//     }
//
//     final servicesFiltered = _getServicesFiltered();
//     final stats = _getCategorieStats(categorieSelectionnee!);
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // En-tête de catégorie avec recherche
//         Container(
//           padding: const EdgeInsets.all(16),
//           color: Colors.white,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: widget.primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       _getIconeCategorie(categorieSelectionnee!),
//                       color: widget.primaryColor,
//                       size: 20,
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(categorieSelectionnee!,
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         if (stats['count'] > 0)
//                           Text("${stats['count']} service(s) • ${stats['prixMin'].toStringAsFixed(0)}€ - ${stats['prixMax'].toStringAsFixed(0)}€",
//                               style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: searchController,
//                 decoration: InputDecoration(
//                   hintText: "Rechercher un service...",
//                   prefixIcon: Icon(Icons.search),
//                   suffixIcon: searchQuery.isNotEmpty
//                       ? IconButton(
//                     icon: Icon(Icons.clear),
//                     onPressed: () {
//                       setState(() {
//                         searchController.clear();
//                         searchQuery = '';
//                       });
//                     },
//                   )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.grey.shade300),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: widget.primaryColor),
//                   ),
//                   filled: true,
//                   fillColor: Colors.grey.shade50,
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     searchQuery = value;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),
//
//         // Liste des services
//         Expanded(
//           child: servicesFiltered.isEmpty
//               ? _construireEtatVide()
//               : ListView.builder(
//             controller: scrollController,
//             padding: const EdgeInsets.all(16),
//             itemCount: servicesFiltered.length,
//             itemBuilder: (context, index) => _construireCarteService(servicesFiltered[index]),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _construireEtatVide() {
//     final bool isSearching = searchQuery.isNotEmpty;
//
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               isSearching ? Icons.search_off : Icons.inbox_outlined,
//               size: 64,
//               color: Colors.grey.shade300,
//             ),
//             SizedBox(height: 16),
//             Text(
//               isSearching
//                   ? "Aucun service trouvé pour \"$searchQuery\""
//                   : "Aucun service dans cette catégorie",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 8),
//             Text(
//               isSearching
//                   ? "Essayez avec d'autres mots-clés"
//                   : "Ce salon n'a pas encore ajouté de services dans cette catégorie",
//               style: TextStyle(color: Colors.grey.shade600),
//               textAlign: TextAlign.center,
//             ),
//             if (isSearching) ...[
//               SizedBox(height: 24),
//               TextButton.icon(
//                 onPressed: () {
//                   setState(() {
//                     searchController.clear();
//                     searchQuery = '';
//                   });
//                 },
//                 icon: Icon(Icons.clear),
//                 label: Text("Effacer la recherche"),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _construireCarteService(SalonService service) {
//     final estSelectionne = selectedServices.any((s) => s.idTblService == service.idTblService);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: estSelectionne ? widget.primaryColor : Colors.grey.shade200,
//           width: estSelectionne ? 2 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: estSelectionne
//                 ? widget.primaryColor.withOpacity(0.1)
//                 : Colors.black.withOpacity(0.05),
//             blurRadius: estSelectionne ? 12 : 6,
//             spreadRadius: estSelectionne ? 2 : 1,
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           // ✅ Badge promotion en haut à droite
//           if (service.hasPromotion)
//             Positioned(
//               top: 12,
//               right: 12,
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.red.withOpacity(0.3),
//                       blurRadius: 4,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Text(
//                   service.promotion!.pourcentageFormate,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//
//           Material(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.circular(16),
//             child: InkWell(
//               onTap: () => _toggleServiceSelection(service),
//               borderRadius: BorderRadius.circular(16),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Row(
//                   children: [
//                     // Checkbox
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       width: 24,
//                       height: 24,
//                       decoration: BoxDecoration(
//                         color: estSelectionne ? widget.primaryColor : Colors.transparent,
//                         border: Border.all(
//                           color: estSelectionne ? widget.primaryColor : Colors.grey.shade400,
//                           width: 2,
//                         ),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: estSelectionne
//                           ? Icon(Icons.check, color: Colors.white, size: 16)
//                           : null,
//                     ),
//
//                     SizedBox(width: 16),
//
//                     // Informations du service
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             service.intituleService,
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: estSelectionne ? widget.primaryColor : Color(0xFF333333),
//                             ),
//                           ),
//                           SizedBox(height: 6),
//                           Text(
//                             service.description,
//                             style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           SizedBox(height: 12),
//
//                           // ✅ Prix avec gestion des promotions
//                           Row(
//                             children: [
//                               // Prix principal (avec ou sans promotion)
//                               if (service.hasPromotion) ...[
//                                 // Prix barré (prix original)
//                                 Container(
//                                   padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                   child: Text(
//                                     service.prixFormate,
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey.shade500,
//                                       decoration: TextDecoration.lineThrough,
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 4),
//                                 // Prix promotionnel
//                                 Container(
//                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.red.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     service.prixFinalFormate,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.red,
//                                     ),
//                                   ),
//                                 ),
//                               ] else ...[
//                                 // Prix normal (sans promotion)
//                                 Container(
//                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: widget.accentColor.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     service.prixFinalFormate,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600,
//                                       color: widget.accentColor,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//
//                               SizedBox(width: 8),
//
//                               // Durée
//                               Container(
//                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   service.dureeFormatee,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.blue,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//
//                           // ✅ Affichage des économies si promotion
//                           if (service.hasPromotion) ...[
//                             SizedBox(height: 8),
//                             Container(
//                               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: Colors.green.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(Icons.savings, color: Colors.green, size: 12),
//                                   SizedBox(width: 4),
//                                   Text(
//                                     service.promotion!.economieFormatee,
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//
//                     // Icône de sélection
//                     if (estSelectionne)
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: widget.primaryColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           "Sélectionné",
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: widget.primaryColor,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _construireBarreInferieure() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // ✅ Récapitulatif des économies si promotions
//             if (_getTotalEconomies() > 0) ...[
//               Container(
//                 padding: EdgeInsets.all(12),
//                 margin: EdgeInsets.only(bottom: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.green.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.local_offer, color: Colors.green, size: 20),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             "Vous économisez ${_getTotalEconomies().toStringAsFixed(0)}€ !",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green.shade700,
//                             ),
//                           ),
//                           Text(
//                             "Prix avant promotions : ${_getTotalPrixOriginaux()}",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.green.shade600,
//                               decoration: TextDecoration.lineThrough,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//
//             // Boutons d'action
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         selectedServices.clear();
//                       });
//                     },
//                     icon: Icon(Icons.clear_all),
//                     label: Text("Effacer"),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.grey,
//                       side: BorderSide(color: Colors.grey),
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   flex: 2,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       // ✅ Retourner directement les SalonService sélectionnés
//                       Navigator.of(context).pop(selectedServices);
//                     },
//                     icon: Icon(Icons.shopping_cart),
//                     label: Text("Ajouter (${selectedServices.length}) • ${_getTotalPrixSelectionnees()}"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: widget.primaryColor,
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       elevation: 4,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Méthode helper pour obtenir des couleurs uniques par catégorie
//   Color _getCouleurCategorie(int index) {
//     final couleurs = [
//       const Color(0xFF7B61FF), // Violet
//       const Color(0xFFE67E22), // Orange
//       const Color(0xFF2ECC71), // Vert
//       const Color(0xFFE74C3C), // Rouge
//       const Color(0xFF3498DB), // Bleu
//       const Color(0xFF9B59B6), // Violet foncé
//       const Color(0xFF1ABC9C), // Turquoise
//       const Color(0xFFF39C12), // Jaune orangé
//     ];
//     return couleurs[index % couleurs.length];
//   }
//
//   // Obtenir l'icône appropriée pour chaque catégorie
//   IconData _getIconeCategorie(String nomCategorie) {
//     switch (nomCategorie.toLowerCase()) {
//       case 'coiffure':
//       case 'cheveux':
//         return Icons.content_cut;
//       case 'esthétique':
//       case 'beauté':
//       case 'soin':
//         return Icons.spa;
//       case 'manucure':
//       case 'ongles':
//         return Icons.back_hand;
//       case 'massage':
//         return Icons.healing;
//       case 'maquillage':
//         return Icons.brush;
//       case 'barbier':
//       case 'homme':
//         return Icons.face_retouching_natural;
//       case 'lissage & défrisage':
//       case 'lissage':
//         return Icons.straighten;
//       case 'mèches & balayage':
//       case 'mèches':
//         return Icons.brush;
//       case 'autre':
//         return Icons.miscellaneous_services;
//       default:
//         return Icons.star;
//     }
//   }
// }
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/salon_details_geo.dart';
// // import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/select_services/create_firsts_services_api/services_api_service.dart';
// //
// // import '../../../models/salon_service.dart';
// //
// // class SalonServicesModal extends StatefulWidget {
// //   final SalonDetailsForGeo salon;
// //   final Color primaryColor;
// //   final Color accentColor;
// //
// //   const SalonServicesModal({
// //     super.key,
// //     required this.salon,
// //     this.primaryColor = const Color(0xFF7B61FF),
// //     this.accentColor = const Color(0xFFE67E22),
// //   });
// //
// //   @override
// //   State<SalonServicesModal> createState() => _SalonServicesModalState();
// // }
// //
// // class _SalonServicesModalState extends State<SalonServicesModal> {
// //   // États avec le nouveau modèle
// //   List<SalonServicePromotion> categories = [];
// //   List<SalonService> selectedServices = [];
// //
// //   // États de chargement
// //   bool isLoading = false;
// //   String? errorMessage;
// //   int? categorieSelectionnee;
// //   TextEditingController searchController = TextEditingController();
// //   String searchQuery = '';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _chargerDonnees();
// //   }
// //
// //   @override
// //   void dispose() {
// //     searchController.dispose();
// //     super.dispose();
// //   }
// //
// //   /// Charger toutes les données du salon en un seul appel
// //   Future<void> _chargerDonnees() async {
// //     setState(() {
// //       isLoading = true;
// //       errorMessage = null;
// //     });
// //
// //     try {
// //       print("🚀 Chargement des services pour le salon: ${widget.salon.nom}");
// //
// //       // UN SEUL APPEL API ! 🎯
// //       final data = await ServicesApiService.chargerServicesParCategoriePourSalon(
// //         widget.salon.proprietaire!.idTblUser, // ID du salon directement
// //       );
// //
// //       final servicesByCategory = data['services_by_category'] as List;
// //
// //       // Conversion avec le nouveau modèle
// //       final categoriesConverties = servicesByCategory
// //           .map((categoryJson) => SalonServicePromotion.fromJson(categoryJson))
// //           .toList();
// //
// //       setState(() {
// //         categories =
// //
// //         // Sélectionner la première catégorie si disponible
// //         if (categories.isNotEmpty) {
// //           categorieSelectionnee = categories.
// //         }
// //       });
// //
// //       final totalServices = categories.fold<int>(0, (sum, cat) => sum + cat.serviceCount);
// //       print("✅ $totalServices services chargés en ${categories.length} catégories");
// //
// //     } catch (e) {
// //       setState(() {
// //         errorMessage = e.toString();
// //       });
// //       print("❌ Erreur chargement: $e");
// //     } finally {
// //       setState(() => isLoading = false);
// //     }
// //   }
// //
// //   /// Récupérer la catégorie sélectionnée
// //   SalonServiceCategory? _getCategorieSelectionnee() {
// //     if (categorieSelectionnee == null) return null;
// //     try {
// //       return categories.firstWhere(
// //             (cat) => cat.categoryId == categorieSelectionnee,
// //       );
// //     } catch (e) {
// //       return null;
// //     }
// //   }
// //
// //   /// Filtrer les services selon la recherche
// //   List<SalonService> _getServicesFiltered() {
// //     final categorieActive = _getCategorieSelectionnee();
// //     if (categorieActive == null) return [];
// //
// //     if (searchQuery.isEmpty) return categorieActive.services;
// //
// //     return categorieActive.services.where((service) =>
// //     service.intituleService.toLowerCase().contains(searchQuery.toLowerCase()) ||
// //         service.description.toLowerCase().contains(searchQuery.toLowerCase())
// //     ).toList();
// //   }
// //
// //   void _toggleServiceSelection(SalonService service) {
// //     setState(() {
// //       if (selectedServices.any((s) => s.idTblService == service.idTblService)) {
// //         selectedServices.removeWhere((s) => s.idTblService == service.idTblService);
// //       } else {
// //         selectedServices.add(service);
// //       }
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return DraggableScrollableSheet(
// //       initialChildSize: 0.9,
// //       minChildSize: 0.5,
// //       maxChildSize: 0.95,
// //       builder: (context, scrollController) {
// //         return Container(
// //           decoration: BoxDecoration(
// //             color: const Color(0xFFF7F7F9),
// //             borderRadius: BorderRadius.only(
// //               topLeft: Radius.circular(20),
// //               topRight: Radius.circular(20),
// //             ),
// //           ),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               // Poignée du modal
// //               Container(
// //                 width: 40,
// //                 height: 5,
// //                 margin: EdgeInsets.only(top: 15, bottom: 10),
// //                 decoration: BoxDecoration(
// //                   color: Colors.grey[300],
// //                   borderRadius: BorderRadius.circular(10),
// //                 ),
// //               ),
// //
// //               // En-tête
// //               _construireEntete(),
// //
// //               // Corps du modal
// //               Expanded(
// //                 child: _construireCorps(scrollController),
// //               ),
// //
// //               // Boutons d'action en bas
// //               if (selectedServices.isNotEmpty)
// //                 _construireBarreInferieure(),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _construireEntete() {
// //     final totalServices = categories.fold<int>(0, (sum, cat) => sum + cat.serviceCount);
// //
// //     return Container(
// //       padding: const EdgeInsets.all(20),
// //       decoration: BoxDecoration(
// //         color: widget.primaryColor,
// //         borderRadius: BorderRadius.only(
// //           topLeft: Radius.circular(20),
// //           topRight: Radius.circular(20),
// //         ),
// //       ),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     Text(
// //                       "Services disponibles",
// //                       style: TextStyle(
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.bold,
// //                         color: Colors.white,
// //                       ),
// //                     ),
// //                     Text(
// //                       "${widget.salon.nom} • $totalServices services",
// //                       style: TextStyle(
// //                         fontSize: 14,
// //                         fontWeight: FontWeight.normal,
// //                         color: Colors.white70,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               IconButton(
// //                 onPressed: () => Navigator.of(context).pop(),
// //                 icon: Icon(Icons.close, color: Colors.white),
// //               ),
// //             ],
// //           ),
// //           if (selectedServices.isNotEmpty) ...[
// //             SizedBox(height: 16),
// //             Container(
// //               padding: EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: Colors.white.withOpacity(0.2),
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Icon(Icons.shopping_cart, color: Colors.white, size: 20),
// //                   SizedBox(width: 8),
// //                   Expanded(
// //                     child: Text(
// //                       "${selectedServices.length} service(s) sélectionné(s)",
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                   ),
// //                   Text(
// //                     _getTotalPrixSelectionnees(),
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontWeight: FontWeight.bold,
// //                       fontSize: 16,
// //                     ),
// //                   ),
// //                   // ✅ AJOUT : Badge économies si promotions
// //                   if (_getTotalEconomies() > 0) ...[
// //                     SizedBox(width: 8),
// //                     Container(
// //                       padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// //                       decoration: BoxDecoration(
// //                         color: Colors.green,
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: Text(
// //                         "-${_getTotalEconomies().toStringAsFixed(0)}€",
// //                         style: TextStyle(
// //                           color: Colors.white,
// //                           fontSize: 10,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   /// ✅ NOUVEAU : Calcule le total des prix avec promotions appliquées
// //   String _getTotalPrixSelectionnees() {
// //     if (selectedServices.isEmpty) return "";
// //     final total = selectedServices.fold<double>(0, (sum, service) => sum + service.prixFinal); // ✅ Prix final avec promos !
// //     return "${total.toStringAsFixed(0)}€";
// //   }
// //
// //   /// ✅ NOUVEAU : Calcule le total des économies
// //   double _getTotalEconomies() {
// //     return selectedServices.fold<double>(0, (sum, service) {
// //       if (service.hasPromotion) {
// //         return sum + service.promotion!.economie;
// //       }
// //       return sum;
// //     });
// //   }
// //
// //   /// ✅ NOUVEAU : Calcule le prix original total (sans promotions)
// //   String _getTotalPrixOriginaux() {
// //     if (selectedServices.isEmpty) return "";
// //     final total = selectedServices.fold<double>(0, (sum, service) => sum + service.prix);
// //     return "${total.toStringAsFixed(0)}€";
// //   }
// //
// //   Widget _construireCorps([ScrollController? scrollController]) {
// //     if (isLoading) {
// //       return Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             CircularProgressIndicator(color: widget.primaryColor),
// //             SizedBox(height: 16),
// //             Text("Chargement des services..."),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     if (errorMessage != null) {
// //       return Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
// //             SizedBox(height: 16),
// //             Text("Erreur de chargement",
// //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //             SizedBox(height: 8),
// //             Padding(
// //               padding: EdgeInsets.symmetric(horizontal: 32),
// //               child: Text(errorMessage!, textAlign: TextAlign.center,
// //                   style: TextStyle(color: Colors.grey.shade600)),
// //             ),
// //             SizedBox(height: 24),
// //             ElevatedButton.icon(
// //               onPressed: _chargerDonnees,
// //               icon: Icon(Icons.refresh),
// //               label: Text("Réessayer"),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: widget.primaryColor,
// //                 foregroundColor: Colors.white,
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     if (categories.isEmpty) {
// //       return Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(Icons.spa, size: 64, color: Colors.grey.shade300),
// //             SizedBox(height: 16),
// //             Text("Aucun service disponible",
// //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //             SizedBox(height: 8),
// //             Text("Ce salon n'a pas encore configuré ses services",
// //                 style: TextStyle(color: Colors.grey.shade600)),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     return Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         // Sélecteur de catégories
// //         _construireSelecteurCategories(),
// //
// //         // Zone des services
// //         Expanded(child: _construireZoneServices(scrollController)),
// //       ],
// //     );
// //   }
// //
// //   Widget _construireSelecteurCategories() {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       child: Wrap(
// //         spacing: 8,
// //         runSpacing: 8,
// //         alignment: WrapAlignment.start,
// //         children: categories.map((categorie) {
// //           final estActive = categorieSelectionnee == categorie.categoryId;
// //           final couleurCategorie = _getCouleurCategorie(categories.indexOf(categorie));
// //
// //           return GestureDetector(
// //             onTap: () {
// //               setState(() {
// //                 categorieSelectionnee = categorie.categoryId;
// //                 searchQuery = '';
// //                 searchController.clear();
// //               });
// //             },
// //             child: AnimatedContainer(
// //               duration: const Duration(milliseconds: 250),
// //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //               decoration: BoxDecoration(
// //                 color: estActive ? couleurCategorie : Colors.white,
// //                 borderRadius: BorderRadius.circular(18),
// //                 border: Border.all(color: couleurCategorie, width: 1.5),
// //                 boxShadow: estActive ? [
// //                   BoxShadow(
// //                     color: couleurCategorie.withOpacity(0.25),
// //                     blurRadius: 6,
// //                     offset: const Offset(0, 2),
// //                   ),
// //                 ] : [],
// //               ),
// //               child: Row(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   Icon(
// //                     _getIconeCategorie(categorie.categoryName),
// //                     color: estActive ? Colors.white : couleurCategorie,
// //                     size: 16,
// //                   ),
// //                   const SizedBox(width: 6),
// //                   Text(
// //                     categorie.categoryName,
// //                     style: TextStyle(
// //                       fontSize: 11,
// //                       fontWeight: FontWeight.w600,
// //                       color: estActive ? Colors.white : couleurCategorie,
// //                     ),
// //                   ),
// //                   if (estActive) ...[
// //                     const SizedBox(width: 4),
// //                     Container(
// //                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white.withOpacity(0.3),
// //                         borderRadius: BorderRadius.circular(6),
// //                       ),
// //                       child: Text(
// //                         "${categorie.serviceCount}",
// //                         style: const TextStyle(
// //                           fontSize: 8,
// //                           color: Colors.white,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ],
// //               ),
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   Widget _construireZoneServices([ScrollController? scrollController]) {
// //     final categorieActive = _getCategorieSelectionnee();
// //     if (categorieActive == null) {
// //       return Center(child: Text("Sélectionnez une catégorie"));
// //     }
// //
// //     final servicesFiltered = _getServicesFiltered();
// //
// //     return Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         // En-tête de catégorie avec recherche
// //         Container(
// //           padding: const EdgeInsets.all(16),
// //           color: Colors.white,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Row(
// //                 children: [
// //                   Container(
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: widget.primaryColor.withOpacity(0.1),
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     child: Icon(
// //                       _getIconeCategorie(categorieActive.categoryName),
// //                       color: widget.primaryColor,
// //                       size: 20,
// //                     ),
// //                   ),
// //                   SizedBox(width: 12),
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         Text(categorieActive.categoryName,
// //                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //                         if (categorieActive.serviceCount > 0)
// //                           Text("${categorieActive.serviceCount} service(s) • ${categorieActive.prixMinimum.toStringAsFixed(0)}€ - ${categorieActive.prixMaximum.toStringAsFixed(0)}€",
// //                               style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               SizedBox(height: 16),
// //               TextField(
// //                 controller: searchController,
// //                 decoration: InputDecoration(
// //                   hintText: "Rechercher un service...",
// //                   prefixIcon: Icon(Icons.search),
// //                   suffixIcon: searchQuery.isNotEmpty
// //                       ? IconButton(
// //                     icon: Icon(Icons.clear),
// //                     onPressed: () {
// //                       setState(() {
// //                         searchController.clear();
// //                         searchQuery = '';
// //                       });
// //                     },
// //                   )
// //                       : null,
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                     borderSide: BorderSide(color: Colors.grey.shade300),
// //                   ),
// //                   focusedBorder: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                     borderSide: BorderSide(color: widget.primaryColor),
// //                   ),
// //                   filled: true,
// //                   fillColor: Colors.grey.shade50,
// //                 ),
// //                 onChanged: (value) {
// //                   setState(() {
// //                     searchQuery = value;
// //                   });
// //                 },
// //               ),
// //             ],
// //           ),
// //         ),
// //
// //         // Liste des services
// //         Expanded(
// //           child: servicesFiltered.isEmpty
// //               ? _construireEtatVide(categorieActive)
// //               : ListView.builder(
// //             controller: scrollController,
// //             padding: const EdgeInsets.all(16),
// //             itemCount: servicesFiltered.length,
// //             itemBuilder: (context, index) => _construireCarteService(servicesFiltered[index]),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _construireEtatVide(SalonServiceCategory categorie) {
// //     final bool isSearching = searchQuery.isNotEmpty;
// //
// //     return Center(
// //       child: Padding(
// //         padding: const EdgeInsets.all(32),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(
// //               isSearching ? Icons.search_off : Icons.inbox_outlined,
// //               size: 64,
// //               color: Colors.grey.shade300,
// //             ),
// //             SizedBox(height: 16),
// //             Text(
// //               isSearching
// //                   ? "Aucun service trouvé pour \"$searchQuery\""
// //                   : "Aucun service dans cette catégorie",
// //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
// //               textAlign: TextAlign.center,
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               isSearching
// //                   ? "Essayez avec d'autres mots-clés"
// //                   : "Ce salon n'a pas encore ajouté de services dans cette catégorie",
// //               style: TextStyle(color: Colors.grey.shade600),
// //               textAlign: TextAlign.center,
// //             ),
// //             if (isSearching) ...[
// //               SizedBox(height: 24),
// //               TextButton.icon(
// //                 onPressed: () {
// //                   setState(() {
// //                     searchController.clear();
// //                     searchQuery = '';
// //                   });
// //                 },
// //                 icon: Icon(Icons.clear),
// //                 label: Text("Effacer la recherche"),
// //               ),
// //             ],
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _construireCarteService(SalonService service) {
// //     final estSelectionne = selectedServices.any((s) => s.idTblService == service.idTblService);
// //
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(16),
// //         border: Border.all(
// //           color: estSelectionne ? widget.primaryColor : Colors.grey.shade200,
// //           width: estSelectionne ? 2 : 1,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: estSelectionne
// //                 ? widget.primaryColor.withOpacity(0.1)
// //                 : Colors.black.withOpacity(0.05),
// //             blurRadius: estSelectionne ? 12 : 6,
// //             spreadRadius: estSelectionne ? 2 : 1,
// //           ),
// //         ],
// //       ),
// //       child: Stack(
// //         children: [
// //           // ✅ Badge promotion en haut à droite
// //           if (service.hasPromotion)
// //             Positioned(
// //               top: 12,
// //               right: 12,
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                 decoration: BoxDecoration(
// //                   color: Colors.red,
// //                   borderRadius: BorderRadius.circular(12),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.red.withOpacity(0.3),
// //                       blurRadius: 4,
// //                       offset: Offset(0, 2),
// //                     ),
// //                   ],
// //                 ),
// //                 child: Text(
// //                   service.promotion!.pourcentageFormate,
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 10,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //
// //           Material(
// //             color: Colors.transparent,
// //             borderRadius: BorderRadius.circular(16),
// //             child: InkWell(
// //               onTap: () => _toggleServiceSelection(service),
// //               borderRadius: BorderRadius.circular(16),
// //               child: Padding(
// //                 padding: const EdgeInsets.all(20),
// //                 child: Row(
// //                   children: [
// //                     // Checkbox
// //                     AnimatedContainer(
// //                       duration: const Duration(milliseconds: 200),
// //                       width: 24,
// //                       height: 24,
// //                       decoration: BoxDecoration(
// //                         color: estSelectionne ? widget.primaryColor : Colors.transparent,
// //                         border: Border.all(
// //                           color: estSelectionne ? widget.primaryColor : Colors.grey.shade400,
// //                           width: 2,
// //                         ),
// //                         borderRadius: BorderRadius.circular(6),
// //                       ),
// //                       child: estSelectionne
// //                           ? Icon(Icons.check, color: Colors.white, size: 16)
// //                           : null,
// //                     ),
// //
// //                     SizedBox(width: 16),
// //
// //                     // Informations du service
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             service.intituleService,
// //                             style: TextStyle(
// //                               fontSize: 18,
// //                               fontWeight: FontWeight.bold,
// //                               color: estSelectionne ? widget.primaryColor : Color(0xFF333333),
// //                             ),
// //                           ),
// //                           SizedBox(height: 6),
// //                           Text(
// //                             service.description,
// //                             style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
// //                             maxLines: 2,
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                           SizedBox(height: 12),
// //
// //                           // ✅ Prix avec gestion des promotions
// //                           Row(
// //                             children: [
// //                               // Prix principal (avec ou sans promotion)
// //                               if (service.hasPromotion) ...[
// //                                 // Prix barré (prix original)
// //                                 Container(
// //                                   padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// //                                   child: Text(
// //                                     service.prixFormate,
// //                                     style: TextStyle(
// //                                       fontSize: 11,
// //                                       color: Colors.grey.shade500,
// //                                       decoration: TextDecoration.lineThrough,
// //                                     ),
// //                                   ),
// //                                 ),
// //                                 SizedBox(width: 4),
// //                                 // Prix promotionnel
// //                                 Container(
// //                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                                   decoration: BoxDecoration(
// //                                     color: Colors.red.withOpacity(0.1),
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                   child: Text(
// //                                     service.prixFinalFormate,
// //                                     style: TextStyle(
// //                                       fontSize: 12,
// //                                       fontWeight: FontWeight.w600,
// //                                       color: Colors.red,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ] else ...[
// //                                 // Prix normal (sans promotion)
// //                                 Container(
// //                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                                   decoration: BoxDecoration(
// //                                     color: widget.accentColor.withOpacity(0.1),
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                   child: Text(
// //                                     service.prixFinalFormate,
// //                                     style: TextStyle(
// //                                       fontSize: 12,
// //                                       fontWeight: FontWeight.w600,
// //                                       color: widget.accentColor,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ],
// //
// //                               SizedBox(width: 8),
// //
// //                               // Durée
// //                               Container(
// //                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                                 decoration: BoxDecoration(
// //                                   color: Colors.blue.withOpacity(0.1),
// //                                   borderRadius: BorderRadius.circular(12),
// //                                 ),
// //                                 child: Text(
// //                                   service.dureeFormatee,
// //                                   style: TextStyle(
// //                                     fontSize: 12,
// //                                     fontWeight: FontWeight.w600,
// //                                     color: Colors.blue,
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //
// //                           // ✅ Affichage des économies si promotion
// //                           if (service.hasPromotion) ...[
// //                             SizedBox(height: 8),
// //                             Container(
// //                               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.green.withOpacity(0.1),
// //                                 borderRadius: BorderRadius.circular(8),
// //                               ),
// //                               child: Row(
// //                                 mainAxisSize: MainAxisSize.min,
// //                                 children: [
// //                                   Icon(Icons.savings, color: Colors.green, size: 12),
// //                                   SizedBox(width: 4),
// //                                   Text(
// //                                     service.promotion!.economieFormatee,
// //                                     style: TextStyle(
// //                                       fontSize: 10,
// //                                       fontWeight: FontWeight.w600,
// //                                       color: Colors.green,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ],
// //                         ],
// //                       ),
// //                     ),
// //
// //                     // Icône de sélection
// //                     if (estSelectionne)
// //                       Container(
// //                         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                         decoration: BoxDecoration(
// //                           color: widget.primaryColor.withOpacity(0.1),
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                         child: Text(
// //                           "Sélectionné",
// //                           style: TextStyle(
// //                             fontSize: 10,
// //                             fontWeight: FontWeight.w600,
// //                             color: widget.primaryColor,
// //                           ),
// //                         ),
// //                       ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _construireBarreInferieure() {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.1),
// //             blurRadius: 10,
// //             spreadRadius: 1,
// //           ),
// //         ],
// //       ),
// //       child: SafeArea(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             // ✅ NOUVEAU : Récapitulatif des économies si promotions
// //             if (_getTotalEconomies() > 0) ...[
// //               Container(
// //                 padding: EdgeInsets.all(12),
// //                 margin: EdgeInsets.only(bottom: 12),
// //                 decoration: BoxDecoration(
// //                   color: Colors.green.withOpacity(0.1),
// //                   borderRadius: BorderRadius.circular(12),
// //                   border: Border.all(color: Colors.green.withOpacity(0.3)),
// //                 ),
// //                 child: Row(
// //                   children: [
// //                     Icon(Icons.local_offer, color: Colors.green, size: 20),
// //                     SizedBox(width: 8),
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         mainAxisSize: MainAxisSize.min,
// //                         children: [
// //                           Text(
// //                             "Vous économisez ${_getTotalEconomies().toStringAsFixed(0)}€ !",
// //                             style: TextStyle(
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.green.shade700,
// //                             ),
// //                           ),
// //                           Text(
// //                             "Prix avant promotions : ${_getTotalPrixOriginaux()}",
// //                             style: TextStyle(
// //                               fontSize: 12,
// //                               color: Colors.green.shade600,
// //                               decoration: TextDecoration.lineThrough,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //
// //             // Boutons d'action
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: OutlinedButton.icon(
// //                     onPressed: () {
// //                       setState(() {
// //                         selectedServices.clear();
// //                       });
// //                     },
// //                     icon: Icon(Icons.clear_all),
// //                     label: Text("Effacer"),
// //                     style: OutlinedButton.styleFrom(
// //                       foregroundColor: Colors.grey,
// //                       side: BorderSide(color: Colors.grey),
// //                       padding: EdgeInsets.symmetric(vertical: 16),
// //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(width: 12),
// //                 Expanded(
// //                   flex: 2,
// //                   child: ElevatedButton.icon(
// //                     onPressed: () {
// //                       // ✅ Retourner les services sélectionnés convertis en Service
// //                       final servicesForCompatibility = selectedServices.map((s) => s.toService()).toList();
// //                       Navigator.of(context).pop(servicesForCompatibility);
// //                     },
// //                     icon: Icon(Icons.shopping_cart),
// //                     label: Text("Ajouter (${selectedServices.length}) • ${_getTotalPrixSelectionnees()}"),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: widget.primaryColor,
// //                       foregroundColor: Colors.white,
// //                       padding: EdgeInsets.symmetric(vertical: 16),
// //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                       elevation: 4,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // Méthode helper pour obtenir des couleurs uniques par catégorie
// //   Color _getCouleurCategorie(int index) {
// //     final couleurs = [
// //       const Color(0xFF7B61FF), // Violet
// //       const Color(0xFFE67E22), // Orange
// //       const Color(0xFF2ECC71), // Vert
// //       const Color(0xFFE74C3C), // Rouge
// //       const Color(0xFF3498DB), // Bleu
// //       const Color(0xFF9B59B6), // Violet foncé
// //       const Color(0xFF1ABC9C), // Turquoise
// //       const Color(0xFFF39C12), // Jaune orangé
// //     ];
// //     return couleurs[index % couleurs.length];
// //   }
// //
// //   // Obtenir l'icône appropriée pour chaque catégorie
// //   IconData _getIconeCategorie(String nomCategorie) {
// //     switch (nomCategorie.toLowerCase()) {
// //       case 'coiffure':
// //       case 'cheveux':
// //         return Icons.content_cut;
// //       case 'esthétique':
// //       case 'beauté':
// //       case 'soin':
// //         return Icons.spa;
// //       case 'manucure':
// //       case 'ongles':
// //         return Icons.back_hand;
// //       case 'massage':
// //         return Icons.healing;
// //       case 'maquillage':
// //         return Icons.brush;
// //       case 'barbier':
// //       case 'homme':
// //         return Icons.face_retouching_natural;
// //       case 'lissage & défrisage':
// //       case 'lissage':
// //         return Icons.straighten;
// //       case 'mèches & balayage':
// //       case 'mèches':
// //         return Icons.brush;
// //       case 'autre':
// //         return Icons.miscellaneous_services;
// //       default:
// //         return Icons.star;
// //     }
// //   }
// // }
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/models/salon_details_geo.dart';
// // // import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/select_services/create_firsts_services_api/services_api_service.dart';
// // //
// // // import '../../../models/salon_service.dart';
// // //
// // // class SalonServicesModal extends StatefulWidget {
// // //   final SalonDetailsForGeo salon;
// // //   final Color primaryColor;
// // //   final Color accentColor;
// // //
// // //   const SalonServicesModal({
// // //     super.key,
// // //     required this.salon,
// // //     this.primaryColor = const Color(0xFF7B61FF),
// // //     this.accentColor = const Color(0xFFE67E22),
// // //   });
// // //
// // //   @override
// // //   State<SalonServicesModal> createState() => _SalonServicesModalState();
// // // }
// // //
// // // class _SalonServicesModalState extends State<SalonServicesModal> {
// // //   // États avec le nouveau modèle
// // //   List<SalonServiceCategory> categories = [];
// // //   List<SalonService> selectedServices = [];
// // //
// // //   // États de chargement
// // //   bool isLoading = false;
// // //   String? errorMessage;
// // //   int? categorieSelectionnee;
// // //   TextEditingController searchController = TextEditingController();
// // //   String searchQuery = '';
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _chargerDonnees();
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     searchController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   /// Charger toutes les données du salon en un seul appel
// // //   Future<void> _chargerDonnees() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       errorMessage = null;
// // //     });
// // //
// // //     try {
// // //       print("🚀 Chargement des services pour le salon: ${widget.salon.nom}");
// // //
// // //       // UN SEUL APPEL API ! 🎯
// // //       final data = await ServicesApiService.chargerServicesParCategoriePourSalon(
// // //           widget.salon.proprietaire!.idTblUser, // ID du salon directement
// // //       );
// // //
// // //       final servicesByCategory = data['services_by_category'] as List;
// // //
// // //       // Conversion avec le nouveau modèle
// // //       final categoriesConverties = servicesByCategory
// // //           .map((categoryJson) => SalonServiceCategory.fromJson(categoryJson))
// // //           .where((category) => category.hasServices) // Ne garder que les catégories avec services
// // //           .toList();
// // //
// // //       setState(() {
// // //         categories = categoriesConverties;
// // //
// // //         // Sélectionner la première catégorie si disponible
// // //         if (categories.isNotEmpty) {
// // //           categorieSelectionnee = categories.first.categoryId;
// // //         }
// // //       });
// // //
// // //       final totalServices = categories.fold<int>(0, (sum, cat) => sum + cat.serviceCount);
// // //       print("✅ $totalServices services chargés en ${categories.length} catégories");
// // //
// // //     } catch (e) {
// // //       setState(() {
// // //         errorMessage = e.toString();
// // //       });
// // //       print("❌ Erreur chargement: $e");
// // //     } finally {
// // //       setState(() => isLoading = false);
// // //     }
// // //   }
// // //
// // //   /// Récupérer la catégorie sélectionnée
// // //   SalonServiceCategory? _getCategorieSelectionnee() {
// // //     if (categorieSelectionnee == null) return null;
// // //     try {
// // //       return categories.firstWhere(
// // //             (cat) => cat.categoryId == categorieSelectionnee,
// // //       );
// // //     } catch (e) {
// // //       return null;
// // //     }
// // //   }
// // //
// // //   /// Filtrer les services selon la recherche
// // //   List<SalonService> _getServicesFiltered() {
// // //     final categorieActive = _getCategorieSelectionnee();
// // //     if (categorieActive == null) return [];
// // //
// // //     if (searchQuery.isEmpty) return categorieActive.services;
// // //
// // //     return categorieActive.services.where((service) =>
// // //     service.intituleService.toLowerCase().contains(searchQuery.toLowerCase()) ||
// // //         service.description.toLowerCase().contains(searchQuery.toLowerCase())
// // //     ).toList();
// // //   }
// // //
// // //   void _toggleServiceSelection(SalonService service) {
// // //     setState(() {
// // //       if (selectedServices.any((s) => s.idTblService == service.idTblService)) {
// // //         selectedServices.removeWhere((s) => s.idTblService == service.idTblService);
// // //       } else {
// // //         selectedServices.add(service);
// // //       }
// // //     });
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return DraggableScrollableSheet(
// // //       initialChildSize: 0.9,
// // //       minChildSize: 0.5,
// // //       maxChildSize: 0.95,
// // //       builder: (context, scrollController) {
// // //         return Container(
// // //           decoration: BoxDecoration(
// // //             color: const Color(0xFFF7F7F9),
// // //             borderRadius: BorderRadius.only(
// // //               topLeft: Radius.circular(20),
// // //               topRight: Radius.circular(20),
// // //             ),
// // //           ),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               // Poignée du modal
// // //               Container(
// // //                 width: 40,
// // //                 height: 5,
// // //                 margin: EdgeInsets.only(top: 15, bottom: 10),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.grey[300],
// // //                   borderRadius: BorderRadius.circular(10),
// // //                 ),
// // //               ),
// // //
// // //               // En-tête
// // //               _construireEntete(),
// // //
// // //               // Corps du modal
// // //               Expanded(
// // //                 child: _construireCorps(scrollController),
// // //               ),
// // //
// // //               // Boutons d'action en bas
// // //               if (selectedServices.isNotEmpty)
// // //                 _construireBarreInferieure(),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _construireEntete() {
// // //     final totalServices = categories.fold<int>(0, (sum, cat) => sum + cat.serviceCount);
// // //
// // //     return Container(
// // //       padding: const EdgeInsets.all(20),
// // //       decoration: BoxDecoration(
// // //         color: widget.primaryColor,
// // //         borderRadius: BorderRadius.only(
// // //           topLeft: Radius.circular(20),
// // //           topRight: Radius.circular(20),
// // //         ),
// // //       ),
// // //       child: Column(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Row(
// // //             children: [
// // //               Expanded(
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   mainAxisSize: MainAxisSize.min,
// // //                   children: [
// // //                     Text(
// // //                       "Services disponibles",
// // //                       style: TextStyle(
// // //                         fontSize: 20,
// // //                         fontWeight: FontWeight.bold,
// // //                         color: Colors.white,
// // //                       ),
// // //                     ),
// // //                     Text(
// // //                       "${widget.salon.nom} • $totalServices services",
// // //                       style: TextStyle(
// // //                         fontSize: 14,
// // //                         fontWeight: FontWeight.normal,
// // //                         color: Colors.white70,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               IconButton(
// // //                 onPressed: () => Navigator.of(context).pop(),
// // //                 icon: Icon(Icons.close, color: Colors.white),
// // //               ),
// // //             ],
// // //           ),
// // //           if (selectedServices.isNotEmpty) ...[
// // //             SizedBox(height: 16),
// // //             Container(
// // //               padding: EdgeInsets.all(12),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white.withOpacity(0.2),
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               child: Row(
// // //                 children: [
// // //                   Icon(Icons.shopping_cart, color: Colors.white, size: 20),
// // //                   SizedBox(width: 8),
// // //                   Expanded(
// // //                     child: Text(
// // //                       "${selectedServices.length} service(s) sélectionné(s)",
// // //                       style: TextStyle(
// // //                         color: Colors.white,
// // //                         fontWeight: FontWeight.w500,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   Text(
// // //                     _getTotalPrixSelectionnees(),
// // //                     style: TextStyle(
// // //                       color: Colors.white,
// // //                       fontWeight: FontWeight.bold,
// // //                       fontSize: 16,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ],
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   String _getTotalPrixSelectionnees() {
// // //     if (selectedServices.isEmpty) return "";
// // //     final total = selectedServices.fold<double>(0, (sum, service) => sum + service.prix);
// // //     return "${total.toStringAsFixed(0)}€";
// // //   }
// // //
// // //   Widget _construireCorps([ScrollController? scrollController]) {
// // //     if (isLoading) {
// // //       return Center(
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             CircularProgressIndicator(color: widget.primaryColor),
// // //             SizedBox(height: 16),
// // //             Text("Chargement des services..."),
// // //           ],
// // //         ),
// // //       );
// // //     }
// // //
// // //     if (errorMessage != null) {
// // //       return Center(
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
// // //             SizedBox(height: 16),
// // //             Text("Erreur de chargement",
// // //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // //             SizedBox(height: 8),
// // //             Padding(
// // //               padding: EdgeInsets.symmetric(horizontal: 32),
// // //               child: Text(errorMessage!, textAlign: TextAlign.center,
// // //                   style: TextStyle(color: Colors.grey.shade600)),
// // //             ),
// // //             SizedBox(height: 24),
// // //             ElevatedButton.icon(
// // //               onPressed: _chargerDonnees,
// // //               icon: Icon(Icons.refresh),
// // //               label: Text("Réessayer"),
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: widget.primaryColor,
// // //                 foregroundColor: Colors.white,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //     }
// // //
// // //     if (categories.isEmpty) {
// // //       return Center(
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             Icon(Icons.spa, size: 64, color: Colors.grey.shade300),
// // //             SizedBox(height: 16),
// // //             Text("Aucun service disponible",
// // //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // //             SizedBox(height: 8),
// // //             Text("Ce salon n'a pas encore configuré ses services",
// // //                 style: TextStyle(color: Colors.grey.shade600)),
// // //           ],
// // //         ),
// // //       );
// // //     }
// // //
// // //     return Column(
// // //       mainAxisSize: MainAxisSize.min,
// // //       children: [
// // //         // Sélecteur de catégories
// // //         _construireSelecteurCategories(),
// // //
// // //         // Zone des services
// // //         Expanded(child: _construireZoneServices(scrollController)),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _construireSelecteurCategories() {
// // //     return Container(
// // //       padding: const EdgeInsets.all(16),
// // //       child: Wrap(
// // //         spacing: 8,
// // //         runSpacing: 8,
// // //         alignment: WrapAlignment.start,
// // //         children: categories.map((categorie) {
// // //           final estActive = categorieSelectionnee == categorie.categoryId;
// // //           final couleurCategorie = _getCouleurCategorie(categories.indexOf(categorie));
// // //
// // //           return GestureDetector(
// // //             onTap: () {
// // //               setState(() {
// // //                 categorieSelectionnee = categorie.categoryId;
// // //                 searchQuery = '';
// // //                 searchController.clear();
// // //               });
// // //             },
// // //             child: AnimatedContainer(
// // //               duration: const Duration(milliseconds: 250),
// // //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // //               decoration: BoxDecoration(
// // //                 color: estActive ? couleurCategorie : Colors.white,
// // //                 borderRadius: BorderRadius.circular(18),
// // //                 border: Border.all(color: couleurCategorie, width: 1.5),
// // //                 boxShadow: estActive ? [
// // //                   BoxShadow(
// // //                     color: couleurCategorie.withOpacity(0.25),
// // //                     blurRadius: 6,
// // //                     offset: const Offset(0, 2),
// // //                   ),
// // //                 ] : [],
// // //               ),
// // //               child: Row(
// // //                 mainAxisSize: MainAxisSize.min,
// // //                 children: [
// // //                   Icon(
// // //                     _getIconeCategorie(categorie.categoryName),
// // //                     color: estActive ? Colors.white : couleurCategorie,
// // //                     size: 16,
// // //                   ),
// // //                   const SizedBox(width: 6),
// // //                   Text(
// // //                     categorie.categoryName,
// // //                     style: TextStyle(
// // //                       fontSize: 11,
// // //                       fontWeight: FontWeight.w600,
// // //                       color: estActive ? Colors.white : couleurCategorie,
// // //                     ),
// // //                   ),
// // //                   if (estActive) ...[
// // //                     const SizedBox(width: 4),
// // //                     Container(
// // //                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
// // //                       decoration: BoxDecoration(
// // //                         color: Colors.white.withOpacity(0.3),
// // //                         borderRadius: BorderRadius.circular(6),
// // //                       ),
// // //                       child: Text(
// // //                         "${categorie.serviceCount}",
// // //                         style: const TextStyle(
// // //                           fontSize: 8,
// // //                           color: Colors.white,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ],
// // //               ),
// // //             ),
// // //           );
// // //         }).toList(),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _construireZoneServices([ScrollController? scrollController]) {
// // //     final categorieActive = _getCategorieSelectionnee();
// // //     if (categorieActive == null) {
// // //       return Center(child: Text("Sélectionnez une catégorie"));
// // //     }
// // //
// // //     final servicesFiltered = _getServicesFiltered();
// // //
// // //     return Column(
// // //       mainAxisSize: MainAxisSize.min,
// // //       children: [
// // //         // En-tête de catégorie avec recherche
// // //         Container(
// // //           padding: const EdgeInsets.all(16),
// // //           color: Colors.white,
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Row(
// // //                 children: [
// // //                   Container(
// // //                     padding: const EdgeInsets.all(8),
// // //                     decoration: BoxDecoration(
// // //                       color: widget.primaryColor.withOpacity(0.1),
// // //                       borderRadius: BorderRadius.circular(8),
// // //                     ),
// // //                     child: Icon(
// // //                       _getIconeCategorie(categorieActive.categoryName),
// // //                       color: widget.primaryColor,
// // //                       size: 20,
// // //                     ),
// // //                   ),
// // //                   SizedBox(width: 12),
// // //                   Expanded(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       mainAxisSize: MainAxisSize.min,
// // //                       children: [
// // //                         Text(categorieActive.categoryName,
// // //                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // //                         if (categorieActive.serviceCount > 0)
// // //                           Text("${categorieActive.serviceCount} service(s) • ${categorieActive.prixMinimum.toStringAsFixed(0)}€ - ${categorieActive.prixMaximum.toStringAsFixed(0)}€",
// // //                               style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //               SizedBox(height: 16),
// // //               TextField(
// // //                 controller: searchController,
// // //                 decoration: InputDecoration(
// // //                   hintText: "Rechercher un service...",
// // //                   prefixIcon: Icon(Icons.search),
// // //                   suffixIcon: searchQuery.isNotEmpty
// // //                       ? IconButton(
// // //                     icon: Icon(Icons.clear),
// // //                     onPressed: () {
// // //                       setState(() {
// // //                         searchController.clear();
// // //                         searchQuery = '';
// // //                       });
// // //                     },
// // //                   )
// // //                       : null,
// // //                   border: OutlineInputBorder(
// // //                     borderRadius: BorderRadius.circular(12),
// // //                     borderSide: BorderSide(color: Colors.grey.shade300),
// // //                   ),
// // //                   focusedBorder: OutlineInputBorder(
// // //                     borderRadius: BorderRadius.circular(12),
// // //                     borderSide: BorderSide(color: widget.primaryColor),
// // //                   ),
// // //                   filled: true,
// // //                   fillColor: Colors.grey.shade50,
// // //                 ),
// // //                 onChanged: (value) {
// // //                   setState(() {
// // //                     searchQuery = value;
// // //                   });
// // //                 },
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //
// // //         // Liste des services
// // //         Expanded(
// // //           child: servicesFiltered.isEmpty
// // //               ? _construireEtatVide(categorieActive)
// // //               : ListView.builder(
// // //             controller: scrollController,
// // //             padding: const EdgeInsets.all(16),
// // //             itemCount: servicesFiltered.length,
// // //             itemBuilder: (context, index) => _construireCarteService(servicesFiltered[index]),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _construireEtatVide(SalonServiceCategory categorie) {
// // //     final bool isSearching = searchQuery.isNotEmpty;
// // //
// // //     return Center(
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(32),
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             Icon(
// // //               isSearching ? Icons.search_off : Icons.inbox_outlined,
// // //               size: 64,
// // //               color: Colors.grey.shade300,
// // //             ),
// // //             SizedBox(height: 16),
// // //             Text(
// // //               isSearching
// // //                   ? "Aucun service trouvé pour \"$searchQuery\""
// // //                   : "Aucun service dans cette catégorie",
// // //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
// // //               textAlign: TextAlign.center,
// // //             ),
// // //             SizedBox(height: 8),
// // //             Text(
// // //               isSearching
// // //                   ? "Essayez avec d'autres mots-clés"
// // //                   : "Ce salon n'a pas encore ajouté de services dans cette catégorie",
// // //               style: TextStyle(color: Colors.grey.shade600),
// // //               textAlign: TextAlign.center,
// // //             ),
// // //             if (isSearching) ...[
// // //               SizedBox(height: 24),
// // //               TextButton.icon(
// // //                 onPressed: () {
// // //                   setState(() {
// // //                     searchController.clear();
// // //                     searchQuery = '';
// // //                   });
// // //                 },
// // //                 icon: Icon(Icons.clear),
// // //                 label: Text("Effacer la recherche"),
// // //               ),
// // //             ],
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _construireCarteService(SalonService service) {
// // //     final estSelectionne = selectedServices.any((s) => s.idTblService == service.idTblService);
// // //
// // //     return Container(
// // //       margin: const EdgeInsets.only(bottom: 16),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(16),
// // //         border: Border.all(
// // //           color: estSelectionne ? widget.primaryColor : Colors.grey.shade200,
// // //           width: estSelectionne ? 2 : 1,
// // //         ),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: estSelectionne
// // //                 ? widget.primaryColor.withOpacity(0.1)
// // //                 : Colors.black.withOpacity(0.05),
// // //             blurRadius: estSelectionne ? 12 : 6,
// // //             spreadRadius: estSelectionne ? 2 : 1,
// // //           ),
// // //         ],
// // //       ),
// // //       child: Stack(
// // //         children: [
// // //           // ✅ Badge promotion en haut à droite
// // //           if (service.hasPromotion)
// // //             Positioned(
// // //               top: 12,
// // //               right: 12,
// // //               child: Container(
// // //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.red,
// // //                   borderRadius: BorderRadius.circular(12),
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: Colors.red.withOpacity(0.3),
// // //                       blurRadius: 4,
// // //                       offset: Offset(0, 2),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 child: Text(
// // //                   service.promotion!.pourcentageFormate,
// // //                   style: TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 10,
// // //                     fontWeight: FontWeight.bold,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //
// // //           Material(
// // //             color: Colors.transparent,
// // //             borderRadius: BorderRadius.circular(16),
// // //             child: InkWell(
// // //               onTap: () => _toggleServiceSelection(service),
// // //               borderRadius: BorderRadius.circular(16),
// // //               child: Padding(
// // //                 padding: const EdgeInsets.all(20),
// // //                 child: Row(
// // //                   children: [
// // //                     // Checkbox
// // //                     AnimatedContainer(
// // //                       duration: const Duration(milliseconds: 200),
// // //                       width: 24,
// // //                       height: 24,
// // //                       decoration: BoxDecoration(
// // //                         color: estSelectionne ? widget.primaryColor : Colors.transparent,
// // //                         border: Border.all(
// // //                           color: estSelectionne ? widget.primaryColor : Colors.grey.shade400,
// // //                           width: 2,
// // //                         ),
// // //                         borderRadius: BorderRadius.circular(6),
// // //                       ),
// // //                       child: estSelectionne
// // //                           ? Icon(Icons.check, color: Colors.white, size: 16)
// // //                           : null,
// // //                     ),
// // //
// // //                     SizedBox(width: 16),
// // //
// // //                     // Informations du service
// // //                     Expanded(
// // //                       child: Column(
// // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // //                         children: [
// // //                           Text(
// // //                             service.intituleService,
// // //                             style: TextStyle(
// // //                               fontSize: 18,
// // //                               fontWeight: FontWeight.bold,
// // //                               color: estSelectionne ? widget.primaryColor : Color(0xFF333333),
// // //                             ),
// // //                           ),
// // //                           SizedBox(height: 6),
// // //                           Text(
// // //                             service.description,
// // //                             style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
// // //                             maxLines: 2,
// // //                             overflow: TextOverflow.ellipsis,
// // //                           ),
// // //                           SizedBox(height: 12),
// // //
// // //                           // ✅ Prix avec gestion des promotions
// // //                           Row(
// // //                             children: [
// // //                               // Prix principal (avec ou sans promotion)
// // //                               if (service.hasPromotion) ...[
// // //                                 // Prix barré (prix original)
// // //                                 Container(
// // //                                   padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// // //                                   child: Text(
// // //                                     service.prixFormate,
// // //                                     style: TextStyle(
// // //                                       fontSize: 11,
// // //                                       color: Colors.grey.shade500,
// // //                                       decoration: TextDecoration.lineThrough,
// // //                                     ),
// // //                                   ),
// // //                                 ),
// // //                                 SizedBox(width: 4),
// // //                                 // Prix promotionnel
// // //                                 Container(
// // //                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                                   decoration: BoxDecoration(
// // //                                     color: Colors.red.withOpacity(0.1),
// // //                                     borderRadius: BorderRadius.circular(12),
// // //                                   ),
// // //                                   child: Text(
// // //                                     service.prixFinalFormate,
// // //                                     style: TextStyle(
// // //                                       fontSize: 12,
// // //                                       fontWeight: FontWeight.w600,
// // //                                       color: Colors.red,
// // //                                     ),
// // //                                   ),
// // //                                 ),
// // //                               ] else ...[
// // //                                 // Prix normal (sans promotion)
// // //                                 Container(
// // //                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                                   decoration: BoxDecoration(
// // //                                     color: widget.accentColor.withOpacity(0.1),
// // //                                     borderRadius: BorderRadius.circular(12),
// // //                                   ),
// // //                                   child: Text(
// // //                                     service.prixFinalFormate,
// // //                                     style: TextStyle(
// // //                                       fontSize: 12,
// // //                                       fontWeight: FontWeight.w600,
// // //                                       color: widget.accentColor,
// // //                                     ),
// // //                                   ),
// // //                                 ),
// // //                               ],
// // //
// // //                               SizedBox(width: 8),
// // //
// // //                               // Durée
// // //                               Container(
// // //                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                                 decoration: BoxDecoration(
// // //                                   color: Colors.blue.withOpacity(0.1),
// // //                                   borderRadius: BorderRadius.circular(12),
// // //                                 ),
// // //                                 child: Text(
// // //                                   service.dureeFormatee,
// // //                                   style: TextStyle(
// // //                                     fontSize: 12,
// // //                                     fontWeight: FontWeight.w600,
// // //                                     color: Colors.blue,
// // //                                   ),
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //
// // //                           // ✅ Affichage des économies si promotion
// // //                           if (service.hasPromotion) ...[
// // //                             SizedBox(height: 8),
// // //                             Container(
// // //                               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                               decoration: BoxDecoration(
// // //                                 color: Colors.green.withOpacity(0.1),
// // //                                 borderRadius: BorderRadius.circular(8),
// // //                               ),
// // //                               child: Row(
// // //                                 mainAxisSize: MainAxisSize.min,
// // //                                 children: [
// // //                                   Icon(Icons.savings, color: Colors.green, size: 12),
// // //                                   SizedBox(width: 4),
// // //                                   Text(
// // //                                     service.promotion!.economieFormatee,
// // //                                     style: TextStyle(
// // //                                       fontSize: 10,
// // //                                       fontWeight: FontWeight.w600,
// // //                                       color: Colors.green,
// // //                                     ),
// // //                                   ),
// // //                                 ],
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ],
// // //                       ),
// // //                     ),
// // //
// // //                     // Icône de sélection
// // //                     if (estSelectionne)
// // //                       Container(
// // //                         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                         decoration: BoxDecoration(
// // //                           color: widget.primaryColor.withOpacity(0.1),
// // //                           borderRadius: BorderRadius.circular(12),
// // //                         ),
// // //                         child: Text(
// // //                           "Sélectionné",
// // //                           style: TextStyle(
// // //                             fontSize: 10,
// // //                             fontWeight: FontWeight.w600,
// // //                             color: widget.primaryColor,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Widget _construireCarteService(SalonService service) {
// // //   //   final estSelectionne = selectedServices.any((s) => s.idTblService == service.idTblService);
// // //   //
// // //   //   return Container(
// // //   //     margin: const EdgeInsets.only(bottom: 16),
// // //   //     decoration: BoxDecoration(
// // //   //       color: Colors.white,
// // //   //       borderRadius: BorderRadius.circular(16),
// // //   //       border: Border.all(
// // //   //         color: estSelectionne ? widget.primaryColor : Colors.grey.shade200,
// // //   //         width: estSelectionne ? 2 : 1,
// // //   //       ),
// // //   //       boxShadow: [
// // //   //         BoxShadow(
// // //   //           color: estSelectionne
// // //   //               ? widget.primaryColor.withOpacity(0.1)
// // //   //               : Colors.black.withOpacity(0.05),
// // //   //           blurRadius: estSelectionne ? 12 : 6,
// // //   //           spreadRadius: estSelectionne ? 2 : 1,
// // //   //         ),
// // //   //       ],
// // //   //     ),
// // //   //     child: Material(
// // //   //       color: Colors.transparent,
// // //   //       borderRadius: BorderRadius.circular(16),
// // //   //       child: InkWell(
// // //   //         onTap: () => _toggleServiceSelection(service),
// // //   //         borderRadius: BorderRadius.circular(16),
// // //   //         child: Padding(
// // //   //           padding: const EdgeInsets.all(20),
// // //   //           child: Row(
// // //   //             children: [
// // //   //               // Checkbox
// // //   //               AnimatedContainer(
// // //   //                 duration: const Duration(milliseconds: 200),
// // //   //                 width: 24,
// // //   //                 height: 24,
// // //   //                 decoration: BoxDecoration(
// // //   //                   color: estSelectionne ? widget.primaryColor : Colors.transparent,
// // //   //                   border: Border.all(
// // //   //                     color: estSelectionne ? widget.primaryColor : Colors.grey.shade400,
// // //   //                     width: 2,
// // //   //                   ),
// // //   //                   borderRadius: BorderRadius.circular(6),
// // //   //                 ),
// // //   //                 child: estSelectionne
// // //   //                     ? Icon(Icons.check, color: Colors.white, size: 16)
// // //   //                     : null,
// // //   //               ),
// // //   //
// // //   //               SizedBox(width: 16),
// // //   //
// // //   //               // Informations du service
// // //   //               Expanded(
// // //   //                 child: Column(
// // //   //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //   //                   children: [
// // //   //                     Text(
// // //   //                       service.intituleService,
// // //   //                       style: TextStyle(
// // //   //                         fontSize: 18,
// // //   //                         fontWeight: FontWeight.bold,
// // //   //                         color: estSelectionne ? widget.primaryColor : Color(0xFF333333),
// // //   //                       ),
// // //   //                     ),
// // //   //                     SizedBox(height: 6),
// // //   //                     Text(
// // //   //                       service.description,
// // //   //                       style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
// // //   //                       maxLines: 2,
// // //   //                       overflow: TextOverflow.ellipsis,
// // //   //                     ),
// // //   //                     SizedBox(height: 12),
// // //   //
// // //   //                     // Prix et durée RÉELS du salon ! 🎯
// // //   //                     Row(
// // //   //                       children: [
// // //   //                         Container(
// // //   //                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //   //                           decoration: BoxDecoration(
// // //   //                             color: widget.accentColor.withOpacity(0.1),
// // //   //                             borderRadius: BorderRadius.circular(12),
// // //   //                           ),
// // //   //                           child: Text(
// // //   //                             service.prixFormate,
// // //   //                             style: TextStyle(
// // //   //                               fontSize: 12,
// // //   //                               fontWeight: FontWeight.w600,
// // //   //                               color: widget.accentColor,
// // //   //                             ),
// // //   //                           ),
// // //   //                         ),
// // //   //                         SizedBox(width: 8),
// // //   //                         Container(
// // //   //                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //   //                           decoration: BoxDecoration(
// // //   //                             color: Colors.blue.withOpacity(0.1),
// // //   //                             borderRadius: BorderRadius.circular(12),
// // //   //                           ),
// // //   //                           child: Text(
// // //   //                             service.dureeFormatee,
// // //   //                             style: TextStyle(
// // //   //                               fontSize: 12,
// // //   //                               fontWeight: FontWeight.w600,
// // //   //                               color: Colors.blue,
// // //   //                             ),
// // //   //                           ),
// // //   //                         ),
// // //   //                       ],
// // //   //                     ),
// // //   //                   ],
// // //   //                 ),
// // //   //               ),
// // //   //
// // //   //               // Icône de sélection
// // //   //               if (estSelectionne)
// // //   //                 Container(
// // //   //                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //   //                   decoration: BoxDecoration(
// // //   //                     color: widget.primaryColor.withOpacity(0.1),
// // //   //                     borderRadius: BorderRadius.circular(12),
// // //   //                   ),
// // //   //                   child: Text(
// // //   //                     "Sélectionné",
// // //   //                     style: TextStyle(
// // //   //                       fontSize: 10,
// // //   //                       fontWeight: FontWeight.w600,
// // //   //                       color: widget.primaryColor,
// // //   //                     ),
// // //   //                   ),
// // //   //                 ),
// // //   //             ],
// // //   //           ),
// // //   //         ),
// // //   //       ),
// // //   //     ),
// // //   //   );
// // //   // }
// // //
// // //   Widget _construireBarreInferieure() {
// // //     return Container(
// // //       padding: const EdgeInsets.all(16),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.1),
// // //             blurRadius: 10,
// // //             spreadRadius: 1,
// // //           ),
// // //         ],
// // //       ),
// // //       child: SafeArea(
// // //         child: Row(
// // //           children: [
// // //             Expanded(
// // //               child: OutlinedButton.icon(
// // //                 onPressed: () {
// // //                   setState(() {
// // //                     selectedServices.clear();
// // //                   });
// // //                 },
// // //                 icon: Icon(Icons.clear_all),
// // //                 label: Text("Effacer"),
// // //                 style: OutlinedButton.styleFrom(
// // //                   foregroundColor: Colors.grey,
// // //                   side: BorderSide(color: Colors.grey),
// // //                   padding: EdgeInsets.symmetric(vertical: 16),
// // //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //                 ),
// // //               ),
// // //             ),
// // //             SizedBox(width: 12),
// // //             Expanded(
// // //               flex: 2,
// // //               child: ElevatedButton.icon(
// // //                 onPressed: () {
// // //                   // Retourner les services sélectionnés convertis en Service si nécessaire
// // //
// // //
// // //                   final servicesForCompatibility = selectedServices.map((s) => s.toService()).toList();
// // //                   Navigator.of(context).pop(servicesForCompatibility);
// // //                 },
// // //                 icon: Icon(Icons.shopping_cart),
// // //                 label: Text("Ajouter (${selectedServices.length}) • ${_getTotalPrixSelectionnees()}"),
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: widget.primaryColor,
// // //                   foregroundColor: Colors.white,
// // //                   padding: EdgeInsets.symmetric(vertical: 16),
// // //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //                   elevation: 4,
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Méthode helper pour obtenir des couleurs uniques par catégorie
// // //   Color _getCouleurCategorie(int index) {
// // //     final couleurs = [
// // //       const Color(0xFF7B61FF), // Violet
// // //       const Color(0xFFE67E22), // Orange
// // //       const Color(0xFF2ECC71), // Vert
// // //       const Color(0xFFE74C3C), // Rouge
// // //       const Color(0xFF3498DB), // Bleu
// // //       const Color(0xFF9B59B6), // Violet foncé
// // //       const Color(0xFF1ABC9C), // Turquoise
// // //       const Color(0xFFF39C12), // Jaune orangé
// // //     ];
// // //     return couleurs[index % couleurs.length];
// // //   }
// // //
// // //   // Obtenir l'icône appropriée pour chaque catégorie
// // //   IconData _getIconeCategorie(String nomCategorie) {
// // //     switch (nomCategorie.toLowerCase()) {
// // //       case 'coiffure':
// // //       case 'cheveux':
// // //         return Icons.content_cut;
// // //       case 'esthétique':
// // //       case 'beauté':
// // //       case 'soin':
// // //         return Icons.spa;
// // //       case 'manucure':
// // //       case 'ongles':
// // //         return Icons.back_hand;
// // //       case 'massage':
// // //         return Icons.healing;
// // //       case 'maquillage':
// // //         return Icons.brush;
// // //       case 'barbier':
// // //       case 'homme':
// // //         return Icons.face_retouching_natural;
// // //       case 'lissage & défrisage':
// // //       case 'lissage':
// // //         return Icons.straighten;
// // //       case 'mèches & balayage':
// // //       case 'mèches':
// // //         return Icons.brush;
// // //       case 'autre':
// // //         return Icons.miscellaneous_services;
// // //       default:
// // //         return Icons.star;
// // //     }
// // //   }
// // // }