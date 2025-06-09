import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../services/firebase_token/token_service.dart';

class PhoneApiService {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Met à jour uniquement le numéro de téléphone d'un utilisateur
  /// Format corrigé pour correspondre au backend Django
  static Future<PhoneUpdateResult> updatePhone(String userUuid, String newPhone) async {
    try {
      final apiUrl = '$baseUrl/update_user_phone/$userUuid/';

      // Récupérer le token d'authentification
      final String? authToken = await TokenService.getAuthToken();

      if (authToken == null) {
        print('Erreur: Token d\'authentification non disponible');
        return PhoneUpdateResult(
          success: false,
          message: 'Token d\'authentification non disponible',
          errorType: PhoneUpdateErrorType.authentication,
        );
      }

      // Préparer les headers avec le token d'authentification
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      // CORRECTION : Utiliser "numeroTelephone" (camelCase) comme attendu par Django
      final request = PhoneUpdateRequest(numeroTelephone: newPhone);
      final jsonBody = jsonEncode(request.toJson());

      print('🔍 Envoi de la requête de mise à jour téléphone');
      print('🔍 URL: $apiUrl');
      print('🔍 Corps: $jsonBody');

      // Envoyer la requête PATCH
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonBody,
      );

      print('🔍 Statut réponse: ${response.statusCode}');
      print('🔍 Corps réponse: ${response.body}');

      // Analyser la réponse
      return _handleResponse(response);
    } catch (e) {
      print('❌ Exception lors de la mise à jour du téléphone: $e');
      return PhoneUpdateResult(
        success: false,
        message: 'Erreur de connexion: $e',
        errorType: PhoneUpdateErrorType.network,
      );
    }
  }

  /// Analyse la réponse du serveur et retourne un résultat structuré
  static PhoneUpdateResult _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          final responseData = jsonDecode(response.body);
          return PhoneUpdateResult(
            success: true,
            message: responseData['message'] ?? 'Numéro de téléphone mis à jour avec succès',
            data: responseData,
          );
        } catch (e) {
          return PhoneUpdateResult(
            success: true,
            message: 'Numéro de téléphone mis à jour avec succès',
          );
        }

      case 400:
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Données invalides';

          // Extraire le message d'erreur du backend Django
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }

          return PhoneUpdateResult(
            success: false,
            message: errorMessage,
            errorType: PhoneUpdateErrorType.validation,
            data: errorData,
          );
        } catch (e) {
          return PhoneUpdateResult(
            success: false,
            message: 'Format de numéro de téléphone invalide',
            errorType: PhoneUpdateErrorType.validation,
          );
        }

      case 401:
        return PhoneUpdateResult(
          success: false,
          message: 'Session expirée, veuillez vous reconnecter',
          errorType: PhoneUpdateErrorType.authentication,
        );

      case 403:
        return PhoneUpdateResult(
          success: false,
          message: 'Vous n\'êtes pas autorisé à modifier ce numéro',
          errorType: PhoneUpdateErrorType.authorization,
        );

      case 404:
        return PhoneUpdateResult(
          success: false,
          message: 'Utilisateur non trouvé',
          errorType: PhoneUpdateErrorType.notFound,
        );

      case 500:
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Erreur serveur, veuillez réessayer plus tard';

          if (errorData['error'] != null) {
            errorMessage = 'Erreur serveur: ${errorData['error']}';
          }

          return PhoneUpdateResult(
            success: false,
            message: errorMessage,
            errorType: PhoneUpdateErrorType.server,
            data: errorData,
          );
        } catch (e) {
          return PhoneUpdateResult(
            success: false,
            message: 'Erreur serveur, veuillez réessayer plus tard',
            errorType: PhoneUpdateErrorType.server,
          );
        }

      default:
        return PhoneUpdateResult(
          success: false,
          message: 'Erreur inattendue (${response.statusCode}): ${response.body}',
          errorType: PhoneUpdateErrorType.unknown,
        );
    }
  }
}

