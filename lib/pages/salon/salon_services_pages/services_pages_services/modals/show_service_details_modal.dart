// 📁 Fichier: show_service_details_modal.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';

Future<void> showServiceDetailsModal({
  required BuildContext context,
  required ServiceWithPromo serviceWithPromo,
  required bool isOwner,
  required VoidCallback onEdit,
  required VoidCallback onAddToCart,
}) async {
  // Fonction pour supprimer une promotion
  Future<void> deletePromotion(int promotionId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://www.hairbnb.site/api/delete_promotion/$promotionId/'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Rafraîchir les données après suppression
        Navigator.pop(context, true); // Indique qu'une mise à jour est nécessaire
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la suppression de la promotion"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Afficher le modal
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Récupérer toutes les promotions du service
          List<PromotionFull> allPromotions = serviceWithPromo.getAllPromotions();

          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
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
                      serviceWithPromo.intitule,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B61FF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      serviceWithPromo.description.isNotEmpty ? serviceWithPromo.description : "Pas de description",
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
                        const SizedBox(width: 8),
                        Text("${serviceWithPromo.temps} min", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
                        const SizedBox(width: 8),
                        serviceWithPromo.promotion_active != null
                            ? Row(
                          children: [
                            Text("${serviceWithPromo.prix} €",
                                style: const TextStyle(
                                    decoration: TextDecoration.lineThrough, color: Colors.red)),
                            const SizedBox(width: 6),
                            Text("${serviceWithPromo.prix_final.toStringAsFixed(2)} € 🔥",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        )
                            : Text("${serviceWithPromo.prix} €",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    // Section des promotions
                    if (allPromotions.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      const Text(
                        "Promotions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B61FF),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Liste des promotions
                      ...allPromotions.map((promo) {
                        // Déterminer le statut de la promotion
                        String statusText;
                        Color statusColor;

                        switch (promo.getCurrentStatus()) {
                          case "active":
                            statusText = "Active";
                            statusColor = Colors.green;
                            break;
                          case "future":
                            statusText = "À venir";
                            statusColor = Colors.orange;
                            break;
                          case "expired":
                            statusText = "Terminée";
                            statusColor = Colors.grey;
                            break;
                          default:
                            statusText = "Indéfini";
                            statusColor = Colors.grey;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: statusColor,
                              width: statusText == "Active" ? 2 : 1,
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
                                              color: statusText == "Active" ? statusColor : Colors.black87,
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
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
                                        "Du ${promo.dateDebut.toLocal().toString().split(' ')[0]} au ${promo.dateFin.toLocal().toString().split(' ')[0]}",
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                      if (statusText == "Active") ...[
                                        const SizedBox(height: 5),
                                        Text(
                                          "Prix promotionnel: ${(serviceWithPromo.prix * (1 - promo.pourcentage/100)).toStringAsFixed(2)} €",
                                          style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      // Afficher une boîte de dialogue de confirmation
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text("Supprimer la promotion"),
                                          content: const Text(
                                              "Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible."
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: const Text("Annuler"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                                deletePromotion(promo.id);
                                              },
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text("Supprimer"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isOwner)
                          ElevatedButton.icon(
                            onPressed: () {
                              debugPrint("🛒 EditService() called for service show_service_details_modal.dart : "
                                  "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                              Navigator.pop(context, true);
                              onEdit();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text("Modifier", style: TextStyle(color: Colors.white)),
                          ),
                        // if (!isOwner)
                        //   ElevatedButton.icon(
                        //     onPressed: () {
                        //       debugPrint("🛒 addToCart() called for service from show_service_details_modal.dart : "
                        //           "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                        //       Navigator.pop(context, true);  // Voici le problème! Retourne true, ce qui déclenche onEdit()
                        //       onAddToCart();
                        //     },
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: const Color(0xFF7B61FF),
                        //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        //     ),
                        //     icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        //     label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
                        //   ),

                        if (!isOwner)
                          ElevatedButton.icon(
                            onPressed: () {
                              debugPrint("🛒 addToCart() called for service from show_service_details_modal.dart : "
                                  "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                              Navigator.pop(context, false);  // Retourne false au lieu de true
                              onAddToCart();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                            label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
                          ),
                        //-----------------------------
                        // if (!isOwner)
                        //   ElevatedButton.icon(
                        //     onPressed: () {
                        //       debugPrint("🛒 addToCart() called for service from show_service_details_modal.dart : "
                        //           "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                        //       Navigator.pop(context, true);
                        //       onAddToCart();
                        //     },
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: const Color(0xFF7B61FF),
                        //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        //     ),
                        //     icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        //     label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
                        //   ),
                        //-------------------------------------------------------------------------
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // Si le résultat est true, la liste a été modifiée et nous devons rafraîchir
  if (result == true) {
    onEdit(); // Utiliser la callback onEdit pour rafraîchir la liste des services
  }
}






// // // 📁 Fichier: show_service_details_modal.dart
// // 📁 Fichier: show_service_details_modal.dart
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../../../models/services.dart';
// import '../../../../../models/promotion.dart';
//
// Future<void> showServiceDetailsModal({
//   required BuildContext context,
//   required Service service,
//   required bool isOwner,
//   required VoidCallback onEdit,
//   required VoidCallback onAddToCart,
// }) async {
//   // Fonction pour supprimer une promotion
//   Future<void> deletePromotion(int promotionId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('https://www.hairbnb.site/api/delete_promotion/$promotionId/'),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         // Rafraîchir les données après suppression
//         Navigator.pop(context, true); // Indique qu'une mise à jour est nécessaire
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la suppression de la promotion"), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   // Fonction pour récupérer toutes les promotions d'un service
//   Future<List<Promotion>> getPromotions(int serviceId) async {
//     try {
//       // DÉBOGAGE: Afficher l'URL pour vérifier que le service ID est correct
//       print("Récupération des promotions pour le service ID: $serviceId");
//
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_promotions_by_service/$serviceId/'),
//       );
//
//       // DÉBOGAGE: Afficher le code de statut et le corps de la réponse
//       print("Réponse du serveur: Code ${response.statusCode}");
//       print("Corps de la réponse: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
//         final promos = data.map((json) => Promotion.fromJson(json)).toList();
//
//         // DÉBOGAGE: Afficher le nombre de promotions récupérées
//         print("Nombre de promotions récupérées: ${promos.length}");
//
//         return promos;
//       } else if (response.statusCode == 404) {
//         // L'endpoint n'existe peut-être pas encore
//         print("L'endpoint pour récupérer les promotions n'existe pas (404)");
//         // Retourner une liste vide mais ne pas bloquer l'affichage
//         return [];
//       } else {
//         print("Erreur lors de la récupération des promotions: ${response.statusCode}");
//         return [];
//       }
//     } catch (e) {
//       print("Exception lors de la récupération des promotions: $e");
//       return [];
//     }
//   }
//
//   // Créer une liste de promotions de test si l'API n'est pas encore disponible
//   List<Promotion> createTestPromotions(int serviceId) {
//     final now = DateTime.now();
//     return [
//       // Promotion active
//       if (service.promotion != null) service.promotion!,
//
//       // Promotion future
//       Promotion(
//         id: 9999,
//         serviceId: serviceId,
//         pourcentage: 30.0,
//         dateDebut: now.add(const Duration(days: 7)),
//         dateFin: now.add(const Duration(days: 14)),
//       ),
//
//       // Promotion passée
//       Promotion(
//         id: 9998,
//         serviceId: serviceId,
//         pourcentage: 20.0,
//         dateDebut: now.subtract(const Duration(days: 30)),
//         dateFin: now.subtract(const Duration(days: 15)),
//       ),
//     ];
//   }
//
//   // Afficher le modal
//   final result = await showModalBottomSheet<bool>(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       // Utiliser une liste de promotions statique pour les tests si nécessaire
//       // final testPromotions = createTestPromotions(service.id);
//
//       return StatefulBuilder(
//         builder: (context, setState) {
//           return FutureBuilder<List<Promotion>>(
//             future: getPromotions(service.id),
//             builder: (context, snapshot) {
//               List<Promotion> allPromotions = [];
//
//               // DÉBOGAGE: Afficher l'état de la connexion
//               print("État de la connexion: ${snapshot.connectionState}");
//               print("Erreur snapshot: ${snapshot.error}");
//
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 // Afficher un indicateur de chargement pendant la récupération des promotions
//                 return const Center(
//                   child: CircularProgressIndicator(),
//                 );
//               } else if (snapshot.hasError) {
//                 // Afficher un message d'erreur dans la console
//                 print("Erreur lors du chargement des promotions: ${snapshot.error}");
//
//                 // Si la promotion active existe, l'ajouter à la liste
//                 if (service.promotion != null) {
//                   allPromotions = [service.promotion!];
//                 }
//               } else if (snapshot.hasData) {
//                 // Utiliser les données récupérées
//                 allPromotions = snapshot.data!;
//
//                 // Ajouter la promotion active si elle n'est pas déjà dans la liste
//                 if (service.promotion != null) {
//                   bool found = false;
//                   for (var promo in allPromotions) {
//                     if (promo.id == service.promotion!.id) {
//                       found = true;
//                       break;
//                     }
//                   }
//
//                   if (!found) {
//                     allPromotions.add(service.promotion!);
//                   }
//                 }
//               } else {
//                 // Si aucune donnée n'est disponible mais que le service a une promotion active
//                 if (service.promotion != null) {
//                   allPromotions = [service.promotion!];
//                 }
//               }
//
//               // UTILISER LES PROMOTIONS DE TEST SI AUCUNE N'EST TROUVÉE ET QUE NOUS SOMMES EN MODE DEBUG
//               if (allPromotions.isEmpty) {
//                 print("Aucune promotion trouvée, utilisation des promotions de test");
//                 allPromotions = createTestPromotions(service.id);
//               }
//
//               // Trier les promotions
//               final DateTime now = DateTime.now();
//               allPromotions.sort((a, b) {
//                 final bool aIsActive = now.isAfter(a.dateDebut) && now.isBefore(a.dateFin);
//                 final bool bIsActive = now.isAfter(b.dateDebut) && now.isBefore(b.dateFin);
//
//                 if (aIsActive && !bIsActive) return -1;
//                 if (!aIsActive && bIsActive) return 1;
//
//                 final bool aIsFuture = a.dateDebut.isAfter(now);
//                 final bool bIsFuture = b.dateDebut.isAfter(now);
//
//                 if (aIsFuture && !bIsFuture) return -1;
//                 if (!aIsFuture && bIsFuture) return 1;
//
//                 return a.dateDebut.compareTo(b.dateDebut);
//               });
//
//               return AnimatedPadding(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeOut,
//                 padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//                 child: DraggableScrollableSheet(
//                   expand: false,
//                   initialChildSize: 0.6,
//                   maxChildSize: 0.9,
//                   builder: (context, scrollController) => Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                     ),
//                     padding: const EdgeInsets.all(20),
//                     child: ListView(
//                       controller: scrollController,
//                       shrinkWrap: true,
//                       children: [
//                         Center(
//                           child: Container(
//                             width: 40,
//                             height: 5,
//                             margin: const EdgeInsets.only(bottom: 20),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[300],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                         Text(
//                           service.intitule,
//                           style: const TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF7B61FF),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           service.description.isNotEmpty ? service.description : "Pas de description",
//                           style: const TextStyle(fontSize: 16, color: Colors.black87),
//                         ),
//                         const SizedBox(height: 20),
//                         Row(
//                           children: [
//                             const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                             const SizedBox(width: 8),
//                             Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                             const SizedBox(width: 8),
//                             service.promotion != null
//                                 ? Row(
//                               children: [
//                                 Text("${service.prix} €",
//                                     style: const TextStyle(
//                                         decoration: TextDecoration.lineThrough, color: Colors.red)),
//                                 const SizedBox(width: 6),
//                                 Text("${service.getPrixAvecReduction().toStringAsFixed(2)} € 🔥",
//                                     style: const TextStyle(
//                                         fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                               ],
//                             )
//                                 : Text("${service.prix} €",
//                                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           ],
//                         ),
//
//                         // Section des promotions
//                         if (allPromotions.isNotEmpty) ...[
//                           const SizedBox(height: 30),
//                           const Text(
//                             "Promotions",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF7B61FF),
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Liste des promotions
//                           ...allPromotions.map((promo) {
//                             final DateTime now = DateTime.now();
//                             final bool isActive = now.isAfter(promo.dateDebut) && now.isBefore(promo.dateFin);
//                             final bool isFuture = promo.dateDebut.isAfter(now);
//
//                             Color statusColor = Colors.grey; // Par défaut (passées)
//                             String statusText = "Terminée";
//
//                             if (isActive) {
//                               statusColor = Colors.green;
//                               statusText = "Active";
//                             } else if (isFuture) {
//                               statusColor = Colors.orange;
//                               statusText = "À venir";
//                             }
//
//                             return Card(
//                               margin: const EdgeInsets.only(bottom: 10),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                                 side: BorderSide(
//                                   color: statusColor,
//                                   width: isActive ? 2 : 1,
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(12),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Text(
//                                                 "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
//                                                 style: TextStyle(
//                                                   fontSize: 16,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: isActive ? statusColor : Colors.black87,
//                                                 ),
//                                               ),
//                                               Container(
//                                                 margin: const EdgeInsets.only(left: 8),
//                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                                 decoration: BoxDecoration(
//                                                   color: statusColor,
//                                                   borderRadius: BorderRadius.circular(10),
//                                                 ),
//                                                 child: Text(
//                                                   statusText,
//                                                   style: const TextStyle(color: Colors.white, fontSize: 12),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(height: 5),
//                                           Text(
//                                             "Du ${promo.dateDebut.toLocal().toString().split(' ')[0]} au ${promo.dateFin.toLocal().toString().split(' ')[0]}",
//                                             style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                           ),
//                                           if (isActive) ...[
//                                             const SizedBox(height: 5),
//                                             Text(
//                                               "Prix promotionnel: ${(service.prix * (1 - promo.pourcentage/100)).toStringAsFixed(2)} €",
//                                               style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold),
//                                             ),
//                                           ],
//                                         ],
//                                       ),
//                                     ),
//                                     if (isOwner)
//                                       IconButton(
//                                         icon: const Icon(Icons.delete, color: Colors.red),
//                                         onPressed: () {
//                                           // Afficher une boîte de dialogue de confirmation
//                                           showDialog(
//                                             context: context,
//                                             builder: (dialogContext) => AlertDialog(
//                                               title: const Text("Supprimer la promotion"),
//                                               content: const Text(
//                                                   "Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible."
//                                               ),
//                                               actions: [
//                                                 TextButton(
//                                                   onPressed: () => Navigator.pop(dialogContext),
//                                                   child: const Text("Annuler"),
//                                                 ),
//                                                 TextButton(
//                                                   onPressed: () {
//                                                     Navigator.pop(dialogContext);
//                                                     deletePromotion(promo.id);
//                                                   },
//                                                   style: TextButton.styleFrom(foregroundColor: Colors.red),
//                                                   child: const Text("Supprimer"),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ],
//
//                         const SizedBox(height: 30),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             if (isOwner)
//                               ElevatedButton.icon(
//                                 onPressed: () {
//                                   Navigator.pop(context, true);
//                                   onEdit();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                                 ),
//                                 icon: const Icon(Icons.edit, color: Colors.white),
//                                 label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                               ),
//                             if (!isOwner)
//                               ElevatedButton.icon(
//                                 onPressed: () {
//                                   Navigator.pop(context, true);
//                                   onAddToCart();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF7B61FF),
//                                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                                 ),
//                                 icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                                 label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       );
//     },
//   );
//
//   // Si le résultat est true, la liste a été modifiée et nous devons rafraîchir
//   if (result == true) {
//     onEdit(); // Utiliser la callback onEdit pour rafraîchir la liste des services
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../../../models/services.dart';
// import '../../../../../models/promotion.dart';
//
// Future<void> showServiceDetailsModal({
//   required BuildContext context,
//   required Service service,
//   required bool isOwner,
//   required VoidCallback onEdit,
//   required VoidCallback onAddToCart,
// }) async {
//   // Fonction pour supprimer une promotion
//   Future<void> deletePromotion(int promotionId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('https://www.hairbnb.site/api/delete_promotion/$promotionId/'),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         // Rafraîchir les données après suppression
//         Navigator.pop(context, true); // Indique qu'une mise à jour est nécessaire
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la suppression de la promotion"), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   // Fonction pour récupérer toutes les promotions d'un service
//   Future<List<Promotion>> getPromotions(int serviceId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_promotions_by_service/$serviceId/'),
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
//         return data.map((json) => Promotion.fromJson(json)).toList();
//       }
//       return [];
//     } catch (e) {
//       print("Erreur lors de la récupération des promotions: $e");
//       return [];
//     }
//   }
//
//   // Afficher le modal
//   final result = await showModalBottomSheet<bool>(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return FutureBuilder<List<Promotion>>(
//         future: getPromotions(service.id),
//         builder: (context, snapshot) {
//           List<Promotion> allPromotions = [];
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             // Afficher un indicateur de chargement pendant la récupération des promotions
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             // Afficher un message d'erreur
//             print("Erreur lors du chargement des promotions: ${snapshot.error}");
//             allPromotions = [];
//           } else if (snapshot.hasData) {
//             // Utiliser les données récupérées
//             allPromotions = snapshot.data!;
//           }
//
//           // Trier les promotions : d'abord les actives, puis par date de début
//           final DateTime now = DateTime.now();
//           allPromotions.sort((a, b) {
//             // Vérifier si les promotions sont actives
//             final bool aIsActive = a.isActive();
//             final bool bIsActive = b.isActive();
//
//             if (aIsActive && !bIsActive) return -1; // a avant b
//             if (!aIsActive && bIsActive) return 1;  // b avant a
//
//             // Ensuite, trier par date de début (les plus proches en premier)
//             final aIsFuture = a.dateDebut.isAfter(now);
//             final bIsFuture = b.dateDebut.isAfter(now);
//
//             if (aIsFuture && !bIsFuture) return -1; // futures avant passées
//             if (!aIsFuture && bIsFuture) return 1;  // futures avant passées
//
//             // Enfin, trier par date de début
//             return a.dateDebut.compareTo(b.dateDebut);
//           });
//
//           return AnimatedPadding(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//             child: DraggableScrollableSheet(
//               expand: false,
//               maxChildSize: 0.9, // Permettre plus d'espace pour la liste des promotions
//               builder: (context, scrollController) => Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: ListView(
//                   controller: scrollController,
//                   shrinkWrap: true,
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
//                       service.intitule,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       service.description.isNotEmpty ? service.description : "Pas de description",
//                       style: const TextStyle(fontSize: 16, color: Colors.black87),
//                     ),
//                     const SizedBox(height: 20),
//                     Row(
//                       children: [
//                         const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                         const SizedBox(width: 8),
//                         Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                         const SizedBox(width: 8),
//                         service.promotion != null
//                             ? Row(
//                           children: [
//                             Text("${service.prix} €",
//                                 style: const TextStyle(
//                                     decoration: TextDecoration.lineThrough, color: Colors.red)),
//                             const SizedBox(width: 6),
//                             Text("${service.getPrixAvecReduction().toStringAsFixed(2)} € 🔥",
//                                 style: const TextStyle(
//                                     fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                           ],
//                         )
//                             : Text("${service.prix} €",
//                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//
//                     // Section des promotions
//                     if (allPromotions.isNotEmpty) ...[
//                       const SizedBox(height: 30),
//                       const Text(
//                         "Promotions",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF7B61FF),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//
//                       // Liste des promotions
//                       ...allPromotions.map((promo) {
//                         final bool isActive = promo.isActive();
//                         final bool isFuture = promo.dateDebut.isAfter(DateTime.now());
//                         final bool isPast = promo.dateFin.isBefore(DateTime.now());
//
//                         Color statusColor = Colors.grey; // Par défaut (passées)
//                         String statusText = "Terminée";
//
//                         if (isActive) {
//                           statusColor = Colors.green;
//                           statusText = "Active";
//                         } else if (isFuture) {
//                           statusColor = Colors.orange;
//                           statusText = "À venir";
//                         }
//
//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             side: BorderSide(
//                               color: statusColor,
//                               width: isActive ? 2 : 1,
//                             ),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Text(
//                                             "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                               color: isActive ? statusColor : Colors.black87,
//                                             ),
//                                           ),
//                                           Container(
//                                             margin: const EdgeInsets.only(left: 8),
//                                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                             decoration: BoxDecoration(
//                                               color: statusColor,
//                                               borderRadius: BorderRadius.circular(10),
//                                             ),
//                                             child: Text(
//                                               statusText,
//                                               style: const TextStyle(color: Colors.white, fontSize: 12),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 5),
//                                       Text(
//                                         "Du ${promo.dateDebut.toLocal().toString().split(' ')[0]} au ${promo.dateFin.toLocal().toString().split(' ')[0]}",
//                                         style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                       ),
//                                       if (isActive) ...[
//                                         const SizedBox(height: 5),
//                                         Text(
//                                           "Prix promotionnel: ${(service.prix * (1 - promo.pourcentage/100)).toStringAsFixed(2)} €",
//                                           style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                                 if (isOwner)
//                                   IconButton(
//                                     icon: const Icon(Icons.delete, color: Colors.red),
//                                     onPressed: () {
//                                       // Afficher une boîte de dialogue de confirmation
//                                       showDialog(
//                                         context: context,
//                                         builder: (dialogContext) => AlertDialog(
//                                           title: const Text("Supprimer la promotion"),
//                                           content: const Text(
//                                               "Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible."
//                                           ),
//                                           actions: [
//                                             TextButton(
//                                               onPressed: () => Navigator.pop(dialogContext),
//                                               child: const Text("Annuler"),
//                                             ),
//                                             TextButton(
//                                               onPressed: () {
//                                                 Navigator.pop(dialogContext);
//                                                 deletePromotion(promo.id);
//                                               },
//                                               style: TextButton.styleFrom(foregroundColor: Colors.red),
//                                               child: const Text("Supprimer"),
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ],
//
//                     const SizedBox(height: 30),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         if (isOwner)
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context, true);
//                               onEdit();
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             ),
//                             icon: const Icon(Icons.edit, color: Colors.white),
//                             label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                           ),
//                         if (!isOwner)
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context, true);
//                               onAddToCart();
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF7B61FF),
//                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             ),
//                             icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                             label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
//
//   // Si le résultat est true, la liste a été modifiée et nous devons rafraîchir
//   if (result == true) {
//     onEdit(); // Utiliser la callback onEdit pour rafraîchir la liste des services
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
// // // 📁 Fichier: show_service_details_modal.dart
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import '../../../../../models/services.dart';
// // import '../../../../../models/promotion.dart';
// //
// // Future<void> showServiceDetailsModal({
// //   required BuildContext context,
// //   required Service service,
// //   required bool isOwner,
// //   required VoidCallback onEdit,
// //   required VoidCallback onAddToCart,
// // }) async {
// //   // Fonction pour supprimer une promotion
// //   Future<void> deletePromotion(int promotionId) async {
// //     try {
// //       final response = await http.delete(
// //         Uri.parse('https://www.hairbnb.site/api/delete_promotion/$promotionId/'),
// //       );
// //
// //       if (response.statusCode == 200 || response.statusCode == 204) {
// //         // Rafraîchir les données après suppression
// //         Navigator.pop(context, true); // Indique qu'une mise à jour est nécessaire
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Erreur lors de la suppression de la promotion"), backgroundColor: Colors.red),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
// //       );
// //     }
// //   }
// //
// //   // Fonction pour récupérer toutes les promotions d'un service
// //   Future<List<Promotion>> getPromotions(int serviceId) async {
// //     try {
// //       final response = await http.get(
// //         Uri.parse('https://www.hairbnb.site/api/get_promotions_by_service/$serviceId/'),
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
// //         return data.map((json) => Promotion.fromJson(json)).toList();
// //       }
// //       return [];
// //     } catch (e) {
// //       print("Erreur lors de la récupération des promotions: $e");
// //       return [];
// //     }
// //   }
// //
// //   // Afficher le modal
// //   final result = await showModalBottomSheet<bool>(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) {
// //       return FutureBuilder<List<Promotion>>(
// //         future: getPromotions(service.id),
// //         builder: (context, snapshot) {
// //           // Liste de toutes les promotions incluant celle qui est active
// //           List<Promotion> allPromotions = [];
// //
// //           // Ajouter la promotion active si elle existe
// //           if (service.promotion != null) {
// //             allPromotions.add(service.promotion!);
// //           }
// //
// //           // Ajouter les autres promotions si elles sont disponibles
// //           if (snapshot.hasData) {
// //             // Filtrer pour éviter les doublons avec la promotion active
// //             final otherPromos = snapshot.data!.where(
// //                     (promo) => service.promotion == null || promo.id != service.promotion!.id
// //             ).toList();
// //
// //             allPromotions.addAll(otherPromos);
// //           }
// //
// //           return AnimatedPadding(
// //             duration: const Duration(milliseconds: 300),
// //             curve: Curves.easeOut,
// //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// //             child: DraggableScrollableSheet(
// //               expand: false,
// //               maxChildSize: 0.9, // Permettre plus d'espace pour la liste des promotions
// //               builder: (context, scrollController) => Container(
// //                 decoration: const BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //                 ),
// //                 padding: const EdgeInsets.all(20),
// //                 child: ListView(
// //                   controller: scrollController,
// //                   shrinkWrap: true,
// //                   children: [
// //                     Center(
// //                       child: Container(
// //                         width: 40,
// //                         height: 5,
// //                         margin: const EdgeInsets.only(bottom: 20),
// //                         decoration: BoxDecoration(
// //                           color: Colors.grey[300],
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                       ),
// //                     ),
// //                     Text(
// //                       service.intitule,
// //                       style: const TextStyle(
// //                         fontSize: 22,
// //                         fontWeight: FontWeight.bold,
// //                         color: Color(0xFF7B61FF),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 10),
// //                     Text(
// //                       service.description.isNotEmpty ? service.description : "Pas de description",
// //                       style: const TextStyle(fontSize: 16, color: Colors.black87),
// //                     ),
// //                     const SizedBox(height: 20),
// //                     Row(
// //                       children: [
// //                         const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
// //                         const SizedBox(width: 8),
// //                         Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 12),
// //                     Row(
// //                       children: [
// //                         const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
// //                         const SizedBox(width: 8),
// //                         service.promotion != null
// //                             ? Row(
// //                           children: [
// //                             Text("${service.prix} €",
// //                                 style: const TextStyle(
// //                                     decoration: TextDecoration.lineThrough, color: Colors.red)),
// //                             const SizedBox(width: 6),
// //                             Text("${service.getPrixAvecReduction().toStringAsFixed(2)} € 🔥",
// //                                 style: const TextStyle(
// //                                     fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
// //                           ],
// //                         )
// //                             : Text("${service.prix} €",
// //                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                       ],
// //                     ),
// //
// //                     // Section des promotions
// //                     if (allPromotions.isNotEmpty) ...[
// //                       const SizedBox(height: 30),
// //                       const Text(
// //                         "Promotions",
// //                         style: TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                           color: Color(0xFF7B61FF),
// //                         ),
// //                       ),
// //                       const SizedBox(height: 10),
// //
// //                       // Liste des promotions
// //                       ...allPromotions.map((promo) {
// //                         // Vérifier si c'est la promotion active
// //                         final bool isActive = service.promotion != null &&
// //                             promo.id == service.promotion!.id;
// //
// //                         return Card(
// //                           margin: const EdgeInsets.only(bottom: 10),
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(10),
// //                             side: BorderSide(
// //                               color: isActive ? Colors.green : Colors.grey.shade300,
// //                               width: isActive ? 2 : 1,
// //                             ),
// //                           ),
// //                           child: Padding(
// //                             padding: const EdgeInsets.all(12),
// //                             child: Row(
// //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                               children: [
// //                                 Expanded(
// //                                   child: Column(
// //                                     crossAxisAlignment: CrossAxisAlignment.start,
// //                                     children: [
// //                                       Row(
// //                                         children: [
// //                                           Text(
// //                                             "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
// //                                             style: TextStyle(
// //                                               fontSize: 16,
// //                                               fontWeight: FontWeight.bold,
// //                                               color: isActive ? Colors.green : Colors.black87,
// //                                             ),
// //                                           ),
// //                                           if (isActive)
// //                                             Container(
// //                                               margin: const EdgeInsets.only(left: 8),
// //                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //                                               decoration: BoxDecoration(
// //                                                 color: Colors.green,
// //                                                 borderRadius: BorderRadius.circular(10),
// //                                               ),
// //                                               child: const Text(
// //                                                 "Active",
// //                                                 style: TextStyle(color: Colors.white, fontSize: 12),
// //                                               ),
// //                                             ),
// //                                         ],
// //                                       ),
// //                                       const SizedBox(height: 5),
// //                                       Text(
// //                                         "Du ${promo.dateDebut.toLocal().toString().split(' ')[0]} au ${promo.dateFin.toLocal().toString().split(' ')[0]}",
// //                                         style: const TextStyle(fontSize: 14, color: Colors.grey),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                                 if (isOwner)
// //                                   IconButton(
// //                                     icon: const Icon(Icons.delete, color: Colors.red),
// //                                     onPressed: () {
// //                                       // Afficher une boîte de dialogue de confirmation
// //                                       showDialog(
// //                                         context: context,
// //                                         builder: (dialogContext) => AlertDialog(
// //                                           title: const Text("Supprimer la promotion"),
// //                                           content: const Text(
// //                                               "Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible."
// //                                           ),
// //                                           actions: [
// //                                             TextButton(
// //                                               onPressed: () => Navigator.pop(dialogContext),
// //                                               child: const Text("Annuler"),
// //                                             ),
// //                                             TextButton(
// //                                               onPressed: () {
// //                                                 Navigator.pop(dialogContext);
// //                                                 deletePromotion(promo.id);
// //                                               },
// //                                               style: TextButton.styleFrom(foregroundColor: Colors.red),
// //                                               child: const Text("Supprimer"),
// //                                             ),
// //                                           ],
// //                                         ),
// //                                       );
// //                                     },
// //                                   ),
// //                               ],
// //                             ),
// //                           ),
// //                         );
// //                       }).toList(),
// //                     ],
// //
// //                     const SizedBox(height: 30),
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.end,
// //                       children: [
// //                         if (isOwner)
// //                           ElevatedButton.icon(
// //                             onPressed: () {
// //                               Navigator.pop(context, true);
// //                               onEdit();
// //                             },
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: Colors.blue,
// //                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //                             ),
// //                             icon: const Icon(Icons.edit, color: Colors.white),
// //                             label: const Text("Modifier", style: TextStyle(color: Colors.white)),
// //                           ),
// //                         if (!isOwner)
// //                           ElevatedButton.icon(
// //                             onPressed: () {
// //                               Navigator.pop(context, true);
// //                               onAddToCart();
// //                             },
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: const Color(0xFF7B61FF),
// //                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //                             ),
// //                             icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
// //                             label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
// //                           ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       );
// //     },
// //   );
// //
// //   // Si le résultat est true, la liste a été modifiée et nous devons rafraîchir
// //   if (result == true) {
// //     onEdit(); // Utiliser la callback onEdit pour rafraîchir la liste des services
// //   }
// // }
//
//
//
//
//
// // // 📁 Fichier: show_service_details_modal.dart
// // import 'package:flutter/material.dart';
// // import '../../../../../models/services.dart';
// //
// // Future<void> showServiceDetailsModal({
// //   required BuildContext context,
// //   required Service service,
// //   required bool isOwner,
// //   required VoidCallback onEdit,
// //   required VoidCallback onAddToCart,
// // }) async {
// //   await showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) {
// //       return AnimatedPadding(
// //         duration: const Duration(milliseconds: 300),
// //         curve: Curves.easeOut,
// //         padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// //         child: DraggableScrollableSheet(
// //           expand: false,
// //           builder: (context, scrollController) => Container(
// //             decoration: const BoxDecoration(
// //               color: Colors.white,
// //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //             ),
// //             padding: const EdgeInsets.all(20),
// //             child: ListView(
// //               controller: scrollController,
// //               shrinkWrap: true,
// //               children: [
// //                 Center(
// //                   child: Container(
// //                     width: 40,
// //                     height: 5,
// //                     margin: const EdgeInsets.only(bottom: 20),
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey[300],
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                   ),
// //                 ),
// //                 Text(
// //                   service.intitule,
// //                   style: const TextStyle(
// //                     fontSize: 22,
// //                     fontWeight: FontWeight.bold,
// //                     color: Color(0xFF7B61FF),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 10),
// //                 Text(
// //                   service.description.isNotEmpty ? service.description : "Pas de description",
// //                   style: const TextStyle(fontSize: 16, color: Colors.black87),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 Row(
// //                   children: [
// //                     const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
// //                     const SizedBox(width: 8),
// //                     Text("${service.temps} min", style: const TextStyle(fontSize: 16)),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 12),
// //                 Row(
// //                   children: [
// //                     const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
// //                     const SizedBox(width: 8),
// //                     service.promotion != null
// //                         ? Row(
// //                       children: [
// //                         Text("${service.prix} €",
// //                             style: const TextStyle(
// //                                 decoration: TextDecoration.lineThrough, color: Colors.red)),
// //                         const SizedBox(width: 6),
// //                         Text("${service.getPrixAvecReduction()} € 🔥",
// //                             style: const TextStyle(
// //                                 fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
// //                       ],
// //                     )
// //                         : Text("${service.prix} €",
// //                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 30),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.end,
// //                   children: [
// //                     if (isOwner)
// //                       ElevatedButton.icon(
// //                         onPressed: () {
// //                           Navigator.pop(context);
// //                           onEdit();
// //                         },
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.blue,
// //                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //                         ),
// //                         icon: const Icon(Icons.edit, color: Colors.white),
// //                         label: const Text("Modifier", style: TextStyle(color: Colors.white)),
// //                       ),
// //                     if (!isOwner)
// //                       ElevatedButton.icon(
// //                         onPressed: () {
// //                           Navigator.pop(context);
// //                           onAddToCart();
// //                         },
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: const Color(0xFF7B61FF),
// //                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //                         ),
// //                         icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
// //                         label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
// //                       ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     },
// //   );
// // }
