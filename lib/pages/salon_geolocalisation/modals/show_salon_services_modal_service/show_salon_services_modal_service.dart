// 🔧 CORRECTION: show_salon_services_modal_service.dart - Type et logique corrigés

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/salon_details_geo.dart';
import 'package:hairbnb/models/service_with_promo.dart'; // ✅ CHANGEMENT: Import du bon modèle

import '../show_salon_services_modal.dart';

class SalonServicesModalService {

  /// Affiche le modal des services pour un salon donné
  ///
  /// [context] - Le contexte Flutter
  /// [salon] - Le salon pour lequel afficher les services
  /// [primaryColor] - Couleur primaire pour le thème (optionnel)
  /// [accentColor] - Couleur d'accent pour le thème (optionnel)
  /// [onServicesSelected] - Callback appelé quand des services sont sélectionnés (optionnel)
  static Future<List<ServiceWithPromo>?> afficherServicesModal( // ✅ CHANGEMENT: Retour ServiceWithPromo
      BuildContext context, {
        required SalonDetailsForGeo salon,
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
        Function(List<ServiceWithPromo>)? onServicesSelected, // ✅ CHANGEMENT: Type correct
      }) async {

    // ✅ Utilisation de showDialog au lieu de showModalBottomSheet pour meilleure UX
    final selectedServices = await showDialog<List<ServiceWithPromo>>( // ✅ CHANGEMENT: Type correct
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: SalonServicesModal(
          salon: salon,
          primaryColor: primaryColor,
          accentColor: accentColor,
        ),
      ),
    );

    // Si des services ont été sélectionnés
    if (selectedServices != null && selectedServices.isNotEmpty) {

      // ✅ NE PAS afficher la notification ici car elle sera gérée dans salon_map_page.dart
      // _afficherNotificationSucces(context, selectedServices.length);

      // Appeler le callback si fourni
      if (onServicesSelected != null) {
        onServicesSelected(selectedServices);
      }

      return selectedServices;
    }

    return null;
  }

  /// ✅ MÉTHODE SUPPRIMÉE: _afficherNotificationSucces
  /// (sera gérée dans salon_map_page.dart pour éviter les doublons)

  /// ✅ MÉTHODE SUPPRIMÉE: _naviguerVersLepanier
  /// (sera gérée dans salon_map_page.dart)

  /// Affiche le modal avec des options personnalisées avancées
  static Future<List<ServiceWithPromo>?> afficherServicesModalAvecOptions( // ✅ CHANGEMENT: Type correct
      BuildContext context, {
        required SalonDetailsForGeo salon,
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
        bool afficherNotification = false, // ✅ CHANGEMENT: Désactivé par défaut
        String? messageNotificationPersonnalise,
        Function(List<ServiceWithPromo>)? onServicesSelected, // ✅ CHANGEMENT: Type correct
        VoidCallback? onPanierClique,
      }) async {

    final selectedServices = await showDialog<List<ServiceWithPromo>>( // ✅ CHANGEMENT: Type correct
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: SalonServicesModal(
          salon: salon,
          primaryColor: primaryColor,
          accentColor: accentColor,
        ),
      ),
    );

    if (selectedServices != null && selectedServices.isNotEmpty) {

      // Afficher la notification seulement si explicitement demandé
      if (afficherNotification) {
        final message = messageNotificationPersonnalise ??
            "${selectedServices.length} service(s) ajouté(s) au panier !";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: "Voir le panier",
              textColor: Colors.white,
              onPressed: onPanierClique ?? () {
                if (kDebugMode) {
                  print("🛒 Navigation vers le panier - À implémenter selon votre app");
                }
              },
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Callback personnalisé
      if (onServicesSelected != null) {
        onServicesSelected(selectedServices);
      }

      return selectedServices;
    }

    return null;
  }

  /// Affiche le modal en mode "aperçu seulement" (sans sélection)
  static Future<void> afficherApercuServices(
      BuildContext context, {
        required SalonDetailsForGeo salon,
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
      }) async {

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: SalonServicesModal(
          salon: salon,
          primaryColor: primaryColor,
          accentColor: accentColor,
          // Vous pourriez ajouter un paramètre `modeApercu: true` au modal
        ),
      ),
    );
  }
}








