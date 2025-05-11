import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/public_salon_details.dart';

class ServicePriceWidget extends StatelessWidget {
  final ServiceSalonDetails serviceSalonDetails;

  const ServicePriceWidget({super.key, required this.serviceSalonDetails});

  @override
  Widget build(BuildContext context) {
    final hasPromo = serviceSalonDetails.promotionActive != null;
    final prixOriginal = serviceSalonDetails.prix ?? 0.0;

    double prixFinal = prixOriginal;
    if (hasPromo) {
      final percentage = double.tryParse(serviceSalonDetails.promotionActive!.discountPercentage) ?? 0;
      prixFinal = prixOriginal * (1 - (percentage / 100));
    }

    return Row(
      children: [
        if (hasPromo) ...[
          _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.grey, isStrikethrough: true),
          const SizedBox(width: 8),
          _animatedTag('${prixFinal.toStringAsFixed(2)} €', Colors.red),
        ] else
          _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.green),
        const SizedBox(width: 8),
        _tag('${serviceSalonDetails.duree ?? 0} min', Colors.blue),
      ],
    );
  }

  Widget _tag(String label, Color color, {bool isStrikethrough = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: color,
          fontSize: 12,
          decoration: isStrikethrough ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }

  Widget _animatedTag(String label, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(10 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: _tag(label, color),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../models/public_salon_details.dart'; // ✅ bon modèle
//
// class ServicePriceWidget extends StatelessWidget {
//   final ServiceSalonDetails service; // ✅ classe correcte
//
//   const ServicePriceWidget({super.key, required this.service});
//
//   @override
//   Widget build(BuildContext context) {
//     final bool hasPromo = service.promotionActive != null;
//     final double prixOriginal = service.prix ?? 0.0;
//     double prixReduit = prixOriginal;
//
//     // ✅ Calcul du prix réduit si promotion active
//     if (hasPromo) {
//       final pourcentage = double.tryParse(service.promotionActive!.discountPercentage) ?? 0;
//       prixReduit = prixOriginal * (1 - pourcentage / 100);
//       prixReduit = double.parse(prixReduit.toStringAsFixed(2));
//     }
//
//     return Row(
//       children: [
//         if (hasPromo) ...[
//           _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.grey, isStrikethrough: true),
//           const SizedBox(width: 8),
//           _animatedTag('${prixReduit.toStringAsFixed(2)} €', Colors.red),
//           const SizedBox(width: 6),
//           _tag('-${double.parse(service.promotionActive!.discountPercentage).toStringAsFixed(0)}%', Colors.red.shade800),
//         ] else
//           _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.green),
//         const SizedBox(width: 8),
//         _tag('${service.duree ?? 0} min', Colors.blue),
//       ],
//     );
//   }
//
//   Widget _tag(String label, Color color, {bool isStrikethrough = false}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         label,
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w500,
//           color: color,
//           fontSize: 12,
//           decoration: isStrikethrough ? TextDecoration.lineThrough : null,
//         ),
//       ),
//     );
//   }
//
//   Widget _animatedTag(String label, Color color) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 400),
//       builder: (context, value, child) {
//         return Opacity(
//           opacity: value,
//           child: Transform.translate(
//             offset: Offset(10 * (1 - value), 0),
//             child: child,
//           ),
//         );
//       },
//       child: _tag(label, color),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../models/Services.dart';
//
// class ServicePriceWidget extends StatelessWidget {
//   final Service service;
//
//   const ServicePriceWidget({super.key, required this.service});
//
//   @override
//   Widget build(BuildContext context) {
//     final bool hasPromo = service.promotion != null;
//     final double prixOriginal = service.prix;
//     final double prixReduit = service.prixFinal;
//
//     return Row(
//       children: [
//         if (hasPromo) ...[
//           _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.grey,
//               isStrikethrough: true),
//           const SizedBox(width: 8),
//           _animatedTag('${prixReduit.toStringAsFixed(2)} €', Colors.red),
//         ] else
//           _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.green),
//         const SizedBox(width: 8),
//         _tag('${service.temps} min', Colors.blue),
//       ],
//     );
//   }
//
//   Widget _tag(String label, Color color, {bool isStrikethrough = false}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         label,
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w500,
//           color: color,
//           fontSize: 12,
//           decoration: isStrikethrough ? TextDecoration.lineThrough : null,
//         ),
//       ),
//     );
//   }
//
//   Widget _animatedTag(String label, Color color) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 400),
//       builder: (context, value, child) {
//         return Opacity(
//           opacity: value,
//           child: Transform.translate(
//             offset: Offset(10 * (1 - value), 0),
//             child: child,
//           ),
//         );
//       },
//       child: _tag(label, color),
//     );
//   }
// }
