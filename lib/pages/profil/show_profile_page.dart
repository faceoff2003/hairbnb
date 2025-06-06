import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/profil/services/image_util.dart';
import '../../models/current_user.dart';
import '../../services/auth_services/logout_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../ai_chat/widgets/ai_chat_wrapper.dart';
import '../commandes/coiffeuse_commande_page.dart';
import '../horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
import '../mes_commandes/mes_commandes_page.dart';
import '../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
import '../salon/salon_services_pages/promotion/promotions_management_page.dart';
import '../salon/salon_services_pages/show_services_list_page.dart';
import '../../public_salon_details/show_salon_page.dart';
import 'services/delete_account/delete_account_service.dart';
import 'services/update_services/adress_update/adress_update_service.dart';
import 'services/update_services/phone_update/phone_update_service.dart';

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

  void _editField(String fieldName, String currentValue) {
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

                  // Si c'est le numéro de téléphone, utiliser le service spécifique
                  if (fieldName == "Téléphone") {
                    await _updatePhoneNumber(fieldController.text);
                  }
                  // Sinon utiliser la méthode générique
                  else {
                    await _updateUserProfileField(widget.currentUser.uuid, {fieldName: fieldController.text});
                  }
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

  Future<void> _updatePhoneNumber(String newPhone) async {
    await PhoneUpdateService.updateUserPhoneNumber(
      context,
      widget.currentUser,
      newPhone,
      successGreen: successGreen,
      errorRed: errorRed,
      setLoadingState: (bool value) {
        setState(() {
          isLoading = value;
        });
      },
    );
  }

  Future<void> _updateUserAddress(Map<String, dynamic> addressData) async {
    await AddressUpdateService.updateUserAddress(
      context,
      widget.currentUser,
      addressData,
      successGreen: successGreen,
      errorRed: errorRed,
      setLoadingState: (bool value) {
        setState(() {
          isLoading = value;
        });
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
    // Contrôleurs pour chaque champ d'adresse
    final numeroController = TextEditingController(text: adresse.numero ?? '');
    //final boiteController = TextEditingController(text: adresse.boitePostale ?? '');
    final rueController = TextEditingController(text: adresse.rue?.nomRue ?? '');
    final communeController = TextEditingController(text: adresse.rue?.localite?.commune ?? '');
    final codePostalController = TextEditingController(text: adresse.rue?.localite?.codePostal ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Modifier l'adresse", style: TextStyle(color: primaryViolet, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Champs pour numéro
                TextField(
                  controller: numeroController,
                  decoration: InputDecoration(
                    labelText: "Numéro",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryViolet, width: 2),
                    ),
                  ),
                ),
               const SizedBox(height: 8),
                //const SizedBox(height: 8),
                // Champs pour rue
                TextField(
                  controller: rueController,
                  decoration: InputDecoration(
                    labelText: "Rue",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryViolet, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Champs pour commune
                TextField(
                  controller: communeController,
                  decoration: InputDecoration(
                    labelText: "Commune",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryViolet, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Champs pour code postal
                TextField(
                  controller: codePostalController,
                  decoration: InputDecoration(
                    labelText: "Code postal",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryViolet, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                // Préparer les données d'adresse
                Map<String, dynamic> addressData = {
                  'numero': numeroController.text,
                  //'boitePostale': boiteController.text,
                  'rue': {
                    'nomRue': rueController.text,
                    'localite': {
                      'commune': communeController.text,
                      'codePostal': codePostalController.text
                    }
                  }
                };

                Navigator.pop(context);

                // Appeler le service pour mettre à jour l'adresse
                _updateUserAddress(addressData);
              },
              style: TextButton.styleFrom(foregroundColor: primaryViolet),
              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final CurrentUser user = widget.currentUser;

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
                        // Adresse condensée en une seule tuile
                        _addressCompactTile(user.adresse!),
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
                        _infoTile(Icons.money, "TVA", user.coiffeuse!.tva ?? ''),
                        _infoTile(Icons.map, "Position", user.coiffeuse!.position ?? ''),
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
                            Icons.build,
                            "Services",
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServicesListPage(coiffeuseId: user.idTblUser.toString()),
                                ),
                              );
                            }
                        ),

                        // Promotions
                        _actionTile(
                          Icons.local_offer,
                          "Promotions",
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PromotionsManagementPage(coiffeuseId: user.idTblUser.toString()),
                              ),
                            );
                          },
                          isHighlighted: true,
                        ),

                        // Mon salon
                        _actionTile(
                            Icons.store,
                            "Mon salon",
                                () async {
                              // Afficher un indicateur de chargement
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                // Récupérer le salon directement à partir de l'utilisateur s'il existe
                                if (user.coiffeuse?.salon != null) {
                                  // Fermer l'indicateur de chargement
                                  Navigator.pop(context);

                                  // Naviguer vers la page de détails du salon
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SalonDetailsPage(
                                        salonId: user.coiffeuse!.salon!.idTblSalon,
                                        currentUserId: user.idTblUser,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Appel au service pour récupérer le salon
                                  final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(user.idTblUser);

                                  // Fermer l'indicateur de chargement
                                  Navigator.pop(context);

                                  if (salon != null) {
                                    // Naviguer vers la page de détails du salon
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SalonDetailsPage(
                                          salonId: salon.idSalon,
                                          currentUserId: user.idTblUser,
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Si aucun salon n'est trouvé
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text("Vous n'avez pas encore de salon."),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                // Fermer l'indicateur de chargement en cas d'erreur
                                Navigator.pop(context);

                                // Afficher un message d'erreur
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Erreur lors du chargement du salon: $e"),
                                    backgroundColor: errorRed,
                                  ),
                                );
                              }
                            }
                        ),

                        // Disponibilités
                        _actionTile(
                            Icons.calendar_today,
                            "Mes disponibilités",
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HoraireIndispoPage(coiffeuseId: user.idTblUser),
                                ),
                              );
                            }
                        ),

                        // Commandes reçues
                        _actionTile(
                          Icons.assignment,
                          "Commandes Reçues",
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoiffeuseCommandesPage(
                                  currentUser: user,
                                ),
                              ),
                            );
                          },
                        ),

                        // Assistant IA
                        _actionTile(
                          Icons.chat_bubble,
                          "Assistant IA",
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AIChatWrapper(currentUser: user),
                              ),
                            );
                          },
                          isHighlighted: true,
                        ),
                      ],

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
        onPressed: () => _editField(label, value ?? ""),
      ),
    );
  }

  // Nouvelle méthode pour afficher l'adresse de manière compacte
  Widget _addressCompactTile(Adresse adresse) {
    // Construire l'adresse complète en un seul texte
    String addressLine1 = '';
    String addressLine2 = '';

    // // Ligne 1: Numéro + boîte postale (si disponible) + rue
    // if (adresse.numero != null && adresse.numero!.isNotEmpty) {
    //   addressLine1 += adresse.numero!;
    //   if (adresse.boitePostale != null && adresse.boitePostale!.isNotEmpty) {
    //     addressLine1 += '/' + adresse.boitePostale!;
    //   }
    // }

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