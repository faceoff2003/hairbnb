// Fichier: lib/services/commandes_services.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/commandes_clients.dart';
import '../../emails/emails_notifications_services/email_notification_service.dart';

class CommandeService {
  final String baseUrl;
  final String token;
  late EmailNotificationService _emailService;

  CommandeService({required this.baseUrl, required this.token}) {
    _emailService = EmailNotificationService(baseUrl: baseUrl, token: token);
  }

  // En-têtes HTTP courants
  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Bearer $token',
  };

  // Récupérer les commandes d'une coiffeuse
  Future<List<CommandeClient>> getCommandesCoiffeuse(int idUser, String statut) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coiffeuse-commandes/$idUser/?statut=$statut'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => CommandeClient.fromJson(item)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des commandes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Mettre à jour le statut d'une commande et envoyer une notification
  Future<CommandeClient> updateStatutCommande(int idRendezVous, String nouveauStatut, {CommandeClient? commande}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/update-statut-commande/$idRendezVous/'),
        headers: _headers,
        body: json.encode({'statut': nouveauStatut}),
      );

      if (response.statusCode == 200) {
        CommandeClient updatedCommande = CommandeClient.fromJson(json.decode(response.body));

        if (commande != null) {
          try {
            // Vérifier si l'email est disponible
            final String emailToUse = commande.emailClient.isNotEmpty == true
                ? commande.emailClient
                : await _obtenirEmailDuClient(commande.idRendezVous);

            if (emailToUse.isNotEmpty) {
              // Préparer les données des services pour le template
              List<Map<String, dynamic>> servicesData = commande.services.map((s) => {
                'nom': s.intituleService,
                'prix': s.prixApplique,
                'duree': s.dureeEstimee,
              }).toList();

              await _emailService.sendStatusUpdateNotification(
                email: emailToUse,
                prenomClient: commande.prenomClient,
                nomClient: commande.nomClient,
                rendezVousId: commande.idRendezVous,
                dateHeure: commande.dateHeure,
                nouveauStatut: nouveauStatut,
                nomSalon: commande.nomSalon,
                services: servicesData,
                totalPrix: commande.totalPrix,
                dureeTotale: commande.dureeTotale,
              );
            } else {
              print('Pas d\'email disponible pour le client');
            }
          } catch (e) {
            print('Erreur lors de l\'envoi de l\'email de notification: $e');
          }
        }

        // Envoi de la notification par email si la commande est fournie
        // if (commande != null) {
        //   try {
        //     // Préparer les données des services pour le template
        //     List<Map<String, dynamic>> servicesData = commande.services.map((s) => {
        //       'nom': s.intituleService,
        //       'prix': s.prixApplique,
        //       'duree': s.dureeEstimee,
        //     }).toList();
        //
        //     await _emailService.sendStatusUpdateNotification(
        //       email: commande.emailClient,
        //       prenomClient: commande.prenomClient,
        //       nomClient: commande.nomClient,
        //       rendezVousId: commande.idRendezVous,
        //       dateHeure: commande.dateHeure,
        //       nouveauStatut: nouveauStatut,
        //       nomSalon: commande.nomSalon,
        //       services: servicesData,
        //       totalPrix: commande.totalPrix,
        //       dureeTotale: commande.dureeTotale,
        //     );
        //   } catch (e) {
        //     print('Erreur lors de l\'envoi de l\'email de notification: $e');
        //     // Ne pas bloquer le processus si l'email échoue
        //   }
        // }

        return updatedCommande;
      } else {
        throw Exception('Erreur lors de la mise à jour du statut: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
  Future<String> _obtenirEmailDuClient(int rendezVousId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/client-email/$rendezVousId/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['email'] ?? '';
      }
      return '';
    } catch (e) {
      print('Erreur lors de la récupération de l\'email: $e');
      return '';
    }
  }

  // Mettre à jour la date et l'heure d'une commande et envoyer une notification
  Future<CommandeClient> updateDateHeureCommande(int idRendezVous, DateTime nouveauDateTime, {CommandeClient? commande}) async {
    try {
      final formattedDate = nouveauDateTime.toIso8601String();
      final response = await http.patch(
        Uri.parse('$baseUrl/update-date-heure-commande/$idRendezVous/'),
        headers: _headers,
        body: json.encode({'date_heure': formattedDate}),
      );

      if (response.statusCode == 200) {
        CommandeClient updatedCommande = CommandeClient.fromJson(json.decode(response.body));

        // Envoi de la notification par email si la commande est fournie
        if (commande != null) {
          try {
            await _emailService.sendDateUpdateNotification(
              email: commande.emailClient, // À remplacer par l'email réel du client
              prenomClient: commande.prenomClient,
              nomClient: commande.nomClient,
              rendezVousId: commande.idRendezVous,
              ancienneDateHeure: commande.dateHeure,
              nouvelleDateHeure: formattedDate,
              nomSalon: commande.nomSalon,
            );
          } catch (e) {
            print('Erreur lors de l\'envoi de l\'email de notification: $e');
            // Ne pas bloquer le processus si l'email échoue
          }
        }

        return updatedCommande;
      } else {
        throw Exception('Erreur lors de la mise à jour de la date/heure: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Ajouter ces méthodes dans votre classe CommandeService

// Récupérer les informations de paiement d'un rendez-vous
  Future<Map<String, dynamic>?> getPaiementInfo(int idRendezVous) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/paiement-info/$idRendezVous/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null; // Aucun paiement trouvé
      } else {
        throw Exception('Erreur lors de la récupération des informations de paiement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

// Effectuer un remboursement
  Future<Map<String, dynamic>> remboursementPaiement(int idPaiement, {double? montant}) async {
    try {
      final Map<String, dynamic> data = {
        'id_paiement': idPaiement,
      };

      // Ajouter le montant seulement s'il est fourni (sinon remboursement total)
      if (montant != null) {
        data['montant'] = montant;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/remboursement/'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors du remboursement: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }


}







// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../models/commandes_clients.dart';
//
// class CommandeService {
//   final String baseUrl;
//   final String token;
//
//   CommandeService({required this.baseUrl, required this.token});
//
//   // En-têtes HTTP courants
//   Map<String, String> get _headers => {
//     'Content-Type': 'application/json',
//     'Authorization': 'Bearer $token',
//   };
//
//   // Récupérer les commandes d'une coiffeuse
//   Future<List<CommandeClient>> getCommandesCoiffeuse(int idUser, String statut) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/coiffeuse-commandes/$idUser/?statut=$statut'),
//         headers: _headers,
//       );
//
//       if (response.statusCode == 200) {
//         List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
//         return data.map((item) => CommandeClient.fromJson(item)).toList();
//       } else {
//         throw Exception('Erreur lors de la récupération des commandes: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
//
//   // Mettre à jour le statut d'une commande
//   Future<CommandeClient> updateStatutCommande(int idRendezVous, String nouveauStatut) async {
//     try {
//       final response = await http.patch(
//         Uri.parse('$baseUrl/update-statut-commande/$idRendezVous/'),
//         headers: _headers,
//         body: json.encode({'statut': nouveauStatut}),
//       );
//
//       if (response.statusCode == 200) {
//         return CommandeClient.fromJson(json.decode(response.body));
//       } else {
//         throw Exception('Erreur lors de la mise à jour du statut: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
//
//   // Mettre à jour la date et l'heure d'une commande
//   Future<CommandeClient> updateDateHeureCommande(int idRendezVous, DateTime nouveauDateTime) async {
//     try {
//       final formattedDate = nouveauDateTime.toIso8601String();
//       final response = await http.patch(
//         Uri.parse('$baseUrl/update-date-heure-commande/$idRendezVous/'),
//         headers: _headers,
//         body: json.encode({'date_heure': formattedDate}),
//       );
//
//       if (response.statusCode == 200) {
//         return CommandeClient.fromJson(json.decode(response.body));
//       } else {
//         throw Exception('Erreur lors de la mise à jour de la date/heure: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
// }