// pages/coiffeuse_dashboard/coiffeuse_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/current_user.dart';
import '../../services/firebase_token/token_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';
import '../ai_chat/coiffeuse_ai/coiffeuse_ai_conversations_list.dart';
import '../ai_chat/services/coiffeuse_ai_chat_service.dart';
import '../avis/avis_clients_coiffeuse_page.dart';
import '../commandes/coiffeuse_commande_page.dart';
import '../horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
import '../revenus/revenus_page.dart';
import '../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
import '../salon/salon_services_pages/promotion/promotions_management_page.dart';
import '../salon/salon_services_pages/show_services_list_page.dart';
import '../../public_salon_details/show_salon_page.dart';

class CoiffeuseDashboardPage extends StatefulWidget {
  final CurrentUser currentUser;

  const CoiffeuseDashboardPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<CoiffeuseDashboardPage> createState() => _CoiffeuseDashboardPageState();
}

class _CoiffeuseDashboardPageState extends State<CoiffeuseDashboardPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  int _currentIndex = 0; // Index pour la navbar

  // Couleurs
  final Color primaryOrange = Colors.orange;
  final Color lightBackground = const Color(0xFFF7F7F9);
  final Color errorRed = Colors.red;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Vérifie si l'utilisateur est une coiffeuse propriétaire
  bool _isCoiffeuseProprietaire(CurrentUser user) {
    bool isCoiffeuse = user.isCoiffeuseUser() ||
        user.type?.toLowerCase() == 'coiffeuse' ||
        (user.coiffeuse != null);

    if (!isCoiffeuse) return false;
    return user.coiffeuse?.salon != null;
  }

  /// Navigation vers l'Assistant IA Coiffeuses
  Future<void> _navigateToCoiffeuseAI(CurrentUser user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryOrange),
            SizedBox(height: 16),
            Text(
              'Initialisation de votre assistant IA...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      final token = await TokenService.getAuthToken();

      if (token == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'authentification'),
            backgroundColor: errorRed,
          ),
        );
        return;
      }

      final chatService = CoiffeuseAIChatService(
        baseUrl: 'https://www.hairbnb.site/api',
        token: token,
      );

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoiffeuseConversationsListPage(
            currentUser: user,
            chatService: chatService,
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'initialisation : $e'),
          backgroundColor: errorRed,
        ),
      );
    }
  }

  /// Navigation vers Mon Salon
  Future<void> _navigateToMonSalon() async {
    setState(() => _isLoading = true);

    try {
      if (widget.currentUser.coiffeuse?.salon != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalonDetailsPage(
              salonId: widget.currentUser.coiffeuse!.salon!.idTblSalon,
              currentUserId: widget.currentUser.idTblUser,
            ),
          ),
        );
      } else {
        final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(
            widget.currentUser.idTblUser
        );

        if (salon != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalonDetailsPage(
                salonId: salon.idSalon,
                currentUserId: widget.currentUser.idTblUser,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Vous n'avez pas encore de salon."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du chargement du salon: $e"),
          backgroundColor: errorRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProprietaire = _isCoiffeuseProprietaire(widget.currentUser);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: lightBackground,

      // ✅ AJOUT : CustomAppBar
      appBar: const CustomAppBar(),

      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryOrange))
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec info coiffeuse
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryOrange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_pin,
                          color: Colors.white,
                          size: isSmallScreen ? 28 : 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.currentUser.prenom} ${widget.currentUser.nom}",
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                isProprietaire
                                    ? "Coiffeuse Propriétaire"
                                    : "Coiffeuse",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.currentUser.coiffeuse?.salon != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.store,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              widget.currentUser.coiffeuse!.salon!.nomSalon ?? 'Mon Salon',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Titre section
              Text(
                "Gestion de mon activité",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              SizedBox(height: 16),

              // Grille des actions principales
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: isSmallScreen ? 2 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isSmallScreen ? 1.1 : 1.0,
                children: [
                  // Services
                  _buildActionCard(
                    icon: Icons.build,
                    title: "Services",
                    subtitle: "Gérer mes prestations",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServicesListPage(
                              coiffeuseId: widget.currentUser.idTblUser.toString()
                          ),
                        ),
                      );
                    },
                  ),

                  // Promotions
                  _buildActionCard(
                    icon: Icons.local_offer,
                    title: "Promotions",
                    subtitle: "Mes offres spéciales",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PromotionsManagementPage(
                              coiffeuseId: widget.currentUser.idTblUser.toString()
                          ),
                        ),
                      );
                    },
                  ),

                  // Mon salon
                  _buildActionCard(
                    icon: Icons.store,
                    title: "Mon salon",
                    subtitle: "Détails et gestion",
                    color: Colors.purple,
                    onTap: _navigateToMonSalon,
                  ),

                  // Disponibilités
                  _buildActionCard(
                    icon: Icons.calendar_today,
                    title: "Disponibilités",
                    subtitle: "Mes horaires",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HoraireIndispoPage(
                              coiffeuseId: widget.currentUser.idTblUser
                          ),
                        ),
                      );
                    },
                  ),

                  // Commandes reçues
                  _buildActionCard(
                    icon: Icons.assignment,
                    title: "Commandes",
                    subtitle: "Reçues",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoiffeuseCommandesPage(
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                  ),

                  // Avis clients
                  _buildActionCard(
                    icon: Icons.rate_review,
                    title: "Avis clients",
                    subtitle: "Consultez les retours",
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AvisClientsCoiffeusePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Section spéciale pour les propriétaires
              if (isProprietaire) ...[
                SizedBox(height: 32),

                Text(
                  "⭐ Fonctionnalités Propriétaire",
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.green.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RevenusPage(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.euro_symbol,
                                    color: Colors.white,
                                    size: isSmallScreen ? 28 : 32,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Mes Revenus",
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Suivez vos gains, statistiques et historique des paiements",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Assistant IA - Carte spéciale
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.blue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _navigateToCoiffeuseAI(widget.currentUser),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: isSmallScreen ? 28 : 32,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Assistant IA Personnel",
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Votre conseiller intelligent pour optimiser votre salon",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // ✅ AJOUT : BottomNavBar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// Widget pour construire une carte d'action
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallScreen ? 24 : 28,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}









// // pages/coiffeuse_dashboard/coiffeuse_dashboard_page.dart
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../models/current_user.dart';
// import '../../services/firebase_token/token_service.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../ai_chat/coiffeuse_ai/coiffeuse_ai_conversations_list.dart';
// import '../ai_chat/services/coiffeuse_ai_chat_service.dart';
// import '../avis/avis_clients_coiffeuse_page.dart';
// import '../commandes/coiffeuse_commande_page.dart';
// import '../horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
// import '../revenus/revenus_page.dart';
// import '../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
// import '../salon/salon_services_pages/promotion/promotions_management_page.dart';
// import '../salon/salon_services_pages/show_services_list_page.dart';
// import '../../public_salon_details/show_salon_page.dart';
//
// class CoiffeuseDashboardPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const CoiffeuseDashboardPage({
//     super.key,
//     required this.currentUser,
//   });
//
//   @override
//   State<CoiffeuseDashboardPage> createState() => _CoiffeuseDashboardPageState();
// }
//
// class _CoiffeuseDashboardPageState extends State<CoiffeuseDashboardPage>
//     with SingleTickerProviderStateMixin {
//
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   bool _isLoading = false;
//   int _currentIndex = 0; // Index pour la navbar
//
//   // Couleurs
//   final Color primaryOrange = Colors.orange;
//   final Color lightBackground = const Color(0xFFF7F7F9);
//   final Color errorRed = Colors.red;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut,
//       ),
//     );
//
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   /// Vérifie si l'utilisateur est une coiffeuse propriétaire
//   bool _isCoiffeuseProprietaire(CurrentUser user) {
//     bool isCoiffeuse = user.isCoiffeuseUser() ||
//         user.type?.toLowerCase() == 'coiffeuse' ||
//         (user.coiffeuse != null);
//
//     if (!isCoiffeuse) return false;
//     return user.coiffeuse?.salon != null;
//   }
//
//   /// Navigation vers l'Assistant IA Coiffeuses
//   Future<void> _navigateToCoiffeuseAI(CurrentUser user) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(color: primaryOrange),
//             SizedBox(height: 16),
//             Text(
//               'Initialisation de votre assistant IA...',
//               style: TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//
//     try {
//       final token = await TokenService.getAuthToken();
//
//       if (token == null) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur d\'authentification'),
//             backgroundColor: errorRed,
//           ),
//         );
//         return;
//       }
//
//       final chatService = CoiffeuseAIChatService(
//         baseUrl: 'https://www.hairbnb.site/api',
//         token: token,
//       );
//
//       Navigator.pop(context);
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CoiffeuseConversationsListPage(
//             currentUser: user,
//             chatService: chatService,
//           ),
//         ),
//       );
//     } catch (e) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Erreur lors de l\'initialisation : $e'),
//           backgroundColor: errorRed,
//         ),
//       );
//     }
//   }
//
//   /// Navigation vers Mon Salon
//   Future<void> _navigateToMonSalon() async {
//     setState(() => _isLoading = true);
//
//     try {
//       if (widget.currentUser.coiffeuse?.salon != null) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => SalonDetailsPage(
//               salonId: widget.currentUser.coiffeuse!.salon!.idTblSalon,
//               currentUserId: widget.currentUser.idTblUser,
//             ),
//           ),
//         );
//       } else {
//         final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(
//             widget.currentUser.idTblUser
//         );
//
//         if (salon != null) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => SalonDetailsPage(
//                 salonId: salon.idSalon,
//                 currentUserId: widget.currentUser.idTblUser,
//               ),
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Vous n'avez pas encore de salon."),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Erreur lors du chargement du salon: $e"),
//           backgroundColor: errorRed,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isProprietaire = _isCoiffeuseProprietaire(widget.currentUser);
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//
//     return Scaffold(
//       backgroundColor: lightBackground,
//       appBar: AppBar(
//         backgroundColor: primaryOrange,
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//         ),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.construction, color: Colors.white, size: 20),
//             SizedBox(width: 8),
//             Text(
//               "Espace Coiffeuse",
//               style: TextStyle(
//                 fontSize: isSmallScreen ? 18 : 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator(color: primaryOrange))
//           : FadeTransition(
//         opacity: _fadeAnimation,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // En-tête avec info coiffeuse
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [primaryOrange, Colors.deepOrange],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: primaryOrange.withOpacity(0.3),
//                       spreadRadius: 0,
//                       blurRadius: 10,
//                       offset: Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.person_pin,
//                           color: Colors.white,
//                           size: isSmallScreen ? 28 : 32,
//                         ),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "${widget.currentUser.prenom} ${widget.currentUser.nom}",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: isSmallScreen ? 18 : 22,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               Text(
//                                 isProprietaire
//                                     ? "Coiffeuse Propriétaire"
//                                     : "Coiffeuse",
//                                 style: TextStyle(
//                                   fontSize: isSmallScreen ? 14 : 16,
//                                   color: Colors.white70,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (widget.currentUser.coiffeuse?.salon != null) ...[
//                       SizedBox(height: 12),
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.store,
//                               color: Colors.white,
//                               size: 16,
//                             ),
//                             SizedBox(width: 6),
//                             Text(
//                               widget.currentUser.coiffeuse!.salon!.nomSalon ?? 'Mon Salon',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 24),
//
//               // Titre section
//               Text(
//                 "Gestion de mon activité",
//                 style: GoogleFonts.poppins(
//                   fontSize: isSmallScreen ? 18 : 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[800],
//                 ),
//               ),
//
//               SizedBox(height: 16),
//
//               // Grille des actions principales
//               GridView.count(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 crossAxisCount: isSmallScreen ? 2 : 3,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 childAspectRatio: isSmallScreen ? 1.1 : 1.0,
//                 children: [
//                   // Services
//                   _buildActionCard(
//                     icon: Icons.build,
//                     title: "Services",
//                     subtitle: "Gérer mes prestations",
//                     color: Colors.blue,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ServicesListPage(
//                               coiffeuseId: widget.currentUser.idTblUser.toString()
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//
//                   // Promotions
//                   _buildActionCard(
//                     icon: Icons.local_offer,
//                     title: "Promotions",
//                     subtitle: "Mes offres spéciales",
//                     color: Colors.green,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PromotionsManagementPage(
//                               coiffeuseId: widget.currentUser.idTblUser.toString()
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//
//                   // Mon salon
//                   _buildActionCard(
//                     icon: Icons.store,
//                     title: "Mon salon",
//                     subtitle: "Détails et gestion",
//                     color: Colors.purple,
//                     onTap: _navigateToMonSalon,
//                   ),
//
//                   // Disponibilités
//                   _buildActionCard(
//                     icon: Icons.calendar_today,
//                     title: "Disponibilités",
//                     subtitle: "Mes horaires",
//                     color: Colors.orange,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => HoraireIndispoPage(
//                               coiffeuseId: widget.currentUser.idTblUser
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//
//                   // Commandes reçues
//                   _buildActionCard(
//                     icon: Icons.assignment,
//                     title: "Commandes",
//                     subtitle: "Reçues",
//                     color: Colors.teal,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => CoiffeuseCommandesPage(
//                             currentUser: widget.currentUser,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//
//                   // Avis clients
//                   _buildActionCard(
//                     icon: Icons.rate_review,
//                     title: "Avis clients",
//                     subtitle: "Consultez les retours",
//                     color: Colors.indigo,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => AvisClientsCoiffeusePage(),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//
//               // Section spéciale pour les propriétaires
//               if (isProprietaire) ...[
//                 SizedBox(height: 32),
//
//                 Text(
//                   "⭐ Fonctionnalités Propriétaire",
//                   style: GoogleFonts.poppins(
//                     fontSize: isSmallScreen ? 18 : 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//
//                 SizedBox(height: 16),
//
//                 SizedBox(
//                   width: double.infinity,
//                   child: Card(
//                     elevation: 8,
//                     shadowColor: Colors.green.withOpacity(0.3),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.green.shade400,
//                             Colors.green.shade600,
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(16),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const RevenusPage(),
//                               ),
//                             );
//                           },
//                           child: Padding(
//                             padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   padding: EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(0.2),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Icon(
//                                     Icons.euro_symbol,
//                                     color: Colors.white,
//                                     size: isSmallScreen ? 28 : 32,
//                                   ),
//                                 ),
//                                 SizedBox(width: 16),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "Mes Revenus",
//                                         style: GoogleFonts.poppins(
//                                           fontSize: isSmallScreen ? 16 : 18,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       SizedBox(height: 4),
//                                       Text(
//                                         "Suivez vos gains, statistiques et historique des paiements",
//                                         style: TextStyle(
//                                           fontSize: isSmallScreen ? 12 : 14,
//                                           color: Colors.white70,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Icon(
//                                   Icons.arrow_forward_ios,
//                                   color: Colors.white,
//                                   size: 16,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 // Assistant IA - Carte spéciale
//                 SizedBox(
//                   width: double.infinity,
//                   child: Card(
//                     elevation: 8,
//                     shadowColor: Colors.blue.withOpacity(0.3),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.blue.shade400,
//                             Colors.blue.shade600,
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(16),
//                           onTap: () => _navigateToCoiffeuseAI(widget.currentUser),
//                           child: Padding(
//                             padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   padding: EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(0.2),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Icon(
//                                     Icons.auto_awesome,
//                                     color: Colors.white,
//                                     size: isSmallScreen ? 28 : 32,
//                                   ),
//                                 ),
//                                 SizedBox(width: 16),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "Assistant IA Personnel",
//                                         style: GoogleFonts.poppins(
//                                           fontSize: isSmallScreen ? 16 : 18,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       SizedBox(height: 4),
//                                       Text(
//                                         "Votre conseiller intelligent pour optimiser votre salon",
//                                         style: TextStyle(
//                                           fontSize: isSmallScreen ? 12 : 14,
//                                           color: Colors.white70,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Icon(
//                                   Icons.arrow_forward_ios,
//                                   color: Colors.white,
//                                   size: 16,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//
//               SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//       // Ajout de la BottomNavBar
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
//
//   /// Widget pour construire une carte d'action
//   Widget _buildActionCard({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     final isSmallScreen = MediaQuery.of(context).size.width < 400;
//
//     return Card(
//       elevation: 4,
//       shadowColor: color.withOpacity(0.3),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: onTap,
//           child: Container(
//             padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               gradient: LinearGradient(
//                 colors: [
//                   color.withOpacity(0.1),
//                   color.withOpacity(0.05),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: color,
//                     size: isSmallScreen ? 24 : 28,
//                   ),
//                 ),
//                 SizedBox(height: isSmallScreen ? 8 : 12),
//                 Text(
//                   title,
//                   style: GoogleFonts.poppins(
//                     fontSize: isSmallScreen ? 14 : 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 10 : 12,
//                     color: Colors.grey[600],
//                   ),
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
