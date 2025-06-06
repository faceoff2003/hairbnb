// models/user_creation.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Modèle pour la création d'un profil utilisateur
class UserCreationModel {
  // Champs obligatoires de base
  final String userUuid;
  final String email;
  final String type;
  final String nom;
  final String prenom;
  final String sexe;
  final String telephone;
  final String dateNaissance;

  // Champs d'adresse obligatoires
  final String codePostal;
  final String commune;
  final String rue;
  final String numero;

  // Champs optionnels
  final String? boitePostale;
  final String? nomCommercial;
  final File? photoProfilFile;
  final Uint8List? photoProfilBytes;
  final String? photoProfilName;

  UserCreationModel({
    required this.userUuid,
    required this.email,
    required this.type,
    required this.nom,
    required this.prenom,
    required this.sexe,
    required this.telephone,
    required this.dateNaissance,
    required this.codePostal,
    required this.commune,
    required this.rue,
    required this.numero,
    this.boitePostale,
    this.nomCommercial,
    this.photoProfilFile,
    this.photoProfilBytes,
    this.photoProfilName,
  });

  /// Factory pour créer le modèle depuis un formulaire
  factory UserCreationModel.fromForm({
    required String userUuid,
    required String email,
    required bool isCoiffeuse,
    required String nom,
    required String prenom,
    required String sexe,
    required String telephone,
    required String dateNaissance,
    required String codePostal,
    required String commune,
    required String rue,
    required String numero,
    String? boitePostale,
    String? nomCommercial,
    File? photoProfilFile,
    Uint8List? photoProfilBytes,
    String? photoProfilName,
  }) {
    return UserCreationModel(
      userUuid: userUuid,
      email: email,
      type: isCoiffeuse ? "Coiffeuse" : "Client",
      nom: nom,
      prenom: prenom,
      sexe: sexe, // S'assure que le sexe est en minuscules
      telephone: telephone,
      dateNaissance: dateNaissance,
      codePostal: codePostal,
      commune: commune,
      rue: rue,
      numero: numero,
      boitePostale: boitePostale,
      nomCommercial: nomCommercial,
      photoProfilFile: photoProfilFile,
      photoProfilBytes: photoProfilBytes,
      photoProfilName: photoProfilName,
    );
  }

  /// Validation du modèle
  Map<String, String> validate() {
    Map<String, String> errors = {};

    // Validation des champs obligatoires de base
    if (userUuid.isEmpty) errors['userUuid'] = 'UUID utilisateur requis';
    if (email.isEmpty) errors['email'] = 'Email requis';
    if (!_isValidEmail(email)) errors['email'] = 'Format email invalide';
    if (nom.isEmpty) errors['nom'] = 'Nom requis';
    if (prenom.isEmpty) errors['prenom'] = 'Prénom requis';
    if (sexe.isEmpty) errors['sexe'] = 'Sexe requis';
    if (telephone.isEmpty) errors['telephone'] = 'Téléphone requis';
    if (dateNaissance.isEmpty) errors['dateNaissance'] = 'Date de naissance requise';
    if (!_isValidDate(dateNaissance)) errors['dateNaissance'] = 'Format date invalide (DD-MM-YYYY)';

    // Validation des champs d'adresse
    if (codePostal.isEmpty) errors['codePostal'] = 'Code postal requis';
    if (commune.isEmpty) errors['commune'] = 'Commune requise';
    if (rue.isEmpty) errors['rue'] = 'Rue requise';
    if (numero.isEmpty) errors['numero'] = 'Numéro requis';

    // Validation spécifique pour coiffeuse (basée sur le champ 'type')
    if (type == "coiffeuse") { // CHANGEMENT ICI : Utilise 'type' pour la validation
      if (nomCommercial == null || nomCommercial!.isEmpty) {
        errors['nomCommercial'] = 'Nom commercial requis pour une coiffeuse';
      }
    }

    return errors;
  }

