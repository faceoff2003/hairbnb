import 'package:flutter/material.dart';

class AdminUser {
  final int idTblUser;
  final String uuid;
  final String nom;
  final String prenom;
  final String email;
  final bool isActive;
  final String roleName;
  final String typeName;

  AdminUser({
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.isActive,
    required this.roleName,
    required this.typeName,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      idTblUser: json['idTblUser'] ?? 0,
      uuid: json['uuid'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? true,
      roleName: json['role_name'] ?? 'user',
      typeName: json['type_name'] ?? '',
    );
  }

  String get nomComplet => '$prenom $nom';

  bool get isAdmin => roleName.toLowerCase() == 'admin';

  String get statusText => isActive ? 'Actif' : 'Inactif';

  Color get statusColor => isActive ? Colors.green : Colors.red;

  IconData get roleIcon => isAdmin ? Icons.admin_panel_settings : Icons.person;
}