import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
        if (kDebugMode) {
          if (kDebugMode) {
            print("⚠️ Erreur HTTP ${response.statusCode} : $body");
          }
        }
      }
    } catch (e) {
      print("❌ Erreur lors de la suppression du panier : $e");
    }
  }


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
                          Navigator.pop(context);

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