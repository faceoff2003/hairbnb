import 'package:flutter/material.dart';
import 'package:hairbnb/models/promotion_full.dart';
import 'package:hairbnb/models/service_with_promo.dart';
import '../services/promotion_service.dart';

String getPromotionStatus(PromotionFull promo) {
  final now = DateTime.now();
  if (now.isBefore(promo.dateDebut)) return "future";
  if (now.isAfter(promo.dateFin)) return "expired";
  return "active";
}

Future<void> showAllPromotionsModal({
  required BuildContext context,
  required ServiceWithPromo serviceWithPromo,
  required VoidCallback onRefresh,
}) async {
  final result = await PromotionService.getAllPromotionsForService(serviceWithPromo);
  final List<PromotionFull> allPromotions = result['promotions'] ?? [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          String currentFilter = "Toutes";

          List<PromotionFull> getFilteredPromotions() {
            return allPromotions.where((promo) {
              final status = getPromotionStatus(promo);
              return currentFilter == "Toutes" ||
                  (currentFilter == "Actives" && status == "active") ||
                  (currentFilter == "À venir" && status == "future") ||
                  (currentFilter == "Expirées" && status == "expired");
            }).toList();
          }

          final filteredPromotions = getFilteredPromotions();

          int activeCount = allPromotions.where((p) => getPromotionStatus(p) == "active").length;
          int futureCount = allPromotions.where((p) => getPromotionStatus(p) == "future").length;
          int expiredCount = allPromotions.where((p) => getPromotionStatus(p) == "expired").length;

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Text(
                      'Promotions - ${serviceWithPromo.intitule}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B61FF),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtres
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("Toutes (${allPromotions.length})", currentFilter == "Toutes",
                                  () => setState(() => currentFilter = "Toutes")),
                          _buildFilterChip("Actives ($activeCount)", currentFilter == "Actives",
                                  () => setState(() => currentFilter = "Actives")),
                          _buildFilterChip("À venir ($futureCount)", currentFilter == "À venir",
                                  () => setState(() => currentFilter = "À venir")),
                          _buildFilterChip("Expirées ($expiredCount)", currentFilter == "Expirées",
                                  () => setState(() => currentFilter = "Expirées")),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Liste des promotions filtrées
                    Expanded(
                      child: filteredPromotions.isEmpty
                          ? Center(
                        child: Text(
                          'Aucune promotion ${currentFilter.toLowerCase()}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                          : ListView.builder(
                        controller: scrollController,
                        itemCount: filteredPromotions.length,
                        itemBuilder: (context, index) {
                          final promo = filteredPromotions[index];
                          final status = getPromotionStatus(promo);

                          Color statusColor = Colors.grey;
                          String statusText = "Expirée";

                          if (status == "active") {
                            statusColor = Colors.green;
                            statusText = "Active";
                          } else if (status == "future") {
                            statusColor = Colors.orange;
                            statusText = "À venir";
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: statusColor,
                                width: status == "active" ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Du ${promo.dateDebut.day}/${promo.dateDebut.month}/${promo.dateDebut.year} "
                                              "au ${promo.dateFin.day}/${promo.dateFin.month}/${promo.dateFin.year}",
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        if (status == "active") ...[
                                          const SizedBox(height: 5),
                                          Text(
                                            "Prix promotionnel: ${(serviceWithPromo.prix * (1 - promo.pourcentage / 100)).toStringAsFixed(2)} €",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        onPressed: () {
                                          // TODO: Implémenter showEditPromotionModal(promo)
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Édition à venir"),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Supprimer la promotion"),
                                              content: const Text("Confirmer la suppression ?"),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            final res = await PromotionService.deletePromotion(promo.id);

                                            if (!context.mounted) return; // ✅ Vérifie que le widget est toujours dans l’arbre

                                            if (res['success']) {
                                              Navigator.pop(context); // Fermer le modal
                                              onRefresh(); // Recharger les données
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(res['error'] ?? "Erreur"),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }


                                          // if (confirm == true) {
                                          //   final res = await PromotionService.deletePromotion(promo.id);
                                          //   if (res['success']) {
                                          //     Navigator.pop(context); // Fermer le modal
                                          //     onRefresh(); // Recharger les données
                                          //   } else {
                                          //     ScaffoldMessenger.of(context).showSnackBar(
                                          //       SnackBar(
                                          //         content: Text(res['error'] ?? "Erreur"),
                                          //         backgroundColor: Colors.red,
                                          //       ),
                                          //     );
                                          //   }
                                          // }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFF7B61FF).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF7B61FF) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}






// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/promotion_full.dart';
// import 'package:hairbnb/models/service_with_promo.dart';
//
// import '../services/promotion_service.dart';
//
// String getPromotionStatus(PromotionFull promo) {
//   final now = DateTime.now();
//   if (now.isBefore(promo.dateDebut)) return "future";
//   if (now.isAfter(promo.dateFin)) return "expired";
//   return "active";
// }
//
// Future<void> showAllPromotionsModal({
//   required BuildContext context,
//   required ServiceWithPromo serviceWithPromo,
//   required VoidCallback onRefresh,
// }) async {
//   final result = await PromotionService.getAllPromotionsForService(serviceWithPromo);
//   final List<PromotionFull> allPromotions = result['promotions'];
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           String currentFilter = "Toutes";
//
//           List<PromotionFull> getFilteredPromotions() {
//             return allPromotions.where((promo) {
//               final status = getPromotionStatus(promo);
//               return currentFilter == "Toutes" ||
//                   (currentFilter == "Actives" && status == "active") ||
//                   (currentFilter == "À venir" && status == "future") ||
//                   (currentFilter == "Expirées" && status == "expired");
//             }).toList();
//           }
//
//           final filteredPromotions = getFilteredPromotions();
//
//           int activeCount = allPromotions.where((p) => getPromotionStatus(p) == "active").length;
//           int futureCount = allPromotions.where((p) => getPromotionStatus(p) == "future").length;
//           int expiredCount = allPromotions.where((p) => getPromotionStatus(p) == "expired").length;
//
//           return DraggableScrollableSheet(
//             initialChildSize: 0.7,
//             maxChildSize: 0.9,
//             minChildSize: 0.5,
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     Text(
//                       'Promotions - ${serviceWithPromo.intitule}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: [
//                           _buildFilterChip("Toutes (${allPromotions.length})", currentFilter == "Toutes",
//                                   () => setState(() => currentFilter = "Toutes")),
//                           _buildFilterChip("Actives ($activeCount)", currentFilter == "Actives",
//                                   () => setState(() => currentFilter = "Actives")),
//                           _buildFilterChip("À venir ($futureCount)", currentFilter == "À venir",
//                                   () => setState(() => currentFilter = "À venir")),
//                           _buildFilterChip("Expirées ($expiredCount)", currentFilter == "Expirées",
//                                   () => setState(() => currentFilter = "Expirées")),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Expanded(
//                       child: filteredPromotions.isEmpty
//                           ? Center(
//                         child: Text(
//                           'Aucune promotion ${currentFilter.toLowerCase()}',
//                           style: TextStyle(
//                             fontStyle: FontStyle.italic,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       )
//                           : ListView.builder(
//                         controller: scrollController,
//                         itemCount: filteredPromotions.length,
//                         itemBuilder: (context, index) {
//                           final promo = filteredPromotions[index];
//                           final status = getPromotionStatus(promo);
//
//                           Color statusColor = Colors.grey;
//                           String statusText = "Expirée";
//
//                           if (status == "active") {
//                             statusColor = Colors.green;
//                             statusText = "Active";
//                           } else if (status == "future") {
//                             statusColor = Colors.orange;
//                             statusText = "À venir";
//                           }
//
//                           return Card(
//                             margin: const EdgeInsets.only(bottom: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               side: BorderSide(
//                                 color: statusColor,
//                                 width: status == "active" ? 2 : 1,
//                               ),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Text(
//                                               "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                                 color: status == "active" ? statusColor : Colors.black87,
//                                               ),
//                                             ),
//                                             Container(
//                                               margin: const EdgeInsets.only(left: 8),
//                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                               decoration: BoxDecoration(
//                                                 color: statusColor,
//                                                 borderRadius: BorderRadius.circular(10),
//                                               ),
//                                               child: Text(
//                                                 statusText,
//                                                 style: const TextStyle(color: Colors.white, fontSize: 12),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 5),
//                                         Text(
//                                           "Du ${promo.dateDebut.day}/${promo.dateDebut.month}/${promo.dateDebut.year} "
//                                               "au ${promo.dateFin.day}/${promo.dateFin.month}/${promo.dateFin.year}",
//                                           style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                         ),
//                                         if (status == "active") ...[
//                                           const SizedBox(height: 5),
//                                           Text(
//                                             "Prix promotionnel: ${(serviceWithPromo.prix * (1 - promo.pourcentage / 100)).toStringAsFixed(2)} €",
//                                             style: TextStyle(
//                                               fontSize: 14,
//                                               color: statusColor,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                   Row(
//                                     children: [
//                                       IconButton(
//                                         icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
//                                         onPressed: () {
//                                           // TODO: Implémenter l'édition
//                                         },
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//                                         onPressed: () {
//                                           // TODO: Implémenter la suppression
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       );
//     },
//   );
// }
//
// Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
//   return Padding(
//     padding: const EdgeInsets.only(right: 8.0),
//     child: ChoiceChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (_) => onTap(),
//       backgroundColor: Colors.grey.shade200,
//       selectedColor: const Color(0xFF7B61FF).withOpacity(0.2),
//       labelStyle: TextStyle(
//         color: isSelected ? const Color(0xFF7B61FF) : Colors.black,
//         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//       ),
//     ),
//   );
// }
//
//







//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../../../../../models/services.dart';
// import '../../../../../models/promotion.dart';
//
// Future<void> showAllPromotionsModal({
//   required BuildContext context,
//   required Service service,
//   required VoidCallback onRefresh,
// }) async {
//   // Cette fonction va générer toutes les promotions (actives, futures, expirées)
//   List<Promotion> generateAllPromotions() {
//     List<Promotion> allPromotions = [];
//
//     // Ajouter la promotion active si elle existe
//     if (service.promotion != null) {
//       allPromotions.add(service.promotion!);
//     }
//
//     // Créer un exemple de promotion expirée (Pour démonstration)
//     final now = DateTime.now();
//     final expiredPromo = Promotion(
//       id: -1, // ID négatif pour les exemples
//       serviceId: service.id,
//       pourcentage: 15.0,
//       dateDebut: now.subtract(const Duration(days: 30)),
//       dateFin: now.subtract(const Duration(days: 15)),
//       isActiveValue: false,
//     );
//
//     // Créer un exemple de promotion future (Pour démonstration)
//     final futurePromo = Promotion(
//       id: -2,
//       serviceId: service.id,
//       pourcentage: 25.0,
//       dateDebut: now.add(const Duration(days: 15)),
//       dateFin: now.add(const Duration(days: 30)),
//       isActiveValue: false,
//     );
//
//     // Ajouter ces exemples
//     allPromotions.add(expiredPromo);
//     allPromotions.add(futurePromo);
//
//     return allPromotions;
//   }
//
//   // Obtenir toutes les promotions
//   final List<Promotion> allPromotions = generateAllPromotions();
//
//   // Afficher le modal avec filtrage
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           // État pour le filtre sélectionné
//           String currentFilter = "Toutes";
//
//           // Filtrer les promotions selon le filtre sélectionné
//           List<Promotion> getFilteredPromotions() {
//             final now = DateTime.now();
//
//             switch (currentFilter) {
//               case "Actives":
//                 return allPromotions.where((p) =>
//                 now.isAfter(p.dateDebut) && now.isBefore(p.dateFin)
//                 ).toList();
//
//               case "À venir":
//                 return allPromotions.where((p) =>
//                     now.isBefore(p.dateDebut)
//                 ).toList();
//
//               case "Expirées":
//                 return allPromotions.where((p) =>
//                     now.isAfter(p.dateFin)
//                 ).toList();
//
//               default: // "Toutes"
//                 return allPromotions;
//             }
//           }
//
//           // Obtenir les promotions filtrées
//           final filteredPromotions = getFilteredPromotions();
//
//           // Compter les différents types
//           final now = DateTime.now();
//           int activeCount = allPromotions.where((p) =>
//           now.isAfter(p.dateDebut) && now.isBefore(p.dateFin)
//           ).length;
//
//           int futureCount = allPromotions.where((p) =>
//               now.isBefore(p.dateDebut)
//           ).length;
//
//           int expiredCount = allPromotions.where((p) =>
//               now.isAfter(p.dateFin)
//           ).length;
//
//           return DraggableScrollableSheet(
//             initialChildSize: 0.7,
//             maxChildSize: 0.9,
//             minChildSize: 0.5,
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // En-tête et barre de filtres
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//
//                     Text(
//                       'Promotions - ${service.intitule}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Barre de filtres
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: [
//                           _buildFilterChip(
//                               "Toutes (${allPromotions.length})",
//                               currentFilter == "Toutes",
//                                   () => setState(() => currentFilter = "Toutes")
//                           ),
//                           _buildFilterChip(
//                               "Actives ($activeCount)",
//                               currentFilter == "Actives",
//                                   () => setState(() => currentFilter = "Actives")
//                           ),
//                           _buildFilterChip(
//                               "À venir ($futureCount)",
//                               currentFilter == "À venir",
//                                   () => setState(() => currentFilter = "À venir")
//                           ),
//                           _buildFilterChip(
//                               "Expirées ($expiredCount)",
//                               currentFilter == "Expirées",
//                                   () => setState(() => currentFilter = "Expirées")
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Liste des promotions
//                     Expanded(
//                       child: filteredPromotions.isEmpty
//                           ? Center(
//                         child: Text(
//                           'Aucune promotion ${currentFilter.toLowerCase()}',
//                           style: TextStyle(
//                             fontStyle: FontStyle.italic,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       )
//                           : ListView.builder(
//                         controller: scrollController,
//                         itemCount: filteredPromotions.length,
//                         itemBuilder: (context, index) {
//                           final promo = filteredPromotions[index];
//
//                           // Déterminer le statut de la promotion
//                           final now = DateTime.now();
//                           final bool isActive = now.isAfter(promo.dateDebut) && now.isBefore(promo.dateFin);
//                           final bool isFuture = now.isBefore(promo.dateDebut);
//
//                           Color statusColor = Colors.grey;
//                           String statusText = "Expirée";
//
//                           if (isActive) {
//                             statusColor = Colors.green;
//                             statusText = "Active";
//                           } else if (isFuture) {
//                             statusColor = Colors.orange;
//                             statusText = "À venir";
//                           }
//
//                           return Card(
//                             margin: const EdgeInsets.only(bottom: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               side: BorderSide(
//                                 color: statusColor,
//                                 width: isActive ? 2 : 1,
//                               ),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Text(
//                                               "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                                 color: isActive ? statusColor : Colors.black87,
//                                               ),
//                                             ),
//                                             Container(
//                                               margin: const EdgeInsets.only(left: 8),
//                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                               decoration: BoxDecoration(
//                                                 color: statusColor,
//                                                 borderRadius: BorderRadius.circular(10),
//                                               ),
//                                               child: Text(
//                                                 statusText,
//                                                 style: const TextStyle(color: Colors.white, fontSize: 12),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 5),
//                                         Text(
//                                           "Du ${promo.dateDebut.day}/${promo.dateDebut.month}/${promo.dateDebut.year} au ${promo.dateFin.day}/${promo.dateFin.month}/${promo.dateFin.year}",
//                                           style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                         ),
//                                         if (isActive) ...[
//                                           const SizedBox(height: 5),
//                                           Text(
//                                             "Prix promotionnel: ${(service.prix * (1 - promo.pourcentage/100)).toStringAsFixed(2)} €",
//                                             style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold),
//                                           ),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//
//                                   // Boutons d'action
//                                   if (promo.id > 0) // Seulement pour les vraies promotions
//                                     Row(
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
//                                           onPressed: () {
//                                             // Fonction d'édition
//                                           },
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//                                           onPressed: () {
//                                             // Fonction de suppression
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       );
//     },
//   );
// }
//
// // Widget pour les onglets de filtre
// Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
//   return Padding(
//     padding: const EdgeInsets.only(right: 8.0),
//     child: ChoiceChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (_) => onTap(),
//       backgroundColor: Colors.grey.shade200,
//       selectedColor: const Color(0xFF7B61FF).withOpacity(0.2),
//       labelStyle: TextStyle(
//         color: isSelected ? const Color(0xFF7B61FF) : Colors.black,
//         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//       ),
//     ),
//   );
// }






// // lib/ui/widgets/promotion_modals.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/services.dart';
// import '../../../../../models/promotion.dart';
// import '../../services_pages_services/modals/create_promotion_modal.dart';
// import '../Widgets/promotion_dialogs_widget.dart';
// import '../Widgets/promotion_item_widget.dart';
// import '../services/promotion_service.dart';
//
//
// Future<void> showAllPromotionsModal({
//   required BuildContext context,
//   required Service service,
//   required VoidCallback onRefresh,
// }) async {
//   print("Modal: Ouverture modale pour service ${service.id} (${service.intitule})");
//
//   final result = await PromotionService.getAllPromotionsForService(service);
//   final List<Promotion> promotions = result['promotions'] ?? [];
//
//   // Compter le nombre de chaque type
//   int activeCount = 0, futureCount = 0, expiredCount = 0;
//   for (var promo in promotions) {
//     if (PromotionService.isPromotionActive(promo)) activeCount++;
//     else if (PromotionService.isPromotionFuture(promo)) futureCount++;
//     else expiredCount++;
//   }
//
//   print("Modal: Promotions - Actives: $activeCount, Futures: $futureCount, Expirées: $expiredCount");
//
//   if (promotions.isEmpty && result['error'] != null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Erreur: ${result['error']}"),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           // État pour filtrer les promotions
//           String currentFilter = "Toutes"; // Options: "Toutes", "Actives", "À venir", "Expirées"
//
//           // Fonction pour filtrer les promotions selon le filtre actuel
//           List<Promotion> getFilteredPromotions() {
//             switch (currentFilter) {
//               case "Actives":
//                 return promotions.where((p) => PromotionService.isPromotionActive(p)).toList();
//               case "À venir":
//                 return promotions.where((p) => PromotionService.isPromotionFuture(p)).toList();
//               case "Expirées":
//                 return promotions.where((p) =>
//                 !PromotionService.isPromotionActive(p) &&
//                     !PromotionService.isPromotionFuture(p)).toList();
//               default:
//                 return promotions;
//             }
//           }
//
//           final filteredPromotions = getFilteredPromotions();
//
//           return DraggableScrollableSheet(
//             initialChildSize: 0.7,
//             maxChildSize: 0.9,
//             minChildSize: 0.5,
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             'Promotions - ${service.intitule}',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF7B61FF),
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.add_circle, color: Color(0xFF7B61FF)),
//                           onPressed: () {
//                             Navigator.pop(context);
//                             showCreatePromotionModal(
//                               context: context,
//                               serviceId: service.id,
//                               onPromoAdded: onRefresh,
//                             );
//                           },
//                           tooltip: 'Ajouter une promotion',
//                         ),
//                       ],
//                     ),
//
//                     // Filtres
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: [
//                           _buildFilterChip("Toutes ($activeCount+$futureCount+$expiredCount)", currentFilter == "Toutes", () {
//                             setState(() {
//                               currentFilter = "Toutes";
//                             });
//                           }),
//                           _buildFilterChip("Actives ($activeCount)", currentFilter == "Actives", () {
//                             setState(() {
//                               currentFilter = "Actives";
//                             });
//                           }),
//                           _buildFilterChip("À venir ($futureCount)", currentFilter == "À venir", () {
//                             setState(() {
//                               currentFilter = "À venir";
//                             });
//                           }),
//                           _buildFilterChip("Expirées ($expiredCount)", currentFilter == "Expirées", () {
//                             setState(() {
//                               currentFilter = "Expirées";
//                             });
//                           }),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//                     Expanded(
//                       child: filteredPromotions.isEmpty
//                           ? Center(
//                         child: Text(
//                           'Aucune promotion ${currentFilter.toLowerCase()} pour ce service',
//                           style: TextStyle(
//                             fontStyle: FontStyle.italic,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       )
//                           : ListView.builder(
//                         controller: scrollController,
//                         itemCount: filteredPromotions.length,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 10),
//                             child: PromotionItem(
//                               promotion: filteredPromotions[index],
//                               service: service,
//                               isHighlighted: service.promotion != null &&
//                                   filteredPromotions[index].id == service.promotion!.id,
//                               onDelete: () {
//                                 Navigator.pop(context);
//                                 showDeletePromotionDialog(
//                                   context: context,
//                                   promotion: filteredPromotions[index],
//                                   onSuccess: onRefresh,
//                                 );
//                               },
//                               onEdit: () {
//                                 Navigator.pop(context);
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text("L'édition de promotion sera disponible prochainement"),
//                                     backgroundColor: Colors.orange,
//                                   ),
//                                 );
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       );
//     },
//   );
// }
//
// Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected) {
//   return Padding(
//     padding: const EdgeInsets.only(right: 8),
//     child: ChoiceChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (_) => onSelected(),
//       backgroundColor: Colors.grey.shade200,
//       selectedColor: const Color(0xFF7B61FF).withOpacity(0.2),
//       labelStyle: TextStyle(
//         color: isSelected ? const Color(0xFF7B61FF) : Colors.black,
//         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//       ),
//     ),
//   );
// }

// Future<void> showAllPromotionsModal({
//   required BuildContext context,
//   required Service service,
//   required VoidCallback onRefresh,
// }) async {
//   final result = await PromotionService.getAllPromotionsForService(service);
//   final List<Promotion> promotions = result['promotions'] ?? [];
//
//   if (promotions.isEmpty && result['error'] != null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Erreur: ${result['error']}"),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           return DraggableScrollableSheet(
//             initialChildSize: 0.7,
//             maxChildSize: 0.9,
//             minChildSize: 0.5,
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             'Promotions - ${service.intitule}',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF7B61FF),
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//
//
//                         IconButton(
//                           icon: const Icon(Icons.add_circle, color: Color(0xFF7B61FF)),
//                           onPressed: () {
//                             Navigator.pop(context);
//                             showCreatePromotionModal(
//                               context: context,
//                               serviceId: service.id,
//                               onPromoAdded: onRefresh,
//                             );
//                           },
//                           tooltip: 'Ajouter une promotion',
//                         ),
//
//                       ],
//
//                     ),
//                     const SizedBox(height: 16),
//                     Expanded(
//                       child: promotions.isEmpty
//                           ? Center(
//                         child: Text(
//                           'Aucune promotion pour ce service',
//                           style: TextStyle(
//                             fontStyle: FontStyle.italic,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       )
//                           : ListView.builder(
//                         controller: scrollController,
//                         itemCount: promotions.length,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 10),
//                             child: PromotionItem(
//                               promotion: promotions[index],
//                               service: service,
//                               isHighlighted: service.promotion != null &&
//                                   promotions[index].id == service.promotion!.id,
//                               onDelete: () {
//                                 Navigator.pop(context);
//                                 showDeletePromotionDialog(
//                                   context: context,
//                                   promotion: promotions[index],
//                                   onSuccess: onRefresh,
//                                 );
//                               },
//                               onEdit: () {
//                                 Navigator.pop(context);
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text("L'édition de promotion sera disponible prochainement"),
//                                     backgroundColor: Colors.orange,
//                                   ),
//                                 );
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       );
//     },
//   );
// }
