import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/providers/cart_provider.dart';
import '../../services/providers/current_user_provider.dart';

class ConfirmRdvPage extends StatefulWidget {
  @override
  _ConfirmRdvPageState createState() => _ConfirmRdvPageState();
}

class _ConfirmRdvPageState extends State<ConfirmRdvPage> {
  bool isLoading = false;
  String? currentUserId;
  DateTime? selectedDateTime;
  String? selectedPaymentMethod;

  final List<String> paymentMethods = ["Carte", "Cash", "PayPal"];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  /// **📌 Récupérer l'ID utilisateur**
  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    setState(() {
      currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
    });
  }

  /// **📆 Sélectionner la date et l'heure du RDV**
  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  /// **📡 Envoyer la requête pour valider le RDV**
  Future<void> _confirmRdv() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (currentUserId == null || selectedDateTime == null || selectedPaymentMethod == null || cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs et sélectionner des services.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": currentUserId,
          "coiffeuse_id": cartProvider.coiffeuseId,  // ✅ ID de la coiffeuse récupéré du panier
          "date_heure": selectedDateTime!.toIso8601String(),
          "services": cartProvider.cartItems.map((service) => service.id).toList(),
          "methode_paiement": selectedPaymentMethod,
          "total_price": cartProvider.totalPrice,  // ✅ Envoyer le prix total
          "total_duration": cartProvider.totalDuration, // ✅ Envoyer la durée totale
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
        );

        // ✅ Vider le panier après validation
        cartProvider.clearCart();

        Navigator.pop(context); // Retour à la page précédente
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${errorData['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion au serveur.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  // Future<void> _confirmRdv() async {
  //   if (currentUserId == null || selectedDateTime == null || selectedPaymentMethod == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Veuillez remplir tous les champs.")),
  //     );
  //     return;
  //   }
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/'),
  //       headers: {"Content-Type": "application/json"},
  //       body: json.encode({
  //         "user_id": currentUserId,
  //         "date_heure": selectedDateTime!.toIso8601String(),
  //         "methode_paiement": selectedPaymentMethod
  //       }),
  //     );
  //
  //     if (response.statusCode == 201) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
  //       );
  //
  //       // ✅ Vider le panier après validation
  //       Provider.of<CartProvider>(context, listen: false).clearCart();
  //
  //       Navigator.pop(context); // Retour à la page précédente
  //     } else {
  //       final errorData = json.decode(response.body);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Erreur : ${errorData['message']}")),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Erreur de connexion au serveur.")),
  //     );
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("📅 Validation du RDV"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🛒 Services sélectionnés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Expanded(
              child: cartProvider.cartItems.isEmpty
                  ? const Center(child: Text("Aucun service sélectionné 😔"))
                  : ListView.builder(
                itemCount: cartProvider.cartItems.length,
                itemBuilder: (context, index) {
                  final service = cartProvider.cartItems[index];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
                      title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("💰 ${service.prixFinal} € | ⏳ ${service.temps} min"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Provider.of<CartProvider>(context, listen: false).removeFromCart(service,currentUserId!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${service.intitule} supprimé du panier ❌")),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 📆 Sélection de la date et heure du RDV
            ListTile(
              title: Text(
                selectedDateTime == null
                    ? "📆 Sélectionner une date et heure"
                    : "📆 RDV le ${selectedDateTime!.day}/${selectedDateTime!.month} à ${selectedDateTime!.hour}:${selectedDateTime!.minute}",
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.blue),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 20),

            // 💳 Choix du mode de paiement
            const Text("💳 Méthode de paiement :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              items: paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method.toLowerCase(),
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // 🔥 Bouton pour valider le RDV
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _confirmRdv,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("Confirmer le RDV"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
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
// import '../../services/providers/current_user_provider.dart';
//
// class ConfirmRdvPage extends StatefulWidget {
//   @override
//   _ConfirmRdvPageState createState() => _ConfirmRdvPageState();
// }
//
// class _ConfirmRdvPageState extends State<ConfirmRdvPage> {
//   bool isLoading = false;
//   String? currentUserId;
//   DateTime? selectedDateTime;
//   String? selectedPaymentMethod;
//
//   final List<String> paymentMethods = ["Carte", "Cash", "PayPal"];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//   }
//
//   /// **📌 Récupérer l'ID utilisateur**
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     setState(() {
//       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//     });
//   }
//
//   /// **📆 Sélectionner la date et l'heure du RDV**
//   Future<void> _pickDateTime() async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 60)),
//     );
//
//     if (pickedDate != null) {
//       TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//       );
//
//       if (pickedTime != null) {
//         setState(() {
//           selectedDateTime = DateTime(
//             pickedDate.year,
//             pickedDate.month,
//             pickedDate.day,
//             pickedTime.hour,
//             pickedTime.minute,
//           );
//         });
//       }
//     }
//   }
//
//   /// **📡 Envoyer la requête pour valider le RDV**
//   Future<void> _confirmRdv() async {
//     if (currentUserId == null || selectedDateTime == null || selectedPaymentMethod == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez remplir tous les champs.")),
//       );
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/confirm_rendez_vous/'),
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "user_id": currentUserId,
//           "date_heure": selectedDateTime!.toIso8601String(),
//           "methode_paiement": selectedPaymentMethod
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
//         );
//
//         // ✅ Vider le panier après validation
//         Provider.of<CartProvider>(context, listen: false).clearCart();
//
//         Navigator.pop(context); // Retour à la page précédente
//       } else {
//         final errorData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : ${errorData['message']}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("📅 Validation du RDV"),
//         backgroundColor: Colors.orange,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("🛒 Services sélectionnés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Expanded(
//               child: cartProvider.cartItems.isEmpty
//                   ? const Center(child: Text("Aucun service sélectionné 😔"))
//                   : ListView.builder(
//                 itemCount: cartProvider.cartItems.length,
//                 itemBuilder: (context, index) {
//                   final service = cartProvider.cartItems[index];
//                   return ListTile(
//                     leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
//                     title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Text("💰 ${service.prixFinal} € | ⏳ ${service.temps} min"),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // 📆 Sélection de la date et heure du RDV
//             ListTile(
//               title: Text(selectedDateTime == null
//                   ? "📆 Sélectionner une date et heure"
//                   : "📆 RDV le ${selectedDateTime!.day}/${selectedDateTime!.month} à ${selectedDateTime!.hour}:${selectedDateTime!.minute}"),
//               trailing: const Icon(Icons.calendar_today, color: Colors.blue),
//               onTap: _pickDateTime,
//             ),
//             const SizedBox(height: 20),
//
//             // 💳 Choix du mode de paiement
//             const Text("💳 Méthode de paiement :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             DropdownButtonFormField<String>(
//               value: selectedPaymentMethod,
//               items: paymentMethods.map((method) {
//                 return DropdownMenuItem(
//                   value: method.toLowerCase(),
//                   child: Text(method),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedPaymentMethod = value;
//                 });
//               },
//               decoration: const InputDecoration(border: OutlineInputBorder()),
//             ),
//             const SizedBox(height: 20),
//
//             // 🔥 Bouton pour valider le RDV
//             isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ElevatedButton.icon(
//               onPressed: _confirmRdv,
//               icon: const Icon(Icons.check_circle, color: Colors.white),
//               label: const Text("Confirmer le RDV"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 padding: const EdgeInsets.symmetric(vertical: 15),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
