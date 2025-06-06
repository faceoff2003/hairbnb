// Cette méthode pourrait être placée dans un service dédié, par exemple PhoneUpdateService.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/current_user.dart';
import '../../../../../services/providers/current_user_provider.dart';
import 'phone_api_service.dart';

class PhoneUpdateService {
  static Future<bool> updateUserPhoneNumber(
      BuildContext context,
      CurrentUser currentUser,
      String newPhone, {
        required Color successGreen,
        required Color errorRed,
        required Function(bool) setLoadingState,
      }) async {
    // Définir l'état de chargement
    setLoadingState(true);

    try {
      // Appeler l'API pour mettre à jour le numéro
      final success = await PhoneApiService.updatePhone(currentUser.uuid, newPhone);

      // Désactiver l'état de chargement
      setLoadingState(false);

      if (success) {
        // 1. Mettre à jour localement
        currentUser.numeroTelephone = newPhone;

        // 2. Mettre à jour via le provider pour propager le changement partout
        final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        await userProvider.fetchCurrentUser();

        // 3. Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Numéro de téléphone mis à jour"),
                ],
              ),
              backgroundColor: successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            )
        );
        return true;
      } else {
        // Gestion de l'échec avec message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Échec de la mise à jour du numéro de téléphone"),
                ],
              ),
              backgroundColor: errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            )
        );
        return false;
      }
    } catch (e) {
      // Gestion des erreurs de réseau ou autres
      setLoadingState(false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text("Erreur lors de la mise à jour: $e")),
              ],
            ),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          )
      );
      return false;
    }
  }
}