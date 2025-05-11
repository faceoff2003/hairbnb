import 'services.dart';

class CartItem {
  final Service service;
  int quantity; // Permet d'ajouter plusieurs fois le même service

  CartItem({
    required this.service,
    this.quantity = 1,
  });

  // Calcul du prix total pour cet élément dans le panier
  double getPrixTotal() {
    return service.getPrixAvecReduction() * quantity;
  }

  // Convertir JSON vers CartItemModel
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      service: Service.fromJson(json['service']),
      quantity: json['quantity'],
    );
  }

  // Convertir CartItemModel vers JSON
  Map<String, dynamic> toJson() {
    return {
      "service": service.toJson(),
      "quantity": quantity,
    };
  }
}
