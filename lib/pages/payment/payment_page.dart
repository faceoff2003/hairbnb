// payment_page.dart - version corrigée

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:hairbnb/pages/payment/payment_services/paiement_service.dart';
import 'package:hairbnb/pages/payment/payment_verification_page.dart';

class PaiementPage extends StatefulWidget {
  final int rendezVousId;

  const PaiementPage({
    required this.rendezVousId,
    super.key,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
  }

  // ⚠️ IMPORTANT: Fonction corrigée pour éviter la récursion infinie
  Future<void> _lancerPaiementStripeCheckout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await PaiementService.createCheckoutSession(widget.rendezVousId);
      final checkoutUrl = response['checkout_url'];

      if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
        throw Exception("URL de paiement manquante.");
      }

      // ⚠️ Utilisation directe de url_launcher sans appeler notre propre fonction
      final uri = Uri.parse(checkoutUrl);

      // CORRECTION: Éviter la récursion en utilisant directement le package
      if (!await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication
      )) {
        throw Exception("Impossible d'ouvrir la page de paiement.");
      }

      // Rediriger vers la page de vérification
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentVerificationPage(
              rendezVousId: widget.rendezVousId,
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Finalisez votre paiement sécurisé",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Redirection en cours..."),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _lancerPaiementStripeCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  "Payer maintenant",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              "Votre paiement est sécurisé via Stripe.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  "Paiement 100% sécurisé",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}