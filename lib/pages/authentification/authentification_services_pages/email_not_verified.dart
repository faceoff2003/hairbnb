import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../profil/profil_creation_page.dart';
import '../login_page.dart';

class EmailNotVerifiedPage extends StatelessWidget {
  final String email;

  const EmailNotVerifiedPage({super.key, required this.email});

  Future<void> _resendVerificationEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de vérification renvoyé.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  Future<void> _checkVerificationStatus(BuildContext context) async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileCreationPage(
            email: user.email ?? '',
            userUuid: user.uid,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email toujours non vérifié.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mail_lock_outlined, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              Text(
                "Votre email $email n'a pas encore été vérifié.",
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _resendVerificationEmail(context),
                icon: const Icon(Icons.refresh),
                label: const Text("Renvoyer l'email de vérification"),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () => _checkVerificationStatus(context),
                icon: const Icon(Icons.verified_user),
                label: const Text("J'ai confirmé mon email"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ),
                child: const Text("Retour à la connexion", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}