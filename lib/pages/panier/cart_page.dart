import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/providers/cart_provider.dart';
import '../../models/Services.dart';
import '../../services/providers/current_user_provider.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = true;
  bool hasError = false;
  String? currentUserId; // ✅ Stocker l'ID utilisateur

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser(); // Récupérer l'ID utilisateur
  }

  /// **📌 Récupérer l'ID utilisateur**
  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    setState(() {
      currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
    });

    if (currentUserId != null) {
      _fetchCart(); // Charger le panier après récupération de l'ID user
    }
  }

  /// **📡 Charger le panier depuis le serveur**
  Future<void> _fetchCart() async {
    if (currentUserId == null) return; // Sécurité

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.248:8000/api/get_cart/$currentUserId/'), // ✅ Ajout de user_id
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        Provider.of<CartProvider>(context, listen: false).setCartFromApi(responseData);
      } else {
        throw Exception("Erreur lors du chargement du panier.");
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// **➕ Ajouter un service au panier**
  Future<void> _addToCart(Service service) async {
    if (currentUserId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.248:8000/api/add_to_cart/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": currentUserId, "service_id": service.id, "quantity": 1}),
      );

      if (response.statusCode == 200) {
        _fetchCart(); // Recharge le panier
      }
    } catch (e) {
      print("❌ Erreur lors de l'ajout au panier : $e");
    }
  }

  /// **❌ Supprimer un service du panier**
  Future<void> _removeFromCart(Service service) async {
    if (currentUserId == null) return;

    try {
      final request = http.Request(
        "DELETE",
        Uri.parse('http://192.168.0.248:8000/api/remove_from_cart/'),
      )
        ..headers["Content-Type"] = "application/json"
        ..body = json.encode({"user_id": currentUserId, "service_id": service.id});

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        _fetchCart(); // Recharge le panier
      }
    } catch (e) {
      print("❌ Erreur lors de la suppression du panier : $e");
    }
  }

  /// **🗑️ Vider tout le panier**
  Future<void> _clearCart() async {
    if (currentUserId == null) return;

    try {
      final request = http.Request(
        "DELETE",
        Uri.parse('http://192.168.0.248:8000/api/clear_cart/'),
      )
        ..headers["Content-Type"] = "application/json"
        ..body = json.encode({"user_id": currentUserId});

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        Provider.of<CartProvider>(context, listen: false).clearCart();
      }
    } catch (e) {
      print("❌ Erreur lors du vidage du panier : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Mon Panier"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: ElevatedButton(
          onPressed: _fetchCart,
          child: const Text("Réessayer"),
        ),
      )
          : cartProvider.cartItems.isEmpty
          ? const Center(child: Text("Votre panier est vide 😔"))
          : ListView.builder(
        itemCount: cartProvider.cartItems.length,
        itemBuilder: (context, index) {
          final service = cartProvider.cartItems[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: ListTile(
              leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
              title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("💰 ${service.prix} € | ⏳ ${service.temps} min"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeFromCart(service),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: cartProvider.cartItems.isEmpty
          ? const SizedBox()
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton.icon(
          onPressed: () {
            _clearCart(); // Vide le panier
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Commande validée 🎉")),
            );
          },
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text("Valider la commande"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../services/providers/cart_provider.dart';
// import '../../models/Services.dart';
//
// class CartPage extends StatefulWidget {
//   @override
//   _CartPageState createState() => _CartPageState();
// }
//
// class _CartPageState extends State<CartPage> {
//   bool isLoading = true;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCart(); // Charge le panier dès l'ouverture
//   }
//
//   /// **📡 Charger le panier depuis le serveur**
//   Future<void> _fetchCart() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.248:8000/api/get_cart/'), // 🔗 URL de l'API
//         //headers: {"Authorization": "Bearer YOUR_TOKEN_HERE"}, // Authentification JWT si activée
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         Provider.of<CartProvider>(context, listen: false).setCartFromApi(responseData);
//       } else {
//         throw Exception("Erreur lors du chargement du panier.");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   /// **➕ Ajouter un service au panier**
//   Future<void> _addToCart(Service service) async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://192.168.0.248:8000/api/add_to_cart/'),
//         //headers: {"Content-Type": "application/json", "Authorization": "Bearer YOUR_TOKEN_HERE"},
//         body: json.encode({"service_id": service.id, "quantity": 1}),
//       );
//
//       if (response.statusCode == 200) {
//         _fetchCart(); // Recharge le panier
//       }
//     } catch (e) {
//       print("❌ Erreur lors de l'ajout au panier : $e");
//     }
//   }
//
//   /// **❌ Supprimer un service du panier**
//   Future<void> _removeFromCart(Service service) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('http://192.168.0.248:8000/api/remove_from_cart/'),
//         //headers: {"Content-Type": "application/json", "Authorization": "Bearer YOUR_TOKEN_HERE"},
//         body: json.encode({"service_id": service.id}),
//       );
//
//       if (response.statusCode == 200) {
//         _fetchCart(); // Recharge le panier
//       }
//     } catch (e) {
//       print("❌ Erreur lors de la suppression du panier : $e");
//     }
//   }
//
//   /// **🗑️ Vider tout le panier**
//   Future<void> _clearCart() async {
//     try {
//       final response = await http.delete(
//         Uri.parse('http://192.168.0.248:8000/api/clear_cart/'),
//         //headers: {"Authorization": "Bearer YOUR_TOKEN_HERE"},
//       );
//
//       if (response.statusCode == 200) {
//         Provider.of<CartProvider>(context, listen: false).clearCart();
//       }
//     } catch (e) {
//       print("❌ Erreur lors du vidage du panier : $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("🛒 Mon Panier"),
//         backgroundColor: Colors.orange,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: ElevatedButton(
//           onPressed: _fetchCart,
//           child: const Text("Réessayer"),
//         ),
//       )
//           : cartProvider.cartItems.isEmpty
//           ? const Center(child: Text("Votre panier est vide 😔"))
//           : ListView.builder(
//         itemCount: cartProvider.cartItems.length,
//         itemBuilder: (context, index) {
//           final service = cartProvider.cartItems[index];
//
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//             child: ListTile(
//               leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
//               title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
//               subtitle: Text("💰 ${service.prix} € | ⏳ ${service.temps} min"),
//               trailing: IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 onPressed: () => _removeFromCart(service),
//               ),
//             ),
//           );
//         },
//       ),
//       bottomNavigationBar: cartProvider.cartItems.isEmpty
//           ? const SizedBox()
//           : Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: ElevatedButton.icon(
//           onPressed: () {
//             _clearCart(); // Vide le panier
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text("Commande validée 🎉")),
//             );
//           },
//           icon: const Icon(Icons.check, color: Colors.white),
//           label: const Text("Valider la commande"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             padding: const EdgeInsets.symmetric(vertical: 15),
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../services/providers/cart_provider.dart';
//
// class CartPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("🛒 Mon Panier"),
//         backgroundColor: Colors.orange,
//       ),
//       body: cartProvider.cartItems.isEmpty
//           ? const Center(child: Text("Votre panier est vide 😔"))
//           : ListView.builder(
//         itemCount: cartProvider.cartItems.length,
//         itemBuilder: (context, index) {
//           final service = cartProvider.cartItems[index];
//
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//             child: ListTile(
//               leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
//               title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
//               subtitle: Text("💰 ${service.prix} € | ⏳ ${service.temps} min"),
//               trailing: IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 onPressed: () => cartProvider.removeFromCart(service),
//               ),
//             ),
//           );
//         },
//       ),
//       bottomNavigationBar: cartProvider.cartItems.isEmpty
//           ? const SizedBox()
//           : Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: ElevatedButton.icon(
//           onPressed: () {
//             // TODO: Implémenter la logique de paiement ou réservation
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text("Commande validée 🎉")),
//             );
//             cartProvider.clearCart();
//           },
//           icon: const Icon(Icons.check, color: Colors.white),
//           label: const Text("Valider la commande"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             padding: const EdgeInsets.symmetric(vertical: 15),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
