import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void showCreatePromotionModal({
  required BuildContext context,
  required int salonId,
  required int serviceId,
  required VoidCallback onPromoAdded,
}) {

  // Vérifier que les IDs sont valides
  if (salonId <= 0) {
    if (kDebugMode) {
      print('❌ ERREUR: salonId invalide ($salonId)');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ID du salon invalide ($salonId)'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (serviceId <= 0) {
    if (kDebugMode) {
      print('❌ ERREUR: serviceId invalide ($serviceId)');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ID du service invalide ($serviceId)'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

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

  Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
    validateFields(setModalState);
    if (errors.values.any((e) => e != null)) return;

    final startDateTime = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day);

    final promotionData = {
      'discount_percentage': double.parse(discountController.text.trim()),
      'start_date': startDateTime.toIso8601String().split('T')[0],
      'end_date': endDateTime.toIso8601String().split('T')[0],
    };

    setModalState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Utiliser la nouvelle URL avec salon_id et service_id
      final url = 'https://www.hairbnb.site/api/salon/$salonId/service/$serviceId/promotion/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(promotionData),
      );

      if (response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Promotion créée avec succès !');
        }

        showDialog(
          context: innerContext,
          barrierDismissible: false,
          builder: (context) => Dialog(
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
                  const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
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
        String errorText = "Impossible de créer la promotion.";
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          if (kDebugMode) {
            print('❌ Erreur 400 détails: $errorData');
          }

          if (errorData is Map) {
            if (errorData.containsKey('error')) {
              errorText = errorData['error'];
            } else if (errorData.containsKey('detail')) {
              errorText = errorData['detail'];
            } else if (errorData.containsKey('message')) {
              errorText = errorData['message'];
            } else {
              errorText = errorData.toString();
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Erreur lors du parsing de l\'erreur: $e');
          }
          errorText = response.body;
        }

        setModalState(() {
          errorMessage = errorText;
          isLoading = false;
        });

      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('❌ Erreur 404: Ressource non trouvée');
        }
        setModalState(() {
          errorMessage = "Service ou salon introuvable (404). Vérifiez les IDs.";
          isLoading = false;
        });

      } else {
        if (kDebugMode) {
          print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        }
        setModalState(() {
          errorMessage = "Erreur serveur (${response.statusCode}): ${response.reasonPhrase}";
          isLoading = false;
        });
      }

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Exception lors de la création: $e');
      }
      if (kDebugMode) {
        print('📍 StackTrace: $stackTrace');
      }

      setModalState(() {
        errorMessage = "Erreur de connexion: $e";
        isLoading = false;
      });
    }
  }

  // Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
  //   validateFields(setModalState);
  //   if (errors.values.any((e) => e != null)) return;
  //
  //   final startDateTime = DateTime(startDate!.year, startDate!.month, startDate!.day);
  //   final endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day);
  //
  //   final promotionData = {
  //     'discount_percentage': double.parse(discountController.text.trim()),
  //     'start_date': startDateTime.toIso8601String().split('T')[0],
  //     'end_date': endDateTime.toIso8601String().split('T')[0],
  //   };
  //
  //   setModalState(() {
  //     isLoading = true;
  //     errorMessage = null;
  //   });
  //
  //   try {
  //     // 🔥 DEBUG : Afficher toutes les infos de la requête
  //     print('🚀 Début création promotion:');
  //     print('   📍 Salon ID: $salonId');
  //     print('   🎯 Service ID: $serviceId');
  //     print('   💰 Réduction: ${promotionData['discount_percentage']}%');
  //     print('   📅 Début: ${promotionData['start_date']}');
  //     print('   📅 Fin: ${promotionData['end_date']}');
  //
  //     // 🔥 CHANGEMENT : Tester d'abord l'ancienne URL simple
  //     final url = 'https://www.hairbnb.site/api/create_promotion/$serviceId/';
  //     print('   🌐 URL: $url');
  //
  //     // 🔥 NOUVEAU : Ajouter salon_id dans le body de la requête
  //     final fullPromotionData = {
  //       ...promotionData,
  //       'salon_id': salonId, // 🔥 Ajouter salon_id dans le body
  //     };
  //
  //     print('   📦 Body envoyé: ${json.encode(fullPromotionData)}');
  //
  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode(fullPromotionData),
  //     );
  //
  //     print('📨 Réponse serveur:');
  //     print('   📊 Status Code: ${response.statusCode}');
  //     print('   📄 Headers: ${response.headers}');
  //     print('   📃 Body: ${response.body}');
  //
  //     if (response.statusCode == 201) {
  //       print('✅ Promotion créée avec succès !');
  //
  //       showDialog(
  //         context: innerContext,
  //         barrierDismissible: false,
  //         builder: (context) => Dialog(
  //           backgroundColor: Colors.transparent,
  //           elevation: 0,
  //           child: Container(
  //             width: 100,
  //             height: 100,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(16),
  //             ),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.check_circle, color: successGreen, size: 60),
  //                 const SizedBox(height: 10),
  //                 const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //
  //       Future.delayed(const Duration(milliseconds: 1500), () {
  //         Navigator.of(innerContext).pop();
  //         Navigator.of(innerContext).pop(true);
  //         onPromoAdded();
  //       });
  //
  //     } else if (response.statusCode == 400) {
  //       // 🔥 AMÉLIORATION : Gestion détaillée des erreurs 400
  //       String errorText = "Impossible de créer la promotion.";
  //       try {
  //         final errorData = json.decode(utf8.decode(response.bodyBytes));
  //         print('❌ Erreur 400 détails: $errorData');
  //
  //         if (errorData is Map) {
  //           if (errorData.containsKey('error')) {
  //             errorText = errorData['error'];
  //           } else if (errorData.containsKey('detail')) {
  //             errorText = errorData['detail'];
  //           } else if (errorData.containsKey('message')) {
  //             errorText = errorData['message'];
  //           } else {
  //             // Afficher toutes les erreurs disponibles
  //             errorText = errorData.toString();
  //           }
  //         }
  //       } catch (e) {
  //         print('❌ Erreur lors du parsing de l\'erreur: $e');
  //         errorText = response.body;
  //       }
  //
  //       setModalState(() {
  //         errorMessage = errorText;
  //         isLoading = false;
  //       });
  //
  //     } else if (response.statusCode == 404) {
  //       print('❌ Erreur 404: Ressource non trouvée');
  //       setModalState(() {
  //         errorMessage = "Service ou salon introuvable. Vérifiez les IDs.";
  //         isLoading = false;
  //       });
  //
  //     } else {
  //       print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
  //       setModalState(() {
  //         errorMessage = "Erreur serveur (${response.statusCode}): ${response.reasonPhrase}";
  //         isLoading = false;
  //       });
  //     }
  //
  //   } catch (e, stackTrace) {
  //     print('❌ Exception lors de la création: $e');
  //     print('📍 StackTrace: $stackTrace');
  //
  //     setModalState(() {
  //       errorMessage = "Erreur de connexion: $e";
  //       isLoading = false;
  //     });
  //   }
  // }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Builder(
        builder: (innerContext) => AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),

                  // 🔥 DEBUG : Afficher les IDs dans l'interface
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔍 Debug Info:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text('Salon ID: $salonId', style: TextStyle(color: Colors.blue[700])),
                        Text('Service ID: $serviceId', style: TextStyle(color: Colors.blue[700])),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => validateFields(setModalState),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.percent, color: primaryViolet),
                      labelText: "Pourcentage de réduction",
                      errorText: errors['discount'],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ListTile(
                    title: Text(startDate == null
                        ? "Choisir une date de début"
                        : "Début : ${startDate!.toLocal().toString().split(' ')[0]}"),
                    trailing: Icon(Icons.calendar_today, color: primaryViolet),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: innerContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => startDate = picked);
                        validateFields(setModalState);
                      }
                    },
                    subtitle: errors['startDate'] != null
                        ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
                        : null,
                  ),

                  ListTile(
                    title: Text(endDate == null
                        ? "Choisir une date de fin"
                        : "Fin : ${endDate!.toLocal().toString().split(' ')[0]}"),
                    trailing: Icon(Icons.calendar_today, color: primaryViolet),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: innerContext,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setModalState(() => endDate = picked);
                        validateFields(setModalState);
                      }
                    },
                    subtitle: errors['endDate'] != null
                        ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Afficher le message d'erreur s'il y en a un
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: errorRed.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: errorRed),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: errorRed),
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
                      onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryViolet,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
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
// void showCreatePromotionModal({
//   required BuildContext context,
//   required int salonId,      // 🔥 NOUVEAU : ID du salon
//   required int serviceId,
//   required VoidCallback onPromoAdded,
// }) {
//   final TextEditingController discountController = TextEditingController();
//   DateTime? startDate;
//   DateTime? endDate;
//   bool isLoading = false;
//   String? errorMessage;
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
//       errorMessage = null;
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
//   Future<void> submitPromotion(StateSetter setModalState,
//       BuildContext innerContext) async {
//     validateFields(setModalState);
//     if (errors.values.any((e) => e != null)) return;
//
//     // Créer la promotion avec les dates
//     final startDateTime = DateTime(
//         startDate!.year, startDate!.month, startDate!.day);
//     final endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day);
//
//     // 🔥 MISE À JOUR : Créer un objet avec salon_id
//     final promotionData = {
//       'discount_percentage': double.parse(discountController.text.trim()),
//       'start_date': startDateTime.toIso8601String().split('T')[0],
//       'end_date': endDateTime.toIso8601String().split('T')[0],
//     };
//
//     setModalState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       print("Envoi de la promotion: Salon ID=$salonId, Service ID=$serviceId, "
//           "Réduction=${promotionData['discount_percentage']}%, "
//           "Début=${promotionData['start_date']}, "
//           "Fin=${promotionData['end_date']}");
//
//       // 🔥 MISE À JOUR : Nouvelle URL avec salon_id et service_id
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/salon/$salonId/service/$serviceId/promotion/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(promotionData),
//       );
//
//       print("Réponse du serveur: Code ${response.statusCode}");
//       print("Corps de la réponse: ${response.body}");
//
//       if (response.statusCode == 201) {
//         showDialog(
//           context: innerContext,
//           barrierDismissible: false,
//           builder: (context) =>
//               Dialog(
//                 backgroundColor: Colors.transparent,
//                 elevation: 0,
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.check_circle, color: successGreen, size: 60),
//                       const SizedBox(height: 10),
//                       const Text("Promotion ajoutée !",
//                           style: TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//               ),
//         );
//
//         Future.delayed(const Duration(milliseconds: 1500), () {
//           Navigator.of(innerContext).pop();
//           Navigator.of(innerContext).pop(true);
//           onPromoAdded();
//         });
//       } else if (response.statusCode == 400) {
//         // Gérer l'erreur 400 et extraire le message
//         String errorText = "Impossible de créer la promotion.";
//         try {
//           final errorData = json.decode(utf8.decode(response.bodyBytes));
//           if (errorData.containsKey('error')) {
//             errorText = errorData['error'];
//           }
//         } catch (_) {}
//
//         setModalState(() {
//           errorMessage = errorText;
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
//     builder: (context) =>
//         StatefulBuilder(
//           builder: (context, setModalState) =>
//               Builder(
//                 builder: (innerContext) =>
//                     AnimatedPadding(
//                       duration: const Duration(milliseconds: 300),
//                       padding: MediaQuery
//                           .of(innerContext)
//                           .viewInsets + const EdgeInsets.all(10),
//                       child: DraggableScrollableSheet(
//                         initialChildSize: 0.75,
//                         maxChildSize: 0.95,
//                         minChildSize: 0.5,
//                         expand: false,
//                         builder: (context, scrollController) =>
//                             Container(
//                               padding: const EdgeInsets.all(20),
//                               decoration: const BoxDecoration(
//                                 color: Color(0xFFF7F7F9),
//                                 borderRadius: BorderRadius.vertical(
//                                     top: Radius.circular(24)),
//                               ),
//                               child: ListView(
//                                 controller: scrollController,
//                                 children: [
//                                   Center(
//                                     child: Container(
//                                       width: 40,
//                                       height: 5,
//                                       margin: const EdgeInsets.only(bottom: 20),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                     ),
//                                   ),
//                                   const Text("Ajouter une promotion",
//                                       style: TextStyle(
//                                           fontSize: 24, fontWeight: FontWeight
//                                           .w700)),
//                                   const SizedBox(height: 30),
//                                   TextField(
//                                     controller: discountController,
//                                     keyboardType: TextInputType.number,
//                                     onChanged: (_) =>
//                                         validateFields(setModalState),
//                                     inputFormatters: [
//                                       FilteringTextInputFormatter.allow(RegExp(
//                                           r'[0-9]')),
//                                     ],
//                                     decoration: InputDecoration(
//                                       prefixIcon: Icon(
//                                           Icons.percent, color: primaryViolet),
//                                       labelText: "Pourcentage de réduction",
//                                       errorText: errors['discount'],
//                                       border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               14)),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 20),
//                                   ListTile(
//                                     title: Text(startDate == null
//                                         ? "Choisir une date de début"
//                                         : "Début : ${startDate!
//                                         .toLocal()
//                                         .toString()
//                                         .split(' ')[0]}"),
//                                     trailing: Icon(Icons.calendar_today,
//                                         color: primaryViolet),
//                                     onTap: () async {
//                                       final picked = await showDatePicker(
//                                         context: innerContext,
//                                         initialDate: DateTime.now(),
//                                         firstDate: DateTime.now(),
//                                         lastDate: DateTime.now().add(
//                                             const Duration(days: 365)),
//                                       );
//                                       if (picked != null) {
//                                         setModalState(() => startDate = picked);
//                                         validateFields(setModalState);
//                                       }
//                                     },
//                                     subtitle: errors['startDate'] != null
//                                         ? Text(
//                                         errors['startDate']!, style: TextStyle(
//                                         color: errorRed, fontSize: 12))
//                                         : null,
//                                   ),
//                                   ListTile(
//                                     title: Text(endDate == null
//                                         ? "Choisir une date de fin"
//                                         : "Fin : ${endDate!
//                                         .toLocal()
//                                         .toString()
//                                         .split(' ')[0]}"),
//                                     trailing: Icon(Icons.calendar_today,
//                                         color: primaryViolet),
//                                     onTap: () async {
//                                       final picked = await showDatePicker(
//                                         context: innerContext,
//                                         initialDate: startDate ??
//                                             DateTime.now(),
//                                         firstDate: startDate ?? DateTime.now(),
//                                         lastDate: DateTime.now().add(
//                                             const Duration(days: 730)),
//                                       );
//                                       if (picked != null) {
//                                         setModalState(() => endDate = picked);
//                                         validateFields(setModalState);
//                                       }
//                                     },
//                                     subtitle: errors['endDate'] != null
//                                         ? Text(
//                                         errors['endDate']!, style: TextStyle(
//                                         color: errorRed, fontSize: 12))
//                                         : null,
//                                   ),
//                                   const SizedBox(height: 20),
//
//                                   // Afficher le message d'erreur s'il y en a un
//                                   if (errorMessage != null)
//                                     Container(
//                                       padding: const EdgeInsets.all(10),
//                                       decoration: BoxDecoration(
//                                         color: errorRed.withOpacity(0.1),
//                                         borderRadius: BorderRadius.circular(8),
//                                         border: Border.all(color: errorRed),
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           Icon(Icons.error_outline,
//                                               color: errorRed),
//                                           const SizedBox(width: 10),
//                                           Expanded(
//                                             child: Text(
//                                               errorMessage!,
//                                               style: TextStyle(color: errorRed),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//
//                                   const SizedBox(height: 20),
//
//                                   SizedBox(
//                                     width: double.infinity,
//                                     child: ElevatedButton(
//                                       onPressed: isLoading ? null : () =>
//                                           submitPromotion(
//                                               setModalState, innerContext),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: primaryViolet,
//                                         padding: const EdgeInsets.symmetric(
//                                             vertical: 16),
//                                         shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                                 14)),
//                                       ),
//                                       child: isLoading
//                                           ? const CircularProgressIndicator(
//                                           color: Colors.white)
//                                           : const Text("Créer la promotion",
//                                           style: TextStyle(
//                                               fontWeight: FontWeight.bold)),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                       ),
//                     ),
//               ),
//         ),
//   );
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
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // import '../../../../../models/promotion_full.dart';
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
// //   String? errorMessage;
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
// //       errorMessage = null;
// //
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
// //   Future<void> submitPromotion(StateSetter setModalState,
// //       BuildContext innerContext) async {
// //     validateFields(setModalState);
// //     if (errors.values.any((e) => e != null)) return;
// //
// //     // Créer la promotion avec les dates
// //     final startDateTime = DateTime(
// //         startDate!.year, startDate!.month, startDate!.day);
// //     final endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day);
// //
// //     final promo = PromotionFull(
// //       id: 0,
// //       serviceId: serviceId,
// //       pourcentage: double.parse(discountController.text.trim()),
// //       dateDebut: startDateTime,
// //       dateFin: endDateTime,
// //     );
// //
// //     setModalState(() {
// //       isLoading = true;
// //       errorMessage = null;
// //     });
// //
// //     try {
// //       print("Envoi de la promotion: Service ID=${promo.serviceId}, "
// //           "Réduction=${promo.pourcentage}%, "
// //           "Début=${promo.dateDebut.toIso8601String().split('T')[0]}, "
// //           "Fin=${promo.dateFin.toIso8601String().split('T')[0]}");
// //
// //       final response = await http.post(
// //         Uri.parse('https://www.hairbnb.site/api/create_promotion/$serviceId/'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode(promo.toJson()),
// //       );
// //
// //       print("Réponse du serveur: Code ${response.statusCode}");
// //       print("Corps de la réponse: ${response.body}");
// //
// //       if (response.statusCode == 201) {
// //         showDialog(
// //           context: innerContext,
// //           barrierDismissible: false,
// //           builder: (context) =>
// //               Dialog(
// //                 backgroundColor: Colors.transparent,
// //                 elevation: 0,
// //                 child: Container(
// //                   width: 100,
// //                   height: 100,
// //                   decoration: BoxDecoration(
// //                     color: Colors.white,
// //                     borderRadius: BorderRadius.circular(16),
// //                   ),
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Icon(Icons.check_circle, color: successGreen, size: 60),
// //                       const SizedBox(height: 10),
// //                       const Text("Promotion ajoutée !",
// //                           style: TextStyle(fontWeight: FontWeight.bold)),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //         );
// //
// //         Future.delayed(const Duration(milliseconds: 1500), () {
// //           Navigator.of(innerContext).pop();
// //           Navigator.of(innerContext).pop(true);
// //           onPromoAdded();
// //         });
// //       } else if (response.statusCode == 400) {
// //         // Gérer l'erreur 400 et extraire le message
// //         String errorText = "Impossible de créer la promotion.";
// //         try {
// //           final errorData = json.decode(utf8.decode(response.bodyBytes));
// //           if (errorData.containsKey('error')) {
// //             errorText = errorData['error'];
// //           }
// //         } catch (_) {}
// //
// //         setModalState(() {
// //           errorMessage = errorText;
// //           isLoading = false;
// //         });
// //       } else {
// //         setModalState(() {
// //           errorMessage = "Erreur: ${response.body}";
// //           isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       setModalState(() {
// //         errorMessage = "Erreur de connexion: $e";
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) =>
// //         StatefulBuilder(
// //           builder: (context, setModalState) =>
// //               Builder(
// //                 builder: (innerContext) =>
// //                     AnimatedPadding(
// //                       duration: const Duration(milliseconds: 300),
// //                       padding: MediaQuery
// //                           .of(innerContext)
// //                           .viewInsets + const EdgeInsets.all(10),
// //                       child: DraggableScrollableSheet(
// //                         initialChildSize: 0.75,
// //                         maxChildSize: 0.95,
// //                         minChildSize: 0.5,
// //                         expand: false,
// //                         builder: (context, scrollController) =>
// //                             Container(
// //                               padding: const EdgeInsets.all(20),
// //                               decoration: const BoxDecoration(
// //                                 color: Color(0xFFF7F7F9),
// //                                 borderRadius: BorderRadius.vertical(
// //                                     top: Radius.circular(24)),
// //                               ),
// //                               child: ListView(
// //                                 controller: scrollController,
// //                                 children: [
// //                                   Center(
// //                                     child: Container(
// //                                       width: 40,
// //                                       height: 5,
// //                                       margin: const EdgeInsets.only(bottom: 20),
// //                                       decoration: BoxDecoration(
// //                                         color: Colors.grey[300],
// //                                         borderRadius: BorderRadius.circular(8),
// //                                       ),
// //                                     ),
// //                                   ),
// //                                   const Text("Ajouter une promotion",
// //                                       style: TextStyle(
// //                                           fontSize: 24, fontWeight: FontWeight
// //                                           .w700)),
// //                                   const SizedBox(height: 30),
// //                                   TextField(
// //                                     controller: discountController,
// //                                     keyboardType: TextInputType.number,
// //                                     onChanged: (_) =>
// //                                         validateFields(setModalState),
// //                                     inputFormatters: [
// //                                       FilteringTextInputFormatter.allow(RegExp(
// //                                           r'[0-9]')),
// //                                     ],
// //                                     decoration: InputDecoration(
// //                                       prefixIcon: Icon(
// //                                           Icons.percent, color: primaryViolet),
// //                                       labelText: "Pourcentage de réduction",
// //                                       errorText: errors['discount'],
// //                                       border: OutlineInputBorder(
// //                                           borderRadius: BorderRadius.circular(
// //                                               14)),
// //                                     ),
// //                                   ),
// //                                   const SizedBox(height: 20),
// //                                   ListTile(
// //                                     title: Text(startDate == null
// //                                         ? "Choisir une date de début"
// //                                         : "Début : ${startDate!
// //                                         .toLocal()
// //                                         .toString()
// //                                         .split(' ')[0]}"),
// //                                     trailing: Icon(Icons.calendar_today,
// //                                         color: primaryViolet),
// //                                     onTap: () async {
// //                                       final picked = await showDatePicker(
// //                                         context: innerContext,
// //                                         initialDate: DateTime.now(),
// //                                         firstDate: DateTime.now(),
// //                                         lastDate: DateTime.now().add(
// //                                             const Duration(days: 365)),
// //                                       );
// //                                       if (picked != null) {
// //                                         setModalState(() => startDate = picked);
// //                                         validateFields(setModalState);
// //                                       }
// //                                     },
// //                                     subtitle: errors['startDate'] != null
// //                                         ? Text(
// //                                         errors['startDate']!, style: TextStyle(
// //                                         color: errorRed, fontSize: 12))
// //                                         : null,
// //                                   ),
// //                                   ListTile(
// //                                     title: Text(endDate == null
// //                                         ? "Choisir une date de fin"
// //                                         : "Fin : ${endDate!
// //                                         .toLocal()
// //                                         .toString()
// //                                         .split(' ')[0]}"),
// //                                     trailing: Icon(Icons.calendar_today,
// //                                         color: primaryViolet),
// //                                     onTap: () async {
// //                                       final picked = await showDatePicker(
// //                                         context: innerContext,
// //                                         initialDate: startDate ??
// //                                             DateTime.now(),
// //                                         firstDate: startDate ?? DateTime.now(),
// //                                         lastDate: DateTime.now().add(
// //                                             const Duration(days: 730)),
// //                                       );
// //                                       if (picked != null) {
// //                                         setModalState(() => endDate = picked);
// //                                         validateFields(setModalState);
// //                                       }
// //                                     },
// //                                     subtitle: errors['endDate'] != null
// //                                         ? Text(
// //                                         errors['endDate']!, style: TextStyle(
// //                                         color: errorRed, fontSize: 12))
// //                                         : null,
// //                                   ),
// //                                   const SizedBox(height: 20),
// //
// //                                   // Afficher le message d'erreur s'il y en a un
// //                                   if (errorMessage != null)
// //                                     Container(
// //                                       padding: const EdgeInsets.all(10),
// //                                       decoration: BoxDecoration(
// //                                         color: errorRed.withOpacity(0.1),
// //                                         borderRadius: BorderRadius.circular(8),
// //                                         border: Border.all(color: errorRed),
// //                                       ),
// //                                       child: Row(
// //                                         children: [
// //                                           Icon(Icons.error_outline,
// //                                               color: errorRed),
// //                                           const SizedBox(width: 10),
// //                                           Expanded(
// //                                             child: Text(
// //                                               errorMessage!,
// //                                               style: TextStyle(color: errorRed),
// //                                             ),
// //                                           ),
// //                                         ],
// //                                       ),
// //                                     ),
// //
// //                                   const SizedBox(height: 20),
// //
// //                                   SizedBox(
// //                                     width: double.infinity,
// //                                     child: ElevatedButton(
// //                                       onPressed: isLoading ? null : () =>
// //                                           submitPromotion(
// //                                               setModalState, innerContext),
// //                                       style: ElevatedButton.styleFrom(
// //                                         backgroundColor: primaryViolet,
// //                                         padding: const EdgeInsets.symmetric(
// //                                             vertical: 16),
// //                                         shape: RoundedRectangleBorder(
// //                                             borderRadius: BorderRadius.circular(
// //                                                 14)),
// //                                       ),
// //                                       child: isLoading
// //                                           ? const CircularProgressIndicator(
// //                                           color: Colors.white)
// //                                           : const Text("Créer la promotion",
// //                                           style: TextStyle(
// //                                               fontWeight: FontWeight.bold)),
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                       ),
// //                     ),
// //               ),
// //         ),
// //   );
// // }