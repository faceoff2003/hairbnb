// lib/pages/profil/services/update_services/adress_update/adress_update_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/current_user.dart';
import '../../../../../services/providers/current_user_provider.dart';
import 'adress_api_service.dart';

class AddressUpdateService {
  static Future<bool> updateUserAddress(
      BuildContext context,
      CurrentUser currentUser,
      Map<String, dynamic> addressData, {
        required Color successGreen,
        required Color errorRed,
        required Function(bool) setLoadingState,
      }) async {
    // Définir l'état de chargement
    setLoadingState(true);

    try {
      // Appeler l'API pour mettre à jour l'adresse
      final success = await AddressApiService.updateAddress(currentUser.uuid, addressData);

      // Désactiver l'état de chargement
      setLoadingState(false);

      if (success) {
        try {
          // Conversion des données pour mise à jour locale
          //final addressRequest = AddressUpdateRequest.fromJson(addressData);

          // Mettre à jour localement l'adresse si possible
          if (currentUser.adresse != null) {
            //currentUser.adresse?.numero = addressRequest.numero;
            //currentUser.adresse?.boitePostale = addressRequest.boitePostale;

            if (currentUser.adresse?.rue != null) {
              //currentUser.adresse?.rue?.nomRue = addressRequest.rue?.nomRue;

              if (currentUser.adresse?.rue?.localite != null) {
                //currentUser.adresse?.rue?.localite?.commune = addressRequest.rue?.localite?.commune;
                //currentUser.adresse?.rue?.localite?.codePostal = addressRequest.rue?.localite?.codePostal;
              }
            }
          }
        } catch (e) {
          // En cas d'erreur lors de la mise à jour locale, on continue quand même
          // car nous allons rafraîchir l'utilisateur depuis le serveur
          print("Erreur lors de la mise à jour locale: $e");
        }

        // Mettre à jour via le provider pour propager le changement partout
        final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        await userProvider.fetchCurrentUser(); // Recharger l'utilisateur depuis le serveur

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Adresse mise à jour avec succès"),
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
                  Text("Échec de la mise à jour de l'adresse"),
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

class AddressUpdateRequest {
}












// // lib/pages/profil/services/update_services/adress_update/adress_update_service.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../../models/current_user.dart';
// import '../../../../../services/providers/current_user_provider.dart';
// import '../../profile_creation_api.dart';
// import 'adress_api_service.dart';
//
// class AddressUpdateService {
//   static Future<bool> updateUserAddress(
//       BuildContext context,
//       CurrentUser currentUser,
//       Map<String, dynamic> addressData, {
//         required Color successGreen,
//         required Color errorRed,
//         required Function(bool) setLoadingState,
//       }) async {
//     // Définir l'état de chargement
//     setLoadingState(true);
//
//     try {
//       // Appeler l'API pour mettre à jour l'adresse
//       final success = await AddressApiService.updateAddress(currentUser.uuid, addressData);
//       final addressRequest = AddressUpdateRequest.fromJson(addressData);
//
//       if (success) {
//         // Mettre à jour localement l'adresse
//         currentUser.adresse?.numero = addressRequest.numero;
//         currentUser.adresse?.boitePostale = addressRequest.boitePostale;
//         currentUser.adresse?.rue?.nomRue = addressRequest.rue?.nomRue;
//         currentUser.adresse?.rue?.localite?.commune = addressRequest.rue?.localite?.commune;
//         currentUser.adresse?.rue?.localite?.codePostal = addressRequest.rue?.localite?.codePostal;
//
//         // Mettre à jour via le provider
//         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         await userProvider.fetchCurrentUser();
//
//         // Message de succès...
//
//
//
//
//
//         // Désactiver l'état de chargement
//       setLoadingState(false);
//
//       if (success) {
//         // 1. Mettre à jour localement (si nécessaire, mais généralement pas besoin car l'adresse est un objet complexe)
//         // L'adresse sera mise à jour via le fetchCurrentUser
//
//         // 2. Mettre à jour via le provider pour propager le changement partout
//         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         await userProvider.fetchCurrentUser(); // Recharger l'utilisateur depuis le serveur
//
//         // 3. Afficher un message de succès
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: const [
//                   Icon(Icons.check_circle, color: Colors.white),
//                   SizedBox(width: 12),
//                   Text("Adresse mise à jour avec succès"),
//                 ],
//               ),
//               backgroundColor: successGreen,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               margin: const EdgeInsets.all(10),
//             )
//         );
//         return true;
//       } else {
//         // Gestion de l'échec avec message d'erreur
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: const [
//                   Icon(Icons.error_outline, color: Colors.white),
//                   SizedBox(width: 12),
//                   Text("Échec de la mise à jour de l'adresse"),
//                 ],
//               ),
//               backgroundColor: errorRed,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               margin: const EdgeInsets.all(10),
//             )
//         );
//         return false;
//       }
//       }
//     } catch (e) {
//       // Gestion des erreurs de réseau ou autres
//       setLoadingState(false);
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.white),
//                 const SizedBox(width: 12),
//                 Expanded(child: Text("Erreur lors de la mise à jour: $e")),
//               ],
//             ),
//             backgroundColor: errorRed,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//             margin: const EdgeInsets.all(10),
//           )
//       );
//       return false;
//     }
//   }
// }







// // lib/pages/profil/services/update_services/address_update/address_update_service.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/firebase_token/token_service.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
//
// class AddressUpdateService {
//   static Future<bool> updateUserAddress(
//       BuildContext context,
//       CurrentUser currentUser,
//       Map<String, dynamic> addressData, {
//         required Color successGreen,
//         required Color errorRed,
//         required Function(bool) setLoadingState,
//       }) async {
//     // Définir l'état de chargement
//     setLoadingState(true);
//
//     // Utiliser la nouvelle URL spécifique pour la mise à jour d'adresse
//     final String apiUrl = 'https://www.hairbnb.site/api/update_user_address/${currentUser.uuid}/';
//
//     try {
//       // Récupérer le token d'authentification
//       String? authToken = await TokenService.getAuthToken();
//
//       if (authToken == null || authToken.isEmpty) {
//         setLoadingState(false);
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: const [
//                   Icon(Icons.error_outline, color: Colors.white),
//                   SizedBox(width: 12),
//                   Text("Erreur d'authentification: Veuillez vous reconnecter"),
//                 ],
//               ),
//               backgroundColor: errorRed,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               margin: const EdgeInsets.all(10),
//             )
//         );
//         return false;
//       }
//
//       // Envoyer la requête avec le token
//       final response = await http.patch(
//         Uri.parse(apiUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $authToken'
//         },
//         body: jsonEncode(addressData),
//       );
//
//       setLoadingState(false);
//
//       if (response.statusCode == 200) {
//         // Mettre à jour via le provider pour propager le changement partout
//         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         await userProvider.fetchCurrentUser(); // Recharger l'utilisateur depuis le serveur
//
//         // Afficher un message de succès
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: const [
//                   Icon(Icons.check_circle, color: Colors.white),
//                   SizedBox(width: 12),
//                   Text("Adresse mise à jour avec succès"),
//                 ],
//               ),
//               backgroundColor: successGreen,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               margin: const EdgeInsets.all(10),
//             )
//         );
//         return true;
//       } else {
//         // Décoder la réponse pour obtenir le message d'erreur détaillé
//         String errorMessage = "Échec de la mise à jour: ${response.statusCode}";
//
//         try {
//           final responseData = json.decode(response.body);
//           if (responseData.containsKey('detail')) {
//             errorMessage = responseData['detail'];
//           }
//         } catch (e) {
//           // Si le décodage échoue, on conserve le message d'erreur par défaut
//         }
//
//         // Gestion de l'échec avec message d'erreur
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const Icon(Icons.error_outline, color: Colors.white),
//                   const SizedBox(width: 12),
//                   Expanded(child: Text(errorMessage)),
//                 ],
//               ),
//               backgroundColor: errorRed,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               margin: const EdgeInsets.all(10),
//             )
//         );
//         return false;
//       }
//     } catch (e) {
//       // Gestion des erreurs de réseau ou autres
//       setLoadingState(false);
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.white),
//                 const SizedBox(width: 12),
//                 Expanded(child: Text("Erreur lors de la mise à jour de l'adresse: $e")),
//               ],
//             ),
//             backgroundColor: errorRed,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//             margin: const EdgeInsets.all(10),
//           )
//       );
//       return false;
//     }
//   }
// }
