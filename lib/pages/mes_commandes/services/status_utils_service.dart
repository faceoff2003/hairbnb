import 'package:flutter/material.dart';

class StatusUtils {
  // Méthode pour obtenir la couleur correspondant à chaque statut
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmé':
      case 'confirme':
      case 'confirmes':
        return Colors.green;
      case 'en attente':
      case 'en_attente':
      case 'attente':
        return Colors.orange;
      case 'annulé':
      case 'annule':
      case 'annules':
        return Colors.red;
      case 'terminé':
      case 'termine':
      case 'termines':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Méthode pour normaliser les statuts (pour les filtres)
  static String normalizeStatus(String status) {
    final statusLower = status.toLowerCase().trim();

    if (['confirmé', 'confirme', 'confirmes'].contains(statusLower)) {
      return 'confirmé';
    }

    if (['en attente', 'en_attente', 'attente'].contains(statusLower)) {
      return 'en attente';
    }

    if (['terminé', 'termine', 'termines'].contains(statusLower)) {
      return 'terminé';
    }

    if (['annulé', 'annule', 'annules'].contains(statusLower)) {
      return 'annulé';
    }

    return status;
  }

  // Vérifie si un statut est actif (en attente ou confirmé)
  static bool isActiveStatus(String status) {
    final normalized = normalizeStatus(status);
    return ['en attente', 'confirmé'].contains(normalized);
  }

  // Vérifie si un statut est terminé (terminé ou annulé)
  static bool isCompletedStatus(String status) {
    final normalized = normalizeStatus(status);
    return ['terminé', 'annulé'].contains(normalized);
  }
}