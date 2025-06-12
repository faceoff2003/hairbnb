// screens/creer_avis_screen.dart

import 'package:flutter/material.dart';
import 'package:hairbnb/pages/avis/services/avis_service.dart';

import '../../models/avis.dart';

class CreerAvisScreen extends StatefulWidget {
  final RdvEligible rdv;

  const CreerAvisScreen({
    Key? key,
    required this.rdv,
  }) : super(key: key);

  @override
  _CreerAvisScreenState createState() => _CreerAvisScreenState();
}

class _CreerAvisScreenState extends State<CreerAvisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentaireController = TextEditingController();

  int _note = 5; // Note par défaut à 5 étoiles
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  /// ⭐ Construire le sélecteur d'étoiles
  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre note',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
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
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  starNumber <= _note ? Icons.star : Icons.star_border,
                  size: 40,
                  color: starNumber <= _note ? Colors.amber : Colors.grey[400],
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            _getTextePourNote(_note),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _getCouleurPourNote(_note),
            ),
          ),
        ),
      ],
    );
  }

  /// 📝 Texte correspondant à la note
  String _getTextePourNote(int note) {
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
        return 'Excellent !';
      default:
        return '';
    }
  }

  /// 🎨 Couleur correspondant à la note
  Color _getCouleurPourNote(int note) {
    if (note <= 2) return Colors.red;
    if (note == 3) return Colors.orange;
    return Colors.green;
  }

  /// 📱 Construire les informations du RDV
  Widget _buildRdvInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du rendez-vous',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // Salon
            _buildInfoRow(Icons.store, 'Salon', widget.rdv.salonNom),
            SizedBox(height: 8),

            // Date
            _buildInfoRow(Icons.calendar_today, 'Date', widget.rdv.dateFormatee),
            SizedBox(height: 8),

            // Services
            _buildInfoRow(Icons.content_cut, 'Services', widget.rdv.servicesTexte),
            SizedBox(height: 8),

            // Prix
            _buildInfoRow(Icons.euro, 'Prix total', widget.rdv.prixFormate),
          ],
        ),
      ),
    );
  }

  /// 🏷️ Widget pour une ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  /// 📝 Construire le champ commentaire
  Widget _buildCommentaireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre commentaire',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _commentaireController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Partagez votre expérience... (minimum 10 caractères)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
            contentPadding: EdgeInsets.all(12),
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
        SizedBox(height: 8),
        Text(
          '💡 Conseil: Décrivez votre expérience, la qualité du service, l\'accueil, etc.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// 📤 Soumettre l'avis
  Future<void> _soumettreAvis() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await AvisService.creerAvis(
        context: context,
        rdvId: widget.rdv.idRendezVous,
        note: _note,
        commentaire: _commentaireController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          // ✅ Succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Retourner à l'écran précédent avec signal de succès
          Navigator.pop(context, true);
        } else {
          // ❌ Erreur
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

  /// 🚫 Annuler et retourner
  void _annuler() {
    // Vérifier si des modifications ont été faites
    if (_commentaireController.text.trim().isNotEmpty || _note != 5) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Annuler la création'),
          content: Text('Êtes-vous sûr de vouloir annuler ? Vos modifications seront perdues.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Continuer la rédaction'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialog
                Navigator.pop(context); // Retourner à l'écran précédent
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Annuler'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donner mon avis'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _annuler,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du RDV
              _buildRdvInfo(),

              SizedBox(height: 24),

              // Sélecteur d'étoiles
              _buildStarRating(),

              SizedBox(height: 24),

              // Champ commentaire
              _buildCommentaireField(),

              SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  // Bouton annuler
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _annuler,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Bouton soumettre
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _soumettreAvis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Envoi...'),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('Publier mon avis'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Note informative
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Votre avis sera visible publiquement et aidera les autres utilisateurs.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}