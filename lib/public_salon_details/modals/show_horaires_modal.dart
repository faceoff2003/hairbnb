import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showHorairesModal(BuildContext context, String horaires) {
  final jours = {
    'Mon': 'Lundi',
    'Tue': 'Mardi',
    'Wed': 'Mercredi',
    'Thu': 'Jeudi',
    'Fri': 'Vendredi',
    'Sat': 'Samedi',
    'Sun': 'Dimanche',
  };

  final horairesList = horaires.split(',').map((e) => e.trim()).toList();

  // REMPLACE showModalBottomSheet PAR showDialog
  showDialog(
    context: context,
    builder: (context) {
      return Dialog( // ENVELOPPE LE CONTENU DANS UN WIDGET Dialog
        backgroundColor: Colors.transparent, // Rend le fond du Dialog transparent
        // Ajuste le padding pour pousser le modal vers le haut si nécessaire.
        // Par exemple, 50px en haut et 100px en bas pour le remonter un peu.
        insetPadding: EdgeInsets.fromLTRB(20, 50, 20, 100), // Ajusté pour le positionnement
        child: Container( // Le Container qui contient le contenu du modal
          // Tu peux retirer le `shape` et `backgroundColor` du `showModalBottomSheet` précédent
          // car maintenant le Container gère sa propre décoration.
          decoration: BoxDecoration(
            color: Colors.white, // Couleur de fond du modal
            borderRadius: BorderRadius.circular(20), // Bords arrondis pour le modal centré
          ),
          padding: const EdgeInsets.all(20), // Padding interne pour le contenu

          // Le contenu de ton modal d'horaires
          child: Column(
            mainAxisSize: MainAxisSize.min, // La colonne prendra la taille minimale de ses enfants
            children: [
              Text(
                'Horaires d\'ouverture',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...horairesList.map((part) {
                final split = part.split('/');
                if (split.length == 2) {
                  final horaire = split[0];
                  final jourCode = split[1];
                  final jour = jours[jourCode] ?? jourCode;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
                        const SizedBox(width: 10),
                        Text(
                          '$jour : $horaire',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 20), // Ajoute un peu d'espace avant le bouton
              Align( // Ajoute un bouton de fermeture
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, // Exemple de couleur
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}