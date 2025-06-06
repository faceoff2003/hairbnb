// // services/profile_api_service.dart
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
//
// import '../../../models/user_creation.dart';
//
// /// Service API pour la gestion des profils utilisateur
// class ProfileApiService {
//   static const String baseUrl = "https://www.hairbnb.site/api";
//
//   /// Crée un profil utilisateur via l'API
//   static Future<UserCreationResponse> createUserProfile({
//     required UserCreationModel userModel,
//     String? firebaseToken,
//   }) async {
//     try {
//       // Validation avant envoi
//       final validationErrors = userModel.validate();
//       if (validationErrors.isNotEmpty) {
//         return UserCreationResponse.error(
//           message: "Erreurs de validation",
//           validationErrors: validationErrors,
//         );
//       }
//
//       final url = Uri.parse("$baseUrl/create-profile/");
//       var request = http.MultipartRequest('POST', url);
//
//       // Ajouter le token d'authentification si fourni
//       if (firebaseToken != null) {
//         request.headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       // Ajouter les champs du formulaire
//       request.fields.addAll(userModel.toApiFields());
//
//       // Ajouter la photo si elle existe
//       if (userModel.photoProfilFile != null || userModel.photoProfilBytes != null) {
//         if (kIsWeb && userModel.photoProfilBytes != null) {
//           request.files.add(
//             http.MultipartFile.fromBytes(
//               'photo_profil',
//               userModel.photoProfilBytes!,
//               filename: userModel.photoProfilName ?? 'profile_photo.png',
//               contentType: MediaType('image', 'png'),
//             ),
//           );
//         } else if (userModel.photoProfilFile != null) {
//           request.files.add(
//             await http.MultipartFile.fromPath(
//               'photo_profil',
//               userModel.photoProfilFile!.path,
//             ),
//           );
//         }
//       }
//
//       // Envoyer la requête
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       // Parser la réponse
//       return UserCreationResponse.fromHttpResponse(
//         statusCode: response.statusCode,
//         body: responseBody,
//       );
//
//     } catch (e) {
//       return UserCreationResponse.error(
//         message: "Erreur de connexion: $e",
//       );
//     }
//   }
//
//   /// Récupère le profil d'un utilisateur
//   static Future<Map<String, dynamic>?> getUserProfile(String userUuid) async {
//     try {
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
//       print("Erreur lors de la récupération du profil: $e");
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
//           'numeroTelephone': newPhone,
//         }),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("Erreur lors de la mise à jour du téléphone: $e");
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
//       print("Erreur lors de la mise à jour de l'adresse: $e");
//       return false;
//     }
//   }
// }
//
//
//
//
// // import 'base_api_service.dart';
// // import 'profile_creation_api.dart';
// //
// // /// Service API pour gérer les opérations liées au profil utilisateur
// // class ProfileApiService {
// //   // Méthode pour mettre à jour le profil utilisateur
// //   static Future<bool> updateUserProfile(
// //       String userUuid,
// //       Map<String, dynamic> updatedData,
// //       {Function(String)? onError}
// //       ) async {
// //     final endpoint = 'update_user_profile/$userUuid/';
// //     final result = await BaseApiService.patch(
// //         endpoint,
// //         updatedData,
// //         onError: onError
// //     );
// //
// //     return result != null;
// //   }
// //
// //   // Méthode spécifique pour mettre à jour l'adresse d'un utilisateur
// //   // static Future<bool> updateUserAddress(
// //   //     String userUuid,
// //   //     AddressUpdateRequest addressRequest,
// //   //     {Function(String)? onError}
// //   //     ) async {
// //   //   // Création de la structure de données pour l'API
// //   //   final Map<String, dynamic> updatedData = {
// //   //     'adresse': addressRequest.toJson()
// //   //   };
// //   //
// //   //   // Utilise la méthode générique updateUserProfile
// //   //   return await updateUserProfile(userUuid, updatedData, onError: onError);
// //   // }
// //
// //   // Méthode spécifique pour mettre à jour un champ simple du profil
// //   static Future<bool> updateUserField(
// //       String userUuid,
// //       String fieldName,
// //       String fieldValue,
// //       {Function(String)? onError}
// //       ) async {
// //     // Crée un Map avec un seul champ
// //     final Map<String, dynamic> updatedData = {
// //       fieldName: fieldValue
// //     };
// //
// //     // Utilise la méthode générique updateUserProfile
// //     return await updateUserProfile(userUuid, updatedData, onError: onError);
// //   }
// //
// //   // Méthode pour récupérer les détails du profil utilisateur
// //   static Future<Map<String, dynamic>?> getUserProfile(
// //       String userUuid,
// //       {Function(String)? onError}
// //       ) async {
// //     final endpoint = 'user_profile/$userUuid/';
// //     return await BaseApiService.get(endpoint, onError: onError);
// //   }
// // }