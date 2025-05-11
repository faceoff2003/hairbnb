// lib/api/gallery_api.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../models/public_salon_details.dart';

class GalleryApi {
  static const String baseUrl = 'https://hairbnb.site/api';

  /// Récupère les images d'un salon
  static Future<List<SalonImage>> getSalonImages(int salonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/salon/$salonId/images/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SalonImage.fromJson(json)).toList();
      } else {
        throw Exception('Échec de récupération des images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des images: $e');
    }
  }

  /// Télécharge des images sur le serveur (pour les plateformes natives)
  static Future<List<SalonImage>> uploadImages(int salonId, List<File> images) async {
    try {
      final url = Uri.parse('$baseUrl/add_images_to_salon/');
      final request = http.MultipartRequest('POST', url);

      // Ajouter l'ID du salon
      request.fields['salon'] = salonId.toString();

      // Ajouter chaque image à la requête
      for (final image in images) {
        final fileStream = http.ByteStream(image.openRead());
        final fileLength = await image.length();
        final fileName = image.path.split('/').last;

        final multipartFile = http.MultipartFile(
          'image', // Le nom du champ attendu par l'API
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType('image', _getImageMimeType(fileName)),
        );

        request.files.add(multipartFile);
      }

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Traiter la réponse de l'API
        final responseData = json.decode(response.body);

        // Si l'API retourne directement une liste d'IDs et non pas d'objets complets
        if (responseData.containsKey('image_ids')) {
          // Simuler des objets SalonImage à partir des IDs reçus
          final List<dynamic> imageIds = responseData['image_ids'];

          // Créer des objets SalonImage fictifs (vous devrez ensuite rafraîchir la galerie)
          return imageIds.map((id) => SalonImage(
            id: id,
            image: 'https://hairbnb.site/media/photos/salons/salon_${salonId}_image_$id.jpg'
          )).toList();
        }

        throw Exception('Format de réponse non reconnu');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData.containsKey('error')
            ? errorData['error']
            : 'Échec du téléchargement: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement des images: $e');
    }
  }

  /// Télécharge des images sur le serveur (pour le web)
  static Future<List<SalonImage>> uploadImagesForWeb(int salonId, List<http.MultipartFile> webFiles) async {
    try {
      final url = Uri.parse('$baseUrl/add_images_to_salon/');
      final request = http.MultipartRequest('POST', url);

      // Ajouter l'ID du salon
      request.fields['salon'] = salonId.toString();

      // Ajouter tous les fichiers à la requête
      request.files.addAll(webFiles);

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Traiter la réponse de l'API
        final responseData = json.decode(response.body);

        // Si l'API retourne directement une liste d'IDs et non pas d'objets complets
        if (responseData.containsKey('image_ids')) {
          // Simuler des objets SalonImage à partir des IDs reçus
          final List<dynamic> imageIds = responseData['image_ids'];

          // Créer des objets SalonImage fictifs (vous devrez ensuite rafraîchir la galerie)
          return imageIds.map((id) => SalonImage(
            image: 'https://hairbnb.site/media/photos/salons/salon_${salonId}_image_$id.jpg', id: id,
          )).toList();
        }

        throw Exception('Format de réponse non reconnu');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData.containsKey('error')
            ? errorData['error']
            : 'Échec du téléchargement: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement des images: $e');
    }
  }

  /// Supprime une image du salon
  static Future<bool> deleteImage(int imageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/salon/images/$imageId/delete/'),
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }

  /// Détermine le type MIME d'une image en fonction de son extension
  static String _getImageMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }
}






