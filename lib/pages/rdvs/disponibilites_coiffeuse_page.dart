import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/my_drawer_service/hairbnb_scaffold.dart';
import '../../services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';

class DisponibilitesCoiffeusePage extends StatefulWidget {
  const DisponibilitesCoiffeusePage({super.key});

  @override
  _DisponibilitesCoiffeusePageState createState() => _DisponibilitesCoiffeusePageState();
}

class _DisponibilitesCoiffeusePageState extends State<DisponibilitesCoiffeusePage> {
  List<dynamic> disponibilites = [];
  bool isLoading = false;
  bool hasError = false;
  String? coiffeuseId;
  int _currentIndex = 2; // Index pour la bottom navigation bar (calendrier)

  DateTime selectedDate = DateTime.now();
  int selectedDuree = 30;
  final List<int> dureesDisponibles = [30, 45, 60];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    coiffeuseId = currentUserProvider.currentUser?.idTblUser.toString();
    if (coiffeuseId != null) {
      _fetchDisponibilites();
    }
  }

  Future<void> _fetchDisponibilites() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$date&duree=$selectedDuree'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          disponibilites = data['disponibilites'];
          isLoading = false;
        });
      } else {
        throw Exception("Erreur de chargement");
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 14)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // Couleur principale
              onPrimary: Colors.white, // Texte sur la couleur principale
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchDisponibilites();
    }
  }

  void _confirmerReservation(String debut, String fin) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final datetime = "${dateStr}T$debut:00"; // Format: 2025-03-26T08:00:00

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer ce créneau ?", style: TextStyle(color: Colors.orange)),
        content: Text("⏰ $debut - $fin le $dateStr\nDurée : $selectedDuree min"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // 🔥 Tu peux maintenant faire un appel POST pour réserver ici
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Créneau sélectionné : $datetime"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text("Réserver", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDate);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;

    return HairbnbScaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la page
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  "📆 Choisir un créneau",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),

              // Sélecteur date et durée
              isSmallScreen
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDureeSelector(),
                  const SizedBox(height: 12),
                  _buildDateSelector(formattedDate),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDureeSelector(),
                  _buildDateSelector(formattedDate),
                ],
              ),

              const SizedBox(height: 20),

              if (isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.orange))
              else if (hasError)
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _fetchDisponibilites,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Réessayer", style: TextStyle(color: Colors.white)),
                  ),
                )
              else if (disponibilites.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Aucune disponibilité trouvée pour cette date.",
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: disponibilites.length,
                      itemBuilder: (context, index) {
                        final slot = disponibilites[index];
                        final debut = slot['debut'];
                        final fin = slot['fin'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.access_time, color: Colors.orange),
                            ),
                            title: Text(
                              "🕒 $debut - $fin",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Durée: $selectedDuree min"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
                            onTap: () => _confirmerReservation(debut, fin),
                          ),
                        );
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Navigation à implémenter selon votre logique d'application
        },
      ),
    );
  }

  Widget _buildDureeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Durée :",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedDuree,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
            items: dureesDisponibles
                .map((duree) => DropdownMenuItem(
                value: duree,
                child: Text(
                  "$duree min",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )))
                .toList(),
            onChanged: (val) {
              setState(() => selectedDuree = val!);
              _fetchDisponibilites();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String formattedDate) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _selectDate,
      icon: const Icon(Icons.calendar_today, color: Colors.orange, size: 18),
      label: Text(
        formattedDate,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}





// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../../services/providers/current_user_provider.dart';
//
// class DisponibilitesCoiffeusePage extends StatefulWidget {
//   @override
//   _DisponibilitesCoiffeusePageState createState() => _DisponibilitesCoiffeusePageState();
// }
//
// class _DisponibilitesCoiffeusePageState extends State<DisponibilitesCoiffeusePage> {
//   List<dynamic> disponibilites = [];
//   bool isLoading = false;
//   bool hasError = false;
//   String? coiffeuseId;
//
//   DateTime selectedDate = DateTime.now();
//   int selectedDuree = 30;
//   final List<int> dureesDisponibles = [30, 45, 60];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     coiffeuseId = currentUserProvider.currentUser?.idTblUser.toString();
//     if (coiffeuseId != null) {
//       _fetchDisponibilites();
//     }
//   }
//
//   Future<void> _fetchDisponibilites() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     final String date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$date&duree=$selectedDuree'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           disponibilites = data['disponibilites'];
//           isLoading = false;
//         });
//       } else {
//         throw Exception("Erreur de chargement");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _selectDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 14)),
//     );
//
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _fetchDisponibilites();
//     }
//   }
//
//   void _confirmerReservation(String debut, String fin) {
//     final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
//     final datetime = "${dateStr}T$debut:00"; // Format: 2025-03-26T08:00:00
//
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text("Confirmer ce créneau ?"),
//         content: Text("⏰ $debut - $fin le $dateStr\nDurée : $selectedDuree min"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: Text("Annuler"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               // 🔥 Tu peux maintenant faire un appel POST pour réserver ici
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text("Créneau sélectionné : $datetime")),
//               );
//             },
//             child: Text("Réserver"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDate);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("📆 Choisir un créneau"), backgroundColor: Colors.orange),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Sélecteur date et durée
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Durée :"),
//                 DropdownButton<int>(
//                   value: selectedDuree,
//                   items: dureesDisponibles
//                       .map((duree) => DropdownMenuItem(value: duree, child: Text("$duree min")))
//                       .toList(),
//                   onChanged: (val) {
//                     setState(() => selectedDuree = val!);
//                     _fetchDisponibilites();
//                   },
//                 ),
//                 TextButton.icon(
//                   onPressed: _selectDate,
//                   icon: Icon(Icons.calendar_today),
//                   label: Text(formattedDate),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 16),
//
//             if (isLoading)
//               const Center(child: CircularProgressIndicator())
//             else if (hasError)
//               ElevatedButton(
//                 onPressed: _fetchDisponibilites,
//                 child: const Text("Réessayer"),
//               )
//             else if (disponibilites.isEmpty)
//                 const Text("Aucune disponibilité trouvée.")
//               else
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: disponibilites.length,
//                     itemBuilder: (context, index) {
//                       final slot = disponibilites[index];
//                       final debut = slot['debut'];
//                       final fin = slot['fin'];
//
//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
//                         child: ListTile(
//                           leading: const Icon(Icons.access_time, color: Colors.green),
//                           title: Text("🕒 $debut - $fin"),
//                           onTap: () => _confirmerReservation(debut, fin),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//           ],
//         ),
//       ),
//     );
//   }
// }















// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../../services/providers/current_user_provider.dart';
//
// class DisponibilitesCoiffeusePage extends StatefulWidget {
//   @override
//   _DisponibilitesCoiffeusePageState createState() => _DisponibilitesCoiffeusePageState();
// }
//
// class _DisponibilitesCoiffeusePageState extends State<DisponibilitesCoiffeusePage> {
//   List<dynamic> disponibilites = [];
//   bool isLoading = false;
//   bool hasError = false;
//   String? coiffeuseId;
//
//   DateTime selectedDate = DateTime.now();
//   int selectedDuree = 30;
//
//   final List<int> dureesDisponibles = [30, 45, 60];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     coiffeuseId = currentUserProvider.currentUser?.idTblUser.toString();
//     if (coiffeuseId != null) {
//       _fetchDisponibilites();
//     }
//   }
//
//   Future<void> _fetchDisponibilites() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     final String date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$date&duree=$selectedDuree'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           disponibilites = data['disponibilites'];
//           isLoading = false;
//         });
//       } else {
//         throw Exception("Erreur de chargement");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _selectDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 14)),
//     );
//
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _fetchDisponibilites();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDate);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("📆 Disponibilités"), backgroundColor: Colors.orange),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // ⏳ Sélecteur de durée
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Durée :"),
//                 DropdownButton<int>(
//                   value: selectedDuree,
//                   items: dureesDisponibles
//                       .map((duree) => DropdownMenuItem(value: duree, child: Text("$duree min")))
//                       .toList(),
//                   onChanged: (val) {
//                     setState(() {
//                       selectedDuree = val!;
//                     });
//                     _fetchDisponibilites();
//                   },
//                 ),
//                 TextButton.icon(
//                   onPressed: _selectDate,
//                   icon: Icon(Icons.calendar_today),
//                   label: Text(formattedDate),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 16),
//
//             if (isLoading)
//               const Center(child: CircularProgressIndicator())
//             else if (hasError)
//               ElevatedButton(
//                 onPressed: _fetchDisponibilites,
//                 child: const Text("Réessayer"),
//               )
//             else if (disponibilites.isEmpty)
//                 const Text("Aucune disponibilité trouvée.")
//               else
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: disponibilites.length,
//                     itemBuilder: (context, index) {
//                       final slot = disponibilites[index];
//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
//                         child: ListTile(
//                           leading: const Icon(Icons.access_time, color: Colors.green),
//                           title: Text("🕒 ${slot['debut']} - ${slot['fin']}"),
//                           onTap: () {
//                             // 👉 Tu pourras ici déclencher la réservation plus tard
//                             showDialog(
//                               context: context,
//                               builder: (ctx) => AlertDialog(
//                                 title: Text("Réserver ce créneau ?"),
//                                 content: Text("${slot['debut']} - ${slot['fin']} le $formattedDate"),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(ctx),
//                                     child: Text("Annuler"),
//                                   ),
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       // TODO: réserver ici
//                                       Navigator.pop(ctx);
//                                     },
//                                     child: Text("Réserver"),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 ),
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
// // import 'dart:convert';
// //
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';
// // import 'package:provider/provider.dart';
// //
// // import '../../services/providers/current_user_provider.dart';
// //
// // class DisponibilitesCoiffeusePage extends StatefulWidget {
// //   @override
// //   _DisponibilitesCoiffeusePageState createState() => _DisponibilitesCoiffeusePageState();
// // }
// //
// // class _DisponibilitesCoiffeusePageState extends State<DisponibilitesCoiffeusePage> {
// //   List<dynamic> disponibilites = [];
// //   bool isLoading = true;
// //   bool hasError = false;
// //   String? coiffeuseId;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchCurrentUser();
// //   }
// //
// //   void _fetchCurrentUser() {
// //     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// //     setState(() {
// //       coiffeuseId = currentUserProvider.currentUser?.idTblUser.toString();
// //     });
// //     if (coiffeuseId != null) {
// //       _fetchDisponibilites();
// //     }
// //   }
// //
// //   Future<void> _fetchDisponibilites() async {
// //     setState(() {
// //       isLoading = true;
// //       hasError = false;
// //     });
// //
// //     final String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
// //     final int duree = 30;
// //
// //     try {
// //       final response = await http.get(
// //         Uri.parse('https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$date&duree=$duree'),
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         setState(() {
// //           disponibilites = data['disponibilites'];
// //           isLoading = false;
// //         });
// //       } else {
// //         throw Exception("Erreur lors du chargement des disponibilités.");
// //       }
// //     } catch (e) {
// //       setState(() {
// //         hasError = true;
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("📆 Mes Disponibilités"), backgroundColor: Colors.orange),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : hasError
// //           ? Center(
// //         child: ElevatedButton(
// //           onPressed: _fetchDisponibilites,
// //           child: const Text("Réessayer"),
// //         ),
// //       )
// //           : disponibilites.isEmpty
// //           ? const Center(child: Text("Aucune disponibilité trouvée."))
// //           : ListView.builder(
// //         itemCount: disponibilites.length,
// //         itemBuilder: (context, index) {
// //           final slot = disponibilites[index];
// //           return Card(
// //             margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// //             child: ListTile(
// //               leading: const Icon(Icons.access_time, color: Colors.green),
// //               title: Text("🕒 ${slot['debut']} - ${slot['fin']}"),
// //             ),
// //           );
// //         },
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
// // // import 'dart:convert';
// // //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:provider/provider.dart';
// // //
// // // import '../../services/providers/current_user_provider.dart';
// // //
// // // /// **Page pour afficher les RDVs d'un client**
// // // class RdvClientPage extends StatefulWidget {
// // //   @override
// // //   _RdvClientPageState createState() => _RdvClientPageState();
// // // }
// // //
// // // class _RdvClientPageState extends State<RdvClientPage> {
// // //   List<dynamic> rdvs = [];
// // //   bool isLoading = true;
// // //   bool hasError = false;
// // //   String? clientId;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchCurrentUser();
// // //   }
// // //
// // //   void _fetchCurrentUser() {
// // //     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // //     setState(() {
// // //       clientId = currentUserProvider.currentUser?.idTblUser.toString();
// // //     });
// // //     if (clientId != null) {
// // //       _fetchRdvClient();
// // //     }
// // //   }
// // //
// // //   Future<void> _fetchRdvClient() async {
// // //     setState(() {
// // //       isLoading = true;
// // //       hasError = false;
// // //     });
// // //     try {
// // //       final response = await http.get(Uri.parse('https://www.hairbnb.site/api/get_rendez_vous_client/$clientId/'));
// // //       if (response.statusCode == 200) {
// // //         setState(() {
// // //           rdvs = json.decode(response.body)['rendez_vous'];
// // //           isLoading = false;
// // //         });
// // //       } else {
// // //         throw Exception("Erreur lors du chargement des RDVs.");
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         hasError = true;
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: const Text("📅 Mes RDVs"), backgroundColor: Colors.orange),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : hasError
// // //           ? Center(
// // //         child: ElevatedButton(
// // //           onPressed: _fetchRdvClient,
// // //           child: const Text("Réessayer"),
// // //         ),
// // //       )
// // //           : rdvs.isEmpty
// // //           ? const Center(child: Text("Aucun rendez-vous trouvé."))
// // //           : ListView.builder(
// // //         itemCount: rdvs.length,
// // //         itemBuilder: (context, index) {
// // //           final rdv = rdvs[index];
// // //           return Card(
// // //             margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
// // //             child: ListTile(
// // //               leading: const Icon(Icons.cut, color: Colors.purple),
// // //               title: Text("Coiffeuse: ${rdv['coiffeuse']['nom']} ${rdv['coiffeuse']['prenom']}",
// // //                   style: const TextStyle(fontWeight: FontWeight.bold)),
// // //               subtitle: Text("📅 ${rdv['date_heure']} - 💰 ${rdv['total_prix']}€ - ⏳ ${rdv['duree_totale']} min"),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }