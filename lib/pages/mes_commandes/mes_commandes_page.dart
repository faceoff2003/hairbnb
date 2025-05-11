import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/pages/mes_commandes/services/card_service.dart';
import 'package:hairbnb/pages/mes_commandes/services/pagination_service.dart';
import 'package:hairbnb/pages/mes_commandes/widgets/loading_indicator_widget.dart';
import 'dart:async';
import '../../models/mes_commandes.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';
import 'api/mes_commandes_api.dart';

class MesCommandesPage extends StatefulWidget {
  final CurrentUser currentUser;

  const MesCommandesPage({super.key, required this.currentUser});

  @override
  State<MesCommandesPage> createState() => _MesCommandesPageState();
}

class _MesCommandesPageState extends State<MesCommandesPage> with CommandesPaginationMixin {
  bool _isLoading = true;
  String? _error;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
  int _currentNavIndex = 0;

  // Liste complète des commandes (non filtrées)
  List<Commande> _commandes = [];

  @override
  void initState() {
    super.initState();
    _chargerCommandes();
    _currentNavIndex = 2;
  }

  // La méthode pour gérer les changements d'onglet
  void _onNavIndexChanged(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  Future<void> _chargerCommandes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final commandes = await CommandesApiService.chargerCommandes(widget.currentUser.idTblUser);
      setState(() {
        _commandes = commandes;
        _isLoading = false;

        // Mettre à jour la liste pour la pagination
        setFullCommandesList(_filteredCommandes);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Filtrer les commandes selon le statut sélectionné
  List<Commande> get _filteredCommandes {
    if (_selectedFilterIndex == 0) return _commandes;

    // Convertir les statuts pour qu'ils correspondent
    Map<String, List<String>> statusMap = {
      'confirmés': ['confirmé', 'confirme', 'confirmes'],
      'en attente': ['en attente', 'en_attente', 'attente'],
      'terminés': ['terminé', 'termine', 'termines'],
      'annulés': ['annulé', 'annule', 'annules'],
    };

    final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
    final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];

    return _commandes.where((commande) {
      final normalizedStatus = commande.statut.toLowerCase().trim();
      return matchingStatuses.contains(normalizedStatus);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavIndexChanged,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: 'Chargement de vos commandes...'),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_commandes.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        // Filtres en haut
        _buildFilterTabs(),

        // Liste des commandes avec pagination
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _chargerCommandes();
              await refreshList();
            },
            color: Colors.purple.shade400,
            child: paginatedCommandes.isEmpty
                ? _buildNoFilterMatchView()
                : _buildCommandesList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
                // Mettre à jour la liste paginée lorsque le filtre change
                setFullCommandesList(_filteredCommandes);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _selectedFilterIndex == index
                    ? Colors.purple.shade400
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: _selectedFilterIndex == index
                      ? Colors.white
                      : Colors.grey.shade700,
                  fontWeight: _selectedFilterIndex == index
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommandesList() {
    return ListView.builder(
      controller: scrollController, // Utiliser le contrôleur de la pagination
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: paginatedCommandes.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Afficher l'indicateur de chargement si on charge plus d'éléments
        if (isLoadingMore && index == paginatedCommandes.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.purple.shade400,
                strokeWidth: 3,
              ),
            ),
          );
        }

        // Afficher une carte de commande
        return CommandeCard(commande: paginatedCommandes[index]);
      },
    );
  }

  Widget _buildNoFilterMatchView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez un autre filtre pour voir vos commandes',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Oups! Quelque chose s\'est mal passé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _chargerCommandes,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.purple.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune commande pour le moment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Découvrez nos salons et faites votre première réservation',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/catalogue');
            },
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('Découvrir les salons'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'dart:async';
// import '../../models/mes_commandes.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/custom_app_bar.dart';
// import 'api/mes_commandes_api.dart';
// import 'mes_commandes_services/card_service.dart';
//
// class MesCommandesPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MesCommandesPage({super.key, required this.currentUser});
//
//   @override
//   State<MesCommandesPage> createState() => _MesCommandesPageState();
// }
//
// class _MesCommandesPageState extends State<MesCommandesPage> {
//   bool _isLoading = true;
//   List<Commande> _commandes = [];
//   String? _error;
//   int _selectedFilterIndex = 0;
//   final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
//   int _currentNavIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerCommandes();
//     _currentNavIndex = 2;
//   }
//
//   // La méthode pour gérer les changements d'onglet
//   void _onNavIndexChanged(int index) {
//     setState(() {
//       _currentNavIndex = index;
//     });
//   }
//
//   Future<void> _chargerCommandes() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final commandes = await CommandesApiService.chargerCommandes(widget.currentUser.idTblUser);
//       setState(() {
//         _commandes = commandes;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Filtrer les commandes selon le statut sélectionné
//   List<Commande> get _filteredCommandes {
//     if (_selectedFilterIndex == 0) return _commandes;
//
//     // Convertir les statuts pour qu'ils correspondent
//     Map<String, List<String>> statusMap = {
//       'confirmés': ['confirmé', 'confirme', 'confirmes'],
//       'en attente': ['en attente', 'en_attente', 'attente'],
//       'terminés': ['terminé', 'termine', 'termines'],
//       'annulés': ['annulé', 'annule', 'annules'],
//     };
//
//     final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
//     final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];
//
//     return _commandes.where((commande) {
//       final normalizedStatus = commande.statut.toLowerCase().trim();
//       return matchingStatuses.contains(normalizedStatus);
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentNavIndex,
//         onTap: _onNavIndexChanged,
//       ),
//       body: _buildBody(),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: Colors.purple.shade400,
//               strokeWidth: 3,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Chargement de vos commandes...',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const Icon(
//                 Icons.error_outline_rounded,
//                 size: 60,
//                 color: Colors.redAccent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Oups! Quelque chose s\'est mal passé',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerCommandes,
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_commandes.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: Colors.purple.shade50,
//                 borderRadius: BorderRadius.circular(100),
//               ),
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 size: 80,
//                 color: Colors.purple.shade300,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Aucune commande pour le moment',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 'Découvrez nos salons et faites votre première réservation',
//                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pushNamed('/catalogue');
//               },
//               icon: const Icon(Icons.storefront_rounded),
//               label: const Text('Découvrir les salons'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: [
//         // Filtres en haut
//         Container(
//           height: 50,
//           margin: const EdgeInsets.symmetric(vertical: 16),
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: _filters.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedFilterIndex = index;
//                   });
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: _selectedFilterIndex == index
//                         ? Colors.purple.shade400
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     _filters[index],
//                     style: TextStyle(
//                       color: _selectedFilterIndex == index
//                           ? Colors.white
//                           : Colors.grey.shade700,
//                       fontWeight: _selectedFilterIndex == index
//                           ? FontWeight.bold
//                           : FontWeight.normal,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//
//         // Liste des commandes
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _chargerCommandes,
//             color: Colors.purple.shade400,
//             child: _filteredCommandes.isEmpty
//                 ? Center(
//               child: Text(
//                 'Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: 16,
//                 ),
//               ),
//             )
//                 : ListView.builder(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               itemCount: _filteredCommandes.length,
//               itemBuilder: (context, index) {
//                 return CommandeCard(commande: _filteredCommandes[index]);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }







// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/mes_commandes/sub_pages/recu_page.dart';
// import 'package:intl/intl.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../models/mes_commandes.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/custom_app_bar.dart';
//
// class MesCommandesPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MesCommandesPage({super.key, required this.currentUser});
//
//   @override
//   State<MesCommandesPage> createState() => _MesCommandesPageState();
// }
//
// class _MesCommandesPageState extends State<MesCommandesPage> {
//   bool _isLoading = true;
//   List<Commande> _commandes = [];
//   String? _error;
//   int _selectedFilterIndex = 0;
//   final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
//   int _currentNavIndex = 0;
//
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerCommandes();
//     _currentNavIndex = 2;
//   }
//
//   // La méthode pour gérer les changements d'onglet
//   void _onNavIndexChanged(int index) {
//     setState(() {
//       _currentNavIndex = index;
//     });
//   }
//
//   Future<void> _chargerCommandes() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//       final response = await http.get(
//         Uri.parse('$_baseUrl/mes-commandes/${widget.currentUser.idTblUser}/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
//         setState(() {
//           _commandes = Commande.fromJsonList(jsonList);
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _error = 'Erreur lors du chargement des commandes: ${response.statusCode}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Erreur de connexion: $e';
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Filtrer les commandes selon le statut sélectionné
//   List<Commande> get _filteredCommandes {
//     if (_selectedFilterIndex == 0) return _commandes;
//
//     // Convertir les statuts pour qu'ils correspondent
//     Map<String, List<String>> statusMap = {
//       'confirmés': ['confirmé', 'confirme', 'confirmes'],
//       'en attente': ['en attente', 'en_attente', 'attente'],
//       'terminés': ['terminé', 'termine', 'termines'],
//       'annulés': ['annulé', 'annule', 'annules'],
//     };
//
//     final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
//     final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];
//
//     return _commandes.where((commande) {
//       final normalizedStatus = commande.statut.toLowerCase().trim();
//       return matchingStatuses.contains(normalizedStatus);
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentNavIndex,
//         onTap: _onNavIndexChanged,
//       ),
//       body: _buildBody(),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: Colors.purple.shade400,
//               strokeWidth: 3,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Chargement de vos commandes...',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const Icon(
//                 Icons.error_outline_rounded,
//                 size: 60,
//                 color: Colors.redAccent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Oups! Quelque chose s\'est mal passé',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerCommandes,
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_commandes.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: Colors.purple.shade50,
//                 borderRadius: BorderRadius.circular(100),
//               ),
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 size: 80,
//                 color: Colors.purple.shade300,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Aucune commande pour le moment',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 'Découvrez nos salons et faites votre première réservation',
//                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pushNamed('/catalogue');
//               },
//               icon: const Icon(Icons.storefront_rounded),
//               label: const Text('Découvrir les salons'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: [
//         // Filtres en haut
//         Container(
//           height: 50,
//           margin: const EdgeInsets.symmetric(vertical: 16),
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: _filters.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedFilterIndex = index;
//                   });
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: _selectedFilterIndex == index
//                         ? Colors.purple.shade400
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     _filters[index],
//                     style: TextStyle(
//                       color: _selectedFilterIndex == index
//                           ? Colors.white
//                           : Colors.grey.shade700,
//                       fontWeight: _selectedFilterIndex == index
//                           ? FontWeight.bold
//                           : FontWeight.normal,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//
//         // Liste des commandes
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _chargerCommandes,
//             color: Colors.purple.shade400,
//             child: _filteredCommandes.isEmpty
//                 ? Center(
//               child: Text(
//                 'Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: 16,
//                 ),
//               ),
//             )
//                 : ListView.builder(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               itemCount: _filteredCommandes.length,
//               itemBuilder: (context, index) {
//                 return CommandeCard(commande: _filteredCommandes[index]);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class CommandeCard extends StatefulWidget {
//   final Commande commande;
//
//   const CommandeCard({super.key, required this.commande});
//
//   @override
//   State<CommandeCard> createState() => _CommandeCardState();
// }
//
// class _CommandeCardState extends State<CommandeCard> {
//   final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
//   final DateFormat timeFormatter = DateFormat('HH:mm');
//   Timer? _timer;
//   Duration _timeLeft = Duration.zero;
//   bool _isExpired = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _calculateTimeLeft();
//
//     // Démarrer le timer seulement si la date est dans le futur et si le statut n'est pas annulé ou terminé
//     if (_timeLeft.inSeconds > 0 &&
//         !["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())) {
//       _startTimer();
//     } else if (_timeLeft.inSeconds <= 0) {
//       _isExpired = true;
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   void _calculateTimeLeft() {
//     final now = DateTime.now();
//     if (widget.commande.dateHeure.isAfter(now)) {
//       _timeLeft = widget.commande.dateHeure.difference(now);
//     } else {
//       _timeLeft = Duration.zero;
//       _isExpired = true;
//     }
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_timeLeft.inSeconds > 0) {
//           _timeLeft = _timeLeft - const Duration(seconds: 1);
//         } else {
//           _isExpired = true;
//           _timer?.cancel();
//         }
//       });
//     });
//   }
//
//   // Widget pour afficher une unité de temps (jours, heures, minutes, secondes)
//   Widget _buildTimeUnit(String value, String unit) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 2),
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.purple[600],
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               fontSize: 14,
//             ),
//           ),
//           Text(
//             unit,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Widget pour afficher le compte à rebours
//   Widget _buildCountdown() {
//     if (_isExpired && ["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())) {
//       return const SizedBox.shrink(); // Ne pas afficher de compte à rebours pour les commandes terminées ou annulées
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: _isExpired ? Colors.orange[50] : Colors.purple[50],
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: _isExpired ? Colors.orange[200]! : Colors.purple[100]!),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 _isExpired ? Icons.timer_off : Icons.timer,
//                 size: 16,
//                 color: _isExpired ? Colors.orange : Colors.purple,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 _isExpired ? "Rendez-vous commencé" : "Temps restant",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: _isExpired ? Colors.orange : Colors.purple,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//           if (!_isExpired) ...[
//             const SizedBox(height: 6),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (_timeLeft.inDays > 0)
//                   _buildTimeUnit("${_timeLeft.inDays}", "j"),
//
//                 _buildTimeUnit("${(_timeLeft.inHours % 24).toString().padLeft(2, '0')}", "h"),
//
//                 _buildTimeUnit("${(_timeLeft.inMinutes % 60).toString().padLeft(2, '0')}", "m"),
//
//                 _buildTimeUnit("${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}", "s"),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {
//             _showCommandeDetails(context);
//           },
//           child: Column(
//             children: [
//               // Barre d'état supérieure
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(widget.commande.statut),
//                 ),
//               ),
//
//               // En-tête de la commande
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     // Avatar du salon
//                     Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         color: Colors.purple.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       alignment: Alignment.center,
//                       child: Text(
//                         widget.commande.nomSalon.isNotEmpty ? widget.commande.nomSalon[0].toUpperCase() : 'S',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//
//                     // Informations principales
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.commande.nomSalon,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(
//                                   Icons.event,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 dateFormatter.format(widget.commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Icon(
//                                   Icons.access_time,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 timeFormatter.format(widget.commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Indicateur de statut
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(widget.commande.statut).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         widget.commande.statut,
//                         style: TextStyle(
//                           color: _getStatusColor(widget.commande.statut),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Compte à rebours dynamique
//               _buildCountdown(),
//
//               const Divider(height: 1),
//
//               // Services (simplifié)
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${widget.commande.services.length} service${widget.commande.services.length > 1 ? "s" : ""}',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           if (widget.commande.services.isNotEmpty)
//                             Text(
//                               widget.commande.services.map((s) => s.intituleService).join(', '),
//                               style: const TextStyle(
//                                 fontSize: 15,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '${widget.commande.montantPaye.toStringAsFixed(2)} €',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.purple,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Actions
//               Container(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Bouton de détails
//                     Expanded(
//                       child: TextButton.icon(
//                         onPressed: () {
//                           _showCommandeDetails(context);
//                         },
//                         icon: const Icon(Icons.visibility),
//                         label: const Text('Détails'),
//                         style: TextButton.styleFrom(
//                           foregroundColor: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//
//                     // Bouton de reçu si disponible
//                     if (widget.commande.receiptUrl != null && widget.commande.receiptUrl!.isNotEmpty)
//                       Expanded(
//                         child: TextButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: widget.commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_rounded),
//                           label: const Text('Reçu'),
//                           style: TextButton.styleFrom(
//                             foregroundColor: Colors.purple.shade700,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showCommandeDetails(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.85,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//         ),
//         child: Column(
//           children: [
//             // Barre d'indication
//             Container(
//               width: 40,
//               height: 5,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(5),
//               ),
//             ),
//
//             // Titre
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.purple.shade100,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                         Icons.receipt_long_rounded,
//                         color: Colors.purple,
//                         size: 24
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Détails de commande',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade800,
//                           ),
//                         ),
//                         Text(
//                           'Commande #${widget.commande.idRendezVous}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(widget.commande.statut).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       widget.commande.statut,
//                       style: TextStyle(
//                         color: _getStatusColor(widget.commande.statut),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Divider(),
//
//             // Compte à rebours dans les détails
//             if (!_isExpired || (_isExpired && !["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())))
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: _buildCountdown(),
//               ),
//
//             // Contenu détaillé
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Informations sur le salon
//                     _buildDetailSection(
//                       'Salon',
//                       Icons.store_rounded,
//                       [
//                         widget.commande.nomSalon,
//                         '${widget.commande.prenomCoiffeuse} ${widget.commande.nomCoiffeuse}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Informations sur la date
//                     _buildDetailSection(
//                       'Date & Heure',
//                       Icons.event_rounded,
//                       [
//                         '${dateFormatter.format(widget.commande.dateHeure)} à ${timeFormatter.format(widget.commande.dateHeure)}',
//                         'Durée: ${widget.commande.dureeTotale} minutes',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Services commandés
//                     _buildServicesSection(),
//
//                     const SizedBox(height: 20),
//
//                     // Paiement
//                     _buildDetailSection(
//                       'Paiement',
//                       Icons.payment_rounded,
//                       [
//                         '${widget.commande.montantPaye.toStringAsFixed(2)} € - ${widget.commande.methodePaiement}',
//                         'Payé le ${dateFormatter.format(widget.commande.datePaiement)}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     // Bouton pour accéder au reçu si disponible
//                     if (widget.commande.receiptUrl != null && widget.commande.receiptUrl!.isNotEmpty)
//                       Center(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: widget.commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_long),
//                           label: const Text('Voir le reçu'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.purple.shade400,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailSection(String title, IconData icon, List<String> details) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ...details.map((detail) => Padding(
//           padding: const EdgeInsets.only(left: 26, bottom: 4),
//           child: Text(
//             detail,
//             style: TextStyle(
//               fontSize: 15,
//               color: Colors.grey.shade700,
//             ),
//           ),
//         )).toList(),
//       ],
//     );
//   }
//
//   Widget _buildServicesSection() {
//     return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//     Row(
//     children: [
//     Icon(Icons.content_cut_rounded, size: 18, color: Colors.purple.shade400),
//     const SizedBox(width: 8),
//     const Text(
//     'Services',
//     style: TextStyle(
//     fontSize: 16,
//     fontWeight: FontWeight.bold,
//     ),
//     ),
//     ],
//     ),
//     const SizedBox(height: 12),
//     ...widget.commande.services.map((service) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//     color: Colors.grey.shade50,
//     borderRadius: BorderRadius.circular(12),
//     border: Border.all(color: Colors.grey.shade200),
//     ),
//     child: Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//     Expanded(
//     child: Text(
//     service.intituleService,
//     style: const TextStyle(fontSize: 15),
//     ),
//     ),
//     Text(
//     '${service.prixApplique.toStringAsFixed(2)} €',
//     style: TextStyle(
//     fontWeight: FontWeight.bold,
//     fontSize: 16,
//       color: Colors.purple.shade700,
//     ),
//     ),
//     ],
//     ),
//     )).toList(),
//
//           // Total
//           Container(
//             margin: const EdgeInsets.only(top: 10),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//             decoration: BoxDecoration(
//               color: Colors.purple.shade50,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Total',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 Text(
//                   '${widget.commande.montantPaye.toStringAsFixed(2)} €',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmé':
//         return Colors.green;
//       case 'en attente':
//         return Colors.orange;
//       case 'annulé':
//         return Colors.red;
//       case 'terminé':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }
// }








// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/mes_commandes/sub_pages/recu_page.dart';
// import 'package:intl/intl.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../models/mes_commandes.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/custom_app_bar.dart';
//
// class MesCommandesPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MesCommandesPage({super.key, required this.currentUser});
//
//   @override
//   State<MesCommandesPage> createState() => _MesCommandesPageState();
// }
//
// class _MesCommandesPageState extends State<MesCommandesPage> {
//   bool _isLoading = true;
//   List<Commande> _commandes = [];
//   String? _error;
//   int _selectedFilterIndex = 0;
//   final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
//   int _currentNavIndex = 0;
//
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerCommandes();
//     _currentNavIndex = 2;
//   }
//
//   // La méthode pour gérer les changements d'onglet
//   void _onNavIndexChanged(int index) {
//     setState(() {
//       _currentNavIndex = index;
//     });
//   }
//
//   Future<void> _chargerCommandes() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//       final response = await http.get(
//         Uri.parse('$_baseUrl/mes-commandes/${widget.currentUser.idTblUser}/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
//         setState(() {
//           _commandes = Commande.fromJsonList(jsonList);
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _error = 'Erreur lors du chargement des commandes: ${response.statusCode}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Erreur de connexion: $e';
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Filtrer les commandes selon le statut sélectionné
//   List<Commande> get _filteredCommandes {
//     if (_selectedFilterIndex == 0) return _commandes;
//
//     // Convertir les statuts pour qu'ils correspondent
//     Map<String, List<String>> statusMap = {
//       'confirmés': ['confirmé', 'confirme', 'confirmes'],
//       'en attente': ['en attente', 'en_attente', 'attente'],
//       'terminés': ['terminé', 'termine', 'termines'],
//       'annulés': ['annulé', 'annule', 'annules'],
//     };
//
//     final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
//     final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];
//
//     return _commandes.where((commande) {
//       final normalizedStatus = commande.statut.toLowerCase().trim();
//       return matchingStatuses.contains(normalizedStatus);
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentNavIndex,
//         onTap: _onNavIndexChanged,
//       ),
//       body: _buildBody(),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: Colors.purple.shade400,
//               strokeWidth: 3,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Chargement de vos commandes...',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const Icon(
//                 Icons.error_outline_rounded,
//                 size: 60,
//                 color: Colors.redAccent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Oups! Quelque chose s\'est mal passé',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerCommandes,
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_commandes.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: Colors.purple.shade50,
//                 borderRadius: BorderRadius.circular(100),
//               ),
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 size: 80,
//                 color: Colors.purple.shade300,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Aucune commande pour le moment',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 'Découvrez nos salons et faites votre première réservation',
//                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pushNamed('/catalogue');
//               },
//               icon: const Icon(Icons.storefront_rounded),
//               label: const Text('Découvrir les salons'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: [
//         // Filtres en haut
//         Container(
//           height: 50,
//           margin: const EdgeInsets.symmetric(vertical: 16),
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: _filters.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedFilterIndex = index;
//                   });
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: _selectedFilterIndex == index
//                         ? Colors.purple.shade400
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     _filters[index],
//                     style: TextStyle(
//                       color: _selectedFilterIndex == index
//                           ? Colors.white
//                           : Colors.grey.shade700,
//                       fontWeight: _selectedFilterIndex == index
//                           ? FontWeight.bold
//                           : FontWeight.normal,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//
//         // Liste des commandes
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _chargerCommandes,
//             color: Colors.purple.shade400,
//             child: _filteredCommandes.isEmpty
//                 ? Center(
//               child: Text(
//                 'Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: 16,
//                 ),
//               ),
//             )
//                 : ListView.builder(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               itemCount: _filteredCommandes.length,
//               itemBuilder: (context, index) {
//                 return CommandeCard(commande: _filteredCommandes[index]);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class CommandeCard extends StatefulWidget {
//   final Commande commande;
//
//   const CommandeCard({super.key, required this.commande});
//
//   @override
//   State<CommandeCard> createState() => _CommandeCardState();
// }
//
// class _CommandeCardState extends State<CommandeCard> {
//   final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
//   final DateFormat timeFormatter = DateFormat('HH:mm');
//   Timer? _timer;
//   Duration _timeLeft = Duration.zero;
//   bool _isExpired = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _calculateTimeLeft();
//
//     // Démarrer le timer seulement si la date est dans le futur et si le statut n'est pas annulé ou terminé
//     if (_timeLeft.inSeconds > 0 &&
//         !["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())) {
//       _startTimer();
//     } else if (_timeLeft.inSeconds <= 0) {
//       _isExpired = true;
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   void _calculateTimeLeft() {
//     final now = DateTime.now();
//     if (widget.commande.dateHeure.isAfter(now)) {
//       _timeLeft = widget.commande.dateHeure.difference(now);
//     } else {
//       _timeLeft = Duration.zero;
//       _isExpired = true;
//     }
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_timeLeft.inSeconds > 0) {
//           _timeLeft = _timeLeft - const Duration(seconds: 1);
//         } else {
//           _isExpired = true;
//           _timer?.cancel();
//         }
//       });
//     });
//   }
//
//   // Widget pour afficher une unité de temps (jours, heures, minutes, secondes)
//   Widget _buildTimeUnit(String value, String unit) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//         decoration: BoxDecoration(
//           color: Colors.purple.shade600,
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Row(
//           children: [
//             Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 fontSize: 16,
//               ),
//             ),
//             Text(
//               unit,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.8),
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Le widget pour afficher le compte à rebours avec un design plus dynamique
//   Widget _buildCountdown() {
//     if (_isExpired && ["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())) {
//       return const SizedBox.shrink(); // Ne pas afficher de compte à rebours pour les commandes terminées ou annulées
//     }
//
//     Color baseColor = _isExpired ? Colors.orange : Colors.purple;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: baseColor.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: baseColor.shade100),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
//                 size: 18,
//                 color: baseColor.shade700,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 _isExpired ? "Rendez-vous commencé" : "Temps restant",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: baseColor.shade700,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//           if (!_isExpired) ...[
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Jours (seulement si > 0)
//                 if (_timeLeft.inDays > 0) _buildTimeUnit("${_timeLeft.inDays}", "j"),
//
//                 // Heures
//                 _buildTimeUnit("${(_timeLeft.inHours % 24).toString().padLeft(2, '0')}", "h"),
//
//                 // Minutes
//                 _buildTimeUnit("${(_timeLeft.inMinutes % 60).toString().padLeft(2, '0')}", "m"),
//
//                 // Secondes
//                 _buildTimeUnit("${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}", "s"),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {
//             _showCommandeDetails(context);
//           },
//           child: Column(
//             children: [
//               // Barre d'état supérieure
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(widget.commande.statut),
//                 ),
//               ),
//
//               // En-tête de la commande
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     // Avatar du salon (cercle avec première lettre)
//                     Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         color: Colors.purple.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       alignment: Alignment.center,
//                       child: Text(
//                         widget.commande.nomSalon.isNotEmpty ? widget.commande.nomSalon[0].toUpperCase() : 'S',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//
//                     // Informations principales
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.commande.nomSalon,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(
//                                   Icons.event,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 dateFormatter.format(widget.commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Icon(
//                                   Icons.access_time,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 timeFormatter.format(widget.commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Indicateur de statut
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(widget.commande.statut).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         widget.commande.statut,
//                         style: TextStyle(
//                           color: _getStatusColor(widget.commande.statut),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Compte à rebours dynamique
//               _buildCountdown(),
//
//               const Divider(height: 1),
//
//               // Services (simplifié)
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${widget.commande.services.length} service${widget.commande.services.length > 1 ? "s" : ""}',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           if (widget.commande.services.isNotEmpty)
//                             Text(
//                               widget.commande.services.map((s) => s.intituleService).join(', '),
//                               style: const TextStyle(
//                                 fontSize: 15,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '${widget.commande.montantPaye.toStringAsFixed(2)} €',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.purple,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Actions
//               Container(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Bouton de détails
//                     Expanded(
//                       child: TextButton.icon(
//                         onPressed: () {
//                           _showCommandeDetails(context);
//                         },
//                         icon: const Icon(Icons.visibility),
//                         label: const Text('Détails'),
//                         style: TextButton.styleFrom(
//                           foregroundColor: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//
//                     // Bouton de reçu si disponible
//                     if (widget.commande.receiptUrl != null && widget.commande.receiptUrl!.isNotEmpty)
//                       Expanded(
//                         child: TextButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: widget.commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_rounded),
//                           label: const Text('Reçu'),
//                           style: TextButton.styleFrom(
//                             foregroundColor: Colors.purple.shade700,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showCommandeDetails(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.85,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//         ),
//         child: Column(
//           children: [
//             // Barre d'indication
//             Container(
//               width: 40,
//               height: 5,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(5),
//               ),
//             ),
//
//             // Titre
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.purple.shade100,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                         Icons.receipt_long_rounded,
//                         color: Colors.purple,
//                         size: 24
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Détails de commande',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade800,
//                           ),
//                         ),
//                         Text(
//                           'Commande #${widget.commande.idRendezVous}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(widget.commande.statut).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       widget.commande.statut,
//                       style: TextStyle(
//                         color: _getStatusColor(widget.commande.statut),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Divider(),
//
//             // Compte à rebours dans les détails
//             if (!_isExpired || (_isExpired && !["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())))
//               Container(
//                 margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: _isExpired ? Colors.orange.shade50 : Colors.purple.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: _isExpired ? Colors.orange.shade200 : Colors.purple.shade200),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
//                           size: 24,
//                           color: _isExpired ? Colors.orange.shade700 : Colors.purple.shade700,
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           _isExpired ? "Rendez-vous commencé" : "Temps restant",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: _isExpired ? Colors.orange.shade700 : Colors.purple.shade700,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (!_isExpired) ...[
//                       const SizedBox(height: 12),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           if (_timeLeft.inDays > 0) _buildTimeUnit("${_timeLeft.inDays}", "j"),
//                           _buildTimeUnit("${(_timeLeft.inHours % 24).toString().padLeft(2, '0')}", "h"),
//                           _buildTimeUnit("${(_timeLeft.inMinutes % 60).toString().padLeft(2, '0')}", "m"),
//                           _buildTimeUnit("${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}", "s"),
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//
//             // Contenu détaillé dans un ScrollView
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Informations sur le salon
//                     _buildDetailSection(
//                       'Salon',
//                       Icons.store_rounded,
//                       [
//                         widget.commande.nomSalon,
//                         '${widget.commande.prenomCoiffeuse} ${widget.commande.nomCoiffeuse}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Informations sur la date
//                     _buildDetailSection(
//                       'Date & Heure',
//                       Icons.event_rounded,
//                       [
//                         '${dateFormatter.format(widget.commande.dateHeure)} à ${timeFormatter.format(widget.commande.dateHeure)}',
//                         'Durée: ${widget.commande.dureeTotale} minutes',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Services commandés
//                     _buildServicesSection(),
//
//                     const SizedBox(height: 20),
//
//                     // Paiement
//                     _buildDetailSection(
//                       'Paiement',
//                       Icons.payment_rounded,
//                       [
//                         '${widget.commande.montantPaye.toStringAsFixed(2)} € - ${widget.commande.methodePaiement}',
//                         'Payé le ${dateFormatter.format(widget.commande.datePaiement)}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     // Bouton pour accéder au reçu si disponible
//                     if (widget.commande.receiptUrl != null && widget.commande.receiptUrl!.isNotEmpty)
//                       Center(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: widget.commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_long),
//                           label: const Text('Voir le reçu'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.purple.shade400,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailSection(String title, IconData icon, List<String> details) {
//     return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//         Row(
//         children: [
//         Icon(icon, size: 18, color: Colors.purple.shade400),
//     const SizedBox(width: 8),
//     Text(
//     title,
//     style: const TextStyle(
//     fontSize: 16,
//     fontWeight: FontWeight.bold,),
//     ),
//         ],
//         ),
//           const SizedBox(height: 8),
//           ...details.map((detail) => Padding(
//             padding: const EdgeInsets.only(left: 26, bottom: 4),
//             child: Text(
//               detail,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//           )).toList(),
//         ],
//     );
//   }
//
//   Widget _buildServicesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.content_cut_rounded, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             const Text(
//               'Services',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         ...widget.commande.services.map((service) => Container(
//           margin: const EdgeInsets.only(bottom: 10),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   service.intituleService,
//                   style: const TextStyle(fontSize: 15),
//                 ),
//               ),
//               Text(
//                 '${service.prixApplique.toStringAsFixed(2)} €',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Colors.purple.shade700,
//                 ),
//               ),
//             ],
//           ),
//         )).toList(),
//
//         // Total
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//           decoration: BoxDecoration(
//             color: Colors.purple.shade50,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Total',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 '${widget.commande.montantPaye.toStringAsFixed(2)} €',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.purple,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmé':
//         return Colors.green;
//       case 'en attente':
//         return Colors.orange;
//       case 'annulé':
//         return Colors.red;
//       case 'terminé':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }
// }





// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/mes_commandes/sub_pages/recu_page.dart';
// import 'package:intl/intl.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../models/mes_commandes.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/custom_app_bar.dart';
//
// class MesCommandesPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MesCommandesPage({super.key, required this.currentUser});
//
//   @override
//   State<MesCommandesPage> createState() => _MesCommandesPageState();
// }
//
// class _MesCommandesPageState extends State<MesCommandesPage> {
//   bool _isLoading = true;
//   List<Commande> _commandes = [];
//   String? _error;
//   int _selectedFilterIndex = 0;
//   final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
//   int _currentNavIndex = 0;
//
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerCommandes();
//     _currentNavIndex = 2;
//   }
//
//   // La méthode pour gérer les changements d'onglet
//   void _onNavIndexChanged(int index) {
//     setState(() {
//       _currentNavIndex = index;
//     });
//   }
//
//   Future<void> _chargerCommandes() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//       final response = await http.get(
//         Uri.parse('$_baseUrl/mes-commandes/${widget.currentUser.idTblUser}/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
//         setState(() {
//           _commandes = Commande.fromJsonList(jsonList);
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _error = 'Erreur lors du chargement des commandes: ${response.statusCode}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Erreur de connexion: $e';
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Filtrer les commandes selon le statut sélectionné
//   List<Commande> get _filteredCommandes {
//     if (_selectedFilterIndex == 0) return _commandes;
//
//     // Convertir les statuts pour qu'ils correspondent
//     Map<String, List<String>> statusMap = {
//       'confirmés': ['confirmé', 'confirme', 'confirmes'],
//       'en attente': ['en attente', 'en_attente', 'attente'],
//       'terminés': ['terminé', 'termine', 'termines'],
//       'annulés': ['annulé', 'annule', 'annules'],
//     };
//
//     final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
//     final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];
//
//     return _commandes.where((commande) {
//       final normalizedStatus = commande.statut.toLowerCase().trim();
//       return matchingStatuses.contains(normalizedStatus);
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentNavIndex,
//         onTap: _onNavIndexChanged,
//       ),
//       body: _buildBody(),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: Colors.purple.shade400,
//               strokeWidth: 3,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Chargement de vos commandes...',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const Icon(
//                 Icons.error_outline_rounded,
//                 size: 60,
//                 color: Colors.redAccent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Oups! Quelque chose s\'est mal passé',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerCommandes,
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_commandes.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: Colors.purple.shade50,
//                 borderRadius: BorderRadius.circular(100),
//               ),
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 size: 80,
//                 color: Colors.purple.shade300,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Aucune commande pour le moment',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 'Découvrez nos salons et faites votre première réservation',
//                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pushNamed('/catalogue');
//               },
//               icon: const Icon(Icons.storefront_rounded),
//               label: const Text('Découvrir les salons'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: [
//         // Filtres en haut
//         Container(
//           height: 50,
//           margin: const EdgeInsets.symmetric(vertical: 16),
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: _filters.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedFilterIndex = index;
//                   });
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: _selectedFilterIndex == index
//                         ? Colors.purple.shade400
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     _filters[index],
//                     style: TextStyle(
//                       color: _selectedFilterIndex == index
//                           ? Colors.white
//                           : Colors.grey.shade700,
//                       fontWeight: _selectedFilterIndex == index
//                           ? FontWeight.bold
//                           : FontWeight.normal,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//
//         // Liste des commandes
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _chargerCommandes,
//             color: Colors.purple.shade400,
//             child: _filteredCommandes.isEmpty
//                 ? Center(
//               child: Text(
//                 'Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: 16,
//                 ),
//               ),
//             )
//                 : ListView.builder(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               itemCount: _filteredCommandes.length,
//               itemBuilder: (context, index) {
//                 return CommandeCard(commande: _filteredCommandes[index]);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class CommandeCard extends StatefulWidget {
//   final Commande commande;
//
//   const CommandeCard({super.key, required this.commande});
//
//   @override
//   State<CommandeCard> createState() => _CommandeCardState();
// }
//
// class _CommandeCardState extends State<CommandeCard> {
//   final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
//   final DateFormat timeFormatter = DateFormat('HH:mm');
//   Timer? _timer;
//   String _countdownText = "";
//
//   @override
//   void initState() {
//     super.initState();
//     // Démarrer le compte à rebours seulement si la date est dans le futur
//     // et que le statut n'est pas "Annulé" ou "Terminé"
//     if (widget.commande.dateHeure.isAfter(DateTime.now()) &&
//         !["annulé", "terminé"].contains(widget.commande.statut.toLowerCase())) {
//       _startCountdown();
//     } else if (widget.commande.dateHeure.isBefore(DateTime.now())) {
//       _countdownText = "Rendez-vous passé";
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   void _startCountdown() {
//     // Mettre à jour immédiatement puis toutes les secondes
//     _updateCountdown();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _updateCountdown();
//     });
//   }
//
//   void _updateCountdown() {
//     final now = DateTime.now();
//     final difference = widget.commande.dateHeure.difference(now);
//
//     if (difference.isNegative) {
//       setState(() {
//         _countdownText = "Rendez-vous commencé";
//       });
//       _timer?.cancel();
//       return;
//     }
//
//     final days = difference.inDays;
//     final hours = difference.inHours % 24;
//     final minutes = difference.inMinutes % 60;
//     final seconds = difference.inSeconds % 60;
//
//     setState(() {
//       if (days > 0) {
//         _countdownText = "$days j ${hours.toString().padLeft(2, '0')}h";
//       } else if (hours > 0) {
//         _countdownText = "${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m";
//       } else {
//         _countdownText = "${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s";
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {
//             _showCommandeDetails(context);
//           },
//           child: Column(
//             children: [
//               // Barre d'état supérieure
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(widget.commande.statut),
//                 ),
//               ),
//
//               // En-tête de la commande
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     // Avatar du salon (cercle avec première lettre)
//                     Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         color: Colors.purple.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       alignment: Alignment.center,
//                       child: Text(
//                         widget.commande.nomSalon.isNotEmpty ? widget.commande.nomSalon[0].toUpperCase() : 'S',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//
//                     // Informations principales
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.commande.nomSalon,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(
//                                   Icons.event,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 dateFormatter.format(widget.commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Icon(
//                                   Icons.access_time,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 timeFormatter.format(widget.commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Indicateur de statut
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(widget.commande.statut).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         widget.commande.statut,
//                         style: TextStyle(
//                           color: _getStatusColor(widget.commande.statut),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Compte à rebours
//               if (_countdownText.isNotEmpty)
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.purple.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.purple.shade100),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.timer_outlined,
//                         size: 18,
//                         color: Colors.purple.shade700,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         _countdownText,
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.purple.shade700,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//               const Divider(height: 1),
//
//               // Services (simplifié)
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${widget.commande.services.length} service${widget.commande.services.length > 1 ? "s" : ""}',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           if (widget.commande.services.isNotEmpty)
//                             Text(
//                               widget.commande.services.map((s) => s.intituleService).join(', '),
//                               style: const TextStyle(
//                                 fontSize: 15,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '${widget.commande.montantPaye.toStringAsFixed(2)} €',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.purple,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Actions
//               Container(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Bouton de détails
//                     Expanded(
//                       child: TextButton.icon(
//                         onPressed: () {
//                           _showCommandeDetails(context);
//                         },
//                         icon: const Icon(Icons.visibility),
//                         label: const Text('Détails'),
//                         style: TextButton.styleFrom(
//                           foregroundColor: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//
//                     // Bouton de reçu si disponible
//                     if (widget.commande.receiptUrl != null && widget.commande.receiptUrl!.isNotEmpty)
//                       Expanded(
//                         child: TextButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: widget.commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_rounded),
//                           label: const Text('Reçu'),
//                           style: TextButton.styleFrom(
//                             foregroundColor: Colors.purple.shade700,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showCommandeDetails(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.85,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//         ),
//         child: Column(
//           children: [
//             // Barre d'indication
//             Container(
//               width: 40,
//               height: 5,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(5),
//               ),
//             ),
//
//             // Titre
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.purple.shade100,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                         Icons.receipt_long_rounded,
//                         color: Colors.purple,
//                         size: 24
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Détails de commande',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade800,
//                           ),
//                         ),
//                         Text(
//                           'Commande #${widget.commande.idRendezVous}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(widget.commande.statut).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       widget.commande.statut,
//                       style: TextStyle(
//                         color: _getStatusColor(widget.commande.statut),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Divider(),
//
//             // Compte à rebours dans les détails
//             if (_countdownText.isNotEmpty)
//               Container(
//                 margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.purple.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.purple.shade100),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.timer_outlined,
//                       size: 22,
//                       color: Colors.purple.shade700,
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       _countdownText,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.purple.shade700,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//             // Contenu détaillé dans un ScrollView
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Informations sur le salon
//                     _buildDetailSection(
//                       'Salon',
//                       Icons.store_rounded,
//                       [
//                         widget.commande.nomSalon,
//                         '${widget.commande.prenomCoiffeuse} ${widget.commande.nomCoiffeuse}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Informations sur la date
//                     _buildDetailSection(
//                       'Date & Heure',
//                       Icons.event_rounded,
//                       [
//                         '${dateFormatter.format(widget.commande.dateHeure)} à ${timeFormatter.format(widget.commande.dateHeure)}',
//                         'Durée: ${widget.commande.dureeTotale} minutes',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Services commandés
//                     _buildServicesSection(),
//
//                     const SizedBox(height: 20),
//
//                     // Paiement
//                     _buildDetailSection(
//                       'Paiement',
//                       Icons.payment_rounded,
//                       [
//                         '${widget.commande.montantPaye.toStringAsFixed(2)} € - ${widget.commande.methodePaiement}',
//                         'Payé le ${dateFormatter.format(widget.commande.datePaiement)}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     // Bouton pour accéder au reçu si disponible
//                     if (widget.commande.receiptUrl != null && widget.commande.receiptUrl!.isNotEmpty)
//                       Center(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: widget.commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_long),
//                           label: const Text('Voir le reçu'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.purple.shade400,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailSection(String title, IconData icon, List<String> details) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ...details.map((detail) => Padding(
//           padding: const EdgeInsets.only(left: 26, bottom: 4),
//           child: Text(
//             detail,
//             style: TextStyle(
//               fontSize: 15,
//               color: Colors.grey.shade700,
//             ),
//           ),
//         )).toList(),
//       ],
//     );
//   }
//
//   Widget _buildServicesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.content_cut_rounded, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             const Text(
//               'Services',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         ...widget.commande.services.map((service) => Container(
//           margin: const EdgeInsets.only(bottom: 10),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   service.intituleService,
//                   style: const TextStyle(fontSize: 15),
//                 ),
//               ),
//               Text(
//                 '${service.prixApplique.toStringAsFixed(2)} €',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Colors.purple.shade700,
//                 ),
//               ),
//             ],
//           ),
//         )).toList(),
//
//         // Total
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//           decoration: BoxDecoration(
//             color: Colors.purple.shade50,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Total',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 '${widget.commande.montantPaye.toStringAsFixed(2)} €',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.purple,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmé':
//         return Colors.green;
//       case 'en attente':
//         return Colors.orange;
//       case 'annulé':
//         return Colors.red;
//       case 'terminé':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }
// }







// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/mes_commandes/sub_pages/recu_page.dart';
// import 'package:intl/intl.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../models/mes_commandes.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/custom_app_bar.dart';
//
// class MesCommandesPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MesCommandesPage({super.key, required this.currentUser});
//
//   @override
//   State<MesCommandesPage> createState() => _MesCommandesPageState();
// }
//
// class _MesCommandesPageState extends State<MesCommandesPage> {
//   bool _isLoading = true;
//   List<Commande> _commandes = [];
//   String? _error;
//   int _selectedFilterIndex = 0;
//   final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
//   int _currentNavIndex = 0;
//
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerCommandes();
//     _currentNavIndex = 2;
//   }
//
//   // La méthode pour gérer les changements d'onglet
//   void _onNavIndexChanged(int index) {
//     setState(() {
//       _currentNavIndex = index;
//     });
//   }
//
//   Future<void> _chargerCommandes() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//       final response = await http.get(
//         Uri.parse('$_baseUrl/mes-commandes/${widget.currentUser.idTblUser}/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
//         setState(() {
//           _commandes = Commande.fromJsonList(jsonList);
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _error = 'Erreur lors du chargement des commandes: ${response.statusCode}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Erreur de connexion: $e';
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Filtrer les commandes selon le statut sélectionné
//   List<Commande> get _filteredCommandes {
//     if (_selectedFilterIndex == 0) return _commandes;
//
//     // Convertir les statuts pour qu'ils correspondent
//     Map<String, List<String>> statusMap = {
//       'confirmés': ['confirmé', 'confirme', 'confirmes'],
//       'en attente': ['en attente', 'en_attente', 'attente'],
//       'terminés': ['terminé', 'termine', 'termines'],
//       'annulés': ['annulé', 'annule', 'annules'],
//     };
//
//     final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
//     final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];
//
//     return _commandes.where((commande) {
//       final normalizedStatus = commande.statut.toLowerCase().trim();
//       return matchingStatuses.contains(normalizedStatus);
//     }).toList();
//   }
//   // List<Commande> get _filteredCommandes {
//   //   if (_selectedFilterIndex == 0) return _commandes;
//   //
//   //   final String filterStatus = _filters[_selectedFilterIndex].toLowerCase();
//   //   return _commandes.where((commande) =>
//   //   commande.statut.toLowerCase() == filterStatus).toList();
//   // }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentNavIndex,
//         onTap: _onNavIndexChanged,
//       ),
//
//       // AppBar(
//       //   title: const Text('Mes Commandes',
//       //       style: TextStyle(
//       //         fontWeight: FontWeight.bold,
//       //         fontSize: 22,
//       //       )
//       //   ),
//       //   centerTitle: true,
//       //   backgroundColor: Colors.purple.shade400,
//       //   elevation: 0,
//       //   actions: [
//       //     IconButton(
//       //       icon: const Icon(Icons.refresh_rounded),
//       //       onPressed: _chargerCommandes,
//       //     ),
//       //   ],
//       // ),
//       body: _buildBody(),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: Colors.purple.shade400,
//               strokeWidth: 3,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Chargement de vos commandes...',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const Icon(
//                 Icons.error_outline_rounded,
//                 size: 60,
//                 color: Colors.redAccent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Oups! Quelque chose s\'est mal passé',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerCommandes,
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_commandes.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: Colors.purple.shade50,
//                 borderRadius: BorderRadius.circular(100),
//               ),
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 size: 80,
//                 color: Colors.purple.shade300,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Aucune commande pour le moment',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 'Découvrez nos salons et faites votre première réservation',
//                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pushNamed('/catalogue');
//               },
//               icon: const Icon(Icons.storefront_rounded),
//               label: const Text('Découvrir les salons'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple.shade400,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: [
//         // Filtres en haut
//         Container(
//           height: 50,
//           margin: const EdgeInsets.symmetric(vertical: 16),
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: _filters.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedFilterIndex = index;
//                   });
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: _selectedFilterIndex == index
//                         ? Colors.purple.shade400
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     _filters[index],
//                     style: TextStyle(
//                       color: _selectedFilterIndex == index
//                           ? Colors.white
//                           : Colors.grey.shade700,
//                       fontWeight: _selectedFilterIndex == index
//                           ? FontWeight.bold
//                           : FontWeight.normal,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//
//         // Liste des commandes
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _chargerCommandes,
//             color: Colors.purple.shade400,
//             child: _filteredCommandes.isEmpty
//                 ? Center(
//               child: Text(
//                 'Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: 16,
//                 ),
//               ),
//             )
//                 : ListView.builder(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               itemCount: _filteredCommandes.length,
//               itemBuilder: (context, index) {
//                 return CommandeCard(commande: _filteredCommandes[index]);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class CommandeCard extends StatelessWidget {
//   final Commande commande;
//   final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
//   final DateFormat timeFormatter = DateFormat('HH:mm');
//
//   CommandeCard({super.key, required this.commande});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {
//             _showCommandeDetails(context);
//           },
//           child: Column(
//             children: [
//               // Barre d'état supérieure
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(commande.statut),
//                 ),
//               ),
//
//               // En-tête de la commande
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     // Avatar du salon (cercle avec première lettre)
//                     Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         color: Colors.purple.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       alignment: Alignment.center,
//                       child: Text(
//                         commande.nomSalon.isNotEmpty ? commande.nomSalon[0].toUpperCase() : 'S',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//
//                     // Informations principales
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             commande.nomSalon,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(
//                                   Icons.event,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 dateFormatter.format(commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Icon(
//                                   Icons.access_time,
//                                   size: 16,
//                                   color: Colors.grey.shade600
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 timeFormatter.format(commande.dateHeure),
//                                 style: TextStyle(
//                                   color: Colors.grey.shade600,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Indicateur de statut
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(commande.statut).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         commande.statut,
//                         style: TextStyle(
//                           color: _getStatusColor(commande.statut),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const Divider(height: 1),
//
//               // Services (simplifié)
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${commande.services.length} service${commande.services.length > 1 ? "s" : ""}',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           if (commande.services.isNotEmpty)
//                             Text(
//                               commande.services.map((s) => s.intituleService).join(', '),
//                               style: const TextStyle(
//                                 fontSize: 15,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '${commande.montantPaye.toStringAsFixed(2)} €',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.purple,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Actions
//               Container(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Bouton de détails
//                     Expanded(
//                       child: TextButton.icon(
//                         onPressed: () {
//                           _showCommandeDetails(context);
//                         },
//                         icon: const Icon(Icons.visibility),
//                         label: const Text('Détails'),
//                         style: TextButton.styleFrom(
//                           foregroundColor: Colors.purple.shade700,
//                         ),
//                       ),
//                     ),
//
//                     // Bouton de reçu si disponible
//                     if (commande.receiptUrl != null && commande.receiptUrl!.isNotEmpty)
//                       Expanded(
//                         child: TextButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_rounded),
//                           label: const Text('Reçu'),
//                           style: TextButton.styleFrom(
//                             foregroundColor: Colors.purple.shade700,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showCommandeDetails(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.85,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//         ),
//         child: Column(
//           children: [
//             // Barre d'indication
//             Container(
//               width: 40,
//               height: 5,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(5),
//               ),
//             ),
//
//             // Titre
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.purple.shade100,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                         Icons.receipt_long_rounded,
//                         color: Colors.purple,
//                         size: 24
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Détails de commande',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade800,
//                           ),
//                         ),
//                         Text(
//                           'Commande #${commande.idRendezVous}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(commande.statut).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       commande.statut,
//                       style: TextStyle(
//                         color: _getStatusColor(commande.statut),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Divider(),
//
//             // Contenu détaillé dans un ScrollView
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Informations sur le salon
//                     _buildDetailSection(
//                       'Salon',
//                       Icons.store_rounded,
//                       [
//                         commande.nomSalon,
//                         '${commande.prenomCoiffeuse} ${commande.nomCoiffeuse}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Informations sur la date
//                     _buildDetailSection(
//                       'Date & Heure',
//                       Icons.event_rounded,
//                       [
//                         '${dateFormatter.format(commande.dateHeure)} à ${timeFormatter.format(commande.dateHeure)}',
//                         'Durée: ${commande.dureeTotale} minutes',
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Services commandés
//                     _buildServicesSection(),
//
//                     const SizedBox(height: 20),
//
//                     // Paiement
//                     _buildDetailSection(
//                       'Paiement',
//                       Icons.payment_rounded,
//                       [
//                         '${commande.montantPaye.toStringAsFixed(2)} € - ${commande.methodePaiement}',
//                         'Payé le ${dateFormatter.format(commande.datePaiement)}',
//                       ],
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     // Bouton pour accéder au reçu si disponible
//                     if (commande.receiptUrl != null && commande.receiptUrl!.isNotEmpty)
//                       Center(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ReceiptPage(receiptUrl: commande.receiptUrl!),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.receipt_long),
//                           label: const Text('Voir le reçu'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.purple.shade400,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailSection(String title, IconData icon, List<String> details) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ...details.map((detail) => Padding(
//           padding: const EdgeInsets.only(left: 26, bottom: 4),
//           child: Text(
//             detail,
//             style: TextStyle(
//               fontSize: 15,
//               color: Colors.grey.shade700,
//             ),
//           ),
//         )).toList(),
//       ],
//     );
//   }
//
//   Widget _buildServicesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.content_cut_rounded, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             const Text(
//               'Services',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         ...commande.services.map((service) => Container(
//           margin: const EdgeInsets.only(bottom: 10),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   service.intituleService,
//                   style: const TextStyle(fontSize: 15),
//                 ),
//               ),
//               Text(
//                 '${service.prixApplique.toStringAsFixed(2)} €',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Colors.purple.shade700,
//                 ),
//               ),
//             ],
//           ),
//         )).toList(),
//
//         // Total
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//           decoration: BoxDecoration(
//             color: Colors.purple.shade50,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Total',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 '${commande.montantPaye.toStringAsFixed(2)} €',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.purple,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmé':
//         return Colors.green;
//       case 'en attente':
//         return Colors.orange;
//       case 'annulé':
//         return Colors.red;
//       case 'terminé':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }
// }