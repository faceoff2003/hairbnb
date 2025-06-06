// models/favorites.dart
class FavoriteModel {
  final int idTblFavorite;
  final int? user;  // Nullable car parfois absent dans la réponse
  final dynamic salon; // Peut être un int ou un objet complet
  final String? addedAt; // Nullable car parfois absent dans la réponse

  FavoriteModel({
    required this.idTblFavorite,
    this.user,
    required this.salon,
    this.addedAt,
  });

  // Méthode pour obtenir l'ID du salon quelle que soit sa représentation
  int getSalonId() {
    if (salon is int) {
      return salon;
    } else if (salon is Map<String, dynamic> && salon.containsKey('idTblSalon')) {
      return salon['idTblSalon'];
    }
    return 0; // Valeur par défaut en cas d'erreur
  }

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      idTblFavorite: json['idTblFavorite'],
      user: json['user'],
      salon: json['salon'], // Peut être un int ou un objet complet
      addedAt: json['added_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblFavorite': idTblFavorite,
      'user': user,
      'salon': salon is int ? salon : (salon is Map ? salon['idTblSalon'] : 0),
      'added_at': addedAt,
    };
  }

  @override
  String toString() {
    return 'FavoriteModel(idTblFavorite: $idTblFavorite, user: $user, salon: ${salon is int ? salon : "Objet Salon"}, addedAt: $addedAt)';
  }
}






// import 'package:flutter/foundation.dart';
//
// class FavoriteModel {
//   final int idTblFavorite;
//   final int user;
//   final int salon;
//   final String addedAt;
//
//   FavoriteModel({
//     required this.idTblFavorite,
//     required this.user,
//     required this.salon,
//     required this.addedAt,
//   });
//
//   factory FavoriteModel.fromJson(Map<String, dynamic> json) {
//     try {
//     return FavoriteModel(
//       idTblFavorite: json['idTblFavorite']?? 0,
//       user: json['user'] ?? 0,
//       salon: json['salon'] ?? 0,
//       addedAt: json['added_at'] ?? 0,
//     );
//     } catch (e) {
//
//       if (kDebugMode) {
//         print("Erreur lors de la conversion JSON en FavoriteModel: $e");
//       }
//       if (kDebugMode) {
//         print("JSON reçu: $json");
//       }
//
//       // Retourner un modèle par défaut en cas d'erreur
//       return FavoriteModel(
//         idTblFavorite: 0,
//         user: 0,
//         salon: 0,
//         addedAt: '',
//       );
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblFavorite': idTblFavorite,
//       'user': user,
//       'salon': salon,
//       'added_at': addedAt,
//     };
//   }
//
//   @override
//   String toString() {
//     return 'FavoriteModel(idTblFavorite: $idTblFavorite, user: $user, salon: $salon, addedAt: $addedAt)';
//   }
// }