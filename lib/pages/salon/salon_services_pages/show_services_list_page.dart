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




//  import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/page_size_selector.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/pagination_controls.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/search_field.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/create_promotion_modal.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/edit_service_modal.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/show_service_details_modal.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'services_pages_services/modals/add_service_modal.dart';
// import 'services_pages_services/services/add_to_cart_service.dart';
// import 'services_pages_services/services/delete_service.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late CurrentUser currentUser;
//   late String currentUserId;
//   int _currentIndex = 0;
//   int currentPage = 1;
//   int pageSize = 5; // Configurable page size
//   int totalServices = 0;
//   String? nextPageUrl;
//   String? previousPageUrl;
//
//   bool isLoadingMore = false;
//   bool hasMore = true;
//
//   // Option: Choose only one pagination approach
//   bool useInfiniteScroll = false; // Set to false to disable infinite scroll
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUser = currentUserProvider.currentUser! ;
//       currentUserId = currentUser.idTblUser.toString();
//
//     });
//   }
//
//   Future<void> _fetchServices({bool loadMore = false}) async {
//     if (loadMore) {
//       setState(() => isLoadingMore = true);
//     } else {
//       setState(() {
//         isLoading = true;
//         hasError = false;
//         if (!loadMore) {
//           // Only reset services when loading a new page
//           services.clear();
//           filteredServices.clear();
//         }
//       });
//     }
//
//     try {
//       final url = Uri.parse(
//         'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         // Extract pagination info if available
//         if (responseData.containsKey('count')) {
//           setState(() {
//             totalServices = responseData['count'];
//             nextPageUrl = responseData['next'];
//             previousPageUrl = responseData['previous'];
//           });
//         }
//
//         // Extract services based on response structure
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> fetched = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         setState(() {
//           if (loadMore) {
//             services.addAll(fetched);
//           } else {
//             services = fetched;
//           }
//           filteredServices = List.from(services);
//           // Determine if there are more pages based on nextPageUrl
//           hasMore = nextPageUrl != null;
//
//           // Only increment page for infinite scroll if actually loading more
//           // Page number is already managed in goToNextPage for button navigation
//         });
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   // // La fonction _deleteService a été déplacée vers un fichier séparé
//   //
//   // void _ajouterAuPanier(Service service) {
//   //   Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//   //   );
//   // }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//
//   // Fixed navigation to next page
//   void _goToNextPage() {
//     if (nextPageUrl != null) {
//       setState(() {
//         currentPage++;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   // Fixed navigation to previous page
//   void _goToPreviousPage() {
//     if (previousPageUrl != null && currentPage > 1) {
//       setState(() {
//         currentPage--;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: primaryViolet,
//         child: const Icon(Icons.add),
//         onPressed: () {
//           showAddServiceModal(
//             context,
//             widget.coiffeuseId,
//             _fetchServices,
//           );
//         },
//       )
//           : null,
//
//
//       body: Column(
//         children: [
//           // Search and page size selector
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 SearchField(controller: _searchController),
//                 const SizedBox(width: 8),
//                 PageSizeSelector(
//                   currentSize: pageSize,
//                   onChanged: (newSize) {
//                     setState(() {
//                       pageSize = newSize;
//                       currentPage = 1;
//                       services.clear();
//                       filteredServices.clear();
//                     });
//                     _fetchServices();
//                   },
//                 ),
//               ],
//             ),
//           ),
//
//
//           // Pagination info
//           if (totalServices > 0)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Total: $totalServices services",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                   Text(
//                     "Page $currentPage/${(totalServices / pageSize).ceil()}",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Main content
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : hasError
//                 ? Center(child: ElevatedButton(onPressed: () => _fetchServices(), child: const Text("Réessayer")))
//                 : services.isEmpty
//                 ? const Center(child: Text("Aucun service trouvé."))
//                 : NotificationListener<ScrollNotification>(
//               onNotification: (ScrollNotification scrollInfo) {
//                 // Only use infinite scroll if the flag is enabled
//                 if (useInfiniteScroll && !isLoadingMore && hasMore &&
//                     scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//                   // Only load more if we're at the bottom and there's more to load
//                   setState(() {
//                     currentPage++;  // Increment page counter before loading more
//                   });
//                   _fetchServices(loadMore: true);
//                 }
//                 return false;
//               },
//               child: ListView.builder(
//                 itemCount: filteredServices.length + (isLoadingMore ? 1 : 0),
//                 padding: const EdgeInsets.all(12),
//                 itemBuilder: (context, index) {
//                   if (index == filteredServices.length) {
//                     return const Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: CircularProgressIndicator(),
//                       ),
//                     );
//                   }
//
//                   final service = filteredServices[index];
//                   final hasPromo = service.promotion != null;
//                   return Card(
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     elevation: 2,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       onTap: () => showServiceDetailsModal(
//                         context: context,
//                         service: service,
//                         isOwner: isOwner,
//                         onEdit: () {
//                           showEditServiceModal(context, service, _fetchServices);
//                         },
//                         onAddToCart: () => addToCart(context: context, service: service, userId: currentUserId),
//
//                       ),
//
//
//                       leading: IconButton(
//                         icon: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
//                         onPressed: () => addToCart(context: context, service: service, userId: currentUserId!)                        ,
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
//                       ),
//                       subtitle: Row(
//                         children: [
//                           Icon(Icons.access_time, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           Text("${service.temps} min", style: TextStyle(color: primaryViolet)),
//                           const SizedBox(width: 16),
//                           Icon(Icons.euro, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             transitionBuilder: (Widget child, Animation<double> animation) {
//                               return ScaleTransition(scale: animation, child: child);
//                             },
//                             child: hasPromo
//                                 ? Row(
//                               key: ValueKey("promo_${service.id}"),
//                               children: [
//                                 Text("${service.prix}€ ", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                                 const SizedBox(width: 4),
//                                 Text("${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                               ],
//                             )
//                                 : Text("${service.prix}€", key: ValueKey("normal_${service.id}"), style: TextStyle(color: primaryViolet)),
//                           ),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => showCreatePromotionModal(context: context, serviceId: service.id, onPromoAdded: _fetchServices),),
//                         IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showEditServiceModal(context, service, _fetchServices),),
//                           IconButton(icon: const Icon(Icons.delete, color: Colors.red),onPressed: () => deleteService(service.id,context,_showError,setState,services,filteredServices,totalServices
//                               )
//                           ),
//                         ],
//                       )
//                           : null,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//
//           // Pagination Controls
//           PaginationControls(
//             currentPage: currentPage,
//             totalItems: totalServices,
//             pageSize: pageSize,
//             previousPageUrl: previousPageUrl,
//             nextPageUrl: nextPageUrl,
//             onPrevious: _goToPreviousPage,
//             onNext: _goToNextPage,
//           ),
//
//         ],
//       ),
//     );
//   }
// }
//













// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/page_size_selector.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/pagination_controls.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/components/search_field.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/edit_service_modal.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/modals/show_service_details_modal.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'services_pages_services/modals/add_service_modal.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//   int currentPage = 1;
//   int pageSize = 5; // Configurable page size
//   int totalServices = 0;
//   String? nextPageUrl;
//   String? previousPageUrl;
//
//   bool isLoadingMore = false;
//   bool hasMore = true;
//
//   // Option: Choose only one pagination approach
//   bool useInfiniteScroll = false; // Set to false to disable infinite scroll
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices({bool loadMore = false}) async {
//     if (loadMore) {
//       setState(() => isLoadingMore = true);
//     } else {
//       setState(() {
//         isLoading = true;
//         hasError = false;
//         if (!loadMore) {
//           // Only reset services when loading a new page
//           services.clear();
//           filteredServices.clear();
//         }
//       });
//     }
//
//     try {
//       final url = Uri.parse(
//         'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         // Extract pagination info if available
//         if (responseData.containsKey('count')) {
//           setState(() {
//             totalServices = responseData['count'];
//             nextPageUrl = responseData['next'];
//             previousPageUrl = responseData['previous'];
//           });
//         }
//
//         // Extract services based on response structure
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> fetched = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         setState(() {
//           if (loadMore) {
//             services.addAll(fetched);
//           } else {
//             services = fetched;
//           }
//           filteredServices = List.from(services);
//           // Determine if there are more pages based on nextPageUrl
//           hasMore = nextPageUrl != null;
//
//           // Only increment page for infinite scroll if actually loading more
//           // Page number is already managed in goToNextPage for button navigation
//         });
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         setState(() {
//           services.removeWhere((s) => s.id == serviceId);
//           filteredServices.removeWhere((s) => s.id == serviceId);
//           totalServices--; // mise à jour du total
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Service supprimé avec succès ✅"), backgroundColor: Colors.green),
//         );
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: service.id),
//       ),
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   // Fixed navigation to next page
//   void _goToNextPage() {
//     if (nextPageUrl != null) {
//       setState(() {
//         currentPage++;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   // Fixed navigation to previous page
//   void _goToPreviousPage() {
//     if (previousPageUrl != null && currentPage > 1) {
//       setState(() {
//         currentPage--;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: primaryViolet,
//         child: const Icon(Icons.add),
//         onPressed: () {
//           showAddServiceModal(
//             context,
//             widget.coiffeuseId,
//             _fetchServices,
//           );
//         },
//       )
//           : null,
//
//
//       body: Column(
//         children: [
//           // Search and page size selector
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 SearchField(controller: _searchController),
//                 const SizedBox(width: 8),
//                 PageSizeSelector(
//                   currentSize: pageSize,
//                   onChanged: (newSize) {
//                     setState(() {
//                       pageSize = newSize;
//                       currentPage = 1;
//                       services.clear();
//                       filteredServices.clear();
//                     });
//                     _fetchServices();
//                   },
//                 ),
//               ],
//             ),
//           ),
//
//
//           // Pagination info
//           if (totalServices > 0)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Total: $totalServices services",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                   Text(
//                     "Page $currentPage/${(totalServices / pageSize).ceil()}",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Main content
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : hasError
//                 ? Center(child: ElevatedButton(onPressed: () => _fetchServices(), child: const Text("Réessayer")))
//                 : services.isEmpty
//                 ? const Center(child: Text("Aucun service trouvé."))
//                 : NotificationListener<ScrollNotification>(
//               onNotification: (ScrollNotification scrollInfo) {
//                 // Only use infinite scroll if the flag is enabled
//                 if (useInfiniteScroll && !isLoadingMore && hasMore &&
//                     scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//                   // Only load more if we're at the bottom and there's more to load
//                   setState(() {
//                     currentPage++;  // Increment page counter before loading more
//                   });
//                   _fetchServices(loadMore: true);
//                 }
//                 return false;
//               },
//               child: ListView.builder(
//                 itemCount: filteredServices.length + (isLoadingMore ? 1 : 0),
//                 padding: const EdgeInsets.all(12),
//                 itemBuilder: (context, index) {
//                   if (index == filteredServices.length) {
//                     return const Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: CircularProgressIndicator(),
//                       ),
//                     );
//                   }
//
//                   final service = filteredServices[index];
//                   final hasPromo = service.promotion != null;
//                   return Card(
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     elevation: 2,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       onTap: () => showServiceDetailsModal(
//                         context: context,
//                         service: service,
//                         isOwner: isOwner,
//                         onEdit: () {
//                           showEditServiceModal(context, service, _fetchServices);
//                         },
//                         onAddToCart: () => _ajouterAuPanier(service),
//                       ),
//
//
//                         leading: IconButton(
//                         icon: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
//                       ),
//                       subtitle: Row(
//                         children: [
//                           Icon(Icons.access_time, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           Text("${service.temps} min", style: TextStyle(color: primaryViolet)),
//                           const SizedBox(width: 16),
//                           Icon(Icons.euro, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             transitionBuilder: (Widget child, Animation<double> animation) {
//                               return ScaleTransition(scale: animation, child: child);
//                             },
//                             child: hasPromo
//                                 ? Row(
//                               key: ValueKey("promo_${service.id}"),
//                               children: [
//                                 Text("${service.prix}€ ", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                                 const SizedBox(width: 4),
//                                 Text("${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                               ],
//                             )
//                                 : Text("${service.prix}€", key: ValueKey("normal_${service.id}"), style: TextStyle(color: primaryViolet)),
//                           ),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                           IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showEditServiceModal(context, service, _fetchServices),),
//                           IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                         ],
//                       )
//                           : null,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//
//           // Pagination Controls
//           PaginationControls(
//             currentPage: currentPage,
//             totalItems: totalServices,
//             pageSize: pageSize,
//             previousPageUrl: previousPageUrl,
//             nextPageUrl: nextPageUrl,
//             onPrevious: _goToPreviousPage,
//             onNext: _goToNextPage,
//           ),
//
//         ],
//       ),
//     );
//   }
// }






 // import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//   int currentPage = 1;
//   int pageSize = 10; // Configurable page size
//   int totalServices = 0;
//   String? nextPageUrl;
//   String? previousPageUrl;
//
//   bool isLoadingMore = false;
//   bool hasMore = true;
//
//   // Option: Choose only one pagination approach
//   bool useInfiniteScroll = false; // Set to false to disable infinite scroll
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices({bool loadMore = false}) async {
//     if (loadMore) {
//       setState(() => isLoadingMore = true);
//     } else {
//       setState(() {
//         isLoading = true;
//         hasError = false;
//         if (!loadMore) {
//           // Only reset services when loading a new page
//           services.clear();
//           filteredServices.clear();
//         }
//       });
//     }
//
//     try {
//       final url = Uri.parse(
//         'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         // Extract pagination info if available
//         if (responseData.containsKey('count')) {
//           setState(() {
//             totalServices = responseData['count'];
//             nextPageUrl = responseData['next'];
//             previousPageUrl = responseData['previous'];
//           });
//         }
//
//         // Extract services based on response structure
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> fetched = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         setState(() {
//           if (loadMore) {
//             services.addAll(fetched);
//           } else {
//             services = fetched;
//           }
//           filteredServices = List.from(services);
//           // Determine if there are more pages based on nextPageUrl
//           hasMore = nextPageUrl != null;
//
//           // Only increment page for infinite scroll if actually loading more
//           // Page number is already managed in goToNextPage for button navigation
//         });
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: service.id),
//       ),
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   // Nouvelle méthode pour afficher le modal d'ajout de service
//   void _showAddServiceModal() {
//     final TextEditingController nameController = TextEditingController();
//     final TextEditingController descriptionController = TextEditingController();
//     final TextEditingController priceController = TextEditingController();
//     final TextEditingController durationController = TextEditingController();
//     bool isLoading = false;
//
//     Widget buildTextField(String label, TextEditingController controller, IconData icon,
//         {TextInputType? keyboardType, int maxLines = 1}) {
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 20),
//         child: TextField(
//           controller: controller,
//           maxLines: maxLines,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             prefixIcon: Icon(icon, color: primaryViolet),
//             labelText: label,
//             labelStyle: const TextStyle(color: Color(0xFF555555)),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//       );
//     }
//
//     Future<void> addService() async {
//       if (nameController.text.isEmpty ||
//           descriptionController.text.isEmpty ||
//           priceController.text.isEmpty ||
//           durationController.text.isEmpty) {
//         _showError("Tous les champs sont obligatoires.");
//         return;
//       }
//
//       setState(() => isLoading = true);
//
//       try {
//         final response = await http.post(
//           Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
//           headers: {'Content-Type': 'application/json'},
//           body: json.encode({
//             'userId': widget.coiffeuseId,
//             'intitule_service': nameController.text,
//             'description': descriptionController.text,
//             'prix': double.parse(priceController.text),
//             'temps_minutes': int.parse(durationController.text),
//           }),
//         );
//
//         if (response.statusCode == 201) {
//           Navigator.pop(context, true); // Ferme le modal avec succès
//           _fetchServices(); // Actualise la liste des services
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Service ajouté avec succès ✅"), backgroundColor: Colors.green),
//           );
//         } else {
//           _showError("Erreur lors de l'ajout : ${response.body}");
//         }
//       } catch (e) {
//         _showError("Erreur de connexion au serveur: $e");
//       } finally {
//         setState(() => isLoading = false);
//       }
//     }
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setModalState) {
//             return AnimatedPadding(
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeOut,
//               padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.85,
//                 maxChildSize: 0.95,
//                 minChildSize: 0.5,
//                 expand: false,
//                 builder: (context, scrollController) => Container(
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFF7F7F9),
//                     borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                   ),
//                   padding: const EdgeInsets.all(20),
//                   child: ListView(
//                     controller: scrollController,
//                     children: [
//                       Center(
//                         child: Container(
//                           width: 40,
//                           height: 5,
//                           margin: const EdgeInsets.only(bottom: 20),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                       const Text(
//                         "Ajouter un service",
//                         style: TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF333333),
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                       buildTextField("Nom du service", nameController, Icons.design_services),
//                       buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
//                       buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
//                       buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
//                       const SizedBox(height: 20),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: isLoading
//                               ? null
//                               : () {
//                             setModalState(() {
//                               isLoading = true;
//                             });
//                             addService().then((_) {
//                               setModalState(() {
//                                 isLoading = false;
//                               });
//                             });
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryViolet,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                             elevation: 4,
//                             shadowColor: const Color(0x887B61FF),
//                           ),
//                           child: isLoading
//                               ? const CircularProgressIndicator(color: Colors.white)
//                               : const Text(
//                             "Ajouter le service",
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     ).then((value) {
//       if (value == true) {
//         _fetchServices();
//       }
//     });
//   }
//
//   void _showPageSizeSelector() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Services par page",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _pageSizeButton(5),
//                   _pageSizeButton(10),
//                   _pageSizeButton(20),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _pageSizeButton(int size) {
//     final isSelected = size == pageSize;
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isSelected ? primaryViolet : Colors.grey[200],
//         foregroundColor: isSelected ? Colors.white : Colors.black87,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//       onPressed: () {
//         Navigator.pop(context);
//         if (size != pageSize) {
//           setState(() {
//             pageSize = size;
//             currentPage = 1;
//             services.clear();
//             filteredServices.clear();
//           });
//           _fetchServices();
//         }
//       },
//       child: Text(
//         "$size",
//         style: TextStyle(
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
//
//   // Fixed navigation to next page
//   void _goToNextPage() {
//     if (nextPageUrl != null) {
//       setState(() {
//         currentPage++;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   // Fixed navigation to previous page
//   void _goToPreviousPage() {
//     if (previousPageUrl != null && currentPage > 1) {
//       setState(() {
//         currentPage--;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: primaryViolet,
//         child: const Icon(Icons.add),
//         onPressed: _showAddServiceModal, // Modifié pour utiliser le modal
//       )
//           : null,
//       body: Column(
//         children: [
//           // Search and page size selector
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 // Search field
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: "Rechercher un service...",
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // Page size selector button
//                 IconButton(
//                   icon: const Icon(Icons.format_list_numbered),
//                   tooltip: "Nombre de services par page",
//                   onPressed: _showPageSizeSelector,
//                 ),
//               ],
//             ),
//           ),
//
//           // Pagination info
//           if (totalServices > 0)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Total: $totalServices services",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                   Text(
//                     "Page $currentPage/${(totalServices / pageSize).ceil()}",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Main content
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : hasError
//                 ? Center(child: ElevatedButton(onPressed: () => _fetchServices(), child: const Text("Réessayer")))
//                 : services.isEmpty
//                 ? const Center(child: Text("Aucun service trouvé."))
//                 : NotificationListener<ScrollNotification>(
//               onNotification: (ScrollNotification scrollInfo) {
//                 // Only use infinite scroll if the flag is enabled
//                 if (useInfiniteScroll && !isLoadingMore && hasMore &&
//                     scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//                   // Only load more if we're at the bottom and there's more to load
//                   setState(() {
//                     currentPage++;  // Increment page counter before loading more
//                   });
//                   _fetchServices(loadMore: true);
//                 }
//                 return false;
//               },
//               child: ListView.builder(
//                 itemCount: filteredServices.length + (isLoadingMore ? 1 : 0),
//                 padding: const EdgeInsets.all(12),
//                 itemBuilder: (context, index) {
//                   if (index == filteredServices.length) {
//                     return const Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: CircularProgressIndicator(),
//                       ),
//                     );
//                   }
//
//                   final service = filteredServices[index];
//                   final hasPromo = service.promotion != null;
//                   return Card(
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     elevation: 2,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       onTap: () => _showServiceDetails(service),
//                       leading: IconButton(
//                         icon: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
//                       ),
//                       subtitle: Row(
//                         children: [
//                           Icon(Icons.access_time, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           Text("${service.temps} min", style: TextStyle(color: primaryViolet)),
//                           const SizedBox(width: 16),
//                           Icon(Icons.euro, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             transitionBuilder: (Widget child, Animation<double> animation) {
//                               return ScaleTransition(scale: animation, child: child);
//                             },
//                             child: hasPromo
//                                 ? Row(
//                               key: ValueKey("promo_${service.id}"),
//                               children: [
//                                 Text("${service.prix}€ ", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                                 const SizedBox(width: 4),
//                                 Text("${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                               ],
//                             )
//                                 : Text("${service.prix}€", key: ValueKey("normal_${service.id}"), style: TextStyle(color: primaryViolet)),
//                           ),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                           IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                           IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                         ],
//                       )
//                           : null,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//
//           // Pagination Controls
//           if (totalServices > pageSize && !isLoading)
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Previous page button
//                   ElevatedButton.icon(
//                     onPressed: previousPageUrl != null ? _goToPreviousPage : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryViolet,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       disabledForegroundColor: Colors.grey[500],
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     icon: const Icon(Icons.arrow_back),
//                     label: const Text("Précédent"),
//                   ),
//
//                   // Page indicator
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Text(
//                       "$currentPage / ${(totalServices / pageSize).ceil()}",
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//
//                   // Next page button
//                   ElevatedButton.icon(
//                     onPressed: nextPageUrl != null ? _goToNextPage : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryViolet,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       disabledForegroundColor: Colors.grey[500],
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     icon: const Icon(Icons.arrow_forward),
//                     label: const Text("Suivant"),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _showServiceDetails(Service service) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//           padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             expand: false,
//             builder: (context, scrollController) => Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: ListView(
//                 controller: scrollController,
//                 shrinkWrap: true,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   Text(service.intitule,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       )),
//                   const SizedBox(height: 10),
//                   Text(
//                     service.description.isNotEmpty ? service.description : "Pas de description",
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       service.promotion != null
//                           ? Row(
//                         children: [
//                           Text("${service.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           const SizedBox(width: 6),
//                           Text("${service.getPrixAvecReduction()} € 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                         ],
//                       )
//                           : Text("${service.prix} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       if (isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => EditServicePage(
//                                   service: service,
//                                   onServiceUpdated: _fetchServices,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.edit, color: Colors.white),
//                           label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                         ),
//                       if (!isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             _ajouterAuPanier(service);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7B61FF),
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                           label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                         ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }






 // import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//   int currentPage = 1;
//   int pageSize = 10; // Configurable page size
//   int totalServices = 0;
//   String? nextPageUrl;
//   String? previousPageUrl;
//
//   bool isLoadingMore = false;
//   bool hasMore = true;
//
//   // Option: Choose only one pagination approach
//   bool useInfiniteScroll = false; // Set to false to disable infinite scroll
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices({bool loadMore = false}) async {
//     if (loadMore) {
//       setState(() => isLoadingMore = true);
//     } else {
//       setState(() {
//         isLoading = true;
//         hasError = false;
//         if (!loadMore) {
//           // Only reset services when loading a new page
//           services.clear();
//           filteredServices.clear();
//         }
//       });
//     }
//
//     try {
//       final url = Uri.parse(
//         'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         // Extract pagination info if available
//         if (responseData.containsKey('count')) {
//           setState(() {
//             totalServices = responseData['count'];
//             nextPageUrl = responseData['next'];
//             previousPageUrl = responseData['previous'];
//           });
//         }
//
//         // Extract services based on response structure
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> fetched = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         setState(() {
//           if (loadMore) {
//             services.addAll(fetched);
//           } else {
//             services = fetched;
//           }
//           filteredServices = List.from(services);
//           // Determine if there are more pages based on nextPageUrl
//           hasMore = nextPageUrl != null;
//
//           // Only increment page for infinite scroll if actually loading more
//           // Page number is already managed in goToNextPage for button navigation
//         });
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: service.id),
//       ),
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   void _showPageSizeSelector() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Services par page",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _pageSizeButton(5),
//                   _pageSizeButton(10),
//                   _pageSizeButton(20),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _pageSizeButton(int size) {
//     final isSelected = size == pageSize;
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isSelected ? primaryViolet : Colors.grey[200],
//         foregroundColor: isSelected ? Colors.white : Colors.black87,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//       onPressed: () {
//         Navigator.pop(context);
//         if (size != pageSize) {
//           setState(() {
//             pageSize = size;
//             currentPage = 1;
//             services.clear();
//             filteredServices.clear();
//           });
//           _fetchServices();
//         }
//       },
//       child: Text(
//         "$size",
//         style: TextStyle(
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
//
//   // Fixed navigation to next page
//   void _goToNextPage() {
//     if (nextPageUrl != null) {
//       setState(() {
//         currentPage++;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   // Fixed navigation to previous page
//   void _goToPreviousPage() {
//     if (previousPageUrl != null && currentPage > 1) {
//       setState(() {
//         currentPage--;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices(loadMore: false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: primaryViolet,
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: Column(
//         children: [
//           // Search and page size selector
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 // Search field
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: "Rechercher un service...",
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // Page size selector button
//                 IconButton(
//                   icon: const Icon(Icons.format_list_numbered),
//                   tooltip: "Nombre de services par page",
//                   onPressed: _showPageSizeSelector,
//                 ),
//               ],
//             ),
//           ),
//
//           // Pagination info
//           if (totalServices > 0)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Total: $totalServices services",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                   Text(
//                     "Page $currentPage/${(totalServices / pageSize).ceil()}",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Main content
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : hasError
//                 ? Center(child: ElevatedButton(onPressed: () => _fetchServices(), child: const Text("Réessayer")))
//                 : services.isEmpty
//                 ? const Center(child: Text("Aucun service trouvé."))
//                 : NotificationListener<ScrollNotification>(
//               onNotification: (ScrollNotification scrollInfo) {
//                 // Only use infinite scroll if the flag is enabled
//                 if (useInfiniteScroll && !isLoadingMore && hasMore &&
//                     scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//                   // Only load more if we're at the bottom and there's more to load
//                   setState(() {
//                     currentPage++;  // Increment page counter before loading more
//                   });
//                   _fetchServices(loadMore: true);
//                 }
//                 return false;
//               },
//               child: ListView.builder(
//                 itemCount: filteredServices.length + (isLoadingMore ? 1 : 0),
//                 padding: const EdgeInsets.all(12),
//                 itemBuilder: (context, index) {
//                   if (index == filteredServices.length) {
//                     return const Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: CircularProgressIndicator(),
//                       ),
//                     );
//                   }
//
//                   final service = filteredServices[index];
//                   final hasPromo = service.promotion != null;
//                   return Card(
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     elevation: 2,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       onTap: () => _showServiceDetails(service),
//                       leading: IconButton(
//                         icon: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
//                       ),
//                       subtitle: Row(
//                         children: [
//                           Icon(Icons.access_time, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           Text("${service.temps} min", style: TextStyle(color: primaryViolet)),
//                           const SizedBox(width: 16),
//                           Icon(Icons.euro, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             transitionBuilder: (Widget child, Animation<double> animation) {
//                               return ScaleTransition(scale: animation, child: child);
//                             },
//                             child: hasPromo
//                                 ? Row(
//                               key: ValueKey("promo_${service.id}"),
//                               children: [
//                                 Text("${service.prix}€ ", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                                 const SizedBox(width: 4),
//                                 Text("${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                               ],
//                             )
//                                 : Text("${service.prix}€", key: ValueKey("normal_${service.id}"), style: TextStyle(color: primaryViolet)),
//                           ),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                           IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                           IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                         ],
//                       )
//                           : null,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//
//           // Pagination Controls
//           if (totalServices > pageSize && !isLoading)
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Previous page button
//                   ElevatedButton.icon(
//                     onPressed: previousPageUrl != null ? _goToPreviousPage : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryViolet,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       disabledForegroundColor: Colors.grey[500],
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     icon: const Icon(Icons.arrow_back),
//                     label: const Text("Précédent"),
//                   ),
//
//                   // Page indicator
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Text(
//                       "$currentPage / ${(totalServices / pageSize).ceil()}",
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//
//                   // Next page button
//                   ElevatedButton.icon(
//                     onPressed: nextPageUrl != null ? _goToNextPage : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryViolet,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       disabledForegroundColor: Colors.grey[500],
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     icon: const Icon(Icons.arrow_forward),
//                     label: const Text("Suivant"),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _showServiceDetails(Service service) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//           padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             expand: false,
//             builder: (context, scrollController) => Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: ListView(
//                 controller: scrollController,
//                 shrinkWrap: true,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   Text(service.intitule,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       )),
//                   const SizedBox(height: 10),
//                   Text(
//                     service.description.isNotEmpty ? service.description : "Pas de description",
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       service.promotion != null
//                           ? Row(
//                         children: [
//                           Text("${service.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           const SizedBox(width: 6),
//                           Text("${service.getPrixAvecReduction()} € 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                         ],
//                       )
//                           : Text("${service.prix} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       if (isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => EditServicePage(
//                                   service: service,
//                                   onServiceUpdated: _fetchServices,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.edit, color: Colors.white),
//                           label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                         ),
//                       if (!isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             _ajouterAuPanier(service);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7B61FF),
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                           label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                         ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//   int currentPage = 1;
//   int pageSize = 10; // Configurable page size
//   int totalServices = 0;
//   String? nextPageUrl;
//   String? previousPageUrl;
//
//   bool isLoadingMore = false;
//   bool hasMore = true;
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices({bool loadMore = false}) async {
//     if (loadMore) {
//       setState(() => isLoadingMore = true);
//     } else {
//       setState(() {
//         isLoading = true;
//         hasError = false;
//         currentPage = 1;
//         services.clear();
//         filteredServices.clear();
//       });
//     }
//
//     try {
//       final url = Uri.parse(
//         'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         // Extract pagination info if available
//         if (responseData.containsKey('count')) {
//           setState(() {
//             totalServices = responseData['count'];
//             nextPageUrl = responseData['next'];
//             previousPageUrl = responseData['previous'];
//           });
//         }
//
//         // Extract services based on response structure
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> fetched = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         setState(() {
//           if (loadMore) {
//             services.addAll(fetched);
//           } else {
//             services = fetched;
//           }
//           filteredServices = List.from(services);
//           hasMore = fetched.length == pageSize;
//           if (loadMore) currentPage++;
//         });
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: service.id),
//       ),
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   void _showPageSizeSelector() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Services par page",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _pageSizeButton(5),
//                   _pageSizeButton(10),
//                   _pageSizeButton(20),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _pageSizeButton(int size) {
//     final isSelected = size == pageSize;
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isSelected ? primaryViolet : Colors.grey[200],
//         foregroundColor: isSelected ? Colors.white : Colors.black87,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//       onPressed: () {
//         Navigator.pop(context);
//         if (size != pageSize) {
//           setState(() {
//             pageSize = size;
//             currentPage = 1;
//             services.clear();
//             filteredServices.clear();
//           });
//           _fetchServices();
//         }
//       },
//       child: Text(
//         "$size",
//         style: TextStyle(
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
//
//   // Navigation to next page
//   void _goToNextPage() {
//     if (nextPageUrl != null) {
//       setState(() {
//         currentPage++;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices();
//     }
//   }
//
//   // Navigation to previous page
//   void _goToPreviousPage() {
//     if (previousPageUrl != null && currentPage > 1) {
//       setState(() {
//         currentPage--;
//         isLoading = true;
//         services.clear();
//         filteredServices.clear();
//       });
//       _fetchServices();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: primaryViolet,
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: Column(
//         children: [
//           // Search and page size selector
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 // Search field
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: "Rechercher un service...",
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // Page size selector button
//                 IconButton(
//                   icon: const Icon(Icons.format_list_numbered),
//                   tooltip: "Nombre de services par page",
//                   onPressed: _showPageSizeSelector,
//                 ),
//               ],
//             ),
//           ),
//
//           // Pagination info
//           if (totalServices > 0)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Total: $totalServices services",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                   Text(
//                     "Page $currentPage/${(totalServices / pageSize).ceil()}",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Main content
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : hasError
//                 ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//                 : services.isEmpty
//                 ? const Center(child: Text("Aucun service trouvé."))
//                 : NotificationListener<ScrollNotification>(
//               onNotification: (ScrollNotification scrollInfo) {
//                 if (!isLoadingMore && hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//                   _fetchServices(loadMore: true);
//                 }
//                 return false;
//               },
//               child: ListView.builder(
//                 itemCount: filteredServices.length + (isLoadingMore ? 1 : 0),
//                 padding: const EdgeInsets.all(12),
//                 itemBuilder: (context, index) {
//                   if (index == filteredServices.length) {
//                     return const Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: CircularProgressIndicator(),
//                       ),
//                     );
//                   }
//
//                   final service = filteredServices[index];
//                   final hasPromo = service.promotion != null;
//                   return Card(
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     elevation: 2,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       onTap: () => _showServiceDetails(service),
//                       leading: IconButton(
//                         icon: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
//                       ),
//                       subtitle: Row(
//                         children: [
//                           Icon(Icons.access_time, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           Text("${service.temps} min", style: TextStyle(color: primaryViolet)),
//                           const SizedBox(width: 16),
//                           Icon(Icons.euro, size: 18, color: primaryViolet),
//                           const SizedBox(width: 4),
//                           AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             transitionBuilder: (Widget child, Animation<double> animation) {
//                               return ScaleTransition(scale: animation, child: child);
//                             },
//                             child: hasPromo
//                                 ? Row(
//                               key: ValueKey("promo_${service.id}"),
//                               children: [
//                                 Text("${service.prix}€ ", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                                 const SizedBox(width: 4),
//                                 Text("${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                               ],
//                             )
//                                 : Text("${service.prix}€", key: ValueKey("normal_${service.id}"), style: TextStyle(color: primaryViolet)),
//                           ),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                           IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                           IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                         ],
//                       )
//                           : null,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//
//           // Pagination Controls
//           if (totalServices > pageSize && !isLoading)
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Previous page button
//                   ElevatedButton.icon(
//                     onPressed: previousPageUrl != null ? _goToPreviousPage : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryViolet,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       disabledForegroundColor: Colors.grey[500],
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     icon: const Icon(Icons.arrow_back),
//                     label: const Text("Précédent"),
//                   ),
//
//                   // Page indicator
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Text(
//                       "$currentPage / ${(totalServices / pageSize).ceil()}",
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//
//                   // Next page button
//                   ElevatedButton.icon(
//                     onPressed: nextPageUrl != null ? _goToNextPage : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryViolet,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       disabledForegroundColor: Colors.grey[500],
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     icon: const Icon(Icons.arrow_forward),
//                     label: const Text("Suivant"),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _showServiceDetails(Service service) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//           padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             expand: false,
//             builder: (context, scrollController) => Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: ListView(
//                 controller: scrollController,
//                 shrinkWrap: true,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   Text(service.intitule,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       )),
//                   const SizedBox(height: 10),
//                   Text(
//                     service.description.isNotEmpty ? service.description : "Pas de description",
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       service.promotion != null
//                           ? Row(
//                         children: [
//                           Text("${service.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           const SizedBox(width: 6),
//                           Text("${service.getPrixAvecReduction()} € 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                         ],
//                       )
//                           : Text("${service.prix} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       if (isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => EditServicePage(
//                                   service: service,
//                                   onServiceUpdated: _fetchServices,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.edit, color: Colors.white),
//                           label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                         ),
//                       if (!isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             _ajouterAuPanier(service);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7B61FF),
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                           label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                         ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//   int currentPage = 1;
//   final int pageSize = 10;
//   bool isLoadingMore = false;
//   bool hasMore = true;
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices({bool loadMore = false}) async {
//     if (loadMore) {
//       setState(() => isLoadingMore = true);
//     } else {
//       setState(() {
//         isLoading = true;
//         hasError = false;
//         currentPage = 1;
//         services.clear();
//         filteredServices.clear();
//       });
//     }
//
//     try {
//       final url = Uri.parse(
//         'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/?page=$currentPage&page_size=$pageSize',
//       );
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         // ✅ Gestion du cas avec pagination : data dans ['results']['salon']['services']
//         final serviceList = responseData.containsKey('results')
//             ? responseData['results']['salon']['services']
//             : responseData['salon']['services'];
//
//         final List<Service> fetched = (serviceList as List)
//             .map((json) => Service.fromJson(json))
//             .whereType<Service>()
//             .toList();
//
//         setState(() {
//           services.addAll(fetched);
//           filteredServices = List.from(services);
//           hasMore = fetched.length == pageSize;
//           currentPage++;
//         });
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//     }
//   }
//
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: service.id),
//       ),
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: primaryViolet,
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : NotificationListener<ScrollNotification>(
//         onNotification: (ScrollNotification scrollInfo) {
//           if (!isLoadingMore && hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//             _fetchServices(loadMore: true);
//           }
//           return false;
//         },
//         child: ListView.builder(
//           itemCount: filteredServices.length,
//           padding: const EdgeInsets.all(12),
//           itemBuilder: (context, index) {
//             final service = filteredServices[index];
//             final hasPromo = service.promotion != null;
//             return Card(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               elevation: 2,
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 onTap: () => _showServiceDetails(service),
//                 leading: IconButton(
//                   icon: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
//                   onPressed: () => _ajouterAuPanier(service),
//                 ),
//                 title: Text(
//                   service.intitule,
//                   style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
//                 ),
//                 subtitle: Row(
//                   children: [
//                     Icon(Icons.access_time, size: 18, color: primaryViolet),
//                     const SizedBox(width: 4),
//                     Text("${service.temps} min", style: TextStyle(color: primaryViolet)),
//                     const SizedBox(width: 16),
//                     Icon(Icons.euro, size: 18, color: primaryViolet),
//                     const SizedBox(width: 4),
//                     AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 300),
//                       transitionBuilder: (Widget child, Animation<double> animation) {
//                         return ScaleTransition(scale: animation, child: child);
//                       },
//                       child: hasPromo
//                           ? Row(
//                         key: ValueKey("promo_${service.id}"),
//                         children: [
//                           Text("${service.prix}€ ", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           const SizedBox(width: 4),
//                           Text("${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                         ],
//                       )
//                           : Text("${service.prix}€", key: ValueKey("normal_${service.id}"), style: TextStyle(color: primaryViolet)),
//                     ),
//                   ],
//                 ),
//                 trailing: isOwner
//                     ? Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(icon: Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                     IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                     IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                   ],
//                 )
//                     : null,
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   void _showServiceDetails(Service service) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//           padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             expand: false,
//             builder: (context, scrollController) => Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: ListView(
//                 controller: scrollController,
//                 shrinkWrap: true,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   Text(service.intitule,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       )),
//                   const SizedBox(height: 10),
//                   Text(
//                     service.description.isNotEmpty ? service.description : "Pas de description",
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       service.promotion != null
//                           ? Row(
//                         children: [
//                           Text("${service.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           const SizedBox(width: 6),
//                           Text("${service.getPrixAvecReduction()} € 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                         ],
//                       )
//                           : Text("${service.prix} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       if (isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => EditServicePage(
//                                   service: service,
//                                   onServiceUpdated: _fetchServices,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.edit, color: Colors.white),
//                           label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                         ),
//                       if (!isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             _ajouterAuPanier(service);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7B61FF),
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                           label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                         ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }








// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: service.id),
//       ),
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: primaryViolet,
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : ListView.builder(
//         itemCount: filteredServices.length,
//         padding: const EdgeInsets.all(12),
//         itemBuilder: (context, index) {
//           final service = filteredServices[index];
//           return Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             elevation: 2,
//             child: ListTile(
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               onTap: () => _showServiceDetails(service),
//               leading: IconButton(
//                 icon: Icon(Icons.shopping_cart_checkout_rounded, color: primaryViolet),
//                 onPressed: () => _ajouterAuPanier(service),
//
//               ),
//               title: Text(
//                 service.intitule,
//                 style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet),
//               ),
//               subtitle: Row(
//                 children: [
//                   Icon(Icons.access_time, size: 18, color: primaryViolet),
//                   const SizedBox(width: 4),
//                   Text("${service.temps} min", style: TextStyle(color: primaryViolet)),
//                   const SizedBox(width: 16),
//                   Icon(Icons.euro, size: 18, color: primaryViolet),
//                   const SizedBox(width: 4),
//                   Text(
//                     service.promotion != null
//                         ? "${service.getPrixAvecReduction()}€ 🔥"
//                         : "${service.prix}€",
//                     style: TextStyle(
//                       color: service.promotion != null ? Colors.green : primaryViolet,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//               trailing: isOwner
//                   ? Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(icon: Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                   IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                   IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                 ],
//               )
//                   : null,
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // Ajoute ceci dans ton fichier ServicesListPage
//
//   void _showServiceDetails(Service service) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//           padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             expand: false,
//             builder: (context, scrollController) => Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: ListView(
//                 controller: scrollController,
//                 shrinkWrap: true,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   Text(service.intitule,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       )),
//                   const SizedBox(height: 10),
//                   Text(
//                     service.description.isNotEmpty
//                         ? service.description
//                         : "Pas de description",
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                       const SizedBox(width: 8),
//                       Text(
//                         service.promotion != null
//                             ? "${service.getPrixAvecReduction()} € 🔥"
//                             : "${service.prix} €",
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       if (isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => EditServicePage(
//                                   service: service,
//                                   onServiceUpdated: _fetchServices,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.edit, color: Colors.white),
//                           label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                         ),
//                       if (!isOwner)
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             _ajouterAuPanier(service);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7B61FF),
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                           label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                         ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }






 // // ✅ Nouvelle version designée à la sauce "modern UI"
// // Avec boutons d'édition / suppression restaurés + panier + duration / prix
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(utf8.decode(response.bodyBytes));
//         if (data['status'] == 'success' && data['salon'].containsKey('services')) {
//           setState(() {
//             services = (data['salon']['services'] as List).map((e) => Service.fromJson(e)).toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données.");
//         }
//       } else {
//         _showError("Erreur serveur: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((s) =>
//       s.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (s.description).toLowerCase().contains(query.toLowerCase())
//       ).toList();
//     });
//   }
//
//   void _deleteService(int id) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$id/');
//     try {
//       final res = await http.delete(url);
//       if (res.statusCode == 200) _fetchServices();
//       else _showError("Erreur lors de la suppression.");
//     } catch (_) {
//       _showError("Connexion échouée.");
//     }
//   }
//
//   void _ajouterAuPanier(Service s) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(s, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text("${s.intitule} ajouté au panier ✅"),
//       backgroundColor: Colors.green,
//     ));
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg),
//       backgroundColor: Colors.red,
//     ));
//   }
//
//   void _showPromoModal(Service s) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: s.id),
//       ),
//     ).then((val) {
//       if (val == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5FF),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (i) => setState(() => _currentIndex = i),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: const Color(0xFF7B61FF),
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//           ),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredServices.length,
//               itemBuilder: (context, index) {
//                 final s = filteredServices[index];
//                 return Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.deepPurple.withAlpha(20),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       )
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               s.intitule,
//                               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
//                             onPressed: () => _ajouterAuPanier(s),
//                           )
//                         ],
//                       ),
//                       const SizedBox(height: 6),
//                       Text(s.description, style: const TextStyle(color: Colors.black54)),
//                       const SizedBox(height: 6),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text("⏱️ ${s.temps} min", style: const TextStyle(fontSize: 13)),
//                           if (s.promotion != null)
//                             Row(children: [
//                               Text("${s.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                               const SizedBox(width: 4),
//                               Text("${s.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                             ])
//                           else
//                             Text("${s.prix}€", style: const TextStyle(fontWeight: FontWeight.bold))
//                         ],
//                       ),
//                       if (isOwner)
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showPromoModal(s)),
//                             IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: s, onServiceUpdated: _fetchServices)))),
//                             IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(s.id)),
//                           ],
//                         )
//                     ],
//                   ),
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }







// // ✅ ServicesListPage au design modernisé style UI violet-orange
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: CreatePromotionModal(serviceId: service.id),
//         );
//       },
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: const Color(0xFF7B61FF),
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//           ),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: filteredServices.length,
//         itemBuilder: (context, index) {
//           final service = filteredServices[index];
//           return Container(
//             margin: const EdgeInsets.symmetric(vertical: 10),
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(18),
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF7B61FF), Color(0xFFE26BFD)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF9C27B0).withAlpha(51), // 0.2 * 255 = 51
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 )
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         service.intitule,
//                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => _ajouterAuPanier(service),
//                       icon: const Icon(Icons.shopping_cart, color: Colors.white),
//                     )
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text("${service.temps} min", style: const TextStyle(color: Colors.white70)),
//                     service.promotion != null
//                         ? Row(
//                       children: [
//                         Text("${service.prix}€", style: const TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough)),
//                         const SizedBox(width: 6),
//                         Text("${service.getPrixAvecReduction()}€",
//                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                       ],
//                     )
//                         : Text("${service.prix}€", style: const TextStyle(color: Colors.white)),
//                   ],
//                 )
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }








// // ✅ Version finale avec CustomAppBar, BottomNavBar et style modernisé
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: CreatePromotionModal(serviceId: service.id),
//         );
//       },
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: const Color(0xFF7B61FF),
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//           ),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.search, color: Color(0xFF7B61FF)),
//                 hintText: "Rechercher un service...",
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: const BorderSide(color: Colors.grey),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredServices.length,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemBuilder: (context, index) {
//                 final service = filteredServices[index];
//                 return Card(
//                   color: Colors.primaries[index % Colors.primaries.length][100],
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   elevation: 3,
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.all(12),
//                     title: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(service.intitule,
//                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.shopping_cart_outlined, color: Colors.green),
//                           onPressed: () => _ajouterAuPanier(service),
//                         ),
//                       ],
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text("${service.temps} min", style: const TextStyle(fontSize: 13, color: Colors.grey)),
//                             if (service.promotion != null) ...[
//                               Text("${service.getPrixAvecReduction()}€ 🔥",
//                                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
//                             ] else ...[
//                               Text("${service.prix}€",
//                                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
//                             ]
//                           ],
//                         ),
//                         if (service.description.isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 4.0),
//                             child: Text(service.description, style: const TextStyle(fontSize: 13)),
//                           ),
//                       ],
//                     ),
//                     trailing: isOwner
//                         ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                         IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                         IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                       ],
//                     )
//                         : null,
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







// // ✅ Version finale avec CustomAppBar et BottomNavBar intégrés

//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   int _currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code \${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : \$e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description).toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/\$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("\${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: CreatePromotionModal(serviceId: service.id),
//         );
//       },
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: const Color(0xFF7B61FF),
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//           ),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.search),
//                 hintText: "Rechercher un service...",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Color(0xFF7B61FF)),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredServices.length,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemBuilder: (context, index) {
//                 final service = filteredServices[index];
//                 return Card(
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   elevation: 4,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                             Text("\${service.temps} min", style: const TextStyle(color: Colors.grey)),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(service.description, style: const TextStyle(fontSize: 14)),
//                         const SizedBox(height: 8),
//                         if (service.promotion != null) ...[
//                           Text("Prix: \${service.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           Text("Promo: \${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                         ] else ...[
//                           Text("Prix: \${service.prix}€", style: const TextStyle(fontWeight: FontWeight.w500)),
//                         ],
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: isOwner
//                               ? [
//                             IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                             IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                             IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                           ]
//                               : [
//                             IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// // ✅ Nouvelle version avec design cohérent Hairbnb : moderne, violet, arrondi, animations douces
// // Harmonisation UI/UX avec le reste de l'app (ajout salon, galerie, etc.)
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() => _filterServices(_searchController.text));
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() => isLoading = true);
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         final list = responseData['salon']['services'] as List;
//         services = list.map((json) => Service.fromJson(json)).toList();
//         filteredServices = List.from(services);
//       } else {
//         _showError("Erreur serveur: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Connexion impossible : $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((s) =>
//       s.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (s.description ?? '').toLowerCase().contains(query.toLowerCase())
//       ).toList();
//     });
//   }
//
//   void _deleteService(int id) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$id/');
//     final response = await http.delete(url);
//     if (response.statusCode == 200) _fetchServices();
//     else _showError("Erreur lors de la suppression.");
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${service.intitule} ajouté au panier")));
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: CreatePromotionModal(serviceId: service.id),
//       ),
//     ).then((val) => val == true ? _fetchServices() : null);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF7B61FF),
//         elevation: 0,
//         title: const Text("Mes Services", style: TextStyle(color: Colors.white)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: const Color(0xFF7B61FF),
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 filled: true,
//                 fillColor: Colors.white,
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: filteredServices.length,
//               itemBuilder: (context, i) {
//                 final s = filteredServices[i];
//                 return AnimatedContainer(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       )
//                     ],
//                   ),
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.all(16),
//                     title: Text(s.intitule, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(s.description ?? "Aucune description", style: const TextStyle(fontSize: 13)),
//                         const SizedBox(height: 6),
//                         if (s.promotion != null)
//                           Row(children: [
//                             Text("${s.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                             const SizedBox(width: 8),
//                             Text("${s.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green)),
//                           ])
//                         else
//                           Text("Prix: ${s.prix}€"),
//                         const SizedBox(height: 4),
//                         Text("Durée: ${s.temps} min", style: const TextStyle(color: Colors.grey))
//                       ],
//                     ),
//                     trailing: isOwner
//                         ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         IconButton(
//                             icon: const Icon(Icons.local_offer, color: Colors.purple),
//                             onPressed: () => _showCreatePromotionModal(s)),
//                         IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (_) => EditServicePage(service: s, onServiceUpdated: _fetchServices)),
//                             )),
//                         IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(s.id))
//                       ],
//                     )
//                         : IconButton(
//                       icon: const Icon(Icons.shopping_cart, color: Colors.green),
//                       onPressed: () => _ajouterAuPanier(s),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }









// // ✅ Version améliorée avec style uniforme et moderne
// // Harmonisation avec les pages "salon" et "ajout service"
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description ?? '').toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: CreatePromotionModal(serviceId: service.id),
//         );
//       },
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Color(0xFF7B61FF))),
//         backgroundColor: Colors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: const Color(0xFF7B61FF),
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//           ),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.search),
//                 hintText: "Rechercher un service...",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Color(0xFF7B61FF)),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredServices.length,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemBuilder: (context, index) {
//                 final service = filteredServices[index];
//                 return Card(
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   elevation: 4,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                             Text("${service.temps} min", style: const TextStyle(color: Colors.grey)),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(service.description ?? "Aucune description", style: const TextStyle(fontSize: 14)),
//                         const SizedBox(height: 8),
//                         if (service.promotion != null) ...[
//                           Text("Prix: ${service.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                         ] else ...[
//                           Text("Prix: ${service.prix}€", style: const TextStyle(fontWeight: FontWeight.w500)),
//                         ],
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: isOwner
//                               ? [
//                             IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                             IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                             IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                           ]
//                               : [
//                             IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







// // ✅ Version améliorée avec style uniforme et moderne
// // Harmonisation avec les pages "salon" et "ajout service"
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services.where((service) {
//         final titre = service.intitule.toLowerCase();
//         final desc = (service.description ?? '').toLowerCase();
//         return titre.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service, currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: CreatePromotionModal(serviceId: service.id),
//         );
//       },
//     ).then((value) {
//       if (value == true) _fetchServices();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isOwner = currentUserId == widget.coiffeuseId;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Color(0xFF7B61FF)));
//         backgroundColor: Colors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         backgroundColor: const Color(0xFF7B61FF),
//         child: const Icon(Icons.add),
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//           ),
//         ).then((_) => _fetchServices()),
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.search),
//                 hintText: "Rechercher un service...",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Color(0xFF7B61FF)),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredServices.length,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemBuilder: (context, index) {
//                 final service = filteredServices[index];
//                 return Card(
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   elevation: 4,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                             Text("${service.temps} min", style: const TextStyle(color: Colors.grey))
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(service.description ?? "Aucune description", style: const TextStyle(fontSize: 14)),
//                         const SizedBox(height: 8),
//                         if (service.promotion != null) ...[
//                           Text("Prix: ${service.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//                         ] else ...[
//                           Text("Prix: ${service.prix}€", style: const TextStyle(fontWeight: FontWeight.w500)),
//                         ],
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: isOwner
//                               ? [
//                             IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () => _showCreatePromotionModal(service)),
//                             IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditServicePage(service: service, onServiceUpdated: _fetchServices)))),
//                             IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                           ]
//                               : [
//                             IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service))
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late String? currentUserId;
//   late final Service service;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'ID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) {
//               try {
//                 return Service.fromJson(json);
//               } catch (e) {
//                 //--------------------------------------------------------------
//                 debugPrint("❌ show services list : Erreur JSON -> Service : $e");
//                 //--------------------------------------------------------------
//                 //debugPrint("❌ Erreur JSON -> Service : $e");
//                 return null;
//               }
//             })
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service,currentUserId!);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//       //---------------------------------------------------------------------------------
//       print('id service dans _ajouterAuPanier est : ${service.id}');
//       //---------------------------------------------------------------------------------
//
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCreatePromotionModal(Service service) {
//     final serviceId=service.id;
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true, // Pour permettre à la modal de prendre plus d'espace si nécessaire
//       backgroundColor: Colors.transparent, // Pour que les coins arrondis du Container apparaissent
//       builder: (context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets, // Gérer le clavier
//           child: CreatePromotionModal(serviceId: serviceId),
//         );
//       },
//     ).then((value) {
//       if (value == true) {
//         _fetchServices();
//       }
//     });
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//           ).then((_) => _fetchServices());
//         },
//         child: const Icon(Icons.add),
//         backgroundColor: Colors.orange,
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView.builder(
//           itemCount: filteredServices.length,
//           itemBuilder: (context, index) {
//             final service = filteredServices[index];
//             final color = Colors.primaries[index % Colors.primaries.length][100];
//             return Card(
//               color: color,
//               margin: const EdgeInsets.symmetric(vertical: 8.0),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.white,
//                   child: const Icon(Icons.cut, color: Colors.orange),
//                 ),
//                 title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Durée: ${service.temps} min"),
//                     Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                     if (service.promotion != null) ...[
//                       Text("Prix: ${service.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                       Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                     ] else ...[
//                       Text("Prix: ${service.prix}€"),
//                     ],
//                   ],
//                 ),
//                 trailing: isOwner
//                     ? Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () {
//                       _showCreatePromotionModal(service);
//                     }),
//                     IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(
//                         builder: (context) => EditServicePage(service: service, onServiceUpdated: _fetchServices),
//                       ));
//                     }),
//                     IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                   ],
//                 )
//                     : IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

















// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/create_promotion_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart'; // ✅ Page pour ajouter un service
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'ID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//         if (responseData['status'] == 'success' && responseData['salon'].containsKey('services')) {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) {
//               try {
//                 return Service.fromJson(json);
//               } catch (e) {
//                 debugPrint("❌ Erreur JSON -> Service : $e");
//                 return null;
//               }
//             })
//                 .whereType<Service>()
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Format incorrect des données reçues.");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         _fetchServices();
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("${service.intitule} ajouté au panier ✅"), backgroundColor: Colors.green),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId)),
//           ).then((_) => _fetchServices());
//         },
//         child: const Icon(Icons.add),
//         backgroundColor: Colors.orange,
//       )
//           : null,
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView.builder(
//           itemCount: filteredServices.length,
//           itemBuilder: (context, index) {
//             final service = filteredServices[index];
//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 8.0),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.white,
//                   child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                 ),
//                 title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (service.promotion != null) ...[
//                       Text("Prix: ${service.prix}€", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                       Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                     ] else ...[
//                       Text("Prix: ${service.prix}€"),
//                     ],
//                   ],
//                 ),
//                 trailing: isOwner
//                     ? Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(icon: const Icon(Icons.local_offer, color: Colors.purple), onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(
//                         builder: (context) => CreatePromotionPage(serviceId: service.id),
//                       )).then((_) => _fetchServices());
//                     }),
//                     IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(
//                         builder: (context) => EditServicePage(service: service, onServiceUpdated: _fetchServices),
//                       ));
//                     }),
//                     IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(service.id)),
//                   ],
//                 )
//                     : IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//

















//
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart'; // Import de la page d'ajout
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'ID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString(); // Assure que c'est bien un String
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final url = Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/');
//       debugPrint("🔗 Envoi de la requête à : $url");
//
//       final response = await http.get(url);
//
//       debugPrint("🔍 Statut HTTP : ${response.statusCode}");
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//
//         debugPrint("📥 Réponse reçue : $responseData");
//
//         if (responseData['status'] == 'success') {
//           // ✅ Vérification de la structure des données
//           if (responseData.containsKey('salon') && responseData['salon'].containsKey('services')) {
//             setState(() {
//               services = (responseData['salon']['services'] as List)
//                   .map((json) {
//                 try {
//                   return Service.fromJson(json);
//                 } catch (e) {
//                   debugPrint("❌ Erreur lors de la conversion JSON -> Service : $e");
//                   return null; // Évite un crash si un service est invalide
//                 }
//               })
//                   .whereType<Service>() // Supprime les valeurs null
//                   .toList();
//
//               filteredServices = List.from(services);
//             });
//           } else {
//             _showError("Format incorrect des données reçues.");
//           }
//         } else {
//           _showError("Erreur API: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur serveur: Code ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur : $e");
//       debugPrint("❌ Exception Flutter : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier ✅"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           service.promotion != null
//                               ? Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text("Prix: ${service.prix}€", style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                               Text("Promo: ${service.getPrixAvecReduction()}€ 🔥", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                             ],
//                           )
//                               : Text("Prix: ${service.prix}€"),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? IconButton(icon: Icon(Icons.edit), onPressed: () => print("Modifier"))
//                           : IconButton(icon: Icon(Icons.shopping_cart, color: Colors.green), onPressed: () => _ajouterAuPanier(service)),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










//------------------------ce code fonction mais il faut rajouter les promotions-----------------
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
// import 'add_service_page.dart'; // Import de la page d'ajout
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'ID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString(); // Assure que c'est bien un String
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier ✅"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       )
//                           : IconButton(
//                         icon: const Icon(Icons.shopping_cart, color: Colors.green),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: isOwner
//           ? FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(
//                 coiffeuseId: widget.coiffeuseId,
//                 onServiceAdded: _fetchServices, // 🔥 Correction ajoutée ici
//               ),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       )
//           : null,
//
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'UUID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString(); // Assure que c'est bien un String
//     });
//
//     debugPrint("🟢 ID de l'utilisateur connecté : $currentUserId");
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     Provider.of<CartProvider>(context, listen: false).addToCart(service);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier ✅"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId != null && currentUserId == widget.coiffeuseId.toString();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: isOwner
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       )
//                           : IconButton(
//                         icon: const Icon(Icons.shopping_cart, color: Colors.green),
//                         onPressed: () => _ajouterAuPanier(service),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }








//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import '../../../services/providers/current_user_provider.dart';
// import 'edit_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   late int currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   /// **📌 Récupérer l'UUID de l'utilisateur actuel**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser!.idTblUser; // Stocke l'UUID de l'utilisateur connecté
//     });
//   }
//
//   /// **📡 Charger les services de la coiffeuse**
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services);
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   /// **🔍 Filtrer les services selon la recherche**
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   /// **🗑️ Supprimer un service**
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index);
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices();
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices();
//     }
//   }
//
//   /// **🛒 Ajouter un service au panier**
//   void _ajouterAuPanier(Service service) {
//     // 🔧 Ajouter ici la logique pour le panier (Exemple: appeler une API ou stocker localement)
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${service.intitule} ajouté au panier !"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     print("🔍 Vérification: currentUserId = $currentUserId, coiffeuseId = ${widget.coiffeuseId}");
//     bool isOwner = currentUserId.toString() == widget.coiffeuseId.toString();
//
//
//     //----------------------------------------------------------------------------------------
//     print('le id de current user est : '+currentUserId.toString());
//     print('le id de current la coiffeuse est : '+widget.coiffeuseId);
//
//     //-----------------------------------------------------------------------------------------
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: currentUserId == widget.coiffeuseId
//                           ? Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       )
//                           : IconButton(
//                         icon: const Icon(Icons.shopping_cart, color: Colors.green),
//                         //onPressed: () => _ajouterAuPanier(service),
//                           onPressed: ()
//                           {
//                             Provider.of<CartProvider>(context, listen: false).addToCart(service);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text("Service ajouté au panier ✅")),
//                             );
//                           },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//






















//--------------------------------------------Code fonctionel il faut l'updater----------------------------------
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import 'edit_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   List<Service> filteredServices = [];
//   TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//     _searchController.addListener(() {
//       _filterServices(_searchController.text);
//     });
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final responseData = json.decode(decodedBody);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//             filteredServices = List.from(services); // Initialise la liste affichée
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _filterServices(String query) {
//     setState(() {
//       filteredServices = services
//           .where((service) =>
//       service.intitule.toLowerCase().contains(query.toLowerCase()) ||
//           (service.description ?? '').toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }
//
//   Future<void> _deleteService(int serviceId, int index) async {
//     setState(() {
//       filteredServices.removeAt(index); // Suppression instantanée dans l'UI
//       services.removeWhere((service) => service.id == serviceId);
//     });
//
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode != 200) {
//         _showError("Erreur lors de la suppression.");
//         _fetchServices(); // Recharge si erreur
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//       _fetchServices(); // Recharge si erreur
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mes Services", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔎 Barre de recherche
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Rechercher un service...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔽 Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredServices.length,
//                 itemBuilder: (context, index) {
//                   final service = filteredServices[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => _deleteService(service.id, index),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId, onServiceAdded: _fetchServices),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import 'delete_service_page.dart';
// import 'edit_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Catégories", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Barre de recherche
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: "Rechercher un service...",
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.filter_list, size: 18),
//                   label: const Text("Filtrer"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Titre
//             const Text(
//               "Catégories de services",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             // Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: services.length,
//                 itemBuilder: (context, index) {
//                   final service = services[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Description: ${service.description.isNotEmpty ? service.description : 'Aucune description'}"),
//                           Text("Prix: ${service.prix} € | Temps: ${service.temps} min"),
//                         ],
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditServicePage(
//                                     service: service,
//                                     onServiceUpdated: _fetchServices,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () {
//                               setState(() {
//                                 services.removeAt(index); // 🔥 Suppression instantanée dans l'UI
//                               });
//
//                               deleteService(
//                                 context,
//                                 service.id,
//                                 _fetchServices, // 🔁 Rafraîchir en cas d'erreur
//                                     () {}, // 👌 Plus besoin de rafraîchir après suppression
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId, onServiceAdded: _fetchServices),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../../../models/services.dart';
//
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../models/services.dart';
// import 'edit_service_page.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<Service> services = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((json) => Service.fromJson(json))
//                 .toList();
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _deleteService(int serviceId) async {
//     final url = Uri.parse('http://192.168.0.248:8000/api/delete_service/$serviceId/');
//
//     try {
//       final response = await http.delete(url);
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ Service supprimé"), backgroundColor: Colors.green),
//         );
//         _fetchServices(); // Rafraîchir la liste après suppression
//       } else {
//         _showError("Erreur lors de la suppression.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Catégories")),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(child: ElevatedButton(onPressed: _fetchServices, child: const Text("Réessayer")))
//           : services.isEmpty
//           ? const Center(child: Text("Aucun service trouvé."))
//           : ListView.builder(
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final service = services[index];
//
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
//             child: ListTile(
//               title: Text(service.intitule),
//               subtitle: Text("Prix: ${service.prix}€ | Temps: ${service.temps} min"),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.edit, color: Colors.blue),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => EditServicePage(
//                             service: service,
//                             onServiceUpdated: _fetchServices,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.red),
//                     onPressed: () => _deleteService(service.id),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }













// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<dynamic> services = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = responseData['salon']['services'];
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Catégories", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Erreur de chargement",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _fetchServices,
//               child: const Text("Réessayer"),
//             ),
//           ],
//         ),
//       )
//           : services.isEmpty
//           ? const Center(
//         child: Text(
//           "Aucun service trouvé.",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Barre de recherche
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: "Rechercher un service...",
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.filter_list, size: 18),
//                   label: const Text("Filtrer"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Titre
//             const Text(
//               "Catégories de services",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             // Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: services.length,
//                 itemBuilder: (context, index) {
//                   final service = services[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service['intitule_service'],
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Text("Prix: ${service['prix']} € | Temps: ${service['temps_minutes']} min"),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId,onServiceAdded: _fetchServices,),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }






//------------------------------------------------------------------------------

// class AddServicePage extends StatefulWidget {
//   final String coiffeuseId;
//   final Function onServiceAdded; // Ajout d'un callback pour la mise à jour
//
//   const AddServicePage({Key? key, required this.coiffeuseId, required this.onServiceAdded}) : super(key: key);
//
//   @override
//   _AddServicePageState createState() => _AddServicePageState();
// }
//
// class _AddServicePageState extends State<AddServicePage> {
//   final TextEditingController _serviceController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _prixController = TextEditingController();
//   final TextEditingController _tempsController = TextEditingController();
//   bool _isLoading = false;
//
//   Future<void> _addService() async {
//     if (_serviceController.text.isEmpty ||
//         _prixController.text.isEmpty ||
//         _tempsController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez remplir tous les champs")),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final url = Uri.parse(
//         'http://192.168.0.248:8000/api/add_service_to_coiffeuse/${widget.coiffeuseId}/');
//
//     // ✅ Utilisation de la classe Service
//     Service newService = Service(
//       id: 0, // L'ID sera défini par la base de données
//       intitule: _serviceController.text,
//       description: _descriptionController.text,
//       prix: double.parse(_prixController.text),
//       temps: int.parse(_tempsController.text), prixFinal: 0,
//     );
//
//     final body = json.encode(newService.toJson()); // ✅ Conversion en JSON
//
//     print("🚀 Envoi de la requête POST à : $url");
//     print("📩 Données envoyées : $body");
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: body,
//       );
//
//       print("✅ Réponse reçue : ${response.statusCode}");
//       print("📩 Corps de la réponse : ${response.body}");
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("✅ Service ajouté avec succès !"),
//             backgroundColor: Colors.green, // ✅ MESSAGE EN VERT
//           ),
//         );
//
//         // ✅ Mettre à jour la liste avec le nouvel objet Service
//         widget.onServiceAdded();
//
//         // Fermer la page après succès
//         Navigator.pop(context);
//       } else {
//         final responseData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("❌ Erreur: ${responseData['message']}"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       print("❌ Erreur de connexion : $e");
//       ScaffoldMessenger.of(context)
//       .showSnackBar(
//         const SnackBar(
//           content: Text("Erreur de connexion au serveur."),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Ajouter un service")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//                 controller: _serviceController,
//                 decoration: const InputDecoration(labelText: "Nom du service")),
//             TextField(
//                 controller: _descriptionController,
//                 decoration: const InputDecoration(labelText: "Description")),
//             TextField(
//                 controller: _prixController,
//                 decoration: const InputDecoration(labelText: "Prix (€)"),
//                 keyboardType: TextInputType.number),
//             TextField(
//                 controller: _tempsController,
//                 decoration: const InputDecoration(labelText: "Temps (min)"),
//                 keyboardType: TextInputType.number),
//             const SizedBox(height: 20),
//             _isLoading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                 onPressed: _addService, child: const Text("Ajouter")),
//           ],
//         ),
//       ),
//     );
//   }
// }





































// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPageState();
// }
//
// class _ServicesListPageState extends State<ServicesListPage> {
//   List<dynamic> services = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = responseData['salon']['services'];
//           });
//         } else {
//           _showError("Erreur: ${responseData['message']}");
//         }
//       } else {
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Categories", style: TextStyle(color: Colors.orange)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Erreur de chargement",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _fetchServices,
//               child: const Text("Réessayer"),
//             ),
//           ],
//         ),
//       )
//           : services.isEmpty
//           ? const Center(
//         child: Text(
//           "Aucun service trouvé.",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Barre de recherche
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: "Search for services...",
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.filter_list, size: 18),
//                   label: const Text("Filter"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Titre
//             const Text(
//               "Categories of services",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             // Liste des services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: services.length,
//                 itemBuilder: (context, index) {
//                   final service = services[index];
//                   final color = Colors.primaries[index % Colors.primaries.length][100];
//                   return Card(
//                     color: color,
//                     margin: const EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: const Icon(Icons.miscellaneous_services, color: Colors.black),
//                       ),
//                       title: Text(
//                         service['intitule_service'],
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Text("Prix: ${service['prix']} € | Temps: ${service['temps_minutes']} min"),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'add_service_page.dart'; // Page pour ajouter un service
// import 'package:hairbnb/models/services.dart';
//
// class ServicesListPage extends StatefulWidget {
//   final String coiffeuseId;
//
//   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
//
//   @override
//   State<ServicesListPage> createState() => _ServicesListPage();
// }
//
// class _ServicesListPage extends State<ServicesListPage> {
//   List<Service> services = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuseId}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//
//         if (responseData['status'] == 'success') {
//           setState(() {
//             services = (responseData['salon']['services'] as List)
//                 .map((serviceJson) => Service.fromJson(serviceJson))
//                 .toList();
//           });
//         } else {
//           setState(() {
//             hasError = true;
//           });
//           _showError("Erreur : ${responseData['message']}");
//         }
//       } else {
//         setState(() {
//           hasError = true;
//         });
//         _showError("Erreur lors du chargement des services.");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _refreshData() async {
//     await _fetchServices();
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Liste des services"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Erreur de chargement",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _fetchServices,
//               child: const Text("Réessayer"),
//             ),
//           ],
//         ),
//       )
//           : services.isEmpty
//           ? const Center(
//         child: Text(
//           "Aucun service trouvé.",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _refreshData,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(8),
//           itemCount: services.length,
//           itemBuilder: (context, index) {
//             final service = services[index];
//             return Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       service.intitule,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Description : ${service.description}"),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("Prix : ${service.prix} €"),
//                         Text("Temps : ${service.temps} min"),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
//             ),
//           );
//
//           if (result == true) {
//             _fetchServices();
//           }
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import '../../../services/messages/messages_page.dart';
// // import 'add_service_page.dart'; // Nouvelle page pour ajouter un service
// //
// // class ServicesListPage extends StatefulWidget {
// //   final String coiffeuseId;
// //
// //   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
// //
// //   @override
// //   State<ServicesListPage> createState() => _ServicesListPageState();
// // }
// //
// // class _ServicesListPageState extends State<ServicesListPage> {
// //   List<dynamic> services = [];
// //   bool isLoading = false;
// //   bool hasError = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchServices();
// //   }
// //
// //   Future<void> _fetchServices() async {
// //     setState(() {
// //       isLoading = true;
// //       hasError = false;
// //     });
// //
// //     try {
// //       print('je suis la  ' + widget.coiffeuseId);
// //       final response = await http.get(
// //         Uri.parse('http://192.168.0.248:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
// //       );
// //
// //       if (response.statusCode == 200) {
// //         setState(() {
// //           services = json.decode(response.body);
// //         });
// //       } else {
// //         setState(() {
// //           hasError = true;
// //         });
// //         _showError("Erreur lors du chargement des services : ${response.body}");
// //       }
// //     } catch (e) {
// //       setState(() {
// //         hasError = true;
// //       });
// //       _showError("Erreur de connexion au serveur.");
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   Future<void> _refreshData() async {
// //     await _fetchServices();
// //   }
// //
// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Liste des services"),
// //       ),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : hasError
// //           ? Center(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text(
// //               "Erreur de chargement",
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 10),
// //             ElevatedButton(
// //               onPressed: _fetchServices,
// //               child: const Text("Réessayer"),
// //             ),
// //           ],
// //         ),
// //       )
// //           : services.isEmpty
// //           ? const Center(
// //         child: Text(
// //           "Aucun service trouvé.",
// //           style: TextStyle(fontSize: 16),
// //         ),
// //       )
// //           : RefreshIndicator(
// //         onRefresh: _refreshData,
// //         child: ListView.builder(
// //           padding: const EdgeInsets.all(8),
// //           itemCount: services.length,
// //           itemBuilder: (context, index) {
// //             final service = services[index];
// //             return Card(
// //               elevation: 4,
// //               margin: const EdgeInsets.symmetric(vertical: 8),
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       service['intitule_service'] ?? "Nom indisponible",
// //                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text("Prix : ${service['prix']?.toString() ?? 'Non défini'} €"),
// //                         Text("Temps : ${service['temps_minutes']?.toString() ?? 'Non défini'} min"),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () async {
// //           final result = await Navigator.push(
// //             context,
// //             MaterialPageRoute(
// //               builder: (context) => AddServicePage(coiffeuseId: widget.coiffeuseId),
// //             ),
// //           );
// //
// //           if (result == true) {
// //             _fetchServices();
// //           }
// //         },
// //         child: const Icon(Icons.add),
// //       ),
// //     );
// //   }
// // }
// //
// //
// // // class ServicesListPage extends StatefulWidget {
// // //   final String coiffeuseId;
// // //
// // //   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
// // //
// // //   @override
// // //   State<ServicesListPage> createState() => _ServicesListPageState();
// // // }
// // //
// // // class _ServicesListPageState extends State<ServicesListPage> {
// // //   List<dynamic> services = [];
// // //   bool isLoading = false;
// // //   bool hasError = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       final response = await http.get(
// // //         //Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
// // //         //+++++++++++++++++++++++++++++++++++++A modifier (supprimer) plutard++++++++++++++++++++++++++++++++++++++
// // //         Uri.parse('http://192.168.0.202:8000/api/coiffeuse_services/1/'),
// // //         //+++++++++++++++++++++++++++++++++++++A modifier plutard++++++++++++++++++++++++++++++++++++++
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         setState(() {
// // //           services = json.decode(response.body);
// // //         });
// // //       } else {
// // //         setState(() {
// // //           hasError = true;
// // //         });
// // //         showError("Erreur lors du chargement des services : ${response.body}",context);
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         hasError = true;
// // //       });
// // //       showError("Erreur de connexion au serveur.",context);
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   // void _showError(String message) {
// // //   //   ScaffoldMessenger.of(context).showSnackBar(
// // //   //     SnackBar(
// // //   //       content: Text(
// // //   //         message,
// // //   //         style: const TextStyle(color: Colors.white),
// // //   //       ),
// // //   //       backgroundColor: Colors.red,
// // //   //     ),
// // //   //   );
// // //   // }
// // //
// // //   Future<void> _refreshData() async {
// // //     await _fetchServices();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Liste des services"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : hasError
// // //           ? Center(
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             const Text(
// // //               "Erreur de chargement",
// // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             ElevatedButton(
// // //               onPressed: _fetchServices,
// // //               child: const Text("Réessayer"),
// // //             ),
// // //           ],
// // //         ),
// // //       )
// // //           : services.isEmpty
// // //           ? const Center(
// // //         child: Text(
// // //           "Aucun service trouvé.",
// // //           style: TextStyle(fontSize: 16),
// // //         ),
// // //       )
// // //           : RefreshIndicator(
// // //         onRefresh: _refreshData,
// // //         child: SingleChildScrollView(
// // //           scrollDirection: Axis.horizontal,
// // //           child: DataTable(
// // //             columns: const [
// // //               DataColumn(label: Text("Nom du service")),
// // //               DataColumn(label: Text("Prix (€)")),
// // //               DataColumn(label: Text("Temps (minutes)")),
// // //               DataColumn(label: Text("Actions")),
// // //             ],
// // //             rows: services.map((service) {
// // //               return DataRow(cells: [
// // //                 DataCell(
// // //                     Text(service['intitule_service'] ?? "Nom indisponible")),
// // //                 DataCell(Text(service['prix']?.toString() ?? "Non défini")),
// // //                 DataCell(Text(service['temps_minutes']?.toString() ??
// // //                     "Non défini")),
// // //                 DataCell(
// // //                   IconButton(
// // //                     icon: const Icon(Icons.edit),
// // //                     onPressed: () async {
// // //                       final result = await Navigator.push(
// // //                         context,
// // //                         MaterialPageRoute(
// // //                           builder: (context) =>
// // //                               EditServicePage(
// // //                                 service: service,
// // //                               ),
// // //                         ),
// // //                       );
// // //                       if (result == true) {
// // //                         // Rafraîchir la liste après modification
// // //                         _fetchServices();
// // //                       }
// // //                     },
// // //                   ),
// // //                 ),
// // //               ]);
// // //             }).toList(),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// // class EditServicePage extends StatefulWidget {
// //   final dynamic service;
// //
// //   const EditServicePage({Key? key, required this.service}) : super(key: key);
// //
// //   @override
// //   State<EditServicePage> createState() => _EditServicePageState();
// // }
// //
// // class _EditServicePageState extends State<EditServicePage> {
// //   late TextEditingController nameController;
// //   late TextEditingController descriptionController;
// //   late TextEditingController priceController;
// //   late TextEditingController durationController;
// //   bool isLoading = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     nameController =
// //         TextEditingController(text: widget.service['intitule_service']);
// //     descriptionController =
// //         TextEditingController(text: widget.service['description']);
// //     priceController =
// //         TextEditingController(text: widget.service['prix']?.toString() ?? '');
// //     durationController = TextEditingController(
// //         text: widget.service['temps_minutes']?.toString() ?? '');
// //   }
// //
// //   // Future<void> _saveChanges() async {
// //   //   if (nameController.text.isEmpty ||
// //   //       descriptionController.text.isEmpty ||
// //   //       priceController.text.isEmpty ||
// //   //       durationController.text.isEmpty) {
// //   //     _showError("Tous les champs sont obligatoires.");
// //   //     return;
// //   //   }
// //   //
// //   //   setState(() {
// //   //     isLoading = true;
// //   //   });
// //   //
// //   //   try {
// //   //     final response = await http.put(
// //   //       Uri.parse('http://127.0.0.1:8000/api/add_or_update_service/${widget
// //   //           .service['idTblService']}/'),
// //   //       headers: {'Content-Type': 'application/json'},
// //   //       body: json.encode({
// //   //         'intitule_service': nameController.text,
// //   //         'description': descriptionController.text,
// //   //         'prix': double.parse(priceController.text),
// //   //         'temps_minutes': int.parse(durationController.text),
// //   //       }),
// //   //     );
// //   //
// //   //     if (response.statusCode == 200) {
// //   //       ScaffoldMessenger.of(context).showSnackBar(
// //   //         const SnackBar(
// //   //           content: Text("Service mis à jour avec succès."),
// //   //           backgroundColor: Colors.green,
// //   //         ),
// //   //       );
// //   //       Navigator.pop(
// //   //           context, true); // Indique que les modifications ont été réussies
// //   //     } else {
// //   //       _showError("Erreur lors de la mise à jour : ${response.body}");
// //   //     }
// //   //   } catch (e) {
// //   //     _showError("Erreur de connexion au serveur.");
// //   //   } finally {
// //   //     setState(() {
// //   //       isLoading = false;
// //   //     });
// //   //   }
// //   // }
// //   //
// //   // void _showError(String message) {
// //   //   ScaffoldMessenger.of(context).showSnackBar(
// //   //     SnackBar(
// //   //       content: Text(
// //   //         message,
// //   //         style: const TextStyle(color: Colors.white),
// //   //       ),
// //   //       backgroundColor: Colors.red,
// //   //     ),
// //   //   );
// //   // }
// //
// //   Future<void> _saveChanges() async {
// //     if (nameController.text.isEmpty ||
// //         descriptionController.text.isEmpty ||
// //         priceController.text.isEmpty ||
// //         durationController.text.isEmpty) {
// //       showError("Tous les champs sont obligatoires je ss dans show services pages.",context);
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final url = widget.service['idTblService'] != null
// //           ? 'http://192.168.0.248:8000/api/add_or_update_service/${widget
// //           .service['idTblService']}/'
// //           : 'http://192.168.0.248:8000/api/add_or_update_service/';
// //
// //       final response = await http.put(
// //         Uri.parse(url),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'intitule_service': nameController.text,
// //           'description': descriptionController.text,
// //           'temps_minutes': int.parse(durationController.text),
// //           'prix': double.parse(priceController.text),
// //         }),
// //       );
// //
// //       if (response.statusCode == 200 || response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text("Service mis à jour avec succès."),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //         Navigator.pop(context, true); // Retour avec succès
// //       } else {
// //         showError("Erreur lors de la mise à jour : ${response.body}",context);
// //       }
// //     } catch (e) {
// //       showError("Erreur de connexion au serveur.",context);
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //   return Scaffold(
// //   appBar: AppBar(
// //   title: const Text("Modifier le service"),
// //   ),
// //   body: isLoading
// //   ? const Center(child: CircularProgressIndicator())
// //       : Padding(
// //   padding: const EdgeInsets.all(16.0),
// //   child: SingleChildScrollView(
// //   child: Column(
// //   crossAxisAlignment: CrossAxisAlignment.stretch,
// //   children: [
// //   TextField(
// //   controller: nameController,
// //   decoration: const InputDecoration(
// //   labelText: "Nom du service",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 10),
// //   TextField(
// //   controller: descriptionController,
// //   maxLines: 3,
// //   decoration: const InputDecoration(
// //   labelText: "Description",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 10),
// //   TextField(
// //   controller: priceController,
// //   keyboardType: TextInputType.number,
// //   decoration: const InputDecoration(
// //   labelText: "Prix (€)",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 10),
// //   TextField(
// //   controller: durationController,
// //   keyboardType: TextInputType.number,
// //   decoration: const InputDecoration(
// //   labelText: "Durée (minutes)",
// //   border: OutlineInputBorder(),
// //   ),
// //   ),
// //   const SizedBox(height: 20),
// //   ElevatedButton(
// //   onPressed: _saveChanges,
// //   child: const Text("Enregistrer les modifications"),
// //   ),
// //   ],
// //   ),
// //   ),
// //   ),
// //   );
// //   }
// //   }
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // //
// // // class ServicesListPage extends StatefulWidget {
// // //   final String coiffeuseId;
// // //
// // //   const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
// // //
// // //   @override
// // //   State<ServicesListPage> createState() => _ServicesListPageState();
// // // }
// // //
// // // class _ServicesListPageState extends State<ServicesListPage> {
// // //   List<dynamic> services = [];
// // //   bool isLoading = false;
// // //   bool hasError = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       final response = await http.get(
// // //         Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'),
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         setState(() {
// // //           services = json.decode(response.body);
// // //         });
// // //       } else {
// // //         setState(() {
// // //           hasError = true;
// // //         });
// // //         _showError("Erreur lors du chargement des services : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         hasError = true;
// // //       });
// // //       _showError("Erreur de connexion au serveur.");
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   void _showError(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(
// // //           message,
// // //           style: const TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Liste des services"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : hasError
// // //           ? Center(
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             const Text(
// // //               "Erreur de chargement",
// // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             ElevatedButton(
// // //               onPressed: _fetchServices,
// // //               child: const Text("Réessayer"),
// // //             ),
// // //           ],
// // //         ),
// // //       )
// // //           : services.isEmpty
// // //           ? const Center(
// // //         child: Text(
// // //           "Aucun service trouvé.",
// // //           style: TextStyle(fontSize: 16),
// // //         ),
// // //       )
// // //           : SingleChildScrollView(
// // //         scrollDirection: Axis.horizontal,
// // //         child: DataTable(
// // //           columns: const [
// // //             DataColumn(label: Text("Nom du service")),
// // //             DataColumn(label: Text("Prix (€)")),
// // //             DataColumn(label: Text("Temps (minutes)")),
// // //             DataColumn(label: Text("Actions")),
// // //           ],
// // //           rows: services.map((service) {
// // //             return DataRow(cells: [
// // //               DataCell(Text(service['intitule_service'] ?? "Nom indisponible")),
// // //               DataCell(Text(service['prix']?.toString() ?? "Non défini")),
// // //               DataCell(Text(service['temps_minutes']?.toString() ?? "Non défini")),
// // //               DataCell(
// // //                 IconButton(
// // //                   icon: const Icon(Icons.edit),
// // //                   onPressed: () {
// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                         builder: (context) => EditServicePage(
// // //                           service: service,
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //             ]);
// // //           }).toList(),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class EditServicePage extends StatefulWidget {
// // //   final dynamic service;
// // //
// // //   const EditServicePage({Key? key, required this.service}) : super(key: key);
// // //
// // //   @override
// // //   State<EditServicePage> createState() => _EditServicePageState();
// // // }
// // //
// // // class _EditServicePageState extends State<EditServicePage> {
// // //   late TextEditingController nameController;
// // //   late TextEditingController descriptionController;
// // //   late TextEditingController priceController;
// // //   late TextEditingController durationController;
// // //
// // //   bool isLoading = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     nameController = TextEditingController(text: widget.service['intitule_service']);
// // //     descriptionController = TextEditingController(text: widget.service['description']);
// // //     priceController = TextEditingController(text: widget.service['prix']?.toString() ?? '');
// // //     durationController = TextEditingController(text: widget.service['temps_minutes']?.toString() ?? '');
// // //   }
// // //
// // //   Future<void> _saveChanges() async {
// // //     if (nameController.text.isEmpty ||
// // //         descriptionController.text.isEmpty ||
// // //         priceController.text.isEmpty ||
// // //         durationController.text.isEmpty) {
// // //       _showError("Tous les champs sont obligatoires.");
// // //       return;
// // //     }
// // //
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('http://127.0.0.1:8000/api/update_service/${widget.service['idTblService']}/'),
// // //         body: json.encode({
// // //           'name': nameController.text,
// // //           'description': descriptionController.text,
// // //           'price': double.parse(priceController.text),
// // //           'minutes': int.parse(durationController.text),
// // //         }),
// // //         headers: {'Content-Type': 'application/json'},
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text(
// // //               "Service mis à jour avec succès.",
// // //               style: TextStyle(color: Colors.white),
// // //             ),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         Navigator.pop(context);
// // //       } else {
// // //         _showError("Erreur lors de la mise à jour : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       _showError("Erreur de connexion au serveur.");
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   void _showError(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(
// // //           "Erreur : $message\nURL : http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/",
// // //           style: const TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }
// // //
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Modifier le service"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           children: [
// // //             TextField(
// // //               controller: nameController,
// // //               decoration: const InputDecoration(labelText: "Nom du service"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: descriptionController,
// // //               maxLines: 3,
// // //               decoration: const InputDecoration(labelText: "Description"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: priceController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Prix (€)"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: durationController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Durée (minutes)"),
// // //             ),
// // //             const SizedBox(height: 20),
// // //             ElevatedButton(
// // //               onPressed: _saveChanges,
// // //               child: const Text("Enregistrer les modifications"),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // //
// // // class ServicesListPage extends StatefulWidget {
// // //   final String coiffeuseId;
// // //
// // //   const ServicesListPage({Key? key, this.coiffeuseId = "1"}) : super(key: key);
// // //
// // //   @override
// // //   State<ServicesListPage> createState() => _ServicesListPageState();
// // // }
// // //
// // // class _ServicesListPageState extends State<ServicesListPage> {
// // //   List<dynamic> services = [];
// // //   bool isLoading = false;
// // //   bool hasError = false;
// // //
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// // //       Navigator.push(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (context) => ServicesListPage(coiffeuseId: "1"), // Passer un ID valide
// // //         ),
// // //       );
// // //       //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// // //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'));
// // //
// // //       if (response.statusCode == 200) {
// // //         setState(() {
// // //           services = json.decode(response.body);
// // //         });
// // //       } else {
// // //         setState(() {
// // //           hasError = true;
// // //         });
// // //         _showError("Erreur lors du chargement des services : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         hasError = true;
// // //       });
// // //       _showError("Erreur de connexion au serveur.");
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   void _showError(String message) {
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       Navigator.push(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (context) => EditServicePage(service: null,),
// // //         ),
// // //       );
// // //     });
// // //   }
// // //
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Liste des services"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : hasError
// // //           ? Center(
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             const Text(
// // //               "Erreur de chargement",
// // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             ElevatedButton(
// // //               onPressed: _fetchServices,
// // //               child: const Text("Réessayer"),
// // //             ),
// // //           ],
// // //         ),
// // //       )
// // //           : services.isEmpty
// // //           ? const Center(
// // //         child: Text(
// // //           "Aucun service trouvé.",
// // //           style: TextStyle(fontSize: 16),
// // //         ),
// // //       )
// // //           : SingleChildScrollView(
// // //         scrollDirection: Axis.horizontal,
// // //         child: DataTable(
// // //           columns: const [
// // //             DataColumn(label: Text("Nom du service")),
// // //             DataColumn(label: Text("Prix (€)")),
// // //             DataColumn(label: Text("Temps (minutes)")),
// // //             DataColumn(label: Text("Actions")),
// // //           ],
// // //           rows: services.map((service) {
// // //             return DataRow(cells: [
// // //               DataCell(Text(service['intitule_service'] ?? "Nom indisponible")),
// // //               DataCell(Text(service['prix'] ?? "Non défini")),
// // //               DataCell(Text(service['temps_minutes']?.toString() ?? "Non défini")),
// // //               DataCell(
// // //                 IconButton(
// // //                   icon: const Icon(Icons.edit),
// // //                   onPressed: () {
// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                         builder: (context) => EditServicePage(
// // //                           service: service,
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //             ]);
// // //           }).toList(),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // // class EditServicePage extends StatefulWidget {
// // //   final dynamic service; // Les détails du service à modifier
// // //
// // //   const EditServicePage({Key? key, required this.service}) : super(key: key);
// // //
// // //   @override
// // //   State<EditServicePage> createState() => _EditServicePageState();
// // // }
// // //
// // // class _EditServicePageState extends State<EditServicePage> {
// // //   late TextEditingController nameController;
// // //   late TextEditingController descriptionController;
// // //   late TextEditingController priceController;
// // //   late TextEditingController durationController;
// // //
// // //   bool isLoading = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     nameController = TextEditingController(text: widget.service['intitule_service']);
// // //     descriptionController = TextEditingController(text: widget.service['description']);
// // //     priceController = TextEditingController(text: widget.service['prix']?.toString() ?? '');
// // //     durationController = TextEditingController(text: widget.service['temps_minutes']?.toString() ?? '');
// // //   }
// // //
// // //   Future<void> _saveChanges() async {
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('http://127.0.0.1:8000/api/update_service/${widget.service['idTblService']}/'),
// // //         body: json.encode({
// // //           'name': nameController.text,
// // //           'description': descriptionController.text,
// // //           'price': double.parse(priceController.text),
// // //           'minutes': int.parse(durationController.text),
// // //         }),
// // //         headers: {'Content-Type': 'application/json'},
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text(
// // //               "Service mis à jour avec succès.",
// // //               style: TextStyle(color: Colors.white),
// // //             ),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         Navigator.pop(context);
// // //       } else {
// // //         _showError("Erreur lors de la mise à jour : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       _showError("Erreur de connexion au serveur.");
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   void _showError(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(
// // //           message,
// // //           style: const TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Modifier le service"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           children: [
// // //             TextField(
// // //               controller: nameController,
// // //               decoration: const InputDecoration(labelText: "Nom du service"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: descriptionController,
// // //               maxLines: 3,
// // //               decoration: const InputDecoration(labelText: "Description"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: priceController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Prix (€)"),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: durationController,
// // //               keyboardType: TextInputType.number,
// // //               decoration: const InputDecoration(labelText: "Durée (minutes)"),
// // //             ),
// // //             const SizedBox(height: 20),
// // //             ElevatedButton(
// // //               onPressed: _saveChanges,
// // //               child: const Text("Enregistrer les modifications"),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // //
// // // class ServicesListPage extends StatefulWidget {
// // //   final String coiffeuseId; // ID de la coiffeuse
// // //
// // //   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// // //   // Changer plutard
// // //   //const ServicesListPage({Key? key, required this.coiffeuseId}) : super(key: key);
// // //   const ServicesListPage({Key? key, this.coiffeuseId="1"}) : super(key: key);
// // //   // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// // //
// // //   @override
// // //   State<ServicesListPage> createState() => _ServicesListPageState();
// // // }
// // //
// // // class _ServicesListPageState extends State<ServicesListPage> {
// // //   List<dynamic> services = [];
// // //   bool isLoading = false;
// // //   bool hasError = false;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchServices();
// // //   }
// // //
// // //   Future<void> _fetchServices() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //
// // //     try {
// // //       final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/coiffeuse_services/${widget.coiffeuseId}/'));
// // //
// // //       if (response.statusCode == 200) {
// // //         setState(() {
// // //           services = json.decode(response.body);
// // //         });
// // //       } else {
// // //         setState(() {
// // //           hasError = true;
// // //         });
// // //         _showError("Erreur lors du chargement des services : ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         hasError = true;
// // //       });
// // //       _showError("Erreur de connexion au serveur.");
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   void _showError(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(
// // //           message,
// // //           style: const TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Liste des services"),
// // //       ),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : hasError
// // //           ? Center(
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             const Text(
// // //               "Erreur de chargement",
// // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             ElevatedButton(
// // //               onPressed: _fetchServices,
// // //               child: const Text("Réessayer"),
// // //             ),
// // //           ],
// // //         ),
// // //       )
// // //           : services.isEmpty
// // //           ? const Center(
// // //         child: Text(
// // //           "Aucun service trouvé.",
// // //           style: TextStyle(fontSize: 16),
// // //         ),
// // //       )
// // //           : ListView.builder(
// // //         itemCount: services.length,
// // //         itemBuilder: (context, index) {
// // //           final service = services[index];
// // //           return Card(
// // //             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
// // //             child: ListTile(
// // //               title: Text(
// // //                 service['intitule_service'] ?? "Nom indisponible",
// // //                 style: const TextStyle(fontWeight: FontWeight.bold),
// // //               ),
// // //               subtitle: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text("Description : ${service['description'] ?? 'Non disponible'}"),
// // //                   const SizedBox(height: 4),
// // //                   Text("Durée : ${service['temps']?['minutes'] ?? '-'} minutes"),
// // //                   Text("Prix : ${service['prix']?['prix'] ?? '-'} €"),
// // //                 ],
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }
