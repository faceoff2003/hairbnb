// // lib/utils/promotion_helpers.dart
// import 'dart:ui';
// import '../../../../../models/promotion.dart';
//
// class PromotionHelpers {
//   // Détermine le statut d'une promotion
//   static String getPromotionStatus(Promotion promo) {
//     final now = DateTime.now();
//
//     // Si la promotion a une propriété isActiveValue, on l'utilise d'abord
//     if (promo.isActiveValue) {
//       return "active";
//     }
//
//     // Sinon, on se base sur les dates
//     if (now.isBefore(promo.dateDebut)) {
//       return "future";
//     } else if (now.isAfter(promo.dateFin)) {
//       return "expired";
//     }
//
//     return "active";
//   }
//
//   // Renvoie la couleur correspondant au statut
//   static getStatusColor(String status) {
//     switch (status) {
//       case "active":
//         return const Color(0xFF2ECC71); // Vert
//       case "future":
//         return const Color(0xFFF39C12); // Orange
//       case "expired":
//         return const Color(0xFF95A5A6); // Gris
//       default:
//         return const Color(0xFF95A5A6); // Gris par défaut
//     }
//   }
//
//   // Renvoie le texte correspondant au statut en français
//   static String getStatusText(String status) {
//     switch (status) {
//       case "active":
//         return "Active";
//       case "future":
//         return "À venir";
//       case "expired":
//         return "Expirée";
//       default:
//         return "Inconnue";
//     }
//   }
//
//   // Calcule le prix après réduction
//   static double calculateDiscountedPrice(double originalPrice, double discountPercentage) {
//     return originalPrice * (1 - discountPercentage / 100);
//   }
// }