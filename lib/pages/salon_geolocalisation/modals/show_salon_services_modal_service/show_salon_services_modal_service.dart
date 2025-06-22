// 🔧 NOUVEAU: show_salon_services_modal_service.dart - Avec currentUser et notifications centrées

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/salon_details_geo.dart';
import 'package:hairbnb/models/service_with_promo.dart';
import 'package:hairbnb/models/current_user.dart';

import '../show_salon_services_modal.dart';

class SalonServicesModalService {

  /// Affiche le modal des services pour un salon donné
  ///
  /// [context] - Le contexte Flutter
  /// [salon] - Le salon pour lequel afficher les services
  /// [currentUser] - L'utilisateur connecté (NOUVEAU)
  /// [primaryColor] - Couleur primaire pour le thème (optionnel)
  /// [accentColor] - Couleur d'accent pour le thème (optionnel)
  /// [onServicesSelected] - Callback appelé quand des services sont sélectionnés (optionnel)
  static Future<List<ServiceWithPromo>?> afficherServicesModal(
      BuildContext context, {
        required SalonDetailsForGeo salon,
        CurrentUser? currentUser, // ✅ NOUVEAU
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
        Function(List<ServiceWithPromo>)? onServicesSelected,
      }) async {

    // ✅ Modal avec notifications centrées intégrées
    final selectedServices = await showModalBottomSheet<List<ServiceWithPromo>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalonServicesModal(
        salon: salon,
        currentUser: currentUser, // ✅ NOUVEAU
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );

    // Si des services ont été sélectionnés
    if (selectedServices != null && selectedServices.isNotEmpty) {

      if (kDebugMode) {
        print("✅ Services sélectionnés depuis le modal: ${selectedServices.length}");
      }

      // Appeler le callback si fourni (pour compatibilité arrière)
      if (onServicesSelected != null) {
        onServicesSelected(selectedServices);
      }

      return selectedServices;
    }

    return null;
  }

  /// Affiche le modal avec des options personnalisées avancées
  static Future<List<ServiceWithPromo>?> afficherServicesModalAvecOptions(
      BuildContext context, {
        required SalonDetailsForGeo salon,
        CurrentUser? currentUser, // ✅ NOUVEAU
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
        bool afficherNotification = false,
        String? messageNotificationPersonnalise,
        Function(List<ServiceWithPromo>)? onServicesSelected,
        VoidCallback? onPanierClique,
      }) async {

    final selectedServices = await showModalBottomSheet<List<ServiceWithPromo>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalonServicesModal(
        salon: salon,
        currentUser: currentUser, // ✅ NOUVEAU
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );

    if (selectedServices != null && selectedServices.isNotEmpty) {

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
        CurrentUser? currentUser, // ✅ NOUVEAU
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
      }) async {

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalonServicesModal(
        salon: salon,
        currentUser: currentUser, // ✅ NOUVEAU
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );
  }
}
