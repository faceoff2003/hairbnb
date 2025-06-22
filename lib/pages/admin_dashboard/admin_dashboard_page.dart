import 'package:flutter/material.dart';
import '../../models/current_user.dart';
import '../ai_chat/widgets/ai_chat_wrapper.dart';
import 'admin_avis/admin_avis_moderation_page.dart';
import 'admin_users/admin_user_management_page.dart';

class AdminDashboardPage extends StatelessWidget {
  final CurrentUser currentUser;

  const AdminDashboardPage({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final primaryViolet = const Color(0xFF7B61FF);
    final lightBackground = const Color(0xFFF7F7F9);

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
          "Administration",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec info admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryViolet, primaryViolet.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryViolet.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Panneau d'Administration",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bienvenue ${currentUser.prenom} ${currentUser.nom}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section Modération
            _buildSectionHeader("Modération", Icons.gavel, primaryViolet),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.rate_review,
              title: "Modération des Avis",
              subtitle: "Gérer, masquer ou supprimer les avis clients",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminAvisModerationPage(currentUser: currentUser),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Section Outils IA
            _buildSectionHeader("Outils IA", Icons.auto_awesome, primaryViolet),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.chat_bubble,
              title: "Assistant IA Admin",
              subtitle: "Chat intelligent pour l'administration",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIChatWrapper(currentUser: currentUser),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Section Statistiques (à implémenter plus tard)
            _buildSectionHeader("Statistiques", Icons.analytics, primaryViolet),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.bar_chart,
              title: "Statistiques Générales",
              subtitle: "Vue d'ensemble de la plateforme",
              color: Colors.green,


              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Fonctionnalité à venir prochainement"),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              isComingSoon: true,
            ),

            const SizedBox(height: 16),

            // Section Gestion Utilisateurs (à implémenter plus tard)
            _buildSectionHeader("Gestion", Icons.people, primaryViolet),
            const SizedBox(height: 12),

            _buildAdminCard(
              context,
              icon: Icons.person_remove,
              title: "Gestion des Utilisateurs",
              subtitle: "Activer, désactiver ou changer les rôles",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminUserManagementPage(currentUser: currentUser),
                  ),
                );
              },
            ),


            // _buildAdminCard(
            //   context,
            //   icon: Icons.person_remove,
            //   title: "Gestion des Utilisateurs",
            //   subtitle: "Bloquer, débloquer ou supprimer des comptes",
            //   color: Colors.red,
            //   // onTap: () {
            //   //   ScaffoldMessenger.of(context).showSnackBar(
            //   //     const SnackBar(
            //   //       content: Text("Fonctionnalité à venir prochainement"),
            //   //       backgroundColor: Colors.orange,
            //   //     ),
            //   //   );
            //   // },
            //   // isComingSoon: true,
            //
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => AdminUserManagementPage(currentUser: currentUser),
            //       ),
            //     );
            //   },
            // ),

            const SizedBox(height: 24),

            // Footer avec version
            Center(
              child: Text(
                "Version Admin 1.0.0",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color primaryViolet) {
    return Row(
      children: [
        Icon(icon, color: primaryViolet, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryViolet,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
        bool isComingSoon = false,
      }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isComingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Bientôt",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}