import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/profil/services/image_util.dart';
import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_change_widget.dart';
import 'package:provider/provider.dart';
import '../../models/current_user.dart';
import '../../services/auth_services/logout_service.dart';
import '../../services/providers/current_user_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../admin_dashboard/admin_dashboard_page.dart';
import '../avis/mes_avis_page.dart';
import '../coiffeuse_dashboard/coiffeuse_dashboard_page.dart';
import '../home_page.dart';
import '../mes_commandes/mes_commandes_page.dart';
import 'services/delete_account/delete_account_service.dart';
import 'services/update_services/phone_update/phone_edit_widget.dart';

class ProfileScreen extends StatefulWidget {
  final CurrentUser currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  String errorMessage = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Couleurs de l'application
  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color lightBackground = const Color(0xFFF7F7F9);
  final Color successGreen = Colors.green;
  final Color errorRed = Colors.red;

  @override
  void initState() {
    super.initState();

    // Initialisation de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        )
    );

    // Démarrer l'animation directement car pas besoin d'attendre fetchUserProfile
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";

  /// Vérifie si l'utilisateur est une coiffeuse propriétaire
  bool _isCoiffeuseProprietaire(CurrentUser user) {
    // Vérifier que c'est une coiffeuse (via type ou isCoiffeuseUser())
    bool isCoiffeuse = user.isCoiffeuseUser() ||
        user.type?.toLowerCase() == 'coiffeuse' ||
        (user.coiffeuse != null);

    if (!isCoiffeuse) {
      return false;
    }

    if (user.coiffeuse?.salon != null) {
      return true;
    }

    return false;
  }

  /// Vérifie si l'utilisateur est admin
  bool _isAdmin(CurrentUser user) {
    return user.role?.toLowerCase() == 'admin' ||
        user.role?.toLowerCase() == 'administrateur';

  }