/// Classe pour représenter le corps de la requête de mise à jour du téléphone
/// CORRECTION : Utilise "numeroTelephone" comme attendu par le backend Django
class PhoneUpdateRequest {
  final String numeroTelephone;

  PhoneUpdateRequest({required this.numeroTelephone});

  Map<String, dynamic> toJson() {
    return {
      'numeroTelephone': numeroTelephone, // camelCase comme attendu par Django
    };
  }
}

/// Résultat de la mise à jour du numéro de téléphone
class PhoneUpdateResult {
  final bool success;
  final String message;
  final PhoneUpdateErrorType? errorType;
  final Map<String, dynamic>? data;

  PhoneUpdateResult({
    required this.success,
    required this.message,
    this.errorType,
    this.data,
  });
}

/// Types d'erreurs possibles lors de la mise à jour du téléphone
enum PhoneUpdateErrorType {
  validation,      // Erreur de validation (format incorrect, etc.)
  authentication,  // Problème d'authentification
  authorization,   // Problème d'autorisation
  conflict,        // Numéro déjà utilisé (pas utilisé par cette API)
  notFound,        // Utilisateur non trouvé
  network,         // Erreur réseau
  server,          // Erreur serveur
  unknown,         // Erreur inconnue
}














// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../../../services/firebase_token/token_service.dart';
//
// class PhoneApiService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   /// Met à jour uniquement le numéro de téléphone d'un utilisateur
//   /// Inclut automatiquement le token d'authentification
//   static Future<PhoneUpdateResult> updatePhone(String userUuid, String newPhone) async {
//     try {
//       final apiUrl = '$baseUrl/update_user_phone/$userUuid/';
//
//       // Récupérer le token d'authentification
//       final String? authToken = await TokenService.getAuthToken();
//
//       if (authToken == null) {
//         print('Erreur: Token d\'authentification non disponible');
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Token d\'authentification non disponible',
//           errorType: PhoneUpdateErrorType.authentication,
//         );
//       }
//
//       // Préparer les headers avec le token d'authentification
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $authToken',
//       };
//
//       // Créer la requête avec le champ du numéro de téléphone
//       final request = PhoneUpdateRequest(numeroTelephone: newPhone);
//       final jsonBody = jsonEncode(request.toJson());
//
//       print('🔍 Envoi de la requête de mise à jour téléphone');
//       print('🔍 URL: $apiUrl');
//       print('🔍 Corps: $jsonBody');
//
//       // Envoyer la requête PATCH
//       final response = await http.patch(
//         Uri.parse(apiUrl),
//         headers: headers,
//         body: jsonBody,
//       );
//
//       print('🔍 Statut réponse: ${response.statusCode}');
//       print('🔍 Corps réponse: ${response.body}');
//
//       // Analyser la réponse
//       return _handleResponse(response);
//     } catch (e) {
//       print('❌ Exception lors de la mise à jour du téléphone: $e');
//       return PhoneUpdateResult(
//         success: false,
//         message: 'Erreur de connexion: $e',
//         errorType: PhoneUpdateErrorType.network,
//       );
//     }
//   }
//
//   /// Analyse la réponse du serveur et retourne un résultat structuré
//   static PhoneUpdateResult _handleResponse(http.Response response) {
//     switch (response.statusCode) {
//       case 200:
//         try {
//           final responseData = jsonDecode(response.body);
//           return PhoneUpdateResult(
//             success: true,
//             message: responseData['message'] ?? 'Numéro de téléphone mis à jour avec succès',
//             data: responseData,
//           );
//         } catch (e) {
//           return PhoneUpdateResult(
//             success: true,
//             message: 'Numéro de téléphone mis à jour avec succès',
//           );
//         }
//
//       case 400:
//         try {
//           final errorData = jsonDecode(response.body);
//           return PhoneUpdateResult(
//             success: false,
//             message: errorData['message'] ?? 'Données invalides',
//             errorType: PhoneUpdateErrorType.validation,
//             data: errorData,
//           );
//         } catch (e) {
//           return PhoneUpdateResult(
//             success: false,
//             message: 'Format de numéro de téléphone invalide',
//             errorType: PhoneUpdateErrorType.validation,
//           );
//         }
//
//       case 401:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Session expirée, veuillez vous reconnecter',
//           errorType: PhoneUpdateErrorType.authentication,
//         );
//
//       case 403:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Accès non autorisé',
//           errorType: PhoneUpdateErrorType.authorization,
//         );
//
//       case 404:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Utilisateur non trouvé',
//           errorType: PhoneUpdateErrorType.notFound,
//         );
//
//       case 409:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Ce numéro de téléphone est déjà utilisé par un autre compte',
//           errorType: PhoneUpdateErrorType.conflict,
//         );
//
//       case 500:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Erreur serveur, veuillez réessayer plus tard',
//           errorType: PhoneUpdateErrorType.server,
//         );
//
//       default:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Erreur inattendue (${response.statusCode})',
//           errorType: PhoneUpdateErrorType.unknown,
//         );
//     }
//   }
// }
//
// /// Classe pour représenter le corps de la requête de mise à jour du téléphone
// class PhoneUpdateRequest {
//   final String numeroTelephone;
//
//   PhoneUpdateRequest({required this.numeroTelephone});
//
//   Map<String, dynamic> toJson() {
//     return {
//       'numero_telephone': numeroTelephone,
//     };
//   }
// }
//
// /// Résultat de la mise à jour du numéro de téléphone
// class PhoneUpdateResult {
//   final bool success;
//   final String message;
//   final PhoneUpdateErrorType? errorType;
//   final Map<String, dynamic>? data;
//
//   PhoneUpdateResult({
//     required this.success,
//     required this.message,
//     this.errorType,
//     this.data,
//   });
// }
//
// /// Types d'erreurs possibles lors de la mise à jour du téléphone
// enum PhoneUpdateErrorType {
//   validation,      // Erreur de validation (format incorrect, etc.)
//   authentication,  // Problème d'authentification
//   authorization,   // Problème d'autorisation
//   conflict,        // Numéro déjà utilisé
//   notFound,        // Utilisateur non trouvé
//   network,         // Erreur réseau
//   server,          // Erreur serveur
//   unknown,         // Erreur inconnue
// }
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:http/http.dart' as http;
// // import '../../../../../services/firebase_token/token_service.dart';
// //
// // class PhoneApiService {
// //   static const String baseUrl = 'https://www.hairbnb.site/api';
// //
// //   /// Met à jour uniquement le numéro de téléphone d'un utilisateur
// //   /// Inclut automatiquement le token d'authentification
// //   static Future<bool> updatePhone(String userUuid, String newPhone) async {
// //     try {
// //       final apiUrl = '$baseUrl/update_user_phone/$userUuid/';
// //
// //       // Récupérer le token d'authentification
// //       final String? authToken = await TokenService.getAuthToken();
// //
// //       if (authToken == null) {
// //         print('Erreur: Token d\'authentification non disponible');
// //         return false;
// //       }
// //
// //       // Préparer les headers avec le token d'authentification
// //       final headers = {
// //         'Content-Type': 'application/json',
// //         'Authorization': 'Bearer $authToken', // Ajout du token
// //       };
// //
// //       // Créer la requête avec uniquement le champ du numéro de téléphone
// //       //final request = PhoneUpdateRequest(numeroTelephone: newPhone);
// //
// //       // Envoyer la requête PATCH
// //       final response = await http.patch(
// //         Uri.parse(apiUrl),
// //         headers: headers, // Utiliser les headers avec le token
// //         //body: jsonEncode(request.toJson()),
// //       );
// //
// //       // Vérifier le statut de la réponse
// //       if (response.statusCode == 200) {
// //         return true;
// //       } else {
// //         print('Erreur API: ${response.statusCode} - ${response.body}');
// //         return false;
// //       }
// //     } catch (e) {
// //       print('Exception lors de la mise à jour du téléphone: $e');
// //       return false;
// //     }
// //   }
// // }
// //
// // class PhoneUpdateRequest {
// // }