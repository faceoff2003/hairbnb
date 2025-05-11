import 'package:flutter/material.dart';
import 'package:hairbnb/services/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../models/service_with_promo.dart';

void addToCart({
  required BuildContext context,
  required ServiceWithPromo serviceWithPromo,
  required String userId,
}) {
  Provider.of<CartProvider>(context, listen: false).addToCart(serviceWithPromo, userId);
  debugPrint("🛒 addToCart() called for service from add_to_card_service.dart : ${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("${serviceWithPromo.intitule} ajouté au panier ✅"),
      backgroundColor: Colors.green,
    ),
  );
}