  /// Validation de l'email
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Validation de la date
  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!regex.hasMatch(date)) return false;

    try {
      final parts = date.split('-');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final parsedDate = DateTime(year, month, day);
      return parsedDate.year == year &&
          parsedDate.month == month &&
          parsedDate.day == day;
    } catch (e) {
      return false;
    }
  }

  /// Conversion en Map pour l'envoi API
  Map<String, String> toApiFields() {
    Map<String, String> fields = {
      'userUuid': userUuid,
      'email': email,
      'type': type, // CHANGEMENT ICI : Envoie 'type' à l'API
      'nom': nom,
      'prenom': prenom,
      'sexe': sexe,
      'telephone': telephone,
      'date_naissance': dateNaissance,
      'code_postal': codePostal,
      'commune': commune,
      'rue': rue,
      'numero': numero,
    };

    // Ajouter la boîte postale si présente
    if (boitePostale != null && boitePostale!.isNotEmpty) {
      fields['boite_postale'] = boitePostale!;
    }

    // Ajouter le nom commercial pour les coiffeuses
    if (nomCommercial != null && nomCommercial!.isNotEmpty) {
      fields['nom_commercial'] = nomCommercial!;
    }

    return fields;
  }

  /// Copie du modèle avec modifications
  UserCreationModel copyWith({
    String? userUuid,
    String? email,
    String? type, // CHANGEMENT ICI : Utilise 'type'
    String? nom,
    String? prenom,
    String? sexe,
    String? telephone,
    String? dateNaissance,
    String? codePostal,
    String? commune,
    String? rue,
    String? numero,
    String? boitePostale,
    String? nomCommercial,
    File? photoProfilFile,
    Uint8List? photoProfilBytes,
    String? photoProfilName,
  }) {
    return UserCreationModel(
      userUuid: userUuid ?? this.userUuid,
      email: email ?? this.email,
      type: type ?? this.type, // CHANGEMENT ICI : Copie le champ 'type'
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      sexe: sexe ?? this.sexe,
      telephone: telephone ?? this.telephone,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      codePostal: codePostal ?? this.codePostal,
      commune: commune ?? this.commune,
      rue: rue ?? this.rue,
      numero: numero ?? this.numero,
      boitePostale: boitePostale ?? this.boitePostale,
      nomCommercial: nomCommercial ?? this.nomCommercial,
      photoProfilFile: photoProfilFile ?? this.photoProfilFile,
      photoProfilBytes: photoProfilBytes ?? this.photoProfilBytes,
      photoProfilName: photoProfilName ?? this.photoProfilName,
    );
  }

  @override
  String toString() {
    // CHANGEMENT ICI : Affiche le champ 'type'
    return 'UserCreationModel(userUuid: $userUuid, email: $email, type: $type, nom: $nom, prenom: $prenom)';
  }
}

