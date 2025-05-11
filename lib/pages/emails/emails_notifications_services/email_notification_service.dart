// Fichier: lib/services/email_notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/email_notification.dart';

class EmailNotificationService {
  final String baseUrl;
  final String token;

  EmailNotificationService({required this.baseUrl, required this.token});

  // En-têtes HTTP courants
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Envoie une notification par email
  Future<bool> sendEmailNotification(EmailNotification notification) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/email-notifications/'),
        headers: _headers,
        body: json.encode(notification.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Email envoyé avec succès');
        return true;
      } else {
        print('Erreur lors de l\'envoi de l\'email: ${response.statusCode}');
        print('Message: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de l\'envoi de l\'email: $e');
      return false;
    }
  }

  /// Envoie une notification après modification du statut d'un rendez-vous
  Future<bool> sendStatusUpdateNotification({
    required String email,
    required String prenomClient,
    required String nomClient,
    required int rendezVousId,
    required String dateHeure,
    required String nouveauStatut,
    required String nomSalon,
    List<Map<String, dynamic>>? services,
    double? totalPrix,
    int? dureeTotale,
  }) async {
    // Déterminer le type d'email en fonction du statut
    String templateId;
    String subject;

    switch (nouveauStatut) {
      case 'confirmé':
        templateId = 'confirmation_rdv';
        subject = 'Confirmation de votre rendez-vous chez $nomSalon';
        break;
      case 'annulé':
        templateId = 'annulation_rdv';
        subject = 'Annulation de votre rendez-vous chez $nomSalon';
        break;
      case 'terminé':
        return true; // Pas de notification pour le statut "terminé"
      default:
        templateId = 'modification_rdv';
        subject = 'Modification de votre rendez-vous chez $nomSalon';
    }

    final notification = EmailNotification(
      toEmail: email,
      toName: '$prenomClient $nomClient',
      subject: subject,
      templateId: templateId,
      rendezVousId: rendezVousId,
      templateData: {
        'prenom': prenomClient,
        'nom': nomClient,
        'date_heure': dateHeure,
        'salon_nom': nomSalon,
        'statut': nouveauStatut,
        if (services != null) 'services': services,
        if (totalPrix != null) 'total_prix': totalPrix,
        if (dureeTotale != null) 'duree_totale': dureeTotale,
      },
    );

    return await sendEmailNotification(notification);
  }

  /// Envoie une notification après modification de la date d'un rendez-vous
  Future<bool> sendDateUpdateNotification({
    required String email,
    required String prenomClient,
    required String nomClient,
    required int rendezVousId,
    required String ancienneDateHeure,
    required String nouvelleDateHeure,
    required String nomSalon,
  }) async {
    final notification = EmailNotification(
      toEmail: email,
      toName: '$prenomClient $nomClient',
      subject: 'Modification de la date de votre rendez-vous chez $nomSalon',
      templateId: 'modification_rdv',
      rendezVousId: rendezVousId,
      templateData: {
        'prenom': prenomClient,
        'nom': nomClient,
        'date_heure': nouvelleDateHeure,
        'ancienne_date_heure': ancienneDateHeure,
        'salon_nom': nomSalon,
      },
    );

    return await sendEmailNotification(notification);
  }
}