// // lib/pages/salon_geolocalisation/services/salon_services_modal_service.dart
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/salon_details_geo.dart';
// import 'package:hairbnb/models/services.dart';
//
// import '../show_salon_services_modal.dart';
//
// class SalonServicesModalService {
//
//   /// Affiche le modal des services pour un salon donné
//   ///
//   /// [context] - Le contexte Flutter
//   /// [salon] - Le salon pour lequel afficher les services
//   /// [primaryColor] - Couleur primaire pour le thème (optionnel)
//   /// [accentColor] - Couleur d'accent pour le thème (optionnel)
//   /// [onServicesSelected] - Callback appelé quand des services sont sélectionnés (optionnel)
//   static Future<List<Service>?> afficherServicesModal(
//       BuildContext context, {
//         required SalonDetailsForGeo salon,
//         Color primaryColor = const Color(0xFF7B61FF),
//         Color accentColor = const Color(0xFFE67E22),
//         Function(List<Service>)? onServicesSelected,
//       }) async {
//
//     // MODIFICATION ICI : Remplacer showModalBottomSheet par showDialog et ajouter Dialog
//     final selectedServices = await showDialog<List<Service>>(
//       context: context,
//       builder: (context) => Dialog( // Ajoute le widget Dialog
//         backgroundColor: Colors.transparent, // Rend le fond du Dialog transparent
//         insetPadding: EdgeInsets.all(20), // Ajoute de la marge autour du modal
//         child: SalonServicesModal( // Ton modal de services actuel
//           salon: salon,
//           primaryColor: primaryColor,
//           accentColor: accentColor,
//         ),
//       ),
//     );
//
//     // Si des services ont été sélectionnés
//     if (selectedServices != null && selectedServices.isNotEmpty) {
//
//       // Afficher la notification de succès
//       _afficherNotificationSucces(context, selectedServices.length);
//
//       // Appeler le callback si fourni
//       if (onServicesSelected != null) {
//         onServicesSelected(selectedServices);
//       }
//
//       return selectedServices;
//     }
//
//     return null;
//   }
//
//   /// Affiche une notification de succès quand des services sont ajoutés
//   static void _afficherNotificationSucces(BuildContext context, int nombreServices) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("$nombreServices service(s) ajouté(s) au panier !"),
//         backgroundColor: Colors.green,
//         duration: Duration(seconds: 3),
//         action: SnackBarAction(
//           label: "Voir le panier",
//           textColor: Colors.white,
//           onPressed: () {
//             _naviguerVersLepanier(context);
//           },
//         ),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
//
//   /// Navigue vers la page du panier
//   /// Adaptez cette méthode selon votre système de navigation
//   static void _naviguerVersLepanier(BuildContext context) {
//     // Option 1: Navigation avec routes nommées
//     // Navigator.pushNamed(context, '/cart');
//
//     // Option 2: Navigation directe (remplacez par votre page de panier)
//     // Navigator.push(
//     //   context,
//     //   MaterialPageRoute(builder: (context) => CartPage()),
//     // );
//
//     // Option 3: Navigation avec vos routes existantes
//     // Adaptez selon votre implémentation
//     if (kDebugMode) {
//       print("🛒 Navigation vers le panier - À implémenter selon votre app");
//     }
//   }
//
//   /// Affiche le modal avec des options personnalisées avancées
//   static Future<List<Service>?> afficherServicesModalAvecOptions(
//       BuildContext context, {
//         required SalonDetailsForGeo salon,
//         Color primaryColor = const Color(0xFF7B61FF),
//         Color accentColor = const Color(0xFFE67E22),
//         bool afficherNotification = true,
//         String? messageNotificationPersonnalise,
//         Function(List<Service>)? onServicesSelected,
//         VoidCallback? onPanierClique,
//       }) async {
//
//     // MODIFICATION ICI AUSSI : Remplacer showModalBottomSheet par showDialog et ajouter Dialog
//     final selectedServices = await showDialog<List<Service>>(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: EdgeInsets.all(20),
//         child: SalonServicesModal(
//           salon: salon,
//           primaryColor: primaryColor,
//           accentColor: accentColor,
//         ),
//       ),
//     );
//
//     if (selectedServices != null && selectedServices.isNotEmpty) {
//
//       // Afficher la notification si demandé
//       if (afficherNotification) {
//         final message = messageNotificationPersonnalise ??
//             "${selectedServices.length} service(s) ajouté(s) au panier !";
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 3),
//             action: SnackBarAction(
//               label: "Voir le panier",
//               textColor: Colors.white,
//               onPressed: onPanierClique ?? () => _naviguerVersLepanier(context),
//             ),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       }
//
//       // Callback personnalisé
//       if (onServicesSelected != null) {
//         onServicesSelected(selectedServices);
//       }
//
//       return selectedServices;
//     }
//
//     return null;
//   }
//
//   /// Affiche le modal en mode "aperçu seulement" (sans sélection)
//   static Future<void> afficherApercuServices(
//       BuildContext context, {
//         required SalonDetailsForGeo salon,
//         Color primaryColor = const Color(0xFF7B61FF),
//         Color accentColor = const Color(0xFFE67E22),
//       }) async {
//
//     // MODIFICATION ICI AUSSI : Remplacer showModalBottomSheet par showDialog et ajouter Dialog
//     await showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: EdgeInsets.all(20),
//         child: SalonServicesModal(
//           salon: salon,
//           primaryColor: primaryColor,
//           accentColor: accentColor,
//           // Vous pourriez ajouter un paramètre `modeApercu: true` au modal
//         ),
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
// // // lib/pages/salon_geolocalisation/services/salon_services_modal_service.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/salon_details_geo.dart';
// // import 'package:hairbnb/models/services.dart';
// //
// // import '../show_salon_services_modal.dart';
// //
// // class SalonServicesModalService {
// //
// //   /// Affiche le modal des services pour un salon donné
// //   ///
// //   /// [context] - Le contexte Flutter
// //   /// [salon] - Le salon pour lequel afficher les services
// //   /// [primaryColor] - Couleur primaire pour le thème (optionnel)
// //   /// [accentColor] - Couleur d'accent pour le thème (optionnel)
// //   /// [onServicesSelected] - Callback appelé quand des services sont sélectionnés (optionnel)
// //   static Future<List<Service>?> afficherServicesModal(
// //       BuildContext context, {
// //         required SalonDetailsForGeo salon,
// //         Color primaryColor = const Color(0xFF7B61FF),
// //         Color accentColor = const Color(0xFFE67E22),
// //         Function(List<Service>)? onServicesSelected,
// //       }) async {
// //
// //     final selectedServices = await showModalBottomSheet<List<Service>>(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (context) => SalonServicesModal(
// //         salon: salon,
// //         primaryColor: primaryColor,
// //         accentColor: accentColor,
// //       ),
// //     );
// //
// //     // Si des services ont été sélectionnés
// //     if (selectedServices != null && selectedServices.isNotEmpty) {
// //
// //       // Afficher la notification de succès
// //       _afficherNotificationSucces(context, selectedServices.length);
// //
// //       // Appeler le callback si fourni
// //       if (onServicesSelected != null) {
// //         onServicesSelected(selectedServices);
// //       }
// //
// //       return selectedServices;
// //     }
// //
// //     return null;
// //   }
// //
// //   /// Affiche une notification de succès quand des services sont ajoutés
// //   static void _afficherNotificationSucces(BuildContext context, int nombreServices) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text("$nombreServices service(s) ajouté(s) au panier !"),
// //         backgroundColor: Colors.green,
// //         duration: Duration(seconds: 3),
// //         action: SnackBarAction(
// //           label: "Voir le panier",
// //           textColor: Colors.white,
// //           onPressed: () {
// //             _naviguerVersLepanier(context);
// //           },
// //         ),
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(10),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// Navigue vers la page du panier
// //   /// Adaptez cette méthode selon votre système de navigation
// //   static void _naviguerVersLepanier(BuildContext context) {
// //     // Option 1: Navigation avec routes nommées
// //     // Navigator.pushNamed(context, '/cart');
// //
// //     // Option 2: Navigation directe (remplacez par votre page de panier)
// //     // Navigator.push(
// //     //   context,
// //     //   MaterialPageRoute(builder: (context) => CartPage()),
// //     // );
// //
// //     // Option 3: Navigation avec vos routes existantes
// //     // Adaptez selon votre implémentation
// //     print("🛒 Navigation vers le panier - À implémenter selon votre app");
// //   }
// //
// //   /// Affiche le modal avec des options personnalisées avancées
// //   static Future<List<Service>?> afficherServicesModalAvecOptions(
// //       BuildContext context, {
// //         required SalonDetailsForGeo salon,
// //         Color primaryColor = const Color(0xFF7B61FF),
// //         Color accentColor = const Color(0xFFE67E22),
// //         bool afficherNotification = true,
// //         String? messageNotificationPersonnalise,
// //         Function(List<Service>)? onServicesSelected,
// //         VoidCallback? onPanierClique,
// //       }) async {
// //
// //     final selectedServices = await showModalBottomSheet<List<Service>>(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (context) => SalonServicesModal(
// //         salon: salon,
// //         primaryColor: primaryColor,
// //         accentColor: accentColor,
// //       ),
// //     );
// //
// //     if (selectedServices != null && selectedServices.isNotEmpty) {
// //
// //       // Afficher la notification si demandé
// //       if (afficherNotification) {
// //         final message = messageNotificationPersonnalise ??
// //             "${selectedServices.length} service(s) ajouté(s) au panier !";
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(message),
// //             backgroundColor: Colors.green,
// //             duration: Duration(seconds: 3),
// //             action: SnackBarAction(
// //               label: "Voir le panier",
// //               textColor: Colors.white,
// //               onPressed: onPanierClique ?? () => _naviguerVersLepanier(context),
// //             ),
// //             behavior: SnackBarBehavior.floating,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //           ),
// //         );
// //       }
// //
// //       // Callback personnalisé
// //       if (onServicesSelected != null) {
// //         onServicesSelected(selectedServices);
// //       }
// //
// //       return selectedServices;
// //     }
// //
// //     return null;
// //   }
// //
// //   /// Affiche le modal en mode "aperçu seulement" (sans sélection)
// //   static Future<void> afficherApercuServices(
// //       BuildContext context, {
// //         required SalonDetailsForGeo salon,
// //         Color primaryColor = const Color(0xFF7B61FF),
// //         Color accentColor = const Color(0xFFE67E22),
// //       }) async {
// //
// //     await showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (context) => SalonServicesModal(
// //         salon: salon,
// //         primaryColor: primaryColor,
// //         accentColor: accentColor,
// //         // Vous pourriez ajouter un paramètre `modeApercu: true` au modal
// //       ),
// //     );
// //   }
// // }