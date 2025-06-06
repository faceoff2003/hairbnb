import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/pages/authentification/login_page.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';


class DeleteAccountService {
  static const String baseUrl = 'https://www.hairbnb.site';

  /// Supprime complètement le compte de l'utilisateur (Django + Firebase)
  static Future<void> deleteUserAccount({
    required BuildContext context,
    required CurrentUser currentUser,
    required Color successGreen,
    required Color errorRed,
    required Function(bool) setLoadingState,
  }) async {
    // 1. Confirmation avec dialog de sécurité
    bool confirmed = await _showDeleteConfirmationDialog(context, errorRed);
    if (!confirmed) return;

    setLoadingState(true);

    try {
      // 2. Récupérer le token Firebase
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final String? idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('Impossible de récupérer le token d\'authentification');
      }

      // 3. Appel à l'API Django pour supprimer le compte
      final response = await http.post(
        Uri.parse('$baseUrl/api/delete_my_profile_firebase/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'confirmation': 'SUPPRIMER',
          'anonymize_reviews': true,
        }),
      );

      setLoadingState(false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));

        // 4. Afficher le résultat de la suppression
        // The redirection will now be handled within _showDeletionSummary
        await _showDeletionSummary(context, responseData, successGreen);


      } else {
        // Gérer les erreurs de l'API
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression du compte');
      }

    } catch (e) {
      setLoadingState(false);
      _showErrorDialog(context, 'Erreur lors de la suppression du compte: $e', errorRed);
    }
  }

  /// Dialog de confirmation avec double vérification
  static Future<bool> _showDeleteConfirmationDialog(BuildContext context, Color errorRed) async {
    final TextEditingController confirmController = TextEditingController();
    bool isConfirmed = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.warning, color: errorRed, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Supprimer le compte',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ ATTENTION: Cette action est IRRÉVERSIBLE!',
                    style: TextStyle(
                      color: errorRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La suppression de votre compte entraînera la perte définitive de:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Toutes vos informations personnelles\n'
                        '• Votre salon et ses images\n'
                        '• Vos services et promotions\n'
                        '• Votre historique de rendez-vous\n'
                        '• Votre compte Firebase',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pour confirmer, tapez "SUPPRIMER" ci-dessous:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      hintText: 'Tapez SUPPRIMER',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: errorRed),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: errorRed, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        isConfirmed = value.toUpperCase() == 'SUPPRIMER';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    isConfirmed = false;
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isConfirmed
                      ? () {
                    Navigator.of(context).pop();
                    isConfirmed = true;
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SUPPRIMER'),
                ),
              ],
            );
          },
        );
      },
    );

    return isConfirmed;
  }

  /// Affiche le résumé de la suppression
  static Future<void> _showDeletionSummary(BuildContext context, Map<String, dynamic> responseData, Color successGreen) async {
    final deletionSummary = responseData['deletion_summary'];
    final deletedItems = deletionSummary['deleted_items'];

    await showDialog( // Changed to await showDialog
      context: context,
      barrierDismissible: false, // Make it non-dismissible until OK is pressed or countdown finishes
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: successGreen, size: 28),
              const SizedBox(width: 8),
              const Text('Compte supprimé'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ ${responseData['message']}'),
              const SizedBox(height: 12),
              const Text('Éléments supprimés:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...deletedItems.entries.map((entry) {
                if (entry.value > 0) {
                  return Text('• ${entry.key}: ${entry.value}');
                }
                return const SizedBox.shrink();
              }).toList(),
              if (responseData['firebase_account_deleted'] == true)
                const Text('• Compte Firebase supprimé', style: TextStyle(color: Colors.green)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await _logoutAndRedirect(context); // Redirect to login page
              },
              style: ElevatedButton.styleFrom(backgroundColor: successGreen),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Affiche un dialog d'erreur
  static void _showErrorDialog(BuildContext context, String message, Color errorRed) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error, color: errorRed, size: 28),
              const SizedBox(width: 8),
              const Text('Erreur'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Déconnecte l'utilisateur et redirige vers la page de connexion
  static Future<void> _logoutAndRedirect(BuildContext context) async {
    try {
      Provider.of<CurrentUserProvider>(context, listen: false).clearUser();

      await FirebaseAuth.instance.signOut();

      // Rediriger vers LoginPage et vider la pile de navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      // En cas d'erreur de déconnexion, forcer la redirection

      Provider.of<CurrentUserProvider>(context, listen: false).clearUser();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }
}











// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/authentification/login_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
//
//
// class DeleteAccountService {
//   static const String baseUrl = 'https://www.hairbnb.site';
//
//   /// Supprime complètement le compte de l'utilisateur (Django + Firebase)
//   static Future<void> deleteUserAccount({
//     required BuildContext context,
//     required CurrentUser currentUser,
//     required Color successGreen,
//     required Color errorRed,
//     required Function(bool) setLoadingState,
//   }) async {
//     // 1. Confirmation avec dialog de sécurité
//     bool confirmed = await _showDeleteConfirmationDialog(context, errorRed);
//     if (!confirmed) return;
//
//     setLoadingState(true);
//
//     try {
//       // 2. Récupérer le token Firebase
//       final User? firebaseUser = FirebaseAuth.instance.currentUser;
//       if (firebaseUser == null) {
//         throw Exception('Utilisateur non authentifié');
//       }
//
//       final String? idToken = await firebaseUser.getIdToken();
//       if (idToken == null) {
//         throw Exception('Impossible de récupérer le token d\'authentification');
//       }
//
//       // 3. Appel à l'API Django pour supprimer le compte
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/delete_my_profile_firebase/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $idToken',
//         },
//         body: jsonEncode({
//           'confirmation': 'SUPPRIMER',
//           'anonymize_reviews': true,
//         }),
//       );
//
//       setLoadingState(false);
//
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//
//         // 4. Afficher le résultat de la suppression
//         _showDeletionSummary(context, responseData, successGreen);
//
//         // 5. Déconnecter et rediriger vers la page de connexion
//         await _logoutAndRedirect(context);
//
//       } else {
//         // Gérer les erreurs de l'API
//         final errorData = jsonDecode(response.body);
//         throw Exception(errorData['message'] ?? 'Erreur lors de la suppression du compte');
//       }
//
//     } catch (e) {
//       setLoadingState(false);
//       _showErrorDialog(context, 'Erreur lors de la suppression du compte: $e', errorRed);
//     }
//   }
//
//   /// Dialog de confirmation avec double vérification
//   static Future<bool> _showDeleteConfirmationDialog(BuildContext context, Color errorRed) async {
//     final TextEditingController confirmController = TextEditingController();
//     bool isConfirmed = false;
//
//     await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               title: Row(
//                 children: [
//                   Icon(Icons.warning, color: errorRed, size: 28),
//                   const SizedBox(width: 8),
//                   const Expanded(
//                     child: Text(
//                       'Supprimer le compte',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '⚠️ ATTENTION: Cette action est IRRÉVERSIBLE!',
//                     style: TextStyle(
//                       color: errorRed,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'La suppression de votre compte entraînera la perte définitive de:',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     '• Toutes vos informations personnelles\n'
//                         '• Votre salon et ses images\n'
//                         '• Vos services et promotions\n'
//                         '• Votre historique de rendez-vous\n'
//                         '• Votre compte Firebase',
//                     style: TextStyle(fontSize: 13),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Pour confirmer, tapez "SUPPRIMER" ci-dessous:',
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: confirmController,
//                     decoration: InputDecoration(
//                       hintText: 'Tapez SUPPRIMER',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: errorRed),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: errorRed, width: 2),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setState(() {
//                         isConfirmed = value.toUpperCase() == 'SUPPRIMER';
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     isConfirmed = false;
//                   },
//                   child: const Text('Annuler'),
//                 ),
//                 ElevatedButton(
//                   onPressed: isConfirmed
//                       ? () {
//                     Navigator.of(context).pop();
//                     isConfirmed = true;
//                   }
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: errorRed,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('SUPPRIMER'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//
//     return isConfirmed;
//   }
//
//   /// Affiche le résumé de la suppression
//   static void _showDeletionSummary(BuildContext context, Map<String, dynamic> responseData, Color successGreen) {
//     final deletionSummary = responseData['deletion_summary'];
//     final deletedItems = deletionSummary['deleted_items'];
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Row(
//             children: [
//               Icon(Icons.check_circle, color: successGreen, size: 28),
//               const SizedBox(width: 8),
//               const Text('Compte supprimé'),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('✅ ${responseData['message']}'),
//               const SizedBox(height: 12),
//               const Text('Éléments supprimés:', style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               ...deletedItems.entries.map((entry) {
//                 if (entry.value > 0) {
//                   return Text('• ${entry.key}: ${entry.value}');
//                 }
//                 return const SizedBox.shrink();
//               }).toList(),
//               if (responseData['firebase_account_deleted'] == true)
//                 const Text('• Compte Firebase supprimé', style: TextStyle(color: Colors.green)),
//             ],
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(),
//               style: ElevatedButton.styleFrom(backgroundColor: successGreen),
//               child: const Text('OK', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Affiche un dialog d'erreur
//   static void _showErrorDialog(BuildContext context, String message, Color errorRed) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Row(
//             children: [
//               Icon(Icons.error, color: errorRed, size: 28),
//               const SizedBox(width: 8),
//               const Text('Erreur'),
//             ],
//           ),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Déconnecte l'utilisateur et redirige vers la page de connexion
//   static Future<void> _logoutAndRedirect(BuildContext context) async {
//     try {
//       await FirebaseAuth.instance.signOut();
//
//       // Rediriger vers LoginPage et vider la pile de navigation
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//             (Route<dynamic> route) => false,
//       );
//     } catch (e) {
//       // En cas d'erreur de déconnexion, forcer la redirection
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//             (Route<dynamic> route) => false,
//       );
//     }
//   }
// }