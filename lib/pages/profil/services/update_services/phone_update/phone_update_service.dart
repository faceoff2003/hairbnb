import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/current_user.dart';
import '../../../../../services/providers/current_user_provider.dart';
import 'phone_api_service.dart';

class PhoneUpdateService {
  /// Valide le format du numéro de téléphone selon les règles du backend
  static PhoneValidationResult validatePhoneNumber(String phone) {
    // Supprimer les espaces et caractères spéciaux pour la validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Vérifier que le numéro n'est pas vide
    if (phone.trim().isEmpty) {
      return PhoneValidationResult(
        isValid: false,
        message: 'Le numéro de téléphone est requis',
      );
    }

    // Vérification correspondant au backend Django (longueur > 3)
    if (cleanPhone.length < 3) {
      return PhoneValidationResult(
        isValid: false,
        message: 'Numéro de téléphone invalide (trop court)',
      );
    }

    // Vérifier la longueur maximum raisonnable
    if (cleanPhone.length > 20) {
      return PhoneValidationResult(
        isValid: false,
        message: 'Le numéro de téléphone ne peut pas dépasser 20 caractères',
      );
    }

    // Vérifier que le numéro ne contient que des chiffres et caractères autorisés
    if (!RegExp(r'^[\d\+\s\-\(\)]*$').hasMatch(phone)) {
      return PhoneValidationResult(
        isValid: false,
        message: 'Le numéro de téléphone contient des caractères invalides',
      );
    }

    // Validation plus poussée pour les formats courants
    final phonePatterns = [
      RegExp(r'^\+?[1-9]\d{2,19}$'),     // Format international basique
      RegExp(r'^\+?32\d{8,9}$'),         // Format belge
      RegExp(r'^\+?33\d{9}$'),           // Format français
      RegExp(r'^0\d{8,9}$'),             // Format national belge/français
      RegExp(r'^\+?1\d{10}$'),           // Format américain/canadien
      RegExp(r'^\+?44\d{10}$'),          // Format britannique
    ];

    // Vérifier qu'au moins un pattern correspond (pour les numéros bien formatés)
    bool matchesKnownPattern = phonePatterns.any((pattern) => pattern.hasMatch(cleanPhone));

    // Si le numéro ne correspond à aucun pattern mais respecte les règles de base, l'accepter quand même
    // (pour permettre des formats moins courants)

    return PhoneValidationResult(
      isValid: true,
      message: matchesKnownPattern ? 'Numéro de téléphone valide' : 'Numéro de téléphone accepté',
      formattedPhone: _formatPhone(phone),
    );
  }

  /// Formate le numéro de téléphone pour un affichage cohérent
  static String _formatPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Si le numéro commence par +32 (Belgique)
    if (cleanPhone.startsWith('+32')) {
      final number = cleanPhone.substring(3);
      if (number.length >= 8) {
        return '+32 ${number.substring(0, 3)} ${number.substring(3, 5)} ${number.substring(5)}';
      }
    }

    // Si le numéro commence par +33 (France)
    if (cleanPhone.startsWith('+33')) {
      final number = cleanPhone.substring(3);
      if (number.length >= 9) {
        return '+33 ${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
      }
    }

