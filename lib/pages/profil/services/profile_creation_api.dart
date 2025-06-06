// services/profile_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../models/user_creation.dart';
import '../../../services/firebase_token/token_service.dart';

/// Service API pour la gestion des profils utilisateur
class ProfileApiService {
  static const String baseUrl = "https://www.hairbnb.site/api";

  /// Crée un profil utilisateur via l'API
  static Future<UserCreationResponse> createUserProfile({
    required UserCreationModel userModel,
    String? firebaseToken,
  }) async {
    try {
      // 1. Validation des données avant l'envoi
      final validationErrors = userModel.validate();
      if (validationErrors.isNotEmpty) {
        return UserCreationResponse.error(
          message: "Erreurs de validation",
          validationErrors: validationErrors,
        );
      }

      // 2. Définition de l'URL pour la création de profil
      // L'URL est correcte : baseUrl + /create-profile/
      final url = Uri.parse("$baseUrl/create-profile/");
      var request = http.MultipartRequest('POST', url);

      // 3. Récupération et ajout du token d'authentification Firebase
      String? authToken = firebaseToken;
      // Si le token n'est pas directement fourni, essayer de le récupérer via TokenService
      authToken ??= await TokenService.getAuthToken();

      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
        if (kDebugMode) {
          print("🔐 Token ajouté à la requête");
        }
      } else {
        if (kDebugMode) {
          print("⚠️ Aucun token d'authentification disponible");
        }
      }

      // 4. Ajout des champs de texte du modèle utilisateur à la requête
      // userModel.toApiFields() enverra maintenant le champ 'type'
      request.fields.addAll(userModel.toApiFields());

      //5. Ajout de la photo de profil (si présente)
      if (userModel.photoProfilFile != null || userModel.photoProfilBytes != null) {
        if (kIsWeb && userModel.photoProfilBytes != null) {
          // Pour le web, utilisez les bytes de l'image
          request.files.add(
            http.MultipartFile.fromBytes(
              'photo_profil',
              userModel.photoProfilBytes!,
              filename: userModel.photoProfilName ?? 'profile_photo.png',
              contentType: MediaType('image', 'png'), // Définir le type de contenu
            ),
          );
        } else if (userModel.photoProfilFile != null) {
          // Pour les plateformes mobiles/desktop, utilisez le chemin du fichier
          request.files.add(
            await http.MultipartFile.fromPath(
              'photo_profil',
              userModel.photoProfilFile!.path,
            ),
          );
        }
      }

      // 6. Envoi de la requête et lecture de la réponse
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print("📡 Réponse API (${response.statusCode}): $responseBody");
      }

      // 7. Parsing et retour de la réponse de l'API
      return UserCreationResponse.fromHttpResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );

    } catch (e) {
      // Gestion des erreurs de connexion ou autres exceptions
      if (kDebugMode) {
        print("❌ Erreur dans createUserProfile: $e");
      }
      return UserCreationResponse.error(
        message: "Erreur de connexion: $e",
      );
    }
  }

  /// Récupère le profil d'un utilisateur par son UUID
  static Future<Map<String, dynamic>?> getUserProfile(String userUuid) async {
    try {
      // CORRECTION DE L'URL : Suppression du '/api/' en double
      final url = Uri.parse("$baseUrl/get_user_profile/$userUuid/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération du profil: $e");
      }
      return null;
    }
  }

  /// Met à jour le numéro de téléphone d'un utilisateur
  static Future<bool> updatePhoneNumber({
    required String userUuid,
    required String newPhone,
    String? firebaseToken,
  }) async {
    try {
      // CORRECTION DE L'URL : Suppression du '/api/' en double
      final url = Uri.parse("$baseUrl/update_user_phone/$userUuid/");
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (firebaseToken != null) {
        headers['Authorization'] = 'Bearer $firebaseToken';
      }

      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode({
          'numeroTelephone': newPhone,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du téléphone: $e");
      }
      return false;
    }
  }

  /// Met à jour l'adresse d'un utilisateur
  static Future<bool> updateAddress({
    required String userUuid,
    required Map<String, dynamic> addressData,
    String? firebaseToken,
  }) async {
    try {
      // CORRECTION DE L'URL : Suppression du '/api/' en double
      final url = Uri.parse("$baseUrl/update_user_address/$userUuid/");
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (firebaseToken != null) {
        headers['Authorization'] = 'Bearer $firebaseToken';
      }

      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode(addressData),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour de l'adresse: $e");
      }
      return false;
    }
  }
}







