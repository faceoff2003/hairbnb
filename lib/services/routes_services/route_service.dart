import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pages/payment/paiement_sucess_page.dart';
import '../../pages/chat/chat_page.dart';
import '../../services/providers/current_user_provider.dart';

class RouteService {
  // Singleton pattern
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  // Méthode pour générer les routes à la demande
  Route<dynamic>? generateRoute(RouteSettings settings) {
    // Extrait le nom de la route et les arguments
    final name = settings.name;
    final arguments = settings.arguments;

    // Gère chaque route spécifique
    switch (name) {
      case '/paiement_success':
      // Crée la route uniquement lorsqu'elle est demandée
        return MaterialPageRoute(
          builder: (context) => PaiementSuccessScreen(
            sessionId: arguments is Map<String, dynamic> ? arguments['sessionId'] : null,
          ),
          settings: settings,
        );

      // 🆕 Route pour le chat
      default:
        // Vérifier si c'est une route de chat (format: /chat/otherUserId)
        if (name != null && name.startsWith('/chat/')) {
          final otherUserId = name.replaceFirst('/chat/', '');
          
          return MaterialPageRoute(
            builder: (context) {
              final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
              final currentUser = currentUserProvider.currentUser;
              
              if (currentUser == null) {
                // Si pas d'utilisateur connecté, rediriger vers la home
                return Container(
                  child: Center(
                    child: Text("Veuillez vous connecter pour accéder au chat"),
                  ),
                );
              }
              
              return ChatPage(
                currentUser: currentUser,
                otherUserId: otherUserId,
              );
            },
            settings: settings,
          );
        }

        // Retourne null pour les routes inconnues (laissez le navigateur principal les gérer)
        return null;
    }
  }

  // Méthode pour naviguer vers l'écran de succès de paiement
  void navigateToPaiementSuccess(BuildContext context, String? sessionId) {
    Navigator.of(context).pushNamed(
      '/paiement_success',
      arguments: {'sessionId': sessionId},
    );
  }

  // 🆕 Méthode pour naviguer vers le chat
  void navigateToChat(BuildContext context, String otherUserId) {
    Navigator.of(context).pushNamed('/chat/$otherUserId');
  }
}
