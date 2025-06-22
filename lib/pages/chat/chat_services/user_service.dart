import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:hairbnb/models/current_user.dart';

import '../../../services/api_services/api_service.dart';

/// ✅ Gestionnaire de cache avec expiration automatique
class UserCacheManager {
  static final Map<String, CurrentUser?> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration CACHE_DURATION = Duration(minutes: 10);

  static CurrentUser? getCachedUser(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return null;
    
    // Vérifier si le cache a expiré
    if (DateTime.now().difference(timestamp) > CACHE_DURATION) {
      _cache.remove(userId);
      _cacheTimestamps.remove(userId);
      if (kDebugMode) {
        print("🧹 Cache expiré pour $userId");
      }
      return null;
    }
    
    if (kDebugMode) {
      print("✅ Cache valide pour $userId");
    }
    return _cache[userId];
  }

  static void setCachedUser(String userId, CurrentUser? user) {
    _cache[userId] = user;
    _cacheTimestamps[userId] = DateTime.now();
    if (kDebugMode) {
      print("💾 Mise en cache pour $userId: ${user?.prenom} ${user?.nom}");
    }
  }

  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    if (kDebugMode) {
      print("🧹 Cache utilisateur entièrement vidé");
    }
  }

  static void removeUser(String userId) {
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
    if (kDebugMode) {
      print("🗑️ Utilisateur $userId retiré du cache");
    }
  }

  static int getCacheSize() {
    return _cache.length;
  }

  static List<String> getCachedUserIds() {
    return _cache.keys.toList();
  }
}

/// ✅ Fonction principale pour récupérer un autre utilisateur UNIFIÉE
Future<CurrentUser?> fetchOtherUserComplete(String otherUserId) async {
  if (kDebugMode) {
    print("🔍 [fetchOtherUserComplete] Recherche UUID: $otherUserId");
  }

  // Vérifier le cache avec expiration
  final cachedUser = UserCacheManager.getCachedUser(otherUserId);
  if (cachedUser != null) {
    return cachedUser;
  }

  CurrentUser? user;

  // Stratégie 1: Endpoint unifié get_user_profile (PRIORITÉ)
  user = await _fetchFromUnifiedEndpoint(otherUserId);

  // Stratégie 2: Fallback vers l'endpoint coiffeuses
  user ??= await _fetchFromCoiffeusesEndpoint(otherUserId);

  // Stratégie 3: Endpoint client individuel
  user ??= await _fetchFromClientEndpoint(otherUserId);

  // Mettre en cache le résultat (même si null pour éviter les appels répétés)
  UserCacheManager.setCachedUser(otherUserId, user);

  if (user != null && kDebugMode) {
    print("✅ [fetchOtherUserComplete] Utilisateur récupéré: ${user.prenom} ${user.nom} (${user.type})");
  } else if (kDebugMode) {
    print("❌ [fetchOtherUserComplete] Impossible de récupérer l'utilisateur: $otherUserId");
  }

  return user;
}

/// ✅ Stratégie 1: Endpoint unifié (RECOMMANDÉ)
Future<CurrentUser?> _fetchFromUnifiedEndpoint(String otherUserId) async {
  try {
    if (kDebugMode) {
      print("🔄 [Endpoint Unifié] Test pour: $otherUserId");
    }

    // Utiliser APIService pour les en-têtes
    final headers = await APIService.headersPublic;
    
    final response = await http.get(
      Uri.parse('${APIService.baseURL}/get_user_profile/$otherUserId/'),
      headers: headers,
    ).timeout(Duration(seconds: 10));

    if (kDebugMode) {
      print("📡 [Endpoint Unifié] Status: ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData["success"] == true && jsonData["data"] != null) {
        final userData = jsonData["data"];
        
        // ✅ Normaliser les champs pour cohérence
        final normalizedData = {
          'idTblUser': userData['idTblUser'] ?? 0,
          'uuid': userData['uuid'] ?? otherUserId,
          'nom': userData['nom'] ?? '',
          'prenom': userData['prenom'] ?? '',
          'email': userData['email'] ?? '',
          'numero_telephone': userData['numero_telephone'],
          'date_naissance': userData['date_naissance'],
          'is_active': userData['is_active'] ?? true,
          'photo_profil': userData['photo_profil'], // Garder underscore
          'type': userData['type'] ?? 'client',
        };

        final user = CurrentUser.fromJson(normalizedData);
        if (kDebugMode) {
          print("✅ [Endpoint Unifié] Succès: ${user.prenom} ${user.nom}");
        }
        return user;
      }
    } else if (response.statusCode == 404) {
      if (kDebugMode) {
        print("ℹ️ [Endpoint Unifié] Utilisateur non trouvé (404)");
      }
    } else {
      if (kDebugMode) {
        print("❌ [Endpoint Unifié] Erreur HTTP ${response.statusCode}");
      }
    }
  } catch (error) {
    if (kDebugMode) {
      print("❌ [Endpoint Unifié] Exception: $error");
    }
  }
  return null;
}

