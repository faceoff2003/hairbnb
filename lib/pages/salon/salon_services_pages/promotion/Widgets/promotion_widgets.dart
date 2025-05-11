// 📁 lib/ui/widgets/promotion_widgets.dart
import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';
import '../../services_pages_services/modals/create_promotion_modal.dart';
import '../modals/show_all_promotions_modal.dart';
import '../utils/date_formatter.dart';
import 'promotion_dialogs_widget.dart';

class PromotionItem extends StatelessWidget {
  final PromotionFull promotion;
  final ServiceWithPromo service;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isCompact;

  const PromotionItem({
    super.key,
    required this.promotion,
    required this.service,
    required this.onDelete,
    required this.onEdit,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = promotion.getCurrentStatus();
    final statusColor = status == 'active'
        ? const Color(0xFF4CAF50)
        : (status == 'future' ? const Color(0xFFFF9800) : Colors.grey);
    final discount = promotion.pourcentage;
    final discountedPrice = service.prix * (1 - discount / 100);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_offer,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${discount.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DateFormatter.formatDate(promotion.dateDebut)} → ${DateFormatter.formatDate(promotion.dateFin)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (status == 'active')
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      Text(
                        'Actuel: ${discountedPrice.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (status == 'future')
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Color(0xFFFF9800)),
                      const SizedBox(width: 4),
                      Text(
                        'À venir: ${discountedPrice.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (status == 'expired')
                  Row(
                    children: [
                      Icon(Icons.event_busy, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Expiré',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: const Color(0xFF7B61FF),
                tooltip: 'Modifier',
                onPressed: onEdit,
                splashRadius: 24,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.redAccent,
                tooltip: 'Supprimer',
                onPressed: onDelete,
                splashRadius: 24,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ServicePromotionCard extends StatelessWidget {
  final ServiceWithPromo service;
  final VoidCallback onRefresh;

  const ServicePromotionCard({
    super.key,
    required this.service,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivePromo = service.promotion_active != null;
    final futurePromos = service.promotions_a_venir;
    final bool hasPromos = hasActivePromo || futurePromos.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.spa,
                    color: Color(0xFF7B61FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.intitule,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF7B61FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.temps} min',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Icon(
                            Icons.euro,
                            size: 14,
                            color: Color(0xFF7B61FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.prix} €',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    showCreatePromotionModal(
                      context: context,
                      serviceId: service.id,
                      onPromoAdded: onRefresh,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 4),
                      Text('Promo'),
                    ],
                  ),
                ),
              ],
            ),
            if (hasPromos) const Divider(height: 30),

            // Active promotion
            if (hasActivePromo)
              PromotionItem(
                promotion: service.promotion_active!,
                service: service,
                isCompact: true,
                onDelete: () => showDeletePromotionDialog(
                  context: context,
                  promotionFull: service.promotion_active!,
                  onSuccess: onRefresh,
                ),
                onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("L'édition de promotion sera disponible prochainement"),
                    backgroundColor: Color(0xFFFF9800),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),

            // Future promotions
            ...futurePromos.take(2).map((promo) => PromotionItem(
              promotion: promo,
              service: service,
              isCompact: true,
              onDelete: () => showDeletePromotionDialog(
                context: context,
                promotionFull: promo,
                onSuccess: onRefresh,
              ),
              onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("L'édition de promotion sera disponible prochainement"),
                  backgroundColor: Color(0xFFFF9800),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            )),

            // View all button
            if (futurePromos.length > 2 || hasActivePromo)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => showAllPromotionsModal(
                      context: context,
                      serviceWithPromo: service,
                      onRefresh: onRefresh,
                    ),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Voir toutes les promotions'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      foregroundColor: const Color(0xFF7B61FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFF7B61FF).withOpacity(0.1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}








// // 📁 lib/ui/widgets/promotion_widgets.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
// import '../../services_pages_services/modals/create_promotion_modal.dart';
// import '../modals/show_all_promotions_modal.dart';
// import '../services/promotion_service.dart';
// import '../utils/date_formatter.dart';
// import 'promotion_dialogs_widget.dart';
//
// class PromotionItem extends StatelessWidget {
//   final PromotionFull promotion;
//   final ServiceWithPromo service;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//   final bool isCompact;
//
//   const PromotionItem({
//     super.key,
//     required this.promotion,
//     required this.service,
//     required this.onDelete,
//     required this.onEdit,
//     this.isCompact = true,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final status = promotion.getCurrentStatus();
//     final statusColor = status == 'active'
//         ? Colors.green
//         : (status == 'future' ? Colors.orange : Colors.grey);
//     final discount = promotion.pourcentage;
//     final discountedPrice = service.prix * (1 - discount / 100);
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: statusColor.withOpacity(0.4)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Icon(Icons.local_offer, size: 16, color: statusColor),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '-${discount.toStringAsFixed(0)}% • ${DateFormatter.formatDate(promotion.dateDebut)} → ${DateFormatter.formatDate(promotion.dateFin)}',
//                   style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
//                 ),
//                 if (status == 'active')
//                   Text(
//                     'Actuel: ${discountedPrice.toStringAsFixed(2)} €',
//                     style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
//                   )
//               ],
//             ),
//           ),
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert, size: 18),
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'edit',
//                 child: Text('Modifier'),
//               ),
//               const PopupMenuItem(
//                 value: 'delete',
//                 child: Text('Supprimer'),
//               ),
//             ],
//             onSelected: (value) {
//               if (value == 'edit') onEdit();
//               if (value == 'delete') onDelete();
//             },
//           )
//         ],
//       ),
//     );
//   }
// }
//
// class ServicePromotionCard extends StatelessWidget {
//   final ServiceWithPromo service;
//   final VoidCallback onRefresh;
//
//   const ServicePromotionCard({
//     super.key,
//     required this.service,
//     required this.onRefresh,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final hasActivePromo = service.promotion_active != null;
//     final futurePromos = service.promotions_a_venir;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(service.intitule,
//                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//                       const SizedBox(height: 4),
//                       Text('${service.temps} min • ${service.prix} €',
//                           style: TextStyle(color: Colors.grey[700], fontSize: 12)),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add, color: Color(0xFF7B61FF)),
//                   onPressed: () {
//                     showCreatePromotionModal(
//                       context: context,
//                       serviceId: service.id,
//                       onPromoAdded: onRefresh,
//                     );
//                   },
//                 ),
//               ],
//             ),
//             const Divider(),
//             if (hasActivePromo)
//               PromotionItem(
//                 promotion: service.promotion_active!,
//                 service: service,
//                 isCompact: true,
//                 onDelete: () => showDeletePromotionDialog(
//                   context: context,
//                   promotionFull: service.promotion_active!,
//                   onSuccess: onRefresh,
//                 ),
//                 onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text("L'édition de promotion sera disponible prochainement"),
//                     backgroundColor: Colors.orange,
//                   ),
//                 ),
//               ),
//             ...futurePromos.take(2).map((promo) => PromotionItem(
//               promotion: promo,
//               service: service,
//               isCompact: true,
//               onDelete: () => showDeletePromotionDialog(
//                 context: context,
//                 promotionFull: promo,
//                 onSuccess: onRefresh,
//               ),
//               onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text("L'édition de promotion sera disponible prochainement"),
//                   backgroundColor: Colors.orange,
//                 ),
//               ),
//             )),
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton.icon(
//                 onPressed: () => showAllPromotionsModal(
//                   context: context,
//                   serviceWithPromo: service,
//                   onRefresh: onRefresh,
//                 ),
//                 icon: const Icon(Icons.calendar_month, size: 16),
//                 label: const Text('Voir tout'),
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   foregroundColor: const Color(0xFF7B61FF),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }









// // 📁 lib/ui/widgets/promotion_widgets.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
// import '../../services_pages_services/modals/create_promotion_modal.dart';
// import '../modals/show_all_promotions_modal.dart';
// import '../utils/date_formatter.dart';
// import 'promotion_dialogs_widget.dart';
//
// class PromotionStatusBadge extends StatelessWidget {
//   final PromotionFull promotion;
//   final bool isCompact;
//
//   const PromotionStatusBadge({
//     super.key,
//     required this.promotion,
//     this.isCompact = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final status = promotion.getCurrentStatus();
//
//     // Configuration selon le statut
//     final Map<String, Map<String, dynamic>> statusConfig = {
//       'active': {
//         'color': Colors.green,
//         'text': 'Active',
//         'icon': Icons.check_circle_rounded
//       },
//       'future': {
//         'color': Colors.orange,
//         'text': 'À venir',
//         'icon': Icons.schedule
//       },
//       'expired': {
//         'color': Colors.grey,
//         'text': 'Terminée',
//         'icon': Icons.event_busy
//       },
//     };
//
//     final config = statusConfig[status] ?? statusConfig['expired']!;
//
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: isCompact ? 6 : 8,
//         vertical: isCompact ? 1 : 3,
//       ),
//       decoration: BoxDecoration(
//         color: config['color'],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (!isCompact) Icon(
//             config['icon'],
//             color: Colors.white,
//             size: 12,
//           ),
//           if (!isCompact) const SizedBox(width: 4),
//           Text(
//             config['text'],
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: isCompact ? 10 : 12,
//               fontWeight: isCompact ? FontWeight.normal : FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class PromotionItem extends StatelessWidget {
//   final PromotionFull promotion;
//   final ServiceWithPromo service;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//   final bool isHighlighted;
//   final bool isCompact;
//
//   const PromotionItem({
//     super.key,
//     required this.promotion,
//     required this.service,
//     required this.onDelete,
//     required this.onEdit,
//     this.isHighlighted = false,
//     this.isCompact = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final status = promotion.getCurrentStatus();
//     final statusColor = status == 'active'
//         ? Colors.green
//         : (status == 'future' ? Colors.orange : Colors.grey);
//
//     final double discount = promotion.pourcentage;
//     final double discountedPrice = service.prix * (1 - discount / 100);
//
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: statusColor.withOpacity(isHighlighted ? 0.3 : 0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//         border: Border.all(
//           color: statusColor.withOpacity(isHighlighted ? 0.8 : 0.3),
//           width: isHighlighted ? 2 : 1,
//         ),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: EdgeInsets.all(isCompact ? 8 : 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Promotion percentage and status
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Text(
//                           '-${discount.toStringAsFixed(0)}%',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: statusColor,
//                             fontSize: isCompact ? 13 : 15,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       PromotionStatusBadge(
//                         promotion: promotion,
//                         isCompact: isCompact,
//                       ),
//                     ],
//                   ),
//
//                   // Action buttons
//                   if (!isCompact)
//                     Row(
//                       children: [
//                         IconButton(
//                           constraints: const BoxConstraints(),
//                           padding: const EdgeInsets.all(8),
//                           icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
//                           tooltip: 'Modifier',
//                           onPressed: onEdit,
//                         ),
//                         IconButton(
//                           constraints: const BoxConstraints(),
//                           padding: const EdgeInsets.all(8),
//                           icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
//                           tooltip: 'Supprimer',
//                           onPressed: onDelete,
//                         ),
//                       ],
//                     )
//                   else
//                     PopupMenuButton(
//                       padding: EdgeInsets.zero,
//                       icon: const Icon(Icons.more_vert, size: 18),
//                       itemBuilder: (context) => [
//                         const PopupMenuItem(
//                           value: 'edit',
//                           child: Row(
//                             children: [
//                               Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
//                               SizedBox(width: 8),
//                               Text('Modifier'),
//                             ],
//                           ),
//                         ),
//                         const PopupMenuItem(
//                           value: 'delete',
//                           child: Row(
//                             children: [
//                               Icon(Icons.delete_outline, size: 18, color: Colors.red),
//                               SizedBox(width: 8),
//                               Text('Supprimer'),
//                             ],
//                           ),
//                         ),
//                       ],
//                       onSelected: (value) {
//                         if (value == 'edit') {
//                           onEdit();
//                         } else if (value == 'delete') {
//                           onDelete();
//                         }
//                       },
//                     ),
//                 ],
//               ),
//
//               const SizedBox(height: 8),
//
//               // Date range
//               Row(
//                 children: [
//                   Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${DateFormatter.formatDate(promotion.dateDebut)} - ${DateFormatter.formatDate(promotion.dateFin)}',
//                     style: TextStyle(
//                       fontSize: isCompact ? 11 : 12,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ],
//               ),
//
//               // Show discounted price if active
//               if (status == 'active' && !isCompact)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 6),
//                   child: Row(
//                     children: [
//                       Icon(Icons.euro, size: 14, color: statusColor),
//                       const SizedBox(width: 4),
//                       RichText(
//                         text: TextSpan(
//                           style: DefaultTextStyle.of(context).style,
//                           children: [
//                             TextSpan(
//                               text: '${service.prix}€ ',
//                               style: const TextStyle(
//                                 decoration: TextDecoration.lineThrough,
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             TextSpan(
//                               text: '${discountedPrice.toStringAsFixed(2)}€',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                                 color: statusColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class ServicePromotionCard extends StatelessWidget {
//   final ServiceWithPromo service;
//   final VoidCallback onRefresh;
//   final bool isCompact;
//
//   const ServicePromotionCard({
//     super.key,
//     required this.service,
//     required this.onRefresh,
//     this.isCompact = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final hasActivePromo = service.promotion_active != null;
//     final hasFuturePromos = service.promotions_a_venir.isNotEmpty;
//     final futurePromoCount = service.promotions_a_venir.length;
//
//     // Limite d'affichage des promotions à venir en mode compact
//     final maxPreviewPromos = isCompact ? 1 : 2;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Material(
//           color: Colors.transparent,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Service header with gradient background
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       const Color(0xFF7B61FF),
//                       const Color(0xFF7B61FF).withOpacity(0.8),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Service info
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             service.intitule,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               // Duration
//                               const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
//                               const SizedBox(width: 4),
//                               Text(
//                                 '${service.temps} min',
//                                 style: const TextStyle(color: Colors.white70, fontSize: 12),
//                               ),
//                               const SizedBox(width: 16),
//
//                               // Price
//                               const Icon(Icons.euro, color: Colors.white70, size: 14),
//                               const SizedBox(width: 4),
//                               hasActivePromo
//                                   ? Row(
//                                 children: [
//                                   Text(
//                                     '${service.prix}€',
//                                     style: const TextStyle(
//                                       decoration: TextDecoration.lineThrough,
//                                       color: Colors.white54,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     '${service.prix_final}€',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               )
//                                   : Text(
//                                 '${service.prix}€',
//                                 style: const TextStyle(color: Colors.white, fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Add promo button
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         showCreatePromotionModal(
//                           context: context,
//                           serviceId: service.id,
//                           onPromoAdded: onRefresh,
//                         );
//                       },
//                       icon: const Icon(Icons.add, size: 16),
//                       label: const Text('Promo'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: const Color(0xFF7B61FF),
//                         elevation: 0,
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
//                         minimumSize: const Size(60, 30),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Active promotion section
//               if (hasActivePromo)
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(Icons.local_offer, size: 16, color: Colors.green),
//                           const SizedBox(width: 6),
//                           const Text(
//                             'Promotion active',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const Spacer(),
//                           // Badge avec pourcentage
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '-${service.promotion_active!.pourcentage.toStringAsFixed(0)}%',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       PromotionItem(
//                         promotion: service.promotion_active!,
//                         service: service,
//                         isHighlighted: true,
//                         isCompact: isCompact,
//                         onDelete: () => showDeletePromotionDialog(
//                           context: context,
//                           promotionFull: service.promotion_active!,
//                           onSuccess: onRefresh,
//                         ),
//                         onEdit: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("L'édition de promotion sera disponible prochainement"),
//                               backgroundColor: Colors.orange,
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//
//               // Future promotions preview
//               if (hasFuturePromos)
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(Icons.event_available, size: 16, color: Colors.orange),
//                           const SizedBox(width: 6),
//                           Text(
//                             'Promotions à venir (${service.promotions_a_venir.length})',
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       ...service.promotions_a_venir
//                           .take(maxPreviewPromos)
//                           .map((promo) => PromotionItem(
//                         promotion: promo,
//                         service: service,
//                         isCompact: true,
//                         onDelete: () => showDeletePromotionDialog(
//                           context: context,
//                           promotionFull: promo,
//                           onSuccess: onRefresh,
//                         ),
//                         onEdit: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("L'édition de promotion sera disponible prochainement"),
//                               backgroundColor: Colors.orange,
//                             ),
//                           );
//                         },
//                       )),
//                       if (futurePromoCount > maxPreviewPromos)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8),
//                           child: Text(
//                             '+ ${futurePromoCount - maxPreviewPromos} autres promotions à venir',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontStyle: FontStyle.italic,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//               // View all button
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
//                 child: Center(
//                   child: TextButton.icon(
//                     onPressed: () => showAllPromotionsModal(
//                       context: context,
//                       serviceWithPromo: service,
//                       onRefresh: onRefresh,
//                     ),
//                     icon: const Icon(Icons.calendar_month, size: 16),
//                     label: const Text('Voir toutes les promotions'),
//                     style: TextButton.styleFrom(
//                       foregroundColor: const Color(0xFF7B61FF),
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         side: const BorderSide(color: Color(0xFF7B61FF), width: 1),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






// // 📁 lib/ui/widgets/promotion_widgets.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
// import '../../services_pages_services/modals/create_promotion_modal.dart';
// import '../modals/show_all_promotions_modal.dart';
// import '../services/promotion_service.dart';
// import '../utils/date_formatter.dart';
// import 'promotion_dialogs_widget.dart';
//
// class PromotionStatusBadge extends StatelessWidget {
//   final PromotionFull promotion;
//
//   const PromotionStatusBadge({super.key, required this.promotion});
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = PromotionService.isPromotionActive(promotion);
//     final bool isFuture = PromotionService.isPromotionFuture(promotion);
//
//     Color statusColor = Colors.grey;
//     String statusText = "Terminée";
//
//     if (isActive) {
//       statusColor = Colors.green;
//       statusText = "Active";
//     } else if (isFuture) {
//       statusColor = Colors.orange;
//       statusText = "À venir";
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: statusColor,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         statusText,
//         style: const TextStyle(color: Colors.white, fontSize: 12),
//       ),
//     );
//   }
// }
//
// class PromotionItem extends StatelessWidget {
//   final PromotionFull promotion;
//   final ServiceWithPromo service;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//   final bool isHighlighted;
//
//   const PromotionItem({
//     super.key,
//     required this.promotion,
//     required this.service,
//     required this.onDelete,
//     required this.onEdit,
//     this.isHighlighted = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = PromotionService.isPromotionActive(promotion);
//     final bool isFuture = PromotionService.isPromotionFuture(promotion);
//
//     Color statusColor = Colors.grey;
//
//     if (isActive) {
//       statusColor = Colors.green;
//     } else if (isFuture) {
//       statusColor = Colors.orange;
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: statusColor.withAlpha(25),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isHighlighted ? statusColor : statusColor.withAlpha(128),
//           width: isHighlighted ? 2 : 1,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       '${promotion.pourcentage.toStringAsFixed(0)}% de réduction',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: isActive ? statusColor : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     PromotionStatusBadge(promotion: promotion),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Du ${DateFormatter.formatDate(promotion.dateDebut)} au ${DateFormatter.formatDate(promotion.dateFin)}',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                 ),
//                 if (isActive)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Text(
//                       'Prix actuel: ${(service.prix * (1 - promotion.pourcentage / 100)).toStringAsFixed(2)} €',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
//                 onPressed: onEdit,
//                 constraints: const BoxConstraints(),
//                 padding: const EdgeInsets.all(8),
//                 tooltip: 'Modifier',
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//                 onPressed: onDelete,
//                 constraints: const BoxConstraints(),
//                 padding: const EdgeInsets.all(8),
//                 tooltip: 'Supprimer',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ServicePromotionCard extends StatelessWidget {
//   final ServiceWithPromo service;
//   final VoidCallback onRefresh;
//
//   const ServicePromotionCard({
//     super.key,
//     required this.service,
//     required this.onRefresh,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final Color primaryViolet = const Color(0xFF7B61FF);
//     final hasActivePromo = service.promotion_active != null;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: hasActivePromo ? Colors.green : Colors.grey.shade300,
//           width: hasActivePromo ? 2 : 1,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     service.intitule,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: primaryViolet,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.add_circle, color: primaryViolet),
//                   onPressed: () {
//                     showCreatePromotionModal(
//                       context: context,
//                       serviceId: service.id,
//                       onPromoAdded: onRefresh,
//                     );
//                   },
//                   tooltip: 'Ajouter une promotion',
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.timer, color: Colors.grey[600], size: 18),
//                 const SizedBox(width: 4),
//                 Text('${service.temps} min', style: TextStyle(color: Colors.grey[600])),
//                 const SizedBox(width: 16),
//                 Icon(Icons.euro, color: Colors.grey[600], size: 18),
//                 const SizedBox(width: 4),
//                 Text('${service.prix} €', style: TextStyle(color: Colors.grey[600])),
//               ],
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Promotions',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//
//             if (hasActivePromo)
//               PromotionItem(
//                 promotion: service.promotion_active!,
//                 service: service,
//                 isHighlighted: true,
//                 onDelete: () => showDeletePromotionDialog(
//                   context: context,
//                   promotionFull: service.promotion_active!,
//                   onSuccess: onRefresh,
//                 ),
//                 onEdit: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("L'édition de promotion sera disponible prochainement"),
//                       backgroundColor: Colors.orange,
//                     ),
//                   );
//                 },
//               )
//             else
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 8),
//                 child: Text(
//                   'Aucune promotion active',
//                   style: TextStyle(
//                     fontStyle: FontStyle.italic,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ),
//
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton.icon(
//                 onPressed: () => showAllPromotionsModal(
//                   context: context,
//                   serviceWithPromo: service,
//                   onRefresh: onRefresh,
//                 ),
//                 icon: const Icon(Icons.calendar_month),
//                 label: const Text('Voir toutes les promotions'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }








// // 📁 lib/ui/widgets/promotion_widgets.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/services.dart';
// import '../../../../../models/promotion.dart';
// import '../../services_pages_services/modals/create_promotion_modal.dart';
// import '../modals/show_all_promotions_modal.dart';
// import '../services/promotion_service.dart';
// import '../utils/date_formatter.dart';
// import 'promotion_dialogs_widget.dart';
//
// class PromotionStatusBadge extends StatelessWidget {
//   final Promotion promotion;
//
//   const PromotionStatusBadge({super.key, required this.promotion});
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = PromotionService.isPromotionActive(promotion);
//     final bool isFuture = PromotionService.isPromotionFuture(promotion);
//
//     Color statusColor = Colors.grey; // Par défaut (passées)
//     String statusText = "Terminée";
//
//     if (isActive) {
//       statusColor = Colors.green;
//       statusText = "Active";
//     } else if (isFuture) {
//       statusColor = Colors.orange;
//       statusText = "À venir";
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: statusColor,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         statusText,
//         style: const TextStyle(color: Colors.white, fontSize: 12),
//       ),
//     );
//   }
// }
//
// class PromotionItem extends StatelessWidget {
//   final Promotion promotion;
//   final Service service;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//   final bool isHighlighted;
//
//   const PromotionItem({
//     super.key,
//     required this.promotion,
//     required this.service,
//     required this.onDelete,
//     required this.onEdit,
//     this.isHighlighted = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = PromotionService.isPromotionActive(promotion);
//     final bool isFuture = PromotionService.isPromotionFuture(promotion);
//
//     Color statusColor = Colors.grey; // Par défaut (passées)
//
//     if (isActive) {
//       statusColor = Colors.green;
//     } else if (isFuture) {
//       statusColor = Colors.orange;
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: statusColor.withAlpha(25), // ≈ 10% d'opacité
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isHighlighted
//               ? statusColor
//               : statusColor.withAlpha(128), // ≈ 50% d'opacité
//           width: isHighlighted ? 2 : 1,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       '${promotion.pourcentage.toStringAsFixed(0)}% de réduction',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: isActive ? statusColor : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     PromotionStatusBadge(promotion: promotion),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Du ${DateFormatter.formatDate(promotion.dateDebut)} au ${DateFormatter.formatDate(promotion.dateFin)}',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                 ),
//                 if (isActive)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Text(
//                       'Prix actuel: ${(service.prix * (1 - promotion.pourcentage / 100)).toStringAsFixed(2)} €',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Row(
//             children: [
//               IconButton(
//                 icon: Icon(Icons.edit, color: Colors.blue, size: 20),
//                 onPressed: onEdit,
//                 constraints: const BoxConstraints(),
//                 padding: const EdgeInsets.all(8),
//                 tooltip: 'Modifier',
//               ),
//               IconButton(
//                 icon: Icon(Icons.delete, color: Colors.red, size: 20),
//                 onPressed: onDelete,
//                 constraints: const BoxConstraints(),
//                 padding: const EdgeInsets.all(8),
//                 tooltip: 'Supprimer',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ServicePromotionCard extends StatelessWidget {
//   final Service service;
//   final VoidCallback onRefresh;
//
//   const ServicePromotionCard({
//     super.key,
//     required this.service,
//     required this.onRefresh,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final Color primaryViolet = const Color(0xFF7B61FF);
//     final hasActivePromo = service.promotion != null;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: hasActivePromo ? Colors.green : Colors.grey.shade300,
//           width: hasActivePromo ? 2 : 1,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     service.intitule,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: primaryViolet,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.add_circle, color: primaryViolet),
//                   onPressed: () {
//                     showCreatePromotionModal(
//                       context: context,
//                       serviceId: service.id,
//                       onPromoAdded: onRefresh,
//                     );
//                   },
//                   tooltip: 'Ajouter une promotion',
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.timer, color: Colors.grey[600], size: 18),
//                 const SizedBox(width: 4),
//                 Text('${service.temps} min', style: TextStyle(color: Colors.grey[600])),
//                 const SizedBox(width: 16),
//                 Icon(Icons.euro, color: Colors.grey[600], size: 18),
//                 const SizedBox(width: 4),
//                 Text('${service.prix} €', style: TextStyle(color: Colors.grey[600])),
//               ],
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Promotions',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//
//             // Promotion active
//             if (hasActivePromo)
//               PromotionItem(
//                 promotion: service.promotion!,
//                 service: service,
//                 isHighlighted: true,
//                 onDelete: () => showDeletePromotionDialog(
//                   context: context,
//                   promotion: service.promotion!,
//                   onSuccess: onRefresh,
//                 ),
//                 onEdit: () {
//                   // TODO: Implémenter l'édition
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("L'édition de promotion sera disponible prochainement"),
//                       backgroundColor: Colors.orange,
//                     ),
//                   );
//                 },
//               )
//             else
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 8),
//                 child: Text(
//                   'Aucune promotion active',
//                   style: TextStyle(
//                     fontStyle: FontStyle.italic,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ),
//
//             // Bouton pour voir toutes les promotions
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton.icon(
//                 onPressed: () => showAllPromotionsModal(context: context,service: service,onRefresh: onRefresh),
//                 icon: const Icon(Icons.calendar_month),
//                 label: const Text('Voir toutes les promotions'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }