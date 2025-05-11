// 📁 lib/ui/widgets/promotion_item_widget.dart
import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';
import '../services/promotion_service.dart';
import '../utils/date_formatter.dart';

class PromotionItem extends StatelessWidget {
  final PromotionFull promotionFull;
  final ServiceWithPromo serviceWithPromo;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isHighlighted;

  const PromotionItem({
    super.key,
    required this.promotionFull,
    required this.serviceWithPromo,
    required this.onDelete,
    required this.onEdit,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = PromotionService.isPromotionActive(promotionFull);
    final bool isFuture = PromotionService.isPromotionFuture(promotionFull);

    Color statusColor = Colors.grey;

    if (isActive) {
      statusColor = Colors.green;
    } else if (isFuture) {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? statusColor
              : statusColor.withAlpha((0.5 * 255).toInt()),
          width: isHighlighted ? 2 : 1,
        ),
      ),
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
                      '${promotionFull.pourcentage.toStringAsFixed(0)}% de réduction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? statusColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(promotionFull, statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Du ${DateFormatter.formatDate(promotionFull.dateDebut)} au ${DateFormatter.formatDate(promotionFull.dateFin)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Prix actuel: ${(serviceWithPromo.prix * (1 - promotionFull.pourcentage / 100)).toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: onEdit,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: onDelete,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PromotionFull promo, Color color) {
    String label = "Inconnue";

    if (PromotionService.isPromotionActive(promo)) {
      label = "Active";
    } else if (PromotionService.isPromotionFuture(promo)) {
      label = "À venir";
    } else {
      label = "Terminée";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}






// // lib/ui/widgets/promotion_item_widget.dart
// import 'package:flutter/material.dart';
// import '../modals/promotion_modals.dart';
// import '../services/promotion_service.dart';
// import '../utils/date_formatter.dart';
//
// class PromotionItem extends StatelessWidget {
//   final PromotionFull promotionFull;
//   final ServiceWithPromotion serviceWithPromotion;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//   final bool isHighlighted;
//
//   const PromotionItem({
//     super.key,
//     required this.promotionFull,
//     required this.serviceWithPromotion,
//     required this.onDelete,
//     required this.onEdit,
//     this.isHighlighted = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = PromotionService.isPromotionActive(promotionFull);
//     final bool isFuture = PromotionService.isPromotionFuture(promotionFull);
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
//         color: statusColor.withAlpha(25), // 10% de transparence
//
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isHighlighted
//               ? statusColor
//               : statusColor.withAlpha((0.5 * 255).toInt()),
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
