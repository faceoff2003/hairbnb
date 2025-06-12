// widgets/avis_badge_widget.dart
import 'package:flutter/material.dart';
import '../services/avis_service.dart';

class AvisBadgeWidget extends StatefulWidget {
  final VoidCallback? onTap; // Fonction appelée quand on clique sur le badge
  final bool showText; // Afficher le texte ou juste l'icône avec badge

  const AvisBadgeWidget({
    Key? key,
    this.onTap,
    this.showText = true,
  }) : super(key: key);

  @override
  _AvisBadgeWidgetState createState() => _AvisBadgeWidgetState();
}

class _AvisBadgeWidgetState extends State<AvisBadgeWidget> {
  int _avisCount = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _chargerAvisEnAttente();
  }

  /// 🔄 Charger le nombre d'avis en attente
  Future<void> _chargerAvisEnAttente() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final count = await AvisService.getCountAvisEnAttente();

      if (mounted) {
        setState(() {
          _avisCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des avis: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _avisCount = 0; // En cas d'erreur, on cache le badge
        });
      }
    }
  }

  /// 🎨 Construire le badge avec nombre
  Widget _buildBadge({required Widget child}) {
    if (_avisCount == 0) {
      return child; // Pas de badge si aucun avis
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              '$_avisCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Affichage pendant le chargement
    if (_isLoading) {
      return widget.showText
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Chargement...', style: TextStyle(fontSize: 14)),
        ],
      )
          : SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // ❌ Pas d'affichage si erreur ou aucun avis
    if (_hasError || _avisCount == 0) {
      return SizedBox.shrink();
    }

    // 🎯 Widget principal avec badge
    Widget mainWidget;

    if (widget.showText) {
      // Version avec texte (pour menu, drawer, etc.)
      mainWidget = Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review,
              color: Colors.orange,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '$_avisCount avis en attente',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      // Version icône seule (pour app bar, etc.)
      mainWidget = _buildBadge(
        child: Icon(
          Icons.rate_review,
          color: Colors.orange,
          size: 24,
        ),
      );
    }

    // 🖱️ Ajouter la gestion du clic
    return GestureDetector(
      onTap: widget.onTap,
      child: mainWidget,
    );
  }

  /// 🔄 Méthode publique pour recharger les données
  void refresh() {
    _chargerAvisEnAttente();
  }
}

/// 🎯 Widget simplifié pour une utilisation rapide dans l'AppBar
class AvisBadgeIcon extends StatelessWidget {
  final VoidCallback? onTap;

  const AvisBadgeIcon({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AvisBadgeWidget(
      onTap: onTap,
      showText: false,
    );
  }
}

/// 🎯 Widget avec texte pour menus/drawer
class AvisBadgeText extends StatelessWidget {
  final VoidCallback? onTap;

  const AvisBadgeText({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AvisBadgeWidget(
      onTap: onTap,
      showText: true,
    );
  }
}