import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/profil/profil_widgets/show_salon_page.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/current_user.dart';
import '../../services/auth_services/logout_service.dart';
import '../../services/providers/get_user_type_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../ai_chat/conversations_list_page.dart';
import '../ai_chat/providers/ai_chat_provider.dart';
import '../ai_chat/services/ai_chat_service.dart';
import '../ai_chat/widgets/ai_chat_wrapper.dart';
import '../commandes/coiffeuse_commande_page.dart';
import '../horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
import '../mes_commandes/mes_commandes_page.dart';
import '../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
import '../salon/salon_services_pages/promotion/promotions_management_page.dart';
import '../salon/salon_services_pages/show_services_list_page.dart';

class ProfileScreen extends StatefulWidget {
  final CurrentUser currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = "";
  String baseUrl = "";
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

    fetchUserProfile().then((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    baseUrl = 'https://www.hairbnb.site/api/get_user_profile/${widget.currentUser.uuid}/';

    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Erreur : ${response.statusCode} ${response.reasonPhrase}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur réseau : $e";
        isLoading = false;
      });
    }
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
                if (fieldController.text.isNotEmpty && fieldController.text != currentValue) {
                  await updateUserProfile(widget.currentUser.uuid, {fieldName: fieldController.text});
                  fetchUserProfile();
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => fetchUserProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryViolet,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      )
          : userData == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Aucune donnée à afficher.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
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
                    backgroundImage: widget.currentUser.photoProfil != null &&
                        widget.currentUser.photoProfil!.isNotEmpty
                        ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                      print("Erreur de chargement de l'image : $exception");
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
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
                  "Type : ${capitalize(userData!['type'])}",
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
                      _infoTile(Icons.email, "Email", widget.currentUser.email),
                      _infoTile(Icons.phone, "Téléphone", widget.currentUser.numeroTelephone),
                      if (userData!['adresse'] != null) _infoTile(Icons.home, "Adresse", userData!['adresse']),
                      if (userData!['rue'] != null) _infoTile(Icons.location_on, "Rue", userData!['rue']),
                      if (userData!['commune'] != null) _infoTile(Icons.location_city, "Commune", userData!['commune']),
                      if (userData!['code_postal'] != null) _infoTile(Icons.local_post_office, "Code postal", userData!['code_postal']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section d'informations professionnelles (pour les coiffeuses)
              if (widget.currentUser.type == 'coiffeuse') ...[
                _buildSectionHeader("Informations professionnelles", Icons.business_center),
                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _infoTile(Icons.business, "Dénomination Sociale", userData!['denomination_sociale']),
                        _infoTile(Icons.money, "TVA", userData!['tva']),
                        _infoTile(Icons.map, "Position", userData!['position']),
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
                      if (widget.currentUser.type == 'coiffeuse') ...[
                        _actionTile(
                            Icons.build,
                            "Services",
                                () async {
                              final userDetails = await getIdAndTypeFromUuid(userData?['uuid']);
                              if (userDetails != null) {
                                final idTblUser = userDetails['idTblUser'];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Erreur lors de la récupération des services."),
                                    backgroundColor: errorRed,
                                  ),
                                );
                              }
                            }
                        ),

                        // Nouveau bouton pour les promotions
                        _actionTile(
                          Icons.local_offer,
                          "Promotions",
                              () async {
                            final userDetails = await getIdAndTypeFromUuid(userData?['uuid']);
                            if (userDetails != null) {
                              final idTblUser = userDetails['idTblUser'];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PromotionsManagementPage(coiffeuseId: idTblUser.toString()),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Erreur lors de la récupération des promotions."),
                                  backgroundColor: errorRed,
                                ),
                              );
                            }
                          },
                          isHighlighted: true, // Mettre en évidence ce bouton
                        ),

                        _actionTile(
                            Icons.store,
                            "Mon salon",
                                () async {
                              final userDetails = await getIdAndTypeFromUuid(userData?['uuid']);
                              if (userDetails != null) {
                                final coiffeuseId = userDetails['idTblUser'];

                                // Afficher un indicateur de chargement
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                try {
                                  // Appel au service pour récupérer le salon
                                  final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(coiffeuseId);
                                  final currentUserId = widget.currentUser.idTblUser;

                                  // Fermer l'indicateur de chargement
                                  Navigator.pop(context);

                                  if (salon != null) {
                                    // Naviguer vers la page de détails du salon
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SalonDetailsPage(
                                          salonId: salon.idSalon,
                                          currentUserId: currentUserId,
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
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Impossible de charger les données du salon."),
                                    backgroundColor: errorRed,
                                  ),
                                );
                              }
                            }
                        ),

                        _actionTile(
                            Icons.calendar_today,
                            "Mes disponibilités",
                                () async {
                              final userDetails = await getIdAndTypeFromUuid(widget.currentUser.uuid);
                              if (userDetails != null) {
                                final coiffeuseId = userDetails['idTblUser'];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HoraireIndispoPage(coiffeuseId: coiffeuseId),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Impossible de charger vos horaires."),
                                    backgroundColor: errorRed,
                                  ),
                                );
                              }
                            }
                        ),

                        _actionTile(
                          Icons.assignment,
                          "Commandes Reçues",
                              () {
                                final currentUser = widget.currentUser;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoiffeuseCommandesPage(
                                  currentUser: currentUser,
                                ),
                              ),
                            );
                          },
                          isHighlighted: false, // Pour mettre en évidence ce bouton
                        ),

                        _actionTile(
                          Icons.chat_bubble,
                          "Assistant IA",
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AIChatWrapper(currentUser: widget.currentUser),
                              ),
                            );
                          },
                          isHighlighted: true,
                        ),
                      ],

                      _actionTile(
                        Icons.shopping_bag,
                        "Mes Commandes",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MesCommandesPage(currentUser: widget.currentUser),
                            ),
                          );
                        },
                        isHighlighted: true,  // Pour mettre en évidence ce bouton
                      ),

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

  Widget _infoTile(IconData icon, String label, dynamic value) {
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
        value != null && value.toString().isNotEmpty ? value.toString() : "Non spécifié",
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

  Future<void> updateUserProfile(String userUuid, Map<String, dynamic> updatedData) async {
    final String apiUrl = 'https://www.hairbnb.site/api/update_user_profile/$userUuid/';
    try {
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Profil mis à jour avec succès"),
                ],
              ),
              backgroundColor: successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            )
        );
      } else {
        throw Exception("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text("Erreur réseau : $e")),
              ],
            ),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          )
      );
    }
  }
}