/// Classe pour gérer la réponse de l'API
class UserCreationResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final Map<String, String>? validationErrors;
  final int? statusCode;

  UserCreationResponse({
    required this.success,
    required this.message,
    this.data,
    this.validationErrors,
    this.statusCode,
  });

  /// Factory pour une réponse de succès
  factory UserCreationResponse.success({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return UserCreationResponse(
      success: true,
      message: message,
      data: data,
      statusCode: 201,
    );
  }

  /// Factory pour une réponse d'erreur
  factory UserCreationResponse.error({
    required String message,
    Map<String, String>? validationErrors,
    int? statusCode,
  }) {
    return UserCreationResponse(
      success: false,
      message: message,
      validationErrors: validationErrors,
      statusCode: statusCode,
    );
  }

  /// Factory depuis une réponse HTTP
  factory UserCreationResponse.fromHttpResponse({
    required int statusCode,
    required String body,
  }) {
    try {
      final responseData = json.decode(body);

      if (statusCode == 201 && responseData['status'] == 'success') {
        return UserCreationResponse.success(
          message: responseData['message'] ?? 'Profil créé avec succès',
          data: responseData['data'],
        );
      } else if (statusCode == 400) {
        // Erreurs de validation
        Map<String, String> errors = {};
        if (responseData['errors'] != null) {
          Map<String, dynamic> apiErrors = responseData['errors'];
          apiErrors.forEach((field, messages) {
            if (messages is List) {
              errors[field] = messages.join(', ');
            } else {
              errors[field] = messages.toString();
            }
          });
        }

        return UserCreationResponse.error(
          message: responseData['message'] ?? 'Erreurs de validation',
          validationErrors: errors,
          statusCode: statusCode,
        );
      } else {
        return UserCreationResponse.error(
          message: responseData['message'] ?? 'Erreur serveur',
          statusCode: statusCode,
        );
      }
    } catch (e) {
      return UserCreationResponse.error(
        message: "Erreur lors du parsing de la réponse: $e",
        statusCode: statusCode,
      );
    }
  }

  /// Récupérer les informations utilisateur créé
  Map<String, dynamic>? get createdUserData => data;

  /// Vérifier si c'est une erreur d'authentification
  bool get isAuthError => statusCode == 401;

  /// Vérifier si c'est une erreur de validation
  bool get isValidationError => statusCode == 400 && validationErrors != null;

  @override
  String toString() {
    return 'UserCreationResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}









// // models/user_creation.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
//
// /// Modèle pour la création d'un profil utilisateur
// class UserCreationModel {
//   // Champs obligatoires de base
//   final String userUuid;
//   final String email;
//   final String role;
//   final String nom;
//   final String prenom;
//   final String sexe;
//   final String telephone;
//   final String dateNaissance;
//
//   // Champs d'adresse obligatoires
//   final String codePostal;
//   final String commune;
//   final String rue;
//   final String numero;
//
//   // Champs optionnels
//   final String? boitePostale;
//   final String? nomCommercial;
//   final File? photoProfilFile;
//   final Uint8List? photoProfilBytes;
//   final String? photoProfilName;
//
//   UserCreationModel({
//     required this.userUuid,
//     required this.email,
//     required this.role,
//     required this.nom,
//     required this.prenom,
//     required this.sexe,
//     required this.telephone,
//     required this.dateNaissance,
//     required this.codePostal,
//     required this.commune,
//     required this.rue,
//     required this.numero,
//     this.boitePostale,
//     this.nomCommercial,
//     this.photoProfilFile,
//     this.photoProfilBytes,
//     this.photoProfilName,
//   });
//
//   /// Factory pour créer le modèle depuis un formulaire
//   factory UserCreationModel.fromForm({
//     required String userUuid,
//     required String email,
//     required bool isCoiffeuse,
//     required String nom,
//     required String prenom,
//     required String sexe,
//     required String telephone,
//     required String dateNaissance,
//     required String codePostal,
//     required String commune,
//     required String rue,
//     required String numero,
//     String? boitePostale,
//     String? nomCommercial,
//     File? photoProfilFile,
//     Uint8List? photoProfilBytes,
//     String? photoProfilName,
//   }) {
//     return UserCreationModel(
//       userUuid: userUuid,
//       email: email,
//       role: isCoiffeuse ? "coiffeuse" : "client",
//       nom: nom,
//       prenom: prenom,
//       sexe: sexe.toLowerCase(),
//       telephone: telephone,
//       dateNaissance: dateNaissance,
//       codePostal: codePostal,
//       commune: commune,
//       rue: rue,
//       numero: numero,
//       boitePostale: boitePostale,
//       nomCommercial: nomCommercial,
//       photoProfilFile: photoProfilFile,
//       photoProfilBytes: photoProfilBytes,
//       photoProfilName: photoProfilName,
//     );
//   }
//
//   /// Validation du modèle
//   Map<String, String> validate() {
//     Map<String, String> errors = {};
//
//     // Validation des champs obligatoires de base
//     if (userUuid.isEmpty) errors['userUuid'] = 'UUID utilisateur requis';
//     if (email.isEmpty) errors['email'] = 'Email requis';
//     if (!_isValidEmail(email)) errors['email'] = 'Format email invalide';
//     if (nom.isEmpty) errors['nom'] = 'Nom requis';
//     if (prenom.isEmpty) errors['prenom'] = 'Prénom requis';
//     if (sexe.isEmpty) errors['sexe'] = 'Sexe requis';
//     if (telephone.isEmpty) errors['telephone'] = 'Téléphone requis';
//     if (dateNaissance.isEmpty) errors['dateNaissance'] = 'Date de naissance requise';
//     if (!_isValidDate(dateNaissance)) errors['dateNaissance'] = 'Format date invalide (DD-MM-YYYY)';
//
//     // Validation des champs d'adresse
//     if (codePostal.isEmpty) errors['codePostal'] = 'Code postal requis';
//     if (commune.isEmpty) errors['commune'] = 'Commune requise';
//     if (rue.isEmpty) errors['rue'] = 'Rue requise';
//     if (numero.isEmpty) errors['numero'] = 'Numéro requis';
//
//     // Validation spécifique pour coiffeuse
//     if (role == "coiffeuse") {
//       if (nomCommercial == null || nomCommercial!.isEmpty) {
//         errors['nomCommercial'] = 'Nom commercial requis pour une coiffeuse';
//       }
//     }
//
//     return errors;
//   }
//
//   /// Validation de l'email
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
//   }
//
//   /// Validation de la date
//   bool _isValidDate(String date) {
//     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
//     if (!regex.hasMatch(date)) return false;
//
//     try {
//       final parts = date.split('-');
//       final day = int.parse(parts[0]);
//       final month = int.parse(parts[1]);
//       final year = int.parse(parts[2]);
//       final parsedDate = DateTime(year, month, day);
//       return parsedDate.year == year &&
//           parsedDate.month == month &&
//           parsedDate.day == day;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   /// Conversion en Map pour l'envoi API
//   Map<String, String> toApiFields() {
//     Map<String, String> fields = {
//       'userUuid': userUuid,
//       'email': email,
//       'role': role,
//       'nom': nom,
//       'prenom': prenom,
//       'sexe': sexe,
//       'telephone': telephone,
//       'date_naissance': dateNaissance,
//       'code_postal': codePostal,
//       'commune': commune,
//       'rue': rue,
//       'numero': numero,
//     };
//
//     // Ajouter la boîte postale si présente
//     if (boitePostale != null && boitePostale!.isNotEmpty) {
//       fields['boite_postale'] = boitePostale!;
//     }
//
//     // Ajouter le nom commercial pour les coiffeuses
//     if (nomCommercial != null && nomCommercial!.isNotEmpty) {
//       fields['nom_commercial'] = nomCommercial!;
//     }
//
//     return fields;
//   }
//
//   /// Copie du modèle avec modifications
//   UserCreationModel copyWith({
//     String? userUuid,
//     String? email,
//     String? role,
//     String? nom,
//     String? prenom,
//     String? sexe,
//     String? telephone,
//     String? dateNaissance,
//     String? codePostal,
//     String? commune,
//     String? rue,
//     String? numero,
//     String? boitePostale,
//     String? nomCommercial,
//     File? photoProfilFile,
//     Uint8List? photoProfilBytes,
//     String? photoProfilName,
//   }) {
//     return UserCreationModel(
//       userUuid: userUuid ?? this.userUuid,
//       email: email ?? this.email,
//       role: role ?? this.role,
//       nom: nom ?? this.nom,
//       prenom: prenom ?? this.prenom,
//       sexe: sexe ?? this.sexe,
//       telephone: telephone ?? this.telephone,
//       dateNaissance: dateNaissance ?? this.dateNaissance,
//       codePostal: codePostal ?? this.codePostal,
//       commune: commune ?? this.commune,
//       rue: rue ?? this.rue,
//       numero: numero ?? this.numero,
//       boitePostale: boitePostale ?? this.boitePostale,
//       nomCommercial: nomCommercial ?? this.nomCommercial,
//       photoProfilFile: photoProfilFile ?? this.photoProfilFile,
//       photoProfilBytes: photoProfilBytes ?? this.photoProfilBytes,
//       photoProfilName: photoProfilName ?? this.photoProfilName,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'UserCreationModel(userUuid: $userUuid, email: $email, role: $role, nom: $nom, prenom: $prenom)';
//   }
// }
//
// /// Classe pour gérer la réponse de l'API
// class UserCreationResponse {
//   final bool success;
//   final String message;
//   final Map<String, dynamic>? data;
//   final Map<String, String>? validationErrors;
//   final int? statusCode;
//
//   UserCreationResponse({
//     required this.success,
//     required this.message,
//     this.data,
//     this.validationErrors,
//     this.statusCode,
//   });
//
//   /// Factory pour une réponse de succès
//   factory UserCreationResponse.success({
//     required String message,
//     Map<String, dynamic>? data,
//   }) {
//     return UserCreationResponse(
//       success: true,
//       message: message,
//       data: data,
//       statusCode: 201,
//     );
//   }
//
//   /// Factory pour une réponse d'erreur
//   factory UserCreationResponse.error({
//     required String message,
//     Map<String, String>? validationErrors,
//     int? statusCode,
//   }) {
//     return UserCreationResponse(
//       success: false,
//       message: message,
//       validationErrors: validationErrors,
//       statusCode: statusCode,
//     );
//   }
//
//   /// Factory depuis une réponse HTTP
//   factory UserCreationResponse.fromHttpResponse({
//     required int statusCode,
//     required String body,
//   }) {
//     try {
//       final responseData = json.decode(body);
//
//       if (statusCode == 201 && responseData['status'] == 'success') {
//         return UserCreationResponse.success(
//           message: responseData['message'] ?? 'Profil créé avec succès',
//           data: responseData['data'],
//         );
//       } else if (statusCode == 400) {
//         // Erreurs de validation
//         Map<String, String> errors = {};
//         if (responseData['errors'] != null) {
//           Map<String, dynamic> apiErrors = responseData['errors'];
//           apiErrors.forEach((field, messages) {
//             if (messages is List) {
//               errors[field] = messages.join(', ');
//             } else {
//               errors[field] = messages.toString();
//             }
//           });
//         }
//
//         return UserCreationResponse.error(
//           message: responseData['message'] ?? 'Erreurs de validation',
//           validationErrors: errors,
//           statusCode: statusCode,
//         );
//       } else {
//         return UserCreationResponse.error(
//           message: responseData['message'] ?? 'Erreur serveur',
//           statusCode: statusCode,
//         );
//       }
//     } catch (e) {
//       return UserCreationResponse.error(
//         message: "Erreur lors du parsing de la réponse: $e",
//         statusCode: statusCode,
//       );
//     }
//   }
//
//   /// Récupérer les informations utilisateur créé
//   Map<String, dynamic>? get createdUserData => data;
//
//   /// Vérifier si c'est une erreur d'authentification
//   bool get isAuthError => statusCode == 401;
//
//   /// Vérifier si c'est une erreur de validation
//   bool get isValidationError => statusCode == 400 && validationErrors != null;
//
//   @override
//   String toString() {
//     return 'UserCreationResponse(success: $success, message: $message, statusCode: $statusCode)';
//   }
// }








// // models/user_creation_model.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
//
// /// Modèle pour la création d'un profil utilisateur
// class UserCreationModel {
//   // Champs obligatoires
//   final String userUuid;
//   final String email;
//   final String role;
//   final String nom;
//   final String prenom;
//   final String sexe;
//   final String telephone;
//   final String dateNaissance;
//
//   // Champs d'adresse
//   final String codePostal;
//   final String commune;
//   final String rue;
//   final String numero;
//   final String? boitePostale;
//
//   // Champs optionnels
//   final String? denominationSociale;
//   final String? tva;
//   final File? photoProfilFile;
//   final Uint8List? photoProfilBytes;
//   final String? photoProfilName;
//
//   UserCreationModel({
//     required this.userUuid,
//     required this.email,
//     required this.role,
//     required this.nom,
//     required this.prenom,
//     required this.sexe,
//     required this.telephone,
//     required this.dateNaissance,
//     required this.codePostal,
//     required this.commune,
//     required this.rue,
//     required this.numero,
//     this.boitePostale,
//     this.denominationSociale,
//     this.tva,
//     this.photoProfilFile,
//     this.photoProfilBytes,
//     this.photoProfilName,
//   });
//
//   /// Factory pour créer le modèle depuis un formulaire
//   factory UserCreationModel.fromForm({
//     required String userUuid,
//     required String email,
//     required bool isCoiffeuse,
//     required String nom,
//     required String prenom,
//     required String sexe,
//     required String telephone,
//     required String dateNaissance,
//     required String codePostal,
//     required String commune,
//     required String rue,
//     required String numero,
//     String? boitePostale,
//     String? denominationSociale,
//     String? tva,
//     File? photoProfilFile,
//     Uint8List? photoProfilBytes,
//     String? photoProfilName,
//   }) {
//     return UserCreationModel(
//       userUuid: userUuid,
//       email: email,
//       role: isCoiffeuse ? "coiffeuse" : "client",
//       nom: nom,
//       prenom: prenom,
//       sexe: sexe.toLowerCase(),
//       telephone: telephone,
//       dateNaissance: dateNaissance,
//       codePostal: codePostal,
//       commune: commune,
//       rue: rue,
//       numero: numero,
//       boitePostale: boitePostale,
//       denominationSociale: denominationSociale,
//       tva: tva,
//       photoProfilFile: photoProfilFile,
//       photoProfilBytes: photoProfilBytes,
//       photoProfilName: photoProfilName,
//     );
//   }
//
//   /// Validation du modèle
//   Map<String, String> validate() {
//     Map<String, String> errors = {};
//
//     // Validation des champs obligatoires
//     if (userUuid.isEmpty) errors['userUuid'] = 'UUID utilisateur requis';
//     if (email.isEmpty) errors['email'] = 'Email requis';
//     if (!_isValidEmail(email)) errors['email'] = 'Format email invalide';
//     if (nom.isEmpty) errors['nom'] = 'Nom requis';
//     if (prenom.isEmpty) errors['prenom'] = 'Prénom requis';
//     if (sexe.isEmpty) errors['sexe'] = 'Sexe requis';
//     if (telephone.isEmpty) errors['telephone'] = 'Téléphone requis';
//     if (dateNaissance.isEmpty) errors['dateNaissance'] = 'Date de naissance requise';
//     if (!_isValidDate(dateNaissance)) errors['dateNaissance'] = 'Format date invalide (DD-MM-YYYY)';
//
//     // Validation adresse
//     if (codePostal.isEmpty) errors['codePostal'] = 'Code postal requis';
//     if (commune.isEmpty) errors['commune'] = 'Commune requise';
//     if (rue.isEmpty) errors['rue'] = 'Rue requise';
//     if (numero.isEmpty) errors['numero'] = 'Numéro requis';
//
//     // Validation spécifique pour coiffeuse
//     if (role == "coiffeuse") {
//       if (denominationSociale == null || denominationSociale!.isEmpty) {
//         errors['denominationSociale'] = 'Dénomination sociale requise pour une coiffeuse';
//       }
//       if (tva == null || tva!.isEmpty) {
//         errors['tva'] = 'Numéro TVA requis pour une coiffeuse';
//       }
//     }
//
//     return errors;
//   }
//
//   /// Validation de l'email
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
//   }
//
//   /// Validation de la date
//   bool _isValidDate(String date) {
//     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
//     if (!regex.hasMatch(date)) return false;
//
//     try {
//       final parts = date.split('-');
//       final day = int.parse(parts[0]);
//       final month = int.parse(parts[1]);
//       final year = int.parse(parts[2]);
//       final parsedDate = DateTime(year, month, day);
//       return parsedDate.year == year &&
//           parsedDate.month == month &&
//           parsedDate.day == day;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   /// Conversion en Map pour l'envoi API
//   Map<String, String> toApiFields() {
//     Map<String, String> fields = {
//       'userUuid': userUuid,
//       'email': email,
//       'role': role,
//       'nom': nom,
//       'prenom': prenom,
//       'sexe': sexe,
//       'telephone': telephone,
//       'date_naissance': dateNaissance,
//       'code_postal': codePostal,
//       'commune': commune,
//       'rue': rue,
//       'numero': numero,
//     };
//
//     // Ajouter la boîte postale si présente
//     if (boitePostale != null && boitePostale!.isNotEmpty) {
//       fields['boite_postale'] = boitePostale!;
//     }
//
//     // Ajouter les champs optionnels pour coiffeuse
//     if (denominationSociale != null && denominationSociale!.isNotEmpty) {
//       fields['denomination_sociale'] = denominationSociale!;
//     }
//
//     if (tva != null && tva!.isNotEmpty) {
//       fields['tva'] = tva!;
//     }
//
//     return fields;
//   }
//
//   /// Copie du modèle avec modifications
//   UserCreationModel copyWith({
//     String? userUuid,
//     String? email,
//     String? role,
//     String? nom,
//     String? prenom,
//     String? sexe,
//     String? telephone,
//     String? dateNaissance,
//     String? codePostal,
//     String? commune,
//     String? rue,
//     String? numero,
//     String? boitePostale,
//     String? denominationSociale,
//     String? tva,
//     File? photoProfilFile,
//     Uint8List? photoProfilBytes,
//     String? photoProfilName,
//   }) {
//     return UserCreationModel(
//       userUuid: userUuid ?? this.userUuid,
//       email: email ?? this.email,
//       role: role ?? this.role,
//       nom: nom ?? this.nom,
//       prenom: prenom ?? this.prenom,
//       sexe: sexe ?? this.sexe,
//       telephone: telephone ?? this.telephone,
//       dateNaissance: dateNaissance ?? this.dateNaissance,
//       codePostal: codePostal ?? this.codePostal,
//       commune: commune ?? this.commune,
//       rue: rue ?? this.rue,
//       numero: numero ?? this.numero,
//       boitePostale: boitePostale ?? this.boitePostale,
//       denominationSociale: denominationSociale ?? this.denominationSociale,
//       tva: tva ?? this.tva,
//       photoProfilFile: photoProfilFile ?? this.photoProfilFile,
//       photoProfilBytes: photoProfilBytes ?? this.photoProfilBytes,
//       photoProfilName: photoProfilName ?? this.photoProfilName,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'UserCreationModel(userUuid: $userUuid, email: $email, role: $role, nom: $nom, prenom: $prenom)';
//   }
// }
//
// /// Classe pour gérer la réponse de l'API
// class UserCreationResponse {
//   final bool success;
//   final String message;
//   final Map<String, dynamic>? data;
//   final Map<String, String>? validationErrors;
//   final int? statusCode;
//
//   UserCreationResponse({
//     required this.success,
//     required this.message,
//     this.data,
//     this.validationErrors,
//     this.statusCode,
//   });
//
//   /// Factory pour une réponse de succès
//   factory UserCreationResponse.success({
//     required String message,
//     Map<String, dynamic>? data,
//   }) {
//     return UserCreationResponse(
//       success: true,
//       message: message,
//       data: data,
//       statusCode: 201,
//     );
//   }
//
//   /// Factory pour une réponse d'erreur
//   factory UserCreationResponse.error({
//     required String message,
//     Map<String, String>? validationErrors,
//     int? statusCode,
//   }) {
//     return UserCreationResponse(
//       success: false,
//       message: message,
//       validationErrors: validationErrors,
//       statusCode: statusCode,
//     );
//   }
//
//   /// Factory depuis une réponse HTTP
//   factory UserCreationResponse.fromHttpResponse({
//     required int statusCode,
//     required String body,
//   }) {
//     try {
//       final responseData = json.decode(body);
//
//       if (statusCode == 201 && responseData['status'] == 'success') {
//         return UserCreationResponse.success(
//           message: responseData['message'] ?? 'Profil créé avec succès',
//           data: responseData['data'],
//         );
//       } else if (statusCode == 400) {
//         // Erreurs de validation
//         Map<String, String> errors = {};
//         if (responseData['errors'] != null) {
//           Map<String, dynamic> apiErrors = responseData['errors'];
//           apiErrors.forEach((field, messages) {
//             if (messages is List) {
//               errors[field] = messages.join(', ');
//             } else {
//               errors[field] = messages.toString();
//             }
//           });
//         }
//
//         return UserCreationResponse.error(
//           message: responseData['message'] ?? 'Erreurs de validation',
//           validationErrors: errors,
//           statusCode: statusCode,
//         );
//       } else {
//         return UserCreationResponse.error(
//           message: responseData['message'] ?? 'Erreur serveur',
//           statusCode: statusCode,
//         );
//       }
//     } catch (e) {
//       return UserCreationResponse.error(
//         message: "Erreur lors du parsing de la réponse: $e",
//         statusCode: statusCode,
//       );
//     }
//   }
//
//   /// Récupérer les informations utilisateur créé
//   Map<String, dynamic>? get createdUserData => data;
//
//   /// Vérifier si c'est une erreur d'authentification
//   bool get isAuthError => statusCode == 401;
//
//   /// Vérifier si c'est une erreur de validation
//   bool get isValidationError => statusCode == 400 && validationErrors != null;
//
//   @override
//   String toString() {
//     return 'UserCreationResponse(success: $success, message: $message, statusCode: $statusCode)';
//   }
// }
//
//
//
//
//
// // // models/user_creation_model.dart
// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/foundation.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:http_parser/http_parser.dart';
// //
// // /// Modèle pour la création d'un profil utilisateur
// // class UserCreationModel {
// //   // Champs obligatoires
// //   final String userUuid;
// //   final String email;
// //   final String role;
// //   final String nom;
// //   final String prenom;
// //   final String sexe;
// //   final String telephone;
// //   final String dateNaissance;
// //
// //   // Champs d'adresse
// //   final String codePostal;
// //   final String commune;
// //   final String rue;
// //   final String numero;
// //
// //   // Champs optionnels
// //   final String? denominationSociale;
// //   final File? photoProfilFile;
// //   final Uint8List? photoProfilBytes;
// //   final String? photoProfilName;
// //
// //   UserCreationModel({
// //     required this.userUuid,
// //     required this.email,
// //     required this.role,
// //     required this.nom,
// //     required this.prenom,
// //     required this.sexe,
// //     required this.telephone,
// //     required this.dateNaissance,
// //     required this.codePostal,
// //     required this.commune,
// //     required this.rue,
// //     required this.numero,
// //     this.denominationSociale,
// //     this.photoProfilFile,
// //     this.photoProfilBytes,
// //     this.photoProfilName,
// //   });
// //
// //   /// Factory pour créer le modèle depuis un formulaire
// //   factory UserCreationModel.fromForm({
// //     required String userUuid,
// //     required String email,
// //     required bool isCoiffeuse,
// //     required String nom,
// //     required String prenom,
// //     required String sexe,
// //     required String telephone,
// //     required String dateNaissance,
// //     required String codePostal,
// //     required String commune,
// //     required String rue,
// //     required String numero,
// //     String? denominationSociale,
// //     File? photoProfilFile,
// //     Uint8List? photoProfilBytes,
// //     String? photoProfilName,
// //   }) {
// //     return UserCreationModel(
// //       userUuid: userUuid,
// //       email: email,
// //       role: isCoiffeuse ? "Coiffeuse" : "Client",
// //       nom: nom,
// //       prenom: prenom,
// //       sexe: sexe,
// //       telephone: telephone,
// //       dateNaissance: dateNaissance,
// //       codePostal: codePostal,
// //       commune: commune,
// //       rue: rue,
// //       numero: numero,
// //       denominationSociale: denominationSociale,
// //       photoProfilFile: photoProfilFile,
// //       photoProfilBytes: photoProfilBytes,
// //       photoProfilName: photoProfilName,
// //     );
// //   }
// //
// //   /// Validation du modèle
// //   Map<String, String> validate() {
// //     Map<String, String> errors = {};
// //
// //     // Validation des champs obligatoires
// //     if (userUuid.isEmpty) errors['userUuid'] = 'UUID utilisateur requis';
// //     if (email.isEmpty) errors['email'] = 'Email requis';
// //     if (!_isValidEmail(email)) errors['email'] = 'Format email invalide';
// //     if (nom.isEmpty) errors['nom'] = 'Nom requis';
// //     if (prenom.isEmpty) errors['prenom'] = 'Prénom requis';
// //     if (sexe.isEmpty) errors['sexe'] = 'Sexe requis';
// //     if (telephone.isEmpty) errors['telephone'] = 'Téléphone requis';
// //     if (dateNaissance.isEmpty) errors['dateNaissance'] = 'Date de naissance requise';
// //     if (!_isValidDate(dateNaissance)) errors['dateNaissance'] = 'Format date invalide (DD-MM-YYYY)';
// //
// //     // Validation adresse
// //     if (codePostal.isEmpty) errors['codePostal'] = 'Code postal requis';
// //     if (commune.isEmpty) errors['commune'] = 'Commune requise';
// //     if (rue.isEmpty) errors['rue'] = 'Rue requise';
// //     if (numero.isEmpty) errors['numero'] = 'Numéro requis';
// //
// //     // Validation spécifique pour coiffeuse
// //     if (role == "Coiffeuse" && (denominationSociale == null || denominationSociale!.isEmpty)) {
// //       errors['denominationSociale'] = 'Dénomination sociale requise pour une coiffeuse';
// //     }
// //
// //     return errors;
// //   }
// //
// //   /// Validation de l'email
// //   bool _isValidEmail(String email) {
// //     return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
// //   }
// //
// //   /// Validation de la date
// //   bool _isValidDate(String date) {
// //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// //     if (!regex.hasMatch(date)) return false;
// //
// //     try {
// //       final parts = date.split('-');
// //       final day = int.parse(parts[0]);
// //       final month = int.parse(parts[1]);
// //       final year = int.parse(parts[2]);
// //       final parsedDate = DateTime(year, month, day);
// //       return parsedDate.year == year &&
// //           parsedDate.month == month &&
// //           parsedDate.day == day;
// //     } catch (e) {
// //       return false;
// //     }
// //   }
// //
// //   /// Conversion en Map pour l'envoi API
// //   Map<String, String> toApiFields() {
// //     Map<String, String> fields = {
// //       'userUuid': userUuid,
// //       'email': email,
// //       'role': role,
// //       'nom': nom,
// //       'prenom': prenom,
// //       'sexe': sexe,
// //       'telephone': telephone,
// //       'date_naissance': dateNaissance,
// //       'code_postal': codePostal,
// //       'commune': commune,
// //       'rue': rue,
// //       'numero': numero,
// //     };
// //
// //     // Ajouter les champs optionnels
// //     if (denominationSociale != null && denominationSociale!.isNotEmpty) {
// //       fields['denomination_sociale'] = denominationSociale!;
// //     }
// //
// //     return fields;
// //   }
// //
// //   /// Méthode pour créer le profil via l'API
// //   Future<UserCreationResponse> createProfile({
// //     String? firebaseToken,
// //     String baseUrl = "https://www.hairbnb.site",
// //   }) async {
// //     try {
// //       // Validation avant envoi
// //       final validationErrors = validate();
// //       if (validationErrors.isNotEmpty) {
// //         return UserCreationResponse.error(
// //           message: "Erreurs de validation",
// //           validationErrors: validationErrors,
// //         );
// //       }
// //
// //       final url = Uri.parse("$baseUrl/api/create_user_profile/");
// //       var request = http.MultipartRequest('POST', url);
// //
// //       // Ajouter le token d'authentification si fourni
// //       if (firebaseToken != null) {
// //         request.headers['Authorization'] = 'Bearer $firebaseToken';
// //       }
// //
// //       // Ajouter les champs du formulaire
// //       request.fields.addAll(toApiFields());
// //
// //       // Ajouter la photo si elle existe
// //       if (photoProfilFile != null || photoProfilBytes != null) {
// //         if (kIsWeb && photoProfilBytes != null) {
// //           request.files.add(
// //             http.MultipartFile.fromBytes(
// //               'photo_profil',
// //               photoProfilBytes!,
// //               filename: photoProfilName ?? 'profile_photo.png',
// //               contentType: MediaType('image', 'png'),
// //             ),
// //           );
// //         } else if (photoProfilFile != null) {
// //           request.files.add(
// //             await http.MultipartFile.fromPath(
// //               'photo_profil',
// //               photoProfilFile!.path,
// //             ),
// //           );
// //         }
// //       }
// //
// //       // Envoyer la requête
// //       final response = await request.send();
// //       final responseBody = await response.stream.bytesToString();
// //
// //       // Parser la réponse
// //       return UserCreationResponse.fromHttpResponse(
// //         statusCode: response.statusCode,
// //         body: responseBody,
// //       );
// //
// //     } catch (e) {
// //       return UserCreationResponse.error(
// //         message: "Erreur de connexion: $e",
// //       );
// //     }
// //   }
// //
// //   /// Copie du modèle avec modification
// //   UserCreationModel copyWith({
// //     String? userUuid,
// //     String? email,
// //     String? role,
// //     String? nom,
// //     String? prenom,
// //     String? sexe,
// //     String? telephone,
// //     String? dateNaissance,
// //     String? codePostal,
// //     String? commune,
// //     String? rue,
// //     String? numero,
// //     String? denominationSociale,
// //     File? photoProfilFile,
// //     Uint8List? photoProfilBytes,
// //     String? photoProfilName,
// //   }) {
// //     return UserCreationModel(
// //       userUuid: userUuid ?? this.userUuid,
// //       email: email ?? this.email,
// //       role: role ?? this.role,
// //       nom: nom ?? this.nom,
// //       prenom: prenom ?? this.prenom,
// //       sexe: sexe ?? this.sexe,
// //       telephone: telephone ?? this.telephone,
// //       dateNaissance: dateNaissance ?? this.dateNaissance,
// //       codePostal: codePostal ?? this.codePostal,
// //       commune: commune ?? this.commune,
// //       rue: rue ?? this.rue,
// //       numero: numero ?? this.numero,
// //       denominationSociale: denominationSociale ?? this.denominationSociale,
// //       photoProfilFile: photoProfilFile ?? this.photoProfilFile,
// //       photoProfilBytes: photoProfilBytes ?? this.photoProfilBytes,
// //       photoProfilName: photoProfilName ?? this.photoProfilName,
// //     );
// //   }
// //
// //   @override
// //   String toString() {
// //     return 'UserCreationModel(userUuid: $userUuid, email: $email, role: $role, nom: $nom, prenom: $prenom)';
// //   }
// // }
// //
// // /// Classe pour gérer la réponse de l'API
// // class UserCreationResponse {
// //   final bool success;
// //   final String message;
// //   final Map<String, dynamic>? data;
// //   final Map<String, String>? validationErrors;
// //   final int? statusCode;
// //
// //   UserCreationResponse({
// //     required this.success,
// //     required this.message,
// //     this.data,
// //     this.validationErrors,
// //     this.statusCode,
// //   });
// //
// //   /// Factory pour une réponse de succès
// //   factory UserCreationResponse.success({
// //     required String message,
// //     Map<String, dynamic>? data,
// //   }) {
// //     return UserCreationResponse(
// //       success: true,
// //       message: message,
// //       data: data,
// //       statusCode: 201,
// //     );
// //   }
// //
// //   /// Factory pour une réponse d'erreur
// //   factory UserCreationResponse.error({
// //     required String message,
// //     Map<String, String>? validationErrors,
// //     int? statusCode,
// //   }) {
// //     return UserCreationResponse(
// //       success: false,
// //       message: message,
// //       validationErrors: validationErrors,
// //       statusCode: statusCode,
// //     );
// //   }
// //
// //   /// Factory depuis une réponse HTTP
// //   factory UserCreationResponse.fromHttpResponse({
// //     required int statusCode,
// //     required String body,
// //   }) {
// //     try {
// //       final responseData = json.decode(body);
// //
// //       if (statusCode == 201 && responseData['status'] == 'success') {
// //         return UserCreationResponse.success(
// //           message: responseData['message'] ?? 'Profil créé avec succès',
// //           data: responseData['data'],
// //         );
// //       } else if (statusCode == 400) {
// //         // Erreurs de validation
// //         Map<String, String> errors = {};
// //         if (responseData['errors'] != null) {
// //           Map<String, dynamic> apiErrors = responseData['errors'];
// //           apiErrors.forEach((field, messages) {
// //             if (messages is List) {
// //               errors[field] = messages.join(', ');
// //             } else {
// //               errors[field] = messages.toString();
// //             }
// //           });
// //         }
// //
// //         return UserCreationResponse.error(
// //           message: responseData['message'] ?? 'Erreurs de validation',
// //           validationErrors: errors,
// //           statusCode: statusCode,
// //         );
// //       } else {
// //         return UserCreationResponse.error(
// //           message: responseData['message'] ?? 'Erreur serveur',
// //           statusCode: statusCode,
// //         );
// //       }
// //     } catch (e) {
// //       return UserCreationResponse.error(
// //         message: "Erreur lors du parsing de la réponse: $e",
// //         statusCode: statusCode,
// //       );
// //     }
// //   }
// //
// //   /// Récupérer les informations utilisateur créé
// //   Map<String, dynamic>? get createdUserData => data;
// //
// //   /// Vérifier si c'est une erreur d'authentification
// //   bool get isAuthError => statusCode == 401;
// //
// //   /// Vérifier si c'est une erreur de validation
// //   bool get isValidationError => statusCode == 400 && validationErrors != null;
// //
// //   @override
// //   String toString() {
// //     return 'UserCreationResponse(success: $success, message: $message, statusCode: $statusCode)';
// //   }
// // }