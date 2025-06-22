import 'package:flutter/material.dart';
import '../../../../models/admin_user.dart';
import '../../../../models/current_user.dart';

class UserCard extends StatelessWidget {
  final AdminUser user;
  final CurrentUser currentUser;
  final Function(AdminUser, String) onAction;

  const UserCard({
    super.key,
    required this.user,
    required this.currentUser,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final primaryViolet = const Color(0xFF7B61FF);
    final isCurrentUser = user.idTblUser == currentUser.idTblUser;

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec nom et statut
            Row(
              children: [
                // Avatar avec icône de rôle
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: user.isAdmin ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    user.roleIcon,
                    color: user.isAdmin ? Colors.orange : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Infos utilisateur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.nomComplet,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryViolet.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Vous',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primaryViolet,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: user.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Infos supplémentaires
            Row(
              children: [
                Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Rôle: ${user.roleName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const Spacer(),
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  user.typeName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions (seulement si ce n'est pas l'utilisateur actuel)
            if (!isCurrentUser) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Toggle statut
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onAction(user, 'toggle_status'),
                      icon: Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(
                        user.isActive ? 'Désactiver' : 'Activer',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.isActive ? Colors.red.shade50 : Colors.green.shade50,
                        foregroundColor: user.isActive ? Colors.red : Colors.green,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: user.isActive ? Colors.red.shade300 : Colors.green.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Toggle rôle
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onAction(user, 'toggle_role'),
                      icon: Icon(
                        user.isAdmin ? Icons.person : Icons.admin_panel_settings,
                        size: 18,
                      ),
                      label: Text(
                        user.isAdmin ? 'Rétrograder' : 'Promouvoir',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryViolet.withOpacity(0.1),
                        foregroundColor: primaryViolet,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: primaryViolet.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Divider(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Vous ne pouvez pas modifier votre propre compte',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}