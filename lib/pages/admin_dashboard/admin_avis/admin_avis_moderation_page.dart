// pages/admin/admin_avis_moderation_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/admin_avis.dart';
import '../../../models/current_user.dart';
import 'admin_avis_services/admin_avis_service.dart';

class AdminAvisModerationPage extends StatefulWidget {
  final CurrentUser currentUser;

  const AdminAvisModerationPage({
    super.key,
    required this.currentUser,
  });

  @override
  _AdminAvisModerationPageState createState() => _AdminAvisModerationPageState();
}

class _AdminAvisModerationPageState extends State<AdminAvisModerationPage> {
  final primaryViolet = const Color(0xFF7B61FF);
  final lightBackground = const Color(0xFFF7F7F9);

  List<AdminAvis> _avis = [];
  AdminPagination? _pagination;
  AdminAvisFilters _filters = AdminAvisFilters();
  bool _isLoading = true;
  String? _errorMessage;

  // Contrôleurs pour la recherche
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatut;
  int? _selectedNote;

  @override
  void initState() {
    super.initState();
    _chargerAvis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 🔄 Charger les avis avec filtres
  Future<void> _chargerAvis({bool reset = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (reset) {
          _filters = _filters.copyWith(page: 1);
        }
      });

      final response = await AdminAvisService.getAvisAdmin(
        context: context,
        filters: _filters,
      );

      if (mounted) {
        setState(() {
          _avis = response.avis;
          _pagination = response.pagination;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur chargement avis admin: $e");
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 🔍 Appliquer les filtres
  void _appliquerFiltres() {
    setState(() {
      _filters = _filters.copyWith(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        statut: _selectedStatut,
        note: _selectedNote,
        page: 1, // Reset à la page 1
      );
    });
    _chargerAvis();
  }

  /// 🔄 Réinitialiser les filtres
  void _reinitialiserFiltres() {
    setState(() {
      _searchController.clear();
      _selectedStatut = null;
      _selectedNote = null;
      _filters = AdminAvisFilters();
    });
    _chargerAvis();
  }

  /// 🗑️ Supprimer un avis
  Future<void> _supprimerAvis(AdminAvis avis) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Supprimer l\'avis'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer définitivement cet avis ?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client: ${avis.client.nomComplet}', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Salon: ${avis.salon.nomSalon}'),
                  Text('Note: ${avis.etoilesVisuelles}'),
                  SizedBox(height: 4),
                  Text(avis.commentaireApercu, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Cette action est irréversible.',
              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await AdminAvisService.supprimerAvisAdmin(
          context: context,
          avisId: avis.id,
        );

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message), backgroundColor: Colors.green),
          );
          _chargerAvis(); // Recharger la liste
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 👁️ Masquer/Démasquer un avis
  Future<void> _toggleVisibiliteAvis(AdminAvis avis) async {
    final action = avis.estVisible ? 'masquer' : 'visible';
    final actionText = avis.estVisible ? 'masquer' : 'rendre visible';

    try {
      final result = await AdminAvisService.modererAvisAdmin(
        context: context,
        avisId: avis.id,
        action: action,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avis $actionText avec succès'), backgroundColor: Colors.green),
        );
        _chargerAvis(); // Recharger la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// 📄 Changer de page
  void _changerPage(int nouvellePage) {
    setState(() {
      _filters = _filters.copyWith(page: nouvellePage);
    });
    _chargerAvis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryViolet,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Modération des Avis",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _chargerAvis(reset: true),
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de filtres
          _buildFilterBar(),

          // Liste des avis
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryViolet))
                : _errorMessage != null
                ? _buildErrorState()
                : _avis.isEmpty
                ? _buildEmptyState()
                : _buildAvisList(),
          ),

          // Pagination
          if (_pagination != null && _pagination!.totalPages > 1)
            _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par commentaire, client ou salon...',
              prefixIcon: Icon(Icons.search, color: primaryViolet),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _appliquerFiltres();
                },
                icon: Icon(Icons.clear),
              )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryViolet, width: 2),
              ),
            ),
            onSubmitted: (_) => _appliquerFiltres(),
          ),

          const SizedBox(height: 12),

          // Filtres rapides
          Row(
            children: [
              // Filtre statut
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatut,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Tous')),
                    DropdownMenuItem(value: 'visible', child: Text('Visible')),
                    DropdownMenuItem(value: 'masque', child: Text('Masqué')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatut = value);
                    _appliquerFiltres();
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Filtre note
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedNote,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Toutes')),
                    ...List.generate(5, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1} ⭐'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedNote = value);
                    _appliquerFiltres();
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Bouton reset
              IconButton(
                onPressed: _reinitialiserFiltres,
                icon: Icon(Icons.filter_alt_off, color: primaryViolet),
                tooltip: 'Réinitialiser',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvisList() {
    return RefreshIndicator(
      onRefresh: () => _chargerAvis(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _avis.length,
        itemBuilder: (context, index) => _buildAvisCard(_avis[index]),
      ),
    );
  }

  Widget _buildAvisCard(AdminAvis avis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec client et salon
            Row(
              children: [
                // Photo client
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avis.client.photoUrl.isNotEmpty
                      ? NetworkImage(avis.client.photoUrl)
                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avis.client.nomComplet,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        avis.client.emailMasque,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '→ ${avis.salon.nomSalon}',
                        style: TextStyle(color: primaryViolet, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Statut badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: avis.estVisible ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    avis.statutLibelle,
                    style: TextStyle(
                      color: avis.estVisible ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Note et date
            Row(
              children: [
                Text(avis.etoilesVisuelles, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('${avis.note}/5', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(avis.dateFormatee, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),

            const SizedBox(height: 12),

            // Commentaire
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                avis.commentaire,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),

            const SizedBox(height: 16),

            // Actions admin
            Row(
              children: [
                // Masquer/Afficher
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleVisibiliteAvis(avis),
                    icon: Icon(avis.estVisible ? Icons.visibility_off : Icons.visibility),
                    label: Text(avis.estVisible ? 'Masquer' : 'Afficher'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: avis.estVisible ? Colors.orange : Colors.green,
                      side: BorderSide(color: avis.estVisible ? Colors.orange : Colors.green),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Supprimer
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _supprimerAvis(avis),
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Info technique
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                'ID: ${avis.id} | Client: ${avis.client.idTblUser} | RDV: ${avis.rdvId ?? 'N/A'}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_pagination == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Column(
        children: [
          // Info pagination
          Text(
            _pagination!.texteInfo,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),

          // Boutons pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Première page
              IconButton(
                onPressed: _pagination!.page > 1 ? () => _changerPage(1) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'Première page',
              ),

              // Page précédente
              IconButton(
                onPressed: _pagination!.hasPrevious ? () => _changerPage(_pagination!.page - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Page précédente',
              ),

              // Numéro de page actuel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_pagination!.page}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryViolet,
                    fontSize: 16,
                  ),
                ),
              ),

              // Page suivante
              IconButton(
                onPressed: _pagination!.hasNext ? () => _changerPage(_pagination!.page + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Page suivante',
              ),

              // Dernière page
              IconButton(
                onPressed: _pagination!.page < _pagination!.totalPages
                    ? () => _changerPage(_pagination!.totalPages)
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Dernière page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _filters.hasActiveFilters ? 'Aucun avis trouvé' : 'Aucun avis à modérer',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filters.hasActiveFilters
                  ? 'Essayez de modifier vos filtres'
                  : 'Tous les avis sont déjà modérés !',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (_filters.hasActiveFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _reinitialiserFiltres,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Réinitialiser les filtres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryViolet,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _chargerAvis(reset: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryViolet,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}