    // Format par défaut : groupes de 2 ou 3 chiffres
    if (cleanPhone.startsWith('0') && cleanPhone.length >= 9) {
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 5)} ${cleanPhone.substring(5, 7)} ${cleanPhone.substring(7)}';
    }

    return phone; // Retourner le numéro original si aucun format spécifique
  }

  /// Met à jour le numéro de téléphone de l'utilisateur
  static Future<bool> updateUserPhoneNumber(
      BuildContext context,
      CurrentUser currentUser,
      String newPhone, {
        required Color successGreen,
        required Color errorRed,
        required Function(bool) setLoadingState,
      }) async {
    // 1. Validation du numéro de téléphone
    final validation = validatePhoneNumber(newPhone);
    if (!validation.isValid) {
      _showErrorSnackBar(context, validation.message, errorRed);
      return false;
    }

    // 2. Vérifier si le numéro a vraiment changé
    final formattedNewPhone = validation.formattedPhone ?? newPhone;
    if (currentUser.numeroTelephone == formattedNewPhone ||
        currentUser.numeroTelephone == newPhone) {
      _showInfoSnackBar(context, 'Le numéro de téléphone est identique', Colors.orange);
      return false;
    }

    // 3. Démarrer l'état de chargement
    setLoadingState(true);

    try {
      // 4. Appeler l'API pour mettre à jour le numéro
      final result = await PhoneApiService.updatePhone(currentUser.uuid, newPhone.trim());

      // 5. Désactiver l'état de chargement
      setLoadingState(false);

      // 6. Traiter le résultat
      if (result.success) {
        // Succès : mettre à jour localement et rafraîchir
        await _handleSuccessfulUpdate(context, currentUser, newPhone.trim(), successGreen);
        return true;
      } else {
        // Échec : afficher le message d'erreur approprié
        _handleUpdateError(context, result, errorRed);
        return false;
      }
    } catch (e) {
      // 7. Gestion des erreurs inattendues
      setLoadingState(false);
      _showErrorSnackBar(context, 'Erreur inattendue: $e', errorRed);
      return false;
    }
  }

  /// Gère la mise à jour réussie
  static Future<void> _handleSuccessfulUpdate(
      BuildContext context,
      CurrentUser currentUser,
      String newPhone,
      Color successGreen,
      ) async {
    // 1. Mettre à jour localement
    currentUser.numeroTelephone = newPhone;

    // 2. Mettre à jour via le provider pour propager le changement
    try {
      final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      await userProvider.fetchCurrentUser();
    } catch (e) {
      print('Erreur lors du rafraîchissement des données utilisateur: $e');
      // Continuer même si le rafraîchissement échoue
    }

    // 3. Afficher le message de succès
    _showSuccessSnackBar(context, 'Numéro de téléphone mis à jour avec succès', successGreen);
  }

  /// Gère les erreurs de mise à jour avec messages spécifiques au backend Django
  static void _handleUpdateError(
      BuildContext context,
      PhoneUpdateResult result,
      Color errorRed,
      ) {
    String message = result.message;
    IconData icon = Icons.error_outline;

    // Personnaliser le message et l'icône selon le type d'erreur
    switch (result.errorType) {
      case PhoneUpdateErrorType.validation:
        icon = Icons.warning;
        // Le message du backend Django est déjà descriptif
        break;
      case PhoneUpdateErrorType.authentication:
        icon = Icons.lock_outline;
        message = 'Session expirée. Veuillez vous reconnecter.';
        break;
      case PhoneUpdateErrorType.authorization:
        icon = Icons.block;
        message = 'Vous n\'êtes pas autorisé à modifier ce numéro.';
        break;
      case PhoneUpdateErrorType.notFound:
        icon = Icons.person_off;
        message = 'Utilisateur non trouvé.';
        break;
      case PhoneUpdateErrorType.network:
        icon = Icons.wifi_off;
        message = 'Problème de connexion. Vérifiez votre réseau.';
        break;
      case PhoneUpdateErrorType.server:
        icon = Icons.cloud_off;
        // Utiliser le message du serveur qui peut être plus descriptif
        break;
      default:
        break;
    }

    _showErrorSnackBar(context, message, errorRed, icon: icon);
  }

  /// Affiche un SnackBar de succès
  static void _showSuccessSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche un SnackBar d'erreur
  static void _showErrorSnackBar(BuildContext context, String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Affiche un SnackBar d'information
  static void _showInfoSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Résultat de la validation du numéro de téléphone
class PhoneValidationResult {
  final bool isValid;
  final String message;
  final String? formattedPhone;

  PhoneValidationResult({
    required this.isValid,
    required this.message,
    this.formattedPhone,
  });
}










// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../../models/current_user.dart';
// import '../../../../../services/providers/current_user_provider.dart';
// import 'phone_api_service.dart';
//
// class PhoneUpdateService {
//   /// Valide le format du numéro de téléphone
//   static PhoneValidationResult validatePhoneNumber(String phone) {
//     // Supprimer les espaces et caractères spéciaux pour la validation
//     final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
//
//     // Vérifier que le numéro n'est pas vide
//     if (phone.trim().isEmpty) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Le numéro de téléphone ne peut pas être vide',
//       );
//     }
//
//     // Vérifier la longueur minimum
//     if (cleanPhone.length < 8) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Le numéro de téléphone doit contenir au moins 8 chiffres',
//       );
//     }
//
//     // Vérifier la longueur maximum
//     if (cleanPhone.length > 15) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Le numéro de téléphone ne peut pas dépasser 15 chiffres',
//       );
//     }
//
//     // Vérifier que le numéro ne contient que des chiffres (après nettoyage)
//     if (!RegExp(r'^[\d\+][\d\s\-\(\)]*$').hasMatch(phone)) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Le numéro de téléphone contient des caractères invalides',
//       );
//     }
//
//     // Vérifier les formats courants
//     final phonePatterns = [
//       RegExp(r'^\+?[1-9]\d{7,14}$'), // Format international simple
//       RegExp(r'^\+?32\d{8,9}$'),     // Format belge
//       RegExp(r'^\+?33\d{9}$'),       // Format français
//       RegExp(r'^0\d{8,9}$'),         // Format national belge/français
//     ];
//
//     bool matchesPattern = phonePatterns.any((pattern) => pattern.hasMatch(cleanPhone));
//     if (!matchesPattern) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Format de numéro de téléphone non reconnu',
//       );
//     }
//
//     return PhoneValidationResult(
//       isValid: true,
//       message: 'Numéro de téléphone valide',
//       formattedPhone: _formatPhone(phone),
//     );
//   }
//
//   /// Formate le numéro de téléphone pour un affichage cohérent
//   static String _formatPhone(String phone) {
//     final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
//
//     // Si le numéro commence par +32 (Belgique)
//     if (cleanPhone.startsWith('+32')) {
//       final number = cleanPhone.substring(3);
//       if (number.length >= 8) {
//         return '+32 ${number.substring(0, 3)} ${number.substring(3, 5)} ${number.substring(5)}';
//       }
//     }
//
//     // Si le numéro commence par +33 (France)
//     if (cleanPhone.startsWith('+33')) {
//       final number = cleanPhone.substring(3);
//       if (number.length >= 9) {
//         return '+33 ${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
//       }
//     }
//
//     // Format par défaut : groupes de 2 ou 3 chiffres
//     if (cleanPhone.startsWith('0') && cleanPhone.length >= 9) {
//       return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 5)} ${cleanPhone.substring(5, 7)} ${cleanPhone.substring(7)}';
//     }
//
//     return phone; // Retourner le numéro original si aucun format spécifique
//   }
//
//   /// Met à jour le numéro de téléphone de l'utilisateur avec validation complète
//   static Future<bool> updateUserPhoneNumber(
//       BuildContext context,
//       CurrentUser currentUser,
//       String newPhone, {
//         required Color successGreen,
//         required Color errorRed,
//         required Function(bool) setLoadingState,
//       }) async {
//     // 1. Validation du numéro de téléphone
//     final validation = validatePhoneNumber(newPhone);
//     if (!validation.isValid) {
//       _showErrorSnackBar(context, validation.message, errorRed);
//       return false;
//     }
//
//     // 2. Vérifier si le numéro a vraiment changé
//     final formattedNewPhone = validation.formattedPhone ?? newPhone;
//     if (currentUser.numeroTelephone == formattedNewPhone ||
//         currentUser.numeroTelephone == newPhone) {
//       _showInfoSnackBar(context, 'Le numéro de téléphone est identique', Colors.orange);
//       return false;
//     }
//
//     // 3. Démarrer l'état de chargement
//     setLoadingState(true);
//
//     try {
//       // 4. Appeler l'API pour mettre à jour le numéro
//       final result = await PhoneApiService.updatePhone(currentUser.uuid, formattedNewPhone);
//
//       // 5. Désactiver l'état de chargement
//       setLoadingState(false);
//
//       // 6. Traiter le résultat
//       if (result.success) {
//         // Succès : mettre à jour localement et rafraîchir
//         await _handleSuccessfulUpdate(context, currentUser, formattedNewPhone, successGreen);
//         return true;
//       } else {
//         // Échec : afficher le message d'erreur approprié
//         _handleUpdateError(context, result, errorRed);
//         return false;
//       }
//     } catch (e) {
//       // 7. Gestion des erreurs inattendues
//       setLoadingState(false);
//       _showErrorSnackBar(context, 'Erreur inattendue: $e', errorRed);
//       return false;
//     }
//   }
//
//   /// Gère la mise à jour réussie
//   static Future<void> _handleSuccessfulUpdate(
//       BuildContext context,
//       CurrentUser currentUser,
//       String newPhone,
//       Color successGreen,
//       ) async {
//     // 1. Mettre à jour localement
//     currentUser.numeroTelephone = newPhone;
//
//     // 2. Mettre à jour via le provider pour propager le changement
//     try {
//       final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//       await userProvider.fetchCurrentUser();
//     } catch (e) {
//       print('Erreur lors du rafraîchissement des données utilisateur: $e');
//       // Continuer même si le rafraîchissement échoue
//     }
//
//     // 3. Afficher le message de succès
//     _showSuccessSnackBar(context, 'Numéro de téléphone mis à jour avec succès', successGreen);
//   }
//
//   /// Gère les erreurs de mise à jour
//   static void _handleUpdateError(
//       BuildContext context,
//       PhoneUpdateResult result,
//       Color errorRed,
//       ) {
//     String message = result.message;
//     IconData icon = Icons.error_outline;
//
//     // Personnaliser le message et l'icône selon le type d'erreur
//     switch (result.errorType) {
//       case PhoneUpdateErrorType.validation:
//         icon = Icons.warning;
//         break;
//       case PhoneUpdateErrorType.authentication:
//         icon = Icons.lock_outline;
//         message = 'Session expirée. Veuillez vous reconnecter.';
//         break;
//       case PhoneUpdateErrorType.conflict:
//         icon = Icons.phone_locked;
//         break;
//       case PhoneUpdateErrorType.network:
//         icon = Icons.wifi_off;
//         message = 'Problème de connexion. Vérifiez votre réseau.';
//         break;
//       case PhoneUpdateErrorType.server:
//         icon = Icons.cloud_off;
//         break;
//       default:
//         break;
//     }
//
//     _showErrorSnackBar(context, message, errorRed, icon: icon);
//   }
//
//   /// Affiche un SnackBar de succès
//   static void _showSuccessSnackBar(BuildContext context, String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(10),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   /// Affiche un SnackBar d'erreur
//   static void _showErrorSnackBar(BuildContext context, String message, Color color, {IconData? icon}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(icon ?? Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(10),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }
//
//   /// Affiche un SnackBar d'information
//   static void _showInfoSnackBar(BuildContext context, String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.info_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(10),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }
// }
//
// /// Résultat de la validation du numéro de téléphone
// class PhoneValidationResult {
//   final bool isValid;
//   final String message;
//   final String? formattedPhone;
//
//   PhoneValidationResult({
//     required this.isValid,
//     required this.message,
//     this.formattedPhone,
//   });
// }