// // // lib/services/gallery_api.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import '../../models/public_salon_details.dart';
//
// class GalleryApi {
//   static const String baseUrl = 'https://hairbnb.site/api';
//
//   /// Récupère les images d'un salon
//   static Future<List<SalonImage>> getSalonImages(int salonId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/salon/$salonId/images/'),
//         //headers: await _getHeaders(),
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         return data.map((json) => SalonImage.fromJson(json)).toList();
//       } else {
//         throw Exception('Échec de récupération des images: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur lors de la récupération des images: $e');
//     }
//   }
//
//   /// Télécharge des images sur le serveur (pour les plateformes natives)
//   static Future<List<SalonImage>> uploadImages(int salonId, List<File> images) async {
//     final uploadedImages = <SalonImage>[];
//
//     for (final image in images) {
//       try {
//         final url = Uri.parse('$baseUrl/salon/images/add/');
//         final request = http.MultipartRequest('POST', url);
//
//         // ✅ Ajouter le champ 'salon' dans le body
//         request.fields['salon'] = salonId.toString();
//
//         final fileStream = http.ByteStream(image.openRead());
//         final fileLength = await image.length();
//         final fileName = image.path.split('/').last;
//
//         final multipartFile = http.MultipartFile(
//           'image',
//           fileStream,
//           fileLength,
//           filename: fileName,
//           contentType: MediaType('image', _getImageMimeType(fileName)),
//         );
//
//         request.files.add(multipartFile);
//
//         //final headers = await _getHeaders();
//         //request.headers.addAll(headers);
//
//         final streamedResponse = await request.send();
//         final response = await http.Response.fromStream(streamedResponse);
//
//         if (response.statusCode == 201) {
//           final responseData = json.decode(response.body);
//           final newImage = SalonImage.fromJson(responseData);
//           uploadedImages.add(newImage);
//         } else {
//           throw Exception('Échec du téléchargement: ${response.statusCode}');
//         }
//       } catch (e) {
//         print('Erreur lors du téléchargement de l\'image: $e');
//       }
//     }
//
//     return uploadedImages;
//   }
//
//   /// Télécharge des images sur le serveur (pour le web)
//   static Future<List<SalonImage>> uploadImagesForWeb(int salonId, List<http.MultipartFile> webFiles) async {
//     final uploadedImages = <SalonImage>[];
//
//     for (final file in webFiles) {
//       try {
//         final url = Uri.parse('$baseUrl/salon/images/add/');
//         final request = http.MultipartRequest('POST', url);

        // ✅ Ajouter le champ 'salon' dans le body
//         request.fields['salon'] = salonId.toString();
//
//         request.files.add(file);
//
//         //final headers = await _getHeaders();
//         //request.headers.addAll(headers);
//
//         final streamedResponse = await request.send();
//         final response = await http.Response.fromStream(streamedResponse);
//
//         if (response.statusCode == 201) {
//           final responseData = json.decode(response.body);
//           final newImage = SalonImage.fromJson(responseData);
//           uploadedImages.add(newImage);
//         } else {
//           throw Exception('Échec du téléchargement: ${response.statusCode}');
//         }
//       } catch (e) {
//         print('Erreur lors du téléchargement de l\'image: $e');
//       }
//     }
//
//     return uploadedImages;
//   }
//
//   /// Supprime une image du salon
//   static Future<bool> deleteImage(int imageId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/salon/images/$imageId/delete/'),
//         //headers: await _getHeaders(),
//       );
//
//       return response.statusCode == 204;
//     } catch (e) {
//       throw Exception('Erreur lors de la suppression de l\'image: $e');
//     }
//   }
//
//   /// Détermine le type MIME d'une image en fonction de son extension
//   static String _getImageMimeType(String fileName) {
//     final extension = fileName.split('.').last.toLowerCase();
//
//     switch (extension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }
// }








// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import '../../models/public_salon_details.dart';
// import '../../services/providers/user_service.dart';
//
// class GalleryApi {
//   static const String baseUrl = 'https://hairbnb.site/api';
//
//   /// Récupère les images d'un salon
//   static Future<List<SalonImage>> getSalonImages(int salonId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/salon/$salonId/images/'),
//         //headers: await _getHeaders(),
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         return data.map((json) => SalonImage.fromJson(json)).toList();
//       } else {
//         throw Exception(
//             'Échec de récupération des images: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur lors de la récupération des images: $e');
//     }
//   }
//
//   /// Télécharge des images sur le serveur (pour les plateformes natives)
//   static Future<List<SalonImage>> uploadImages(int salonId,
//       List<File> images) async {
//     final uploadedImages = <SalonImage>[];
//
//     for (final image in images) {
//       try {
//         final url = Uri.parse('$baseUrl/salon/$salonId/images/add/');
//         final request = http.MultipartRequest('POST', url);
//
//         // Ajouter les en-têtes d'authentification
//         //final headers = await _getHeaders();
//         //request.headers.addAll(headers);
//
//         // Préparer le fichier pour l'upload
//         final fileStream = http.ByteStream(image.openRead());
//         final fileLength = await image.length();
//         final fileName = image.path
//             .split('/')
//             .last;
//
//         final multipartFile = http.MultipartFile(
//           'image', // Le nom du champ attendu par l'API
//           fileStream,
//           fileLength,
//           filename: fileName,
//           contentType: MediaType('image', _getImageMimeType(fileName)),
//         );
//
//         request.files.add(multipartFile);
//
//         // Envoyer la requête
//         final streamedResponse = await request.send();
//         final response = await http.Response.fromStream(streamedResponse);
//
//         if (response.statusCode == 201) {
//           final responseData = json.decode(response.body);
//           final newImage = SalonImage.fromJson(responseData);
//           uploadedImages.add(newImage);
//         } else {
//           throw Exception('Échec du téléchargement: ${response.statusCode}');
//         }
//       } catch (e) {
//         // Continue avec les autres images même si une échoue
//         print('Erreur lors du téléchargement de l\'image: $e');
//       }
//     }
//
//     return uploadedImages;
//   }
//
//   /// Télécharge des images sur le serveur (pour le web)
//   static Future<List<SalonImage>> uploadImagesForWeb(int salonId,
//       List<http.MultipartFile> webFiles) async {
//     final uploadedImages = <SalonImage>[];
//
//     for (final file in webFiles) {
//       try {
//         final url = Uri.parse('$baseUrl/salon/$salonId/images/add/');
//         final request = http.MultipartRequest('POST', url);
//
//         // Ajouter les en-têtes d'authentification
//         //final headers = await _getHeaders();
//         //request.headers.addAll(headers);
//
//         // Ajouter le fichier à la requête
//         request.files.add(file);
//
//         // Envoyer la requête
//         final streamedResponse = await request.send();
//         final response = await http.Response.fromStream(streamedResponse);
//
//         if (response.statusCode == 201) {
//           final responseData = json.decode(response.body);
//           final newImage = SalonImage.fromJson(responseData);
//           uploadedImages.add(newImage);
//         } else {
//           throw Exception('Échec du téléchargement: ${response.statusCode}');
//         }
//       } catch (e) {
//         print('Erreur lors du téléchargement de l\'image: $e');
//       }
//     }
//
//     return uploadedImages;
//   }
// }
//
//   /// Supprime une image du salon
//   Future<bool> deleteImage(int imageId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/salon/images/$imageId/delete/'),
//         //headers: await _getHeaders(),
//       );
//
//       return response.statusCode == 204;
//     } catch (e) {
//       throw Exception('Erreur lors de la suppression de l\'image: $e');
//     }
//   }
//
//   /// Détermine le type MIME d'une image en fonction de son extension
//   String _getImageMimeType(String fileName) {
//     final extension = fileName.split('.').last.toLowerCase();
//
//     switch (extension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }


  // /// Récupère les en-têtes HTTP avec le token d'authentification
  // static Future<Map<String, String>> _getHeaders() async {
  //   // Récupérer le token depuis le stockage sécurisé
  //   final token = await _getAuthToken();
  //
  //   return {
  //     'Accept': 'application/json',
  //     if (token != null) 'Authorization': 'Bearer $token',
  //   };
  // }

//   /// Récupère le token d'authentification depuis le stockage
//   static Future<String?> _getAuthToken() async {
//     // Implementez votre logique pour récupérer le token
//     // Par exemple avec SharedPreferences ou Flutter Secure Storage
//
//     // Exemple:
//     // final prefs = await SharedPreferences.getInstance();
//     // return prefs.getString('auth_token');
//
//     // Pour l'instant on retourne une valeur fictive
//     return 'sample_token';
//   }
// }

// /// Supprime une image du salon
//   Future<bool> deleteImage(int imageId) async {
//     try {
//   final response = await http.delete(
//   Uri.parse('$baseUrl/salon/images/$imageId/delete/'),
// //headers: await _getHeaders(),
//   );
//   return response.statusCode == 204;
//     } catch (e) {
//   throw Exception('Erreur lors de la suppression de l\'image: $e');
//     }
//   }

// /// Détermine le type MIME d'une image en fonction de son extension
//   String _getImageMimeType(String fileName) {
// final extension = fileName.split('.').last.toLowerCase();
//   switch (extension) {
// case 'jpg':
// case 'jpeg':
// return 'jpeg';
// case 'png':
// return 'png';
// case 'gif':
// return 'gif';
// case 'webp':
// return 'webp';
// default:
// return 'jpeg';
// }
// }

