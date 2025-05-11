// lib/ui/widgets/promotion_dialogs.dart
import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../services/promotion_service.dart';


Future<void> showDeletePromotionDialog({
  required BuildContext context,
  required PromotionFull promotionFull,
  required VoidCallback onSuccess,
}) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer la promotion'),
      content: const Text('Êtes-vous sûr de vouloir supprimer cette promotion ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context); // ✅ capturé avant pop
            Navigator.pop(context);

            final result = await PromotionService.deletePromotion(promotionFull.id);

            if (result['success'] == true) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: Colors.green,
                ),
              );
              onSuccess();
            } else {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(result['error'] ?? "Erreur inconnue"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}




// Future<void> showDeletePromotionDialog({
//   required BuildContext context,
//   required PromotionFull promotionFull,
//   required VoidCallback onSuccess,
// }) async {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Text('Supprimer la promotion'),
//       content: const Text('Êtes-vous sûr de vouloir supprimer cette promotion ?'),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Annuler'),
//         ),
//         TextButton(
//           onPressed: () async {
//             Navigator.pop(context);
//             final result = await PromotionService.deletePromotion(promotionFull.id);
//
//             final messenger = ScaffoldMessenger.of(context);
//             if (result['success'] == true) {
//               messenger.showSnackBar(
//                 SnackBar(
//                   content: Text(result['message']),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//               onSuccess();
//             } else {
//               messenger.showSnackBar(
//                 SnackBar(
//                   content: Text(result['error']),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           },
//           style: TextButton.styleFrom(foregroundColor: Colors.red),
//           child: const Text('Supprimer'),
//         ),
//       ],
//     ),
//   );
// }
