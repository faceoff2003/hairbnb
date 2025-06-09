import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../models/service_with_promo.dart';

class CartProvider extends ChangeNotifier {
  List<ServiceWithPromo> _cartItems = [];
  int? _coiffeuseId;

  List<ServiceWithPromo> get cartItems => _cartItems;
  int? get coiffeuseId => _coiffeuseId;

  /// **📡 Charger le panier depuis l'API et récupérer `coiffeuseId`**
  Future<void> fetchCartFromApi(String userId) async {
    try {
      // 🔐 Récupération du token Firebase
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_cart/$userId/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ Envoi sécurisé
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("🛒 Réponse API panier: $responseData"); // 🔍 DEBUG AJOUTÉ
        setCartFromApi(responseData);
      } else {
        print("❌ Erreur HTTP ${response.statusCode} : ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur de connexion au serveur : $e");
    }
  }



  // Future<void> fetchCartFromApi(String userId) async {
  //   try {
  //     // 🔐 Récupération du token Firebase
  //     final user = FirebaseAuth.instance.currentUser;
  //     final token = await user?.getIdToken();
  //
  //     if (token == null) throw Exception("Token Firebase manquant");
  //
  //     final response = await http.get(
  //       Uri.parse('https://www.hairbnb.site/api/get_cart/$userId/'),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "Bearer $token", // ✅ Envoi sécurisé
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);
  //       setCartFromApi(responseData);
  //     } else {
  //       print("❌ Erreur HTTP ${response.statusCode} : ${response.body}");
  //     }
  //   } catch (e) {
  //     print("❌ Erreur de connexion au serveur : $e");
  //   }
  // }


  /// **🔹 Mettre à jour les données du panier avec `coiffeuse_id`**
  void setCartFromApi(Map<String, dynamic> cartData) {
    print("🔄 Traitement des données du panier...");

    _cartItems = (cartData['items'] as List)
        .map((item) {
      print("📦 Item panier: $item");
      return ServiceWithPromo.fromJson(item['service']);
    })
        .toList();

    _coiffeuseId = cartData['coiffeuse_id'];

    // Vérifier les durées après chargement
    print("🔢 Panier chargé - ${_cartItems.length} services:");
    for (var service in _cartItems) {
      print("   - ${service.intitule}: ${service.temps} minutes");
    }
    print("🔢 Durée totale calculée: $totalDuration minutes");
    print("🏠 ID Coiffeuse: $_coiffeuseId");

    notifyListeners();
  }


  // void setCartFromApi(Map<String, dynamic> cartData) {
  //   _cartItems = (cartData['items'] as List)
  //       .map((item) => ServiceWithPromo.fromJson(item['service']))
  //       .toList();
  //
  //   _coiffeuseId = cartData['coiffeuse_id']; // ✅ Stocker l'ID de la coiffeuse
  //   notifyListeners();
  // }


  Future<Map<String, dynamic>?> envoyerReservation({
    required String userId,
    required DateTime dateHeure,
    required String methodePaiement,
  }) async {
    if (coiffeuseId == null || cartItems.isEmpty) return null;

    final url = Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/');

    // 🔐 Récupération du token Firebase
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) {
      print("❌ Token Firebase manquant");
      return null;
    }

    final body = json.encode({
      "user_id": userId,
      "coiffeuse_id": coiffeuseId,
      "date_heure": dateHeure.toIso8601String(),
      "services": cartItems.map((s) => s.id).toList(),
      "methode_paiement": methodePaiement,
      "total_price": totalPrice,
      "total_duration": totalDuration,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ Envoi du token
        },
        body: body,
      );

      if (response.statusCode == 201) {
        clearCart(); // 🧹 Vider le panier après succès

        // Récupérer les données de la réponse
        final Map<String, dynamic> responseData =
        json.decode(response.body) is Map
            ? json.decode(response.body)
            : {'success': true};

        return responseData;
      } else {
        print("❌ Erreur serveur : ${response.body}");
        return null;
      }
    } catch (e) {
      print("🚨 Erreur réseau : $e");
      return null;
    }
  }


  /// **➕ Ajouter un service au panier**
  Future<void> addToCart(ServiceWithPromo serviceWithPromo, String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/add_to_cart/');

    try {
      // 🔐 Récupération du token Firebase
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      // 📦 Envoi sécurisé avec le token dans les headers
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ Token ici
        },
        body: json.encode({
          "user_id": userId,
          "service_id": serviceWithPromo.id,
        }),
      );

      if (response.statusCode == 200) {
        fetchCartFromApi(userId); // ✅ Recharger le panier après ajout
      } else {
        print("⚠️ Erreur HTTP ${response.statusCode} : ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur lors de l'ajout au panier : $e");
    }
  }


  // /// **➕ Ajouter un service au panier**
  // Future<void> addToCart(ServiceWithPromo serviceWithPromo, String userId) async {
  //   final url = Uri.parse('https://www.hairbnb.site/api/add_to_cart/');
  //
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: json.encode({
  //         "user_id": userId,
  //         "service_id": serviceWithPromo.id,
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       fetchCartFromApi(userId); // ✅ Recharger le panier après ajout
  //     }
  //   } catch (e) {
  //     print("❌ Erreur lors de l'ajout au panier : $e");
  //   }
  // }

  /// ❌ Supprimer un service
  Future<void> removeFromCart(ServiceWithPromo serviceWithPromo, String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/remove_from_cart/');

    try {
      // 🔐 Récupérer le token Firebase
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) {
        print("❌ Token Firebase manquant");
        return;
      }

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ Authentification sécurisée
        },
        body: json.encode({
          "user_id": userId,
          "service_id": serviceWithPromo.id,
        }),
      );

      if (response.statusCode == 200) {
        fetchCartFromApi(userId); // ✅ Recharge le panier après suppression
      } else {
        final body = response.body;
        print("❌ Erreur lors de la suppression du service (${response.statusCode}) : $body");
      }
    } catch (e) {
      print("❌ Erreur de connexion lors de la suppression : $e");
    }
  }

  /// **🗑️ Vider complètement le panier**
  void clearCart() {
    _cartItems.clear();
    _coiffeuseId = null;
    notifyListeners();
  }

  /// ✅ **Calcul du total des prix avec les promotions**
  double get totalPrice {
    return _cartItems.fold(0.0, (total, serviceWithPromo) {
      return total + serviceWithPromo.prix_final; // ✅ Prix déjà ajusté avec la promo
    });
  }

  /// ✅ **Calcul du total du temps estimé**
  int get totalDuration {
    print("🔢 Calcul totalDuration - cartItems.length: ${_cartItems.length}");
    int total = _cartItems.fold(0, (total, service) {
      print("   Service: ${service.intitule}, temps: ${service.temps}");
      return total + service.temps;
    });
    print("🔢 totalDuration final: $total");

    // 🛡️ PROTECTION: Si totalDuration = 0, utiliser une valeur par défaut
    if (total <= 0 && _cartItems.isNotEmpty) {
      print("⚠️ totalDuration était 0, utilisation de 30 min par service par défaut");
      total = _cartItems.length * 30; // 30 minutes par service par défaut
    }

    return total;
  }

  // int get totalDuration {
  //   return _cartItems.fold(0, (total, service) {
  //     return total + service.temps;
  //   });
  // }

  /// 🔥 Vider le panier côté API + localement
  Future<bool> clearCartFromServer(String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/clear_cart/');

    try {
      // 🔐 Token Firebase
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      final response = http.Request("DELETE", url)
        ..headers["Content-Type"] = "application/json"
        ..headers["Authorization"] = "Bearer $token"
        ..body = json.encode({"user_id": userId});

      final streamed = await http.Client().send(response);

      if (streamed.statusCode == 200) {
        _cartItems.clear();
        _coiffeuseId = null;
        notifyListeners();
        return true;
      } else {
        final body = await streamed.stream.bytesToString();
        print("❌ Erreur HTTP ${streamed.statusCode} : $body");
        return false;
      }
    } catch (e) {
      print("❌ Erreur lors du clearCartFromServer : $e");
      return false;
    }
  }

}