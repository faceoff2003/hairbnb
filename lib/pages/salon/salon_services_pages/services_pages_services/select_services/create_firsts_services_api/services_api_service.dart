import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../../models/categorie.dart';
import '../../../../../../models/services.dart';

class ServicesApiService {
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Récupération du token Firebase
  static Future<String?> _obtenirTokenFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        return token;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Charger toutes les catégories
  static Future<List<Categorie>> chargerCategories() async {
    try {
      final token = await _obtenirTokenFirebase();

      if (token == null) {
        throw Exception('Token Firebase manquant - Utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final categoriesJson = data['categories'] as List;
          print("📂 CATEGORIES JSON: $categoriesJson");

          // Conversion avec debug individuel
          List<Categorie> categoriesConverties = [];
          for (int i = 0; i < categoriesJson.length; i++) {
            print("🔄 Conversion catégorie $i:");
            final categorieJson = categoriesJson[i];
            final categorie = Categorie.fromJson(categorieJson);
            categoriesConverties.add(categorie);
            print("🎯 Catégorie $i convertie: ${categorie.toString()}");
          }

          print("✅ CATEGORIES FINALES: ${categoriesConverties.map((c) => 'ID:${c.id} Nom:${c.nom}').toList()}");
          return categoriesConverties;
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement des catégories');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé - Token Firebase invalide');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ ERREUR CATEGORIES: $e");
      throw e;
    }
  }

  /// Charger les services pour une catégorie
  static Future<List<Service>> chargerServicesPourCategorie(int categorieId) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        print("❌ Token manquant pour charger services catégorie $categorieId");
        return [];
      }

      print("🔄 Appel API pour catégorie $categorieId");
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categorieId/services/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final servicesJson = data['services'] as List;
          final services = servicesJson.map((json) => Service.fromJson(json)).toList();

          print("✅ ${services.length} services chargés pour catégorie $categorieId");
          return services;
        }
      } else {
        print("❌ Erreur chargement services catégorie $categorieId: ${response.statusCode}");
      }
      return [];
    } catch (e) {
      print('❌ Erreur chargement services catégorie $categorieId: $e');
      return [];
    }
  }

  /// Charger les services ajoutés par un utilisateur
  static Future<List<Service>> chargerServicesAjoutes(int userId) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        print("❌ Token manquant pour charger les services ajoutés");
        return [];
      }

      print("🔄 Chargement des services ajoutés pour l'utilisateur $userId");

      // Essayons plusieurs URLs possibles
      List<String> urlsAEssayer = [
        '$baseUrl/users/$userId/services/',
        '$baseUrl/services/user/$userId/',
        '$baseUrl/user-services/$userId/',
        '$baseUrl/my-services/',
      ];

      for (String url in urlsAEssayer) {
        print("🔄 Tentative avec URL: $url");

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);

            // Essayons différents formats de réponse
            List<dynamic>? servicesJson;

            if (data is Map<String, dynamic>) {
              if (data.containsKey('status') && data['status'] == 'success') {
                servicesJson = data['services'] as List?;
              } else if (data.containsKey('data')) {
                servicesJson = data['data'] as List?;
              } else if (data.containsKey('results')) {
                servicesJson = data['results'] as List?;
              } else if (data.containsKey('userServices')) {
                servicesJson = data['userServices'] as List?;
              }
            } else if (data is List) {
              servicesJson = data;
            }

            if (servicesJson != null) {
              print("📂 Services JSON trouvés: $servicesJson");

              final services = servicesJson.map((json) {
                print("🔄 Conversion service: $json");
                return Service.fromJson(json);
              }).toList();

              print("✅ ${services.length} services ajoutés récupérés");
              return services;
            }
          } catch (e) {
            print("❌ Erreur parsing JSON pour URL $url: $e");
            continue; // Essayer l'URL suivante
          }
        }
      }

      print("❌ Aucune URL n'a fonctionné pour récupérer les services ajoutés");
      return [];
    } catch (e) {
      print('❌ Erreur chargement services ajoutés: $e');
      return [];
    }
  }

  /// Ajouter un service existant à un utilisateur
  static Future<bool> ajouterServiceExistant({
    required int userId,
    required int serviceId,
    required int categoryId,
    required double prix,
    required int tempsMinutes,
  }) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        throw Exception('Token Firebase manquant');
      }

      print("🔄 Ajout service ID $serviceId - Prix: ${prix}€ - Durée: ${tempsMinutes}min");

      final response = await http.post(
        Uri.parse('$baseUrl/services/add-existing/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'service_id': serviceId,
          'category_id': categoryId,
          'prix': prix,
          'temps_minutes': tempsMinutes,
        }),
      );

      if (response.statusCode == 201) {
        print("✅ Service ajouté avec succès");
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception("Erreur ajout service: ${errorData['message']}");
      }
    } catch (e) {
      print("❌ Erreur ajout service: $e");
      throw e;
    }
  }

  /// Ajouter plusieurs services en une fois
  static Future<List<String>> ajouterPlusieursServices({
    required int userId,
    required List<Map<String, dynamic>> services,
  }) async {
    List<String> erreurs = [];

    for (final serviceData in services) {
      try {
        await ajouterServiceExistant(
          userId: userId,
          serviceId: serviceData['service_id'],
          categoryId: serviceData['category_id'],
          prix: serviceData['prix'],
          tempsMinutes: serviceData['temps_minutes'],
        );
      } catch (e) {
        erreurs.add("Service ${serviceData['service_id']}: $e");
      }
    }

    return erreurs;
  }

  /// Supprimer un service ajouté par un utilisateur
  static Future<bool> supprimerServiceUtilisateur({
    required int userId,
    required int serviceId,
  }) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        throw Exception('Token Firebase manquant');
      }

      print("🔄 Suppression service ID $serviceId pour utilisateur $userId");

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/services/$serviceId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("📡 Réponse suppression service: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ Service supprimé avec succès");
        return true;
      } else {
        throw Exception("Erreur suppression service: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erreur suppression service: $e");
      throw e;
    }
  }

  /// Modifier un service utilisateur (prix, durée)
  static Future<bool> modifierServiceUtilisateur({
    required int userId,
    required int serviceId,
    required double prix,
    required int tempsMinutes,
  }) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        throw Exception('Token Firebase manquant');
      }

      print("🔄 Modification service ID $serviceId - Prix: ${prix}€ - Durée: ${tempsMinutes}min");

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/services/$serviceId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'prix': prix,
          'temps_minutes': tempsMinutes,
        }),
      );

      print("📡 Réponse modification service: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ Service modifié avec succès");
        return true;
      } else {
        throw Exception("Erreur modification service: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erreur modification service: $e");
      throw e;
    }
  }

  /// Récupérer tous les services d'un salon organisés par catégorie
  static Future<Map<String, dynamic>> chargerServicesParCategoriePourSalon(int salonId) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        throw Exception('Token Firebase manquant - Utilisateur non connecté');
      }

      print("🔄 Chargement des services du salon ID: $salonId");

      final response = await http.get(
        Uri.parse('$baseUrl/salon/$salonId/services-by-category/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          print("✅ Services du salon récupérés: ${data['total_services']} services");
          return data;
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement des services du salon');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé - Token Firebase invalide');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ ERREUR chargement services salon: $e");
      throw e;
    }
  }
}