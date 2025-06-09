import 'package:flutter/material.dart';
import 'package:hairbnb/models/salon_details_geo.dart';

final Color primaryColor = Color(0xFF8E44AD);

Widget buildTeamPreview(List<CoiffeuseDetailsForGeo> coiffeuses) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "L'équipe :",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: coiffeuses.take(3).map<Widget>((coiffeuse) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: coiffeuse.estProprietaire
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: coiffeuse.estProprietaire
                        ? primaryColor.withOpacity(0.2)
                        : Colors.transparent,
                    // MODIFIÉ: Pour le moment, on utilise juste une icône (photo_profil pas dans le nouveau modèle)
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: coiffeuse.estProprietaire ? primaryColor : Colors.grey[500],
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    coiffeuse.prenom,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: coiffeuse.estProprietaire ? primaryColor : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (coiffeuses.length > 3)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "+${coiffeuses.length - 3} autres",
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ),
      ],
    ),
  );
}