  void _editField(String fieldName, String currentValue) {
    // Pour le numéro de téléphone, utiliser le nouveau widget dédié
    if (fieldName == "Téléphone") {
      showPhoneEditDialog(
        context,
        widget.currentUser,
        primaryColor: primaryViolet,
        successColor: successGreen,
        errorColor: errorRed,
        setLoadingState: (bool value) {
          setState(() {
            isLoading = value;
          });
        },
      );
      return;
    }

    final TextEditingController fieldController = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Modifier $fieldName", style: TextStyle(color: primaryViolet, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: fieldController,
            decoration: InputDecoration(
              hintText: "Nouvelle valeur pour $fieldName",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryViolet, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // Vérifier que le champ a changé et n'est pas vide
                if (fieldController.text.isNotEmpty && fieldController.text != currentValue) {
                  await _updateUserProfileField(widget.currentUser.uuid, {fieldName: fieldController.text});
                }
              },
              style: TextButton.styleFrom(foregroundColor: primaryViolet),
              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserProfileField(String userUuid, Map<String, dynamic> updatedData) async {
    setState(() {
      isLoading = true;
    });

    setState(() {
      isLoading = false;
    });
  }

  void _editAddress(Adresse adresse) {
    showDialog(
      context: context,
      builder: (context) {
        return AddressChangeWidget(
          currentUser: widget.currentUser,
          currentAddress: adresse,
          setLoadingState: (bool value) {
            setState(() {
              isLoading = value;
            });
          },
          primaryColor: primaryViolet,
          successColor: successGreen,
          errorColor: errorRed,
        );
      },
    );
  }

  /// Navigation sécurisée vers la home page
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CurrentUser user = Provider.of<CurrentUserProvider>(context).currentUser ?? widget.currentUser;
//-----------------------------------------------------------------------------------------------------
    // DEBUG TEMPORAIRE - à retirer après test
    if (kDebugMode) {
      print("=== DEBUG PROFIL ===");
      print("user.type: ${user.type}");
      print("user.role: ${user.role}");
      print("user.isCoiffeuseUser(): ${user.isCoiffeuseUser()}");
      print("user.coiffeuse: ${user.coiffeuse}");
      print("user.coiffeuse?.salon: ${user.coiffeuse?.salon}");
      print("_isAdmin(user): ${_isAdmin(user)}");
      print("_isCoiffeuseProprietaire(user): ${_isCoiffeuseProprietaire(user)}");
      print("===================");
    }
//-----------------------------------------------------------------------------------------------------
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryViolet,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            // 🔥 FIX: Navigation intelligente
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            } else {
              _navigateToHome();
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Profil",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryViolet))
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: errorRed, size: 60),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: errorRed, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Section d'en-tête avec photo et nom
              Hero(
                tag: 'userAvatar',
                child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryViolet, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: user.photoProfil != null &&
                          user.photoProfil!.isNotEmpty
                          ? NetworkImage(ImageUtil.getFullImageUrl(user.photoProfil!))
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) {
                        if (kDebugMode) {
                          print("Erreur de chargement de l'image : $exception");
                        }
                      },
                    )
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "${capitalize(user.prenom)} ${capitalize(user.nom)}",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Type : ${capitalize(user.type ?? 'Indéfini')}",
                  style: TextStyle(fontSize: 16, color: primaryViolet, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),

              // Section d'informations générales
              _buildSectionHeader("Informations générales", Icons.person),
              Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _infoTile(Icons.email, "Email", user.email),
                      _infoTile(Icons.phone, "Téléphone", user.numeroTelephone),
                      if (user.adresse != null) ...[
                        Consumer<CurrentUserProvider>(
                          builder: (context, userProvider, child) {
                            final currentAddr = userProvider.currentUser?.adresse ?? user.adresse;
                            if (currentAddr != null) {
                              return _addressCompactTile(currentAddr);
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section d'informations professionnelles (pour les coiffeuses)
              if (user.isCoiffeuseUser() && user.coiffeuse != null) ...[
                _buildSectionHeader("Informations professionnelles", Icons.business_center),
                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _infoTile(Icons.business, "Dénomination Sociale", user.coiffeuse!.denominationSociale ?? ''),
                        // _infoTile(Icons.money, "TVA", user.coiffeuse!.tva ?? ''),
                        // _infoTile(Icons.map, "Position", user.coiffeuse!.position ?? ''),
                        if (user.coiffeuse!.salon != null)
                          _infoTile(Icons.store, "Nom du salon", user.coiffeuse!.salon!.nomSalon ?? ''),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Section des actions
              _buildSectionHeader("Actions", Icons.settings),
              Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      if (user.isCoiffeuseUser()) ...[
                        _actionTile(
                          Icons.dashboard,
                          "Espace Coiffeuse",
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoiffeuseDashboardPage(
                                  currentUser: user,
                                ),
                              ),
                            );
                          },
                          isHighlighted: true,
                        ),
                      ],

                      // Assistant IA pour Admins
                      if (_isAdmin(user))
                        _actionTile(
                          Icons.admin_panel_settings,
                          "Administration",
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminDashboardPage(currentUser: user),
                              ),
                            );
                          },
                          isHighlighted: true,
                        ),
                      _actionTile(
                        Icons.rate_review,
                        "Mes avis",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MesAvisPage(),
                            ),
                          );
                        },
                        isHighlighted: true,
                      ),

                      // Mes commandes (pour tous)
                      _actionTile(
                        Icons.shopping_bag,
                        "Mes Commandes",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MesCommandesPage(currentUser: user),
                            ),
                          );
                        },
                        isHighlighted: true,
                      ),

                      // Suppression du compte
                      _actionTile(
                        Icons.delete_forever,
                        "Supprimer mon compte",
                            () async {
                          await DeleteAccountService.deleteUserAccount(
                            context: context,
                            currentUser: user,
                            successGreen: successGreen,
                            errorRed: errorRed,
                            setLoadingState: (bool value) {
                              setState(() {
                                isLoading = value;
                              });
                            },
                          );
                        },
                        isDestructive: true,
                      ),

                      // Déconnexion
                      _actionTile(
                        Icons.logout,
                        "Déconnexion",
                            () async {
                          await LogoutService.confirmLogout(context);
                        },
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4, // Correspond à l'onglet "Profil"
        onTap: (index) {
          // L'action est gérée dans le widget de la navbar lui-même
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryViolet, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryViolet
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryViolet),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value != null && value.isNotEmpty ? value : "Non spécifié",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        color: primaryViolet,
        onPressed: () {
          // Utilisation spéciale pour le téléphone
          if (label == "Téléphone") {
            showPhoneEditDialog(
              context,
              widget.currentUser,
              primaryColor: primaryViolet,
              successColor: successGreen,
              errorColor: errorRed,
              setLoadingState: (bool value) {
                setState(() {
                  isLoading = value;
                });
              },
            );
          } else {
            _editField(label, value ?? "");
          }
        },
      ),
    );
  }

  // Nouvelle méthode pour afficher l'adresse de manière compacte
  Widget _addressCompactTile(Adresse adresse) {
    // Construire l'adresse complète en un seul texte
    String addressLine1 = '';
    String addressLine2 = '';

    // Ligne 1: Numéro + rue
    if (adresse.numero != null && adresse.numero!.isNotEmpty) {
      addressLine1 += adresse.numero!;
    }

    // Ajouter le nom de la rue
    if (adresse.rue != null && adresse.rue!.nomRue != null && adresse.rue!.nomRue!.isNotEmpty) {
      if (addressLine1.isNotEmpty) addressLine1 += ' ';
      addressLine1 += adresse.rue!.nomRue!;
    }

    // Ligne 2: Code postal + Commune
    if (adresse.rue?.localite != null) {
      if (adresse.rue!.localite!.codePostal != null && adresse.rue!.localite!.codePostal!.isNotEmpty) {
        addressLine2 += adresse.rue!.localite!.codePostal!;
      }

      if (adresse.rue!.localite!.commune != null && adresse.rue!.localite!.commune!.isNotEmpty) {
        if (addressLine2.isNotEmpty) addressLine2 += ' ';
        addressLine2 += adresse.rue!.localite!.commune!;
      }
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.location_on, color: primaryViolet),
      ),
      title: Text(
        'Adresse',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (addressLine1.isNotEmpty)
            Text(
              addressLine1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (addressLine2.isNotEmpty)
            Text(
              addressLine2,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        color: primaryViolet,
        onPressed: () => _editAddress(adresse),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false, bool isHighlighted = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : isHighlighted
              ? Colors.orange.withOpacity(0.2)
              : primaryViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : isHighlighted
              ? Colors.orange
              : primaryViolet,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          color: isDestructive
              ? Colors.red
              : isHighlighted
              ? Colors.orange
              : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive
            ? Colors.red
            : isHighlighted
            ? Colors.orange
            : Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: isHighlighted ? Colors.orange.withOpacity(0.05) : null,
    );
  }
}