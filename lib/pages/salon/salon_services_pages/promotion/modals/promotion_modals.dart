// lib/ui/widgets/promotion_status_badge.dart
import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../services/promotion_service.dart';

class PromotionStatusBadge extends StatelessWidget {
  final PromotionFull promotionFull;

  const PromotionStatusBadge({super.key, required this.promotionFull});

  @override
  Widget build(BuildContext context) {
    final bool isActive = PromotionService.isPromotionActive(promotionFull);
    final bool isFuture = PromotionService.isPromotionFuture(promotionFull);

    Color statusColor = Colors.grey;
    String statusText = "Terminée";

    if (isActive) {
      statusColor = Colors.green;
      statusText = "Active";
    } else if (isFuture) {
      statusColor = Colors.orange;
      statusText = "À venir";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
