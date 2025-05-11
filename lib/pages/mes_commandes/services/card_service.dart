import 'package:flutter/material.dart';
import 'package:hairbnb/pages/mes_commandes/services/status_utils_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/mes_commandes.dart';
import '../modals/commande_detail_modal.dart';
import '../sub_pages/recu_page.dart';
import '../widgets/countdown_widget.dart';

class CommandeCard extends StatefulWidget {
  final Commande commande;

  const CommandeCard({super.key, required this.commande});

  @override
  State<CommandeCard> createState() => _CommandeCardState();
}

class _CommandeCardState extends State<CommandeCard> {
  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
  final DateFormat timeFormatter = DateFormat('HH:mm');
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();

    // Démarrer le timer seulement si la date est dans le futur et si le statut n'est pas annulé ou terminé
    if (_timeLeft.inSeconds > 0 &&
        !["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())) {
      _startTimer();
    } else if (_timeLeft.inSeconds <= 0) {
      _isExpired = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.commande.dateHeure.isAfter(now)) {
      _timeLeft = widget.commande.dateHeure.difference(now);
    } else {
      _timeLeft = Duration.zero;
      _isExpired = true;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          _isExpired = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            _showCommandeDetails(context);
          },
          child: Column(
            children: [
              // Barre d'état supérieure
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: StatusUtils.getStatusColor(widget.commande.statut),
                ),
              ),

              // En-tête de la commande
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar du salon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.commande.nomSalon.isNotEmpty ? widget.commande.nomSalon[0].toUpperCase() : 'S',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Informations principales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.commande.nomSalon,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Colors.grey.shade600
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormatter.format(widget.commande.dateHeure),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeFormatter.format(widget.commande.dateHeure),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Indicateur de statut
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: StatusUtils.getStatusColor(widget.commande.statut).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.commande.statut,
                        style: TextStyle(
                          color: StatusUtils.getStatusColor(widget.commande.statut),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Compte à rebours dynamique
              CountdownWidget(
                dateHeure: widget.commande.dateHeure,
                statut: widget.commande.statut,
                timeLeft: _timeLeft,
                isExpired: _isExpired,
              ),

              const Divider(height: 1),

              // Services (simplifié)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.commande.services.length} service${widget.commande.services.length > 1 ? "s" : ""}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.commande.services.isNotEmpty)
                            Text(
                              widget.commande.services.map((s) => s.intituleService).join(', '),
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.commande.montantPaye.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bouton de détails
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          _showCommandeDetails(context);
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Détails'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple.shade700,
                        ),
                      ),
                    ),

                    // Bouton de reçu si disponible
                    if (widget.commande.receiptUrl != null && widget.commande.receiptUrl!.isNotEmpty)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ReceiptPage(receiptUrl: widget.commande.receiptUrl!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_rounded),
                          label: const Text('Reçu'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.purple.shade700,
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

  void _showCommandeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommandeDetailModal(commande: widget.commande, timeLeft: _timeLeft, isExpired: _isExpired),
    );
  }
}