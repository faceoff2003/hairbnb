// pages/payment/payment_verification_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/home_page.dart'; // Importez votre page d'accueil
import 'package:hairbnb/pages/payment/payment_services/paiement_service.dart';

class PaymentVerificationPage extends StatefulWidget {
  final int rendezVousId;

  const PaymentVerificationPage({
    Key? key,
    required this.rendezVousId,
  }) : super(key: key);

  @override
  State<PaymentVerificationPage> createState() => _PaymentVerificationPageState();
}

class _PaymentVerificationPageState extends State<PaymentVerificationPage> {
  bool _isVerifying = true;
  String _statusMessage = "Vérification du paiement en cours...";
  int _failureCount = 0;
  final int _maxFailures = 10; // Maximum de tentatives avant d'abandonner
  Timer? _statusCheckTimer;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();

    // Configurer l'écouteur de deep links
    PaiementService.listenForDeepLinks(_handleDeepLink);

    // Commencer immédiatement la vérification
    _checkPaymentStatus();

    // Configurer la vérification périodique
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_redirecting) {
        _checkPaymentStatus();
      }
    });
  }

  @override
  void dispose() {
    // Annuler le timer et les écouteurs
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _handleDeepLink(Uri uri) {
    print("Deep link reçu dans PaymentVerificationPage: $uri");

    if (uri.path.contains('/paiement/success')) {
      // Forcer une vérification immédiate
      _checkPaymentStatus();
    } else if (uri.path.contains('/paiement/error')) {
      // Mettre à jour l'interface
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _statusMessage = "Le paiement a été annulé ou a échoué.";
          _statusCheckTimer?.cancel();
        });
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_redirecting) return; // Éviter les vérifications multiples pendant la redirection

    try {
      final isPaid = await PaiementService.checkPaymentStatus(widget.rendezVousId);

      if (isPaid) {
        // Marquer comme en redirection pour éviter des appels multiples
        _redirecting = true;

        // Arrêter les vérifications
        _statusCheckTimer?.cancel();

        if (mounted) {
          setState(() {
            _isVerifying = false;
            _statusMessage = "Paiement confirmé ! Redirection...";
          });

          // Attendre un court moment pour montrer le succès, puis rediriger
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false, // Supprimer toutes les routes précédentes
              );
            }
          });
        }
      }

      // En cas de succès de la requête, réinitialiser le compteur d'échecs
      _failureCount = 0;
    } catch (e) {
      print("Erreur vérification paiement: $e");
      _failureCount++;

      if (_failureCount >= _maxFailures) {
        // Arrêter les vérifications après plusieurs échecs
        _statusCheckTimer?.cancel();

        if (mounted) {
          setState(() {
            _isVerifying = false;
            _statusMessage = "Impossible de vérifier le statut du paiement après plusieurs tentatives.";
          });

          _showErrorDialog();
        }
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Erreur de vérification"),
        content: const Text(
            "Nous n'avons pas pu vérifier le statut de votre paiement. "
                "Veuillez vérifier votre connexion internet."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialogue

              // Recommencer les vérifications
              setState(() {
                _failureCount = 0;
                _isVerifying = true;
                _statusMessage = "Vérification du paiement en cours...";
              });

              _checkPaymentStatus();
              _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
                if (!_redirecting) {
                  _checkPaymentStatus();
                }
              });
            },
            child: const Text("Réessayer"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialogue
              Navigator.of(context).pop(); // Retourner à l'écran précédent
            },
            child: const Text("Retour"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Empêcher le retour en arrière pendant la vérification
      onWillPop: () async => !_isVerifying,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Vérification du paiement"),
          centerTitle: true,
          automaticallyImplyLeading: !_isVerifying, // Désactiver le bouton retour pendant la vérification
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isVerifying)
                  const CircularProgressIndicator()
                else if (_statusMessage.contains("confirmé"))
                  const Icon(Icons.check_circle, color: Colors.green, size: 64)
                else
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),

                const SizedBox(height: 24),

                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isVerifying
                        ? Colors.black
                        : _statusMessage.contains("confirmé")
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (!_isVerifying && !_statusMessage.contains("confirmé"))
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton(
                      onPressed: () {
                        // Recommencer les vérifications
                        setState(() {
                          _failureCount = 0;
                          _isVerifying = true;
                          _statusMessage = "Vérification du paiement en cours...";
                        });

                        _checkPaymentStatus();
                        _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
                          if (!_redirecting) {
                            _checkPaymentStatus();
                          }
                        });
                      },
                      child: const Text("Réessayer"),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}