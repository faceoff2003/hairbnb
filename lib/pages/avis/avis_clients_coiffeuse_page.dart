// pages/avis/avis_clients_coiffeuse_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/avis_client.dart';
import '../../models/current_user.dart';
import '../../services/providers/current_user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'services/avis_service.dart';

class AvisClientsCoiffeusePage extends StatefulWidget {
  const AvisClientsCoiffeusePage({super.key});

  @override
  _AvisClientsCoiffeusePageState createState() => _AvisClientsCoiffeusePageState();
}

class _AvisClientsCoiffeusePageState extends State<AvisClientsCoiffeusePage> {
  List<AvisClient> _avisClients = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _salonNom;
  CurrentUser? _currentUser;

  // Filtres
  int? _noteFiltre;
  final List<int> _notesDisponibles = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _chargerAvisClients();
  }

  /// 👤 Récupérer l'utilisateur actuel
  void _getCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    _currentUser = currentUserProvider.currentUser;
  }

  /// 🔄 Charger tous les avis des clients
  Future<void> _chargerAvisClients() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await AvisService.getAvisClientsCoiffeuse(
        context: context,
        noteFiltre: _noteFiltre,
      );

      if (mounted) {
        setState(() {
          _avisClients = result['avis'] ?? [];
          _salonNom = result['salon']?['nom'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors du chargement des avis clients: $e");
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 🎯 Appliquer un filtre par note
  void _appliquerFiltreNote(int? note) {
    setState(() {
      _noteFiltre = note;
    });
    _chargerAvisClients();
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
      case 1: return 'Très décevant';
      case 2: return 'Décevant';
      case 3: return 'Correct';
      case 4: return 'Très bien';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  /// 🔢 Calculer les statistiques
  Map<String, dynamic> _calculerStatistiques() {
    if (_avisClients.isEmpty) return {};

    double moyenne = _avisClients.map((a) => a.note).reduce((a, b) => a + b) / _avisClients.length;
    Map<int, int> repartition = {};

    for (int i = 1; i <= 5; i++) {
      repartition[i] = _avisClients.where((a) => a.note == i).length;
    }

    return {
      'moyenne': moyenne,
      'total': _avisClients.length,
      'repartition': repartition,
    };
  }

  /// 📊 Widget des statistiques
  Widget _buildStatistiques() {
    final stats = _calculerStatistiques();
    if (stats.isEmpty) return SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            '📊 Statistiques des avis',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),

          // Moyennes
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${stats['total']}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Avis reçus',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${stats['moyenne'].toStringAsFixed(1)}',
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

          SizedBox(height: 12),

          // Répartition par étoiles
          Row(
            children: List.generate(5, (index) {
              final note = index + 1;
              final count = stats['repartition'][note] ?? 0;
              final percentage = (count / stats['total'] * 100).round();

              return Expanded(
                child: Column(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: isSmallScreen ? 16 : 18),
                    Text(
                      '$note',
                      style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 10 : 12),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 8 : 10),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 🔍 Widget des filtres
  Widget _buildFiltres() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Filtrer par note:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 8),

          // Bouton "Toutes"
          FilterChip(
            label: Text('Toutes'),
            selected: _noteFiltre == null,
            onSelected: (_) => _appliquerFiltreNote(null),
            selectedColor: Colors.orange.withOpacity(0.3),
          ),

          SizedBox(width: 8),

          // Filtres par étoiles
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _notesDisponibles.map((note) {
                  return Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(' $note'),
                        ],
                      ),
                      selected: _noteFiltre == note,
                      onSelected: (_) => _appliquerFiltreNote(note),
                      selectedColor: Colors.orange.withOpacity(0.3),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💳 Construire une carte d'avis client
  Widget _buildAvisCard(AvisClient avis) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 En-tête client
            Row(
              children: [
                // Avatar client
                Container(
                  width: isSmallScreen ? 40 : 45,
                  height: isSmallScreen ? 40 : 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade600],
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),

                SizedBox(width: 12),

                // Infos client
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avis.clientNomComplet,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (avis.dateFormatee.isNotEmpty)
                        Text(
                          'Avis du ${avis.dateFormatee}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Note et badge
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(5, (i) => Icon(
                          Icons.star,
                          size: isSmallScreen ? 14 : 16,
                          color: i < avis.note ? Colors.amber : Colors.grey[300],
                        )),
                        SizedBox(width: 4),
                        Text(
                          '${avis.note}/5',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCouleurNote(avis.note),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getTexteNote(avis.note),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

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
                        'Commentaire du client',
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
                      fontSize: isSmallScreen ? 13 : 14,
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
              'Aucun avis reçu',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _noteFiltre != null
                  ? 'Aucun avis avec $_noteFiltre étoile${_noteFiltre! > 1 ? 's' : ''} trouvé.'
                  : 'Vos clients n\'ont pas encore laissé d\'avis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24),
            if (_noteFiltre != null)
              ElevatedButton.icon(
                onPressed: () => _appliquerFiltreNote(null),
                icon: Icon(Icons.clear),
                label: Text('Voir tous les avis'),
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
              onPressed: _chargerAvisClients,
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

  /// 📱 Construire la sidebar
  Widget _buildSideDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _currentUser?.photoProfil != null
                      ? NetworkImage('https://www.hairbnb.site${_currentUser!.photoProfil}')
                      : AssetImage('assets/images/avatar.png') as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: 10),
                Text(
                  _currentUser != null ? '${_currentUser!.prenom} ${_currentUser!.nom}' : 'Utilisateur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentUser?.type ?? 'Type d\'utilisateur',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Accueil'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers l'accueil
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Mes Rendez-vous'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers les rendez-vous
            },
          ),
          ListTile(
            leading: Icon(Icons.rate_review),
            title: Text('Avis clients'),
            selected: true,
            selectedTileColor: Colors.orange.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: Text('Rechercher'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers la recherche
            },
          ),
          ListTile(
            leading: Icon(Icons.message),
            title: Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers les messages
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers le profil
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers les paramètres
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context);
              // Logique de déconnexion
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      appBar: CustomAppBar(),
      drawer: _buildSideDrawer(),
      body: RefreshIndicator(
        onRefresh: _chargerAvisClients,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Chargement des avis...',
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
            : _avisClients.isEmpty
            ? _buildEmptyState()
            : Column(
          children: [
            // En-tête avec titre et nom du salon
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avis de mes clients',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_salonNom != null)
                    Text(
                      _salonNom!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),

            // Statistiques
            _buildStatistiques(),

            // Filtres
            _buildFiltres(),

            SizedBox(height: 16),

            // Liste des avis
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 16),
                itemCount: _avisClients.length,
                itemBuilder: (context, index) {
                  final avis = _avisClients[index];
                  return _buildAvisCard(avis);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4, // Index pour "Profil" (ou vous pouvez choisir un autre index approprié)
        onTap: (index) {
          // La navigation est gérée dans BottomNavBar
        },
      ),
    );
  }
}







// // pages/avis/avis_clients_coiffeuse_page.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../models/avis_client.dart';
// import 'services/avis_service.dart';
//
// class AvisClientsCoiffeusePage extends StatefulWidget {
//   const AvisClientsCoiffeusePage({super.key});
//
//   @override
//   _AvisClientsCoiffeusePageState createState() => _AvisClientsCoiffeusePageState();
// }
//
// class _AvisClientsCoiffeusePageState extends State<AvisClientsCoiffeusePage> {
//   List<AvisClient> _avisClients = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   String? _salonNom;
//
//   // Filtres
//   int? _noteFiltre;
//   final List<int> _notesDisponibles = [1, 2, 3, 4, 5];
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerAvisClients();
//   }
//
//   /// 🔄 Charger tous les avis des clients
//   Future<void> _chargerAvisClients() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       final result = await AvisService.getAvisClientsCoiffeuse(
//         context: context,
//         noteFiltre: _noteFiltre,
//       );
//
//       if (mounted) {
//         setState(() {
//           _avisClients = result['avis'] ?? [];
//           _salonNom = result['salon']?['nom'];
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur lors du chargement des avis clients: $e");
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
//   /// 🎯 Appliquer un filtre par note
//   void _appliquerFiltreNote(int? note) {
//     setState(() {
//       _noteFiltre = note;
//     });
//     _chargerAvisClients();
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
//       case 1: return 'Très décevant';
//       case 2: return 'Décevant';
//       case 3: return 'Correct';
//       case 4: return 'Très bien';
//       case 5: return 'Excellent';
//       default: return '';
//     }
//   }
//
//   /// 🔢 Calculer les statistiques
//   Map<String, dynamic> _calculerStatistiques() {
//     if (_avisClients.isEmpty) return {};
//
//     double moyenne = _avisClients.map((a) => a.note).reduce((a, b) => a + b) / _avisClients.length;
//     Map<int, int> repartition = {};
//
//     for (int i = 1; i <= 5; i++) {
//       repartition[i] = _avisClients.where((a) => a.note == i).length;
//     }
//
//     return {
//       'moyenne': moyenne,
//       'total': _avisClients.length,
//       'repartition': repartition,
//     };
//   }
//
//   /// 📊 Widget des statistiques
//   Widget _buildStatistiques() {
//     final stats = _calculerStatistiques();
//     if (stats.isEmpty) return SizedBox.shrink();
//
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//
//     return Container(
//       margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
//       padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.orange, Colors.deepOrange],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Titre
//           Text(
//             '📊 Statistiques des avis',
//             style: TextStyle(
//               fontSize: isSmallScreen ? 14 : 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           SizedBox(height: 12),
//
//           // Moyennes
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       '${stats['total']}',
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 20 : 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Text(
//                       'Avis reçus',
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 10 : 12,
//                         color: Colors.white70,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(width: 1, height: 40, color: Colors.white30),
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       '${stats['moyenne'].toStringAsFixed(1)}',
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 20 : 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Text(
//                       'Note moyenne',
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 10 : 12,
//                         color: Colors.white70,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           SizedBox(height: 12),
//
//           // Répartition par étoiles
//           Row(
//             children: List.generate(5, (index) {
//               final note = index + 1;
//               final count = stats['repartition'][note] ?? 0;
//               final percentage = (count / stats['total'] * 100).round();
//
//               return Expanded(
//                 child: Column(
//                   children: [
//                     Icon(Icons.star, color: Colors.white, size: isSmallScreen ? 16 : 18),
//                     Text(
//                       '$note',
//                       style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 10 : 12),
//                     ),
//                     Text(
//                       '$count',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: isSmallScreen ? 12 : 14,
//                       ),
//                     ),
//                     Text(
//                       '$percentage%',
//                       style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 8 : 10),
//                     ),
//                   ],
//                 ),
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 🔍 Widget des filtres
//   Widget _buildFiltres() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         children: [
//           Text(
//             'Filtrer par note:',
//             style: TextStyle(fontWeight: FontWeight.w600),
//           ),
//           SizedBox(width: 8),
//
//           // Bouton "Toutes"
//           FilterChip(
//             label: Text('Toutes'),
//             selected: _noteFiltre == null,
//             onSelected: (_) => _appliquerFiltreNote(null),
//             selectedColor: Colors.orange.withOpacity(0.3),
//           ),
//
//           SizedBox(width: 8),
//
//           // Filtres par étoiles
//           Expanded(
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: _notesDisponibles.map((note) {
//                   return Padding(
//                     padding: EdgeInsets.only(right: 6),
//                     child: FilterChip(
//                       label: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.star, size: 14, color: Colors.amber),
//                           Text(' $note'),
//                         ],
//                       ),
//                       selected: _noteFiltre == note,
//                       onSelected: (_) => _appliquerFiltreNote(note),
//                       selectedColor: Colors.orange.withOpacity(0.3),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 💳 Construire une carte d'avis client
//   Widget _buildAvisCard(AvisClient avis) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//
//     return Card(
//       margin: EdgeInsets.symmetric(
//         horizontal: isSmallScreen ? 8 : 16,
//         vertical: 8,
//       ),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 👤 En-tête client
//             Row(
//               children: [
//                 // Avatar client
//                 Container(
//                   width: isSmallScreen ? 40 : 45,
//                   height: isSmallScreen ? 40 : 45,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [Colors.blue.shade300, Colors.blue.shade600],
//                     ),
//                   ),
//                   child: Icon(
//                     Icons.person,
//                     color: Colors.white,
//                     size: isSmallScreen ? 20 : 24,
//                   ),
//                 ),
//
//                 SizedBox(width: 12),
//
//                 // Infos client
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         avis.clientNomComplet,
//                         style: GoogleFonts.poppins(
//                           fontSize: isSmallScreen ? 14 : 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       if (avis.dateFormatee.isNotEmpty)
//                         Text(
//                           'Avis du ${avis.dateFormatee}',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 10 : 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//                 // Note et badge
//                 Column(
//                   children: [
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         ...List.generate(5, (i) => Icon(
//                           Icons.star,
//                           size: isSmallScreen ? 14 : 16,
//                           color: i < avis.note ? Colors.amber : Colors.grey[300],
//                         )),
//                         SizedBox(width: 4),
//                         Text(
//                           '${avis.note}/5',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 12 : 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 4),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isSmallScreen ? 6 : 8,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _getCouleurNote(avis.note),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         _getTexteNote(avis.note),
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 8 : 10,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//
//             SizedBox(height: 12),
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
//                         'Commentaire du client',
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
//                       fontSize: isSmallScreen ? 13 : 14,
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
//               'Aucun avis reçu',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               _noteFiltre != null
//                   ? 'Aucun avis avec $_noteFiltre étoile${_noteFiltre! > 1 ? 's' : ''} trouvé.'
//                   : 'Vos clients n\'ont pas encore laissé d\'avis.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[500],
//               ),
//             ),
//             SizedBox(height: 24),
//             if (_noteFiltre != null)
//               ElevatedButton.icon(
//                 onPressed: () => _appliquerFiltreNote(null),
//                 icon: Icon(Icons.clear),
//                 label: Text('Voir tous les avis'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
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
//               onPressed: _chargerAvisClients,
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
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Avis de mes clients',
//               style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
//             ),
//             if (_salonNom != null)
//               Text(
//                 _salonNom!,
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 12 : 14,
//                   color: Colors.white70,
//                 ),
//               ),
//           ],
//         ),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: RefreshIndicator(
//         onRefresh: _chargerAvisClients,
//         child: _isLoading
//             ? Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: Colors.orange),
//               SizedBox(height: 16),
//               Text(
//                 'Chargement des avis...',
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
//             : _avisClients.isEmpty
//             ? _buildEmptyState()
//             : Column(
//           children: [
//             // Statistiques
//             _buildStatistiques(),
//
//             // Filtres
//             _buildFiltres(),
//
//             SizedBox(height: 16),
//
//             // Liste des avis
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.only(bottom: 16),
//                 itemCount: _avisClients.length,
//                 itemBuilder: (context, index) {
//                   final avis = _avisClients[index];
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