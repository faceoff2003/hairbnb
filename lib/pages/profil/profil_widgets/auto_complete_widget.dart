import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class StreetAutocomplete extends StatefulWidget {
  final TextEditingController streetController;
  final TextEditingController communeController;
  final TextEditingController codePostalController;
  final String geoapifyApiKey;
  final VoidCallback? onStreetSelected; // Nouveau callback pour la sélection
  final VoidCallback? onStreetChanged;  // Nouveau callback pour les changements de texte

  const StreetAutocomplete({
    super.key,
    required this.streetController,
    required this.communeController,
    required this.codePostalController,
    required this.geoapifyApiKey,
    this.onStreetSelected,
    this.onStreetChanged,
  });

  @override
  State<StreetAutocomplete> createState() => _StreetAutocompleteState();
}

class _StreetAutocompleteState extends State<StreetAutocomplete> {
  // La liste de suggestions est gérée par Autocomplete lui-même via Future.
  // Plus besoin d'un setState pour les suggestions ici.
  Future<Iterable<String>> fetchStreetSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      return const Iterable<String>.empty();
    }

    // Construire la requête pour Geoapify Autocomplete avec filtrage par commune et code postal.
    String searchQuery = query;

    // Ajouter la commune et le code postal pour améliorer la recherche.
    if (widget.communeController.text.isNotEmpty) {
      searchQuery += ", ${widget.communeController.text}";
    }
    if (widget.codePostalController.text.isNotEmpty) {
      searchQuery += ", ${widget.codePostalController.text}";
    }
    searchQuery += ", Belgium"; // Limiter à la Belgique

    String urlString = "https://api.geoapify.com/v1/geocode/autocomplete"
        "?text=${Uri.encodeComponent(searchQuery)}"
        "&type=street" // Rechercher uniquement les rues
        "&filter=countrycode:be" // Filtrer par code de pays (Belgique)
        "&limit=8" // Limiter le nombre de résultats
        "&lang=fr" // Langue des résultats (français)
        "&apiKey=${widget.geoapifyApiKey}"; // Clé API Geoapify

    final url = Uri.parse(urlString);

    if (kDebugMode) {
      print("Geoapify - Requête Rue URL: $url");
    }

    try {
      final response = await http.get(url);

      if (kDebugMode) {
        print("Geoapify - Réponse Rue Statut: ${response.statusCode}");
        print("Geoapify - Réponse Rue Corps: ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          // Extraire les noms de rues uniques
          Set<String> uniqueStreets = {};

          for (var feature in data['features']) {
            final properties = feature['properties'];

            // Essayer différents champs pour obtenir le nom de la rue (priorité à 'street', puis 'address_line1', puis 'name')
            String? street = properties['street'] ??
                properties['address_line1'] ??
                properties['name'];

            if (street != null && street.isNotEmpty) {
              // Nettoyer le nom de la rue (enlever les numéros s'il y en a)
              street = _cleanStreetName(street);
              if (street.isNotEmpty) {
                uniqueStreets.add(street);
              }
            }
          }
          return uniqueStreets;
        } else {
          return const Iterable<String>.empty();
        }
      } else {
        debugPrint("Erreur API Geoapify (Rue - ${response.statusCode}): ${response.body}");
        return const Iterable<String>.empty();
      }
    } catch (e) {
      debugPrint("Erreur de connexion Geoapify (Rue) : $e");
      return const Iterable<String>.empty();
    }
  }

  // Méthode pour nettoyer le nom de la rue (enlever les numéros de maison)
  String _cleanStreetName(String street) {
    // Supprimer les numéros au début ou à la fin de la chaîne, ainsi que les numéros avec lettres (ex: 12A)
    return street.replaceAll(RegExp(r'^\d+\s*'), '') // Numéros au début
        .replaceAll(RegExp(r'\s*\d+$'), '') // Numéros à la fin
        .replaceAll(RegExp(r'^\d+[a-zA-Z]?\s*'), '') // Numéros avec lettres au début
        .trim(); // Supprimer les espaces en début et fin
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        // Appeler le callback lorsque le texte change (l'utilisateur tape)
        // Note: Ce callback est appelé à chaque frappe dans Autocomplete.
        widget.onStreetChanged?.call();

        // optionsBuilder doit retourner un Future<Iterable<String>>.
        // Appelle la fonction asynchrone fetchStreetSuggestions.
        return fetchStreetSuggestions(textEditingValue.text);
      },
      onSelected: (String selection) {
        // Cette méthode est appelée lorsqu'une suggestion est sélectionnée par l'utilisateur.
        widget.streetController.text = selection; // Mettre à jour le contrôleur externe
        widget.onStreetSelected?.call(); // Appeler le callback pour indiquer qu'une rue a été sélectionnée.

        if (kDebugMode) {
          print("Rue sélectionnée: $selection");
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        // Ne PAS modifier controller.text ici. Laissez Autocomplete gérer son contrôleur interne.
        // Utilisez simplement le 'controller' fourni par Autocomplete pour le TextField.

        return TextField(
          controller: controller, // Utilisez le contrôleur fourni par Autocomplete
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            labelText: "Tapez le nom de votre rue",
            hintText: "Ex: Rue de la Paix, Avenue Louise...",
            prefixIcon: Icon(Icons.search, color: Color(0xFF8E44AD)), // Icône de recherche
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF8E44AD), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
          // Mettre à jour le contrôleur externe UNIQUEMENT lorsque le texte change.
          // C'est ainsi que widget.streetController.text reste synchronisé.
          onChanged: (text) {
            widget.streetController.text = text;
            widget.onStreetChanged?.call();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        // Personnaliser l'apparence des suggestions.
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4, // Ombre portée
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200, // Hauteur maximale de la liste des suggestions
                maxWidth: MediaQuery.of(context).size.width - 32, // Largeur basée sur l'écran
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    leading: Icon(Icons.location_on, // Icône de localisation
                        color: Color(0xFF8E44AD),
                        size: 20),
                    title: Text(
                      option,
                      style: TextStyle(fontSize: 14),
                    ),
                    dense: true, // Rendre la liste plus compacte
                    onTap: () => onSelected(option), // Appeler onSelected quand un élément est tapé
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}






// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
//
// class StreetAutocomplete extends StatefulWidget {
//   final TextEditingController streetController;
//   final TextEditingController communeController;
//   final TextEditingController codePostalController;
//   final String geoapifyApiKey;
//   final VoidCallback? onStreetSelected; // Nouveau callback
//   final VoidCallback? onStreetChanged;  // Nouveau callback
//
//   const StreetAutocomplete({
//     super.key,
//     required this.streetController,
//     required this.communeController,
//     required this.codePostalController,
//     required this.geoapifyApiKey,
//     this.onStreetSelected,
//     this.onStreetChanged,
//   });
//
//   @override
//   State<StreetAutocomplete> createState() => _StreetAutocompleteState();
// }
//
// class _StreetAutocompleteState extends State<StreetAutocomplete> {
//   // La liste de suggestions est maintenant gérée par Autocomplete lui-même via Future
//   // Plus besoin de setState ici pour les suggestions
//   Future<Iterable<String>> fetchStreetSuggestions(String query) async {
//     if (query.isEmpty || query.length < 2) {
//       return const Iterable<String>.empty();
//     }
//
//     // Construire la requête pour Geoapify Autocomplete avec filtrage par commune et code postal
//     String searchQuery = query;
//
//     // Ajouter la commune et le code postal pour améliorer la recherche
//     if (widget.communeController.text.isNotEmpty) {
//       searchQuery += ", ${widget.communeController.text}";
//     }
//     if (widget.codePostalController.text.isNotEmpty) {
//       searchQuery += ", ${widget.codePostalController.text}";
//     }
//     searchQuery += ", Belgium";
//
//     String urlString = "https://api.geoapify.com/v1/geocode/autocomplete"
//         "?text=${Uri.encodeComponent(searchQuery)}"
//         "&type=street"
//         "&filter=countrycode:be"
//         "&limit=8"
//         "&lang=fr"
//         "&apiKey=${widget.geoapifyApiKey}";
//
//     final url = Uri.parse(urlString);
//
//     if (kDebugMode) {
//       print("Geoapify - Requête Rue URL: $url");
//     }
//
//     try {
//       final response = await http.get(url);
//
//       if (kDebugMode) {
//         print("Geoapify - Réponse Rue Statut: ${response.statusCode}");
//         print("Geoapify - Réponse Rue Corps: ${response.body}");
//       }
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           // Extraire les noms de rues uniques
//           Set<String> uniqueStreets = {};
//
//           for (var feature in data['features']) {
//             final properties = feature['properties'];
//
//             // Essayer différents champs pour obtenir le nom de la rue
//             String? street = properties['street'] ??
//                 properties['address_line1'] ??
//                 properties['name'];
//
//             if (street != null && street.isNotEmpty) {
//               // Nettoyer le nom de la rue (enlever les numéros s'il y en a)
//               street = _cleanStreetName(street);
//               if (street.isNotEmpty) {
//                 uniqueStreets.add(street);
//               }
//             }
//           }
//
//           return uniqueStreets;
//         } else {
//           return const Iterable<String>.empty();
//         }
//       } else {
//         debugPrint("Erreur API Geoapify (Rue - ${response.statusCode}): ${response.body}");
//         return const Iterable<String>.empty();
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion Geoapify (Rue) : $e");
//       return const Iterable<String>.empty();
//     }
//   }
//
//   // Méthode pour nettoyer le nom de la rue (enlever les numéros)
//   String _cleanStreetName(String street) {
//     // Enlever les numéros au début ou à la fin
//     return street.replaceAll(RegExp(r'^\d+\s*'), '') // Numéros au début
//         .replaceAll(RegExp(r'\s*\d+$'), '') // Numéros à la fin
//         .replaceAll(RegExp(r'^\d+[a-zA-Z]?\s*'), '') // Numéros avec lettres au début
//         .trim();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Autocomplete<String>(
//       optionsBuilder: (TextEditingValue textEditingValue) {
//         // Appeler le callback quand le texte change
//         widget.onStreetChanged?.call();
//
//         // optionsBuilder doit retourner un Future<Iterable<String>>
//         return fetchStreetSuggestions(textEditingValue.text);
//       },
//       onSelected: (String selection) {
//         // Cette méthode est appelée quand une suggestion est sélectionnée
//         widget.streetController.text = selection;
//
//         // Appeler le callback quand une rue est sélectionnée
//         widget.onStreetSelected?.call();
//
//         if (kDebugMode) {
//           print("Rue sélectionnée: $selection");
//         }
//       },
//       fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
//         // Synchroniser le contrôleur interne d'Autocomplete avec le contrôleur externe
//         controller.text = widget.streetController.text;
//         controller.selection = widget.streetController.selection;
//
//         return TextField(
//           controller: controller,
//           focusNode: focusNode,
//           onEditingComplete: onEditingComplete,
//           decoration: InputDecoration(
//             labelText: "Tapez le nom de votre rue",
//             hintText: "Ex: Rue de la Paix, Avenue Louise...",
//             prefixIcon: Icon(Icons.search, color: Color(0xFF8E44AD)),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Color(0xFF8E44AD), width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: EdgeInsets.symmetric(vertical: 16),
//           ),
//           // Mettre à jour le contrôleur externe lorsque le texte change
//           onChanged: (text) {
//             widget.streetController.text = text;
//             // Appeler le callback quand le texte change manuellement
//             widget.onStreetChanged?.call();
//           },
//         );
//       },
//       optionsViewBuilder: (context, onSelected, options) {
//         return Align(
//           alignment: Alignment.topLeft,
//           child: Material(
//             elevation: 4,
//             borderRadius: BorderRadius.circular(12),
//             child: Container(
//               constraints: BoxConstraints(
//                 maxHeight: 200,
//                 maxWidth: MediaQuery.of(context).size.width - 32,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: ListView.builder(
//                 padding: EdgeInsets.zero,
//                 shrinkWrap: true,
//                 itemCount: options.length,
//                 itemBuilder: (context, index) {
//                   final String option = options.elementAt(index);
//                   return ListTile(
//                     leading: Icon(Icons.location_on,
//                         color: Color(0xFF8E44AD),
//                         size: 20),
//                     title: Text(
//                       option,
//                       style: TextStyle(fontSize: 14),
//                     ),
//                     dense: true,
//                     onTap: () => onSelected(option),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         );
//       },
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
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:flutter/foundation.dart';
// //
// // class StreetAutocomplete extends StatefulWidget {
// //   final TextEditingController streetController;
// //   final TextEditingController communeController;
// //   final TextEditingController codePostalController;
// //   final String geoapifyApiKey;
// //
// //   const StreetAutocomplete({
// //     super.key,
// //     required this.streetController,
// //     required this.communeController,
// //     required this.codePostalController,
// //     required this.geoapifyApiKey,
// //   });
// //
// //   @override
// //   State<StreetAutocomplete> createState() => _StreetAutocompleteState();
// // }
// //
// // class _StreetAutocompleteState extends State<StreetAutocomplete> {
// //   // La liste de suggestions est maintenant gérée par Autocomplete lui-même via Future
// //   // Plus besoin de setState ici pour les suggestions
// //   Future<Iterable<String>> fetchStreetSuggestions(String query) async {
// //     if (query.isEmpty) {
// //       return const Iterable<String>.empty();
// //     }
// //
// //     // Construire la requête pour Geoapify Autocomplete
// //     String urlString = "https://api.geoapify.com/v1/geocode/autocomplete?text=$query&lang=fr&limit=5&apiKey=${widget.geoapifyApiKey}";
// //
// //     // Ajout du filtre par pays (Belgique)
// //     urlString += "&filter=countrycode:be";
// //
// //     // IMPORTANT : Le filtrage par 'postcode' ou 'place' via 'filter=' n'est pas supporté
// //     // directement pour l'API Autocomplete de Geoapify.
// //     // Si vous avez besoin de filtrer par code postal/commune, il faut utiliser 'bias'
// //     // avec des coordonnées (e.g., bias=proximity:lon,lat) ou un filtre 'rect'.
// //     // Pour l'instant, nous retirons le filtre postcode pour éviter le 400 Bad Request.
// //     // Si vous voulez affiner, vous devrez d'abord géocoder la commune/code postal
// //     // pour obtenir les coordonnées, puis les utiliser comme 'bias=proximity'.
// //
// //     final url = Uri.parse(urlString);
// //
// //     if (kDebugMode) {
// //       print("Geoapify - Requête Rue URL: $url");
// //     }
// //
// //     try {
// //       final response = await http.get(url);
// //
// //       if (kDebugMode) {
// //         print("Geoapify - Réponse Rue Statut: ${response.statusCode}");
// //         print("Geoapify - Réponse Rue Corps: ${response.body}");
// //       }
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         if (data['features'] != null && data['features'].isNotEmpty) {
// //           return (data['features'] as List)
// //               .map((item) => item['properties']['address_line1']?.toString() ?? '') // Utilise 'address_line1' pour la rue
// //               .where((s) => s.isNotEmpty);
// //         } else {
// //           return const Iterable<String>.empty();
// //         }
// //       } else {
// //         debugPrint("Erreur API Geoapify (Rue - ${response.statusCode}): ${response.body}");
// //         return ["Erreur de recherche"].map((e) => e); // Retourne une erreur visible
// //       }
// //     } catch (e) {
// //       debugPrint("Erreur de connexion Geoapify (Rue) : $e");
// //       return ["Erreur réseau"].map((e) => e); // Retourne une erreur visible
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Autocomplete<String>(
// //       optionsBuilder: (TextEditingValue textEditingValue) {
// //         // optionsBuilder doit retourner un Future<Iterable<String>>
// //         // Appelez la fonction asynchrone directement ici.
// //         return fetchStreetSuggestions(textEditingValue.text);
// //       },
// //       onSelected: (String selection) {
// //         // Cette méthode est appelée quand une suggestion est sélectionnée
// //         widget.streetController.text = selection;
// //       },
// //       fieldViewBuilder:
// //           (context, controller, focusNode, onEditingComplete) {
// //         // Synchroniser le contrôleur interne d'Autocomplete avec le contrôleur externe
// //         // Ceci est important pour que les valeurs tapées manuellement soient reflétées.
// //         // Éviter setState ici.
// //         controller.text = widget.streetController.text;
// //         controller.selection = widget.streetController.selection; // Garde la sélection
// //
// //         return TextField(
// //           controller: controller,
// //           focusNode: focusNode,
// //           onEditingComplete: onEditingComplete,
// //           decoration: const InputDecoration(
// //             labelText: "Rue",
// //             border: OutlineInputBorder(),
// //           ),
// //           // Mettre à jour le contrôleur externe lorsque le texte change dans le champ Autocomplete
// //           onChanged: (text) {
// //             widget.streetController.text = text;
// //           },
// //         );
// //       },
// //     );
// //   }
// // }