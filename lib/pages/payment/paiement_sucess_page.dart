import 'package:flutter/material.dart';

class PaiementSuccessScreen extends StatelessWidget {
  final String? sessionId;

  const PaiementSuccessScreen({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    // Récupérer le sessionId depuis les arguments de route si pas fourni directement
    String? routeSessionId = sessionId;

    if (routeSessionId == null) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        routeSessionId = arguments['sessionId'] as String?;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Confirmé'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Paiement réussi !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre réservation a été confirmée avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              if (routeSessionId != null) ...[
                const SizedBox(height: 12),
                Text(
                  'ID de session: $routeSessionId',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Retour à l'écran d'accueil ou navigation vers les détails de réservation
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home', // Remplacez par votre route d'accueil
                        (route) => false, // Supprime toutes les routes de la pile
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}