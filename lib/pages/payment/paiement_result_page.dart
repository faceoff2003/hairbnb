import 'package:flutter/material.dart';

class PaiementResultPage extends StatelessWidget {
  final bool success;
  final int rendezVousId;
  final Function() onContinue;

  const PaiementResultPage({
    required this.success,
    required this.rendezVousId,
    required this.onContinue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(success ? "Paiement réussi" : "Paiement échoué"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Désactive le bouton retour
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône de statut
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 80,
              ),

              const SizedBox(height: 24),

              // Titre du statut
              Text(
                success
                    ? "Paiement confirmé !"
                    : "Échec du paiement",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Message détaillé
              Text(
                success
                    ? "Votre réservation a été confirmée avec succès. Merci de faire confiance à Hairbnb!"
                    : "Une erreur est survenue lors du traitement de votre paiement. Veuillez réessayer ou contacter le support.",
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Numéro de référence
              if (success)
                Text(
                  "Référence: RDV-$rendezVousId",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 32),

              // Bouton de continuation
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: success ? Colors.green : Colors.blue,
                ),
                child: Text(
                  success
                      ? "Voir mes rendez-vous"
                      : "Réessayer",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bouton secondaire
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  success
                      ? "Retour à l'accueil"
                      : "Annuler",
                  style: TextStyle(
                    fontSize: 16,
                    color: success ? Colors.black54 : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}