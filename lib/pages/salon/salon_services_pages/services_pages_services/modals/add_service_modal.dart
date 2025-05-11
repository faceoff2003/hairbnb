// importations nécessaires
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> showAddServiceModal(BuildContext context, String coiffeuseId, VoidCallback onSuccess) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  bool isLoading = false;
  final Color primaryViolet = const Color(0xFF7B61FF);

  Widget buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryViolet),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> addService(StateSetter setModalState) async {
    final intitule = nameController.text.trim();
    final description = descriptionController.text.trim();
    final prixText = priceController.text.trim();
    final durationText = durationController.text.trim();

    // Vérifications des champs vides
    if (intitule.isEmpty || description.isEmpty || prixText.isEmpty || durationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs sont obligatoires."), backgroundColor: Colors.red),
      );
      return;
    }

    bool hasAtMostTwoDecimalPlaces(double value) {
      return ((value * 100).roundToDouble() == (value * 100));
    }


    // Vérifications supplémentaires
    if (intitule.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'intitulé ne doit pas dépasser 100 caractères."), backgroundColor: Colors.red),
      );
      return;
    }

    if (description.length > 700) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La description ne doit pas dépasser 700 caractères."), backgroundColor: Colors.red),
      );
      return;
    }

    final double? prix = double.tryParse(prixText);
    final int? temps = int.tryParse(durationText);

    if (prix == null || temps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prix et durée doivent être des nombres valides."), backgroundColor: Colors.red),
      );
      return;
    }

    if (prix > 999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le prix ne doit pas dépasser 999 €."), backgroundColor: Colors.red),
      );
      return;
    }

    if (!hasAtMostTwoDecimalPlaces(prix)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le prix doit avoir au maximum 2 chiffres après la virgule."), backgroundColor: Colors.red),
      );
      return;
    }

    if (temps > 480) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La durée ne doit pas dépasser 8 heures (480 minutes)."), backgroundColor: Colors.red),
      );
      return;
    }

    setModalState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': coiffeuseId,
          'intitule_service': intitule,
          'description': description,
          'prix': prix,
          'temps_minutes': temps,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setModalState(() => isLoading = false);
    }
  }



  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
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
                    const Text("Ajouter un service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 30),
                    buildTextField("Nom du service", nameController, Icons.design_services),
                    buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
                    buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
                    buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => addService(setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryViolet,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Ajouter le service", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}






// // importations nécessaires
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// Future<void> showAddServiceModal(BuildContext context, String coiffeuseId, VoidCallback onSuccess) {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController durationController = TextEditingController();
//   bool isLoading = false;
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color errorRed = Colors.red;
//   final Color successGreen = Colors.green;
//
//   // États de validation
//   Map<String, String?> errors = {
//     'name': null,
//     'description': null,
//     'price': null,
//     'duration': null,
//   };
//
//   Map<String, bool> isValid = {
//     'name': false,
//     'description': false,
//     'price': false,
//     'duration': false,
//   };
//
//   Widget buildTextField(
//       String label,
//       TextEditingController controller,
//       IconData icon,
//       String fieldKey,
//       String? errorText,
//       bool valid,
//       StateSetter setModalState,
//       {
//         TextInputType? keyboardType,
//         int maxLines = 1,
//         Function(String)? onChanged,
//       }
//       ) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TextField(
//             controller: controller,
//             maxLines: maxLines,
//             keyboardType: keyboardType,
//             onChanged: onChanged ?? (value) {},
//             decoration: InputDecoration(
//               prefixIcon: Icon(icon, color: primaryViolet),
//               suffixIcon: errorText != null
//                   ? Icon(Icons.close, color: errorRed)
//                   : (valid ? Icon(Icons.check_circle, color: successGreen) : null),
//               labelText: label,
//               filled: true,
//               fillColor: Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: errorText != null
//                     ? BorderSide(color: errorRed, width: 1)
//                     : (valid ? BorderSide(color: successGreen, width: 1) : BorderSide.none),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: errorText != null
//                     ? BorderSide(color: errorRed, width: 2)
//                     : BorderSide(color: primaryViolet, width: 2),
//               ),
//             ),
//           ),
//           if (errorText != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline, color: errorRed, size: 16),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       errorText,
//                       style: TextStyle(color: errorRed, fontSize: 12),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // Fonction pour vérifier le nombre de décimales
//   bool hasAtMostTwoDecimalPlaces(double value) {
//     return ((value * 100).roundToDouble() == (value * 100));
//   }
//
//   // Fonction pour afficher l'animation de succès
//   void showSuccessAnimation(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
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
//                 Icon(
//                   Icons.check_circle,
//                   color: successGreen,
//                   size: 60,
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Succès!",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // Fonction pour afficher l'animation de succès
//
//
//   // Fonction pour valider les entrées
//   void validateField(String fieldKey, String value, StateSetter setModalState) {
//     switch (fieldKey) {
//       case 'name':
//         if (value.isEmpty) {
//           setModalState(() {
//             errors[fieldKey] = "Le nom du service est obligatoire";
//             isValid[fieldKey] = false;
//           });
//         } else if (value.length > 100) {
//           setModalState(() {
//             errors[fieldKey] = "L'intitulé ne doit pas dépasser 100 caractères";
//             isValid[fieldKey] = false;
//           });
//         } else {
//           setModalState(() {
//             errors[fieldKey] = null;
//             isValid[fieldKey] = true;
//           });
//         }
//         break;
//
//       case 'description':
//         if (value.isEmpty) {
//           setModalState(() {
//             errors[fieldKey] = "La description est obligatoire";
//             isValid[fieldKey] = false;
//           });
//         } else if (value.length > 700) {
//           setModalState(() {
//             errors[fieldKey] = "La description ne doit pas dépasser 700 caractères";
//             isValid[fieldKey] = false;
//           });
//         } else {
//           setModalState(() {
//             errors[fieldKey] = null;
//             isValid[fieldKey] = true;
//           });
//         }
//         break;
//
//       case 'price':
//         if (value.isEmpty) {
//           setModalState(() {
//             errors[fieldKey] = "Le prix est obligatoire";
//             isValid[fieldKey] = false;
//           });
//           return;
//         }
//
//         final double? prix = double.tryParse(value);
//         if (prix == null) {
//           setModalState(() {
//             errors[fieldKey] = "Le prix doit être un nombre valide";
//             isValid[fieldKey] = false;
//           });
//         } else if (prix > 999) {
//           setModalState(() {
//             errors[fieldKey] = "Le prix ne doit pas dépasser 999 €";
//             isValid[fieldKey] = false;
//           });
//         } else if (!hasAtMostTwoDecimalPlaces(prix)) {
//           setModalState(() {
//             errors[fieldKey] = "Le prix doit avoir au maximum 2 chiffres après la virgule";
//             isValid[fieldKey] = false;
//           });
//         } else {
//           setModalState(() {
//             errors[fieldKey] = null;
//             isValid[fieldKey] = true;
//           });
//         }
//         break;
//
//       case 'duration':
//         if (value.isEmpty) {
//           setModalState(() {
//             errors[fieldKey] = "La durée est obligatoire";
//             isValid[fieldKey] = false;
//           });
//           return;
//         }
//
//         final int? temps = int.tryParse(value);
//         if (temps == null) {
//           setModalState(() {
//             errors[fieldKey] = "La durée doit être un nombre entier";
//             isValid[fieldKey] = false;
//           });
//         } else if (temps > 480) {
//           setModalState(() {
//             errors[fieldKey] = "La durée ne doit pas dépasser 8 heures (480 minutes)";
//             isValid[fieldKey] = false;
//           });
//         } else if (temps <= 0) {
//           setModalState(() {
//             errors[fieldKey] = "La durée doit être supérieure à 0";
//             isValid[fieldKey] = false;
//           });
//         } else {
//           setModalState(() {
//             errors[fieldKey] = null;
//             isValid[fieldKey] = true;
//           });
//         }
//         break;
//     }
//   }
//
//   Future<void> addService(StateSetter setModalState) async {
//     final intitule = nameController.text.trim();
//     final description = descriptionController.text.trim();
//     final prixText = priceController.text.trim();
//     final durationText = durationController.text.trim();
//
//     // Valider tous les champs
//     validateField('name', intitule, setModalState);
//     validateField('description', description, setModalState);
//     validateField('price', prixText, setModalState);
//     validateField('duration', durationText, setModalState);
//
//     // Vérifier si tous les champs sont valides
//     if (errors.values.any((error) => error != null)) {
//       return;
//     }
//
//     setModalState(() => isLoading = true);
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'userId': coiffeuseId,
//           'intitule_service': intitule,
//           'description': description,
//           'prix': double.parse(prixText),
//           'temps_minutes': int.parse(durationText),
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         // Afficher l'animation de succès
//         showSuccessAnimation(context);
//
//         // Fermer le modal et appeler la fonction de succès
//         Future.delayed(const Duration(milliseconds: 1500), () {
//           // Fermer d'abord la boîte de dialogue de succès
//           Navigator.of(context).pop();
//           // Puis fermer le modal bottom sheet
//           Navigator.of(context).pop(true);
//           // Enfin appeler la fonction de succès
//           onSuccess();
//         });
//       } else {
//         setModalState(() {
//           isLoading = false;
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: Colors.red),
//           );
//         });
//       }
//     } catch (e) {
//       setModalState(() {
//         isLoading = false;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
//         );
//       });
//     }
//   }
//
//
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setModalState) {
//           return AnimatedPadding(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//             child: DraggableScrollableSheet(
//               initialChildSize: 0.85,
//               maxChildSize: 0.95,
//               minChildSize: 0.5,
//               expand: false,
//               builder: (context, scrollController) => Container(
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF7F7F9),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: ListView(
//                   controller: scrollController,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     const Text("Ajouter un service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
//                     const SizedBox(height: 30),
//
//                     buildTextField(
//                       "Nom du service",
//                       nameController,
//                       Icons.design_services,
//                       'name',
//                       errors['name'],
//                       isValid['name']!,
//                       setModalState,
//                       onChanged: (value) => validateField('name', value, setModalState),
//                     ),
//
//                     buildTextField(
//                       "Description",
//                       descriptionController,
//                       Icons.description,
//                       'description',
//                       errors['description'],
//                       isValid['description']!,
//                       setModalState,
//                       maxLines: 3,
//                       onChanged: (value) => validateField('description', value, setModalState),
//                     ),
//
//                     buildTextField(
//                       "Prix (€)",
//                       priceController,
//                       Icons.euro,
//                       'price',
//                       errors['price'],
//                       isValid['price']!,
//                       setModalState,
//                       keyboardType: TextInputType.number,
//                       onChanged: (value) => validateField('price', value, setModalState),
//                     ),
//
//                     buildTextField(
//                       "Durée (minutes)",
//                       durationController,
//                       Icons.timer,
//                       'duration',
//                       errors['duration'],
//                       isValid['duration']!,
//                       setModalState,
//                       keyboardType: TextInputType.number,
//                       onChanged: (value) => validateField('duration', value, setModalState),
//                     ),
//
//                     const SizedBox(height: 20),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : () => addService(setModalState),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryViolet,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                           elevation: 4,
//                         ),
//                         child: isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : const Text("Ajouter le service", style: TextStyle(fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }




//
//
// // importations nécessaires
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// Future<void> showAddServiceModal(BuildContext context, String coiffeuseId, VoidCallback onSuccess) {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController durationController = TextEditingController();
//   bool isLoading = false;
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   Widget buildTextField(String label, TextEditingController controller, IconData icon,
//       {TextInputType? keyboardType, int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: primaryViolet),
//           labelText: label,
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> addService(StateSetter setModalState) async {
//     final intitule = nameController.text.trim();
//     final description = descriptionController.text.trim();
//     final prixText = priceController.text.trim();
//     final durationText = durationController.text.trim();
//
//     // Vérifications des champs vides
//     if (intitule.isEmpty || description.isEmpty || prixText.isEmpty || durationText.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Tous les champs sont obligatoires."), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     bool _hasAtMostTwoDecimalPlaces(double value) {
//       return ((value * 100).roundToDouble() == (value * 100));
//     }
//
//
//     // Vérifications supplémentaires
//     if (intitule.length > 100) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("L'intitulé ne doit pas dépasser 100 caractères."), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     if (description.length > 700) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("La description ne doit pas dépasser 700 caractères."), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     final double? prix = double.tryParse(prixText);
//     final int? temps = int.tryParse(durationText);
//
//     if (prix == null || temps == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Prix et durée doivent être des nombres valides."), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     if (prix > 999) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Le prix ne doit pas dépasser 999 €."), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     if (!_hasAtMostTwoDecimalPlaces(prix)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Le prix doit avoir au maximum 2 chiffres après la virgule."), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     if (temps > 480) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("La durée ne doit pas dépasser 8 heures (480 minutes)."), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     setModalState(() => isLoading = true);
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'userId': coiffeuseId,
//           'intitule_service': intitule,
//           'description': description,
//           'prix': prix,
//           'temps_minutes': temps,
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         Navigator.pop(context, true);
//         onSuccess();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setModalState(() => isLoading = false);
//     }
//   }
//
//
//
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setModalState) {
//           return AnimatedPadding(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//             child: DraggableScrollableSheet(
//               initialChildSize: 0.85,
//               maxChildSize: 0.95,
//               minChildSize: 0.5,
//               expand: false,
//               builder: (context, scrollController) => Container(
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF7F7F9),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: ListView(
//                   controller: scrollController,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     const Text("Ajouter un service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
//                     const SizedBox(height: 30),
//                     buildTextField("Nom du service", nameController, Icons.design_services),
//                     buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
//                     buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
//                     buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
//                     const SizedBox(height: 20),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : () => addService(setModalState),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryViolet,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                           elevation: 4,
//                         ),
//                         child: isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : const Text("Ajouter le service", style: TextStyle(fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }
