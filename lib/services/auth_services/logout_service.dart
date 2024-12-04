import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../pages/login_page.dart';
import '../../widgets/bottom_nav_bar.dart';

class LogoutPage extends StatefulWidget {
  final int initialIndex;
  final Widget child; // La page enfant à afficher

  const LogoutPage({
    Key? key,
    required this.initialIndex,
    required this.child,
  }) : super(key: key);

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Affiche une boîte de dialogue pour confirmer la déconnexion
  Future<void> _confirmLogout(BuildContext context) async {
    final bool shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Annuler
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirmer
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (shouldLogout) {
      await _logout(context);
    }
  }

  /// Déconnexion Firebase et redirection vers LoginPage
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la déconnexion.")),
      );
    }
  }

  /// Gère les actions en fonction de l'élément de navigation sélectionné
  void _handleTap(int index) {
    if (index == 5) {
      // Si l'utilisateur sélectionne "Déconnexion"
      _confirmLogout(context);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child, // Page enfant affichée ici
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleTap,
      ),
    );
  }
}