// /// Récupère les en-têtes HTTP avec le token d'authentification
// static Future<Map<String, String>> _getHeaders() async {
// // Récupérer le token depuis le stockage sécurisé
// final token = await _getAuthToken();
//
// return {
// 'Accept': 'application/json',
// if (token != null) 'Authorization': 'Bearer $token',
// };
// }

// /// Récupère le token d'authentification depuis le stockage
// static Future<String?> _getAuthToken() async {
// // Implementez votre logique pour récupérer le token
// // Par exemple avec SharedPreferences ou Flutter Secure Storage
//
// // Exemple:
// // final prefs = await SharedPreferences.getInstance();
// // return prefs.getString('auth_token');
//
// // Pour l'instant on retourne une valeur fictive
// return 'sample_token';
// }












// // lib/services/gallery_api.dart
//
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import '../../models/public_salon_details.dart';
//
// class GalleryApi {
//   static const String baseUrl = 'https://hairbnb.site/api';
//
//   /// Récupère les images d'un salon
//   static Future<List<SalonImage>> getSalonImages(int salonId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/salon/$salonId/images/'),
//         //headers: await _getHeaders(),
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         return data.map((json) => SalonImage.fromJson(json)).toList();
//       } else {
//         throw Exception(
//             'Échec de récupération des images: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur lors de la récupération des images: $e');
//     }
//   }
//
//   /// Télécharge des images sur le serveur
//   static Future<List<SalonImage>> uploadImages(int salonId,
//       List<File> images) async {
//     final uploadedImages = <SalonImage>[];
//
//     for (final image in images) {
//       try {
//         final url = Uri.parse('$baseUrl/salon/$salonId/images/add/');
//         final request = http.MultipartRequest('POST', url);
//
//         // Ajouter les en-têtes d'authentification
//         //final headers = await _getHeaders();
//         //request.headers.addAll(headers);
//
//         // Préparer le fichier pour l'upload
//         final fileStream = http.ByteStream(image.openRead());
//         final fileLength = await image.length();
//         final fileName = image.path
//             .split('/')
//             .last;
//
//         final multipartFile = http.MultipartFile(
//           'image', // Le nom du champ attendu par l'API
//           fileStream,
//           fileLength,
//           filename: fileName,
//           contentType: MediaType('image', _getImageMimeType(fileName)),
//         );
//
//         request.files.add(multipartFile);
//
//         // Envoyer la requête
//         final streamedResponse = await request.send();
//         final response = await http.Response.fromStream(streamedResponse);
//
//         if (response.statusCode == 201) {
//           final responseData = json.decode(response.body);
//           final newImage = SalonImage.fromJson(responseData);
//           uploadedImages.add(newImage);
//         } else {
//           throw Exception('Échec du téléchargement: ${response.statusCode}');
//         }
//       } catch (e) {
//         // Continue avec les autres images même si une échoue
//         print('Erreur lors du téléchargement de l\'image: $e');
//       }
//     }
//
//     return uploadedImages;
//   }
//
//   /// Supprime une image du salon
//   static Future<bool> deleteImage(int imageId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/salon/images/$imageId/delete/'),
//         //headers: await _getHeaders(),
//       );
//
//       return response.statusCode == 204;
//     } catch (e) {
//       throw Exception('Erreur lors de la suppression de l\'image: $e');
//     }
//   }
//
//   /// Détermine le type MIME d'une image en fonction de son extension
//   static String _getImageMimeType(String fileName) {
//     final extension = fileName
//         .split('.')
//         .last
//         .toLowerCase();
//
//     switch (extension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }
// }

  // /// Récupère les en-têtes HTTP avec le token d'authentification
  // static Future<Map<String, String>> _getHeaders() async {
  //   // Récupérer le token depuis le stockage sécurisé
  //   final token = await _getAuthToken();
  //
  //   return {
  //     'Accept': 'application/json',
  //     if (token != null) 'Authorization': 'Bearer $token',
  //   };
  // }
  //
  // /// Récupère le token d'authentification depuis le stockage
  // static Future<String?> _getAuthToken() async {
  //   // Implementez votre logique pour récupérer le token
  //   // Par exemple avec SharedPreferences ou Flutter Secure Storage
  //
  //   // Exemple:
  //   // final prefs = await SharedPreferences.getInstance();
  //   // return prefs.getString('auth_token');
  //
  //   // Pour l'instant on retourne une valeur fictive
  //   return 'sample_token';
  // }