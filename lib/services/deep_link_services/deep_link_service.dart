import 'package:flutter/material.dart';
import '../../pages/payment/paiement_sucess_page.dart'; // Votre chemin ajusté

class RouteService {
  // Singleton pattern
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  // Ajout de la méthode navigateToPaiementSuccess
  void navigateToPaiementSuccess(BuildContext context, String? sessionId) {
    Navigator.of(context).pushNamed(
      '/paiement_success',
      arguments: {'sessionId': sessionId},
    );
  }

  // Méthode de génération de route appelée par onGenerateRoute
  Route<dynamic>? generateRoute(RouteSettings settings) {
    print('Génération de route pour: ${settings.name}');

    // Récupérer le nom de la route et les arguments
    final String routeName = settings.name ?? '';

    // Si routeName contient des paramètres de requête
    final Uri uri = Uri.parse(routeName);

    // Extraire le chemin principal (sans query parameters)
    String path = uri.path;
    if (path.startsWith('/')) {
      path = path.substring(1); // Enlever le slash initial si présent
    }

    // Vérifier la route
    switch (path) {
      case 'paiement_success':
      // Récupérer session_id des query parameters ou des arguments
        String? sessionId;

        // D'abord essayer depuis les query parameters
        if (uri.queryParameters.containsKey('session_id')) {
          sessionId = uri.queryParameters['session_id'];
          print('Session ID trouvé dans les query parameters: $sessionId');
        }
        // Ensuite essayer depuis les arguments (pour navigation programmatique)
        else if (settings.arguments is Map<String, dynamic>) {
          sessionId = (settings.arguments as Map<String, dynamic>)['sessionId'];
          print('Session ID trouvé dans les arguments: $sessionId');
        }

        return MaterialPageRoute(
          builder: (context) => PaiementSuccessScreen(sessionId: sessionId),
          settings: settings,
        );

    // Vous pouvez ajouter d'autres routes spéciales ici

      default:
        print('Route inconnue: $path');
        return null; // Laisser le système de routes par défaut gérer le reste
    }
  }
}





// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:app_links/app_links.dart';
//
// import '../routes_services/route_service.dart';
//
// class DeepLinkService {
//   // Singleton pattern
//   static final DeepLinkService _instance = DeepLinkService._internal();
//   factory DeepLinkService() => _instance;
//   DeepLinkService._internal();
//
//   // Instance de AppLinks
//   final _appLinks = AppLinks();
//
//   // Abonnement au stream
//   StreamSubscription? _subscription;
//
//   // Fonction pour initialiser le service (à appeler après le paiement)
//   Future<void> initialize(BuildContext context) async {
//     // Annuler l'abonnement précédent si existant
//     _subscription?.cancel();
//
//     // Écouter les deep links entrants
//     _subscription = _appLinks.stringLinkStream.listen(
//             (String link) {
//           print('Deep link reçu (string): $link');
//           final uri = Uri.parse(link);
//           _handleDeepLink(context, uri);
//         },
//         onError: (error) {
//           print('Erreur de réception de deep link: $error');
//         }
//     );
//
//     // Vérifier si l'app a été ouverte par un deep link
//     try {
//       final initialLink = await _appLinks.getInitialLinkString();
//       if (initialLink != null && initialLink.isNotEmpty) {
//         print('Deep link initial: $initialLink');




//         final uri = Uri.parse(initialLink);
//         _handleDeepLink(context, uri);
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération du lien initial: $e');
//     }
//   }
//
//   // Fonction pour arrêter le service
//   void dispose() {
//     _subscription?.cancel();
//     _subscription = null;
//   }
//
//   // Fonction pour traiter le deep link
//   void _handleDeepLink(BuildContext context, Uri uri) {
//     print('Traitement du deep link: $uri');
//
//     // Vérifier si c'est le deep link de paiement réussi
//     if (uri.scheme == 'hairbnb' &&
//         // uri.path.contains('paiement/success') &&
//         uri.queryParameters.containsKey('session_id')) {
//
//       final sessionId = uri.queryParameters['session_id'];
//       print('Session ID reçu: $sessionId');
//
//       // Utiliser le RouteService pour la navigation
//       Future.delayed(Duration.zero, () {
//         RouteService().navigateToPaiementSuccess(context, sessionId);
//       });
//     }
//   }
// }