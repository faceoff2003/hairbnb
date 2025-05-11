import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html show window;

// Fonction qui gère le paiement selon la plateforme
Future<void> handlePayment(int rendezVousId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    if (token == null) throw Exception("Utilisateur non authentifié.");

    // Appel à votre backend pour créer une session de paiement
    final response = await http.post(
      Uri.parse('https://www.hairbnb.site/api/paiement/create-checkout-session/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rendez_vous_id': rendezVousId,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? "Erreur serveur");
    }

    final data = jsonDecode(response.body);

    if (kIsWeb) {
      // Sur le web, utiliser la redirection vers Stripe Checkout
      // Votre backend doit renvoyer une URL de checkout
      if (data['checkout_url'] != null) {
        html.window.open(data['checkout_url'], '_blank');
      } else {
        throw Exception("URL de paiement manquante dans la réponse");
      }
    } else {
      // Sur mobile, utiliser la feuille de paiement native
      if (data['clientSecret'] != null) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: data['clientSecret'],
            merchantDisplayName: 'Hairbnb',
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      } else {
        throw Exception("Client secret manquant dans la réponse");
      }
    }
  } catch (e) {
    print("Erreur: $e");
    rethrow;
  }
}