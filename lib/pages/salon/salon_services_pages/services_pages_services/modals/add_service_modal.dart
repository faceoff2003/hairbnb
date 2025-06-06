import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../../services/firebase_token/token_service.dart';

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
      // Utiliser TokenService au lieu de Firebase Auth directement
      final String? idToken = await TokenService.getAuthToken();

      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur d'authentification. Veuillez vous reconnecter."),
            backgroundColor: Colors.red,
          ),
        );
        setModalState(() => isLoading = false);
        return;
      }

      if (kDebugMode) {
        print("Envoi de la requête avec token authentifié");
      }

      // Envoyer la requête avec le token d'authentification
      final response = await http.post(
        Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'userId': coiffeuseId,
          'intitule_service': intitule,
          'description': description,
          'prix': prix,
          'temps_minutes': temps,
        }),
      );

      // Log de debug
      if (kDebugMode) {
        print("Status code: ${response.statusCode}");
        print("Réponse: ${response.body}");
      }

      // Analyser la réponse
      if (response.statusCode == 201) {
        // Fermer la modal et appeler le callback de succès
        Navigator.pop(context, true);
        onSuccess();
      } else {
        // Traiter les différents codes d'erreur
        Map<String, dynamic> errorResponse = {};
        try {
          errorResponse = json.decode(response.body);
        } catch (e) {
          // Si la réponse n'est pas du JSON valide
        }

        String errorMessage = errorResponse['message'] ??
            errorResponse['detail'] ??
            "Erreur lors de l'ajout du service (${response.statusCode})";

        // Si erreur d'authentification, effacer le token
        if (response.statusCode == 401) {
          await TokenService.clearAuthToken();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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




// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
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
//     bool hasAtMostTwoDecimalPlaces(double value) {
//       return ((value * 100).roundToDouble() == (value * 100));
//     }
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
//     if (!hasAtMostTwoDecimalPlaces(prix)) {
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
//       // Obtenir le token d'authentification Firebase
//       final User? currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Vous devez être connecté pour effectuer cette action."), backgroundColor: Colors.red),
//         );
//         setModalState(() => isLoading = false);
//         return;
//       }
//
//       final String? idToken = await currentUser.getIdToken();
//       if (idToken == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erreur d'authentification. Veuillez vous reconnecter."), backgroundColor: Colors.red),
//         );
//         setModalState(() => isLoading = false);
//         return;
//       }
//
//       // Envoyer la requête avec le token d'authentification
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $idToken',
//         },
//         body: json.encode({
//           'userId': coiffeuseId,
//           'intitule_service': intitule,
//           'description': description,
//           'prix': prix,
//           'temps_minutes': temps,
//         }),
//       );
//
//       // Analyser la réponse
//       if (response.statusCode == 201) {
//         // Fermer la modal et appeler le callback de succès
//         Navigator.pop(context, true);
//         onSuccess();
//       } else {
//         // Traiter les différents codes d'erreur
//         Map<String, dynamic> errorResponse = {};
//         try {
//           errorResponse = json.decode(response.body);
//         } catch (e) {
//           // Si la réponse n'est pas du JSON valide
//         }
//
//         String errorMessage = errorResponse['message'] ??
//             errorResponse['detail'] ??
//             "Erreur lors de l'ajout du service (${response.statusCode})";
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
//     bool hasAtMostTwoDecimalPlaces(double value) {
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
//     if (!hasAtMostTwoDecimalPlaces(prix)) {
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