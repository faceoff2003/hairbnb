import 'package:flutter/material.dart';
import 'package:hairbnb/pages/admin_dashboard/admin_users/widgets/user_card.dart';
import 'package:hairbnb/pages/admin_dashboard/admin_users/widgets/user_filter_chip.dart';
import '../../../models/admin_user.dart';
import '../../../models/current_user.dart';
import 'admin_user_services/admin_user_service.dart';

class AdminUserManagementPage extends StatefulWidget {
  final CurrentUser currentUser;

  const AdminUserManagementPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final primaryViolet = const Color(0xFF7B61FF);
  final lightBackground = const Color(0xFFF7F7F9);

  List<AdminUser> _allUsers = [];
  List<AdminUser> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, inactive, admin, user

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await AdminUserService.fetchAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
      });
    } catch (e) {
      _showErrorSnackBar('Erreur de chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<AdminUser> filtered = _allUsers;

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) =>
      user.nomComplet.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filtre par statut/rôle
    switch (_selectedFilter) {
      case 'active':
        filtered = filtered.where((user) => user.isActive).toList();
        break;
      case 'inactive':
        filtered = filtered.where((user) => !user.isActive).toList();
        break;
      case 'admin':
        filtered = filtered.where((user) => user.isAdmin).toList();
        break;
      case 'user':
        filtered = filtered.where((user) => !user.isAdmin).toList();
        break;
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilters();
  }

  Future<void> _onUserAction(AdminUser user, String action) async {
    try {
      String message;
      switch (action) {
        case 'toggle_status':
          if (user.isActive) {
            message = await AdminUserService.deactivateUser(user.idTblUser);
          } else {
            message = await AdminUserService.activateUser(user.idTblUser);
          }
          break;
        case 'toggle_role':
          final newRoleId = user.isAdmin ? 1 : 2; // 1=user, 2=admin
          message = await AdminUserService.changeUserRole(user.idTblUser, newRoleId);
          break;
        default:
          return;
      }

      _showSuccessSnackBar(message);
      await _loadUsers(); // Recharger la liste
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

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
          "Gestion des Utilisateurs",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec statistiques
          _buildHeader(),

          // Barre de recherche et filtres
          _buildSearchAndFilters(),

          // Liste des utilisateurs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? _buildEmptyState()
                : _buildUsersList(isWideScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = _allUsers.where((u) => u.isActive).length;
    final adminCount = _allUsers.where((u) => u.isAdmin).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryViolet, primaryViolet.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total', '${_allUsers.length}', Icons.people),
          _buildStatCard('Actifs', '$activeCount', Icons.check_circle),
          _buildStatCard('Admins', '$adminCount', Icons.admin_panel_settings),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou email...',
              prefixIcon: Icon(Icons.search, color: primaryViolet),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                UserFilterChip(
                  label: 'Tous',
                  isSelected: _selectedFilter == 'all',
                  onSelected: () => _onFilterChanged('all'),
                ),
                UserFilterChip(
                  label: 'Actifs',
                  isSelected: _selectedFilter == 'active',
                  onSelected: () => _onFilterChanged('active'),
                ),
                UserFilterChip(
                  label: 'Inactifs',
                  isSelected: _selectedFilter == 'inactive',
                  onSelected: () => _onFilterChanged('inactive'),
                ),
                UserFilterChip(
                  label: 'Admins',
                  isSelected: _selectedFilter == 'admin',
                  onSelected: () => _onFilterChanged('admin'),
                ),
                UserFilterChip(
                  label: 'Utilisateurs',
                  isSelected: _selectedFilter == 'user',
                  onSelected: () => _onFilterChanged('user'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(bool isWideScreen) {
    if (isWideScreen) {
      // Layout en grille pour les grands écrans
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          return UserCard(
            user: _filteredUsers[index],
            currentUser: widget.currentUser,
            onAction: _onUserAction,
          );
        },
      );
    } else {
      // Layout en liste pour les petits écrans
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UserCard(
              user: _filteredUsers[index],
              currentUser: widget.currentUser,
              onAction: _onUserAction,
            ),
          );
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}