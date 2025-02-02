import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/Services.dart';

class CartProvider extends ChangeNotifier {
  List<Service> _cartItems = [];

  List<Service> get cartItems => _cartItems;

  /// **📡 Récupérer le panier de l'utilisateur via l'API**
  Future<void> fetchCartFromApi(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.248:8000/api/get_cart_by_user/$userId/'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setCartFromApi(responseData); // Mise à jour des données
      } else {
        print("❌ Erreur lors du chargement du panier");
      }
    } catch (e) {
      print("❌ Erreur de connexion au serveur : $e");
    }
  }

  /// **🛒 Charger le panier depuis l'API et mettre à jour la liste**
  void setCartFromApi(Map<String, dynamic> cartData) {
    _cartItems = (cartData['items'] as List)
        .map((item) => Service.fromJson(item['service']))
        .toList();
    notifyListeners(); // Met à jour l'interface
  }

  /// **➕ Ajouter un service au panier avec appel à l'API**
  Future<void> addToCart(Service service, String userId) async {
    final url = Uri.parse('http://192.168.0.248:8000/api/add_to_cart/');

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
        // Si l'ajout a réussi côté serveur, on met à jour le panier local
        if (!_cartItems.any((item) => item.id == service.id)) {
          _cartItems.add(service);
          notifyListeners();
        }
        print("✅ Service ajouté au panier côté serveur");
      } else {
        print("❌ Erreur lors de l'ajout au panier: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erreur de connexion lors de l'ajout au panier: $e");
    }
  }

  /// **❌ Supprimer un service du panier**
  void removeFromCart(Service service) {
    _cartItems.removeWhere((item) => item.id == service.id);
    notifyListeners();
  }

  /// **🗑️ Vider complètement le panier**
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}











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
