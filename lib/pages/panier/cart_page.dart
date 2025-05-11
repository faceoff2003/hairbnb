import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/service_with_promo.dart';
import '../../services/providers/cart_provider.dart';
import '../../services/providers/current_user_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'confirm_rdv_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool hasError = false;
  String? currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Méthode pour récupérer l'utilisateur actuel
  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    setState(() {
      currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
    });

    if (currentUserId != null) {
      _fetchCart();
    }
  }

  Future<void> _fetchCart() async {
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // 🔐 Récupération du token Firebase
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      // 📦 Requête GET avec header Authorization
      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_cart/$currentUserId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        Provider.of<CartProvider>(context, listen: false).setCartFromApi(responseData);
      } else {
        final errorMsg = utf8.decode(response.bodyBytes);
        print("⚠️ Erreur (${response.statusCode}) : $errorMsg");
        throw Exception("Erreur lors du chargement du panier.");
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      print("❌ Exception dans _fetchCart : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  // Future<void> _fetchCart() async {
  //   if (currentUserId == null) return;
  //
  //   setState(() {
  //     isLoading = true;
  //     hasError = false;
  //   });
  //
  //   try {
  //     final response = await http.get(Uri.parse('https://www.hairbnb.site/api/get_cart/$currentUserId/'));
  //
  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(utf8.decode(response.bodyBytes));
  //       Provider.of<CartProvider>(context, listen: false).setCartFromApi(responseData);
  //     } else {
  //       throw Exception("Erreur lors du chargement du panier.");
  //     }
  //   } catch (e) {
  //     setState(() {
  //       hasError = true;
  //     });
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  // Méthode pour retirer un service du panier
  Future<void> _removeFromCart(ServiceWithPromo serviceWithPromo) async {
    if (currentUserId == null) return;

    try {
      // 🔐 Récupérer le token Firebase
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      // 🧾 Construire la requête DELETE sécurisée
      final request = http.Request(
        "DELETE",
        Uri.parse('https://www.hairbnb.site/api/remove_from_cart/'),
      )
        ..headers["Content-Type"] = "application/json"
        ..headers["Authorization"] = "Bearer $token"
        ..body = json.encode({
          "user_id": currentUserId,
          "service_id": serviceWithPromo.id,
        });

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        _fetchCart();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Service retiré du panier"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );
      } else {
        final body = await response.stream.bytesToString();
        print("⚠️ Erreur HTTP ${response.statusCode} : $body");
      }
    } catch (e) {
      print("❌ Erreur lors de la suppression du panier : $e");
    }
  }


  // Future<void> _removeFromCart(ServiceWithPromo serviceWithPromo) async {
  //   if (currentUserId == null) return;
  //
  //   try {
  //     final request = http.Request(
  //       "DELETE",
  //       Uri.parse('https://www.hairbnb.site/api/remove_from_cart/'),
  //     )
  //       ..headers["Content-Type"] = "application/json"
  //       ..body = json.encode({"user_id": currentUserId, "service_id": serviceWithPromo.id});
  //
  //     final response = await http.Client().send(request);
  //
  //     if (response.statusCode == 200) {
  //       _fetchCart();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("Service retiré du panier"),
  //           backgroundColor: Colors.orange,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //           margin: EdgeInsets.all(10),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print("❌ Erreur lors de la suppression du panier : $e");
  //   }
  // }

  // Future<void> _clearCart() async {
  //   if (currentUserId == null) return;
  //
  //   try {
  //     // 🔐 Récupérer le token Firebase
  //     final user = FirebaseAuth.instance.currentUser;
  //     final token = await user?.getIdToken();
  //
  //     if (token == null) throw Exception("Token Firebase manquant");
  //
  //     // 🔄 Créer la requête DELETE avec Authorization
  //     final request = http.Request(
  //       "DELETE",
  //       Uri.parse('https://www.hairbnb.site/api/clear_cart/'),
  //     )
  //       ..headers["Content-Type"] = "application/json"
  //       ..headers["Authorization"] = "Bearer $token"
  //       ..body = json.encode({"user_id": currentUserId});
  //
  //     final response = await http.Client().send(request);
  //
  //     if (response.statusCode == 200) {
  //       Provider.of<CartProvider>(context, listen: false).clearCart();
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("Panier vidé avec succès"),
  //           backgroundColor: Colors.blue,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //           margin: EdgeInsets.all(10),
  //         ),
  //       );
  //     } else {
  //       final responseBody = await response.stream.bytesToString();
  //       print("⚠️ Erreur HTTP ${response.statusCode} : $responseBody");
  //     }
  //   } catch (e) {
  //     print("❌ Erreur lors du vidage du panier : $e");
  //   }
  // }


  // Future<void> _clearCart() async {
  //   if (currentUserId == null) return;
  //
  //   try {
  //     final request = http.Request(
  //       "DELETE",
  //       Uri.parse('https://www.hairbnb.site/api/clear_cart/'),
  //     )
  //       ..headers["Content-Type"] = "application/json"
  //       ..body = json.encode({"user_id": currentUserId});
  //
  //     final response = await http.Client().send(request);
  //
  //     if (response.statusCode == 200) {
  //       Provider.of<CartProvider>(context, listen: false).clearCart();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("Panier vidé avec succès"),
  //           backgroundColor: Colors.blue,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //           margin: EdgeInsets.all(10),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print("❌ Erreur lors du vidage du panier : $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Mon Panier",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFFF9800),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          if (cartProvider.cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text("Vider le panier ?"),
                    content: Text("Êtes-vous sûr de vouloir supprimer tous les services du panier ?"),
                    actions: [
                      TextButton(
                        child: Text("Annuler", style: TextStyle(color: Colors.grey)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {

                          final success = await Provider.of<CartProvider>(context, listen: false)
                              .clearCartFromServer(currentUserId!);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Panier vidé avec succès"),
                                backgroundColor: Colors.blue,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: EdgeInsets.all(10),
                              ),
                            );
                          }

                        },
                        child: Text("Confirmer"),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? _buildLoadingView()
          : hasError
          ? _buildErrorView()
          : cartProvider.cartItems.isEmpty
          ? _buildEmptyCartView()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFF3E0)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchCart,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: isSmallScreen ? 5 : 10),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final serviceWithPromo = cartProvider.cartItems[index];
                      return _buildCartItem(serviceWithPromo, index);
                    },
                  ),
                ),
              ),
              _buildOrderSummary(cartProvider, isSmallScreen),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cartProvider.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 10),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConfirmRdvPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.greenAccent.withOpacity(0.5),
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Valider la commande",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // NavBar
          BottomNavBar(
            currentIndex: 5, // "Panier"
            onTap: (index) {
              // Navigation gérée directement dans BottomNavBar
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      itemCount: 5,
      padding: EdgeInsets.all(10),
      itemBuilder: (context, index) {
        return Container(
          height: 120,
          margin: EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 20),
          Text(
            "Impossible de charger votre panier",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _fetchCart,
            icon: Icon(Icons.refresh),
            label: Text("Réessayer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Votre panier est vide",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Ajoutez des services pour prendre rendez-vous",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Retour au catalogue
            },
            icon: Icon(Icons.shopping_bag_outlined),
            label: Text("Découvrir les services"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(ServiceWithPromo serviceWithPromo, int index) {
    final isPromo = serviceWithPromo.promotion_active != null;

    return Dismissible(
      key: Key('cart-item-${serviceWithPromo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _removeFromCart(serviceWithPromo);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              // Détail du service si nécessaire
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon du service avec cercle coloré
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.content_cut,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 15),
                  // Contenu principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                serviceWithPromo.intitule,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Bouton de suppression
                            IconButton(
                              onPressed: () => _removeFromCart(serviceWithPromo),
                              icon: Icon(Icons.close, size: 20, color: Colors.grey),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Durée
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              "${serviceWithPromo.temps} min",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        // Prix
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isPromo)
                              Row(
                                children: [
                                  Text(
                                    "${serviceWithPromo.prix} €",
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      "PROMO",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            Spacer(),
                            Text(
                              "${serviceWithPromo.prix_final} €",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isPromo ? Colors.green[700] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total services",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  "${cartProvider.cartItems.length} service${cartProvider.cartItems.length > 1 ? 's' : ''}",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 6),
                    Text(
                      "Temps estimé",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  "${cartProvider.totalDuration} min",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 25, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total à payer",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${cartProvider.totalPrice.toStringAsFixed(2)} €",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}





// // ...imports existants
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import '../../models/service_with_promo.dart';
// import '../../services/providers/cart_provider.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import 'confirm_rdv_page.dart'; // ✅ Ajout pour la navbar
//
// class CartPage extends StatefulWidget {
//   @override
//   _CartPageState createState() => _CartPageState();
// }
//
// class _CartPageState extends State<CartPage> {
//   bool isLoading = true;
//   bool hasError = false;
//   String? currentUserId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//
//     if (currentUserId != null) {
//       _fetchCart();
//     }
//   }
//
//   Future<void> _fetchCart() async {
//     if (currentUserId == null) return;
//
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(Uri.parse('https://www.hairbnb.site/api/get_cart/$currentUserId/'));
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
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
//   Future<void> _addToCart(ServiceWithPromo serviceWithPromo) async {
//     if (currentUserId == null) return;
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/add_to_cart/'),
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({"user_id": currentUserId, "service_id": serviceWithPromo.id, "quantity": 1}),
//       );
//
//       if (response.statusCode == 200) {
//         _fetchCart();
//       }
//     } catch (e) {
//       print("❌ Erreur lors de l'ajout au panier : $e");
//     }
//   }
//
//   Future<void> _removeFromCart(ServiceWithPromo serviceWithPromo) async {
//     if (currentUserId == null) return;
//
//     try {
//       final request = http.Request(
//         "DELETE",
//         Uri.parse('https://www.hairbnb.site/api/remove_from_cart/'),
//       )
//         ..headers["Content-Type"] = "application/json"
//         ..body = json.encode({"user_id": currentUserId, "service_id": serviceWithPromo.id});
//
//       final response = await http.Client().send(request);
//
//       if (response.statusCode == 200) {
//         _fetchCart();
//       }
//     } catch (e) {
//       print("❌ Erreur lors de la suppression du panier : $e");
//     }
//   }
//
//   Future<void> _clearCart() async {
//     if (currentUserId == null) return;
//
//     try {
//       final request = http.Request(
//         "DELETE",
//         Uri.parse('https://www.hairbnb.site/api/clear_cart/'),
//       )
//         ..headers["Content-Type"] = "application/json"
//         ..body = json.encode({"user_id": currentUserId});
//
//       final response = await http.Client().send(request);
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
//     final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("🛒 Mon Panier"),
//         backgroundColor: Colors.orange,
//       ),
//       body: cartProvider.cartItems.isEmpty
//           ? const Center(child: Text("Votre panier est vide 😔"))
//           : Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: cartProvider.cartItems.length,
//               itemBuilder: (context, index) {
//                 final serviceWithPromo = cartProvider.cartItems[index];
//
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                   child: ListTile(
//                     leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
//                     title: Text(serviceWithPromo.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("⏳ ${serviceWithPromo.temps} min"),
//                         if (serviceWithPromo.promotion_active != null) ...[
//                           Text("💰 ${serviceWithPromo.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           Text("🔥 Promo: ${serviceWithPromo.prix_final} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                         ] else ...[
//                           Text("💰 ${serviceWithPromo.prix_final} €"),
//                         ],
//                       ],
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () {
//                         Provider.of<CartProvider>(context, listen: false).removeFromCart(serviceWithPromo, currentUserId!);
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 Text(
//                   "💵 Total: ${cartProvider.totalPrice.toStringAsFixed(2)} €",
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   "⏳ Temps estimé: ${cartProvider.totalDuration} min",
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//
//       /// ✅ Bouton validation commande
//       bottomNavigationBar: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (cartProvider.cartItems.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => ConfirmRdvPage()),
//                   );
//                 },
//                 icon: const Icon(Icons.check, color: Colors.white),
//                 label: const Text("Valider la commande"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                 ),
//               ),
//             ),
//
//           /// 🟣 Intégration de la navbar ici
//           BottomNavBar(
//             currentIndex: 5, // "Panier"
//             onTap: (index) {
//               // Navigation gérée directement dans BottomNavBar
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../services/providers/cart_provider.dart';
// import '../../models/services.dart';
// import '../../services/providers/current_user_provider.dart';
// import 'confirm_rdv_page.dart';
//
// class CartPage extends StatefulWidget {
//   @override
//   _CartPageState createState() => _CartPageState();
// }
//
// class _CartPageState extends State<CartPage> {
//   bool isLoading = true;
//   bool hasError = false;
//   String? currentUserId; // ✅ Stocker l'ID utilisateur
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser(); // Récupérer l'ID utilisateur
//   }
//
//   /// **📌 Récupérer l'ID utilisateur**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(
//         context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//
//     if (currentUserId != null) {
//       _fetchCart(); // Charger le panier après récupération de l'ID user
//     }
//   }
//
//   /// **📡 Charger le panier depuis le serveur**
//   Future<void> _fetchCart() async {
//     if (currentUserId == null) return; // Sécurité
//
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse(
//             'https://www.hairbnb.site/api/get_cart/$currentUserId/'), // ✅ Ajout de user_id
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(utf8.decode(response.bodyBytes));
//
//         Provider.of<CartProvider>(context, listen: false).setCartFromApi(
//             responseData);
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
//     if (currentUserId == null) return;
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/add_to_cart/'),
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "user_id": currentUserId,
//           "service_id": service.id,
//           "quantity": 1
//         }),
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
//     if (currentUserId == null) return;
//
//     try {
//       final request = http.Request(
//         "DELETE",
//         Uri.parse('https://www.hairbnb.site/api/remove_from_cart/'),
//       )
//         ..headers["Content-Type"] = "application/json"
//         ..body = json.encode(
//             {"user_id": currentUserId, "service_id": service.id});
//
//       final response = await http.Client().send(request);
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
//     if (currentUserId == null) return;
//
//     try {
//       final request = http.Request(
//         "DELETE",
//         Uri.parse('https://www.hairbnb.site/api/clear_cart/'),
//       )
//         ..headers["Content-Type"] = "application/json"
//         ..body = json.encode({"user_id": currentUserId});
//
//       final response = await http.Client().send(request);
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
//       body: cartProvider.cartItems.isEmpty
//           ? const Center(child: Text("Votre panier est vide 😔"))
//           : Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: cartProvider.cartItems.length,
//               itemBuilder: (context, index) {
//                 final service = cartProvider.cartItems[index];
//
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                   child: ListTile(
//                     leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
//                     title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("⏳ ${service.temps} min"),
//                         if (service.promotion != null) ...[
//                           Text("💰 ${service.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
//                           Text("🔥 Promo: ${service.prixFinal} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                         ] else ...[
//                           Text("💰 ${service.prixFinal} €"),
//                         ],
//                       ],
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () {
//                         Provider.of<CartProvider>(context, listen: false).removeFromCart(service,currentUserId!);
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           /// **🔥 Afficher le total prix et durée**
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 Text(
//                   "💵 Total: ${cartProvider.totalPrice.toStringAsFixed(2)} €",
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   "⏳ Temps estimé: ${cartProvider.totalDuration} min",
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//
//       // ✅ Ajout du bouton de validation du panier
//       bottomNavigationBar: cartProvider.cartItems.isNotEmpty
//           ? Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: ElevatedButton.icon(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => ConfirmRdvPage()),
//             );
//             // ScaffoldMessenger.of(context).showSnackBar(
//             //   const SnackBar(content: Text("Commande validée 🎉")),
//             // );
//           },
//           icon: const Icon(Icons.check, color: Colors.white),
//           label: const Text("Valider la commande"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             padding: const EdgeInsets.symmetric(vertical: 15),
//           ),
//         ),
//       )
//           : const SizedBox(),
//     );
//   }

  // @override
  // Widget build(BuildContext context) {
  //   final cartProvider = Provider.of<CartProvider>(context);
  //
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text("🛒 Mon Panier"),
  //       backgroundColor: Colors.orange,
  //     ),
  //     body: cartProvider.cartItems.isEmpty
  //         ? const Center(child: Text("Votre panier est vide 😔"))
  //         : Column(
  //       children: [
  //         Expanded(
  //           child: ListView.builder(
  //             itemCount: cartProvider.cartItems.length,
  //             itemBuilder: (context, index) {
  //               final service = cartProvider.cartItems[index];
  //
  //               return Card(
  //                 margin: const EdgeInsets.symmetric(
  //                     vertical: 5, horizontal: 10),
  //                 child: ListTile(
  //                   leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
  //                   title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
  //                   subtitle: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text("⏳ ${service.temps} min"),
  //                       if (service.promotion != null) ...[
  //                         Text("💰 ${service.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)), // Prix barré
  //                         Text("🔥 Promo: ${service.prixFinal} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)), // Prix après réduction
  //                       ] else ...[
  //                         Text("💰 ${service.prixFinal} €"), // Affichage normal si pas de promo
  //                       ],
  //                     ],
  //                   ),
  //                   trailing: IconButton(
  //                     icon: const Icon(Icons.delete, color: Colors.red),
  //                     onPressed: () {
  //                       Provider.of<CartProvider>(context, listen: false).removeFromCart(service, currentUserId!);
  //                     },
  //                   ),
  //                 ),
  //
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //
  //     // ✅ Ajout du bouton de validation du panier
  //     bottomNavigationBar: cartProvider.cartItems.isNotEmpty
  //         ? Padding(
  //       padding: const EdgeInsets.all(10.0),
  //       child: ElevatedButton.icon(
  //         onPressed: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (context) =>
  //                 ConfirmRdvPage()), // 🟢 Naviguer vers la page de confirmation
  //           );
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text("Commande validée 🎉")),
  //           );
  //         },
  //         icon: const Icon(Icons.check, color: Colors.white),
  //         label: const Text("Valider la commande"),
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.green,
  //           padding: const EdgeInsets.symmetric(vertical: 15),
  //         ),
  //       ),
  //     )
  //         : const SizedBox(), // ✅ Cacher si le panier est vide
  //   );
  // }
//}





// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../services/providers/cart_provider.dart';
// import '../../models/services.dart';
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
