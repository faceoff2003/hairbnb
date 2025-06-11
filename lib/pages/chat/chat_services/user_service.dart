import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/services/firebase_token/token_service.dart';

// Cache simple pour éviter les appels répétés
Map<String, CurrentUser?> _usersCache = {};

final String baseUrl = "https://www.hairbnb.site";

/// Fonction principale pour récupérer un autre utilisateur
/// Utilise TokenService pour l'authentification
Future<CurrentUser?> fetchOtherUserComplete(String otherUserId) async {
  if (kDebugMode) {
    print("🔍 [fetchOtherUserComplete] Recherche UUID: $otherUserId");
  }

  // Vérifier le cache
  if (_usersCache.containsKey(otherUserId)) {
    if (kDebugMode) {
      print("✅ [fetchOtherUserComplete] Trouvé dans le cache");
    }
    return _usersCache[otherUserId];
  }

  CurrentUser? user;

  user = await _fetchWithAuthentication(otherUserId);

  // Stratégie 2: Fallback sans auth
  user ??= await _fetchWithoutAuthentication(otherUserId);

  // Stratégie 3: Endpoint coiffeuses spécialisé
  user ??= await _fetchFromCoiffeusesEndpoint(otherUserId);

  // Mettre en cache
  _usersCache[otherUserId] = user;

  if (user != null && kDebugMode) {
    if (kDebugMode) {
      print("✅ [fetchOtherUserComplete] Utilisateur récupéré: ${user.prenom} ${user.nom}");
    }
  } else if (kDebugMode) {
    print("❌ [fetchOtherUserComplete] Impossible de récupérer l'utilisateur");
  }

  return user;
}

/// Récupération avec authentification via TokenService
Future<CurrentUser?> _fetchWithAuthentication(String otherUserId) async {
  try {
    // Utiliser TokenService pour récupérer le token
    final token = await TokenService.getAuthToken();

    if (token == null) {
      if (kDebugMode) {
        print("❌ [_fetchWithAuthentication] Aucun token disponible");
      }
      return null;
    }

    if (kDebugMode) {
      print("🔑 [_fetchWithAuthentication] Token récupéré");
    }

    final endpoints = [
      '/api/get_user_by_uuid/$otherUserId/',
      '/api/get_current_user/$otherUserId/',
      '/api/user_profile/$otherUserId/',
    ];

    for (String endpoint in endpoints) {
      try {
        final url = '$baseUrl$endpoint';

        if (kDebugMode) {
          print("🌐 [_fetchWithAuthentication] Test: $endpoint");
        }

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final data = json.decode(decodedBody);

          CurrentUser? user = _parseUserFromJson(data);
          if (user != null) {
            if (kDebugMode) {
              print("✅ [_fetchWithAuthentication] Succès avec $endpoint");
            }
            return user;
          }
        } else if (response.statusCode == 401) {
          if (kDebugMode) {
            print("❌ [_fetchWithAuthentication] Token expiré, refresh...");
          }
          // Utiliser TokenService pour forcer le refresh
          final newToken = await TokenService.getAuthToken(forceRefresh: true);
          if (newToken != null) {
            // Réessayer avec le nouveau token
            final retryResponse = await http.get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $newToken',
                'Content-Type': 'application/json',
              },
            ).timeout(Duration(seconds: 10));

            if (retryResponse.statusCode == 200) {
              final decodedBody = utf8.decode(retryResponse.bodyBytes);
              final data = json.decode(decodedBody);
              CurrentUser? user = _parseUserFromJson(data);
              if (user != null) {
                if (kDebugMode) {
                  print("✅ [_fetchWithAuthentication] Succès après refresh");
                }
                return user;
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ [_fetchWithAuthentication] Erreur $endpoint: $e");
        }
        continue;
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ [_fetchWithAuthentication] Erreur générale: $e");
    }
  }

  return null;
}

/// Récupération sans authentification (fallback)
Future<CurrentUser?> _fetchWithoutAuthentication(String otherUserId) async {
  try {
    if (kDebugMode) {
      print("🔄 [_fetchWithoutAuthentication] Tentative sans auth");
    }

    final url = '$baseUrl/api/get_current_user/$otherUserId/';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedBody);

      CurrentUser? user = _parseUserFromJson(data);
      if (user != null) {
        if (kDebugMode) {
          print("✅ [_fetchWithoutAuthentication] Succès sans auth");
        }
        return user;
      }
    } else {
      if (kDebugMode) {
        print("❌ [_fetchWithoutAuthentication] Status ${response.statusCode}");
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ [_fetchWithoutAuthentication] Erreur: $e");
    }
  }

  return null;
}

