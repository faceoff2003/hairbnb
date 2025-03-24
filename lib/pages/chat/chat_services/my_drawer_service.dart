import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';

class MyDrawer extends StatelessWidget {
  final CurrentUser currentUser;

  const MyDrawer({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("${currentUser.prenom} ${currentUser.nom}"),
            accountEmail: Text(currentUser.email ?? "Pas d'email"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: currentUser.photoProfil != null
                  ? NetworkImage("https://www.hairbnb.site/${currentUser.photoProfil}")
                  : AssetImage("logo_login/avatar.png") as ImageProvider,
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Accueil"),
            onTap: () {
              Navigator.pushNamed(context, "/home");
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Profil"),
            onTap: () {
              Navigator.pushNamed(context, "/profil");
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Déconnexion"),
            onTap: () {
              // Ajoute ici ta logique de logout
            },
          ),
        ],
      ),
    );
  }
}
