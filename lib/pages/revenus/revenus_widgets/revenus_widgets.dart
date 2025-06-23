// lib/widgets/revenus_widgets.dart

import 'package:flutter/material.dart';
import 'package:hairbnb/models/revenus_model.dart';

/// Widget pour afficher le résumé des revenus
class RevenusResumeCard extends StatelessWidget {
  final ResumeRevenusModel resume;

  const RevenusResumeCard({
    super.key,
    required this.resume,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé des revenus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // Grille des résumés
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildResumeItem(
                  'Total TTC',
                  '${resume.totalTtc.toStringAsFixed(2).replaceAll('.', ',')} €',
                  Icons.euro_symbol,
                  Colors.green,
                ),
                _buildResumeItem(
                  'Total HT',
                  '${resume.totalHt.toStringAsFixed(2).replaceAll('.', ',')} €',
                  Icons.receipt,
                  Colors.blue,
                ),
                _buildResumeItem(
                  'TVA (${resume.tauxTva.toStringAsFixed(0)}%)',
                  '${resume.tva.toStringAsFixed(2).replaceAll('.', ',')} €',
                  Icons.percent,
                  Colors.orange,
                ),
                _buildResumeItem(
                  'RDV payés',
                  '${resume.nbRdvPayes}',
                  Icons.event_available,
                  Colors.purple,
                ),
                _buildResumeItem(
                  'Clients uniques',
                  '${resume.nbClientsUniques}',
                  Icons.people,
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher les statistiques
class RevenusStatistiquesCard extends StatelessWidget {
  final StatistiquesRevenusModel statistiques;

  const RevenusStatistiquesCard({
    super.key,
    required this.statistiques,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // Service le plus vendu
            _buildStatItem(
              'Service le plus vendu',
              statistiques.servicePlusVendu ?? 'Aucun',
              Icons.star,
              Colors.amber,
            ),
            const SizedBox(height: 12),

            // Jour le plus rentable
            _buildStatItem(
              'Jour le plus rentable',
              _formatJourRentable(statistiques.jourLePlusRentable),
              Icons.calendar_today,
              Colors.green,
            ),
            const SizedBox(height: 12),

            // Nombre de services différents
            _buildStatItem(
              'Services différents vendus',
              '${statistiques.nbServicesDifferents}',
              Icons.widgets,
              Colors.purple,
            ),

            // Revenus par jour (si données disponibles)
            if (statistiques.revenusParJour.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Revenus par jour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRevenusParJour(statistiques.revenusParJour),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenusParJour(Map<String, double> revenus) {
    final sortedEntries = revenus.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: sortedEntries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(entry.key),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${entry.value.toStringAsFixed(2).replaceAll('.', ',')} €',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatJourRentable(String? jour) {
    if (jour == null) return 'Aucun';
    try {
      DateTime.parse(jour); // Validation du format de date
      return _formatDate(jour);
    } catch (e) {
      return jour;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

/// Widget pour afficher la liste des rendez-vous
class RevenusRdvList extends StatelessWidget {
  final List<DetailRdvModel> rdvList;

  const RevenusRdvList({
    super.key,
    required this.rdvList,
  });

  @override
  Widget build(BuildContext context) {
    if (rdvList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Aucun rendez-vous payé pour cette période',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Rendez-vous payés',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rdvList.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final rdv = rdvList[index];
              return RevenusRdvItem(rdv: rdv);
            },
          ),
        ],
      ),
    );
  }
}

/// Widget pour un rendez-vous individuel
class RevenusRdvItem extends StatelessWidget {
  final DetailRdvModel rdv;

  const RevenusRdvItem({
    super.key,
    required this.rdv,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(
          '${rdv.rdvId}',
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        rdv.client?.nom != null && rdv.client?.prenom != null
            ? '${rdv.client!.prenom} ${rdv.client!.nom}'
            : 'Client inconnu',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDateTime(rdv.date)),
          Text(
            '${rdv.totalTtc.toStringAsFixed(2).replaceAll('.', ',')} € TTC',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du client
              if (rdv.client != null) ...[
                const Text(
                  'Client',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Email: ${rdv.client!.email ?? 'Non renseigné'}'),
                const SizedBox(height: 12),
              ],

              // Services
              const Text(
                'Services',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...rdv.services.map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.nom,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (service.description.isNotEmpty)
                            Text(
                              service.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (service.dureeMinutes != null)
                            Text(
                              '${service.dureeMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${service.prixTtc.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),

              const Divider(),

              // Totaux
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total HT:'),
                  Text('${rdv.totalHt.toStringAsFixed(2).replaceAll('.', ',')} €'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total TTC:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${rdv.totalTtc.toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Statut et salon
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Statut: ${rdv.statutRdv}'),
                  if (rdv.salon != null)
                    Text('Salon: ${rdv.salon!}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} à '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}