/// Récupération via l'endpoint coiffeuses
Future<CurrentUser?> _fetchFromCoiffeusesEndpoint(String otherUserId) async {
  try {
    if (kDebugMode) {
      print("🔄 [_fetchFromCoiffeusesEndpoint] Tentative endpoint coiffeuses");
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"uuids": [otherUserId]}),
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
        for (var coiffeuseData in jsonData["coiffeuses"]) {
          if (coiffeuseData['uuid'] == otherUserId) {
            // Transformer les données coiffeuse en CurrentUser
            final userData = {
              'idTblUser': coiffeuseData['idTblUser'] ?? 0,
              'uuid': coiffeuseData['uuid'],
              'nom': coiffeuseData['nom'] ?? '',
              'prenom': coiffeuseData['prenom'] ?? '',
              'email': coiffeuseData['email'] ?? '',
              'numero_telephone': coiffeuseData['numero_telephone'],
              'date_naissance': coiffeuseData['date_naissance'],
              'is_active': coiffeuseData['is_active'] ?? true,
              'photo_profil': coiffeuseData['photo_profil'],
              'type': 'coiffeuse',
            };

            CurrentUser? user = _parseUserFromJson({'user': userData});
            if (user != null) {
              if (kDebugMode) {
                print("✅ [_fetchFromCoiffeusesEndpoint] Coiffeuse trouvée");
              }
              return user;
            }
          }
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ [_fetchFromCoiffeusesEndpoint] Erreur: $e");
    }
  }

  return null;
}

/// Parser les données JSON en CurrentUser
CurrentUser? _parseUserFromJson(Map<String, dynamic> data) {
  try {
    CurrentUser? user;

    if (data['user'] != null) {
      // Structure: {"user": {...}}
      user = CurrentUser.fromJson(data['user']);
    } else if (data['data'] != null && data['success'] == true) {
      // Structure: {"success": true, "data": {...}}
      user = CurrentUser.fromJson(data['data']);
    } else if (data['uuid'] != null) {
      // Structure directe: {...}
      user = CurrentUser.fromJson(data);
    }

    return user;
  } catch (e) {
    if (kDebugMode) {
      print("❌ [_parseUserFromJson] Erreur parsing: $e");
    }
    return null;
  }
}

/// Fonction legacy pour compatibilité
Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
  return await fetchOtherUserComplete(otherUserId);
}

/// Vider le cache
void clearUserCache() {
  _usersCache.clear();
  if (kDebugMode) {
    print("🧹 [clearUserCache] Cache vidé");
  }
}

/// Forcer le rechargement d'un utilisateur
Future<CurrentUser?> forceRefreshUser(String otherUserId) async {
  _usersCache.remove(otherUserId);
  return await fetchOtherUserComplete(otherUserId);
}

/// Récupérer les UUIDs des conversations depuis Firebase
Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
  final databaseRef = FirebaseDatabase.instance.ref();
  List<String> coiffeusesUUIDs = [];

  try {
    if (kDebugMode) {
      print("🔍 [fetchCoiffeusesUUIDsFromFirebase] Recherche pour: $userUuid");
    }

    final snapshot = await databaseRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};

      for (var entry in data.entries) {
        final participants = entry.key.split("_");
        if (participants.contains(userUuid)) {
          final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
          if (!coiffeusesUUIDs.contains(otherUserId)) {
            coiffeusesUUIDs.add(otherUserId);
          }
        }
      }

      if (kDebugMode) {
        print("✅ [fetchCoiffeusesUUIDsFromFirebase] ${coiffeusesUUIDs.length} trouvées");
      }
    } else {
      if (kDebugMode) {
        print("❌ [fetchCoiffeusesUUIDsFromFirebase] Aucune donnée Firebase");
      }
    }
  } catch (error) {
    if (kDebugMode) {
      print("❌ [fetchCoiffeusesUUIDsFromFirebase] Erreur: $error");
    }
  }

  return coiffeusesUUIDs;
}








// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:http/http.dart' as http;
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/services/firebase_token/token_service.dart';
//
// // ✅ Cache pour éviter de recharger les mêmes utilisateurs
// Map<String, CurrentUser?> usersCache = {};
//
// final String baseUrl = "https://www.hairbnb.site";
//
// /// 🔄 Fonction principale pour récupérer un utilisateur avec stratégies multiples
// Future<CurrentUser?> fetchOtherUserComplete(String otherUserId) async {
//   if (kDebugMode) {
//     print("🔍 Début de fetchOtherUserComplete pour: $otherUserId");
//   }
//
//   if (usersCache.containsKey(otherUserId)) {
//     if (kDebugMode) {
//       print("✅ Utilisateur trouvé dans le cache");
//     }
//     return usersCache[otherUserId];
//   }
//
//   // Stratégie 1: Endpoints avec authentification
//   CurrentUser? user = await _tryAuthenticatedEndpoints(otherUserId);
//
//   // Stratégie 2: Si échec, essayer via conversations
//   if (user == null) {
//     user = await _tryConversationEndpoint(otherUserId);
//   }
//
//   // Stratégie 3: Si toujours échec, utiliser l'ancien endpoint sans auth
//   if (user == null) {
//     user = await _tryLegacyEndpoint(otherUserId);
//   }
//
//   // Mettre en cache le résultat (même si null)
//   usersCache[otherUserId] = user;
//
//   if (user != null && kDebugMode) {
//     print("✅ Utilisateur final récupéré: ${user.prenom} ${user.nom}");
//     print("📷 Photo profil finale: ${user.photoProfil}");
//   } else if (kDebugMode) {
//     print("❌ Impossible de récupérer l'utilisateur: $otherUserId");
//   }
//
//   return user;
// }
//
// /// Stratégie 1: Essayer les endpoints avec authentification
// Future<CurrentUser?> _tryAuthenticatedEndpoints(String otherUserId) async {
//   final token = await TokenService.getAuthToken();
//   if (token == null) {
//     if (kDebugMode) {
//       print("❌ Aucun token d'authentification disponible");
//     }
//     return null;
//   }
//
//   final endpoints = [
//     '/api/get_user_by_uuid/$otherUserId/',
//     '/api/get_current_user/$otherUserId/',
//     '/api/user_profile/$otherUserId/',
//   ];
//
//   for (String endpoint in endpoints) {
//     try {
//       final url = '$baseUrl$endpoint';
//       if (kDebugMode) {
//         print("🌐 Tentative endpoint avec auth: $url");
//       }
//
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       ).timeout(Duration(seconds: 10));
//
//       if (kDebugMode) {
//         print("📡 Statut de la réponse: ${response.statusCode}");
//       }
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         if (kDebugMode) {
//           print("📄 Réponse reçue pour $endpoint");
//         }
//
//         final data = json.decode(decodedBody);
//
//         // Vérifier différentes structures de réponse possibles
//         CurrentUser? user = _parseUserFromResponse(data);
//
//         if (user != null) {
//           if (kDebugMode) {
//             print("✅ Utilisateur créé depuis $endpoint: ${user.prenom} ${user.nom}");
//           }
//           return user;
//         }
//       } else if (response.statusCode == 401) {
//         if (kDebugMode) {
//           print("❌ Token invalide pour $endpoint - refresh nécessaire");
//         }
//         await TokenService.getAuthToken(forceRefresh: true);
//       }
//     } catch (error) {
//       if (kDebugMode) {
//         print("❌ Erreur avec $endpoint: $error");
//       }
//       continue; // Essayer l'endpoint suivant
//     }
//   }
//
//   return null;
// }
//
// /// Stratégie 2: Essayer l'endpoint des conversations
// Future<CurrentUser?> _tryConversationEndpoint(String otherUserId) async {
//   if (kDebugMode) {
//     print("🔄 Tentative via endpoint conversations");
//   }
//
//   final token = await TokenService.getAuthToken();
//   if (token == null) return null;
//
//   try {
//     final url = '$baseUrl/api/get_conversation_participants/';
//     if (kDebugMode) {
//       print("🌐 Appel API conversations: $url");
//     }
//
//     final response = await http.post(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'user_uuid': otherUserId,
//       }),
//     ).timeout(Duration(seconds: 10));
//
//     if (response.statusCode == 200) {
//       final decodedBody = utf8.decode(response.bodyBytes);
//       final data = json.decode(decodedBody);
//
//       CurrentUser? user = _parseUserFromResponse(data);
//       if (user != null) {
//         if (kDebugMode) {
//           print("✅ Utilisateur récupéré via conversations");
//         }
//         return user;
//       }
//     } else if (response.statusCode == 401) {
//       if (kDebugMode) {
//         print("❌ Token invalide pour conversations - refresh nécessaire");
//       }
//       await TokenService.getAuthToken(forceRefresh: true);
//     }
//   } catch (error) {
//     if (kDebugMode) {
//       print("❌ Erreur endpoint conversations: $error");
//     }
//   }
//
//   return null;
// }
//
// /// Stratégie 3: Fallback sans authentification (legacy)
// Future<CurrentUser?> _tryLegacyEndpoint(String otherUserId) async {
//   if (kDebugMode) {
//     print("🔄 Fallback sans authentification (legacy)");
//   }
//
//   try {
//     final url = '$baseUrl/api/get_current_user/$otherUserId/';
//     if (kDebugMode) {
//       print("🌐 Appel API legacy: $url");
//     }
//
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {'Content-Type': 'application/json'},
//     ).timeout(Duration(seconds: 10));
//
//     if (kDebugMode) {
//       print("📡 Statut de la réponse legacy: ${response.statusCode}");
//     }
//
//     if (response.statusCode == 200) {
//       final decodedBody = utf8.decode(response.bodyBytes);
//       if (kDebugMode) {
//         print("📄 Réponse brute legacy: ${decodedBody.substring(0, decodedBody.length > 200 ? 200 : decodedBody.length)}...");
//       }
//
//       final data = json.decode(decodedBody);
//       CurrentUser? user = _parseUserFromResponse(data);
//
//       if (user != null) {
//         if (kDebugMode) {
//           print("✅ Utilisateur créé via legacy: ${user.prenom} ${user.nom}");
//         }
//         return user;
//       }
//     } else if (response.statusCode == 404) {
//       if (kDebugMode) {
//         print("❌ Utilisateur non trouvé (404) - legacy");
//       }
//     } else {
//       if (kDebugMode) {
//         print("❌ Erreur HTTP legacy ${response.statusCode}: ${response.body}");
//       }
//     }
//   } catch (error) {
//     if (kDebugMode) {
//       print("❌ Erreur fallback legacy: $error");
//     }
//   }
//
//   return null;
// }
//
// /// Fonction utilitaire pour parser différentes structures de réponse
// CurrentUser? _parseUserFromResponse(Map<String, dynamic> data) {
//   try {
//     CurrentUser? user;
//
//     if (data['user'] != null) {
//       // Structure: {"user": {...}}
//       user = CurrentUser.fromJson(data['user']);
//     } else if (data['data'] != null && data['success'] == true) {
//       // Structure: {"success": true, "data": {...}}
//       user = CurrentUser.fromJson(data['data']);
//     } else if (data['uuid'] != null) {
//       // Structure directe: {...}
//       user = CurrentUser.fromJson(data);
//     }
//
//     if (user != null && kDebugMode) {
//       print("📷 Photo profil récupérée: ${user.photoProfil}");
//     } else if (kDebugMode) {
//       print("❌ Structure de réponse inattendue");
//       print("📄 Données reçues: $data");
//     }
//
//     return user;
//   } catch (e) {
//     if (kDebugMode) {
//       print("❌ Erreur lors du parsing: $e");
//     }
//     return null;
//   }
// }
//
// /// 🔄 Fonction legacy pour compatibilité (utilise fetchOtherUserComplete)
// Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
//   return await fetchOtherUserComplete(otherUserId);
// }
//
// /// Fonction pour vider le cache (utile pour le debugging)
// void clearUserCache() {
//   usersCache.clear();
//   if (kDebugMode) {
//     print("🧹 Cache utilisateur vidé");
//   }
// }
//
// /// Fonction pour forcer le rechargement d'un utilisateur
// Future<CurrentUser?> forceRefreshUser(String otherUserId) async {
//   usersCache.remove(otherUserId);
//   return await fetchOtherUserComplete(otherUserId);
// }
//
// Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   List<String> coiffeusesUUIDs = [];
//
//   try {
//     if (kDebugMode) {
//       print("🔍 Récupération des UUIDs de coiffeuses pour: $userUuid");
//     }
//     final snapshot = await databaseRef.get();
//
//     if (snapshot.exists) {
//       final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
//       if (kDebugMode) {
//         print("📄 Données Firebase trouvées: ${data.keys.length} conversations");
//       }
//
//       for (var entry in data.entries) {
//         final participants = entry.key.split("_");
//         if (participants.contains(userUuid)) {
//           final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
//           if (!coiffeusesUUIDs.contains(otherUserId)) {
//             coiffeusesUUIDs.add(otherUserId);
//           }
//         }
//       }
//
//       if (kDebugMode) {
//         print("✅ ${coiffeusesUUIDs.length} coiffeuses trouvées");
//       }
//     } else {
//       if (kDebugMode) {
//         print("❌ Aucune donnée Firebase trouvée");
//       }
//     }
//   } catch (error) {
//     if (kDebugMode) {
//       print("❌ Erreur lors de la récupération des coiffeuses UUIDs : $error");
//     }
//   }
//
//   return coiffeusesUUIDs;
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
// // import 'dart:convert';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:hairbnb/models/current_user.dart';
// //
// // // ✅ Cache pour éviter de recharger les mêmes utilisateurs
// // Map<String, CurrentUser?> usersCache = {};
// //
// // final String baseUrl = "https://www.hairbnb.site"; // ⚠️ Met à jour selon ton backend
// //
// // /// 🔄 Récupérer les informations d'un utilisateur via son UUID
// // Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
// //   print("🔍 Début de fetchOtherUser pour: $otherUserId");
// //
// //   if (usersCache.containsKey(otherUserId)) {
// //     print("✅ Utilisateur trouvé dans le cache");
// //     return usersCache[otherUserId]; // ✅ Retour immédiat si déjà en cache
// //   }
// //
// //   try {
// //     final url = '$baseUrl/api/get_current_user/$otherUserId/';
// //     print("🌐 Appel API: $url");
// //
// //     final response = await http.get(
// //       Uri.parse(url),
// //       headers: {'Content-Type': 'application/json'},
// //     ).timeout(Duration(seconds: 10)); // Ajouter un timeout
// //
// //     print("📡 Statut de la réponse: ${response.statusCode}");
// //
// //     if (response.statusCode == 200) {
// //       final decodedBody = utf8.decode(response.bodyBytes);
// //       print("📄 Réponse brute: ${decodedBody.substring(0, decodedBody.length > 200 ? 200 : decodedBody.length)}...");
// //
// //       final data = json.decode(decodedBody);
// //
// //       // Vérifier la structure de la réponse
// //       if (data['user'] != null) {
// //         final user = CurrentUser.fromJson(data['user']);
// //         print("✅ Utilisateur créé: ${user.prenom} ${user.nom}");
// //         print("📷 Photo profil récupérée: ${user.photoProfil}");
// //
// //         usersCache[otherUserId] = user; // ✅ Stocker en cache
// //         return user;
// //       } else {
// //         print("❌ Structure de réponse inattendue: clé 'user' manquante");
// //         print("📄 Données reçues: $data");
// //       }
// //     } else if (response.statusCode == 404) {
// //       print("❌ Utilisateur non trouvé (404)");
// //       usersCache[otherUserId] = null; // Mettre en cache le fait qu'il n'existe pas
// //     } else {
// //       print("❌ Erreur HTTP ${response.statusCode}: ${response.body}");
// //     }
// //   } catch (error) {
// //     print("❌ Erreur lors de la récupération de l'autre utilisateur: $error");
// //
// //     // Si c'est une erreur de timeout ou de réseau, ne pas mettre en cache
// //     if (error is http.ClientException || error.toString().contains('timeout')) {
// //       print("🔄 Erreur de réseau, pas de mise en cache");
// //       return null;
// //     }
// //   }
// //
// //   return null; // 🔴 En cas d'échec
// // }
// //
// // /// Fonction pour vider le cache (utile pour le debugging)
// // void clearUserCache() {
// //   usersCache.clear();
// //   print("🧹 Cache utilisateur vidé");
// // }
// //
// // /// Fonction pour forcer le rechargement d'un utilisateur
// // Future<CurrentUser?> forceRefreshUser(String otherUserId) async {
// //   usersCache.remove(otherUserId);
// //   return await fetchOtherUser(otherUserId);
// // }
// //
// // Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   List<String> coiffeusesUUIDs = [];
// //
// //   try {
// //     print("🔍 Récupération des UUIDs de coiffeuses pour: $userUuid");
// //     final snapshot = await databaseRef.get();
// //
// //     if (snapshot.exists) {
// //       final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
// //       print("📄 Données Firebase trouvées: ${data.keys.length} conversations");
// //
// //       for (var entry in data.entries) {
// //         final participants = entry.key.split("_");
// //         if (participants.contains(userUuid)) {
// //           final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
// //           if (!coiffeusesUUIDs.contains(otherUserId)) {
// //             coiffeusesUUIDs.add(otherUserId);
// //           }
// //         }
// //       }
// //
// //       print("✅ ${coiffeusesUUIDs.length} coiffeuses trouvées");
// //     } else {
// //       print("❌ Aucune donnée Firebase trouvée");
// //     }
// //   } catch (error) {
// //     print("❌ Erreur lors de la récupération des coiffeuses UUIDs : $error");
// //   }
// //
// //   return coiffeusesUUIDs;
// // }
// //
//
//
//
//
//
//
//
// // import 'dart:convert';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:hairbnb/models/current_user.dart';
// //
// // // ✅ Cache pour éviter de recharger les mêmes utilisateurs
// // Map<String, CurrentUser?> usersCache = {};
// //
// // final String baseUrl = "https://www.hairbnb.site";
// //
// // /// 🔄 Récupérer les informations d'un utilisateur via son UUID
// // Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
// //   if (usersCache.containsKey(otherUserId)) {
// //     return usersCache[otherUserId]; // ✅ Retour immédiat si déjà en cache
// //   }
// //
// //   try {
// //     final response = await http.get(
// //       Uri.parse('$baseUrl/api/get_current_user/$otherUserId/'),
// //       headers: {'Content-Type': 'application/json'},
// //     );
// //
// //     if (response.statusCode == 200) {
// //       final decodedBody = utf8.decode(response.bodyBytes);
// //       final data = json.decode(decodedBody);
// //       final user = CurrentUser.fromJson(data['user']);
// //
// //       usersCache[otherUserId] = user; // ✅ Stocker en cache
// //       return user;
// //     }
// //   } catch (error) {
// //     print("Erreur lors de la récupération de l'autre utilisateur: $error");
// //   }
// //
// //   return null; // 🔴 En cas d'échec
// // }
// //
// // Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
// //   final databaseRef = FirebaseDatabase.instance.ref();
// //   List<String> coiffeusesUUIDs = [];
// //
// //   try {
// //     final snapshot = await databaseRef.get();
// //     if (snapshot.exists) {
// //       final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
// //
// //       for (var entry in data.entries) {
// //         final participants = entry.key.split("_");
// //         if (participants.contains(userUuid)) {
// //           final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
// //           if (!coiffeusesUUIDs.contains(otherUserId)) {
// //             coiffeusesUUIDs.add(otherUserId);
// //           }
// //         }
// //       }
// //     }
// //   } catch (error) {
// //     print("Erreur lors de la récupération des coiffeuses UUIDs : $error");
// //   }
// //
// //   return coiffeusesUUIDs;
// // }
