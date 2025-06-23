import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/pages/panier/cart_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CurrentUserProvider>(context, listen: false).fetchCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;

    return AppBar(
      backgroundColor: Colors.orange,
      // Afficher la flèche seulement si on peut revenir en arrière
      leading: Navigator.canPop(context)
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      )
          : null,
      title: Row(
        children: [
          if (currentUser?.photoProfil != null)
            CircleAvatar(
              backgroundImage: NetworkImage(currentUser!.photoProfil!),
              radius: 20,
            )
          else
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 20,
              child: Icon(Icons.person, color: Colors.white),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 18, color: Colors.black),
                children: [
                  TextSpan(
                    text: currentUser != null
                        ? "${currentUser.nom} ${currentUser.prenom} "
                        : "Chargement...",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: currentUser != null ? "(${currentUser.type})" : "",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart, size: 28, color: Colors.black),
            tooltip: "Voir mon panier",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ),
      ],
    );
  }
}