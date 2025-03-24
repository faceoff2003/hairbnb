import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/providers/cart_provider.dart';
import '../../services/providers/current_user_provider.dart';
import '../../services/providers/disponibilites_provider.dart';

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
    _chargerDisponibilites();
  }

  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
  }

  void _chargerDisponibilites() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
    disponibilitesProvider.loadDisponibilites(
      cartProvider.coiffeuseId.toString(),
      cartProvider.totalDuration,
    );
  }


  Future<void> _pickDateTime() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);

    final now = DateTime.now();
    final endDate = now.add(Duration(days: 14));

    if (!disponibilitesProvider.isLoaded || disponibilitesProvider.joursDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Chargement des disponibilités...")),
      );
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: disponibilitesProvider.joursDisponibles.first,
      firstDate: now,
      lastDate: endDate,
      selectableDayPredicate: (day) => disponibilitesProvider.isJourDispo(day),
    );

    if (pickedDate == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
    final creneaux = await disponibilitesProvider.getCreneauxPourJour(
      dateStr,
      cartProvider.coiffeuseId.toString(),
      cartProvider.totalDuration,
    );

    // 🕓 Si la date choisie est aujourd'hui, on filtre les horaires déjà passés
    final filteredCreneaux = creneaux.where((slot) {
      if (pickedDate.year == now.year &&
          pickedDate.month == now.month &&
          pickedDate.day == now.day) {
        final timeParts = slot["debut"]!.split(":");
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final slotDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, hour, minute);
        return slotDateTime.isAfter(now);
      }
      return true;
    }).toList();

    if (filteredCreneaux.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aucun créneau disponible pour cette date.")),
      );
      return;
    }

    final selectedSlot = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("Choisir une heure"),
        children: filteredCreneaux.map((slot) {
          final debut = slot["debut"]!;
          final fin = slot["fin"]!;
          return SimpleDialogOption(
            child: Text("$debut - $fin"),
            onPressed: () => Navigator.pop(context, slot),
          );
        }).toList(),
      ),
    );

    if (selectedSlot != null) {
      final debut = selectedSlot["debut"]!;
      final dateTime = DateTime.parse("${dateStr}T$debut:00");
      setState(() {
        selectedDateTime = dateTime;
      });
    }
  }


  // Future<void> _pickDateTime() async {
  //   final cartProvider = Provider.of<CartProvider>(context, listen: false);
  //   final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
  //
  //   final now = DateTime.now();
  //   final endDate = now.add(Duration(days: 14));
  //
  //   if (!disponibilitesProvider.isLoaded || disponibilitesProvider.joursDisponibles.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Chargement des disponibilités...")),
  //     );
  //     return;
  //   }
  //
  //   final pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: disponibilitesProvider.joursDisponibles.first,
  //     firstDate: now,
  //     lastDate: endDate,
  //     selectableDayPredicate: (day) => disponibilitesProvider.isJourDispo(day),
  //   );
  //
  //   if (pickedDate == null) return;
  //
  //   final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
  //   final creneaux = await disponibilitesProvider.getCreneauxPourJour(
  //     dateStr,
  //     cartProvider.coiffeuseId.toString(),
  //     cartProvider.totalDuration,
  //   );
  //
  //   if (creneaux.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Aucun créneau disponible pour ce jour.")),
  //     );
  //     return;
  //   }
  //
  //   final selectedSlot = await showDialog<Map<String, String>>(
  //     context: context,
  //     builder: (context) => SimpleDialog(
  //       title: Text("Choisir une heure"),
  //       children: creneaux.map((slot) {
  //         final debut = slot["debut"]!;
  //         final fin = slot["fin"]!;
  //         return SimpleDialogOption(
  //           child: Text("$debut - $fin"),
  //           onPressed: () => Navigator.pop(context, slot),
  //         );
  //       }).toList(),
  //     ),
  //   );
  //
  //   if (selectedSlot != null) {
  //     final debut = selectedSlot["debut"]!;
  //     final dateTime = DateTime.parse("${dateStr}T$debut:00");
  //     setState(() {
  //       selectedDateTime = dateTime;
  //     });
  //   }
  // }

  Future<void> _confirmRdv() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (currentUserId == null ||
        selectedDateTime == null ||
        selectedPaymentMethod == null ||
        cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs et sélectionner des services.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await cartProvider.envoyerReservation(
        userId: currentUserId!,
        dateHeure: selectedDateTime!,
        methodePaiement: selectedPaymentMethod!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la confirmation du RDV.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion au serveur.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("🗓️ Confirmation RDV"), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("💼 Services sélectionnés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: cartProvider.cartItems.isEmpty
                  ? const Center(child: Text("Aucun service sélectionné."))
                  : ListView.builder(
                itemCount: cartProvider.cartItems.length,
                itemBuilder: (context, index) {
                  final service = cartProvider.cartItems[index];
                  return ListTile(
                    leading: Icon(Icons.miscellaneous_services, color: Colors.orange),
                    title: Text(service.intitule),
                    subtitle: Text("💰 ${service.prixFinal} € | ⏳ ${service.temps} min"),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text(selectedDateTime == null
                  ? "📅 Sélectionner un créneau"
                  : "📅 RDV le ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime!)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Méthode de paiement"),
              items: paymentMethods.map((methode) {
                return DropdownMenuItem<String>(
                  value: methode.toLowerCase(),
                  child: Text(methode),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedPaymentMethod = value),
            ),
            const SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              icon: Icon(Icons.check),
              label: Text("Confirmer le RDV"),
              onPressed: _confirmRdv,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}









// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
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
//   Set<DateTime> joursDisponibles = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _loadJoursDisponibles();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//   }
//
//   Future<List<DateTime>> _getJoursDispos(DateTime start, DateTime end) async {
//     final coiffeuseId = Provider.of<CartProvider>(context, listen: false).coiffeuseId;
//     final duree = Provider.of<CartProvider>(context, listen: false).totalDuration;
//     List<DateTime> joursOK = [];
//
//     for (int i = 0; i <= end.difference(start).inDays; i++) {
//       final date = start.add(Duration(days: i));
//       final dateStr = DateFormat('yyyy-MM-dd').format(date);
//
//       final response = await http.get(Uri.parse(
//         "https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree",
//       ));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if ((data['disponibilites'] as List).isNotEmpty) {
//           joursOK.add(date);
//         }
//       }
//     }
//     return joursOK;
//   }
//
//   Future<void> _loadJoursDisponibles() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final coiffeuseId = cartProvider.coiffeuseId;
//     final duree = cartProvider.totalDuration;
//
//     final now = DateTime.now();
//     final end = now.add(Duration(days: 14));
//
//     Set<DateTime> jours = {};
//
//     for (int i = 0; i <= end.difference(now).inDays; i++) {
//       final date = now.add(Duration(days: i));
//       final dateStr = DateFormat('yyyy-MM-dd').format(date);
//
//       final response = await http.get(Uri.parse(
//         "https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree",
//       ));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if ((data['disponibilites'] as List).isNotEmpty) {
//           jours.add(DateTime(date.year, date.month, date.day));
//         }
//       }
//     }
//
//     setState(() {
//       joursDisponibles = jours;
//     });
//   }
//
//
//   Future<void> _pickDateTime() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final now = DateTime.now();
//     final endDate = now.add(Duration(days: 14));
//
//     // ⏳ Affiche un petit loader pendant qu’on récupère les dispos
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator()),
//     );
//
//     final joursDispo = await _getJoursDispos(now, endDate);
//
//     Navigator.pop(context); // ❌ Fermer le loader
//
//     if (joursDispo.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Aucune date disponible pour cette coiffeuse.")),
//       );
//       return;
//     }
//
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: joursDispo.first,
//       firstDate: now,
//       lastDate: endDate,
//       selectableDayPredicate: (day) {
//         return joursDispo.any((d) =>
//         d.year == day.year && d.month == day.month && d.day == day.day);
//       },
//     );
//
//     if (pickedDate == null) return;
//
//     final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
//     final coiffeuseId = cartProvider.coiffeuseId;
//     final duree = cartProvider.totalDuration;
//
//     final response = await http.get(Uri.parse(
//       "https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree",
//     ));
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final slots = data["disponibilites"] as List;
//
//       final selectedSlot = await showDialog<Map<String, String>>(
//         context: context,
//         builder: (context) => SimpleDialog(
//           title: Text("Choisir une heure"),
//           children: slots.map((slot) {
//             final debut = slot["debut"];
//             final fin = slot["fin"];
//             return SimpleDialogOption(
//               child: Text("$debut - $fin"),
//               onPressed: () => Navigator.pop(context, {
//                 "debut": debut.toString(),
//                 "fin": fin.toString(),
//               }),
//             );
//           }).toList(),
//         ),
//       );
//
//       if (selectedSlot != null) {
//         final debut = selectedSlot["debut"];
//         final dateTime = DateTime.parse("${dateStr}T$debut:00");
//         setState(() {
//           selectedDateTime = dateTime;
//         });
//       }
//     }
//   }




  // Future<void> _pickDateTime() async {
  //   final cartProvider = Provider.of<CartProvider>(context, listen: false);
  //   final now = DateTime.now();
  //   final endDate = now.add(Duration(days: 14));
  //
  //   final joursDispo = await _getJoursDispos(now, endDate);
  //
  //   if (joursDispo.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Aucune date disponible pour cette coiffeuse.")),
  //     );
  //     return;
  //   }
  //
  //   // 💡 Choisir la première date dispo comme initialDate valide
  //   final initialDate = joursDispo.first;
  //
  //   final pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: initialDate,
  //     firstDate: now,
  //     lastDate: endDate,
  //     selectableDayPredicate: (day) {
  //       return joursDispo.any((d) =>
  //       d.year == day.year && d.month == day.month && d.day == day.day);
  //     },
  //   );
  //
  //   if (pickedDate == null) return;
  //
  //   final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
  //   final coiffeuseId = cartProvider.coiffeuseId;
  //   final duree = cartProvider.totalDuration;
  //
  //   final response = await http.get(Uri.parse(
  //     "https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree",
  //   ));
  //
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     final slots = data["disponibilites"] as List;
  //
  //     final selectedSlot = await showDialog<Map<String, String>>(
  //       context: context,
  //       builder: (context) => SimpleDialog(
  //         title: Text("Choisir une heure"),
  //         children: slots.map((slot) {
  //           final debut = slot["debut"];
  //           final fin = slot["fin"];
  //           return SimpleDialogOption(
  //             child: Text("$debut - $fin"),
  //             onPressed: () => Navigator.pop(context, {
  //               "debut": debut.toString(),
  //               "fin": fin.toString(),
  //             }),
  //           );
  //         }).toList(),
  //       ),
  //     );
  //
  //     if (selectedSlot != null) {
  //       final debut = selectedSlot["debut"];
  //       final dateTime = DateTime.parse("${dateStr}T$debut:00");
  //       setState(() {
  //         selectedDateTime = dateTime;
  //       });
  //     }
  //   }
  // }


//   Future<void> _confirmRdv() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     if (currentUserId == null ||
//         selectedDateTime == null ||
//         selectedPaymentMethod == null ||
//         cartProvider.cartItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez remplir tous les champs et sélectionner des services.")),
//       );
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final success = await cartProvider.envoyerReservation(
//         userId: currentUserId!,
//         dateHeure: selectedDateTime!,
//         methodePaiement: selectedPaymentMethod!,
//       );
//
//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
//         );
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la confirmation du RDV.")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: Text("🗓️ Confirmation RDV"), backgroundColor: Colors.orange),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("💼 Services sélectionnés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Expanded(
//               child: cartProvider.cartItems.isEmpty
//                   ? const Center(child: Text("Aucun service sélectionné."))
//                   : ListView.builder(
//                 itemCount: cartProvider.cartItems.length,
//                 itemBuilder: (context, index) {
//                   final service = cartProvider.cartItems[index];
//                   return ListTile(
//                     leading: Icon(Icons.miscellaneous_services, color: Colors.orange),
//                     title: Text(service.intitule),
//                     subtitle: Text("💰 ${service.prixFinal} € | ⏳ ${service.temps} min"),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 10),
//             ListTile(
//               title: Text(selectedDateTime == null
//                   ? "📅 Sélectionner un créneau"
//                   : "📅 RDV le ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime!)}"),
//               trailing: Icon(Icons.calendar_today),
//               onTap: _pickDateTime,
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               decoration: InputDecoration(labelText: "Méthode de paiement"),
//               items: paymentMethods.map((methode) {
//                 return DropdownMenuItem<String>(
//                   value: methode.toLowerCase(),
//                   child: Text(methode),
//                 );
//               }).toList(),
//               onChanged: (value) => setState(() => selectedPaymentMethod = value),
//             ),
//             const SizedBox(height: 20),
//             isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : ElevatedButton.icon(
//               icon: Icon(Icons.check),
//               label: Text("Confirmer le RDV"),
//               onPressed: _confirmRdv,
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             ),
//           ],
//         ),
//       ),
//     );
//
//   }
// }












// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
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
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//   }
//
//   Future<List<DateTime>> _getJoursDispos(DateTime start, DateTime end) async {
//     final coiffeuseId = Provider.of<CartProvider>(context, listen: false).coiffeuseId;
//     final duree = Provider.of<CartProvider>(context, listen: false).totalDuration;
//     List<DateTime> joursOK = [];
//
//     for (int i = 0; i <= end.difference(start).inDays; i++) {
//       final date = start.add(Duration(days: i));
//       final dateStr = DateFormat('yyyy-MM-dd').format(date);
//
//       final response = await http.get(Uri.parse(
//         "https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree",
//       ));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if ((data['disponibilites'] as List).isNotEmpty) {
//           joursOK.add(date);
//         }
//       }
//     }
//     return joursOK;
//   }
//
//   Future<void> _pickDateTime() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final now = DateTime.now();
//     final endDate = now.add(Duration(days: 14));
//     final joursDispo = await _getJoursDispos(now, endDate);
//
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: now,
//       lastDate: endDate,
//       selectableDayPredicate: (day) {
//         return joursDispo.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);
//       },
//     );
//
//     if (pickedDate == null) return;
//
//     final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
//     final coiffeuseId = cartProvider.coiffeuseId;
//     final duree = cartProvider.totalDuration;
//
//     final response = await http.get(Uri.parse(
//       "https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree",
//     ));
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final slots = data["disponibilites"] as List;
//
//       final selectedSlot = await showDialog<Map<String, String>>(
//         context: context,
//         builder: (context) => SimpleDialog(
//           title: Text("Choisir une heure"),
//           children: slots.map((slot) {
//             final debut = slot["debut"];
//             final fin = slot["fin"];
//             return SimpleDialogOption(
//               child: Text("$debut - $fin"),
//               onPressed: () => Navigator.pop(context, {
//                 "debut": debut.toString(),
//                 "fin": fin.toString(),
//               }),
//             );
//           }).toList(),
//         ),
//       );
//
//
//       if (selectedSlot != null) {
//         final debut = selectedSlot["debut"];
//         final dateTime = DateTime.parse("${dateStr}T$debut:00");
//         setState(() {
//           selectedDateTime = dateTime;
//         });
//       }
//     }
//   }
//
//   Future<void> _confirmRdv() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     if (currentUserId == null ||
//         selectedDateTime == null ||
//         selectedPaymentMethod == null ||
//         cartProvider.cartItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez remplir tous les champs et sélectionner des services.")),
//       );
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/'),
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "user_id": currentUserId,
//           "coiffeuse_id": cartProvider.coiffeuseId,
//           "date_heure": selectedDateTime!.toIso8601String(),
//           "services": cartProvider.cartItems.map((s) => s.id).toList(),
//           "methode_paiement": selectedPaymentMethod,
//           "total_price": cartProvider.totalPrice,
//           "total_duration": cartProvider.totalDuration,
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
//         );
//         cartProvider.clearCart();
//         Navigator.pop(context);
//       } else {
//         final errorData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : ${errorData['message'] ?? 'Créneau non disponible'}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: Text("🗓️ Confirmation RDV"), backgroundColor: Colors.orange),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("💼 Services sélectionnés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Expanded(
//               child: cartProvider.cartItems.isEmpty
//                   ? const Center(child: Text("Aucun service sélectionné."))
//                   : ListView.builder(
//                 itemCount: cartProvider.cartItems.length,
//                 itemBuilder: (context, index) {
//                   final service = cartProvider.cartItems[index];
//                   return ListTile(
//                     leading: Icon(Icons.miscellaneous_services, color: Colors.orange),
//                     title: Text(service.intitule),
//                     subtitle: Text("💰 ${service.prixFinal} € | ⏳ ${service.temps} min"),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 10),
//             ListTile(
//               title: Text(selectedDateTime == null
//                   ? "📅 Sélectionner un créneau"
//                   : "📅 RDV le ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime!)}"),
//               trailing: Icon(Icons.calendar_today),
//               onTap: _pickDateTime,
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               decoration: InputDecoration(labelText: "Méthode de paiement"),
//               items: paymentMethods.map((methode) {
//                 return DropdownMenuItem<String>(
//                   value: methode.toLowerCase(),
//                   child: Text(methode),
//                 );
//               }).toList(),
//               onChanged: (value) => setState(() => selectedPaymentMethod = value),
//             ),
//             const SizedBox(height: 20),
//             isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : ElevatedButton.icon(
//               icon: Icon(Icons.check),
//               label: Text("Confirmer le RDV"),
//               onPressed: _confirmRdv,
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
//
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
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//   }
//
//   /// 📆 Choisir une date puis un créneau disponible
//   Future<void> _pickDateTime() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 14)),
//     );
//
//     if (pickedDate == null) return;
//
//     final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
//     final coiffeuseId = cartProvider.coiffeuseId;
//     final duree = cartProvider.totalDuration;
//
//     try {
//       final response = await http.get(
//         Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree"),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final slots = data["disponibilites"] as List;
//
//         if (slots.isEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Aucun créneau disponible ce jour-là.")),
//           );
//           return;
//         }
//
//         final selectedSlot = await showDialog<Map<String, String>>(
//           context: context,
//           builder: (context) => SimpleDialog(
//             title: Text("Choisir une heure"),
//             children: slots.map((slot) {
//               final debut = slot["debut"];
//               final fin = slot["fin"];
//               return SimpleDialogOption(
//                 child: Text("$debut - $fin"),
//                 onPressed: () => Navigator.pop(context, slot),
//               );
//             }).toList(),
//           ),
//         );
//
//         if (selectedSlot != null) {
//           final debut = selectedSlot["debut"];
//           final dateTime = DateTime.parse("${dateStr}T$debut:00");
//           setState(() {
//             selectedDateTime = dateTime;
//           });
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors du chargement des créneaux.")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     }
//   }
//
//   /// 📡 Envoie la demande de création de RDV
//   Future<void> _confirmRdv() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     if (currentUserId == null ||
//         selectedDateTime == null ||
//         selectedPaymentMethod == null ||
//         cartProvider.cartItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez remplir tous les champs et sélectionner des services.")),
//       );
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/'),
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "user_id": currentUserId,
//           "coiffeuse_id": cartProvider.coiffeuseId,
//           "date_heure": selectedDateTime!.toIso8601String(),
//           "services": cartProvider.cartItems.map((service) => service.id).toList(),
//           "methode_paiement": selectedPaymentMethod,
//           "total_price": cartProvider.totalPrice,
//           "total_duration": cartProvider.totalDuration,
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
//         );
//         cartProvider.clearCart();
//         Navigator.pop(context);
//       } else {
//         final errorData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : ${errorData['message'] ?? 'Créneau non disponible'}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final formattedDate = selectedDateTime != null
//         ? DateFormat('EEEE d MMMM - HH:mm', 'fr_FR').format(selectedDateTime!)
//         : "Aucun créneau sélectionné";
//
//     return Scaffold(
//       appBar: AppBar(title: Text("Confirmation RDV"), backgroundColor: Colors.orange),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ElevatedButton.icon(
//               onPressed: _pickDateTime,
//               icon: Icon(Icons.calendar_month),
//               label: Text("Choisir un créneau"),
//             ),
//             SizedBox(height: 10),
//             Text("🗓️ Créneau : $formattedDate"),
//
//             SizedBox(height: 20),
//             DropdownButtonFormField<String>(
//               decoration: InputDecoration(labelText: "Méthode de paiement"),
//               items: paymentMethods.map((methode) {
//                 return DropdownMenuItem<String>(
//                   value: methode.toLowerCase(),
//                   child: Text(methode),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedPaymentMethod = value;
//                 });
//               },
//             ),
//
//             SizedBox(height: 30),
//
//             isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : Center(
//               child: ElevatedButton.icon(
//                 icon: Icon(Icons.check),
//                 label: Text("Confirmer le RDV"),
//                 onPressed: _confirmRdv,
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import '../../services/providers/cart_provider.dart';
// // import '../../services/providers/current_user_provider.dart';
// //
// // class ConfirmRdvPage extends StatefulWidget {
// //   @override
// //   _ConfirmRdvPageState createState() => _ConfirmRdvPageState();
// // }
// //
// // class _ConfirmRdvPageState extends State<ConfirmRdvPage> {
// //   bool isLoading = false;
// //   String? currentUserId;
// //   DateTime? selectedDateTime;
// //   String? selectedPaymentMethod;
// //
// //   final List<String> paymentMethods = ["Carte", "Cash", "PayPal"];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchCurrentUser();
// //   }
// //
// //   /// **📌 Récupérer l'ID utilisateur**
// //   void _fetchCurrentUser() {
// //     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// //     setState(() {
// //       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
// //     });
// //   }
// //
// //   /// **📆 Sélectionner la date et l'heure du RDV**
// //   Future<void> _pickDateTime() async {
// //     DateTime? pickedDate = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime.now(),
// //       lastDate: DateTime.now().add(const Duration(days: 60)),
// //     );
// //
// //     if (pickedDate != null) {
// //       TimeOfDay? pickedTime = await showTimePicker(
// //         context: context,
// //         initialTime: TimeOfDay.now(),
// //       );
// //
// //       if (pickedTime != null) {
// //         setState(() {
// //           selectedDateTime = DateTime(
// //             pickedDate.year,
// //             pickedDate.month,
// //             pickedDate.day,
// //             pickedTime.hour,
// //             pickedTime.minute,
// //           );
// //         });
// //       }
// //     }
// //   }
// //
// //   /// **📡 Envoyer la requête pour valider le RDV**
// //   Future<void> _confirmRdv() async {
// //     final cartProvider = Provider.of<CartProvider>(context, listen: false);
// //
// //     if (currentUserId == null || selectedDateTime == null || selectedPaymentMethod == null || cartProvider.cartItems.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Veuillez remplir tous les champs et sélectionner des services.")),
// //       );
// //       return;
// //     }
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/'),
// //         headers: {"Content-Type": "application/json"},
// //         body: json.encode({
// //           "user_id": currentUserId,
// //           "coiffeuse_id": cartProvider.coiffeuseId,  // ✅ ID de la coiffeuse récupéré du panier
// //           "date_heure": selectedDateTime!.toIso8601String(),
// //           "services": cartProvider.cartItems.map((service) => service.id).toList(),
// //           "methode_paiement": selectedPaymentMethod,
// //           "total_price": cartProvider.totalPrice,  // ✅ Envoyer le prix total
// //           "total_duration": cartProvider.totalDuration, // ✅ Envoyer la durée totale
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
// //         );
// //
// //         // ✅ Vider le panier après validation
// //         cartProvider.clearCart();
// //
// //         Navigator.pop(context); // Retour à la page précédente
// //       } else {
// //         final errorData = json.decode(response.body);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Erreur : ${errorData['message']}")),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// //       );
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //
// //
// //   // Future<void> _confirmRdv() async {
// //   //   if (currentUserId == null || selectedDateTime == null || selectedPaymentMethod == null) {
// //   //     ScaffoldMessenger.of(context).showSnackBar(
// //   //       const SnackBar(content: Text("Veuillez remplir tous les champs.")),
// //   //     );
// //   //     return;
// //   //   }
// //   //
// //   //   setState(() {
// //   //     isLoading = true;
// //   //   });
// //   //
// //   //   try {
// //   //     final response = await http.post(
// //   //       Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/'),
// //   //       headers: {"Content-Type": "application/json"},
// //   //       body: json.encode({
// //   //         "user_id": currentUserId,
// //   //         "date_heure": selectedDateTime!.toIso8601String(),
// //   //         "methode_paiement": selectedPaymentMethod
// //   //       }),
// //   //     );
// //   //
// //   //     if (response.statusCode == 201) {
// //   //       ScaffoldMessenger.of(context).showSnackBar(
// //   //         const SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
// //   //       );
// //   //
// //   //       // ✅ Vider le panier après validation
// //   //       Provider.of<CartProvider>(context, listen: false).clearCart();
// //   //
// //   //       Navigator.pop(context); // Retour à la page précédente
// //   //     } else {
// //   //       final errorData = json.decode(response.body);
// //   //       ScaffoldMessenger.of(context).showSnackBar(
// //   //         SnackBar(content: Text("Erreur : ${errorData['message']}")),
// //   //       );
// //   //     }
// //   //   } catch (e) {
// //   //     ScaffoldMessenger.of(context).showSnackBar(
// //   //       const SnackBar(content: Text("Erreur de connexion au serveur.")),
// //   //     );
// //   //   } finally {
// //   //     setState(() {
// //   //       isLoading = false;
// //   //     });
// //   //   }
// //   // }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final cartProvider = Provider.of<CartProvider>(context);
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("📅 Validation du RDV"),
// //         backgroundColor: Colors.orange,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text("🛒 Services sélectionnés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //             const SizedBox(height: 10),
// //
// //             Expanded(
// //               child: cartProvider.cartItems.isEmpty
// //                   ? const Center(child: Text("Aucun service sélectionné 😔"))
// //                   : ListView.builder(
// //                 itemCount: cartProvider.cartItems.length,
// //                 itemBuilder: (context, index) {
// //                   final service = cartProvider.cartItems[index];
// //
// //                   return Card(
// //                     elevation: 3,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     child: ListTile(
// //                       leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
// //                       title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
// //                       subtitle: Text("💰 ${service.prixFinal} € | ⏳ ${service.temps} min"),
// //                       trailing: IconButton(
// //                         icon: const Icon(Icons.delete, color: Colors.red),
// //                         onPressed: () {
// //                           Provider.of<CartProvider>(context, listen: false).removeFromCart(service,currentUserId!);
// //                           ScaffoldMessenger.of(context).showSnackBar(
// //                             SnackBar(content: Text("${service.intitule} supprimé du panier ❌")),
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //
// //             const SizedBox(height: 20),
// //
// //             // 📆 Sélection de la date et heure du RDV
// //             ListTile(
// //               title: Text(
// //                 selectedDateTime == null
// //                     ? "📆 Sélectionner une date et heure"
// //                     : "📆 RDV le ${selectedDateTime!.day}/${selectedDateTime!.month} à ${selectedDateTime!.hour}:${selectedDateTime!.minute}",
// //               ),
// //               trailing: const Icon(Icons.calendar_today, color: Colors.blue),
// //               onTap: _pickDateTime,
// //             ),
// //             const SizedBox(height: 20),
// //
// //             // 💳 Choix du mode de paiement
// //             const Text("💳 Méthode de paiement :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //             DropdownButtonFormField<String>(
// //               value: selectedPaymentMethod,
// //               items: paymentMethods.map((method) {
// //                 return DropdownMenuItem(
// //                   value: method.toLowerCase(),
// //                   child: Text(method),
// //                 );
// //               }).toList(),
// //               onChanged: (value) {
// //                 setState(() {
// //                   selectedPaymentMethod = value;
// //                 });
// //               },
// //               decoration: const InputDecoration(border: OutlineInputBorder()),
// //             ),
// //             const SizedBox(height: 20),
// //
// //             // 🔥 Bouton pour valider le RDV
// //             isLoading
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : ElevatedButton.icon(
// //               onPressed: _confirmRdv,
// //               icon: const Icon(Icons.check_circle, color: Colors.white),
// //               label: const Text("Confirmer le RDV"),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.green,
// //                 padding: const EdgeInsets.symmetric(vertical: 15),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import '../../services/providers/cart_provider.dart';
// // // import '../../services/providers/current_user_provider.dart';
// // //
// // // class ConfirmRdvPage extends StatefulWidget {
// // //   @override
// // //   _ConfirmRdvPageState createState() => _ConfirmRdvPageState();
// // // }
// // //
// // // class _ConfirmRdvPageState extends State<ConfirmRdvPage> {
// // //   bool isLoading = false;
// // //   String? currentUserId;
// // //   DateTime? selectedDateTime;
// // //   String? selectedPaymentMethod;
// // //
// // //   final List<String> paymentMethods = ["Carte", "Cash", "PayPal"];
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchCurrentUser();
// // //   }
// // //
// // //   /// **📌 Récupérer l'ID utilisateur**
// // //   void _fetchCurrentUser() {
// // //     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // //     setState(() {
// // //       currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
// // //     });
// // //   }
// // //
// // //   /// **📆 Sélectionner la date et l'heure du RDV**
// // //   Future<void> _pickDateTime() async {
// // //     DateTime? pickedDate = await showDatePicker(
// // //       context: context,
// // //       initialDate: DateTime.now(),
// // //       firstDate: DateTime.now(),
// // //       lastDate: DateTime.now().add(const Duration(days: 60)),
// // //     );
// // //
// // //     if (pickedDate != null) {
// // //       TimeOfDay? pickedTime = await showTimePicker(
// // //         context: context,
// // //         initialTime: TimeOfDay.now(),
// // //       );
// // //
// // //       if (pickedTime != null) {
// // //         setState(() {
// // //           selectedDateTime = DateTime(
// // //             pickedDate.year,
// // //             pickedDate.month,
// // //             pickedDate.day,
// // //             pickedTime.hour,
// // //             pickedTime.minute,
// // //           );
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   /// **📡 Envoyer la requête pour valider le RDV**
// // //   Future<void> _confirmRdv() async {
// // //     if (currentUserId == null || selectedDateTime == null || selectedPaymentMethod == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text("Veuillez remplir tous les champs.")),
// // //       );
// // //       return;
// // //     }
// // //
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('https://www.hairbnb.site/api/confirm_rendez_vous/'),
// // //         headers: {"Content-Type": "application/json"},
// // //         body: json.encode({
// // //           "user_id": currentUserId,
// // //           "date_heure": selectedDateTime!.toIso8601String(),
// // //           "methode_paiement": selectedPaymentMethod
// // //         }),
// // //       );
// // //
// // //       if (response.statusCode == 201) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text("Rendez-vous confirmé avec succès ! 🎉")),
// // //         );
// // //
// // //         // ✅ Vider le panier après validation
// // //         Provider.of<CartProvider>(context, listen: false).clearCart();
// // //
// // //         Navigator.pop(context); // Retour à la page précédente
// // //       } else {
// // //         final errorData = json.decode(response.body);
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(content: Text("Erreur : ${errorData['message']}")),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // //       );
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final cartProvider = Provider.of<CartProvider>(context);
// // //
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("📅 Validation du RDV"),
// // //         backgroundColor: Colors.orange,
// // //       ),
// // //       body: Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             const Text("🛒 Services sélectionnés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // //             const SizedBox(height: 10),
// // //             Expanded(
// // //               child: cartProvider.cartItems.isEmpty
// // //                   ? const Center(child: Text("Aucun service sélectionné 😔"))
// // //                   : ListView.builder(
// // //                 itemCount: cartProvider.cartItems.length,
// // //                 itemBuilder: (context, index) {
// // //                   final service = cartProvider.cartItems[index];
// // //                   return ListTile(
// // //                     leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
// // //                     title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold)),
// // //                     subtitle: Text("💰 ${service.prixFinal} € | ⏳ ${service.temps} min"),
// // //                   );
// // //                 },
// // //               ),
// // //             ),
// // //             const SizedBox(height: 20),
// // //
// // //             // 📆 Sélection de la date et heure du RDV
// // //             ListTile(
// // //               title: Text(selectedDateTime == null
// // //                   ? "📆 Sélectionner une date et heure"
// // //                   : "📆 RDV le ${selectedDateTime!.day}/${selectedDateTime!.month} à ${selectedDateTime!.hour}:${selectedDateTime!.minute}"),
// // //               trailing: const Icon(Icons.calendar_today, color: Colors.blue),
// // //               onTap: _pickDateTime,
// // //             ),
// // //             const SizedBox(height: 20),
// // //
// // //             // 💳 Choix du mode de paiement
// // //             const Text("💳 Méthode de paiement :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // //             DropdownButtonFormField<String>(
// // //               value: selectedPaymentMethod,
// // //               items: paymentMethods.map((method) {
// // //                 return DropdownMenuItem(
// // //                   value: method.toLowerCase(),
// // //                   child: Text(method),
// // //                 );
// // //               }).toList(),
// // //               onChanged: (value) {
// // //                 setState(() {
// // //                   selectedPaymentMethod = value;
// // //                 });
// // //               },
// // //               decoration: const InputDecoration(border: OutlineInputBorder()),
// // //             ),
// // //             const SizedBox(height: 20),
// // //
// // //             // 🔥 Bouton pour valider le RDV
// // //             isLoading
// // //                 ? const Center(child: CircularProgressIndicator())
// // //                 : ElevatedButton.icon(
// // //               onPressed: _confirmRdv,
// // //               icon: const Icon(Icons.check_circle, color: Colors.white),
// // //               label: const Text("Confirmer le RDV"),
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: Colors.green,
// // //                 padding: const EdgeInsets.symmetric(vertical: 15),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
