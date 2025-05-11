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

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
        ],
      ),
    ),
  );
}