// // services/profile_api_service.dart
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
//
// import '../../../models/user_creation.dart';
// import '../../../services/firebase_token/token_service.dart'; // Assurez-vous que ce chemin est correct
//
// /// Service API pour la gestion des profils utilisateur
// class ProfileApiService {
//   // Base URL de l'API. Elle inclut déjà '/api'.
//   static const String baseUrl = "https://www.hairbnb.site/api";
//
//   /// Crée un profil utilisateur via l'API
//   static Future<UserCreationResponse> createUserProfile({
//     required UserCreationModel userModel,
//     String? firebaseToken,
//   }) async {
//     try {
//       // 1. Validation des données avant l'envoi
//       final validationErrors = userModel.validate();
//       if (validationErrors.isNotEmpty) {
//         return UserCreationResponse.error(
//           message: "Erreurs de validation",
//           validationErrors: validationErrors,
//         );
//       }
//
//       // 2. Définition de l'URL pour la création de profil
//       // L'URL est correcte : baseUrl + /create-profile/
//       final url = Uri.parse("$baseUrl/create-profile/");
//       var request = http.MultipartRequest('POST', url);
//
//       // 3. Récupération et ajout du token d'authentification Firebase
//       String? authToken = firebaseToken;
//       // Si le token n'est pas directement fourni, essayer de le récupérer via TokenService
//       authToken ??= await TokenService.getAuthToken();
//
//       if (authToken != null && authToken.isNotEmpty) {
//         request.headers['Authorization'] = 'Bearer $authToken';
//         if (kDebugMode) {
//           print("🔐 Token ajouté à la requête");
//         }
//       } else {
//         if (kDebugMode) {
//           print("⚠️ Aucun token d'authentification disponible");
//         }
//       }
//
//       // 4. Ajout des champs de texte du modèle utilisateur à la requête
//       // userModel.toApiFields() enverra maintenant le champ 'type'
//       request.fields.addAll(userModel.toApiFields());
//
//       // 5. Ajout de la photo de profil (si présente)
//       if (userModel.photoProfilFile != null || userModel.photoProfilBytes != null) {
//         if (kIsWeb && userModel.photoProfilBytes != null) {
//           // Pour le web, utilisez les bytes de l'image
//           request.files.add(
//             http.MultipartFile.fromBytes(
//               'photo_profil',
//               userModel.photoProfilBytes!,
//               filename: userModel.photoProfilName ?? 'profile_photo.png',
//               contentType: MediaType('image', 'png'), // Définir le type de contenu
//             ),
//           );
//         } else if (userModel.photoProfilFile != null) {
//           // Pour les plateformes mobiles/desktop, utilisez le chemin du fichier
//           request.files.add(
//             await http.MultipartFile.fromPath(
//               'photo_profil',
//               userModel.photoProfilFile!.path,
//             ),
//           );
//         }
//       }
//
//       // 6. Envoi de la requête et lecture de la réponse
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (kDebugMode) {
//         print("📡 Réponse API (${response.statusCode}): $responseBody");
//       }
//
//       // 7. Parsing et retour de la réponse de l'API
//       return UserCreationResponse.fromHttpResponse(
//         statusCode: response.statusCode,
//         body: responseBody,
//       );
//
//     } catch (e) {
//       // Gestion des erreurs de connexion ou autres exceptions
//       if (kDebugMode) {
//         print("❌ Erreur dans createUserProfile: $e");
//       }
//       return UserCreationResponse.error(
//         message: "Erreur de connexion: $e",
//       );
//     }
//   }
//
//   /// Récupère le profil d'un utilisateur par son UUID
//   static Future<Map<String, dynamic>?> getUserProfile(String userUuid) async {
//     try {
//       // CORRECTION DE L'URL : Suppression du '/api/' en double
//       final url = Uri.parse("$baseUrl/get_user_profile/$userUuid/");
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data'];
//         }
//       }
//       return null;
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur lors de la récupération du profil: $e");
//       }
//       return null;
//     }
//   }
//
//   /// Met à jour le numéro de téléphone d'un utilisateur
//   static Future<bool> updatePhoneNumber({
//     required String userUuid,
//     required String newPhone,
//     String? firebaseToken,
//   }) async {
//     try {
//       // CORRECTION DE L'URL : Suppression du '/api/' en double
//       final url = Uri.parse("$baseUrl/update_user_phone/$userUuid/");
//       final headers = <String, String>{
//         'Content-Type': 'application/json',
//       };
//
//       if (firebaseToken != null) {
//         headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       final response = await http.patch(
//         url,
//         headers: headers,
//         body: json.encode({
//           'numeroTelephone': newPhone, // Assurez-vous que le nom du champ correspond à l'API
//         }),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur lors de la mise à jour du téléphone: $e");
//       }
//       return false;
//     }
//   }
//
//   /// Met à jour l'adresse d'un utilisateur
//   static Future<bool> updateAddress({
//     required String userUuid,
//     required Map<String, dynamic> addressData,
//     String? firebaseToken,
//   }) async {
//     try {
//       // CORRECTION DE L'URL : Suppression du '/api/' en double
//       final url = Uri.parse("$baseUrl/update_user_address/$userUuid/");
//       final headers = <String, String>{
//         'Content-Type': 'application/json',
//       };
//
//       if (firebaseToken != null) {
//         headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       final response = await http.patch(
//         url,
//         headers: headers,
//         body: json.encode(addressData),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur lors de la mise à jour de l'adresse: $e");
//       }
//       return false;
//     }
//   }
// }
//
//
//
//
//
//
// // // services/profile_api_service.dart
// // import 'dart:convert';
// // import 'package:flutter/foundation.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:http_parser/http_parser.dart';
// //
// // import '../../../models/user_creation.dart';
// // import '../../../services/firebase_token/token_service.dart';
// //
// // /// Service API pour la gestion des profils utilisateur
// // class ProfileApiService {
// //   static const String baseUrl = "https://www.hairbnb.site/api";
// //
// //   /// Crée un profil utilisateur via l'API
// //   static Future<UserCreationResponse> createUserProfile({
// //     required UserCreationModel userModel,
// //     String? firebaseToken,
// //   }) async {
// //     try {
// //       // Validation avant envoi
// //       final validationErrors = userModel.validate();
// //       if (validationErrors.isNotEmpty) {
// //         return UserCreationResponse.error(
// //           message: "Erreurs de validation",
// //           validationErrors: validationErrors,
// //         );
// //       }
// //
// //       final url = Uri.parse("$baseUrl/create-profile/");
// //       var request = http.MultipartRequest('POST', url);
// //
// //       // Utiliser le token fourni ou récupérer via TokenService
// //       String? authToken = firebaseToken;
// //       authToken ??= await TokenService.getAuthToken();
// //
// //       // Ajouter le token d'authentification si disponible
// //       if (authToken != null && authToken.isNotEmpty) {
// //         request.headers['Authorization'] = 'Bearer $authToken';
// //         if (kDebugMode) {
// //           print("🔐 Token ajouté à la requête");
// //         }
// //       } else {
// //         if (kDebugMode) {
// //           print("⚠️ Aucun token d'authentification disponible");
// //         }
// //       }
// //
// //       // Ajouter les champs du formulaire
// //       request.fields.addAll(userModel.toApiFields());
// //
// //       // Ajouter la photo si elle existe
// //       if (userModel.photoProfilFile != null || userModel.photoProfilBytes != null) {
// //         if (kIsWeb && userModel.photoProfilBytes != null) {
// //           request.files.add(
// //             http.MultipartFile.fromBytes(
// //               'photo_profil',
// //               userModel.photoProfilBytes!,
// //               filename: userModel.photoProfilName ?? 'profile_photo.png',
// //               contentType: MediaType('image', 'png'),
// //             ),
// //           );
// //         } else if (userModel.photoProfilFile != null) {
// //           request.files.add(
// //             await http.MultipartFile.fromPath(
// //               'photo_profil',
// //               userModel.photoProfilFile!.path,
// //             ),
// //           );
// //         }
// //       }
// //
// //       // Envoyer la requête
// //       final response = await request.send();
// //       final responseBody = await response.stream.bytesToString();
// //
// //       if (kDebugMode) {
// //         print("📡 Réponse API (${response.statusCode}): $responseBody");
// //       }
// //
// //       // Parser la réponse
// //       return UserCreationResponse.fromHttpResponse(
// //         statusCode: response.statusCode,
// //         body: responseBody,
// //       );
// //
// //     } catch (e) {
// //       if (kDebugMode) {
// //         print("❌ Erreur dans createUserProfile: $e");
// //       }
// //       return UserCreationResponse.error(
// //         message: "Erreur de connexion: $e",
// //       );
// //     }
// //   }
// //
// //   /// Récupère le profil d'un utilisateur
// //   static Future<Map<String, dynamic>?> getUserProfile(String userUuid) async {
// //     try {
// //       final url = Uri.parse("$baseUrl/api/get_user_profile/$userUuid/");
// //       final response = await http.get(url);
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         if (data['success'] == true) {
// //           return data['data'];
// //         }
// //       }
// //       return null;
// //     } catch (e) {
// //       if (kDebugMode) {
// //         print("Erreur lors de la récupération du profil: $e");
// //       }
// //       return null;
// //     }
// //   }
// //
// //   /// Met à jour le numéro de téléphone d'un utilisateur
// //   static Future<bool> updatePhoneNumber({
// //     required String userUuid,
// //     required String newPhone,
// //     String? firebaseToken,
// //   }) async {
// //     try {
// //       final url = Uri.parse("$baseUrl/api/update_user_phone/$userUuid/");
// //       final headers = <String, String>{
// //         'Content-Type': 'application/json',
// //       };
// //
// //       if (firebaseToken != null) {
// //         headers['Authorization'] = 'Bearer $firebaseToken';
// //       }
// //
// //       final response = await http.patch(
// //         url,
// //         headers: headers,
// //         body: json.encode({
// //           'numeroTelephone': newPhone,
// //         }),
// //       );
// //
// //       return response.statusCode == 200;
// //     } catch (e) {
// //       if (kDebugMode) {
// //         print("Erreur lors de la mise à jour du téléphone: $e");
// //       }
// //       return false;
// //     }
// //   }
// //
// //   /// Met à jour l'adresse d'un utilisateur
// //   static Future<bool> updateAddress({
// //     required String userUuid,
// //     required Map<String, dynamic> addressData,
// //     String? firebaseToken,
// //   }) async {
// //     try {
// //       final url = Uri.parse("$baseUrl/api/update_user_address/$userUuid/");
// //       final headers = <String, String>{
// //         'Content-Type': 'application/json',
// //       };
// //
// //       if (firebaseToken != null) {
// //         headers['Authorization'] = 'Bearer $firebaseToken';
// //       }
// //
// //       final response = await http.patch(
// //         url,
// //         headers: headers,
// //         body: json.encode(addressData),
// //       );
// //
// //       return response.statusCode == 200;
// //     } catch (e) {
// //       if (kDebugMode) {
// //         print("Erreur lors de la mise à jour de l'adresse: $e");
// //       }
// //       return false;
// //     }
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'dart:convert';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:http_parser/http_parser.dart';
// // //
// // // import '../../../models/user_creation.dart';
// // //
// // // /// Service API pour la gestion des profils utilisateur
// // // class ProfileApiService {
// // //   static const String baseUrl = "https://www.hairbnb.site";
// // //
// // //   /// Crée un profil utilisateur via l'API
// // //   static Future<UserCreationResponse> createUserProfile({
// // //     required UserCreationModel userModel,
// // //     String? firebaseToken,
// // //   }) async {
// // //     try {
// // //       // Validation avant envoi
// // //       final validationErrors = userModel.validate();
// // //       if (validationErrors.isNotEmpty) {
// // //         return UserCreationResponse.error(
// // //           message: "Erreurs de validation",
// // //           validationErrors: validationErrors,
// // //         );
// // //       }
// // //
// // //       final url = Uri.parse("$baseUrl/api/create-profile/");
// // //       var request = http.MultipartRequest('POST', url);
// // //
// // //       // Ajouter le token d'authentification si fourni
// // //       if (firebaseToken != null) {
// // //         request.headers['Authorization'] = 'Bearer $firebaseToken';
// // //       }
// // //
// // //       // Ajouter les champs du formulaire
// // //       request.fields.addAll(userModel.toApiFields());
// // //
// // //       // Ajouter la photo si elle existe
// // //       if (userModel.photoProfilFile != null || userModel.photoProfilBytes != null) {
// // //         if (kIsWeb && userModel.photoProfilBytes != null) {
// // //           request.files.add(
// // //             http.MultipartFile.fromBytes(
// // //               'photo_profil',
// // //               userModel.photoProfilBytes!,
// // //               filename: userModel.photoProfilName ?? 'profile_photo.png',
// // //               contentType: MediaType('image', 'png'),
// // //             ),
// // //           );
// // //         } else if (userModel.photoProfilFile != null) {
// // //           request.files.add(
// // //             await http.MultipartFile.fromPath(
// // //               'photo_profil',
// // //               userModel.photoProfilFile!.path,
// // //             ),
// // //           );
// // //         }
// // //       }
// // //
// // //       // Envoyer la requête
// // //       final response = await request.send();
// // //       final responseBody = await response.stream.bytesToString();
// // //
// // //       // Parser la réponse
// // //       return UserCreationResponse.fromHttpResponse(
// // //         statusCode: response.statusCode,
// // //         body: responseBody,
// // //       );
// // //
// // //     } catch (e) {
// // //       return UserCreationResponse.error(
// // //         message: "Erreur de connexion: $e",
// // //       );
// // //     }
// // //   }
// // //
// // //   /// Récupère le profil d'un utilisateur
// // //   static Future<Map<String, dynamic>?> getUserProfile(String userUuid) async {
// // //     try {
// // //       final url = Uri.parse("$baseUrl/api/get_user_profile/$userUuid/");
// // //       final response = await http.get(url);
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //         if (data['success'] == true) {
// // //           return data['data'];
// // //         }
// // //       }
// // //       return null;
// // //     } catch (e) {
// // //       print("Erreur lors de la récupération du profil: $e");
// // //       return null;
// // //     }
// // //   }
// // //
// // //   /// Met à jour le numéro de téléphone d'un utilisateur
// // //   static Future<bool> updatePhoneNumber({
// // //     required String userUuid,
// // //     required String newPhone,
// // //     String? firebaseToken,
// // //   }) async {
// // //     try {
// // //       final url = Uri.parse("$baseUrl/api/update_user_phone/$userUuid/");
// // //       final headers = <String, String>{
// // //         'Content-Type': 'application/json',
// // //       };
// // //
// // //       if (firebaseToken != null) {
// // //         headers['Authorization'] = 'Bearer $firebaseToken';
// // //       }
// // //
// // //       final response = await http.patch(
// // //         url,
// // //         headers: headers,
// // //         body: json.encode({
// // //           'numeroTelephone': newPhone,
// // //         }),
// // //       );
// // //
// // //       return response.statusCode == 200;
// // //     } catch (e) {
// // //       print("Erreur lors de la mise à jour du téléphone: $e");
// // //       return false;
// // //     }
// // //   }
// // //
// // //   /// Met à jour l'adresse d'un utilisateur
// // //   static Future<bool> updateAddress({
// // //     required String userUuid,
// // //     required Map<String, dynamic> addressData,
// // //     String? firebaseToken,
// // //   }) async {
// // //     try {
// // //       final url = Uri.parse("$baseUrl/api/update_user_address/$userUuid/");
// // //       final headers = <String, String>{
// // //         'Content-Type': 'application/json',
// // //       };
// // //
// // //       if (firebaseToken != null) {
// // //         headers['Authorization'] = 'Bearer $firebaseToken';
// // //       }
// // //
// // //       final response = await http.patch(
// // //         url,
// // //         headers: headers,
// // //         body: json.encode(addressData),
// // //       );
// // //
// // //       return response.statusCode == 200;
// // //     } catch (e) {
// // //       print("Erreur lors de la mise à jour de l'adresse: $e");
// // //       return false;
// // //     }
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // //
// // // // class ProfileUpdateRequest {
// // // //   final String? nom;
// // // //   final String? prenom;
// // // //   final String? email;
// // // //   final String? numeroTelephone;
// // // //   final Map<String, dynamic>? adresse;
// // // //   final Map<String, dynamic>? coiffeuse;
// // // //
// // // //   ProfileUpdateRequest({
// // // //     this.nom,
// // // //     this.prenom,
// // // //     this.email,
// // // //     this.numeroTelephone,
// // // //     this.adresse,
// // // //     this.coiffeuse,
// // // //   });
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     final Map<String, dynamic> data = {};
// // // //     if (nom != null) data['nom'] = nom;
// // // //     if (prenom != null) data['prenom'] = prenom;
// // // //     if (email != null) data['email'] = email;
// // // //     // Utiliser le nom du champ tel qu'attendu par l'API
// // // //     if (numeroTelephone != null) data['numero_telephone'] = numeroTelephone;
// // // //     if (adresse != null) data['adresse'] = adresse;
// // // //     if (coiffeuse != null) data['coiffeuse'] = coiffeuse;
// // // //     return data;
// // // //   }
// // // //
// // // //   factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) {
// // // //     return ProfileUpdateRequest(
// // // //       nom: json['nom'],
// // // //       prenom: json['prenom'],
// // // //       email: json['email'],
// // // //       // Accepter les deux formats pour plus de flexibilité
// // // //       numeroTelephone: json['numeroTelephone'] ?? json['numero_telephone'],
// // // //       adresse: json['adresse'],
// // // //       coiffeuse: json['coiffeuse'],
// // // //     );
// // // //   }
// // // //
// // // //   // Méthode d'aide pour créer une requête avec les champs de l'adresse
// // // //   static Map<String, dynamic> createAddressData({
// // // //     required String numero,
// // // //     List<String>? boitesPostales,
// // // //     String? nomRue,
// // // //     String? commune,
// // // //     String? codePostal
// // // //   }) {
// // // //     final Map<String, dynamic> addressData = {'numero': numero};
// // // //
// // // //     // Ajouter les boîtes postales si fournies
// // // //     if (boitesPostales != null && boitesPostales.isNotEmpty) {
// // // //       addressData['boitesPostales'] = boitesPostales;
// // // //     }
// // // //
// // // //     // Ajouter les données de rue si nécessaire
// // // //     if (nomRue != null || commune != null || codePostal != null) {
// // // //       final Map<String, dynamic> rueData = {};
// // // //
// // // //       if (nomRue != null) {
// // // //         rueData['nomRue'] = nomRue;
// // // //       }
// // // //
// // // //       // Ajouter les données de localité si nécessaire
// // // //       if (commune != null || codePostal != null) {
// // // //         final Map<String, dynamic> localiteData = {};
// // // //
// // // //         if (commune != null) {
// // // //           localiteData['commune'] = commune;
// // // //         }
// // // //
// // // //         if (codePostal != null) {
// // // //           localiteData['codePostal'] = codePostal;
// // // //         }
// // // //
// // // //         rueData['localite'] = localiteData;
// // // //       }
// // // //
// // // //       addressData['rue'] = rueData;
// // // //     }
// // // //
// // // //     return addressData;
// // // //   }
// // // //
// // // //   // Méthode d'aide pour créer une requête avec les champs de la coiffeuse
// // // //   static Map<String, dynamic> createCoiffeuseData({
// // // //     String? nomCommercial,
// // // //     String? numeroTva
// // // //   }) {
// // // //     final Map<String, dynamic> coiffeuseData = {};
// // // //
// // // //     if (nomCommercial != null) {
// // // //       coiffeuseData['nom_commercial'] = nomCommercial;
// // // //     }
// // // //
// // // //     if (numeroTva != null) {
// // // //       coiffeuseData['numero_tva'] = numeroTva;
// // // //     }
// // // //
// // // //     return coiffeuseData;
// // // //   }
// // // // }
// // // //
// // // // class AddressUpdateRequest {
// // // //   final String? numero;
// // // //   final String? boitePostale;
// // // //   final RueUpdateRequest? rue;
// // // //
// // // //   AddressUpdateRequest({
// // // //     this.numero,
// // // //     this.boitePostale,
// // // //     this.rue,
// // // //   });
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     final Map<String, dynamic> data = {};
// // // //     if (numero != null) data['numero'] = numero;
// // // //     if (boitePostale != null) data['boitePostale'] = boitePostale;
// // // //     if (rue != null) data['rue'] = rue!.toJson();
// // // //     return data;
// // // //   }
// // // //
// // // //   factory AddressUpdateRequest.fromJson(Map<String, dynamic> json) {
// // // //     return AddressUpdateRequest(
// // // //       numero: json['numero'],
// // // //       boitePostale: json['boitePostale'],
// // // //       rue: json['rue'] != null ? RueUpdateRequest.fromJson(json['rue']) : null,
// // // //     );
// // // //   }
// // // // }
// // // //
// // // // class RueUpdateRequest {
// // // //   final String? nomRue;
// // // //   final LocaliteUpdateRequest? localite;
// // // //
// // // //   RueUpdateRequest({
// // // //     this.nomRue,
// // // //     this.localite,
// // // //   });
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     final Map<String, dynamic> data = {};
// // // //     if (nomRue != null) data['nomRue'] = nomRue;
// // // //     if (localite != null) data['localite'] = localite!.toJson();
// // // //     return data;
// // // //   }
// // // //
// // // //   factory RueUpdateRequest.fromJson(Map<String, dynamic> json) {
// // // //     return RueUpdateRequest(
// // // //       nomRue: json['nomRue'],
// // // //       localite: json['localite'] != null
// // // //           ? LocaliteUpdateRequest.fromJson(json['localite'])
// // // //           : null,
// // // //     );
// // // //   }
// // // // }
// // // //
// // // // class LocaliteUpdateRequest {
// // // //   final String? commune;
// // // //   final String? codePostal;
// // // //
// // // //   LocaliteUpdateRequest({
// // // //     this.commune,
// // // //     this.codePostal,
// // // //   });
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     final Map<String, dynamic> data = {};
// // // //     if (commune != null) data['commune'] = commune;
// // // //     if (codePostal != null) data['codePostal'] = codePostal;
// // // //     return data;
// // // //   }
// // // //
// // // //   factory LocaliteUpdateRequest.fromJson(Map<String, dynamic> json) {
// // // //     return LocaliteUpdateRequest(
// // // //       commune: json['commune'],
// // // //       codePostal: json['codePostal'],
// // // //     );
// // // //   }
// // // // }
// // // //
// // // // class PhoneUpdateRequest {
// // // //   final String numeroTelephone;
// // // //
// // // //   PhoneUpdateRequest({
// // // //     required this.numeroTelephone,
// // // //   });
// // // //
// // // //   Map<String, dynamic> toJson() {
// // // //     return {
// // // //       'numeroTelephone': numeroTelephone,
// // // //     };
// // // //   }
// // // // }