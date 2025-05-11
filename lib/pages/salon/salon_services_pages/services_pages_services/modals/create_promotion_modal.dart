import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../../models/promotion_full.dart';

void showCreatePromotionModal({
  required BuildContext context,
  required int serviceId,
  required VoidCallback onPromoAdded,
}) {
  final TextEditingController discountController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  String? errorMessage;

  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color errorRed = Colors.red;
  final Color successGreen = Colors.green;

  Map<String, String?> errors = {
    'discount': null,
    'startDate': null,
    'endDate': null,
  };

  Map<String, bool> isValid = {
    'discount': false,
    'startDate': false,
    'endDate': false,
  };

  void validateFields(StateSetter setModalState) {
    final discountText = discountController.text.trim();
    final double? discount = double.tryParse(discountText);

    setModalState(() {
      errorMessage = null;

      if (discount == null || discount <= 0 || discount > 100) {
        errors['discount'] = "Pourcentage invalide (1-100%)";
        isValid['discount'] = false;
      } else {
        errors['discount'] = null;
        isValid['discount'] = true;
      }

      if (startDate == null) {
        errors['startDate'] = "Date de début requise";
        isValid['startDate'] = false;
      } else {
        errors['startDate'] = null;
        isValid['startDate'] = true;
      }

      if (endDate == null) {
        errors['endDate'] = "Date de fin requise";
        isValid['endDate'] = false;
      } else if (startDate != null && endDate!.isBefore(startDate!)) {
        errors['endDate'] = "Fin doit être après le début";
        isValid['endDate'] = false;
      } else {
        errors['endDate'] = null;
        isValid['endDate'] = true;
      }
    });
  }

  Future<void> submitPromotion(StateSetter setModalState,
      BuildContext innerContext) async {
    validateFields(setModalState);
    if (errors.values.any((e) => e != null)) return;

    // Créer la promotion avec les dates
    final startDateTime = DateTime(
        startDate!.year, startDate!.month, startDate!.day);
    final endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day);

    final promo = PromotionFull(
      id: 0,
      serviceId: serviceId,
      pourcentage: double.parse(discountController.text.trim()),
      dateDebut: startDateTime,
      dateFin: endDateTime,
    );

    setModalState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print("Envoi de la promotion: Service ID=${promo.serviceId}, "
          "Réduction=${promo.pourcentage}%, "
          "Début=${promo.dateDebut.toIso8601String().split('T')[0]}, "
          "Fin=${promo.dateFin.toIso8601String().split('T')[0]}");

      final response = await http.post(
        Uri.parse('https://www.hairbnb.site/api/create_promotion/$serviceId/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(promo.toJson()),
      );

      print("Réponse du serveur: Code ${response.statusCode}");
      print("Corps de la réponse: ${response.body}");

      if (response.statusCode == 201) {
        showDialog(
          context: innerContext,
          barrierDismissible: false,
          builder: (context) =>
              Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: successGreen, size: 60),
                      const SizedBox(height: 10),
                      const Text("Promotion ajoutée !",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
        );

        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(innerContext).pop();
          Navigator.of(innerContext).pop(true);
          onPromoAdded();
        });
      } else if (response.statusCode == 400) {
        // Gérer l'erreur 400 et extraire le message
        String errorText = "Impossible de créer la promotion.";
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          if (errorData.containsKey('error')) {
            errorText = errorData['error'];
          }
        } catch (_) {}

        setModalState(() {
          errorMessage = errorText;
          isLoading = false;
        });
      } else {
        setModalState(() {
          errorMessage = "Erreur: ${response.body}";
          isLoading = false;
        });
      }
    } catch (e) {
      setModalState(() {
        errorMessage = "Erreur de connexion: $e";
        isLoading = false;
      });
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        StatefulBuilder(
          builder: (context, setModalState) =>
              Builder(
                builder: (innerContext) =>
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      padding: MediaQuery
                          .of(innerContext)
                          .viewInsets + const EdgeInsets.all(10),
                      child: DraggableScrollableSheet(
                        initialChildSize: 0.75,
                        maxChildSize: 0.95,
                        minChildSize: 0.5,
                        expand: false,
                        builder: (context, scrollController) =>
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF7F7F9),
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24)),
                              ),
                              child: ListView(
                                controller: scrollController,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const Text("Ajouter une promotion",
                                      style: TextStyle(
                                          fontSize: 24, fontWeight: FontWeight
                                          .w700)),
                                  const SizedBox(height: 30),
                                  TextField(
                                    controller: discountController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) =>
                                        validateFields(setModalState),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'[0-9]')),
                                    ],
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                          Icons.percent, color: primaryViolet),
                                      labelText: "Pourcentage de réduction",
                                      errorText: errors['discount'],
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              14)),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ListTile(
                                    title: Text(startDate == null
                                        ? "Choisir une date de début"
                                        : "Début : ${startDate!
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0]}"),
                                    trailing: Icon(Icons.calendar_today,
                                        color: primaryViolet),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: innerContext,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                            const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setModalState(() => startDate = picked);
                                        validateFields(setModalState);
                                      }
                                    },
                                    subtitle: errors['startDate'] != null
                                        ? Text(
                                        errors['startDate']!, style: TextStyle(
                                        color: errorRed, fontSize: 12))
                                        : null,
                                  ),
                                  ListTile(
                                    title: Text(endDate == null
                                        ? "Choisir une date de fin"
                                        : "Fin : ${endDate!
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0]}"),
                                    trailing: Icon(Icons.calendar_today,
                                        color: primaryViolet),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: innerContext,
                                        initialDate: startDate ??
                                            DateTime.now(),
                                        firstDate: startDate ?? DateTime.now(),
                                        lastDate: DateTime.now().add(
                                            const Duration(days: 730)),
                                      );
                                      if (picked != null) {
                                        setModalState(() => endDate = picked);
                                        validateFields(setModalState);
                                      }
                                    },
                                    subtitle: errors['endDate'] != null
                                        ? Text(
                                        errors['endDate']!, style: TextStyle(
                                        color: errorRed, fontSize: 12))
                                        : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // Afficher le message d'erreur s'il y en a un
                                  if (errorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: errorRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: errorRed),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: errorRed),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              errorMessage!,
                                              style: TextStyle(color: errorRed),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : () =>
                                          submitPromotion(
                                              setModalState, innerContext),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryViolet,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                14)),
                                      ),
                                      child: isLoading
                                          ? const CircularProgressIndicator(
                                          color: Colors.white)
                                          : const Text("Créer la promotion",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
              ),
        ),
  );
}






// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../../../../../models/promotion.dart';
//
// void showCreatePromotionModal({
//   required BuildContext context,
//   required int serviceId,
//   required VoidCallback onPromoAdded,
// }) {
//   final TextEditingController discountController = TextEditingController();
//   DateTime? startDate;
//   DateTime? endDate;
//   bool isLoading = false;
//   String? errorMessage; // Ajout d'une variable pour stocker le message d'erreur
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color errorRed = Colors.red;
//   final Color successGreen = Colors.green;
//
//   Map<String, String?> errors = {
//     'discount': null,
//     'startDate': null,
//     'endDate': null,
//   };
//
//   Map<String, bool> isValid = {
//     'discount': false,
//     'startDate': false,
//     'endDate': false,
//   };
//
//   void validateFields(StateSetter setModalState) {
//     final discountText = discountController.text.trim();
//     final double? discount = double.tryParse(discountText);
//
//     setModalState(() {
//       errorMessage = null; // Réinitialiser le message d'erreur
//
//       if (discount == null || discount <= 0 || discount > 100) {
//         errors['discount'] = "Pourcentage invalide (1-100%)";
//         isValid['discount'] = false;
//       } else {
//         errors['discount'] = null;
//         isValid['discount'] = true;
//       }
//
//       if (startDate == null) {
//         errors['startDate'] = "Date de début requise";
//         isValid['startDate'] = false;
//       } else {
//         errors['startDate'] = null;
//         isValid['startDate'] = true;
//       }
//
//       if (endDate == null) {
//         errors['endDate'] = "Date de fin requise";
//         isValid['endDate'] = false;
//       } else if (startDate != null && endDate!.isBefore(startDate!)) {
//         errors['endDate'] = "Fin doit être après le début";
//         isValid['endDate'] = false;
//       } else {
//         errors['endDate'] = null;
//         isValid['endDate'] = true;
//       }
//     });
//   }
//
//   Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
//     validateFields(setModalState);
//     if (errors.values.any((e) => e != null)) return;
//
//     // Créer les dates avec uniquement l'année, mois, jour (sans l'heure)
//     final DateTime startDateTime = DateTime(startDate!.year, startDate!.month, startDate!.day);
//     final DateTime endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day);
//
//     final promo = Promotion(
//       id: 0,
//       serviceId: serviceId,
//       pourcentage: double.parse(discountController.text.trim()),
//       dateDebut: startDateTime,
//       dateFin: endDateTime,
//     );
//
//     setModalState(() {
//       isLoading = true;
//       errorMessage = null; // Réinitialiser le message d'erreur avant la requête
//     });
//
//     try {
//       print("Envoi de promo: Début=${promo.dateDebut.toIso8601String().split('T')[0]}, "
//           "Fin=${promo.dateFin.toIso8601String().split('T')[0]}");
//
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/create_promotion/$serviceId/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(promo.toJson()),
//       );
//
//       if (response.statusCode == 201) {
//         showDialog(
//           context: innerContext,
//           barrierDismissible: false,
//           builder: (context) => Dialog(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             child: Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.check_circle, color: successGreen, size: 60),
//                   const SizedBox(height: 10),
//                   const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ),
//           ),
//         );
//
//         Future.delayed(const Duration(milliseconds: 1500), () {
//           Navigator.of(innerContext).pop();
//           Navigator.of(innerContext).pop(true);
//           onPromoAdded();
//         });
//       } else if (response.statusCode == 400) {
//         // Gérer spécifiquement l'erreur 400 et l'afficher dans le modal
//         String errorText = "Impossible de créer la promotion.";
//         try {
//           final errorData = json.decode(utf8.decode(response.bodyBytes));
//           if (errorData.containsKey('error')) {
//             errorText = errorData['error'];
//           }
//         } catch (_) {}
//
//         setModalState(() {
//           errorMessage = errorText; // Définir le message d'erreur pour l'afficher dans le modal
//           isLoading = false;
//         });
//       } else {
//         setModalState(() {
//           errorMessage = "Erreur: ${response.body}";
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setModalState(() {
//         errorMessage = "Erreur de connexion: $e";
//         isLoading = false;
//       });
//     }
//   }
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) => Builder(
//         builder: (innerContext) => AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             initialChildSize: 0.75,
//             maxChildSize: 0.95,
//             minChildSize: 0.5,
//             expand: false,
//             builder: (context, scrollController) => Container(
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Color(0xFFF7F7F9),
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               child: ListView(
//                 controller: scrollController,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   const Text("Ajouter une promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
//                   const SizedBox(height: 30),
//                   TextField(
//                     controller: discountController,
//                     keyboardType: TextInputType.number,
//                     onChanged: (_) => validateFields(setModalState),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
//                     ],
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.percent, color: primaryViolet),
//                       labelText: "Pourcentage de réduction",
//                       errorText: errors['discount'],
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ListTile(
//                     title: Text(startDate == null
//                         ? "Choisir une date de début"
//                         : "Début : ${startDate!.toLocal().toString().split(' ')[0]}"),
//                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: innerContext,
//                         initialDate: DateTime.now(),
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime.now().add(const Duration(days: 365)),
//                       );
//                       if (picked != null) {
//                         setModalState(() => startDate = picked);
//                         validateFields(setModalState);
//                       }
//                     },
//                     subtitle: errors['startDate'] != null
//                         ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
//                         : null,
//                   ),
//                   ListTile(
//                     title: Text(endDate == null
//                         ? "Choisir une date de fin"
//                         : "Fin : ${endDate!.toLocal().toString().split(' ')[0]}"),
//                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: innerContext,
//                         initialDate: startDate ?? DateTime.now(),
//                         firstDate: startDate ?? DateTime.now(),
//                         lastDate: DateTime.now().add(const Duration(days: 730)),
//                       );
//                       if (picked != null) {
//                         setModalState(() => endDate = picked);
//                         validateFields(setModalState);
//                       }
//                     },
//                     subtitle: errors['endDate'] != null
//                         ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
//                         : null,
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Afficher le message d'erreur dans le modal
//                   if (errorMessage != null)
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: errorRed.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: errorRed),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.error_outline, color: errorRed),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               errorMessage!,
//                               style: TextStyle(color: errorRed),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                   const SizedBox(height: 20),
//
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryViolet,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                       ),
//                       child: isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // import '../../../../../models/promotion.dart';
// //
// // void showCreatePromotionModal({
// //   required BuildContext context,
// //   required int serviceId,
// //   required VoidCallback onPromoAdded,
// // }) {
// //   final TextEditingController discountController = TextEditingController();
// //   DateTime? startDate;
// //   DateTime? endDate;
// //   bool isLoading = false;
// //
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //   final Color errorRed = Colors.red;
// //   final Color successGreen = Colors.green;
// //
// //   Map<String, String?> errors = {
// //     'discount': null,
// //     'startDate': null,
// //     'endDate': null,
// //   };
// //
// //   Map<String, bool> isValid = {
// //     'discount': false,
// //     'startDate': false,
// //     'endDate': false,
// //   };
// //
// //   void validateFields(StateSetter setModalState) {
// //     final discountText = discountController.text.trim();
// //     final double? discount = double.tryParse(discountText);
// //
// //     setModalState(() {
// //       if (discount == null || discount <= 0 || discount > 100) {
// //         errors['discount'] = "Pourcentage invalide (1-100%)";
// //         isValid['discount'] = false;
// //       } else {
// //         errors['discount'] = null;
// //         isValid['discount'] = true;
// //       }
// //
// //       if (startDate == null) {
// //         errors['startDate'] = "Date de début requise";
// //         isValid['startDate'] = false;
// //       } else {
// //         errors['startDate'] = null;
// //         isValid['startDate'] = true;
// //       }
// //
// //       if (endDate == null) {
// //         errors['endDate'] = "Date de fin requise";
// //         isValid['endDate'] = false;
// //       } else if (startDate != null && endDate!.isBefore(startDate!)) {
// //         errors['endDate'] = "Fin doit être après le début";
// //         isValid['endDate'] = false;
// //       } else {
// //         errors['endDate'] = null;
// //         isValid['endDate'] = true;
// //       }
// //     });
// //   }
// //
// //   Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
// //     validateFields(setModalState);
// //     if (errors.values.any((e) => e != null)) return;
// //
// //     // Créer les dates avec uniquement l'année, mois, jour (sans l'heure)
// //     final DateTime startDateTime = DateTime(startDate!.year, startDate!.month, startDate!.day);
// //     final DateTime endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day);
// //
// //     final promo = Promotion(
// //       id: 0,
// //       serviceId: serviceId,
// //       pourcentage: double.parse(discountController.text.trim()),
// //       dateDebut: startDateTime,
// //       dateFin: endDateTime,
// //     );
// //
// //     setModalState(() => isLoading = true);
// //     try {
// //       print("Envoi de promo: Début=${promo.dateDebut.toIso8601String().split('T')[0]}, "
// //           "Fin=${promo.dateFin.toIso8601String().split('T')[0]}");
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_promotion/$serviceId/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode(promo.toJson()),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         showDialog(
// //           context: innerContext,
// //           barrierDismissible: false,
// //           builder: (context) => Dialog(
// //             backgroundColor: Colors.transparent,
// //             elevation: 0,
// //             child: Container(
// //               width: 100,
// //               height: 100,
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(16),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.check_circle, color: successGreen, size: 60),
// //                   const SizedBox(height: 10),
// //                   const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         );
// //
// //         Future.delayed(const Duration(milliseconds: 1500), () {
// //           Navigator.of(innerContext).pop();
// //           Navigator.of(innerContext).pop(true);
// //           onPromoAdded();
// //         });
// //       } else if (response.statusCode == 400) {
// //         // Gérer spécifiquement l'erreur 400 (probablement un chevauchement)
// //         String errorMessage = "Impossible de créer la promotion.";
// //         try {
// //           final errorData = json.decode(response.body);
// //           if (errorData.containsKey('error')) {
// //             errorMessage = errorData['error'];
// //           }
// //         } catch (_) {}
// //
// //         ScaffoldMessenger.of(innerContext).showSnackBar(
// //           SnackBar(content: Text(errorMessage), backgroundColor: errorRed),
// //         );
// //       } else {
// //         ScaffoldMessenger.of(innerContext).showSnackBar(
// //           SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: errorRed),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(innerContext).showSnackBar(
// //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: errorRed),
// //       );
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) => StatefulBuilder(
// //       builder: (context, setModalState) => Builder(
// //         builder: (innerContext) => AnimatedPadding(
// //           duration: const Duration(milliseconds: 300),
// //           padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
// //           child: DraggableScrollableSheet(
// //             initialChildSize: 0.75,
// //             maxChildSize: 0.95,
// //             minChildSize: 0.5,
// //             expand: false,
// //             builder: (context, scrollController) => Container(
// //               padding: const EdgeInsets.all(20),
// //               decoration: const BoxDecoration(
// //                 color: Color(0xFFF7F7F9),
// //                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //               ),
// //               child: ListView(
// //                 controller: scrollController,
// //                 children: [
// //                   Center(
// //                     child: Container(
// //                       width: 40,
// //                       height: 5,
// //                       margin: const EdgeInsets.only(bottom: 20),
// //                       decoration: BoxDecoration(
// //                         color: Colors.grey[300],
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                     ),
// //                   ),
// //                   const Text("Ajouter une promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
// //                   const SizedBox(height: 30),
// //                   TextField(
// //                     controller: discountController,
// //                     keyboardType: TextInputType.number,
// //                     onChanged: (_) => validateFields(setModalState),
// //                     decoration: InputDecoration(
// //                       prefixIcon: Icon(Icons.percent, color: primaryViolet),
// //                       labelText: "Pourcentage de réduction",
// //                       errorText: errors['discount'],
// //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   ListTile(
// //                     title: Text(startDate == null
// //                         ? "Choisir une date de début"
// //                         : "Début : ${startDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: DateTime.now(),
// //                         firstDate: DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 365)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => startDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['startDate'] != null
// //                         ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   ListTile(
// //                     title: Text(endDate == null
// //                         ? "Choisir une date de fin"
// //                         : "Fin : ${endDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: startDate ?? DateTime.now(),
// //                         firstDate: startDate ?? DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 730)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => endDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['endDate'] != null
// //                         ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   const SizedBox(height: 30),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: primaryViolet,
// //                         padding: const EdgeInsets.symmetric(vertical: 16),
// //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                       ),
// //                       child: isLoading
// //                           ? const CircularProgressIndicator(color: Colors.white)
// //                           : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     ),
// //   );
// // }
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
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // import '../../../../../models/promotion.dart';
// //
// // void showCreatePromotionModal({
// //   required BuildContext context,
// //   required int serviceId,
// //   required VoidCallback onPromoAdded,
// // }) {
// //   final TextEditingController discountController = TextEditingController();
// //   DateTime? startDate;
// //   DateTime? endDate;
// //   bool isLoading = false;
// //
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //   final Color errorRed = Colors.red;
// //   final Color successGreen = Colors.green;
// //
// //   Map<String, String?> errors = {
// //     'discount': null,
// //     'startDate': null,
// //     'endDate': null,
// //   };
// //
// //   Map<String, bool> isValid = {
// //     'discount': false,
// //     'startDate': false,
// //     'endDate': false,
// //   };
// //
// //   void validateFields(StateSetter setModalState) {
// //     final discountText = discountController.text.trim();
// //     final double? discount = double.tryParse(discountText);
// //
// //     setModalState(() {
// //       if (discount == null || discount <= 0 || discount > 100) {
// //         errors['discount'] = "Pourcentage invalide (1-100%)";
// //         isValid['discount'] = false;
// //       } else {
// //         errors['discount'] = null;
// //         isValid['discount'] = true;
// //       }
// //
// //       if (startDate == null) {
// //         errors['startDate'] = "Date de début requise";
// //         isValid['startDate'] = false;
// //       } else {
// //         errors['startDate'] = null;
// //         isValid['startDate'] = true;
// //       }
// //
// //       if (endDate == null) {
// //         errors['endDate'] = "Date de fin requise";
// //         isValid['endDate'] = false;
// //       } else if (startDate != null && endDate!.isBefore(startDate!)) {
// //         errors['endDate'] = "Fin doit être après le début";
// //         isValid['endDate'] = false;
// //       } else {
// //         errors['endDate'] = null;
// //         isValid['endDate'] = true;
// //       }
// //     });
// //   }
// //
// //   Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
// //     validateFields(setModalState);
// //     if (errors.values.any((e) => e != null)) return;
// //
// //     // On envoie uniquement la date sans préciser d'heure
// //     final promo = Promotion(
// //       id: 0,
// //       serviceId: serviceId,
// //       pourcentage: double.parse(discountController.text.trim()),
// //       // Utiliser uniquement la date, sans l'heure
// //       dateDebut: DateTime(startDate!.year, startDate!.month, startDate!.day),
// //       dateFin: DateTime(endDate!.year, endDate!.month, endDate!.day),
// //     );
// //
// //     setModalState(() => isLoading = true);
// //     try {
// //       // Pour déboguer, afficher uniquement la partie date (YYYY-MM-DD)
// //       print("Envoi de promo: Début=${promo.dateDebut.toIso8601String().split('T')[0]}, "
// //           "Fin=${promo.dateFin.toIso8601String().split('T')[0]}");
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_promotion/$serviceId/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode(promo.toJson()),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         showDialog(
// //           context: innerContext,
// //           barrierDismissible: false,
// //           builder: (context) => Dialog(
// //             backgroundColor: Colors.transparent,
// //             elevation: 0,
// //             child: Container(
// //               width: 100,
// //               height: 100,
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(16),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.check_circle, color: successGreen, size: 60),
// //                   const SizedBox(height: 10),
// //                   const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         );
// //
// //         Future.delayed(const Duration(milliseconds: 1500), () {
// //           Navigator.of(innerContext).pop();
// //           Navigator.of(innerContext).pop(true);
// //           onPromoAdded();
// //         });
// //       } else {
// //         ScaffoldMessenger.of(innerContext).showSnackBar(
// //           SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: errorRed),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(innerContext).showSnackBar(
// //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: errorRed),
// //       );
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) => StatefulBuilder(
// //       builder: (context, setModalState) => Builder(
// //         builder: (innerContext) => AnimatedPadding(
// //           duration: const Duration(milliseconds: 300),
// //           padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
// //           child: DraggableScrollableSheet(
// //             initialChildSize: 0.75,
// //             maxChildSize: 0.95,
// //             minChildSize: 0.5,
// //             expand: false,
// //             builder: (context, scrollController) => Container(
// //               padding: const EdgeInsets.all(20),
// //               decoration: const BoxDecoration(
// //                 color: Color(0xFFF7F7F9),
// //                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //               ),
// //               child: ListView(
// //                 controller: scrollController,
// //                 children: [
// //                   Center(
// //                     child: Container(
// //                       width: 40,
// //                       height: 5,
// //                       margin: const EdgeInsets.only(bottom: 20),
// //                       decoration: BoxDecoration(
// //                         color: Colors.grey[300],
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                     ),
// //                   ),
// //                   const Text("Ajouter une promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
// //                   const SizedBox(height: 30),
// //                   TextField(
// //                     controller: discountController,
// //                     keyboardType: TextInputType.number,
// //                     onChanged: (_) => validateFields(setModalState),
// //                     decoration: InputDecoration(
// //                       prefixIcon: Icon(Icons.percent, color: primaryViolet),
// //                       labelText: "Pourcentage de réduction",
// //                       errorText: errors['discount'],
// //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   ListTile(
// //                     title: Text(startDate == null
// //                         ? "Choisir une date de début"
// //                         : "Début : ${startDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: DateTime.now(),
// //                         firstDate: DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 365)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => startDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['startDate'] != null
// //                         ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   ListTile(
// //                     title: Text(endDate == null
// //                         ? "Choisir une date de fin"
// //                         : "Fin : ${endDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: startDate ?? DateTime.now(),
// //                         firstDate: startDate ?? DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 730)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => endDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['endDate'] != null
// //                         ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   const SizedBox(height: 30),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: primaryViolet,
// //                         padding: const EdgeInsets.symmetric(vertical: 16),
// //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                       ),
// //                       child: isLoading
// //                           ? const CircularProgressIndicator(color: Colors.white)
// //                           : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     ),
// //   );
// // }
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // import '../../../../../models/promotion.dart';
// //
// // void showCreatePromotionModal({
// //   required BuildContext context,
// //   required int serviceId,
// //   required VoidCallback onPromoAdded,
// // }) {
// //   final TextEditingController discountController = TextEditingController();
// //   DateTime? startDate;
// //   DateTime? endDate;
// //   bool isLoading = false;
// //
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //   final Color errorRed = Colors.red;
// //   final Color successGreen = Colors.green;
// //
// //   Map<String, String?> errors = {
// //     'discount': null,
// //     'startDate': null,
// //     'endDate': null,
// //   };
// //
// //   Map<String, bool> isValid = {
// //     'discount': false,
// //     'startDate': false,
// //     'endDate': false,
// //   };
// //
// //   void validateFields(StateSetter setModalState) {
// //     final discountText = discountController.text.trim();
// //     final double? discount = double.tryParse(discountText);
// //
// //     setModalState(() {
// //       if (discount == null || discount <= 0 || discount > 100) {
// //         errors['discount'] = "Pourcentage invalide (1-100%)";
// //         isValid['discount'] = false;
// //       } else {
// //         errors['discount'] = null;
// //         isValid['discount'] = true;
// //       }
// //
// //       if (startDate == null) {
// //         errors['startDate'] = "Date de début requise";
// //         isValid['startDate'] = false;
// //       } else {
// //         errors['startDate'] = null;
// //         isValid['startDate'] = true;
// //       }
// //
// //       if (endDate == null) {
// //         errors['endDate'] = "Date de fin requise";
// //         isValid['endDate'] = false;
// //       } else if (startDate != null && endDate!.isBefore(startDate!)) {
// //         errors['endDate'] = "Fin doit être après le début";
// //         isValid['endDate'] = false;
// //       } else {
// //         errors['endDate'] = null;
// //         isValid['endDate'] = true;
// //       }
// //     });
// //   }
// //
// //   Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
// //     validateFields(setModalState);
// //     if (errors.values.any((e) => e != null)) return;
// //
// //     final promo = Promotion(
// //       id: 0,
// //       serviceId: serviceId,
// //       pourcentage: double.parse(discountController.text.trim()),
// //       dateDebut: startDate!,
// //       dateFin: endDate!,
// //     );
// //
// //     setModalState(() => isLoading = true);
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_promotion/$serviceId/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode(promo.toJson()),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         showDialog(
// //           context: innerContext,
// //           barrierDismissible: false,
// //           builder: (context) => Dialog(
// //             backgroundColor: Colors.transparent,
// //             elevation: 0,
// //             child: Container(
// //               width: 100,
// //               height: 100,
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(16),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.check_circle, color: successGreen, size: 60),
// //                   const SizedBox(height: 10),
// //                   const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         );
// //
// //         Future.delayed(const Duration(milliseconds: 1500), () {
// //           Navigator.of(innerContext).pop();
// //           Navigator.of(innerContext).pop(true);
// //           onPromoAdded();
// //         });
// //       } else {
// //         ScaffoldMessenger.of(innerContext).showSnackBar(
// //           SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: errorRed),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(innerContext).showSnackBar(
// //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: errorRed),
// //       );
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) => StatefulBuilder(
// //       builder: (context, setModalState) => Builder(
// //         builder: (innerContext) => AnimatedPadding(
// //           duration: const Duration(milliseconds: 300),
// //           padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
// //           child: DraggableScrollableSheet(
// //             initialChildSize: 0.75,
// //             maxChildSize: 0.95,
// //             minChildSize: 0.5,
// //             expand: false,
// //             builder: (context, scrollController) => Container(
// //               padding: const EdgeInsets.all(20),
// //               decoration: const BoxDecoration(
// //                 color: Color(0xFFF7F7F9),
// //                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //               ),
// //               child: ListView(
// //                 controller: scrollController,
// //                 children: [
// //                   Center(
// //                     child: Container(
// //                       width: 40,
// //                       height: 5,
// //                       margin: const EdgeInsets.only(bottom: 20),
// //                       decoration: BoxDecoration(
// //                         color: Colors.grey[300],
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                     ),
// //                   ),
// //                   const Text("Ajouter une promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
// //                   const SizedBox(height: 30),
// //                   TextField(
// //                     controller: discountController,
// //                     keyboardType: TextInputType.number,
// //                     onChanged: (_) => validateFields(setModalState),
// //                     decoration: InputDecoration(
// //                       prefixIcon: Icon(Icons.percent, color: primaryViolet),
// //                       labelText: "Pourcentage de réduction",
// //                       errorText: errors['discount'],
// //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   ListTile(
// //                     title: Text(startDate == null
// //                         ? "Choisir une date de début"
// //                         : "Début : ${startDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: DateTime.now(),
// //                         firstDate: DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 365)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => startDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['startDate'] != null
// //                         ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   ListTile(
// //                     title: Text(endDate == null
// //                         ? "Choisir une date de fin"
// //                         : "Fin : ${endDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: startDate ?? DateTime.now(),
// //                         firstDate: startDate ?? DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 730)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => endDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['endDate'] != null
// //                         ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   const SizedBox(height: 30),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: primaryViolet,
// //                         padding: const EdgeInsets.symmetric(vertical: 16),
// //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                       ),
// //                       child: isLoading
// //                           ? const CircularProgressIndicator(color: Colors.white)
// //                           : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     ),
// //   );
// // }
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // void showCreatePromotionModal({
// //   required BuildContext context,
// //   required int serviceId,
// //   required VoidCallback onPromoAdded,
// // }) {
// //   final TextEditingController discountController = TextEditingController();
// //   DateTime? startDate;
// //   DateTime? endDate;
// //   bool isLoading = false;
// //
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //   final Color errorRed = Colors.red;
// //   final Color successGreen = Colors.green;
// //
// //   Map<String, String?> errors = {
// //     'discount': null,
// //     'startDate': null,
// //     'endDate': null,
// //   };
// //
// //   Map<String, bool> isValid = {
// //     'discount': false,
// //     'startDate': false,
// //     'endDate': false,
// //   };
// //
// //   void validateFields(StateSetter setModalState) {
// //     final discountText = discountController.text.trim();
// //     final double? discount = double.tryParse(discountText);
// //
// //     setModalState(() {
// //       if (discount == null || discount <= 0 || discount > 100) {
// //         errors['discount'] = "Pourcentage invalide (1-100%)";
// //         isValid['discount'] = false;
// //       } else {
// //         errors['discount'] = null;
// //         isValid['discount'] = true;
// //       }
// //
// //       if (startDate == null) {
// //         errors['startDate'] = "Date de début requise";
// //         isValid['startDate'] = false;
// //       } else {
// //         errors['startDate'] = null;
// //         isValid['startDate'] = true;
// //       }
// //
// //       if (endDate == null) {
// //         errors['endDate'] = "Date de fin requise";
// //         isValid['endDate'] = false;
// //       } else if (startDate != null && endDate!.isBefore(startDate!)) {
// //         errors['endDate'] = "Fin doit être après le début";
// //         isValid['endDate'] = false;
// //       } else {
// //         errors['endDate'] = null;
// //         isValid['endDate'] = true;
// //       }
// //     });
// //   }
// //
// //   Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
// //     validateFields(setModalState);
// //     if (errors.values.any((e) => e != null)) return;
// //
// //     setModalState(() => isLoading = true);
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_promotion/$serviceId/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'service_id': serviceId,
// //           'discount_percentage': double.parse(discountController.text.trim()),
// //           'start_date': startDate!.toIso8601String(),
// //           'end_date': endDate!.toIso8601String(),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         showDialog(
// //           context: innerContext,
// //           barrierDismissible: false,
// //           builder: (context) => Dialog(
// //             backgroundColor: Colors.transparent,
// //             elevation: 0,
// //             child: Container(
// //               width: 100,
// //               height: 100,
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(16),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.check_circle, color: successGreen, size: 60),
// //                   const SizedBox(height: 10),
// //                   const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         );
// //
// //         Future.delayed(const Duration(milliseconds: 1500), () {
// //           Navigator.of(innerContext).pop();
// //           Navigator.of(innerContext).pop(true);
// //           onPromoAdded();
// //         });
// //       } else {
// //         ScaffoldMessenger.of(innerContext).showSnackBar(
// //           SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: errorRed),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(innerContext).showSnackBar(
// //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: errorRed),
// //       );
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) => StatefulBuilder(
// //       builder: (context, setModalState) => Builder(
// //         builder: (innerContext) => AnimatedPadding(
// //           duration: const Duration(milliseconds: 300),
// //           padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
// //           child: DraggableScrollableSheet(
// //             initialChildSize: 0.75,
// //             maxChildSize: 0.95,
// //             minChildSize: 0.5,
// //             expand: false,
// //             builder: (context, scrollController) => Container(
// //               padding: const EdgeInsets.all(20),
// //               decoration: const BoxDecoration(
// //                 color: Color(0xFFF7F7F9),
// //                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //               ),
// //               child: ListView(
// //                 controller: scrollController,
// //                 children: [
// //                   Center(
// //                     child: Container(
// //                       width: 40,
// //                       height: 5,
// //                       margin: const EdgeInsets.only(bottom: 20),
// //                       decoration: BoxDecoration(
// //                         color: Colors.grey[300],
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                     ),
// //                   ),
// //                   const Text("Ajouter une promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
// //                   const SizedBox(height: 30),
// //                   TextField(
// //                     controller: discountController,
// //                     keyboardType: TextInputType.number,
// //                     onChanged: (_) => validateFields(setModalState),
// //                     decoration: InputDecoration(
// //                       prefixIcon: Icon(Icons.percent, color: primaryViolet),
// //                       labelText: "Pourcentage de réduction",
// //                       errorText: errors['discount'],
// //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   ListTile(
// //                     title: Text(startDate == null
// //                         ? "Choisir une date de début"
// //                         : "Début : ${startDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: DateTime.now(),
// //                         firstDate: DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 365)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => startDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['startDate'] != null
// //                         ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   ListTile(
// //                     title: Text(endDate == null
// //                         ? "Choisir une date de fin"
// //                         : "Fin : ${endDate!.toLocal().toString().split(' ')[0]}"),
// //                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                     onTap: () async {
// //                       final picked = await showDatePicker(
// //                         context: innerContext,
// //                         initialDate: startDate ?? DateTime.now(),
// //                         firstDate: startDate ?? DateTime.now(),
// //                         lastDate: DateTime.now().add(const Duration(days: 730)),
// //                       );
// //                       if (picked != null) {
// //                         setModalState(() => endDate = picked);
// //                         validateFields(setModalState);
// //                       }
// //                     },
// //                     subtitle: errors['endDate'] != null
// //                         ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                         : null,
// //                   ),
// //                   const SizedBox(height: 30),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: primaryViolet,
// //                         padding: const EdgeInsets.symmetric(vertical: 16),
// //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                       ),
// //                       child: isLoading
// //                           ? const CircularProgressIndicator(color: Colors.white)
// //                           : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     ),
// //   );
// // }
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // void showCreatePromotionModal({
// //   required BuildContext context,
// //   required int serviceId,
// //   required VoidCallback onPromoAdded,
// // }) {
// //   final TextEditingController discountController = TextEditingController();
// //   DateTime? startDate;
// //   DateTime? endDate;
// //   bool isLoading = false;
// //
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //   final Color errorRed = Colors.red;
// //   final Color successGreen = Colors.green;
// //
// //   Map<String, String?> errors = {
// //     'discount': null,
// //     'startDate': null,
// //     'endDate': null,
// //   };
// //
// //   Map<String, bool> isValid = {
// //     'discount': false,
// //     'startDate': false,
// //     'endDate': false,
// //   };
// //
// //   void validateFields(StateSetter setModalState) {
// //     final discountText = discountController.text.trim();
// //     final double? discount = double.tryParse(discountText);
// //
// //     setModalState(() {
// //       if (discount == null || discount <= 0 || discount > 100) {
// //         errors['discount'] = "Pourcentage invalide (1-100%)";
// //         isValid['discount'] = false;
// //       } else {
// //         errors['discount'] = null;
// //         isValid['discount'] = true;
// //       }
// //
// //       if (startDate == null) {
// //         errors['startDate'] = "Date de début requise";
// //         isValid['startDate'] = false;
// //       } else {
// //         errors['startDate'] = null;
// //         isValid['startDate'] = true;
// //       }
// //
// //       if (endDate == null) {
// //         errors['endDate'] = "Date de fin requise";
// //         isValid['endDate'] = false;
// //       } else if (startDate != null && endDate!.isBefore(startDate!)) {
// //         errors['endDate'] = "Fin doit être après le début";
// //         isValid['endDate'] = false;
// //       } else {
// //         errors['endDate'] = null;
// //         isValid['endDate'] = true;
// //       }
// //     });
// //   }
// //
// //   Future<void> submitPromotion(StateSetter setModalState) async {
// //     validateFields(setModalState);
// //     if (errors.values.any((e) => e != null)) return;
// //
// //     setModalState(() => isLoading = true);
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_promotion/${serviceId}/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'service_id': serviceId,
// //           'discount_percentage': double.parse(discountController.text.trim()),
// //           'start_date': startDate!.toLocal(),
// //           'end_date': endDate!.toLocal(),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         showDialog(
// //           context: context,
// //           barrierDismissible: false,
// //           builder: (context) => Dialog(
// //             backgroundColor: Colors.transparent,
// //             elevation: 0,
// //             child: Container(
// //               width: 100,
// //               height: 100,
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(16),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.check_circle, color: successGreen, size: 60),
// //                   const SizedBox(height: 10),
// //                   const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         );
// //
// //         Future.delayed(const Duration(milliseconds: 1500), () {
// //           Navigator.of(context).pop(); // close success dialog
// //           Navigator.of(context).pop(true); // close bottom sheet
// //           onPromoAdded();
// //         });
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: errorRed),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: errorRed),
// //       );
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) => StatefulBuilder(
// //       builder: (context, setModalState) => AnimatedPadding(
// //         duration: const Duration(milliseconds: 300),
// //         padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// //         child: DraggableScrollableSheet(
// //           initialChildSize: 0.75,
// //           maxChildSize: 0.95,
// //           minChildSize: 0.5,
// //           expand: false,
// //           builder: (context, scrollController) => Container(
// //             padding: const EdgeInsets.all(20),
// //             decoration: const BoxDecoration(
// //               color: Color(0xFFF7F7F9),
// //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //             ),
// //             child: ListView(
// //               controller: scrollController,
// //               children: [
// //                 Center(
// //                   child: Container(
// //                     width: 40,
// //                     height: 5,
// //                     margin: const EdgeInsets.only(bottom: 20),
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey[300],
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                   ),
// //                 ),
// //                 const Text("Ajouter une promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
// //                 const SizedBox(height: 30),
// //
// //                 // Pourcentage
// //                 TextField(
// //                   controller: discountController,
// //                   keyboardType: TextInputType.number,
// //                   onChanged: (_) => validateFields(setModalState),
// //                   decoration: InputDecoration(
// //                     prefixIcon: Icon(Icons.percent, color: primaryViolet),
// //                     labelText: "Pourcentage de réduction",
// //                     errorText: errors['discount'],
// //                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
// //                   ),
// //                 ),
// //
// //                 const SizedBox(height: 20),
// //
// //                 // Date de début
// //                 ListTile(
// //                   title: Text(startDate == null
// //                       ? "Choisir une date de début"
// //                       : "Début : ${startDate!.toLocal().toString().split(' ')[0]}"),
// //                   trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                   onTap: () async {
// //                     final picked = await showDatePicker(
// //                       context: context,
// //                       initialDate: DateTime.now(),
// //                       firstDate: DateTime.now(),
// //                       lastDate: DateTime.now().add(const Duration(days: 365)),
// //                     );
// //                     if (picked != null) {
// //                       setModalState(() => startDate = picked);
// //                       validateFields(setModalState);
// //                     }
// //                   },
// //                   subtitle: errors['startDate'] != null
// //                       ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                       : null,
// //                 ),
// //
// //                 // Date de fin
// //                 ListTile(
// //                   title: Text(endDate == null
// //                       ? "Choisir une date de fin"
// //                       : "Fin : ${endDate!.toLocal().toString().split(' ')[0]}"),
// //                   trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                   onTap: () async {
// //                     final picked = await showDatePicker(
// //                       context: context,
// //                       initialDate: startDate ?? DateTime.now(),
// //                       firstDate: startDate ?? DateTime.now(),
// //                       lastDate: DateTime.now().add(const Duration(days: 730)),
// //                     );
// //                     if (picked != null) {
// //                       setModalState(() => endDate = picked);
// //                       validateFields(setModalState);
// //                     }
// //                   },
// //                   subtitle: errors['endDate'] != null
// //                       ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
// //                       : null,
// //                 ),
// //
// //                 const SizedBox(height: 30),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: isLoading ? null : () => submitPromotion(setModalState),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: primaryViolet,
// //                       padding: const EdgeInsets.symmetric(vertical: 16),
// //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                     ),
// //                     child: isLoading
// //                         ? const CircularProgressIndicator(color: Colors.white)
// //                         : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     ),
// //   );
// // }
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
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // void showCreatePromotionModal({
// //   required BuildContext context,
// //   required int serviceId,
// //   required VoidCallback onPromoAdded,
// // }) {
// //   final TextEditingController discountController = TextEditingController();
// //   DateTime? startDate;
// //   DateTime? endDate;
// //
// //   bool isLoading = false;
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //   final Color errorRed = Colors.red;
// //   final Color successGreen = Colors.green;
// //
// //   Map<String, String?> errors = {
// //     'discount': null,
// //     'startDate': null,
// //     'endDate': null,
// //   };
// //
// //   Map<String, bool> isValid = {
// //     'discount': false,
// //     'startDate': false,
// //     'endDate': false,
// //   };
// //
// //   void validateFields(StateSetter setModalState) {
// //     final discountText = discountController.text.trim();
// //     final double? discount = double.tryParse(discountText);
// //
// //     setModalState(() {
// //       if (discount == null || discount <= 0 || discount > 100) {
// //         errors['discount'] = "Pourcentage invalide (1-100%)";
// //         isValid['discount'] = false;
// //       } else {
// //         errors['discount'] = null;
// //         isValid['discount'] = true;
// //       }
// //
// //       if (startDate == null) {
// //         errors['startDate'] = "Date de début requise";
// //         isValid['startDate'] = false;
// //       } else {
// //         errors['startDate'] = null;
// //         isValid['startDate'] = true;
// //       }
// //
// //       if (endDate == null) {
// //         errors['endDate'] = "Date de fin requise";
// //         isValid['endDate'] = false;
// //       } else if (startDate != null && endDate!.isBefore(startDate!)) {
// //         errors['endDate'] = "La date de fin doit être après la date de début";
// //         isValid['endDate'] = false;
// //       } else {
// //         errors['endDate'] = null;
// //         isValid['endDate'] = true;
// //       }
// //     });
// //   }
// //
// //   Future<void> submitPromotion(StateSetter setModalState) async {
// //     validateFields(setModalState);
// //     if (errors.values.any((e) => e != null)) return;
// //
// //     setModalState(() => isLoading = true);
// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_promotion/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'service_id': serviceId,
// //           'discount_percentage': double.parse(discountController.text.trim()),
// //           'start_date': startDate!.toIso8601String(),
// //           'end_date': endDate!.toIso8601String(),
// //         }),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         Navigator.of(context).pop(true);
// //         onPromoAdded();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: errorRed),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: errorRed),
// //       );
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) => StatefulBuilder(
// //       builder: (context, setModalState) => Padding(
// //         padding: MediaQuery.of(context).viewInsets,
// //         child: DraggableScrollableSheet(
// //           initialChildSize: 0.7,
// //           maxChildSize: 0.95,
// //           minChildSize: 0.4,
// //           expand: false,
// //           builder: (context, scrollController) => Container(
// //             padding: const EdgeInsets.all(20),
// //             decoration: const BoxDecoration(
// //               color: Color(0xFFF7F7F9),
// //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //             ),
// //             child: ListView(
// //               controller: scrollController,
// //               children: [
// //                 const Center(
// //                   child: Text("Ajouter une promotion", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
// //                 ),
// //                 const SizedBox(height: 20),
// //
// //                 // Pourcentage de réduction
// //                 TextField(
// //                   controller: discountController,
// //                   keyboardType: TextInputType.number,
// //                   onChanged: (_) => validateFields(setModalState),
// //                   decoration: InputDecoration(
// //                     prefixIcon: Icon(Icons.percent, color: primaryViolet),
// //                     labelText: "Pourcentage de réduction (%)",
// //                     errorText: errors['discount'],
// //                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //
// //                 // Date de début
// //                 ListTile(
// //                   title: Text(startDate == null
// //                       ? "Choisir une date de début"
// //                       : "Début : ${startDate!.toLocal()}"),
// //                   trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                   onTap: () async {
// //                     final picked = await showDatePicker(
// //                       context: context,
// //                       initialDate: DateTime.now(),
// //                       firstDate: DateTime.now().subtract(const Duration(days: 0)),
// //                       lastDate: DateTime.now().add(const Duration(days: 365)),
// //                     );
// //                     if (picked != null) {
// //                       setModalState(() => startDate = picked);
// //                       validateFields(setModalState);
// //                     }
// //                   },
// //                   subtitle: errors['startDate'] != null ? Text(errors['startDate']!, style: TextStyle(color: errorRed)) : null,
// //                 ),
// //
// //                 // Date de fin
// //                 ListTile(
// //                   title: Text(endDate == null
// //                       ? "Choisir une date de fin"
// //                       : "Fin : ${endDate!.toLocal()}"),
// //                   trailing: Icon(Icons.calendar_today, color: primaryViolet),
// //                   onTap: () async {
// //                     final picked = await showDatePicker(
// //                       context: context,
// //                       initialDate: DateTime.now(),
// //                       firstDate: DateTime.now(),
// //                       lastDate: DateTime.now().add(const Duration(days: 730)),
// //                     );
// //                     if (picked != null) {
// //                       setModalState(() => endDate = picked);
// //                       validateFields(setModalState);
// //                     }
// //                   },
// //                   subtitle: errors['endDate'] != null ? Text(errors['endDate']!, style: TextStyle(color: errorRed)) : null,
// //                 ),
// //
// //                 const SizedBox(height: 30),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: isLoading ? null : () => submitPromotion(setModalState),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: primaryViolet,
// //                       padding: const EdgeInsets.symmetric(vertical: 14),
// //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                     ),
// //                     child: isLoading
// //                         ? const CircularProgressIndicator(color: Colors.white)
// //                         : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     ),
// //   );
// // }