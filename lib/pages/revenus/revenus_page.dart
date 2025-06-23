// lib/pages/revenus_page.dart

import 'package:flutter/material.dart';
import 'package:hairbnb/pages/revenus/revenus_widgets/revenus_widgets.dart';
import 'package:provider/provider.dart';

import '../../models/revenus_model.dart';
import '../../services/providers/revenus_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';

class RevenusPage extends StatefulWidget {
  const RevenusPage({super.key});

  @override
  State<RevenusPage> createState() => _RevenusPageState();
}

class _RevenusPageState extends State<RevenusPage> {
  int _currentIndex = 0; // Index pour la navbar

  @override
  void initState() {
    super.initState();
    // Charger les revenus au démarrage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RevenusProvider>(context, listen: false).loadRevenus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AJOUT : CustomAppBar
      appBar: const CustomAppBar(),

      body: RefreshIndicator(
        onRefresh: () => Provider.of<RevenusProvider>(context, listen: false).refresh(),
        child: Consumer<RevenusProvider>(
          builder: (context, revenusProvider, child) {
            // État de chargement initial
            if (revenusProvider.isLoading && !revenusProvider.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des revenus...'),
                  ],
                ),
              );
            }

            // État d'erreur
            if (revenusProvider.hasError) {
              return _buildErrorState(revenusProvider.error!);
            }

            // État avec données
            if (revenusProvider.hasData) {
              return _buildRevenusContent(revenusProvider);
            }

            // État vide (pas de données)
            return _buildEmptyState();
          },
        ),
      ),

      // ✅ AJOUT : BottomNavBar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// Interface principale avec les données de revenus
  Widget _buildRevenusContent(RevenusProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ AJOUT : Titre de la page (remplace l'ancienne AppBar)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.euro_symbol,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mes Revenus',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Suivi de vos gains et statistiques',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton refresh intégré
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: provider.isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.refresh, color: Colors.white),
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.refresh(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sélecteur de période
          _buildPeriodeSelector(provider),
          const SizedBox(height: 20),

          // Résumé des revenus
          RevenusResumeCard(resume: provider.revenus!.resume),
          const SizedBox(height: 20),

          // Statistiques
          RevenusStatistiquesCard(statistiques: provider.revenus!.statistiques),
          const SizedBox(height: 20),

          // Liste des rendez-vous
          RevenusRdvList(rdvList: provider.revenus!.detailsRdv),

          // ✅ AJOUT : Espace en bas pour éviter que le contenu soit masqué par la navbar
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Sélecteur de période avec boutons
  Widget _buildPeriodeSelector(RevenusProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Période: ${provider.periodeFormatee}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (provider.isLoading)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Boutons de période
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildPeriodeButton('Aujourd\'hui', PeriodeRevenu.jour, provider),
                _buildPeriodeButton('Semaine', PeriodeRevenu.semaine, provider),
                _buildPeriodeButton('Mois', PeriodeRevenu.mois, provider),
                _buildPeriodeButton('Année', PeriodeRevenu.annee, provider),
                _buildCustomPeriodeButton(provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton pour une période prédéfinie
  Widget _buildPeriodeButton(String label, PeriodeRevenu periode, RevenusProvider provider) {
    final isSelected = provider.periodeActuelle == periode;

    return ElevatedButton(
      onPressed: provider.isLoading
          ? null
          : () => provider.loadRevenusParPeriode(periode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// Bouton pour période personnalisée
  Widget _buildCustomPeriodeButton(RevenusProvider provider) {
    final isSelected = provider.periodeActuelle == PeriodeRevenu.custom;

    return ElevatedButton.icon(
      onPressed: provider.isLoading ? null : () => _showDateRangePicker(provider),
      icon: Icon(
        Icons.date_range,
        size: 18,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      label: const Text('Personnalisé'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Sélecteur de dates personnalisées
  Future<void> _showDateRangePicker(RevenusProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: provider.dateDebut != null && provider.dateFin != null
          ? DateTimeRange(start: provider.dateDebut!, end: provider.dateFin!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.loadRevenusPersonnalises(
        dateDebut: picked.start,
        dateFin: picked.end,
      );
    }
  }

  /// État d'erreur
  Widget _buildErrorState(RevenusErrorModel error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error.error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<RevenusProvider>(context, listen: false).refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// État vide (aucune donnée)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun revenu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucun paiement trouvé pour cette période.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<RevenusProvider>(context, listen: false).refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}







// // lib/pages/revenus_page.dart
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/revenus/revenus_widgets/revenus_widgets.dart';
// import 'package:provider/provider.dart';
//
// import '../../models/revenus_model.dart';
// import '../../services/providers/revenus_provider.dart';
//
// class RevenusPage extends StatefulWidget {
//   const RevenusPage({super.key});
//
//   @override
//   State<RevenusPage> createState() => _RevenusPageState();
// }
//
// class _RevenusPageState extends State<RevenusPage> {
//   @override
//   void initState() {
//     super.initState();
//     // Charger les revenus au démarrage de la page
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<RevenusProvider>(context, listen: false).loadRevenus();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mes Revenus'),
//         backgroundColor: Colors.blue[600],
//         foregroundColor: Colors.white,
//         actions: [
//           // Bouton refresh
//           Consumer<RevenusProvider>(
//             builder: (context, revenusProvider, child) {
//               return IconButton(
//                 icon: revenusProvider.isLoading
//                     ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//                     : const Icon(Icons.refresh),
//                 onPressed: revenusProvider.isLoading
//                     ? null
//                     : () => revenusProvider.refresh(),
//               );
//             },
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: () => Provider.of<RevenusProvider>(context, listen: false).refresh(),
//         child: Consumer<RevenusProvider>(
//           builder: (context, revenusProvider, child) {
//             // État de chargement initial
//             if (revenusProvider.isLoading && !revenusProvider.hasData) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text('Chargement des revenus...'),
//                   ],
//                 ),
//               );
//             }
//
//             // État d'erreur
//             if (revenusProvider.hasError) {
//               return _buildErrorState(revenusProvider.error!);
//             }
//
//             // État avec données
//             if (revenusProvider.hasData) {
//               return _buildRevenusContent(revenusProvider);
//             }
//
//             // État vide (pas de données)
//             return _buildEmptyState();
//           },
//         ),
//       ),
//     );
//   }
//
//   /// Interface principale avec les données de revenus
//   Widget _buildRevenusContent(RevenusProvider provider) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Sélecteur de période
//           _buildPeriodeSelector(provider),
//           const SizedBox(height: 20),
//
//           // Résumé des revenus
//           RevenusResumeCard(resume: provider.revenus!.resume),
//           const SizedBox(height: 20),
//
//           // Statistiques
//           RevenusStatistiquesCard(statistiques: provider.revenus!.statistiques),
//           const SizedBox(height: 20),
//
//           // Liste des rendez-vous
//           RevenusRdvList(rdvList: provider.revenus!.detailsRdv),
//         ],
//       ),
//     );
//   }
//
//   /// Sélecteur de période avec boutons
//   Widget _buildPeriodeSelector(RevenusProvider provider) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Période: ${provider.periodeFormatee}',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (provider.isLoading)
//                   const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//             // Boutons de période
//             Wrap(
//               spacing: 8.0,
//               children: [
//                 _buildPeriodeButton('Aujourd\'hui', PeriodeRevenu.jour, provider),
//                 _buildPeriodeButton('Semaine', PeriodeRevenu.semaine, provider),
//                 _buildPeriodeButton('Mois', PeriodeRevenu.mois, provider),
//                 _buildPeriodeButton('Année', PeriodeRevenu.annee, provider),
//                 _buildCustomPeriodeButton(provider),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Bouton pour une période prédéfinie
//   Widget _buildPeriodeButton(String label, PeriodeRevenu periode, RevenusProvider provider) {
//     final isSelected = provider.periodeActuelle == periode;
//
//     return ElevatedButton(
//       onPressed: provider.isLoading
//           ? null
//           : () => provider.loadRevenusParPeriode(periode),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[200],
//         foregroundColor: isSelected ? Colors.white : Colors.black87,
//         elevation: isSelected ? 2 : 0,
//       ),
//       child: Text(label),
//     );
//   }
//
//   /// Bouton pour période personnalisée
//   Widget _buildCustomPeriodeButton(RevenusProvider provider) {
//     final isSelected = provider.periodeActuelle == PeriodeRevenu.custom;
//
//     return ElevatedButton(
//       onPressed: provider.isLoading ? null : () => _showDateRangePicker(provider),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[200],
//         foregroundColor: isSelected ? Colors.white : Colors.black87,
//         elevation: isSelected ? 2 : 0,
//       ),
//       child: const Text('Personnalisé'),
//     );
//   }
//
//   /// Sélecteur de dates personnalisées
//   Future<void> _showDateRangePicker(RevenusProvider provider) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       initialDateRange: provider.dateDebut != null && provider.dateFin != null
//           ? DateTimeRange(start: provider.dateDebut!, end: provider.dateFin!)
//           : null,
//     );
//
//     if (picked != null) {
//       provider.loadRevenusPersonnalises(
//         dateDebut: picked.start,
//         dateFin: picked.end,
//       );
//     }
//   }
//
//   /// État d'erreur
//   Widget _buildErrorState(RevenusErrorModel error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Colors.red,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Erreur',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               error.error,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Provider.of<RevenusProvider>(context, listen: false).refresh();
//               },
//               child: const Text('Réessayer'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// État vide (aucune donnée)
//   Widget _buildEmptyState() {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.receipt_long_outlined,
//               size: 64,
//               color: Colors.grey,
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Aucun revenu',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Aucun paiement trouvé pour cette période.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }