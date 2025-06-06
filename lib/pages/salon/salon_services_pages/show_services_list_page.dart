import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/page_size_selector.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/pagination_controls.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/search_field.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/create_promotion_modal.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/edit_service_modal.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/show_service_details_modal.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/service_with_promo.dart';
import '../../../services/providers/current_user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/bottom_nav_bar.dart';
import 'services_pages_services/modals/add_service_modal.dart';
import 'services_pages_services/services/add_to_cart_service.dart';
import 'services_pages_services/services/delete_service.dart';

class ServicesListPage extends StatefulWidget {
  final String coiffeuseId;
  const ServicesListPage({super.key, required this.coiffeuseId});

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  List<ServiceWithPromo> services = []; // Type modifié
  List<ServiceWithPromo> filteredServices = []; // Type modifié
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool hasError = false;
  late CurrentUser currentUser;
  late String currentUserId;
  int _currentIndex = 0;
  int currentPage = 1;
  int pageSize = 5; // Configurable page size
  int totalServices = 0;
  String? nextPageUrl;
  String? previousPageUrl;

  bool isLoadingMore = false;
  bool hasMore = true;

  // Option: Choose only one pagination approach
  bool useInfiniteScroll = false; // Set to false to disable infinite scroll

  final Color primaryViolet = const Color(0xFF7B61FF);

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchServices();
    _searchController.addListener(() => _filterServices(_searchController.text));
  }

  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    setState(() {
      currentUser = currentUserProvider.currentUser!;
      currentUserId = currentUser.idTblUser.toString();
    });
  }

  Future<void> _fetchServices({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        hasError = false;
        if (!loadMore) {
          // Only reset services when loading a new page
          services.clear();
          filteredServices.clear();
        }
      });
    }

    try {
      final url = Uri.parse(
        'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        // Extract pagination info if available
        if (responseData.containsKey('count')) {
          setState(() {
            totalServices = responseData['count'];
            nextPageUrl = responseData['next'];
            previousPageUrl = responseData['previous'];
          });
        }

        // Extract services based on response structure
        final serviceList = responseData.containsKey('results')
            ? responseData['results']['salon']['services']
            : responseData['salon']['services'];

        final List<ServiceWithPromo> fetched = (serviceList as List)
            .map((json) => ServiceWithPromo.fromJson(json))
            .whereType<ServiceWithPromo>()
            .toList();

        setState(() {
          if (loadMore) {
            services.addAll(fetched);
          } else {
            services = fetched;
          }
          filteredServices = List.from(services);
          // Determine if there are more pages based on nextPageUrl
          hasMore = nextPageUrl != null;
        });
      } else {
        _showError("Erreur serveur: Code ${response.statusCode}");
      }
    } catch (e) {
      _showError("Erreur de connexion au serveur : $e");
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _filterServices(String query) {
    setState(() {
      filteredServices = services.where((serviceWithPromo) {
        final titre = serviceWithPromo.intitule.toLowerCase();
        final desc = (serviceWithPromo.description).toLowerCase();
        return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Fixed navigation to next page
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

  // Fixed navigation to previous page
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

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId == widget.coiffeuseId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
      floatingActionButton: isOwner
          ? FloatingActionButton(
        backgroundColor: primaryViolet,
        child: const Icon(Icons.add),
        onPressed: () {
          showAddServiceModal(
            context,
            widget.coiffeuseId,
            _fetchServices,
          );
        },
      )
          : null,

      body: Column(
        children: [
          // Search and page size selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SearchField(controller: _searchController),
                const SizedBox(width: 8),
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
          ),

          // Pagination info
          if (totalServices > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total: $totalServices services",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    "Page $currentPage/${(totalServices / pageSize).ceil()}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? Center(child: ElevatedButton(onPressed: () => _fetchServices(), child: const Text("Réessayer")))
                : services.isEmpty
                ? const Center(child: Text("Aucun service trouvé."))
                : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Only use infinite scroll if the flag is enabled
                if (useInfiniteScroll &&
                    !isLoadingMore &&
                    hasMore &&
                    scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  // Only load more if we're at the bottom and there's more to load
                  setState(() {
                    currentPage++; // Increment page counter before loading more
                  });
                  _fetchServices(loadMore: true);
                }
                return false;
              },
              child: ListView.builder(
                itemCount: filteredServices.length + (isLoadingMore ? 1 : 0),
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  if (index == filteredServices.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final serviceWithPromo = filteredServices[index];
                  final hasPromo = serviceWithPromo.promotion_active != null;

                  //final service = filteredServices[index];

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      onTap: () => showServiceDetailsModal(
                        context: context,
                        serviceWithPromo: serviceWithPromo,
                        isOwner: isOwner,
                        onEdit: () {
                          showEditServiceModal(context, serviceWithPromo, _fetchServices);
                        },
                        onAddToCart: () => addToCart(context: context, serviceWithPromo: serviceWithPromo, userId: currentUserId),
                      ),
                      // Suppression du leading qui contenait l'icône du panier
                      title: Text(
                        serviceWithPromo.intitule,
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: primaryViolet),
                          const SizedBox(width: 4),
                          Text("${serviceWithPromo.temps} min", style: TextStyle(color: primaryViolet)),
                          const SizedBox(width: 16),
                          Icon(Icons.euro, size: 18, color: primaryViolet),
                          const SizedBox(width: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: hasPromo
                                ? Row(
                              key: ValueKey("promo_${serviceWithPromo.id}"),
                              children: [
                                Text("${serviceWithPromo.prix}€ ",
                                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
                                const SizedBox(width: 4),
                                Text("${serviceWithPromo.prix_final}€ 🔥",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            )
                                : Text("${serviceWithPromo.prix}€",
                                key: ValueKey("normal_${serviceWithPromo.id}"), style: TextStyle(color: primaryViolet)),
                          ),
                        ],
                      ),
                      trailing: isOwner
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.local_offer, color: Colors.purple),
                            onPressed: () => showCreatePromotionModal(
                              context: context,
                              serviceId: serviceWithPromo.id,
                              onPromoAdded: _fetchServices,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              debugPrint("Edit service button pressed for service ID: ${serviceWithPromo.id} from show_service_list_page.dart");
                              showEditServiceModal(context, serviceWithPromo, _fetchServices);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteService(
                              serviceWithPromo.id,
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
                          : GestureDetector(
                        onTap: () {
                          debugPrint("🛒 addToCart() called for service from show_service_list_page.dart : "
                              "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                          addToCart(
                            context: context,
                            serviceWithPromo: serviceWithPromo,
                            userId: currentUserId,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange, // Couleur plus visible pour l'icône du panier
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  );

                  // return Card(
                  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  //   margin: const EdgeInsets.symmetric(vertical: 8),
                  //   elevation: 2,
                  //   child: ListTile(
                  //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  //     onTap: () => showServiceDetailsModal(
                  //       context: context,
                  //       serviceWithPromo: serviceWithPromo,
                  //       isOwner: isOwner,
                  //       onEdit: () {
                  //         showEditServiceModal(context, serviceWithPromo, _fetchServices);
                  //       },
                  //       onAddToCart: () => addToCart(context: context, serviceWithPromo: serviceWithPromo, userId: currentUserId),
                  //     ),
                  //     leading: GestureDetector(
                  //       onTap: () {
                  //         debugPrint("🛒 addToCart() called for service from show_service_list_page.dart : "
                  //             "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                  //         addToCart(
                  //           context: context,
                  //           serviceWithPromo: serviceWithPromo,
                  //           userId: currentUserId,
                  //         );
                  //       },
                  //       child: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
                  //     ),
                  //     title: Text(
                  //       serviceWithPromo.intitule,
                  //       style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
                  //     ),
                  //     subtitle: Row(
                  //       children: [
                  //         Icon(Icons.access_time, size: 18, color: primaryViolet),
                  //         const SizedBox(width: 4),
                  //         Text("${serviceWithPromo.temps} min", style: TextStyle(color: primaryViolet)),
                  //         const SizedBox(width: 16),
                  //         Icon(Icons.euro, size: 18, color: primaryViolet),
                  //         const SizedBox(width: 4),
                  //         AnimatedSwitcher(
                  //           duration: const Duration(milliseconds: 300),
                  //           transitionBuilder: (Widget child, Animation<double> animation) {
                  //             return ScaleTransition(scale: animation, child: child);
                  //           },
                  //           child: hasPromo
                  //               ? Row(
                  //             key: ValueKey("promo_${serviceWithPromo.id}"),
                  //             children: [
                  //               Text("${serviceWithPromo.prix}€ ",
                  //                   style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
                  //               const SizedBox(width: 4),
                  //               Text("${serviceWithPromo.prix_final}€ 🔥",
                  //                   style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  //             ],
                  //           )
                  //               : Text("${serviceWithPromo.prix}€",
                  //               key: ValueKey("normal_${serviceWithPromo.id}"), style: TextStyle(color: primaryViolet)),
                  //         ),
                  //       ],
                  //     ),
                  //     trailing: isOwner
                  //         ? Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         IconButton(
                  //           icon: const Icon(Icons.local_offer, color: Colors.purple),
                  //           onPressed: () => showCreatePromotionModal(
                  //             context: context,
                  //             serviceId: serviceWithPromo.id,
                  //             onPromoAdded: _fetchServices,
                  //           ),
                  //         ),
                  //         IconButton(
                  //           icon: const Icon(Icons.edit, color: Colors.blue),
                  //           onPressed: () {
                  //             debugPrint("Edit service button pressed for service ID: ${serviceWithPromo.id} from show_service_list_page.dart");
                  //             showEditServiceModal(context, serviceWithPromo, _fetchServices);
                  //           },
                  //         ),
                  //         IconButton(
                  //           icon: const Icon(Icons.delete, color: Colors.red),
                  //           onPressed: () => deleteService(
                  //             serviceWithPromo.id,
                  //             context,
                  //             _showError,
                  //             setState,
                  //             services,
                  //             filteredServices,
                  //             totalServices,
                  //           ),
                  //         ),
                  //       ],
                  //     )
                  //         : null,
                  //   ),
                  // );
                },
              ),
            ),
          ),

          // Pagination Controls
          PaginationControls(
            currentPage: currentPage,
            totalItems: totalServices,
            pageSize: pageSize,
            previousPageUrl: previousPageUrl,
            nextPageUrl: nextPageUrl,
            onPrevious: _goToPreviousPage,
            onNext: _goToNextPage,
          ),
        ],
      ),
    );
  }
}