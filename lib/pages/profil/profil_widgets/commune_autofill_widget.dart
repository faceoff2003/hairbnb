import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CommuneAutoFill extends StatefulWidget {
  final TextEditingController codePostalController;
  final TextEditingController communeController;
  final String geoapifyApiKey;
  final VoidCallback? onCommuneFound; // Nouveau callback si la commune est trouvée
  final VoidCallback? onCommuneNotFound; // Nouveau callback si la commune n'est pas trouvée

  const CommuneAutoFill({
    super.key,
    required this.codePostalController,
    required this.communeController,
    required this.geoapifyApiKey,
    this.onCommuneFound,
    this.onCommuneNotFound,
  });

  @override
  State<CommuneAutoFill> createState() => _CommuneAutoFillState();
}

class _CommuneAutoFillState extends State<CommuneAutoFill> {
  Future<void> fetchCommune(String codePostal) async {
    // Si le code postal est vide ou trop court, vider la commune et signaler qu'elle n'est pas trouvée.
    if (codePostal.isEmpty || codePostal.length < 4) {
      if (mounted) { // Vérifier si le widget est monté avant setState
        setState(() {
          widget.communeController.text = "";
        });
      }
      widget.onCommuneNotFound?.call(); // Appeler le callback de non-trouvé
      return;
    }

    // Construction de l'URL pour l'API Geoapify Geocoding (recherche par code postal).
    final url = Uri.parse(
        "https://api.geoapify.com/v1/geocode/search?postcode=$codePostal&lang=fr&limit=1&apiKey=${widget.geoapifyApiKey}");

    if (kDebugMode) {
      print("Geoapify - Requête Commune URL: $url");
    }

    try {
      final response = await http.get(url);

      if (kDebugMode) {
        print("Geoapify - Réponse Commune Statut: ${response.statusCode}");
        print("Geoapify - Réponse Commune Corps: ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Vérifier si des fonctionnalités (résultats) sont présentes.
        if (data['features'] != null && data['features'].isNotEmpty) {
          final properties = data['features'][0]['properties'];
          if (mounted) { // Vérifier si le widget est monté avant setState
            // Extraire le nom de la ville/commune en utilisant différentes propriétés comme fallback.
            final String communeName = properties['city'] ??
                properties['town'] ??
                properties['village'] ??
                properties['county'] ?? // Ajout de 'county' comme fallback
                "Commune introuvable";

            setState(() {
              widget.communeController.text = communeName;
            });
            // Appeler le callback approprié en fonction du résultat.
            if (communeName != "Commune introuvable") {
              widget.onCommuneFound?.call();
            } else {
              widget.onCommuneNotFound?.call();
            }
          }
        } else {
          // Si aucune fonctionnalité n'est trouvée, signaler que la commune est introuvable.
          if (mounted) { // Vérifier si le widget est monté avant setState
            setState(() {
              widget.communeController.text = "Commune introuvable";
            });
          }
          widget.onCommuneNotFound?.call();
        }
      } else {
        // Gérer les erreurs de l'API (codes de statut non-200).
        debugPrint("Erreur API Geoapify (Commune - ${response.statusCode}): ${response.body}");
        if (mounted) { // Vérifier si le widget est monté avant setState
          setState(() {
            widget.communeController.text = "Erreur de recherche";
          });
        }
        widget.onCommuneNotFound?.call();
      }
    } catch (e) {
      // Gérer les erreurs de connexion réseau.
      debugPrint("Erreur de connexion Geoapify (Commune) : $e");
      if (mounted) { // Vérifier si le widget est monté avant setState
        setState(() {
          widget.communeController.text = "Erreur réseau";
        });
      }
      widget.onCommuneNotFound?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.codePostalController,
      keyboardType: TextInputType.number, // Clavier numérique pour le code postal
      decoration: const InputDecoration(
        labelText: "Code Postal",
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => fetchCommune(value), // Appeler fetchCommune à chaque changement de texte
    );
  }
}





// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
//
// class CommuneAutoFill extends StatefulWidget {
//   final TextEditingController codePostalController;
//   final TextEditingController communeController;
//   final String geoapifyApiKey;
//
//   const CommuneAutoFill({
//     super.key,
//     required this.codePostalController,
//     required this.communeController,
//     required this.geoapifyApiKey,
//   });
//
//   @override
//   State<CommuneAutoFill> createState() => _CommuneAutoFillState();
// }
//
// class _CommuneAutoFillState extends State<CommuneAutoFill> {
//   Future<void> fetchCommune(String codePostal) async {
//     if (codePostal.isEmpty || codePostal.length < 4) {
//       if (mounted) { // Vérifier si le widget est monté avant setState
//         setState(() {
//           widget.communeController.text = "";
//         });
//       }
//       return;
//     }
//
//     final url = Uri.parse(
//         "https://api.geoapify.com/v1/geocode/search?postcode=$codePostal&lang=fr&limit=1&apiKey=${widget.geoapifyApiKey}");
//
//     if (kDebugMode) {
//       print("Geoapify - Requête Commune URL: $url");
//     }
//
//     try {
//       final response = await http.get(url);
//
//       if (kDebugMode) {
//         print("Geoapify - Réponse Commune Statut: ${response.statusCode}");
//         print("Geoapify - Réponse Commune Corps: ${response.body}");
//       }
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           final properties = data['features'][0]['properties'];
//           if (mounted) { // Vérifier si le widget est monté avant setState
//             setState(() {
//               widget.communeController.text = properties['city'] ??
//                   properties['town'] ??
//                   properties['village'] ??
//                   properties['county'] ?? // Ajout de 'county' comme fallback
//                   "Commune introuvable";
//             });
//           }
//         } else {
//           if (mounted) { // Vérifier si le widget est monté avant setState
//             setState(() {
//               widget.communeController.text = "Commune introuvable";
//             });
//           }
//         }
//       } else {
//         debugPrint("Erreur API Geoapify (Commune - ${response.statusCode}): ${response.body}");
//         if (mounted) { // Vérifier si le widget est monté avant setState
//           setState(() {
//             widget.communeController.text = "Erreur de recherche";
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion Geoapify (Commune) : $e");
//       if (mounted) { // Vérifier si le widget est monté avant setState
//         setState(() {
//           widget.communeController.text = "Erreur réseau";
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: widget.codePostalController,
//       keyboardType: TextInputType.number,
//       decoration: const InputDecoration(
//         labelText: "Code Postal",
//         border: OutlineInputBorder(),
//       ),
//       onChanged: (value) => fetchCommune(value),
//     );
//   }
// }
//
//
//
//
//
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
//
//
//
//
// // import 'package:http/http.dart' as http;
// //
// // class CommuneAutoFill extends StatefulWidget {
// //   final TextEditingController codePostalController;
// //   final TextEditingController communeController;
// //
// //   const CommuneAutoFill({
// //     super.key,
// //     required this.codePostalController,
// //     required this.communeController,
// //   });
// //
// //   @override
// //   State<CommuneAutoFill> createState() => _CommuneAutoFillState();
// // }
// //
// // class _CommuneAutoFillState extends State<CommuneAutoFill> {
// //   Future<void> fetchCommune(String codePostal) async {
// //     if (codePostal.isEmpty) return;
// //
// //     final url = Uri.parse("https://api-adresse-belgique.be/commune?code_postal=$codePostal");
// //
// //     try {
// //       final response = await http.get(url);
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         if (data['commune'] != null) {
// //           setState(() {
// //             widget.communeController.text = data['commune'];
// //           });
// //         }
// //       } else {
// //         widget.communeController.text = "";
// //       }
// //     } catch (e) {
// //       debugPrint("Erreur : $e");
// //       widget.communeController.text = "";
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return TextField(
// //       controller: widget.codePostalController,
// //       keyboardType: TextInputType.number,
// //       decoration: const InputDecoration(
// //         labelText: "Code Postal",
// //         border: OutlineInputBorder(),
// //       ),
// //       onChanged: (value) => fetchCommune(value),
// //     );
// //   }
// // }
