// lib/pages/profil/services/update_services/adress_update/adress_update_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/adresse.dart' as AdresseModel;
import '../../../../../models/current_user.dart' as UserModel;
import '../../../../../services/providers/current_user_provider.dart';
import 'adress_api_service.dart';
import 'adress_validation.dart';

class AddressUpdateService {
  static Future<void> updateUserAddress(
      BuildContext context,
      UserModel.CurrentUser currentUser,
      Map<String, dynamic> addressData, {
        required Color successGreen,
        required Color errorRed,
        required Function(bool) setLoadingState,
      }) async {
    try {
      setLoadingState(true);

      if (kDebugMode) {
        print("🚀 Mise à jour adresse pour ${currentUser.uuid}");
      }

      // Validation supplémentaire si nécessaire
      bool needsValidation = addressData['is_validated'] != true;

      if (needsValidation) {
        if (kDebugMode) {
          print("🔍 Validation supplémentaire...");
        }

        final tempAdresse = AdresseModel.Adresse(
          numero: addressData['numero'],
          rue: AdresseModel.Rue(
            nomRue: addressData['rue']['nomRue'],
            localite: AdresseModel.Localite(
              commune: addressData['rue']['localite']['commune'],
              codePostal: addressData['rue']['localite']['codePostal'],
            ),
          ),
        );

        final validationResult = await AddressValidationService.validateAddress(tempAdresse);

        if (!validationResult.isValid) {
          throw Exception(validationResult.errorMessage ?? "Adresse invalide");
        }

        addressData['latitude'] = validationResult.latitude;
        addressData['longitude'] = validationResult.longitude;
        addressData['is_validated'] = true;
        addressData['validation_date'] = DateTime.now().toIso8601String();
      }

      // Appel API
      final result = await AddressApiService.updateUserAddress(
        userUuid: currentUser.uuid,
        addressData: addressData,
      );

      if (result['success'] == true) {
        if (kDebugMode) {
          print("✅ Succès mise à jour");
        }

        // ✅ NOUVELLE LIGNE - Recharger l'utilisateur depuis le provider
        await _refreshUserInProvider(context);

        _showSuccessMessage(context, "Adresse mise à jour avec succès", successGreen);

      } else {
        throw Exception(result['message'] ?? "Erreur inconnue");
      }

    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur: $e");
      }
      _showErrorMessage(context, "Erreur: $e", errorRed);
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  // ✅ NOUVELLE MÉTHODE - Recharge l'utilisateur via le provider
  static Future<void> _refreshUserInProvider(BuildContext context) async {
    try {
      // Importer le provider
      final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      await currentUserProvider.refreshCurrentUser();

      if (kDebugMode) {
        print("🔄 Provider mis à jour après modification adresse");
      }
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Erreur rechargement provider: $e");
      }
    }
  }



  static void _showSuccessMessage(BuildContext context, String message, Color successColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  static void _showErrorMessage(BuildContext context, String message, Color errorColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 4),
      ),
    );
  }



  static Future<UserModel.Adresse?> getCurrentUserAddress(String userUuid) async {
    try {
      final addressData = await AddressApiService.getUserAddress(userUuid);

      if (addressData != null && addressData['adresse'] != null) {
        // Utiliser le bon constructeur selon votre modèle CurrentUser
        return UserModel.Adresse.fromJson(addressData['adresse']);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur récupération: $e");
      }
      return null;
    }
  }
}