/// ✅ Stratégie 2: Endpoint coiffeuses
Future<CurrentUser?> _fetchFromCoiffeusesEndpoint(String otherUserId) async {
  try {
    if (kDebugMode) {
      print("🔄 [Endpoint Coiffeuses] Test pour: $otherUserId");
    }

    final headers = await APIService.headersPublic;

    final response = await http.post(
      Uri.parse('${APIService.baseURL}/get_coiffeuses_info/'),
      headers: headers,
      body: jsonEncode({"uuids": [otherUserId]}),
    ).timeout(Duration(seconds: 10));

    if (kDebugMode) {
      print("📡 [Endpoint Coiffeuses] Status: ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
        final coiffeusesList = jsonData["coiffeuses"] as List;

        for (var coiffeuseData in coiffeusesList) {
          if (coiffeuseData['uuid'] == otherUserId) {
            // Transformer les données coiffeuse en CurrentUser
            final normalizedData = {
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

            final user = CurrentUser.fromJson(normalizedData);
            if (kDebugMode) {
              print("✅ [Endpoint Coiffeuses] Coiffeuse trouvée: ${user.prenom} ${user.nom}");
            }
            return user;
          }
        }

        if (kDebugMode) {
          print("❌ [Endpoint Coiffeuses] UUID non trouvé dans la liste");
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ [Endpoint Coiffeuses] Exception: $e");
    }
  }
  return null;
}

/// ✅ Stratégie 3: Endpoint client individuel
Future<CurrentUser?> _fetchFromClientEndpoint(String otherUserId) async {
  try {
    if (kDebugMode) {
      print("🔄 [Endpoint Client] Test pour: $otherUserId");
    }

    final headers = await APIService.headersPublic;

    final response = await http.get(
      Uri.parse('${APIService.baseURL}/get_client_by_uuid/$otherUserId/'),
      headers: headers,
    ).timeout(Duration(seconds: 10));

    if (kDebugMode) {
      print("📡 [Endpoint Client] Status: ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData["status"] == "success" && jsonData["data"] != null) {
        final clientData = jsonData["data"];

        final normalizedData = {
          'idTblUser': clientData['idTblUser'] ?? 0,
          'uuid': clientData['uuid'] ?? otherUserId,
          'nom': clientData['nom'] ?? '',
          'prenom': clientData['prenom'] ?? '',
          'email': clientData['email'] ?? '',
          'numero_telephone': clientData['numero_telephone'],
          'date_naissance': clientData['date_naissance'],
          'is_active': clientData['is_active'] ?? true,
          'photo_profil': clientData['photo_profil'],
          'type': 'client',
        };

        final user = CurrentUser.fromJson(normalizedData);
        if (kDebugMode) {
          print("✅ [Endpoint Client] Client trouvé: ${user.prenom} ${user.nom}");
        }
        return user;
      }
    } else if (response.statusCode == 404) {
      if (kDebugMode) {
        print("ℹ️ [Endpoint Client] Pas un client (404)");
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ [Endpoint Client] Exception: $e");
    }
  }
  return null;
}

/// ✅ Fonction legacy pour compatibilité
Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
  return await fetchOtherUserComplete(otherUserId);
}

/// ✅ Forcer le rechargement d'un utilisateur (bypass cache)
Future<CurrentUser?> forceRefreshUser(String otherUserId) async {
  UserCacheManager.removeUser(otherUserId);
  return await fetchOtherUserComplete(otherUserId);
}

/// ✅ Vider tout le cache
void clearUserCache() {
  UserCacheManager.clearCache();
}

/// ✅ Récupérer les UUIDs des conversations depuis Firebase
Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
  final databaseRef = FirebaseDatabase.instance.ref();
  List<String> conversationUUIDs = [];

  try {
    if (kDebugMode) {
      print("🔍 [fetchCoiffeusesUUIDsFromFirebase] Recherche pour: $userUuid");
    }

    final snapshot = await databaseRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};

      for (var entry in data.entries) {
        final conversationKey = entry.key as String;
        final participants = conversationKey.split("_");
        
        if (participants.length == 2 && participants.contains(userUuid)) {
          final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
          if (!conversationUUIDs.contains(otherUserId)) {
            conversationUUIDs.add(otherUserId);
          }
        }
      }

      if (kDebugMode) {
        print("✅ [fetchCoiffeusesUUIDsFromFirebase] ${conversationUUIDs.length} conversations trouvées");
        print("📋 UUIDs: ${conversationUUIDs.join(', ')}");
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

  return conversationUUIDs;
}

/// ✅ Fonction utilitaire pour obtenir des stats sur le cache
Map<String, dynamic> getCacheStats() {
  final now = DateTime.now();
  int validEntries = 0;
  int expiredEntries = 0;

  for (String userId in UserCacheManager.getCachedUserIds()) {
    final timestamp = UserCacheManager._cacheTimestamps[userId];
    if (timestamp != null && now.difference(timestamp) <= UserCacheManager.CACHE_DURATION) {
      validEntries++;
    } else {
      expiredEntries++;
    }
  }

  return {
    'total_entries': UserCacheManager.getCacheSize(),
    'valid_entries': validEntries,
    'expired_entries': expiredEntries,
    'cache_duration_minutes': UserCacheManager.CACHE_DURATION.inMinutes,
  };
}

/// ✅ Fonction pour nettoyer les entrées expirées du cache
void cleanExpiredCache() {
  final now = DateTime.now();
  final expiredIds = <String>[];

  for (String userId in UserCacheManager.getCachedUserIds()) {
    final timestamp = UserCacheManager._cacheTimestamps[userId];
    if (timestamp != null && now.difference(timestamp) > UserCacheManager.CACHE_DURATION) {
      expiredIds.add(userId);
    }
  }

  for (String expiredId in expiredIds) {
    UserCacheManager.removeUser(expiredId);
  }

  if (kDebugMode && expiredIds.isNotEmpty) {
    print("🧹 Nettoyage cache: ${expiredIds.length} entrées expirées supprimées");
  }
}
