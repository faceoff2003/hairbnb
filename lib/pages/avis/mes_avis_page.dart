// pages/avis/mes_avis_page.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/avis.dart';
import 'services/avis_service.dart';

class MesAvisPage extends StatefulWidget {
  const MesAvisPage({super.key});

  @override
  _MesAvisPageState createState() => _MesAvisPageState();
}

class _MesAvisPageState extends State<MesAvisPage> {
  List<Avis> _mesAvis = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerMesAvis();
  }

  /// 🔄 Charger tous mes avis
  Future<void> _chargerMesAvis() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final avisList = await AvisService.getMesAvis(context: context);

      if (mounted) {
        setState(() {
          _mesAvis = avisList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors du chargement des avis: $e");
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// ✏️ Modifier un avis
  void _modifierAvis(Avis avis) {
    showDialog(
      context: context,
      builder: (context) => _ModifierAvisDialog(
        avis: avis,
        onAvisModifie: () {
          _chargerMesAvis();
        },
      ),
    );
  }

  /// 🗑️ Supprimer un avis
  void _supprimerAvis(Avis avis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Supprimer l\'avis')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avis.salonNom ?? 'Salon inconnu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        Icons.star,
                        size: 16,
                        color: i < avis.note ? Colors.amber : Colors.grey[300],
                      )),
                      SizedBox(width: 8),
                      Text('${avis.note}/5'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    avis.commentaire,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Cette action est irréversible.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmerSuppressionAvis(avis);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// 🗑️ Confirmer la suppression
  Future<void> _confirmerSuppressionAvis(Avis avis) async {
    try {
      final result = await AvisService.supprimerAvis(
        context: context,
        avisId: avis.id!,
      );

      if (result.success) {
        // ✅ CORRECTION: Recharger AVANT d'afficher le succès
        await _chargerMesAvis();

        if (mounted) {
          // Message de succès
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 60),
                    const SizedBox(height: 10),
                    const Text("Avis supprimé !", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) Navigator.of(context).pop(); // Fermer succès
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Construire une carte d'avis - VERSION RESPONSIVE
  Widget _buildAvisCard(Avis avis) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 16,
          vertical: 8
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏪 En-tête salon - LAYOUT RESPONSIVE
            if (isSmallScreen)
              _buildSmallScreenHeader(avis)
            else
              _buildNormalScreenHeader(avis),

            SizedBox(height: 16),

            // 💬 Commentaire
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote, color: Colors.grey[500], size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Mon commentaire',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    avis.commentaire,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 En-tête pour petits écrans - VERSION EMPILÉE
  Widget _buildSmallScreenHeader(Avis avis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne 1: Logo + Nom salon
        Row(
          children: [
            // Logo salon (plus petit)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: avis.logoUrl.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  avis.logoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.store, color: Colors.grey[400], size: 20);
                  },
                ),
              )
                  : Icon(Icons.store, color: Colors.grey[400], size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                avis.salonNom ?? 'Salon inconnu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Ligne 2: Étoiles + Note + Badge
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    Icons.star,
                    size: 18,
                    color: i < avis.note ? Colors.amber : Colors.grey[300],
                  )),
                  SizedBox(width: 6),
                  Text(
                    '${avis.note}/5',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCouleurNote(avis.note),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTexteNote(avis.note),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Ligne 3: Date + Boutons d'action
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (avis.dateFormatee.isNotEmpty)
              Expanded(
                child: Text(
                  'Avis donné le ${avis.dateFormatee}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Boutons d'action compacts
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    onPressed: () => _modifierAvis(avis),
                    icon: Icon(Icons.edit, color: Colors.blue, size: 18),
                    tooltip: 'Modifier',
                    padding: EdgeInsets.all(6),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
                SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    onPressed: () => _supprimerAvis(avis),
                    icon: Icon(Icons.delete, color: Colors.red, size: 18),
                    tooltip: 'Supprimer',
                    padding: EdgeInsets.all(6),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 💻 En-tête pour écrans normaux - VERSION ORIGINALE
  Widget _buildNormalScreenHeader(Avis avis) {
    return Row(
      children: [
        // Logo salon
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: avis.logoUrl.isNotEmpty
              ? ClipOval(
            child: Image.network(
              avis.logoUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.store, color: Colors.grey[400]);
              },
            ),
          )
              : Icon(Icons.store, color: Colors.grey[400]),
        ),

        SizedBox(width: 12),

        // Infos salon et étoiles
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avis.salonNom ?? 'Salon inconnu',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              // ⭐ Étoiles à côté du nom
              Wrap(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(5, (i) => Icon(
                        Icons.star,
                        size: 20,
                        color: i < avis.note ? Colors.amber : Colors.grey[300],
                      )),
                      SizedBox(width: 8),
                      Text(
                        '${avis.note}/5',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCouleurNote(avis.note),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTexteNote(avis.note),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (avis.dateFormatee.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Avis donné le ${avis.dateFormatee}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Boutons d'action directs
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton modifier (stylo)
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _modifierAvis(avis),
                icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: 'Modifier',
              ),
            ),
            SizedBox(width: 8),
            // Bouton supprimer (poubelle)
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _supprimerAvis(avis),
                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Supprimer',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🎨 Couleur selon la note
  Color _getCouleurNote(int note) {
    if (note <= 2) return Colors.red;
    if (note == 3) return Colors.orange;
    if (note == 4) return Colors.blue;
    return Colors.green;
  }

  /// 📝 Texte selon la note
  String _getTexteNote(int note) {
    switch (note) {
      case 1:
        return 'Très décevant';
      case 2:
        return 'Décevant';
      case 3:
        return 'Correct';
      case 4:
        return 'Très bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  /// 🔄 Widget d'état vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Aucun avis donné',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore donné d\'avis sur vos rendez-vous.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back),
              label: Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ❌ Widget d'état d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _chargerMesAvis,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes avis'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_mesAvis.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: isSmallScreen ? 8 : 16),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: 6
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${_mesAvis.length} avis',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _chargerMesAvis,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Chargement de vos avis...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        )
            : _errorMessage != null
            ? _buildErrorState()
            : _mesAvis.isEmpty
            ? _buildEmptyState()
            : Column(
          children: [
            // 📊 En-tête statistiques - RESPONSIVE
            Container(
              margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_mesAvis.length}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Avis donnés',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isSmallScreen ? 35 : 40,
                    color: Colors.white30,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          (_mesAvis.map((a) => a.note).reduce((a, b) => a + b) / _mesAvis.length).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Note moyenne',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 📋 Liste des avis
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 16),
                itemCount: _mesAvis.length,
                itemBuilder: (context, index) {
                  final avis = _mesAvis[index];
                  return _buildAvisCard(avis);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📝 Dialog pour modifier un avis - VERSION RESPONSIVE
class _ModifierAvisDialog extends StatefulWidget {
  final Avis avis;
  final VoidCallback onAvisModifie;

  const _ModifierAvisDialog({
    required this.avis,
    required this.onAvisModifie,
  });

  @override
  _ModifierAvisDialogState createState() => _ModifierAvisDialogState();
}

class _ModifierAvisDialogState extends State<_ModifierAvisDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentaireController;
  late int _note;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentaireController = TextEditingController(text: widget.avis.commentaire);
    _note = widget.avis.note;
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  /// ⭐ Construire le sélecteur d'étoiles - VERSION COMPACTE
  Widget _buildStarRating() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouvelle note',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _note = starNumber;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 1 : 2),
                child: Icon(
                  starNumber <= _note ? Icons.star : Icons.star_border,
                  size: isSmallScreen ? 25 : 30,
                  color: starNumber <= _note ? Colors.amber : Colors.grey[400],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _soumettreModification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await AvisService.modifierAvis(
        context: context,
        avisId: widget.avis.id!,
        note: _note,
        commentaire: _commentaireController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          widget.onAvisModifie();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 60),
                    const SizedBox(height: 10),
                    const Text("Avis modifié !", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );

          Future.delayed(const Duration(milliseconds: 1100), () {
            Navigator.of(context).pop();
            Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isSmallScreen = screenWidth < 400;

    // 🔧 Hauteur disponible après déduction du clavier
    final availableHeight = screenHeight - keyboardHeight - 100; // Marge de sécurité

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenWidth * 0.95 : 500,
          maxHeight: availableHeight > 300 ? availableHeight : 300, // Minimum 300px
        ),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Padding réduit
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre - COMPACT
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange, size: isSmallScreen ? 20 : 24),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Modifier mon avis',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: isSmallScreen ? 20 : 24),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.all(4),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 8 : 12),

              // Info salon - COMPACT
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, color: Colors.grey[600], size: isSmallScreen ? 16 : 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.avis.salonNom ?? 'Salon inconnu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 10 : 15),

              // Sélecteur d'étoiles - COMPACT
              _buildStarRating(),

              SizedBox(height: isSmallScreen ? 10 : 15),

              // Champ commentaire - FLEXIBLE
              Text(
                'Nouveau commentaire',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),

              // ✅ SOLUTION: Flexible au lieu d'Expanded + hauteur minimale
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: isSmallScreen ? 80 : 100,
                    maxHeight: keyboardHeight > 0 ? 120 : 200, // Plus petit si clavier ouvert
                  ),
                  child: TextFormField(
                    controller: _commentaireController,
                    maxLines: null,
                    expands: true,
                    maxLength: 500,
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    decoration: InputDecoration(
                      hintText: 'Modifiez votre commentaire... (min 10 caractères)',
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                      ),
                      contentPadding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      counterStyle: TextStyle(fontSize: 10),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez écrire un commentaire';
                      }
                      if (value.trim().length < 10) {
                        return 'Le commentaire doit contenir au moins 10 caractères';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Boutons d'action - RESPONSIVE
              if (isSmallScreen)
              // Version empilée pour petits écrans
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _soumettreModification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isSubmitting
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Modification...'),
                          ],
                        )
                            : Text('Modifier'),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Annuler'),
                      ),
                    ),
                  ],
                )
              else
              // Version côte à côte pour écrans normaux
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: Text('Annuler'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _soumettreModification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Modification...'),
                          ],
                        )
                            : Text('Modifier'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}






// // pages/avis/mes_avis_page.dart
// import 'dart:async';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../models/avis.dart';
// import 'services/avis_service.dart';
//
// class MesAvisPage extends StatefulWidget {
//   const MesAvisPage({super.key});
//
//   @override
//   _MesAvisPageState createState() => _MesAvisPageState();
// }
//
// class _MesAvisPageState extends State<MesAvisPage> {
//   List<Avis> _mesAvis = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerMesAvis();
//   }
//
//   /// 🔄 Charger tous mes avis
//   Future<void> _chargerMesAvis() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       final avisList = await AvisService.getMesAvis(context: context);
//
//       if (mounted) {
//         setState(() {
//           _mesAvis = avisList;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur lors du chargement des avis: $e");
//       }
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// ✏️ Modifier un avis
//   void _modifierAvis(Avis avis) {
//     showDialog(
//       context: context,
//       builder: (context) => _ModifierAvisDialog(
//         avis: avis,
//         onAvisModifie: () {
//           _chargerMesAvis();
//         },
//       ),
//     );
//   }
//
//   /// 🗑️ Supprimer un avis
//   void _supprimerAvis(Avis avis) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.red),
//             SizedBox(width: 8),
//             Expanded(child: Text('Supprimer l\'avis')),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
//             SizedBox(height: 12),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     avis.salonNom ?? 'Salon inconnu',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 4),
//                   Row(
//                     children: [
//                       ...List.generate(5, (i) => Icon(
//                         Icons.star,
//                         size: 16,
//                         color: i < avis.note ? Colors.amber : Colors.grey[300],
//                       )),
//                       SizedBox(width: 8),
//                       Text('${avis.note}/5'),
//                     ],
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     avis.commentaire,
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 12),
//             Text(
//               '⚠️ Cette action est irréversible.',
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Annuler'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _confirmerSuppressionAvis(avis);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: Text('Supprimer'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 🗑️ Confirmer la suppression
//   Future<void> _confirmerSuppressionAvis(Avis avis) async {
//     try {
//       final result = await AvisService.supprimerAvis(
//         context: context,
//         avisId: avis.id!,
//       );
//
//       if (result.success) {
//         // ✅ CORRECTION: Recharger AVANT d'afficher le succès
//         await _chargerMesAvis();
//
//         if (mounted) {
//           // Message de succès
//           showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) => Dialog(
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               child: Container(
//                 width: 100,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.green, size: 60),
//                     const SizedBox(height: 10),
//                     const Text("Avis supprimé !", style: TextStyle(fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ),
//             ),
//           );
//
//           Future.delayed(const Duration(milliseconds: 1500), () {
//             if (mounted) Navigator.of(context).pop(); // Fermer succès
//           });
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   Icon(Icons.error, color: Colors.white),
//                   SizedBox(width: 8),
//                   Expanded(child: Text(result.message)),
//                 ],
//               ),
//               backgroundColor: Colors.red,
//               duration: Duration(seconds: 4),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur lors de la suppression: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   /// Construire une carte d'avis - VERSION RESPONSIVE
//   Widget _buildAvisCard(Avis avis) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//
//     return Card(
//       margin: EdgeInsets.symmetric(
//           horizontal: isSmallScreen ? 8 : 16,
//           vertical: 8
//       ),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🏪 En-tête salon - LAYOUT RESPONSIVE
//             if (isSmallScreen)
//               _buildSmallScreenHeader(avis)
//             else
//               _buildNormalScreenHeader(avis),
//
//             SizedBox(height: 16),
//
//             // 💬 Commentaire
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.format_quote, color: Colors.grey[500], size: 16),
//                       SizedBox(width: 4),
//                       Text(
//                         'Mon commentaire',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     avis.commentaire,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[800],
//                       height: 1.4,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// 📱 En-tête pour petits écrans - VERSION EMPILÉE
//   Widget _buildSmallScreenHeader(Avis avis) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Ligne 1: Logo + Nom salon
//         Row(
//           children: [
//             // Logo salon (plus petit)
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.grey[200],
//               ),
//               child: avis.logoUrl.isNotEmpty
//                   ? ClipOval(
//                 child: Image.network(
//                   avis.logoUrl,
//                   width: 40,
//                   height: 40,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Icon(Icons.store, color: Colors.grey[400], size: 20);
//                   },
//                 ),
//               )
//                   : Icon(Icons.store, color: Colors.grey[400], size: 20),
//             ),
//             SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 avis.salonNom ?? 'Salon inconnu',
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//
//         SizedBox(height: 12),
//
//         // Ligne 2: Étoiles + Note + Badge
//         Row(
//           children: [
//             Expanded(
//               child: Row(
//                 children: [
//                   ...List.generate(5, (i) => Icon(
//                     Icons.star,
//                     size: 18,
//                     color: i < avis.note ? Colors.amber : Colors.grey[300],
//                   )),
//                   SizedBox(width: 6),
//                   Text(
//                     '${avis.note}/5',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: _getCouleurNote(avis.note),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       _getTexteNote(avis.note),
//                       style: TextStyle(
//                         fontSize: 9,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//
//         // Ligne 3: Date + Boutons d'action
//         SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             if (avis.dateFormatee.isNotEmpty)
//               Expanded(
//                 child: Text(
//                   'Avis donné le ${avis.dateFormatee}',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey[600],
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             // Boutons d'action compacts
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: IconButton(
//                     onPressed: () => _modifierAvis(avis),
//                     icon: Icon(Icons.edit, color: Colors.blue, size: 18),
//                     tooltip: 'Modifier',
//                     padding: EdgeInsets.all(6),
//                     constraints: BoxConstraints(minWidth: 32, minHeight: 32),
//                   ),
//                 ),
//                 SizedBox(width: 6),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: IconButton(
//                     onPressed: () => _supprimerAvis(avis),
//                     icon: Icon(Icons.delete, color: Colors.red, size: 18),
//                     tooltip: 'Supprimer',
//                     padding: EdgeInsets.all(6),
//                     constraints: BoxConstraints(minWidth: 32, minHeight: 32),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   /// 💻 En-tête pour écrans normaux - VERSION ORIGINALE
//   Widget _buildNormalScreenHeader(Avis avis) {
//     return Row(
//       children: [
//         // Logo salon
//         Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.grey[200],
//           ),
//           child: avis.logoUrl.isNotEmpty
//               ? ClipOval(
//             child: Image.network(
//               avis.logoUrl,
//               width: 50,
//               height: 50,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Icon(Icons.store, color: Colors.grey[400]);
//               },
//             ),
//           )
//               : Icon(Icons.store, color: Colors.grey[400]),
//         ),
//
//         SizedBox(width: 12),
//
//         // Infos salon et étoiles
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 avis.salonNom ?? 'Salon inconnu',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 4),
//               // ⭐ Étoiles à côté du nom
//               Wrap(
//                 children: [
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ...List.generate(5, (i) => Icon(
//                         Icons.star,
//                         size: 20,
//                         color: i < avis.note ? Colors.amber : Colors.grey[300],
//                       )),
//                       SizedBox(width: 8),
//                       Text(
//                         '${avis.note}/5',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: _getCouleurNote(avis.note),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           _getTexteNote(avis.note),
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               if (avis.dateFormatee.isNotEmpty)
//                 Padding(
//                   padding: EdgeInsets.only(top: 4),
//                   child: Text(
//                     'Avis donné le ${avis.dateFormatee}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//
//         // Boutons d'action directs
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Bouton modifier (stylo)
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: IconButton(
//                 onPressed: () => _modifierAvis(avis),
//                 icon: Icon(Icons.edit, color: Colors.blue, size: 20),
//                 tooltip: 'Modifier',
//               ),
//             ),
//             SizedBox(width: 8),
//             // Bouton supprimer (poubelle)
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: IconButton(
//                 onPressed: () => _supprimerAvis(avis),
//                 icon: Icon(Icons.delete, color: Colors.red, size: 20),
//                 tooltip: 'Supprimer',
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   /// 🎨 Couleur selon la note
//   Color _getCouleurNote(int note) {
//     if (note <= 2) return Colors.red;
//     if (note == 3) return Colors.orange;
//     if (note == 4) return Colors.blue;
//     return Colors.green;
//   }
//
//   /// 📝 Texte selon la note
//   String _getTexteNote(int note) {
//     switch (note) {
//       case 1:
//         return 'Très décevant';
//       case 2:
//         return 'Décevant';
//       case 3:
//         return 'Correct';
//       case 4:
//         return 'Très bien';
//       case 5:
//         return 'Excellent';
//       default:
//         return '';
//     }
//   }
//
//   /// 🔄 Widget d'état vide
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.rate_review_outlined,
//               size: 80,
//               color: Colors.grey[400],
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Aucun avis donné',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Vous n\'avez pas encore donné d\'avis sur vos rendez-vous.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[500],
//               ),
//             ),
//             SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () => Navigator.pop(context),
//               icon: Icon(Icons.arrow_back),
//               label: Text('Retour'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// ❌ Widget d'état d'erreur
//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 80,
//               color: Colors.red[400],
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Erreur de chargement',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red[600],
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               _errorMessage ?? 'Une erreur est survenue',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerMesAvis,
//               icon: Icon(Icons.refresh),
//               label: Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mes avis'),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           if (_mesAvis.isNotEmpty)
//             Padding(
//               padding: EdgeInsets.only(right: isSmallScreen ? 8 : 16),
//               child: Center(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                       horizontal: isSmallScreen ? 8 : 12,
//                       vertical: 6
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Text(
//                     '${_mesAvis.length} avis',
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 12 : 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _chargerMesAvis,
//         child: _isLoading
//             ? Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: Colors.orange),
//               SizedBox(height: 16),
//               Text(
//                 'Chargement de vos avis...',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         )
//             : _errorMessage != null
//             ? _buildErrorState()
//             : _mesAvis.isEmpty
//             ? _buildEmptyState()
//             : Column(
//           children: [
//             // 📊 En-tête statistiques - RESPONSIVE
//             Container(
//               margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
//               padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.orange, Colors.deepOrange],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Text(
//                           '${_mesAvis.length}',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 20 : 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           'Avis donnés',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 10 : 12,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     width: 1,
//                     height: isSmallScreen ? 35 : 40,
//                     color: Colors.white30,
//                   ),
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Text(
//                           (_mesAvis.map((a) => a.note).reduce((a, b) => a + b) / _mesAvis.length).toStringAsFixed(1),
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 20 : 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           'Note moyenne',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 10 : 12,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // 📋 Liste des avis
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.only(bottom: 16),
//                 itemCount: _mesAvis.length,
//                 itemBuilder: (context, index) {
//                   final avis = _mesAvis[index];
//                   return _buildAvisCard(avis);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// 📝 Dialog pour modifier un avis - VERSION RESPONSIVE
// class _ModifierAvisDialog extends StatefulWidget {
//   final Avis avis;
//   final VoidCallback onAvisModifie;
//
//   const _ModifierAvisDialog({
//     required this.avis,
//     required this.onAvisModifie,
//   });
//
//   @override
//   _ModifierAvisDialogState createState() => _ModifierAvisDialogState();
// }
//
// class _ModifierAvisDialogState extends State<_ModifierAvisDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _commentaireController;
//   late int _note;
//   bool _isSubmitting = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _commentaireController = TextEditingController(text: widget.avis.commentaire);
//     _note = widget.avis.note;
//   }
//
//   @override
//   void dispose() {
//     _commentaireController.dispose();
//     super.dispose();
//   }
//
//   /// ⭐ Construire le sélecteur d'étoiles
//   Widget _buildStarRating() {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Nouvelle note',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: 12),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(5, (index) {
//             final starNumber = index + 1;
//             return GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _note = starNumber;
//                 });
//               },
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
//                 child: Icon(
//                   starNumber <= _note ? Icons.star : Icons.star_border,
//                   size: isSmallScreen ? 30 : 35,
//                   color: starNumber <= _note ? Colors.amber : Colors.grey[400],
//                 ),
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _soumettreModification() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     try {
//       final result = await AvisService.modifierAvis(
//         context: context,
//         avisId: widget.avis.id!,
//         note: _note,
//         commentaire: _commentaireController.text.trim(),
//       );
//
//       if (mounted) {
//         if (result.success) {
//           widget.onAvisModifie();
//
//           showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) => Dialog(
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               child: Container(
//                 width: 100,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.green, size: 60),
//                     const SizedBox(height: 10),
//                     const Text("Avis modifié !", style: TextStyle(fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ),
//             ),
//           );
//
//           Future.delayed(const Duration(milliseconds: 1100), () {
//             Navigator.of(context).pop();
//             Navigator.pop(context);
//           });
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   Icon(Icons.error, color: Colors.white),
//                   SizedBox(width: 8),
//                   Expanded(child: Text(result.message)),
//                 ],
//               ),
//               backgroundColor: Colors.red,
//               duration: Duration(seconds: 4),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur inattendue: $e'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 4),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSubmitting = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 400;
//
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: isSmallScreen ? screenWidth * 0.95 : 500,
//           maxHeight: screenHeight * 0.8,
//         ),
//         padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Titre
//               Row(
//                 children: [
//                   Icon(Icons.edit, color: Colors.orange),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Modifier mon avis',
//                       style: GoogleFonts.poppins(
//                         fontSize: isSmallScreen ? 16 : 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: Icon(Icons.close),
//                     constraints: BoxConstraints(minWidth: 32, minHeight: 32),
//                   ),
//                 ],
//               ),
//
//               SizedBox(height: 16),
//
//               // Info salon
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.store, color: Colors.grey[600]),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         widget.avis.salonNom ?? 'Salon inconnu',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: isSmallScreen ? 14 : 16,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Sélecteur d'étoiles
//               _buildStarRating(),
//
//               SizedBox(height: 20),
//
//               // Champ commentaire
//               Text(
//                 'Nouveau commentaire',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Expanded(
//                 child: TextFormField(
//                   controller: _commentaireController,
//                   maxLines: null,
//                   expands: true,
//                   maxLength: 500,
//                   style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//                   decoration: InputDecoration(
//                     hintText: 'Modifiez votre commentaire... (minimum 10 caractères)',
//                     hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(color: Colors.orange, width: 2),
//                     ),
//                     contentPadding: EdgeInsets.all(12),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Veuillez écrire un commentaire';
//                     }
//                     if (value.trim().length < 10) {
//                       return 'Le commentaire doit contenir au moins 10 caractères';
//                     }
//                     return null;
//                   },
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Boutons d'action - RESPONSIVE
//               if (isSmallScreen)
//               // Version empilée pour petits écrans
//                 Column(
//                   children: [
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isSubmitting ? null : _soumettreModification,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: _isSubmitting
//                             ? Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               width: 16,
//                               height: 16,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Text('Modification...'),
//                           ],
//                         )
//                             : Text('Modifier'),
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: _isSubmitting ? null : () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: Text('Annuler'),
//                       ),
//                     ),
//                   ],
//                 )
//               else
//               // Version côte à côte pour écrans normaux
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: _isSubmitting ? null : () => Navigator.pop(context),
//                         child: Text('Annuler'),
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     Expanded(
//                       flex: 2,
//                       child: ElevatedButton(
//                         onPressed: _isSubmitting ? null : _soumettreModification,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,
//                           foregroundColor: Colors.white,
//                         ),
//                         child: _isSubmitting
//                             ? Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               width: 16,
//                               height: 16,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Text('Modification...'),
//                           ],
//                         )
//                             : Text('Modifier'),
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
// // // pages/avis/mes_avis_page.dart
// // import 'dart:async';
// //
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// //
// // import '../../models/avis.dart';
// // import 'services/avis_service.dart';
// //
// // class MesAvisPage extends StatefulWidget {
// //   const MesAvisPage({super.key});
// //
// //   @override
// //   _MesAvisPageState createState() => _MesAvisPageState();
// // }
// //
// // class _MesAvisPageState extends State<MesAvisPage> {
// //   List<Avis> _mesAvis = [];
// //   bool _isLoading = true;
// //   String? _errorMessage;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _chargerMesAvis();
// //   }
// //
// //   /// 🔄 Charger tous mes avis
// //   Future<void> _chargerMesAvis() async {
// //     try {
// //       setState(() {
// //         _isLoading = true;
// //         _errorMessage = null;
// //       });
// //
// //       final avisList = await AvisService.getMesAvis(context: context);
// //
// //       if (mounted) {
// //         setState(() {
// //           _mesAvis = avisList;
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       if (kDebugMode) {
// //         print("❌ Erreur lors du chargement des avis: $e");
// //       }
// //       if (mounted) {
// //         setState(() {
// //           _errorMessage = e.toString();
// //           _isLoading = false;
// //         });
// //       }
// //     }
// //   }
// //
// //   /// ✏️ Modifier un avis
// //   void _modifierAvis(Avis avis) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => _ModifierAvisDialog(
// //         avis: avis,
// //         onAvisModifie: () {
// //           _chargerMesAvis();
// //         },
// //       ),
// //     );
// //   }
// //
// //   /// 🗑️ Supprimer un avis
// //   void _supprimerAvis(Avis avis) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Row(
// //           children: [
// //             Icon(Icons.warning, color: Colors.red),
// //             SizedBox(width: 8),
// //             Text('Supprimer l\'avis'),
// //           ],
// //         ),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
// //             SizedBox(height: 12),
// //             Container(
// //               padding: EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: Colors.grey[100],
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     avis.salonNom ?? 'Salon inconnu',
// //                     style: TextStyle(fontWeight: FontWeight.bold),
// //                   ),
// //                   SizedBox(height: 4),
// //                   Row(
// //                     children: [
// //                       ...List.generate(5, (i) => Icon(
// //                         Icons.star,
// //                         size: 16,
// //                         color: i < avis.note ? Colors.amber : Colors.grey[300],
// //                       )),
// //                       SizedBox(width: 8),
// //                       Text('${avis.note}/5'),
// //                     ],
// //                   ),
// //                   SizedBox(height: 4),
// //                   Text(
// //                     avis.commentaire,
// //                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// //                     maxLines: 2,
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             SizedBox(height: 12),
// //             Text(
// //               '⚠️ Cette action est irréversible.',
// //               style: TextStyle(
// //                 color: Colors.red,
// //                 fontSize: 12,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text('Annuler'),
// //           ),
// //           ElevatedButton(
// //             onPressed: () async {
// //               Navigator.pop(context);
// //               await _confirmerSuppressionAvis(avis);
// //             },
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: Colors.red,
// //               foregroundColor: Colors.white,
// //             ),
// //             child: Text('Supprimer'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   /// 🗑️ Confirmer la suppression
// //   Future<void> _confirmerSuppressionAvis(Avis avis) async {
// //     try {
// //       // // Afficher le loader
// //       // showDialog(
// //       //   context: context,
// //       //   barrierDismissible: false,
// //       //   builder: (context) => Center(
// //       //     child: Container(
// //       //       padding: EdgeInsets.all(20),
// //       //       decoration: BoxDecoration(
// //       //         color: Colors.white,
// //       //         borderRadius: BorderRadius.circular(12),
// //       //       ),
// //       //       child: Column(
// //       //         mainAxisSize: MainAxisSize.min,
// //       //         children: [
// //       //           CircularProgressIndicator(color: Colors.red),
// //       //           SizedBox(height: 16),
// //       //           Text('Suppression en cours...'),
// //       //         ],
// //       //       ),
// //       //     ),
// //       //   ),
// //       // );
// //
// //       final result = await AvisService.supprimerAvis(
// //         context: context,
// //         avisId: avis.id!,
// //       );
// //
// //       // ✅ CORRECTION: Vérifier mounted avant chaque Navigator
// //       if (mounted) Navigator.pop(context); // Fermer loader
// //
// //       if (result.success) {
// //         // ✅ CORRECTION: Recharger AVANT d'afficher le succès
// //         await _chargerMesAvis();
// //
// //         if (mounted) {
// //           // Message de succès
// //           showDialog(
// //             context: context,
// //             barrierDismissible: false,
// //             builder: (context) => Dialog(
// //               backgroundColor: Colors.transparent,
// //               elevation: 0,
// //               child: Container(
// //                 width: 100,
// //                 height: 100,
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(16),
// //                 ),
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(Icons.check_circle, color: Colors.green, size: 60),
// //                     const SizedBox(height: 10),
// //                     const Text("Avis supprimé !", style: TextStyle(fontWeight: FontWeight.bold)),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //
// //           Future.delayed(const Duration(milliseconds: 1500), () {
// //             if (mounted) Navigator.of(context).pop(); // Fermer succès
// //           });
// //         }
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Row(
// //                 children: [
// //                   Icon(Icons.error, color: Colors.white),
// //                   SizedBox(width: 8),
// //                   Expanded(child: Text(result.message)),
// //                 ],
// //               ),
// //               backgroundColor: Colors.red,
// //               duration: Duration(seconds: 4),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       // Fermer le loader si encore ouvert
// //       if (mounted) Navigator.pop(context);
// //
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Erreur lors de la suppression: $e'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }
// //
// //   // /// 🗑️ Confirmer la suppression
// //   // Future<void> _confirmerSuppressionAvis(Avis avis) async {
// //   //   try {
// //   //     // Afficher le loader
// //   //     showDialog(
// //   //       context: context,
// //   //       barrierDismissible: false,
// //   //       builder: (context) => Center(
// //   //         child: Container(
// //   //           padding: EdgeInsets.all(20),
// //   //           decoration: BoxDecoration(
// //   //             color: Colors.white,
// //   //             borderRadius: BorderRadius.circular(12),
// //   //           ),
// //   //           child: Column(
// //   //             mainAxisSize: MainAxisSize.min,
// //   //             children: [
// //   //               CircularProgressIndicator(color: Colors.red),
// //   //               SizedBox(height: 16),
// //   //               Text('Suppression en cours...'),
// //   //             ],
// //   //           ),
// //   //         ),
// //   //       ),
// //   //     );
// //   //
// //   //     final result = await AvisService.supprimerAvis(
// //   //       context: context,
// //   //       avisId: avis.id!,
// //   //     );
// //   //
// //   //     if (mounted) Navigator.pop(context);
// //   //     if (result.success) {
// //   //       if (mounted) Navigator.pop(context);
// //   //
// //   //       // Message modal au centre comme les promotions
// //   //       showDialog(
// //   //         context: context,
// //   //         barrierDismissible: false,
// //   //         builder: (context) => Dialog(
// //   //           backgroundColor: Colors.transparent,
// //   //           elevation: 0,
// //   //           child: Container(
// //   //             width: 100,
// //   //             height: 100,
// //   //             decoration: BoxDecoration(
// //   //               color: Colors.white,
// //   //               borderRadius: BorderRadius.circular(16),
// //   //             ),
// //   //             child: Column(
// //   //               mainAxisAlignment: MainAxisAlignment.center,
// //   //               children: [
// //   //                 Icon(Icons.check_circle, color: Colors.green, size: 60),
// //   //                 const SizedBox(height: 10),
// //   //                 const Text("Avis supprimé !", style: TextStyle(fontWeight: FontWeight.bold)),
// //   //               ],
// //   //             ),
// //   //           ),
// //   //         ),
// //   //       );
// //   //
// //   //       Future.delayed(const Duration(milliseconds: 1500), () {
// //   //         Navigator.of(context).pop(); // Ferme le dialog de succès
// //   //       });
// //   //
// //   //       // Recharger la liste
// //   //       _chargerMesAvis();
// //   //     } else {
// //   //       // ❌ Erreur
// //   //       ScaffoldMessenger.of(context).showSnackBar(
// //   //         SnackBar(
// //   //           content: Row(
// //   //             children: [
// //   //               Icon(Icons.error, color: Colors.white),
// //   //               SizedBox(width: 8),
// //   //               Expanded(child: Text(result.message)),
// //   //             ],
// //   //           ),
// //   //           backgroundColor: Colors.red,
// //   //           duration: Duration(seconds: 4),
// //   //         ),
// //   //       );
// //   //     }
// //   //   } catch (e) {
// //   //     // Fermer le loader si encore ouvert
// //   //     if (mounted) Navigator.pop(context);
// //   //
// //   //     ScaffoldMessenger.of(context).showSnackBar(
// //   //       SnackBar(
// //   //         content: Text('Erreur lors de la suppression: $e'),
// //   //         backgroundColor: Colors.red,
// //   //       ),
// //   //     );
// //   //   }
// //   // }
// //
// //   /// Construire une carte d'avis
// //   Widget _buildAvisCard(Avis avis) {
// //     return Card(
// //       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //       elevation: 2,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Padding(
// //         padding: EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // 🏪 En-tête salon
// //             Row(
// //               children: [
// //                 // Logo salon
// //                 Container(
// //                   width: 50,
// //                   height: 50,
// //                   decoration: BoxDecoration(
// //                     shape: BoxShape.circle,
// //                     color: Colors.grey[200],
// //                   ),
// //                   child: avis.logoUrl.isNotEmpty
// //                       ? ClipOval(
// //                     child: Image.network(
// //                       avis.logoUrl,
// //                       width: 50,
// //                       height: 50,
// //                       fit: BoxFit.cover,
// //                       errorBuilder: (context, error, stackTrace) {
// //                         return Icon(Icons.store, color: Colors.grey[400]);
// //                       },
// //                     ),
// //                   )
// //                       : Icon(Icons.store, color: Colors.grey[400]),
// //                 ),
// //
// //                 SizedBox(width: 12),
// //
// //                 // Infos salon et étoiles
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         avis.salonNom ?? 'Salon inconnu',
// //                         style: GoogleFonts.poppins(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       SizedBox(height: 4),
// //                       // ⭐ Étoiles à côté du nom
// //                       Row(
// //                         children: [
// //                           ...List.generate(5, (i) => Icon(
// //                             Icons.star,
// //                             size: 20,
// //                             color: i < avis.note ? Colors.amber : Colors.grey[300],
// //                           )),
// //                           SizedBox(width: 8),
// //                           Text(
// //                             '${avis.note}/5',
// //                             style: TextStyle(
// //                               fontSize: 14,
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.grey[700],
// //                             ),
// //                           ),
// //                           SizedBox(width: 8),
// //                           Container(
// //                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //                             decoration: BoxDecoration(
// //                               color: _getCouleurNote(avis.note),
// //                               borderRadius: BorderRadius.circular(8),
// //                             ),
// //                             child: Text(
// //                               _getTexteNote(avis.note),
// //                               style: TextStyle(
// //                                 fontSize: 10,
// //                                 color: Colors.white,
// //                                 fontWeight: FontWeight.w600,
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       if (avis.dateFormatee.isNotEmpty)
// //                         Padding(
// //                           padding: EdgeInsets.only(top: 4),
// //                           child: Text(
// //                             'Avis donné le ${avis.dateFormatee}',
// //                             style: TextStyle(
// //                               fontSize: 12,
// //                               color: Colors.grey[600],
// //                             ),
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //
// //                 // Boutons d'action directs
// //                 Row(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     // Bouton modifier (stylo)
// //                     Container(
// //                       decoration: BoxDecoration(
// //                         color: Colors.blue.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: IconButton(
// //                         onPressed: () => _modifierAvis(avis),
// //                         icon: Icon(Icons.edit, color: Colors.blue, size: 20),
// //                         tooltip: 'Modifier',
// //                       ),
// //                     ),
// //                     SizedBox(width: 8),
// //                     // Bouton supprimer (poubelle)
// //                     Container(
// //                       decoration: BoxDecoration(
// //                         color: Colors.red.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: IconButton(
// //                         onPressed: () => _supprimerAvis(avis),
// //                         icon: Icon(Icons.delete, color: Colors.red, size: 20),
// //                         tooltip: 'Supprimer',
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //
// //             SizedBox(height: 16),
// //
// //             // 💬 Commentaire
// //             Container(
// //               padding: EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: Colors.grey[50],
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(color: Colors.grey[200]!),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Row(
// //                     children: [
// //                       Icon(Icons.format_quote, color: Colors.grey[500], size: 16),
// //                       SizedBox(width: 4),
// //                       Text(
// //                         'Mon commentaire',
// //                         style: TextStyle(
// //                           fontSize: 12,
// //                           fontWeight: FontWeight.w600,
// //                           color: Colors.grey[600],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   SizedBox(height: 8),
// //                   Text(
// //                     avis.commentaire,
// //                     style: TextStyle(
// //                       fontSize: 14,
// //                       color: Colors.grey[800],
// //                       height: 1.4,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// 🎨 Couleur selon la note
// //   Color _getCouleurNote(int note) {
// //     if (note <= 2) return Colors.red;
// //     if (note == 3) return Colors.orange;
// //     if (note == 4) return Colors.blue;
// //     return Colors.green;
// //   }
// //
// //   /// 📝 Texte selon la note
// //   String _getTexteNote(int note) {
// //     switch (note) {
// //       case 1:
// //         return 'Très décevant';
// //       case 2:
// //         return 'Décevant';
// //       case 3:
// //         return 'Correct';
// //       case 4:
// //         return 'Très bien';
// //       case 5:
// //         return 'Excellent';
// //       default:
// //         return '';
// //     }
// //   }
// //
// //   /// 🔄 Widget d'état vide
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Padding(
// //         padding: EdgeInsets.all(32),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(
// //               Icons.rate_review_outlined,
// //               size: 80,
// //               color: Colors.grey[400],
// //             ),
// //             SizedBox(height: 16),
// //             Text(
// //               'Aucun avis donné',
// //               style: GoogleFonts.poppins(
// //                 fontSize: 20,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.grey[600],
// //               ),
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               'Vous n\'avez pas encore donné d\'avis sur vos rendez-vous.',
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 color: Colors.grey[500],
// //               ),
// //             ),
// //             SizedBox(height: 24),
// //             ElevatedButton.icon(
// //               onPressed: () => Navigator.pop(context),
// //               icon: Icon(Icons.arrow_back),
// //               label: Text('Retour'),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.orange,
// //                 foregroundColor: Colors.white,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// ❌ Widget d'état d'erreur
// //   Widget _buildErrorState() {
// //     return Center(
// //       child: Padding(
// //         padding: EdgeInsets.all(32),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(
// //               Icons.error_outline,
// //               size: 80,
// //               color: Colors.red[400],
// //             ),
// //             SizedBox(height: 16),
// //             Text(
// //               'Erreur de chargement',
// //               style: GoogleFonts.poppins(
// //                 fontSize: 20,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.red[600],
// //               ),
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               _errorMessage ?? 'Une erreur est survenue',
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 color: Colors.grey[600],
// //               ),
// //             ),
// //             SizedBox(height: 24),
// //             ElevatedButton.icon(
// //               onPressed: _chargerMesAvis,
// //               icon: Icon(Icons.refresh),
// //               label: Text('Réessayer'),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.orange,
// //                 foregroundColor: Colors.white,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Mes avis'),
// //         backgroundColor: Colors.orange,
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //         actions: [
// //           if (_mesAvis.isNotEmpty)
// //             Padding(
// //               padding: EdgeInsets.only(right: 16),
// //               child: Center(
// //                 child: Container(
// //                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //                   decoration: BoxDecoration(
// //                     color: Colors.white.withOpacity(0.2),
// //                     borderRadius: BorderRadius.circular(15),
// //                   ),
// //                   child: Text(
// //                     '${_mesAvis.length} avis',
// //                     style: TextStyle(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //       body: RefreshIndicator(
// //         onRefresh: _chargerMesAvis,
// //         child: _isLoading
// //             ? Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               CircularProgressIndicator(color: Colors.orange),
// //               SizedBox(height: 16),
// //               Text(
// //                 'Chargement de vos avis...',
// //                 style: TextStyle(
// //                   fontSize: 16,
// //                   color: Colors.grey[600],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         )
// //             : _errorMessage != null
// //             ? _buildErrorState()
// //             : _mesAvis.isEmpty
// //             ? _buildEmptyState()
// //             : Column(
// //           children: [
// //             // 📊 En-tête statistiques
// //             Container(
// //               margin: EdgeInsets.all(16),
// //               padding: EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [Colors.orange, Colors.deepOrange],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Expanded(
// //                     child: Column(
// //                       children: [
// //                         Text(
// //                           '${_mesAvis.length}',
// //                           style: TextStyle(
// //                             fontSize: 24,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.white,
// //                           ),
// //                         ),
// //                         Text(
// //                           'Avis donnés',
// //                           style: TextStyle(
// //                             fontSize: 12,
// //                             color: Colors.white70,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   Container(
// //                     width: 1,
// //                     height: 40,
// //                     color: Colors.white30,
// //                   ),
// //                   Expanded(
// //                     child: Column(
// //                       children: [
// //                         Text(
// //                           (_mesAvis.map((a) => a.note).reduce((a, b) => a + b) / _mesAvis.length).toStringAsFixed(1),
// //                           style: TextStyle(
// //                             fontSize: 24,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.white,
// //                           ),
// //                         ),
// //                         Text(
// //                           'Note moyenne',
// //                           style: TextStyle(
// //                             fontSize: 12,
// //                             color: Colors.white70,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             // 📋 Liste des avis
// //             Expanded(
// //               child: ListView.builder(
// //                 padding: EdgeInsets.only(bottom: 16),
// //                 itemCount: _mesAvis.length,
// //                 itemBuilder: (context, index) {
// //                   final avis = _mesAvis[index];
// //                   return _buildAvisCard(avis);
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // /// 📝 Dialog pour modifier un avis
// // class _ModifierAvisDialog extends StatefulWidget {
// //   final Avis avis;
// //   final VoidCallback onAvisModifie;
// //
// //   const _ModifierAvisDialog({
// //     required this.avis,
// //     required this.onAvisModifie,
// //   });
// //
// //   @override
// //   _ModifierAvisDialogState createState() => _ModifierAvisDialogState();
// // }
// //
// // class _ModifierAvisDialogState extends State<_ModifierAvisDialog> {
// //   final _formKey = GlobalKey<FormState>();
// //   late final TextEditingController _commentaireController;
// //   late int _note;
// //   bool _isSubmitting = false;
// //   @override
// //   void initState() {
// //     super.initState();
// //     _commentaireController = TextEditingController(text: widget.avis.commentaire);
// //     _note = widget.avis.note;
// //   }
// //
// //   @override
// //   void dispose() {
// //     _commentaireController.dispose();
// //     super.dispose();
// //   }
// //
// //   /// ⭐ Construire le sélecteur d'étoiles
// //   Widget _buildStarRating() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Nouvelle note',
// //           style: TextStyle(
// //             fontSize: 16,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         SizedBox(height: 12),
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: List.generate(5, (index) {
// //             final starNumber = index + 1;
// //             return GestureDetector(
// //               onTap: () {
// //                 setState(() {
// //                   _note = starNumber;
// //                 });
// //               },
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(horizontal: 4),
// //                 child: Icon(
// //                   starNumber <= _note ? Icons.star : Icons.star_border,
// //                   size: 35,
// //                   color: starNumber <= _note ? Colors.amber : Colors.grey[400],
// //                 ),
// //               ),
// //             );
// //           }),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Future<void> _soumettreModification() async {
// //     if (!_formKey.currentState!.validate()) {
// //       return;
// //     }
// //
// //     setState(() {
// //       _isSubmitting = true;
// //     });
// //
// //     try {
// //       final result = await AvisService.modifierAvis(
// //         context: context,
// //         avisId: widget.avis.id!,
// //         note: _note,
// //         commentaire: _commentaireController.text.trim(),
// //       );
// //
// //       if (mounted) {
// //         if (result.success) {
// //           // Navigator.pop(context);
// //           widget.onAvisModifie();
// //
// //           showDialog(
// //             context: context,
// //             barrierDismissible: false,
// //             builder: (context) => Dialog(
// //               backgroundColor: Colors.transparent,
// //               elevation: 0,
// //               child: Container(
// //                 width: 100,
// //                 height: 100,
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(16),
// //                 ),
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(Icons.check_circle, color: Colors.green, size: 60),
// //                     const SizedBox(height: 10),
// //                     const Text("Avis modifié !", style: TextStyle(fontWeight: FontWeight.bold)),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //
// //           Future.delayed(const Duration(milliseconds: 1100), () {
// //             Navigator.of(context).pop();
// //             Navigator.pop(context);
// //           });
// //
// //           //Navigator.pop(context);
// //           //widget.onAvisModifie();
// //         } else {
// //           // ❌ Erreur
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Row(
// //                 children: [
// //                   Icon(Icons.error, color: Colors.white),
// //                   SizedBox(width: 8),
// //                   Expanded(child: Text(result.message)),
// //                 ],
// //               ),
// //               backgroundColor: Colors.red,
// //               duration: Duration(seconds: 4),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Erreur inattendue: $e'),
// //             backgroundColor: Colors.red,
// //             duration: Duration(seconds: 4),
// //           ),
// //         );
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           _isSubmitting = false;
// //         });
// //       }
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Container(
// //         constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
// //         padding: EdgeInsets.all(20),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               // Titre
// //               Row(
// //                 children: [
// //                   Icon(Icons.edit, color: Colors.orange),
// //                   SizedBox(width: 8),
// //                   Expanded(
// //                     child: Text(
// //                       'Modifier mon avis',
// //                       style: GoogleFonts.poppins(
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                   ),
// //                   IconButton(
// //                     onPressed: () => Navigator.pop(context),
// //                     icon: Icon(Icons.close),
// //                   ),
// //                 ],
// //               ),
// //
// //               SizedBox(height: 16),
// //
// //               // Info salon
// //               Container(
// //                 padding: EdgeInsets.all(12),
// //                 decoration: BoxDecoration(
// //                   color: Colors.grey[100],
// //                   borderRadius: BorderRadius.circular(8),
// //                 ),
// //                 child: Row(
// //                   children: [
// //                     Icon(Icons.store, color: Colors.grey[600]),
// //                     SizedBox(width: 8),
// //                     Expanded(
// //                       child: Text(
// //                         widget.avis.salonNom ?? 'Salon inconnu',
// //                         style: TextStyle(
// //                           fontWeight: FontWeight.w600,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //
// //               SizedBox(height: 20),
// //
// //               // Sélecteur d'étoiles
// //               _buildStarRating(),
// //
// //               SizedBox(height: 20),
// //
// //               // Champ commentaire
// //               Text(
// //                 'Nouveau commentaire',
// //                 style: TextStyle(
// //                   fontSize: 16,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               SizedBox(height: 8),
// //               Expanded(
// //                 child: TextFormField(
// //                   controller: _commentaireController,
// //                   maxLines: null,
// //                   expands: true,
// //                   maxLength: 500,
// //                   decoration: InputDecoration(
// //                     hintText: 'Modifiez votre commentaire... (minimum 10 caractères)',
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     focusedBorder: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                       borderSide: BorderSide(color: Colors.orange, width: 2),
// //                     ),
// //                     contentPadding: EdgeInsets.all(12),
// //                   ),
// //                   validator: (value) {
// //                     if (value == null || value.trim().isEmpty) {
// //                       return 'Veuillez écrire un commentaire';
// //                     }
// //                     if (value.trim().length < 10) {
// //                       return 'Le commentaire doit contenir au moins 10 caractères';
// //                     }
// //                     return null;
// //                   },
// //                 ),
// //               ),
// //
// //               SizedBox(height: 20),
// //
// //               // Boutons d'action
// //               Row(
// //                 children: [
// //                   Expanded(
// //                     child: OutlinedButton(
// //                       onPressed: _isSubmitting ? null : () => Navigator.pop(context),
// //                       child: Text('Annuler'),
// //                     ),
// //                   ),
// //                   SizedBox(width: 12),
// //                   Expanded(
// //                     flex: 2,
// //                     child: ElevatedButton(
// //                       onPressed: _isSubmitting ? null : _soumettreModification,
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.orange,
// //                         foregroundColor: Colors.white,
// //                       ),
// //                       child: _isSubmitting
// //                           ? Row(
// //                         mainAxisAlignment: MainAxisAlignment.center,
// //                         children: [
// //                           SizedBox(
// //                             width: 16,
// //                             height: 16,
// //                             child: CircularProgressIndicator(
// //                               color: Colors.white,
// //                               strokeWidth: 2,
// //                             ),
// //                           ),
// //                           SizedBox(width: 8),
// //                           Text('Modification...'),
// //                         ],
// //                       )
// //                           : Text('Modifier'),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // // pages/avis/mes_avis_page.dart
// // // import 'dart:async';
// // //
// // // import 'package:flutter/foundation.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:google_fonts/google_fonts.dart';
// // //
// // // import '../../models/avis.dart';
// // // import 'services/avis_service.dart';
// // //
// // // class MesAvisPage extends StatefulWidget {
// // //   const MesAvisPage({super.key});
// // //
// // //   @override
// // //   _MesAvisPageState createState() => _MesAvisPageState();
// // // }
// // //
// // // class _MesAvisPageState extends State<MesAvisPage> {
// // //   List<Avis> _mesAvis = [];
// // //   bool _isLoading = true;
// // //   String? _errorMessage;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _chargerMesAvis();
// // //   }
// // //
// // //   /// 🔄 Charger tous mes avis
// // //   Future<void> _chargerMesAvis() async {
// // //     try {
// // //       setState(() {
// // //         _isLoading = true;
// // //         _errorMessage = null;
// // //       });
// // //
// // //       final avisList = await AvisService.getMesAvis(context: context);
// // //
// // //       if (mounted) {
// // //         setState(() {
// // //           _mesAvis = avisList;
// // //           _isLoading = false;
// // //         });
// // //       }
// // //     } catch (e) {
// // //       if (kDebugMode) {
// // //         print("❌ Erreur lors du chargement des avis: $e");
// // //       }
// // //       if (mounted) {
// // //         setState(() {
// // //           _errorMessage = e.toString();
// // //           _isLoading = false;
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   /// ✏️ Modifier un avis
// // //   void _modifierAvis(Avis avis) {
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) => _ModifierAvisDialog(
// // //         avis: avis,
// // //         onAvisModifie: () {
// // //           _chargerMesAvis();
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   /// 🗑️ Supprimer un avis
// // //   void _supprimerAvis(Avis avis) {
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) => AlertDialog(
// // //         title: Row(
// // //           children: [
// // //             Icon(Icons.warning, color: Colors.red),
// // //             SizedBox(width: 8),
// // //             Text('Supprimer l\'avis'),
// // //           ],
// // //         ),
// // //         content: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
// // //             SizedBox(height: 12),
// // //             Container(
// // //               padding: EdgeInsets.all(12),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.grey[100],
// // //                 borderRadius: BorderRadius.circular(8),
// // //               ),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text(
// // //                     avis.salonNom ?? 'Salon inconnu',
// // //                     style: TextStyle(fontWeight: FontWeight.bold),
// // //                   ),
// // //                   SizedBox(height: 4),
// // //                   Row(
// // //                     children: [
// // //                       ...List.generate(5, (i) => Icon(
// // //                         Icons.star,
// // //                         size: 16,
// // //                         color: i < avis.note ? Colors.amber : Colors.grey[300],
// // //                       )),
// // //                       SizedBox(width: 8),
// // //                       Text('${avis.note}/5'),
// // //                     ],
// // //                   ),
// // //                   SizedBox(height: 4),
// // //                   Text(
// // //                     avis.commentaire,
// // //                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// // //                     maxLines: 2,
// // //                     overflow: TextOverflow.ellipsis,
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //             SizedBox(height: 12),
// // //             Text(
// // //               '⚠️ Cette action est irréversible.',
// // //               style: TextStyle(
// // //                 color: Colors.red,
// // //                 fontSize: 12,
// // //                 fontWeight: FontWeight.w500,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(context),
// // //             child: Text('Annuler'),
// // //           ),
// // //           ElevatedButton(
// // //             onPressed: () async {
// // //               Navigator.pop(context);
// // //               await _confirmerSuppressionAvis(avis);
// // //             },
// // //             style: ElevatedButton.styleFrom(
// // //               backgroundColor: Colors.red,
// // //               foregroundColor: Colors.white,
// // //             ),
// // //             child: Text('Supprimer'),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   /// 🗑️ Confirmer la suppression
// // //   Future<void> _confirmerSuppressionAvis(Avis avis) async {
// // //     try {
// // //       // Afficher le loader
// // //       showDialog(
// // //         context: context,
// // //         barrierDismissible: false,
// // //         builder: (context) => Center(
// // //           child: Container(
// // //             padding: EdgeInsets.all(20),
// // //             decoration: BoxDecoration(
// // //               color: Colors.white,
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 CircularProgressIndicator(color: Colors.red),
// // //                 SizedBox(height: 16),
// // //                 Text('Suppression en cours...'),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       );
// // //
// // //       final result = await AvisService.supprimerAvis(
// // //         context: context,
// // //         avisId: avis.id!,
// // //       );
// // //
// // //       if (mounted) Navigator.pop(context);
// // //       if (result.success) {
// // //         if (mounted) Navigator.pop(context);
// // //
// // //         // Message modal au centre comme les promotions
// // //         showDialog(
// // //           context: context,
// // //           barrierDismissible: false,
// // //           builder: (context) => Dialog(
// // //             backgroundColor: Colors.transparent,
// // //             elevation: 0,
// // //             child: Container(
// // //               width: 100,
// // //               height: 100,
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white,
// // //                 borderRadius: BorderRadius.circular(16),
// // //               ),
// // //               child: Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   Icon(Icons.check_circle, color: Colors.green, size: 60),
// // //                   const SizedBox(height: 10),
// // //                   const Text("Avis supprimé !", style: TextStyle(fontWeight: FontWeight.bold)),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         );
// // //
// // //         Future.delayed(const Duration(milliseconds: 1500), () {
// // //           Navigator.of(context).pop(); // Ferme le dialog de succès
// // //         });
// // //
// // //         // Recharger la liste
// // //         _chargerMesAvis();
// // //       } else {
// // //         // ❌ Erreur
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Row(
// // //               children: [
// // //                 Icon(Icons.error, color: Colors.white),
// // //                 SizedBox(width: 8),
// // //                 Expanded(child: Text(result.message)),
// // //               ],
// // //             ),
// // //             backgroundColor: Colors.red,
// // //             duration: Duration(seconds: 4),
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       // Fermer le loader si encore ouvert
// // //       if (mounted) Navigator.pop(context);
// // //
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Erreur lors de la suppression: $e'),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //   /// Construire une carte d'avis
// // //   Widget _buildAvisCard(Avis avis) {
// // //     return Card(
// // //       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //       elevation: 2,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //       child: Padding(
// // //         padding: EdgeInsets.all(16),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             // 🏪 En-tête salon
// // //             Row(
// // //               children: [
// // //                 // Logo salon
// // //                 Container(
// // //                   width: 50,
// // //                   height: 50,
// // //                   decoration: BoxDecoration(
// // //                     shape: BoxShape.circle,
// // //                     color: Colors.grey[200],
// // //                   ),
// // //                   child: avis.logoUrl.isNotEmpty
// // //                       ? ClipOval(
// // //                     child: Image.network(
// // //                       avis.logoUrl,
// // //                       width: 50,
// // //                       height: 50,
// // //                       fit: BoxFit.cover,
// // //                       errorBuilder: (context, error, stackTrace) {
// // //                         return Icon(Icons.store, color: Colors.grey[400]);
// // //                       },
// // //                     ),
// // //                   )
// // //                       : Icon(Icons.store, color: Colors.grey[400]),
// // //                 ),
// // //
// // //                 SizedBox(width: 12),
// // //
// // //                 // Infos salon
// // //                 Expanded(
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Text(
// // //                         avis.salonNom ?? 'Salon inconnu',
// // //                         style: GoogleFonts.poppins(
// // //                           fontSize: 18,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                       if (avis.dateFormatee.isNotEmpty)
// // //                         Text(
// // //                           'Avis donné le ${avis.dateFormatee}',
// // //                           style: TextStyle(
// // //                             fontSize: 14,
// // //                             color: Colors.grey[600],
// // //                           ),
// // //                         ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //
// // //                 // Menu actions
// // //                 PopupMenuButton<String>(
// // //                   icon: Icon(Icons.more_vert, color: Colors.grey[600]),
// // //                   onSelected: (value) {
// // //                     switch (value) {
// // //                       case 'modifier':
// // //                         _modifierAvis(avis);
// // //                         break;
// // //                       case 'supprimer':
// // //                         _supprimerAvis(avis);
// // //                         break;
// // //                     }
// // //                   },
// // //                   itemBuilder: (context) => [
// // //                     PopupMenuItem(
// // //                       value: 'modifier',
// // //                       child: Row(
// // //                         children: [
// // //                           Icon(Icons.edit, color: Colors.blue, size: 20),
// // //                           SizedBox(width: 8),
// // //                           Text('Modifier'),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                     PopupMenuItem(
// // //                       value: 'supprimer',
// // //                       child: Row(
// // //                         children: [
// // //                           Icon(Icons.delete, color: Colors.red, size: 20),
// // //                           SizedBox(width: 8),
// // //                           Text('Supprimer'),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ],
// // //             ),
// // //
// // //             SizedBox(height: 16),
// // //
// // //             // ⭐ Note donnée
// // //             Row(
// // //               children: [
// // //                 ...List.generate(5, (i) => Icon(
// // //                   Icons.star,
// // //                   size: 24,
// // //                   color: i < avis.note ? Colors.amber : Colors.grey[300],
// // //                 )),
// // //                 SizedBox(width: 8),
// // //                 Text(
// // //                   '${avis.note}/5',
// // //                   style: TextStyle(
// // //                     fontSize: 16,
// // //                     fontWeight: FontWeight.bold,
// // //                     color: Colors.grey[700],
// // //                   ),
// // //                 ),
// // //                 Spacer(),
// // //                 Container(
// // //                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                   decoration: BoxDecoration(
// // //                     color: _getCouleurNote(avis.note),
// // //                     borderRadius: BorderRadius.circular(12),
// // //                   ),
// // //                   child: Text(
// // //                     _getTexteNote(avis.note),
// // //                     style: TextStyle(
// // //                       fontSize: 12,
// // //                       color: Colors.white,
// // //                       fontWeight: FontWeight.w600,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //
// // //             SizedBox(height: 12),
// // //
// // //             // 💬 Commentaire
// // //             Container(
// // //               padding: EdgeInsets.all(12),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.grey[50],
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 border: Border.all(color: Colors.grey[200]!),
// // //               ),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Row(
// // //                     children: [
// // //                       Icon(Icons.format_quote, color: Colors.grey[500], size: 16),
// // //                       SizedBox(width: 4),
// // //                       Text(
// // //                         'Mon commentaire',
// // //                         style: TextStyle(
// // //                           fontSize: 12,
// // //                           fontWeight: FontWeight.w600,
// // //                           color: Colors.grey[600],
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   SizedBox(height: 8),
// // //                   Text(
// // //                     avis.commentaire,
// // //                     style: TextStyle(
// // //                       fontSize: 14,
// // //                       color: Colors.grey[800],
// // //                       height: 1.4,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   /// 🎨 Couleur selon la note
// // //   Color _getCouleurNote(int note) {
// // //     if (note <= 2) return Colors.red;
// // //     if (note == 3) return Colors.orange;
// // //     if (note == 4) return Colors.blue;
// // //     return Colors.green;
// // //   }
// // //
// // //   /// 📝 Texte selon la note
// // //   String _getTexteNote(int note) {
// // //     switch (note) {
// // //       case 1:
// // //         return 'Très décevant';
// // //       case 2:
// // //         return 'Décevant';
// // //       case 3:
// // //         return 'Correct';
// // //       case 4:
// // //         return 'Très bien';
// // //       case 5:
// // //         return 'Excellent';
// // //       default:
// // //         return '';
// // //     }
// // //   }
// // //
// // //   /// 🔄 Widget d'état vide
// // //   Widget _buildEmptyState() {
// // //     return Center(
// // //       child: Padding(
// // //         padding: EdgeInsets.all(32),
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             Icon(
// // //               Icons.rate_review_outlined,
// // //               size: 80,
// // //               color: Colors.grey[400],
// // //             ),
// // //             SizedBox(height: 16),
// // //             Text(
// // //               'Aucun avis donné',
// // //               style: GoogleFonts.poppins(
// // //                 fontSize: 20,
// // //                 fontWeight: FontWeight.bold,
// // //                 color: Colors.grey[600],
// // //               ),
// // //             ),
// // //             SizedBox(height: 8),
// // //             Text(
// // //               'Vous n\'avez pas encore donné d\'avis sur vos rendez-vous.',
// // //               textAlign: TextAlign.center,
// // //               style: TextStyle(
// // //                 fontSize: 16,
// // //                 color: Colors.grey[500],
// // //               ),
// // //             ),
// // //             SizedBox(height: 24),
// // //             ElevatedButton.icon(
// // //               onPressed: () => Navigator.pop(context),
// // //               icon: Icon(Icons.arrow_back),
// // //               label: Text('Retour'),
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: Colors.orange,
// // //                 foregroundColor: Colors.white,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   /// ❌ Widget d'état d'erreur
// // //   Widget _buildErrorState() {
// // //     return Center(
// // //       child: Padding(
// // //         padding: EdgeInsets.all(32),
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             Icon(
// // //               Icons.error_outline,
// // //               size: 80,
// // //               color: Colors.red[400],
// // //             ),
// // //             SizedBox(height: 16),
// // //             Text(
// // //               'Erreur de chargement',
// // //               style: GoogleFonts.poppins(
// // //                 fontSize: 20,
// // //                 fontWeight: FontWeight.bold,
// // //                 color: Colors.red[600],
// // //               ),
// // //             ),
// // //             SizedBox(height: 8),
// // //             Text(
// // //               _errorMessage ?? 'Une erreur est survenue',
// // //               textAlign: TextAlign.center,
// // //               style: TextStyle(
// // //                 fontSize: 16,
// // //                 color: Colors.grey[600],
// // //               ),
// // //             ),
// // //             SizedBox(height: 24),
// // //             ElevatedButton.icon(
// // //               onPressed: _chargerMesAvis,
// // //               icon: Icon(Icons.refresh),
// // //               label: Text('Réessayer'),
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: Colors.orange,
// // //                 foregroundColor: Colors.white,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text('Mes avis'),
// // //         backgroundColor: Colors.orange,
// // //         foregroundColor: Colors.white,
// // //         elevation: 0,
// // //         actions: [
// // //           if (_mesAvis.isNotEmpty)
// // //             Padding(
// // //               padding: EdgeInsets.only(right: 16),
// // //               child: Center(
// // //                 child: Container(
// // //                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.white.withOpacity(0.2),
// // //                     borderRadius: BorderRadius.circular(15),
// // //                   ),
// // //                   child: Text(
// // //                     '${_mesAvis.length} avis',
// // //                     style: TextStyle(
// // //                       fontSize: 14,
// // //                       fontWeight: FontWeight.w600,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //         ],
// // //       ),
// // //       body: RefreshIndicator(
// // //         onRefresh: _chargerMesAvis,
// // //         child: _isLoading
// // //             ? Center(
// // //           child: Column(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               CircularProgressIndicator(color: Colors.orange),
// // //               SizedBox(height: 16),
// // //               Text(
// // //                 'Chargement de vos avis...',
// // //                 style: TextStyle(
// // //                   fontSize: 16,
// // //                   color: Colors.grey[600],
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         )
// // //             : _errorMessage != null
// // //             ? _buildErrorState()
// // //             : _mesAvis.isEmpty
// // //             ? _buildEmptyState()
// // //             : Column(
// // //           children: [
// // //             // 📊 En-tête statistiques
// // //             Container(
// // //               margin: EdgeInsets.all(16),
// // //               padding: EdgeInsets.all(16),
// // //               decoration: BoxDecoration(
// // //                 gradient: LinearGradient(
// // //                   colors: [Colors.orange, Colors.deepOrange],
// // //                   begin: Alignment.topLeft,
// // //                   end: Alignment.bottomRight,
// // //                 ),
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               child: Row(
// // //                 children: [
// // //                   Expanded(
// // //                     child: Column(
// // //                       children: [
// // //                         Text(
// // //                           '${_mesAvis.length}',
// // //                           style: TextStyle(
// // //                             fontSize: 24,
// // //                             fontWeight: FontWeight.bold,
// // //                             color: Colors.white,
// // //                           ),
// // //                         ),
// // //                         Text(
// // //                           'Avis donnés',
// // //                           style: TextStyle(
// // //                             fontSize: 12,
// // //                             color: Colors.white70,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   Container(
// // //                     width: 1,
// // //                     height: 40,
// // //                     color: Colors.white30,
// // //                   ),
// // //                   Expanded(
// // //                     child: Column(
// // //                       children: [
// // //                         Text(
// // //                           (_mesAvis.map((a) => a.note).reduce((a, b) => a + b) / _mesAvis.length).toStringAsFixed(1),
// // //                           style: TextStyle(
// // //                             fontSize: 24,
// // //                             fontWeight: FontWeight.bold,
// // //                             color: Colors.white,
// // //                           ),
// // //                         ),
// // //                         Text(
// // //                           'Note moyenne',
// // //                           style: TextStyle(
// // //                             fontSize: 12,
// // //                             color: Colors.white70,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //
// // //             // 📋 Liste des avis
// // //             Expanded(
// // //               child: ListView.builder(
// // //                 padding: EdgeInsets.only(bottom: 16),
// // //                 itemCount: _mesAvis.length,
// // //                 itemBuilder: (context, index) {
// // //                   final avis = _mesAvis[index];
// // //                   return _buildAvisCard(avis);
// // //                 },
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // /// 📝 Dialog pour modifier un avis
// // // class _ModifierAvisDialog extends StatefulWidget {
// // //   final Avis avis;
// // //   final VoidCallback onAvisModifie;
// // //
// // //   const _ModifierAvisDialog({
// // //     required this.avis,
// // //     required this.onAvisModifie,
// // //   });
// // //
// // //   @override
// // //   _ModifierAvisDialogState createState() => _ModifierAvisDialogState();
// // // }
// // //
// // // class _ModifierAvisDialogState extends State<_ModifierAvisDialog> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   late final TextEditingController _commentaireController;
// // //   late int _note;
// // //   bool _isSubmitting = false;
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _commentaireController = TextEditingController(text: widget.avis.commentaire);
// // //     _note = widget.avis.note;
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _commentaireController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   /// ⭐ Construire le sélecteur d'étoiles
// // //   Widget _buildStarRating() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'Nouvelle note',
// // //           style: TextStyle(
// // //             fontSize: 16,
// // //             fontWeight: FontWeight.bold,
// // //           ),
// // //         ),
// // //         SizedBox(height: 12),
// // //         Row(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: List.generate(5, (index) {
// // //             final starNumber = index + 1;
// // //             return GestureDetector(
// // //               onTap: () {
// // //                 setState(() {
// // //                   _note = starNumber;
// // //                 });
// // //               },
// // //               child: Container(
// // //                 padding: EdgeInsets.symmetric(horizontal: 4),
// // //                 child: Icon(
// // //                   starNumber <= _note ? Icons.star : Icons.star_border,
// // //                   size: 35,
// // //                   color: starNumber <= _note ? Colors.amber : Colors.grey[400],
// // //                 ),
// // //               ),
// // //             );
// // //           }),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Future<void> _soumettreModification() async {
// // //     if (!_formKey.currentState!.validate()) {
// // //       return;
// // //     }
// // //
// // //     setState(() {
// // //       _isSubmitting = true;
// // //     });
// // //
// // //     try {
// // //       final result = await AvisService.modifierAvis(
// // //         context: context,
// // //         avisId: widget.avis.id!,
// // //         note: _note,
// // //         commentaire: _commentaireController.text.trim(),
// // //       );
// // //
// // //       if (mounted) {
// // //         if (result.success) {
// // //           // Navigator.pop(context);
// // //           widget.onAvisModifie();
// // //
// // //           showDialog(
// // //             context: context,
// // //             barrierDismissible: false,
// // //             builder: (context) => Dialog(
// // //               backgroundColor: Colors.transparent,
// // //               elevation: 0,
// // //               child: Container(
// // //                 width: 100,
// // //                 height: 100,
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white,
// // //                   borderRadius: BorderRadius.circular(16),
// // //                 ),
// // //                 child: Column(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     Icon(Icons.check_circle, color: Colors.green, size: 60),
// // //                     const SizedBox(height: 10),
// // //                     const Text("Avis modifié !", style: TextStyle(fontWeight: FontWeight.bold)),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           );
// // //
// // //           Future.delayed(const Duration(milliseconds: 1100), () {
// // //             Navigator.of(context).pop();
// // //             Navigator.pop(context);
// // //           });
// // //
// // //           //Navigator.pop(context);
// // //           //widget.onAvisModifie();
// // //         } else {
// // //           // ❌ Erreur
// // //           ScaffoldMessenger.of(context).showSnackBar(
// // //             SnackBar(
// // //               content: Row(
// // //                 children: [
// // //                   Icon(Icons.error, color: Colors.white),
// // //                   SizedBox(width: 8),
// // //                   Expanded(child: Text(result.message)),
// // //                 ],
// // //               ),
// // //               backgroundColor: Colors.red,
// // //               duration: Duration(seconds: 4),
// // //             ),
// // //           );
// // //         }
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text('Erreur inattendue: $e'),
// // //             backgroundColor: Colors.red,
// // //             duration: Duration(seconds: 4),
// // //           ),
// // //         );
// // //       }
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           _isSubmitting = false;
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Dialog(
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //       child: Container(
// // //         constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
// // //         padding: EdgeInsets.all(20),
// // //         child: Form(
// // //           key: _formKey,
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               // Titre
// // //               Row(
// // //                 children: [
// // //                   Icon(Icons.edit, color: Colors.orange),
// // //                   SizedBox(width: 8),
// // //                   Expanded(
// // //                     child: Text(
// // //                       'Modifier mon avis',
// // //                       style: GoogleFonts.poppins(
// // //                         fontSize: 18,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   IconButton(
// // //                     onPressed: () => Navigator.pop(context),
// // //                     icon: Icon(Icons.close),
// // //                   ),
// // //                 ],
// // //               ),
// // //
// // //               SizedBox(height: 16),
// // //
// // //               // Info salon
// // //               Container(
// // //                 padding: EdgeInsets.all(12),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.grey[100],
// // //                   borderRadius: BorderRadius.circular(8),
// // //                 ),
// // //                 child: Row(
// // //                   children: [
// // //                     Icon(Icons.store, color: Colors.grey[600]),
// // //                     SizedBox(width: 8),
// // //                     Expanded(
// // //                       child: Text(
// // //                         widget.avis.salonNom ?? 'Salon inconnu',
// // //                         style: TextStyle(
// // //                           fontWeight: FontWeight.w600,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //
// // //               SizedBox(height: 20),
// // //
// // //               // Sélecteur d'étoiles
// // //               _buildStarRating(),
// // //
// // //               SizedBox(height: 20),
// // //
// // //               // Champ commentaire
// // //               Text(
// // //                 'Nouveau commentaire',
// // //                 style: TextStyle(
// // //                   fontSize: 16,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //               SizedBox(height: 8),
// // //               Expanded(
// // //                 child: TextFormField(
// // //                   controller: _commentaireController,
// // //                   maxLines: null,
// // //                   expands: true,
// // //                   maxLength: 500,
// // //                   decoration: InputDecoration(
// // //                     hintText: 'Modifiez votre commentaire... (minimum 10 caractères)',
// // //                     border: OutlineInputBorder(
// // //                       borderRadius: BorderRadius.circular(8),
// // //                     ),
// // //                     focusedBorder: OutlineInputBorder(
// // //                       borderRadius: BorderRadius.circular(8),
// // //                       borderSide: BorderSide(color: Colors.orange, width: 2),
// // //                     ),
// // //                     contentPadding: EdgeInsets.all(12),
// // //                   ),
// // //                   validator: (value) {
// // //                     if (value == null || value.trim().isEmpty) {
// // //                       return 'Veuillez écrire un commentaire';
// // //                     }
// // //                     if (value.trim().length < 10) {
// // //                       return 'Le commentaire doit contenir au moins 10 caractères';
// // //                     }
// // //                     return null;
// // //                   },
// // //                 ),
// // //               ),
// // //
// // //               SizedBox(height: 20),
// // //
// // //               // Boutons d'action
// // //               Row(
// // //                 children: [
// // //                   Expanded(
// // //                     child: OutlinedButton(
// // //                       onPressed: _isSubmitting ? null : () => Navigator.pop(context),
// // //                       child: Text('Annuler'),
// // //                     ),
// // //                   ),
// // //                   SizedBox(width: 12),
// // //                   Expanded(
// // //                     flex: 2,
// // //                     child: ElevatedButton(
// // //                       onPressed: _isSubmitting ? null : _soumettreModification,
// // //                       style: ElevatedButton.styleFrom(
// // //                         backgroundColor: Colors.orange,
// // //                         foregroundColor: Colors.white,
// // //                       ),
// // //                       child: _isSubmitting
// // //                           ? Row(
// // //                         mainAxisAlignment: MainAxisAlignment.center,
// // //                         children: [
// // //                           SizedBox(
// // //                             width: 16,
// // //                             height: 16,
// // //                             child: CircularProgressIndicator(
// // //                               color: Colors.white,
// // //                               strokeWidth: 2,
// // //                             ),
// // //                           ),
// // //                           SizedBox(width: 8),
// // //                           Text('Modification...'),
// // //                         ],
// // //                       )
// // //                           : Text('Modifier'),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
