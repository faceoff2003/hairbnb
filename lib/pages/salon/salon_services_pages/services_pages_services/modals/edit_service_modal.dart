import 'package:flutter/material.dart';
import 'package:hairbnb/services/firebase_token/token_service.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../../../models/service_with_promo.dart';

Future<void> showEditServiceModal(BuildContext context, ServiceWithPromo serviceWithPromo, VoidCallback onSuccess) {
  final TextEditingController nameController = TextEditingController(text: serviceWithPromo.intitule);
  final TextEditingController descriptionController = TextEditingController(text: serviceWithPromo.description);
  final TextEditingController priceController = TextEditingController(text: serviceWithPromo.prix.toString());
  final TextEditingController durationController = TextEditingController(text: serviceWithPromo.temps.toString());

  bool isLoading = false;
  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color errorRed = Colors.red;
  final Color successGreen = Colors.green;

  Map<String, String?> errors = {'price': null, 'duration': null};
  Map<String, bool> isValid = {'price': true, 'duration': true};

  bool hasAtMostTwoDecimalPlaces(double value) {
    return ((value * 100).roundToDouble() == (value * 100));
  }

  void showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text("Modifié !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  void validateField(String key, String value, StateSetter setModalState) {
    switch (key) {
      case 'price':
        final parsed = double.tryParse(value);
        if (value.isEmpty) {
          errors[key] = "Prix requis";
          isValid[key] = false;
        } else if (parsed == null) {
          errors[key] = "Nombre invalide";
          isValid[key] = false;
        } else if (parsed <= 0) {
          errors[key] = "Prix doit être positif";
          isValid[key] = false;
        } else if (parsed > 999) {
          errors[key] = "Maximum 999€";
          isValid[key] = false;
        } else if (!hasAtMostTwoDecimalPlaces(parsed)) {
          errors[key] = "Max 2 décimales";
          isValid[key] = false;
        } else {
          errors[key] = null;
          isValid[key] = true;
        }
        break;

      case 'duration':
        final parsed = int.tryParse(value);
        if (value.isEmpty) {
          errors[key] = "Durée requise";
          isValid[key] = false;
        } else if (parsed == null || parsed <= 0) {
          errors[key] = "Durée invalide";
          isValid[key] = false;
        } else if (parsed > 480) {
          errors[key] = "Max 480 minutes";
          isValid[key] = false;
        } else {
          errors[key] = null;
          isValid[key] = true;
        }
        break;
    }

    setModalState(() {});
  }

  Widget buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      String fieldKey,
      StateSetter setModalState, {
        TextInputType? keyboardType,
        int maxLines = 1,
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: readOnly ? null : (val) => validateField(fieldKey, val, setModalState),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryViolet),
              suffixIcon: readOnly
                  ? null
                  : errors[fieldKey] != null
                  ? Icon(Icons.close, color: errorRed)
                  : (isValid[fieldKey]! ? Icon(Icons.check_circle, color: successGreen) : null),
              labelText: label,
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: readOnly
                    ? BorderSide.none
                    : errors[fieldKey] != null
                    ? BorderSide(color: errorRed)
                    : (isValid[fieldKey]! ? BorderSide(color: successGreen) : BorderSide.none),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryViolet, width: 2),
              ),
            ),
          ),
          if (!readOnly && errors[fieldKey] != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: errorRed, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(errors[fieldKey]!, style: TextStyle(color: errorRed, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> updateService(StateSetter setModalState) async {
    final prixText = priceController.text.trim();
    final durationText = durationController.text.trim();

    // Validation uniquement pour prix et durée
    validateField('price', prixText, setModalState);
    validateField('duration', durationText, setModalState);

    // Vérifie les erreurs uniquement pour les champs modifiables
    if (errors['price'] != null || errors['duration'] != null) return;

    setModalState(() => isLoading = true);

    try {
      // Récupération de l'utilisateur connecté
      final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur: Utilisateur non connecté"),
              backgroundColor: Colors.red
          ),
        );
        return;
      }

      // Récupération du token d'authentification
      final authToken = await TokenService.getAuthToken();

      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur: Token d'authentification non trouvé"),
              backgroundColor: Colors.red
          ),
        );
        return;
      }

      final response = await http.put(
        Uri.parse('https://www.hairbnb.site/api/update_service/${serviceWithPromo.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'userId': currentUser.idTblUser,
          'prix': double.parse(prixText),
          'temps_minutes': int.parse(durationText),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          showSuccessAnimation(context);
          Future.delayed(const Duration(milliseconds: 1500), () {
            Navigator.of(context).pop(); // success modal
            Navigator.of(context).pop(true); // bottom sheet
            onSuccess();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Erreur: ${responseData['message'] ?? 'Erreur inconnue'}"),
                backgroundColor: Colors.red
            ),
          );
        }
      } else {
        // Gestion des erreurs de validation du backend
        try {
          final errorData = json.decode(response.body);
          String errorMessage = "Erreur inconnue";

          if (errorData.containsKey('errors')) {
            final errors = errorData['errors'];
            if (errors is Map) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else {
                errorMessage = firstError.toString();
              }
            }
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Erreur: $errorMessage"),
                backgroundColor: Colors.red
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Erreur ${response.statusCode}: ${response.body}"),
                backgroundColor: Colors.red
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur de connexion: $e"),
            backgroundColor: Colors.red
        ),
      );
    } finally {
      setModalState(() => isLoading = false);
    }
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
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
                const Text("Modifier le service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 30),
                buildTextField("Nom du service", nameController, Icons.design_services, 'name', setModalState, readOnly: true),
                buildTextField("Description", descriptionController, Icons.description, 'description', setModalState, maxLines: 3, readOnly: true),
                buildTextField("Prix (€)", priceController, Icons.euro, 'price', setModalState, keyboardType: TextInputType.number),
                buildTextField("Durée (minutes)", durationController, Icons.timer, 'duration', setModalState, keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : () => updateService(setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryViolet,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}











// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../../../models/service_with_promo.dart';
//
// Future<void> showEditServiceModal(BuildContext context, ServiceWithPromo serviceWithPromo, VoidCallback onSuccess) {
//   final TextEditingController nameController = TextEditingController(text: serviceWithPromo.intitule);
//   final TextEditingController descriptionController = TextEditingController(text: serviceWithPromo.description);
//   final TextEditingController priceController = TextEditingController(text: serviceWithPromo.prix.toString());
//   final TextEditingController durationController = TextEditingController(text: serviceWithPromo.temps.toString());
//
//   bool isLoading = false;
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color errorRed = Colors.red;
//   final Color successGreen = Colors.green;
//
//   Map<String, String?> errors = {'name': null, 'description': null, 'price': null, 'duration': null};
//   Map<String, bool> isValid = {'name': true, 'description': true, 'price': true, 'duration': true};
//
//   bool hasAtMostTwoDecimalPlaces(double value) {
//     return ((value * 100).roundToDouble() == (value * 100));
//   }
//
//   void showSuccessAnimation(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Dialog(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         child: Container(
//           width: 100,
//           height: 100,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               Icon(Icons.check_circle, color: Colors.green, size: 60),
//               SizedBox(height: 10),
//               Text("Modifié !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void validateField(String key, String value, StateSetter setModalState) {
//     switch (key) {
//       case 'name':
//         if (value.isEmpty) {
//           errors[key] = "Le nom est obligatoire";
//           isValid[key] = false;
//         } else if (value.length > 100) {
//           errors[key] = "Maximum 100 caractères";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//
//       case 'description':
//         if (value.isEmpty) {
//           errors[key] = "Description requise";
//           isValid[key] = false;
//         } else if (value.length > 700) {
//           errors[key] = "Maximum 700 caractères";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//
//       case 'price':
//         final parsed = double.tryParse(value);
//         if (value.isEmpty) {
//           errors[key] = "Prix requis";
//           isValid[key] = false;
//         } else if (parsed == null) {
//           errors[key] = "Nombre invalide";
//           isValid[key] = false;
//         } else if (parsed > 999) {
//           errors[key] = "Maximum 999€";
//           isValid[key] = false;
//         } else if (!hasAtMostTwoDecimalPlaces(parsed)) {
//           errors[key] = "Max 2 décimales";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//
//       case 'duration':
//         final parsed = int.tryParse(value);
//         if (value.isEmpty) {
//           errors[key] = "Durée requise";
//           isValid[key] = false;
//         } else if (parsed == null || parsed <= 0) {
//           errors[key] = "Durée invalide";
//           isValid[key] = false;
//         } else if (parsed > 480) {
//           errors[key] = "Max 480 minutes";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//     }
//
//     setModalState(() {});
//   }
//
//   // MODIFICATION 1: Ajout du paramètre `readOnly` pour contrôler si le champ est modifiable.
//   Widget buildTextField(
//       String label,
//       TextEditingController controller,
//       IconData icon,
//       String fieldKey,
//       StateSetter setModalState, {
//         TextInputType? keyboardType,
//         int maxLines = 1,
//         bool readOnly = false, // Nouveau paramètre
//       }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TextField(
//             controller: controller,
//             maxLines: maxLines,
//             keyboardType: keyboardType,
//             readOnly: readOnly, // Applique l'état de lecture seule
//             onChanged: readOnly ? null : (val) => validateField(fieldKey, val, setModalState),
//             decoration: InputDecoration(
//               prefixIcon: Icon(icon, color: primaryViolet),
//               // MODIFICATION 2: Cache l'icône de suffixe pour les champs en lecture seule.
//               suffixIcon: readOnly
//                   ? null
//                   : errors[fieldKey] != null
//                   ? Icon(Icons.close, color: errorRed)
//                   : (isValid[fieldKey]! ? Icon(Icons.check_circle, color: successGreen) : null),
//               labelText: label,
//               filled: true,
//               // MODIFICATION 3: Change la couleur de fond pour indiquer visuellement que le champ est non modifiable.
//               fillColor: readOnly ? Colors.grey[200] : Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: readOnly
//                     ? BorderSide.none
//                     : errors[fieldKey] != null
//                     ? BorderSide(color: errorRed)
//                     : (isValid[fieldKey]! ? BorderSide(color: successGreen) : BorderSide.none),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide(color: primaryViolet, width: 2),
//               ),
//             ),
//           ),
//           // MODIFICATION 4: N'affiche pas les messages d'erreur pour les champs en lecture seule.
//           if (!readOnly && errors[fieldKey] != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 12, top: 4),
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline, color: errorRed, size: 16),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(errors[fieldKey]!, style: TextStyle(color: errorRed, fontSize: 12)),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> updateService(StateSetter setModalState) async {
//     final name = nameController.text.trim();
//     final desc = descriptionController.text.trim();
//     final prixText = priceController.text.trim();
//     final durationText = durationController.text.trim();
//
//     // MODIFICATION 5: Suppression de la validation pour le nom et la description.
//     // Seuls le prix et la durée sont validés avant l'envoi.
//     validateField('price', prixText, setModalState);
//     validateField('duration', durationText, setModalState);
//
//     // Vérifie les erreurs uniquement pour les champs modifiables.
//     if (errors['price'] != null || errors['duration'] != null) return;
//
//     setModalState(() => isLoading = true);
//
//     try {
//       final response = await http.put(
//         Uri.parse('https://www.hairbnb.site/api/update_service/${serviceWithPromo.id}/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           // Les valeurs du nom et de la description sont toujours envoyées,
//           // mais elles proviennent des contrôleurs non modifiés.
//           'intitule_service': name,
//           'description': desc,
//           'prix': double.parse(prixText),
//           'temps_minutes': int.parse(durationText),
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         showSuccessAnimation(context);
//         Future.delayed(const Duration(milliseconds: 1500), () {
//           Navigator.of(context).pop(); // success modal
//           Navigator.of(context).pop(true); // bottom sheet
//           onSuccess();
//         });
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
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) => AnimatedPadding(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//         padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//         child: DraggableScrollableSheet(
//           expand: false,
//           initialChildSize: 0.85,
//           maxChildSize: 0.95,
//           minChildSize: 0.5,
//           builder: (context, scrollController) => Container(
//             padding: const EdgeInsets.all(20),
//             decoration: const BoxDecoration(
//               color: Color(0xFFF7F7F9),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//             child: ListView(
//               controller: scrollController,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 5,
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//                 const Text("Modifier le service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
//                 const SizedBox(height: 30),
//                 // MODIFICATION 6: Les champs pour le nom et la description sont maintenant en lecture seule.
//                 buildTextField("Nom du service", nameController, Icons.design_services, 'name', setModalState, readOnly: true),
//                 buildTextField("Description", descriptionController, Icons.description, 'description', setModalState, maxLines: 3, readOnly: true),
//                 buildTextField("Prix (€)", priceController, Icons.euro, 'price', setModalState, keyboardType: TextInputType.number),
//                 buildTextField("Durée (minutes)", durationController, Icons.timer, 'duration', setModalState, keyboardType: TextInputType.number),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: isLoading ? null : () => updateService(setModalState),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryViolet,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                     elevation: 4,
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }







// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../../../models/service_with_promo.dart';
//
// Future<void> showEditServiceModal(BuildContext context,ServiceWithPromo serviceWithPromo, VoidCallback onSuccess) {
//   final TextEditingController nameController = TextEditingController(text: serviceWithPromo.intitule);
//   final TextEditingController descriptionController = TextEditingController(text: serviceWithPromo.description);
//   final TextEditingController priceController = TextEditingController(text: serviceWithPromo.prix.toString());
//   final TextEditingController durationController = TextEditingController(text: serviceWithPromo.temps.toString());
//
//   bool isLoading = false;
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color errorRed = Colors.red;
//   final Color successGreen = Colors.green;
//
//   Map<String, String?> errors = {'name': null, 'description': null, 'price': null, 'duration': null};
//   Map<String, bool> isValid = {'name': true, 'description': true, 'price': true, 'duration': true};
//
//   bool hasAtMostTwoDecimalPlaces(double value) {
//     return ((value * 100).roundToDouble() == (value * 100));
//   }
//
//   void showSuccessAnimation(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Dialog(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         child: Container(
//           width: 100,
//           height: 100,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               Icon(Icons.check_circle, color: Colors.green, size: 60),
//               SizedBox(height: 10),
//               Text("Modifié !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void validateField(String key, String value, StateSetter setModalState) {
//     switch (key) {
//       case 'name':
//         if (value.isEmpty) {
//           errors[key] = "Le nom est obligatoire";
//           isValid[key] = false;
//         } else if (value.length > 100) {
//           errors[key] = "Maximum 100 caractères";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//
//       case 'description':
//         if (value.isEmpty) {
//           errors[key] = "Description requise";
//           isValid[key] = false;
//         } else if (value.length > 700) {
//           errors[key] = "Maximum 700 caractères";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//
//       case 'price':
//         final parsed = double.tryParse(value);
//         if (value.isEmpty) {
//           errors[key] = "Prix requis";
//           isValid[key] = false;
//         } else if (parsed == null) {
//           errors[key] = "Nombre invalide";
//           isValid[key] = false;
//         } else if (parsed > 999) {
//           errors[key] = "Maximum 999€";
//           isValid[key] = false;
//         } else if (!hasAtMostTwoDecimalPlaces(parsed)) {
//           errors[key] = "Max 2 décimales";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//
//       case 'duration':
//         final parsed = int.tryParse(value);
//         if (value.isEmpty) {
//           errors[key] = "Durée requise";
//           isValid[key] = false;
//         } else if (parsed == null || parsed <= 0) {
//           errors[key] = "Durée invalide";
//           isValid[key] = false;
//         } else if (parsed > 480) {
//           errors[key] = "Max 480 minutes";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//     }
//
//     setModalState(() {});
//   }
//
//   Widget buildTextField(
//       String label,
//       TextEditingController controller,
//       IconData icon,
//       String fieldKey,
//       StateSetter setModalState, {
//         TextInputType? keyboardType,
//         int maxLines = 1,
//       }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TextField(
//             controller: controller,
//             maxLines: maxLines,
//             keyboardType: keyboardType,
//             onChanged: (val) => validateField(fieldKey, val, setModalState),
//             decoration: InputDecoration(
//               prefixIcon: Icon(icon, color: primaryViolet),
//               suffixIcon: errors[fieldKey] != null
//                   ? Icon(Icons.close, color: errorRed)
//                   : (isValid[fieldKey]! ? Icon(Icons.check_circle, color: successGreen) : null),
//               labelText: label,
//               filled: true,
//               fillColor: Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: errors[fieldKey] != null
//                     ? BorderSide(color: errorRed)
//                     : (isValid[fieldKey]! ? BorderSide(color: successGreen) : BorderSide.none),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide(color: primaryViolet, width: 2),
//               ),
//             ),
//           ),
//           if (errors[fieldKey] != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 12, top: 4),
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline, color: errorRed, size: 16),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(errors[fieldKey]!, style: TextStyle(color: errorRed, fontSize: 12)),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> updateService(StateSetter setModalState) async {
//     final name = nameController.text.trim();
//     final desc = descriptionController.text.trim();
//     final prixText = priceController.text.trim();
//     final durationText = durationController.text.trim();
//
//     validateField('name', name, setModalState);
//     validateField('description', desc, setModalState);
//     validateField('price', prixText, setModalState);
//     validateField('duration', durationText, setModalState);
//
//     if (errors.values.any((e) => e != null)) return;
//
//     setModalState(() => isLoading = true);
//
//     try {
//       final response = await http.put(
//         Uri.parse('https://www.hairbnb.site/api/update_service/${serviceWithPromo.id}/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'intitule_service': name,
//           'description': desc,
//           'prix': double.parse(prixText),
//           'temps_minutes': int.parse(durationText),
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         showSuccessAnimation(context);
//         Future.delayed(const Duration(milliseconds: 1500), () {
//           Navigator.of(context).pop(); // success modal
//           Navigator.of(context).pop(true); // bottom sheet
//           onSuccess();
//         });
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
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) => AnimatedPadding(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//         padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//         child: DraggableScrollableSheet(
//           expand: false,
//           initialChildSize: 0.85,
//           maxChildSize: 0.95,
//           minChildSize: 0.5,
//           builder: (context, scrollController) => Container(
//             padding: const EdgeInsets.all(20),
//             decoration: const BoxDecoration(
//               color: Color(0xFFF7F7F9),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//             child: ListView(
//               controller: scrollController,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 5,
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//                 const Text("Modifier le service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
//                 const SizedBox(height: 30),
//                 buildTextField("Nom du service", nameController, Icons.design_services, 'name', setModalState),
//                 buildTextField("Description", descriptionController, Icons.description, 'description', setModalState, maxLines: 3),
//                 buildTextField("Prix (€)", priceController, Icons.euro, 'price', setModalState, keyboardType: TextInputType.number),
//                 buildTextField("Durée (minutes)", durationController, Icons.timer, 'duration', setModalState, keyboardType: TextInputType.number),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: isLoading ? null : () => updateService(setModalState),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryViolet,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                     elevation: 4,
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }
