import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/commandes_clients.dart';
import '../../models/current_user.dart';
import 'commandes_services/commandes_services.dart';

class CoiffeuseCommandesPage extends StatefulWidget {
  final CurrentUser currentUser;

  const CoiffeuseCommandesPage({super.key, required this.currentUser});

  @override
  _CoiffeuseCommandesPageState createState() => _CoiffeuseCommandesPageState();
}

class _CoiffeuseCommandesPageState extends State<CoiffeuseCommandesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CommandeService? _commandeService;
  List<CommandeClient> _commandes = [];
  List<CommandeClient> _toutesCommandes = []; // Pour stocker toutes les commandes
  bool _isLoading = true;
  String _errorMessage = '';

  // Filtres pour les commandes
  String _currentFilter = 'tous'; // Valeur par défaut : tous

  // Format pour l'affichage des dates
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

  @override
  void initState() {
    super.initState();
    // 5 onglets maintenant: Tous, En attente, Confirmés, Annulés, Terminés
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Récupérer le token de Firebase
    _getTokenAndInitialize();
  }

  // Méthode pour récupérer le token et initialiser le service
  Future<void> _getTokenAndInitialize() async {
    try {
      // Récupérer le token
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Récupération du token avec traitement de nullabilité
        final idTokenResult = await user.getIdToken();
        // Vérifier si le token est null ou vide
        if (idTokenResult == null || idTokenResult.isEmpty) {
          setState(() {
            _errorMessage = "Token d'authentification invalide";
            _isLoading = false;
          });
          return;
        }

        // À ce stade, idTokenResult est non-null et non-vide
        final String token = idTokenResult; // Conversion explicite en String non-nullable

        // Initialiser le service de commandes
        _commandeService = CommandeService(
          baseUrl: 'https://www.hairbnb.site/api',
          token: token,
        );

        // Charger toutes les commandes
        await _fetchToutesCommandes();
      } else {
        setState(() {
          _errorMessage = "Erreur d'authentification: aucun utilisateur connecté";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la récupération du token: $e";
        _isLoading = false;
      });
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = 'tous';
            break;
          case 1:
            _currentFilter = 'en attente';
            break;
          case 2:
            _currentFilter = 'confirmé';
            break;
          case 3:
            _currentFilter = 'annulé';
            break;
          case 4:
            _currentFilter = 'terminé';
            break;
        }
      });

      if (_currentFilter == 'tous') {
        // Pour 'tous', pas besoin de refaire un appel API, on utilise les commandes déjà chargées
        _applyFilter('tous');
      } else {
        // Pour les autres filtres, on récupère les commandes spécifiques
        _fetchCommandes();
      }
    }
  }

  // Nouvelle méthode pour récupérer toutes les commandes
  Future<void> _fetchToutesCommandes() async {
    if (_commandeService == null) {
      setState(() {
        _errorMessage = "Service non initialisé";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      int idUser = widget.currentUser.idTblUser;

      // Récupérer toutes les catégories de commandes en parallèle
      final futureEnAttente = _commandeService!.getCommandesCoiffeuse(idUser, 'en attente');
      final futureConfirme = _commandeService!.getCommandesCoiffeuse(idUser, 'confirmé');
      final futureAnnule = _commandeService!.getCommandesCoiffeuse(idUser, 'annulé');
      final futureTermine = _commandeService!.getCommandesCoiffeuse(idUser, 'terminé');

      final results = await Future.wait([
        futureEnAttente,
        futureConfirme,
        futureAnnule,
        futureTermine
      ]);

      // Fusionner toutes les commandes
      _toutesCommandes = [
        ...results[0], // en attente
        ...results[1], // confirmé
        ...results[2], // annulé
        ...results[3], // terminé
      ];

      // Trier par date (plus récent en premier)
      _toutesCommandes.sort((a, b) {
        return DateTime.parse(b.dateHeure).compareTo(DateTime.parse(a.dateHeure));
      });

      // Appliquer le filtre initial
      _applyFilter(_currentFilter);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Méthode pour appliquer un filtre aux commandes déjà chargées
  void _applyFilter(String filter) {
    setState(() {
      if (filter == 'tous') {
        _commandes = List.from(_toutesCommandes);
      } else {
        _commandes = _toutesCommandes.where((c) => c.statut == filter).toList();
      }
    });
  }

  // Méthode pour récupérer les commandes selon un filtre spécifique
  Future<void> _fetchCommandes() async {
    if (_commandeService == null) {
      setState(() {
        _errorMessage = "Service non initialisé";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      int idUser = widget.currentUser.idTblUser;
      final commandes = await _commandeService!.getCommandesCoiffeuse(idUser, _currentFilter);

      setState(() {
        _commandes = commandes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Méthode pour actualiser toutes les données
  Future<void> _refreshData() async {
    await _fetchToutesCommandes();
  }

  Future<void> _updateStatut(int idRendezVous, String nouveauStatut) async {
    if (_commandeService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Service non initialisé")),
      );
      return;
    }

    try {
      // Récupérer la commande avant la mise à jour
      CommandeClient? commande;
      for (var cmd in _toutesCommandes) {
        if (cmd.idRendezVous == idRendezVous) {
          commande = cmd;
          break;
        }
      }

      if (commande == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Commande non trouvée")),
        );
        return;
      }

      // Mise à jour avec envoi de la notification
      await _commandeService!.updateStatutCommande(
        idRendezVous,
        nouveauStatut,
        commande: commande, // Passer la commande pour la notification
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour avec succès')),
      );

      // Recharger toutes les commandes après une mise à jour
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Future<void> _updateStatut(int idRendezVous, String nouveauStatut) async {
  //   if (_commandeService == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Service non initialisé")),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     await _commandeService!.updateStatutCommande(idRendezVous, nouveauStatut);
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Statut mis à jour avec succès')),
  //     );
  //
  //     // Recharger toutes les commandes après une mise à jour
  //     _refreshData();
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString())),
  //     );
  //   }
  // }

  Future<void> _updateDateHeure(int idRendezVous, DateTime nouveauDateTime) async {
    if (_commandeService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Service non initialisé")),
      );
      return;
    }

    try {
      // Récupérer la commande avant la mise à jour
      CommandeClient? commande;
      for (var cmd in _toutesCommandes) {
        if (cmd.idRendezVous == idRendezVous) {
          commande = cmd;
          break;
        }
      }

      if (commande == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Commande non trouvée")),
        );
        return;
      }

      // Mise à jour avec envoi de la notification
      await _commandeService!.updateDateHeureCommande(
        idRendezVous,
        nouveauDateTime,
        commande: commande, // Passer la commande pour la notification
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Date et heure mises à jour avec succès')),
      );

      // Recharger toutes les commandes après une mise à jour
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }


  // Future<void> _updateDateHeure(int idRendezVous, DateTime nouveauDateTime) async {
  //   if (_commandeService == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Service non initialisé")),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     await _commandeService!.updateDateHeureCommande(idRendezVous, nouveauDateTime);
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Date et heure mises à jour avec succès')),
  //     );
  //
  //     // Recharger toutes les commandes après une mise à jour
  //     _refreshData();
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString())),
  //     );
  //   }
  // }

  void _showDatePicker(BuildContext context, int idRendezVous) {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 90)),
      onConfirm: (date) {
        _updateDateHeure(idRendezVous, date);
      },
      currentTime: DateTime.now(),
      locale: LocaleType.fr,
    );
  }

  void _showStatusDialog(BuildContext context, int idRendezVous) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le statut'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusButton('Confirmer', 'confirmé', idRendezVous),
              _buildStatusButton('Annuler avec remboursement', 'annulé', idRendezVous, withRefund: true),
              _buildStatusButton('Annuler sans remboursement', 'annulé', idRendezVous, withRefund: false),
              _buildStatusButton('Marquer comme terminé', 'terminé', idRendezVous),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusButton(String label, String status, int idRendezVous, {bool? withRefund}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _getColorForStatus(status),
          minimumSize: Size(double.infinity, 40),
        ),
        onPressed: () {
          Navigator.of(context).pop();

          if (status == 'annulé' && withRefund != null) {
            _updateStatutWithRefund(idRendezVous, status, withRefund);
          } else {
            _updateStatut(idRendezVous, status);
          }
        },
        child: Text(label),
      ),
    );
  }

  Future<void> _updateStatutWithRefund(int idRendezVous, String nouveauStatut, bool withRefund) async {
    if (_commandeService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Service non initialisé")),
      );
      return;
    }

    try {
      // Récupérer la commande avant la mise à jour
      CommandeClient? commande;
      for (var cmd in _toutesCommandes) {
        if (cmd.idRendezVous == idRendezVous) {
          commande = cmd;
          break;
        }
      }

      if (commande == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Commande non trouvée")),
        );
        return;
      }

      // Mise à jour du statut
      await _commandeService!.updateStatutCommande(
        idRendezVous,
        nouveauStatut,
        commande: commande,
      );

      // Si remboursement demandé
      if (withRefund) {
        try {
          // Récupérer les informations de paiement
          final paiementInfo = await _commandeService!.getPaiementInfo(idRendezVous);

          if (paiementInfo != null && paiementInfo.containsKey('idTblPaiement')) {
            int idPaiement = paiementInfo['idTblPaiement'];

            // Afficher une boîte de dialogue de confirmation
            _showRefundConfirmationDialog(idPaiement, commande.totalPrix);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Aucun paiement trouvé pour ce rendez-vous")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors du remboursement: $e")),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour avec succès')),
      );

      // Recharger toutes les commandes après une mise à jour
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showRefundConfirmationDialog(int idPaiement, double totalMontant) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isFullRefund = true;
        double partialAmount = totalMontant;

        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Confirmer le remboursement'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Voulez-vous effectuer un remboursement total ou partiel?',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text('Total (${totalMontant.toStringAsFixed(2)}€)'),
                            value: true,
                            groupValue: isFullRefund,
                            onChanged: (value) {
                              setState(() {
                                isFullRefund = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text('Partiel'),
                            value: false,
                            groupValue: isFullRefund,
                            onChanged: (value) {
                              setState(() {
                                isFullRefund = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (!isFullRefund)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Montant à rembourser (€)',
                            hintText: 'Ex: 25.00',
                          ),
                          onChanged: (value) {
                            try {
                              partialAmount = double.parse(value);
                            } catch (e) {
                              // Gérer l'erreur de conversion
                            }
                          },
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Annuler'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6A3DE8),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();

                      try {
                        final result = await _commandeService!.remboursementPaiement(
                          idPaiement,
                          montant: isFullRefund ? null : partialAmount,
                        );

                        // Utilisation de la valeur de retour
                        String successMessage = 'Remboursement effectué avec succès';
                        if (result.containsKey('refund_id')) {
                          successMessage += ' (ID: ${result['refund_id']})';
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(successMessage)),
                        );

                        // Recharger les données
                        _refreshData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors du remboursement: $e')),
                        );
                      }
                    },
                    child: Text('Confirmer le remboursement'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // void _showStatusDialog(BuildContext context, int idRendezVous) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Modifier le statut'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             _buildStatusButton('Confirmer', 'confirmé', idRendezVous),
  //             _buildStatusButton('Annuler', 'annulé', idRendezVous),
  //             _buildStatusButton('Marquer comme terminé', 'terminé', idRendezVous),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text('Fermer'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Widget _buildStatusButton(String label, String status, int idRendezVous) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //     child: ElevatedButton(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: _getColorForStatus(status),
  //         minimumSize: Size(double.infinity, 40),
  //       ),
  //       onPressed: () {
  //         Navigator.of(context).pop();
  //         _updateStatut(idRendezVous, status);
  //       },
  //       child: Text(label),
  //     ),
  //   );
  // }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'en attente':
        return Colors.orange;
      case 'confirmé':
        return Colors.green;
      case 'annulé':
        return Colors.red;
      case 'terminé':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6A3DE8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mes Rendez-vous',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Compteur de commandes en attente
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hi ${widget.currentUser.prenom}\n',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: _toutesCommandes.where((c) => c.statut == 'en attente').length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' rendez-vous en attente',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundImage: widget.currentUser.photoProfil != null
                      ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
                      : AssetImage('assets/images/avatar.png') as ImageProvider,
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),

          // TabBar pour les filtres - Ajout de l'onglet "Tous"
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Tous'), // Nouvel onglet
              Tab(text: 'En attente'),
              Tab(text: 'Confirmés'),
              Tab(text: 'Annulés'),
              Tab(text: 'Terminés'),
            ],
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
          ),

          // Contenu principal - Liste des commandes
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _buildCommandesList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandesList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)));
    }

    if (_commandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _currentFilter == 'tous'
                  ? 'Aucun rendez-vous'
                  : 'Aucun rendez-vous ${_currentFilter}',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refreshData,
              child: Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A3DE8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _commandes.length,
        itemBuilder: (context, index) {
          final commande = _commandes[index];
          return _buildCommandeCard(commande);
        },
      ),
    );
  }

  Widget _buildCommandeCard(CommandeClient commande) {
    final dateHeure = DateTime.parse(commande.dateHeure);
    final nomCompletClient = '${commande.prenomClient} ${commande.nomClient}';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec la date et le statut
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF6A3DE8).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Color(0xFF6A3DE8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      dateFormat.format(dateHeure),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A3DE8),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorForStatus(commande.statut),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    commande.statut.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations client
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, color: Colors.grey),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomCompletClient,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Tél: ${commande.telephoneClient}',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),

                Divider(height: 24),

                // Liste des services
                Text(
                  'Services:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                ...commande.services.map((service) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(service.intituleService),
                      Text('${service.prixApplique}€'),
                    ],
                  ),
                )).toList(),

                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${commande.totalPrix}€',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A3DE8),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Durée:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${commande.dureeTotale} min',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Afficher le statut de paiement si disponible
                if (commande.statutPaiement != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          commande.statutPaiement == 'Payé'
                              ? Icons.check_circle
                              : Icons.pending,
                          color: commande.statutPaiement == 'Payé'
                              ? Colors.green
                              : Colors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          commande.statutPaiement!,
                          style: TextStyle(
                            color: commande.statutPaiement == 'Payé'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                // Actions (visibles uniquement pour les commandes en attente ou confirmées)
                if (commande.statut == 'en attente' || commande.statut == 'confirmé')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.update),
                          label: Text('Statut'),
                          onPressed: () => _showStatusDialog(context, commande.idRendezVous),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF6A3DE8),
                            side: BorderSide(color: Color(0xFF6A3DE8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.edit_calendar),
                          label: Text('Date/Heure'),
                          onPressed: () => _showDatePicker(context, commande.idRendezVous),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6A3DE8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}