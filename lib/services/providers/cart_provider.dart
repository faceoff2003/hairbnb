import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:hairbnb/models/Services.dart';

class CartProvider extends ChangeNotifier {
  List<Service> _cartItems = [];
  int? _coiffeuseId; // ✅ Ajouter l'ID de la coiffeuse

  List<Service> get cartItems => _cartItems;
  int? get coiffeuseId => _coiffeuseId;

  /// **📡 Charger le panier depuis l'API et récupérer `coiffeuseId`**
  Future<void> fetchCartFromApi(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_cart/$userId/'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setCartFromApi(responseData);
      } else {
        print("❌ Erreur lors du chargement du panier");
      }
    } catch (e) {
      print("❌ Erreur de connexion au serveur : $e");
    }
  }

  /// **🔹 Mettre à jour les données du panier avec `coiffeuse_id`**
  void setCartFromApi(Map<String, dynamic> cartData) {
    _cartItems = (cartData['items'] as List)
        .map((item) => Service.fromJson(item['service']))
        .toList();

    _coiffeuseId = cartData['coiffeuse_id']; // ✅ Stocker l'ID de la coiffeuse
    notifyListeners();
  }

  Future<bool> envoyerReservation({
    required String userId,
    required DateTime dateHeure,
    required String methodePaiement,
  }) async {
    if (coiffeuseId == null || cartItems.isEmpty) return false;

    final url = Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/');
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
      final response = await http.post(url, headers: {
        "Content-Type": "application/json",
      }, body: body);

      if (response.statusCode == 201) {
        clearCart(); // 🧹 vider le panier après succès
        return true;
      } else {
        print("❌ Erreur serveur : ${response.body}");
        return false;
      }
    } catch (e) {
      print("🚨 Erreur réseau : $e");
      return false;
    }
  }


  /// **➕ Ajouter un service au panier**
  Future<void> addToCart(Service service, String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/add_to_cart/');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": userId,
          "service_id": service.id,
        }),
      );

      if (response.statusCode == 200) {
        fetchCartFromApi(userId); // ✅ Recharger le panier après ajout
      }
    } catch (e) {
      print("❌ Erreur lors de l'ajout au panier : $e");
    }
  }

  /// **❌ Supprimer un service**
  Future<void> removeFromCart(Service service, String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/remove_from_cart/');

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": userId,
          "service_id": service.id
        }),
      );

      if (response.statusCode == 200) {
        fetchCartFromApi(userId); // ✅ Recharge le panier après suppression
      } else {
        print("❌ Erreur lors de la suppression du service : ${response.statusCode}");
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
    return _cartItems.fold(0.0, (total, service) {
      return total + service.prixFinal; // ✅ Prix déjà ajusté avec la promo
    });
  }

  /// ✅ **Calcul du total du temps estimé**
  int get totalDuration {
    return _cartItems.fold(0, (total, service) {
      return total + service.temps;
    });
  }
}





// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../models/Services.dart';
//
// class CartProvider extends ChangeNotifier {
//   List<Service> _cartItems = [];
//
//   List<Service> get cartItems => _cartItems;
//
//   /// **📡 Récupérer le panier de l'utilisateur via l'API**
//   Future<void> fetchCartFromApi(String userId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_cart_by_user/$userId/'),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         setCartFromApi(responseData); // Mise à jour des données
//       } else {
//         print("❌ Erreur lors du chargement du panier");
//       }
//     } catch (e) {
//       print("❌ Erreur de connexion au serveur : $e");
//     }
//   }
//
//   /// **🛒 Charger le panier depuis l'API et mettre à jour la liste**
//   void setCartFromApi(Map<String, dynamic> cartData) {
//     _cartItems = (cartData['items'] as List)
//         .map((item) => Service.fromJson(item['service']))
//         .toList();
//     notifyListeners(); // Met à jour l'interface
//   }
//
//   /// **➕ Ajouter un service au panier avec appel à l'API**
//   Future<void> addToCart(Service service, String userId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/add_to_cart/');
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "user_id": userId,
//           "service_id": service.id,
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         // Si l'ajout a réussi côté serveur, on met à jour le panier local
//         if (!_cartItems.any((item) => item.id == service.id)) {
//           _cartItems.add(service);
//           notifyListeners();
//         }
//         print("✅ Service ajouté au panier côté serveur");
//       } else {
//         print("❌ Erreur lors de l'ajout au panier: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Erreur de connexion lors de l'ajout au panier: $e");
//     }
//   }
//
//   /// **❌ Supprimer un service du panier**
//   void removeFromCart(Service service) {
//     _cartItems.removeWhere((item) => item.id == service.id);
//     notifyListeners();
//   }
//
//   /// **🗑️ Vider complètement le panier**
//   void clearCart() {
//     _cartItems.clear();
//     notifyListeners();
//   }
// }











// import 'package:flutter/material.dart';
// import '../../models/Services.dart';
//
// class CartProvider extends ChangeNotifier {
//   List<Service> _cartItems = [];
//
//   List<Service> get cartItems => _cartItems;
//
//   /// **🛒 Charger le panier depuis l'API et mettre à jour la liste**
//   void setCartFromApi(Map<String, dynamic> cartData) {
//     _cartItems = (cartData['items'] as List)
//         .map((item) => Service.fromJson(item['service']))
//         .toList();
//     notifyListeners(); // Met à jour l'interface
//   }
//
//   /// **➕ Ajouter un service au panier**
//   void addToCart(Service service) {
//     if (!_cartItems.any((item) => item.id == service.id)) {
//       _cartItems.add(service);
//       notifyListeners();
//     }
//   }
//
//   /// **❌ Supprimer un service du panier**
//   void removeFromCart(Service service) {
//     _cartItems.removeWhere((item) => item.id == service.id);
//     notifyListeners();
//   }
//
//   /// **🗑️ Vider complètement le panier**
//   void clearCart() {
//     _cartItems.clear();
//     notifyListeners();
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
//
// class CartProvider with ChangeNotifier {
//   final List<Service> _cartItems = [];
//
//   List<Service> get cartItems => _cartItems;
//
//   void addToCart(Service service) {
//     _cartItems.add(service);
//     notifyListeners(); // Notifie les pages que l'état du panier a changé
//   }
//
//   void removeFromCart(Service service) {
//     _cartItems.remove(service);
//     notifyListeners();
//   }
//
//   void clearCart() {
//     _cartItems.clear();
//     notifyListeners();
//   }
// }
