import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/providers/cart_provider.dart';
import '../../services/providers/current_user_provider.dart';
import '../../services/providers/disponibilites_provider.dart';
import '../payment/payment_page.dart';

class ConfirmRdvPage extends StatefulWidget {
  const ConfirmRdvPage({super.key});

  @override
  _ConfirmRdvPageState createState() => _ConfirmRdvPageState();
}

class _ConfirmRdvPageState extends State<ConfirmRdvPage> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  bool isLoadingDisponibilites = true;
  String? currentUserId;
  DateTime? selectedDateTime;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _disponibilitesTimer;
  bool _isLocaleInitialized = false;

  String _debugInfo = "";
  bool _showDebugInfo = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initialiser les données de locale pour le français
    initializeDateFormatting('fr_FR', null).then((_) {
      setState(() {
        _isLocaleInitialized = true;
      });
      print("✅ Locale fr_FR initialisée avec succès");
    }).catchError((error) {
      print("❌ Erreur lors de l'initialisation de la locale: $error");
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Ajout d'un délai avant de charger les disponibilités pour s'assurer
    // que les providers sont correctement initialisés
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentUser();
      _chargerDisponibilites();

      // Vérifier périodiquement l'état du chargement des disponibilités
      _disponibilitesTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
        if (disponibilitesProvider.isLoaded) {
          setState(() {
            isLoadingDisponibilites = false;
          });
          timer.cancel();
          _disponibilitesTimer = null;
        }
      });
    });

    // Effet de vibration légère au démarrage
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _disponibilitesTimer?.cancel(); // Annuler le timer lors de la destruction
    super.dispose();
  }

  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    currentUserId = currentUserProvider.currentUser?.idTblUser.toString();

    if (currentUserId == null) {
      print("⚠️ ID utilisateur non trouvé. Vérifiez que l'utilisateur est connecté.");
    } else {
      print("✅ ID utilisateur récupéré: $currentUserId");
    }
  }

  // 🔍 Méthode pour mettre à jour les infos de debug
  void _updateDebugInfo(String info) {
    setState(() {
      _debugInfo += "\n${DateTime.now().toString().substring(11, 19)}: $info";
    });
  }

  void _chargerDisponibilites() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);

    _updateDebugInfo("🔄 Début chargement disponibilités");

    // 🛡️ VALIDATION AMÉLIORÉE
    if (cartProvider.coiffeuseId == null) {
      print("⚠️ ID coiffeuse non trouvé. Veuillez sélectionner une coiffeuse.");
      _updateDebugInfo("❌ coiffeuseId null");
      _showCustomSnackBar("Erreur: ID coiffeuse non défini. Retournez à l'écran précédent.");
      setState(() {
        isLoadingDisponibilites = false;
      });
      return;
    }

    if (cartProvider.totalDuration <= 0) {
      print("⚠️ Durée totale non valide: ${cartProvider.totalDuration}");
      _updateDebugInfo("❌ totalDuration: ${cartProvider.totalDuration}");

      // 🔍 Debug détaillé des services
      print("🔍 Services dans le panier:");
      for (var service in cartProvider.cartItems) {
        print("   - ${service.intitule}: ${service.temps} minutes");
      }

      _showCustomSnackBar("Erreur: Durée des services non définie. Services: ${cartProvider.cartItems.length}");
      setState(() {
        isLoadingDisponibilites = false;
      });
      return;
    }

    _updateDebugInfo("✅ coiffeuseId: ${cartProvider.coiffeuseId}");
    _updateDebugInfo("✅ totalDuration: ${cartProvider.totalDuration}");
    _updateDebugInfo("✅ services: ${cartProvider.cartItems.length}");

    print("🔄 Chargement des disponibilités pour coiffeuse: ${cartProvider.coiffeuseId}, durée: ${cartProvider.totalDuration}");

    // Charger les disponibilités et gérer le résultat
    disponibilitesProvider.loadDisponibilites(
      cartProvider.coiffeuseId.toString(),
      cartProvider.totalDuration,
    ).then((_) {
      print("✅ Disponibilités chargées avec succès!");
      _updateDebugInfo("✅ Chargement terminé");
      setState(() {
        isLoadingDisponibilites = false;
      });

      // Diagnostic détaillé
      final diagnosticInfo = disponibilitesProvider.getDiagnosticInfo();
      _updateDebugInfo("📊 Diagnostic: $diagnosticInfo");

      if (disponibilitesProvider.joursDisponibles.isEmpty) {
        print("⚠️ Aucun jour disponible trouvé.");
        _updateDebugInfo("⚠️ Aucun jour disponible");
        if (disponibilitesProvider.lastError != null) {
          _updateDebugInfo("❌ Erreur: ${disponibilitesProvider.lastError}");
        }
        _showCustomSnackBar("Aucune disponibilité trouvée pour cette durée.");
      } else {
        print("✅ ${disponibilitesProvider.joursDisponibles.length} jours disponibles trouvés.");
        _updateDebugInfo("✅ ${disponibilitesProvider.joursDisponibles.length} jours dispos");
      }
    }).catchError((error) {
      print("❌ Erreur lors du chargement des disponibilités: $error");
      _updateDebugInfo("❌ Erreur: $error");
      _showCustomSnackBar("Erreur de chargement des disponibilités: $error");
      setState(() {
        isLoadingDisponibilites = false;
      });
    });
  }

  // Fonction pour forcer le rechargement des disponibilités
  void _rechargerDisponibilites() {
    setState(() {
      isLoadingDisponibilites = true;
    });
    _showCustomSnackBar("Rechargement des disponibilités...");
    _chargerDisponibilites();
  }

  Future<void> _pickDateTime() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);

    final now = DateTime.now();
    final endDate = now.add(Duration(days: 14));

    // Vérifier si le chargement est toujours en cours
    if (isLoadingDisponibilites) {
      _showCustomSnackBar("Chargement des disponibilités en cours...");
      return;
    }

    // Vérifier si les disponibilités sont correctement chargées
    if (!disponibilitesProvider.isLoaded || disponibilitesProvider.joursDisponibles.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Problème de disponibilités"),
          content: Text("Aucune disponibilité n'a été trouvée. Voulez-vous réessayer?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _rechargerDisponibilites();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: Text("Réessayer"),
            ),
          ],
        ),
      );
      return;
    }

    // Choisir la date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: disponibilitesProvider.joursDisponibles.first,
      firstDate: now,
      lastDate: endDate,
      selectableDayPredicate: (day) => disponibilitesProvider.isJourDispo(day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepOrange,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepOrange,
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // Vibration légère lors de la sélection
    HapticFeedback.selectionClick();

    try {
      // Afficher un indicateur de chargement
      setState(() {
        isLoading = true;
      });

      final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
      print("🔄 Récupération des créneaux pour le $dateStr");

      final creneaux = await disponibilitesProvider.getCreneauxPourJour(
        dateStr,
        cartProvider.coiffeuseId.toString(),
        cartProvider.totalDuration,
      );

      setState(() {
        isLoading = false;
      });

      final filteredCreneaux = creneaux.where((slot) {
        if (pickedDate.year == now.year &&
            pickedDate.month == now.month &&
            pickedDate.day == now.day) {
          final timeParts = slot["debut"]!.split(":");
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final slotDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, hour, minute);
          return slotDateTime.isAfter(now);
        }
        return true;
      }).toList();

      if (filteredCreneaux.isEmpty) {
        _showCustomSnackBar("Aucun créneau disponible pour cette date.");
        return;
      }

      // ✅ MODIFICATION: Utilisation d'un showDialog pour centrer la modale
      final selectedSlot = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20), // Espace autour de la modale
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25), // Coins arrondis
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Poignée décorative (optionnelle mais conserve le design)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Créneaux disponibles",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCreneaux.length,
                    itemBuilder: (context, index) {
                      final slot = filteredCreneaux[index];
                      final debut = slot["debut"]!;
                      final fin = slot["fin"]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () => Navigator.pop(context, slot),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade100, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$debut - $fin",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.deepOrange,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedSlot != null) {
        final debut = selectedSlot["debut"]!;
        //final dateTime = DateTime.parse("${dateStr}T$debut:00");
        final dateTime = DateTime.parse("${dateStr}T$debut");
        setState(() {
          selectedDateTime = dateTime;
        });
        print("✅ Créneau sélectionné: $debut");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("❌ Erreur lors de la récupération des créneaux: $e");
      _showCustomSnackBar("Erreur lors de la récupération des créneaux disponibles.");
    }
  }

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.deepOrange.shade700,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(10),
        elevation: 6,
      ),
    );
  }

  // ✅ VERSION SIMPLIFIÉE - Toujours utiliser Stripe
  Future<void> _confirmRdv() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Vérifier si tous les champs requis sont remplis
    if (currentUserId == null) {
      _showCustomSnackBar("Erreur: ID utilisateur non trouvé. Veuillez vous reconnecter.");
      return;
    }

    if (selectedDateTime == null) {
      _showCustomSnackBar("Veuillez sélectionner une date et une heure pour votre rendez-vous.");
      return;
    }

    // ❌ SUPPRIMÉ: Validation de selectedPaymentMethod

    if (cartProvider.cartItems.isEmpty) {
      _showCustomSnackBar("Votre panier est vide. Veuillez sélectionner au moins un service.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Vibration de confirmation
      HapticFeedback.mediumImpact();

      print("🔄 Envoi de la réservation: user=$currentUserId, date=${selectedDateTime.toString()}, paiement=stripe");

      // ✅ TOUJOURS UTILISER "stripe" comme méthode de paiement
      final responseData = await cartProvider.envoyerReservation(
        userId: currentUserId!,
        dateHeure: selectedDateTime!,
        methodePaiement: "stripe", // ✅ FIXE: Toujours Stripe
      );

      if (responseData != null) {
        print("✅ Réservation confirmée avec succès: $responseData");

        // Récupérer l'ID du rendez-vous depuis la réponse
        final rendezVous = responseData['rendez_vous'];
        if (rendezVous == null || rendezVous['id'] == null) {
          _showCustomSnackBar("Erreur : ID du rendez-vous non trouvé.");
          return;
        }
        final rendezVousId = rendezVous['id'];

        // ✅ TOUJOURS ALLER VERS LA PAGE DE PAIEMENT STRIPE
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaiementPage(
              rendezVousId: rendezVousId,
            ),
          ),
        );
      } else {
        print("❌ Échec de la confirmation du rendez-vous");
        _showCustomSnackBar("Erreur lors de la confirmation du RDV.");
      }
    } catch (e) {
      print("❌ Exception lors de la confirmation: $e");
      _showCustomSnackBar("Erreur de connexion au serveur.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Confirmation RDV",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Bouton de rechargement des disponibilités
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _rechargerDisponibilites,
            tooltip: "Recharger les disponibilités",
          ),
          // 🔍 BOUTON DEBUG
          if (_debugInfo.isNotEmpty)
            IconButton(
              icon: Icon(Icons.bug_report),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Debug Info"),
                    content: SingleChildScrollView(
                      child: Text(
                        _debugInfo,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Fermer"),
                      ),
                    ],
                  ),
                );
              },
              tooltip: "Afficher les infos de debug",
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : screenWidth * 0.1,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête animé
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(bottom: 20),
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Réservez votre moment bien-être',
                                textStyle: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade800,
                                ),
                                speed: Duration(milliseconds: 80),
                              ),
                            ],
                            totalRepeatCount: 1,
                          ),
                        ),
                      ),

                      // Indicateur de chargement des disponibilités
                      if (isLoadingDisponibilites)
                        Container(
                          margin: EdgeInsets.only(bottom: 20),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "Chargement des disponibilités...",
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Services sélectionnés
                      _buildSectionHeader("Services sélectionnés"),
                      if (cartProvider.cartItems.isEmpty)
                        _buildEmptyState("Aucun service sélectionné.")
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: cartProvider.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartProvider.cartItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.orange.shade50],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepOrange.shade100,
                                    child: Icon(
                                      Icons.spa_rounded,
                                      color: Colors.deepOrange.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    item.intitule,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.green.shade200),
                                          ),
                                          child: Text(
                                            "${item.prix_final} €",
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 14,
                                                color: Colors.blue.shade700,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "${item.temps} min",
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      SizedBox(height: 25),

                      // Date et heure
                      _buildSectionHeader("Date et heure"),
                      GestureDetector(
                        onTap: _pickDateTime,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 25), // Augmenté car plus de section paiement
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: selectedDateTime != null
                                  ? [Colors.orange.shade200, Colors.orange.shade100]
                                  : [Colors.grey.shade200, Colors.grey.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: selectedDateTime != null ? Colors.orange.shade700 : Colors.grey,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedDateTime == null ? "Sélectionner la date et l'heure" : "Rendez-vous prévu",
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (selectedDateTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: _isLocaleInitialized
                                            ? Text(
                                          DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR').format(selectedDateTime!),
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        )
                                            : Text(
                                          DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ❌ SUPPRIMÉ: Section méthode de paiement

                      // Bouton de confirmation
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: 55,
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: isLoading
                            ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                          ),
                        )
                            : ElevatedButton(
                          onPressed: _confirmRdv,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.green.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 24), // ✅ Icône paiement pour Stripe
                              SizedBox(width: 12),
                              Text(
                                "PAYER AVEC STRIPE", // ✅ Texte plus clair
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Prix total
                      if (cartProvider.cartItems.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total à payer",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                "${cartProvider.totalPrice.toStringAsFixed(2)} €",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Overlay de chargement global
                if (isLoading && !isLoadingDisponibilites)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Chargement en cours...",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 30),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 40,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';
// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'dart:async'; // Ajout pour le Timer
// import 'package:intl/date_symbol_data_local.dart'; // Ajout pour l'initialisation des données de locale
//
// import '../../services/providers/cart_provider.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../services/providers/disponibilites_provider.dart';
// import '../payment/payment_page.dart';
//
// class ConfirmRdvPage extends StatefulWidget {
//   const ConfirmRdvPage({super.key});
//
//   @override
//   _ConfirmRdvPageState createState() => _ConfirmRdvPageState();
// }
//
// class _ConfirmRdvPageState extends State<ConfirmRdvPage> with SingleTickerProviderStateMixin {
//   bool isLoading = false;
//   bool isLoadingDisponibilites = true; // Nouvel état pour suivre le chargement
//   String? currentUserId;
//   DateTime? selectedDateTime;
//   // ❌ SUPPRIMÉ: String? selectedPaymentMethod;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   Timer? _disponibilitesTimer;
//   bool _isLocaleInitialized = false;
//
//   String _debugInfo = "";
//   bool _showDebugInfo = false;
//
//   // ❌ SUPPRIMÉ: final List<String> paymentMethods = ["Carte", "Cash", "PayPal"];
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialiser les données de locale pour le français
//     initializeDateFormatting('fr_FR', null).then((_) {
//       setState(() {
//         _isLocaleInitialized = true;
//       });
//       print("✅ Locale fr_FR initialisée avec succès");
//     }).catchError((error) {
//       print("❌ Erreur lors de l'initialisation de la locale: $error");
//     });
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 800),
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
//
//     // Ajout d'un délai avant de charger les disponibilités pour s'assurer
//     // que les providers sont correctement initialisés
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchCurrentUser();
//       _chargerDisponibilites();
//
//       // Vérifier périodiquement l'état du chargement des disponibilités
//       _disponibilitesTimer = Timer.periodic(Duration(seconds: 2), (timer) {
//         final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
//         if (disponibilitesProvider.isLoaded) {
//           setState(() {
//             isLoadingDisponibilites = false;
//           });
//           timer.cancel();
//           _disponibilitesTimer = null;
//         }
//       });
//     });
//
//     // Effet de vibration légère au démarrage
//     HapticFeedback.lightImpact();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _disponibilitesTimer?.cancel(); // Annuler le timer lors de la destruction
//     super.dispose();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//
//     if (currentUserId == null) {
//       print("⚠️ ID utilisateur non trouvé. Vérifiez que l'utilisateur est connecté.");
//     } else {
//       print("✅ ID utilisateur récupéré: $currentUserId");
//     }
//   }
//
//   // 🔍 Méthode pour mettre à jour les infos de debug
//   void _updateDebugInfo(String info) {
//     setState(() {
//       _debugInfo += "\n${DateTime.now().toString().substring(11, 19)}: $info";
//     });
//   }
//
//   void _chargerDisponibilites() {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
//
//     _updateDebugInfo("🔄 Début chargement disponibilités");
//
//     // 🛡️ VALIDATION AMÉLIORÉE
//     if (cartProvider.coiffeuseId == null) {
//       print("⚠️ ID coiffeuse non trouvé. Veuillez sélectionner une coiffeuse.");
//       _updateDebugInfo("❌ coiffeuseId null");
//       _showCustomSnackBar("Erreur: ID coiffeuse non défini. Retournez à l'écran précédent.");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//       return;
//     }
//
//     if (cartProvider.totalDuration <= 0) {
//       print("⚠️ Durée totale non valide: ${cartProvider.totalDuration}");
//       _updateDebugInfo("❌ totalDuration: ${cartProvider.totalDuration}");
//
//       // 🔍 Debug détaillé des services
//       print("🔍 Services dans le panier:");
//       for (var service in cartProvider.cartItems) {
//         print("   - ${service.intitule}: ${service.temps} minutes");
//       }
//
//       _showCustomSnackBar("Erreur: Durée des services non définie. Services: ${cartProvider.cartItems.length}");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//       return;
//     }
//
//     _updateDebugInfo("✅ coiffeuseId: ${cartProvider.coiffeuseId}");
//     _updateDebugInfo("✅ totalDuration: ${cartProvider.totalDuration}");
//     _updateDebugInfo("✅ services: ${cartProvider.cartItems.length}");
//
//     print("🔄 Chargement des disponibilités pour coiffeuse: ${cartProvider.coiffeuseId}, durée: ${cartProvider.totalDuration}");
//
//     // Charger les disponibilités et gérer le résultat
//     disponibilitesProvider.loadDisponibilites(
//       cartProvider.coiffeuseId.toString(),
//       cartProvider.totalDuration,
//     ).then((_) {
//       print("✅ Disponibilités chargées avec succès!");
//       _updateDebugInfo("✅ Chargement terminé");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//
//       // Diagnostic détaillé
//       final diagnosticInfo = disponibilitesProvider.getDiagnosticInfo();
//       _updateDebugInfo("📊 Diagnostic: $diagnosticInfo");
//
//       if (disponibilitesProvider.joursDisponibles.isEmpty) {
//         print("⚠️ Aucun jour disponible trouvé.");
//         _updateDebugInfo("⚠️ Aucun jour disponible");
//         if (disponibilitesProvider.lastError != null) {
//           _updateDebugInfo("❌ Erreur: ${disponibilitesProvider.lastError}");
//         }
//         _showCustomSnackBar("Aucune disponibilité trouvée pour cette durée.");
//       } else {
//         print("✅ ${disponibilitesProvider.joursDisponibles.length} jours disponibles trouvés.");
//         _updateDebugInfo("✅ ${disponibilitesProvider.joursDisponibles.length} jours dispos");
//       }
//     }).catchError((error) {
//       print("❌ Erreur lors du chargement des disponibilités: $error");
//       _updateDebugInfo("❌ Erreur: $error");
//       _showCustomSnackBar("Erreur de chargement des disponibilités: $error");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//     });
//   }
//
//   // Fonction pour forcer le rechargement des disponibilités
//   void _rechargerDisponibilites() {
//     setState(() {
//       isLoadingDisponibilites = true;
//     });
//     _showCustomSnackBar("Rechargement des disponibilités...");
//     _chargerDisponibilites();
//   }
//
//   Future<void> _pickDateTime() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
//
//     final now = DateTime.now();
//     final endDate = now.add(Duration(days: 14));
//
//     // Vérifier si le chargement est toujours en cours
//     if (isLoadingDisponibilites) {
//       _showCustomSnackBar("Chargement des disponibilités en cours...");
//       return;
//     }
//
//     // Vérifier si les disponibilités sont correctement chargées
//     if (!disponibilitesProvider.isLoaded || disponibilitesProvider.joursDisponibles.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text("Problème de disponibilités"),
//           content: Text("Aucune disponibilité n'a été trouvée. Voulez-vous réessayer?"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text("Annuler"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _rechargerDisponibilites();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepOrange,
//               ),
//               child: Text("Réessayer"),
//             ),
//           ],
//         ),
//       );
//       return;
//     }
//
//     // Choisir la date
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: disponibilitesProvider.joursDisponibles.first,
//       firstDate: now,
//       lastDate: endDate,
//       selectableDayPredicate: (day) => disponibilitesProvider.isJourDispo(day),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.deepOrange,
//               onPrimary: Colors.white,
//               onSurface: Colors.black87,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.deepOrange,
//               ),
//             ),
//             dialogTheme: DialogThemeData(backgroundColor: Colors.white),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (pickedDate == null) return;
//
//     // Vibration légère lors de la sélection
//     HapticFeedback.selectionClick();
//
//     try {
//       // Afficher un indicateur de chargement
//       setState(() {
//         isLoading = true;
//       });
//
//       final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
//       print("🔄 Récupération des créneaux pour le $dateStr");
//
//       final creneaux = await disponibilitesProvider.getCreneauxPourJour(
//         dateStr,
//         cartProvider.coiffeuseId.toString(),
//         cartProvider.totalDuration,
//       );
//
//       setState(() {
//         isLoading = false;
//       });
//
//       final filteredCreneaux = creneaux.where((slot) {
//         if (pickedDate.year == now.year &&
//             pickedDate.month == now.month &&
//             pickedDate.day == now.day) {
//           final timeParts = slot["debut"]!.split(":");
//           final hour = int.parse(timeParts[0]);
//           final minute = int.parse(timeParts[1]);
//           final slotDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, hour, minute);
//           return slotDateTime.isAfter(now);
//         }
//         return true;
//       }).toList();
//
//       if (filteredCreneaux.isEmpty) {
//         _showCustomSnackBar("Aucun créneau disponible pour cette date.");
//         return;
//       }
//
//       // Utilisation d'un bottom sheet pour la sélection du créneau
//       final selectedSlot = await showModalBottomSheet<Map<String, String>>(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (context) => Container(
//           height: MediaQuery.of(context).size.height * 0.5,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 10,
//                 spreadRadius: 0,
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Container(
//                 margin: EdgeInsets.only(top: 8),
//                 height: 4,
//                 width: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   "Créneaux disponibles",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.deepOrange,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   padding: EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: filteredCreneaux.length,
//                   itemBuilder: (context, index) {
//                     final slot = filteredCreneaux[index];
//                     final debut = slot["debut"]!;
//                     final fin = slot["fin"]!;
//
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 8.0),
//                       child: InkWell(
//                         onTap: () => Navigator.pop(context, slot),
//                         child: Container(
//                           padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.orange.shade100, Colors.white],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.orange.shade200),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "$debut - $fin",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               Icon(
//                                 Icons.access_time_rounded,
//                                 color: Colors.deepOrange,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//
//       if (selectedSlot != null) {
//         final debut = selectedSlot["debut"]!;
//         final dateTime = DateTime.parse("${dateStr}T$debut:00");
//         setState(() {
//           selectedDateTime = dateTime;
//         });
//         print("✅ Créneau sélectionné: $debut");
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       print("❌ Erreur lors de la récupération des créneaux: $e");
//       _showCustomSnackBar("Erreur lors de la récupération des créneaux disponibles.");
//     }
//   }
//
//   void _showCustomSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.info_outline, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         backgroundColor: Colors.deepOrange.shade700,
//         duration: Duration(seconds: 3),
//         margin: EdgeInsets.all(10),
//         elevation: 6,
//       ),
//     );
//   }
//
//   // ✅ VERSION SIMPLIFIÉE - Toujours utiliser Stripe
//   Future<void> _confirmRdv() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     // Vérifier si tous les champs requis sont remplis
//     if (currentUserId == null) {
//       _showCustomSnackBar("Erreur: ID utilisateur non trouvé. Veuillez vous reconnecter.");
//       return;
//     }
//
//     if (selectedDateTime == null) {
//       _showCustomSnackBar("Veuillez sélectionner une date et une heure pour votre rendez-vous.");
//       return;
//     }
//
//     // ❌ SUPPRIMÉ: Validation de selectedPaymentMethod
//
//     if (cartProvider.cartItems.isEmpty) {
//       _showCustomSnackBar("Votre panier est vide. Veuillez sélectionner au moins un service.");
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       // Vibration de confirmation
//       HapticFeedback.mediumImpact();
//
//       print("🔄 Envoi de la réservation: user=$currentUserId, date=${selectedDateTime.toString()}, paiement=stripe");
//
//       // ✅ TOUJOURS UTILISER "stripe" comme méthode de paiement
//       final responseData = await cartProvider.envoyerReservation(
//         userId: currentUserId!,
//         dateHeure: selectedDateTime!,
//         methodePaiement: "stripe", // ✅ FIXE: Toujours Stripe
//       );
//
//       if (responseData != null) {
//         print("✅ Réservation confirmée avec succès: $responseData");
//
//         // Récupérer l'ID du rendez-vous depuis la réponse
//         final rendezVous = responseData['rendez_vous'];
//         if (rendezVous == null || rendezVous['id'] == null) {
//           _showCustomSnackBar("Erreur : ID du rendez-vous non trouvé.");
//           return;
//         }
//         final rendezVousId = rendezVous['id'];
//
//         // ✅ TOUJOURS ALLER VERS LA PAGE DE PAIEMENT STRIPE
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PaiementPage(
//               rendezVousId: rendezVousId,
//             ),
//           ),
//         );
//       } else {
//         print("❌ Échec de la confirmation du rendez-vous");
//         _showCustomSnackBar("Erreur lors de la confirmation du RDV.");
//       }
//     } catch (e) {
//       print("❌ Exception lors de la confirmation: $e");
//       _showCustomSnackBar("Erreur de connexion au serveur.");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//
//     return Scaffold(
//       key: _scaffoldKey,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(
//           "Confirmation RDV",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.orange.shade700,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_rounded),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           // Bouton de rechargement des disponibilités
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _rechargerDisponibilites,
//             tooltip: "Recharger les disponibilités",
//           ),
//           // 🔍 BOUTON DEBUG
//           if (_debugInfo.isNotEmpty)
//             IconButton(
//               icon: Icon(Icons.bug_report),
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: Text("Debug Info"),
//                     content: SingleChildScrollView(
//                       child: Text(
//                         _debugInfo,
//                         style: TextStyle(fontFamily: 'monospace', fontSize: 12),
//                       ),
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text("Fermer"),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//               tooltip: "Afficher les infos de debug",
//             ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.orange.shade50, Colors.white],
//           ),
//         ),
//         child: SafeArea(
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: Stack(
//               children: [
//                 SingleChildScrollView(
//                   physics: BouncingScrollPhysics(),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isSmallScreen ? 16 : screenWidth * 0.1,
//                     vertical: 16,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // En-tête animé
//                       Center(
//                         child: Container(
//                           margin: EdgeInsets.only(bottom: 20),
//                           child: AnimatedTextKit(
//                             animatedTexts: [
//                               TypewriterAnimatedText(
//                                 'Réservez votre moment bien-être',
//                                 textStyle: TextStyle(
//                                   fontSize: isSmallScreen ? 18 : 22,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.deepOrange.shade800,
//                                 ),
//                                 speed: Duration(milliseconds: 80),
//                               ),
//                             ],
//                             totalRepeatCount: 1,
//                           ),
//                         ),
//                       ),
//
//                       // Indicateur de chargement des disponibilités
//                       if (isLoadingDisponibilites)
//                         Container(
//                           margin: EdgeInsets.only(bottom: 20),
//                           padding: EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: BorderRadius.circular(15),
//                             border: Border.all(color: Colors.blue.shade200),
//                           ),
//                           child: Row(
//                             children: [
//                               SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                                 ),
//                               ),
//                               SizedBox(width: 16),
//                               Expanded(
//                                 child: Text(
//                                   "Chargement des disponibilités...",
//                                   style: TextStyle(
//                                     color: Colors.blue.shade800,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                       // Services sélectionnés
//                       _buildSectionHeader("Services sélectionnés"),
//                       if (cartProvider.cartItems.isEmpty)
//                         _buildEmptyState("Aucun service sélectionné.")
//                       else
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: cartProvider.cartItems.length,
//                           itemBuilder: (context, index) {
//                             final item = cartProvider.cartItems[index];
//                             return Padding(
//                               padding: const EdgeInsets.only(bottom: 10),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [Colors.white, Colors.orange.shade50],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   borderRadius: BorderRadius.circular(15),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.05),
//                                       blurRadius: 10,
//                                       offset: Offset(0, 4),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ListTile(
//                                   contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                   leading: CircleAvatar(
//                                     backgroundColor: Colors.deepOrange.shade100,
//                                     child: Icon(
//                                       Icons.spa_rounded,
//                                       color: Colors.deepOrange.shade700,
//                                     ),
//                                   ),
//                                   title: Text(
//                                     item.intitule,
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   subtitle: Padding(
//                                     padding: const EdgeInsets.only(top: 6.0),
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                                           decoration: BoxDecoration(
//                                             color: Colors.green.shade50,
//                                             borderRadius: BorderRadius.circular(20),
//                                             border: Border.all(color: Colors.green.shade200),
//                                           ),
//                                           child: Text(
//                                             "${item.prix_final} €",
//                                             style: TextStyle(
//                                               color: Colors.green.shade700,
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                           ),
//                                         ),
//                                         SizedBox(width: 8),
//                                         Container(
//                                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                                           decoration: BoxDecoration(
//                                             color: Colors.blue.shade50,
//                                             borderRadius: BorderRadius.circular(20),
//                                             border: Border.all(color: Colors.blue.shade200),
//                                           ),
//                                           child: Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               Icon(
//                                                 Icons.access_time_rounded,
//                                                 size: 14,
//                                                 color: Colors.blue.shade700,
//                                               ),
//                                               SizedBox(width: 4),
//                                               Text(
//                                                 "${item.temps} min",
//                                                 style: TextStyle(
//                                                   color: Colors.blue.shade700,
//                                                   fontWeight: FontWeight.w600,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//
//                       SizedBox(height: 25),
//
//                       // Date et heure
//                       _buildSectionHeader("Date et heure"),
//                       GestureDetector(
//                         onTap: _pickDateTime,
//                         child: Container(
//                           margin: EdgeInsets.only(bottom: 25), // Augmenté car plus de section paiement
//                           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: selectedDateTime != null
//                                   ? [Colors.orange.shade200, Colors.orange.shade100]
//                                   : [Colors.grey.shade200, Colors.grey.shade100],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(15),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 padding: EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Icon(
//                                   Icons.calendar_today_rounded,
//                                   color: selectedDateTime != null ? Colors.orange.shade700 : Colors.grey,
//                                   size: 28,
//                                 ),
//                               ),
//                               SizedBox(width: 16),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       selectedDateTime == null ? "Sélectionner la date et l'heure" : "Rendez-vous prévu",
//                                       style: TextStyle(
//                                         color: Colors.grey.shade800,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                     if (selectedDateTime != null)
//                                       Padding(
//                                         padding: const EdgeInsets.only(top: 4.0),
//                                         child: _isLocaleInitialized
//                                             ? Text(
//                                           DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR').format(selectedDateTime!),
//                                           style: TextStyle(
//                                             color: Colors.orange.shade800,
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 15,
//                                           ),
//                                         )
//                                             : Text(
//                                           DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
//                                           style: TextStyle(
//                                             color: Colors.orange.shade800,
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 15,
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                               Icon(
//                                 Icons.arrow_forward_ios_rounded,
//                                 color: Colors.grey,
//                                 size: 16,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       // ❌ SUPPRIMÉ: Section méthode de paiement
//
//                       // Bouton de confirmation
//                       AnimatedContainer(
//                         duration: Duration(milliseconds: 300),
//                         height: 55,
//                         width: double.infinity,
//                         margin: EdgeInsets.symmetric(vertical: 10),
//                         child: isLoading
//                             ? Center(
//                           child: CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
//                           ),
//                         )
//                             : ElevatedButton(
//                           onPressed: _confirmRdv,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green.shade600,
//                             foregroundColor: Colors.white,
//                             elevation: 5,
//                             shadowColor: Colors.green.shade200,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.payment, size: 24), // ✅ Icône paiement pour Stripe
//                               SizedBox(width: 12),
//                               Text(
//                                 "PAYER AVEC STRIPE", // ✅ Texte plus clair
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: 1,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       // Prix total
//                       if (cartProvider.cartItems.isNotEmpty)
//                         Container(
//                           margin: EdgeInsets.only(top: 20),
//                           padding: EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.green.shade50,
//                             borderRadius: BorderRadius.circular(15),
//                             border: Border.all(color: Colors.green.shade200),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Total à payer",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey.shade800,
//                                 ),
//                               ),
//                               Text(
//                                 "${cartProvider.totalPrice.toStringAsFixed(2)} €",
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.green.shade800,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//                 // Overlay de chargement global
//                 if (isLoading && !isLoadingDisponibilites)
//                   Container(
//                     color: Colors.black.withOpacity(0.3),
//                     child: Center(
//                       child: Container(
//                         padding: EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             CircularProgressIndicator(
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               "Chargement en cours...",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey.shade800,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Row(
//         children: [
//           Container(
//             width: 4,
//             height: 18,
//             decoration: BoxDecoration(
//               color: Colors.deepOrange,
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           SizedBox(width: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(String message) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(vertical: 30),
//       margin: EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: Colors.grey.shade300, width: 1),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.shopping_basket_outlined,
//             size: 40,
//             color: Colors.grey,
//           ),
//           SizedBox(height: 10),
//           Text(
//             message,
//             style: TextStyle(
//               color: Colors.grey.shade700,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//










// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';
// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'dart:async'; // Ajout pour le Timer
// import 'package:intl/date_symbol_data_local.dart'; // Ajout pour l'initialisation des données de locale
//
// import '../../services/providers/cart_provider.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../services/providers/disponibilites_provider.dart';
// import '../payment/payment_page.dart';
//
// class ConfirmRdvPage extends StatefulWidget {
//   const ConfirmRdvPage({super.key});
//
//   @override
//   _ConfirmRdvPageState createState() => _ConfirmRdvPageState();
// }
//
// class _ConfirmRdvPageState extends State<ConfirmRdvPage> with SingleTickerProviderStateMixin {
//   bool isLoading = false;
//   bool isLoadingDisponibilites = true; // Nouvel état pour suivre le chargement
//   String? currentUserId;
//   DateTime? selectedDateTime;
//   String? selectedPaymentMethod;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   Timer? _disponibilitesTimer;
//   bool _isLocaleInitialized = false;
//
//   String _debugInfo = "";
//   bool _showDebugInfo = false;
//
//   final List<String> paymentMethods = ["Carte", "Cash", "PayPal"];
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialiser les données de locale pour le français
//     initializeDateFormatting('fr_FR', null).then((_) {
//       setState(() {
//         _isLocaleInitialized = true;
//       });
//       print("✅ Locale fr_FR initialisée avec succès");
//     }).catchError((error) {
//       print("❌ Erreur lors de l'initialisation de la locale: $error");
//     });
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 800),
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
//
//     // Ajout d'un délai avant de charger les disponibilités pour s'assurer
//     // que les providers sont correctement initialisés
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchCurrentUser();
//       _chargerDisponibilites();
//
//       // Vérifier périodiquement l'état du chargement des disponibilités
//       _disponibilitesTimer = Timer.periodic(Duration(seconds: 2), (timer) {
//         final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
//         if (disponibilitesProvider.isLoaded) {
//           setState(() {
//             isLoadingDisponibilites = false;
//           });
//           timer.cancel();
//           _disponibilitesTimer = null;
//         }
//       });
//     });
//
//     // Effet de vibration légère au démarrage
//     HapticFeedback.lightImpact();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _disponibilitesTimer?.cancel(); // Annuler le timer lors de la destruction
//     super.dispose();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     currentUserId = currentUserProvider.currentUser?.idTblUser.toString();
//
//     if (currentUserId == null) {
//       print("⚠️ ID utilisateur non trouvé. Vérifiez que l'utilisateur est connecté.");
//     } else {
//       print("✅ ID utilisateur récupéré: $currentUserId");
//     }
//   }
//
//   void _chargerDisponibilites() {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
//
//     // Vérifier si les informations nécessaires sont disponibles
//     if (cartProvider.coiffeuseId == null) {
//       print("⚠️ ID coiffeuse non trouvé. Veuillez sélectionner une coiffeuse.");
//       _showCustomSnackBar("Erreur: ID coiffeuse non défini. Retournez à l'écran précédent.");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//       return;
//     }
//
//     if (cartProvider.totalDuration <= 0) {
//       print("⚠️ Durée totale non valide: ${cartProvider.totalDuration}");
//       _showCustomSnackBar("Erreur: Durée des services non définie. Sélectionnez des services.");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//       return;
//     }
//
//     print("🔄 Chargement des disponibilités pour coiffeuse: ${cartProvider.coiffeuseId}, durée: ${cartProvider.totalDuration}");
//
//     // Charger les disponibilités et gérer le résultat
//     disponibilitesProvider.loadDisponibilites(
//       cartProvider.coiffeuseId.toString(),
//       cartProvider.totalDuration,
//     ).then((_) {
//       print("✅ Disponibilités chargées avec succès!");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//
//       // Vérifier si des jours sont disponibles
//       if (disponibilitesProvider.joursDisponibles.isEmpty) {
//         print("⚠️ Aucun jour disponible trouvé.");
//         _showCustomSnackBar("Aucune disponibilité trouvée pour cette durée.");
//       } else {
//         print("✅ ${disponibilitesProvider.joursDisponibles.length} jours disponibles trouvés.");
//       }
//     }).catchError((error) {
//       print("❌ Erreur lors du chargement des disponibilités: $error");
//       _showCustomSnackBar("Erreur de chargement des disponibilités.");
//       setState(() {
//         isLoadingDisponibilites = false;
//       });
//     });
//   }
//
//   // Fonction pour forcer le rechargement des disponibilités
//   void _rechargerDisponibilites() {
//     setState(() {
//       isLoadingDisponibilites = true;
//     });
//     _showCustomSnackBar("Rechargement des disponibilités...");
//     _chargerDisponibilites();
//   }
//
//   Future<void> _pickDateTime() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final disponibilitesProvider = Provider.of<DisponibilitesProvider>(context, listen: false);
//
//     final now = DateTime.now();
//     final endDate = now.add(Duration(days: 14));
//
//     // Vérifier si le chargement est toujours en cours
//     if (isLoadingDisponibilites) {
//       _showCustomSnackBar("Chargement des disponibilités en cours...");
//       return;
//     }
//
//     // Vérifier si les disponibilités sont correctement chargées
//     if (!disponibilitesProvider.isLoaded || disponibilitesProvider.joursDisponibles.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text("Problème de disponibilités"),
//           content: Text("Aucune disponibilité n'a été trouvée. Voulez-vous réessayer?"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text("Annuler"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _rechargerDisponibilites();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepOrange,
//               ),
//               child: Text("Réessayer"),
//             ),
//           ],
//         ),
//       );
//       return;
//     }
//
//     // Choisir la date
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: disponibilitesProvider.joursDisponibles.first,
//       firstDate: now,
//       lastDate: endDate,
//       selectableDayPredicate: (day) => disponibilitesProvider.isJourDispo(day),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.deepOrange,
//               onPrimary: Colors.white,
//               onSurface: Colors.black87,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.deepOrange,
//               ),
//             ),
//             dialogTheme: DialogThemeData(backgroundColor: Colors.white),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (pickedDate == null) return;
//
//     // Vibration légère lors de la sélection
//     HapticFeedback.selectionClick();
//
//     try {
//       // Afficher un indicateur de chargement
//       setState(() {
//         isLoading = true;
//       });
//
//       final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
//       print("🔄 Récupération des créneaux pour le $dateStr");
//
//       final creneaux = await disponibilitesProvider.getCreneauxPourJour(
//         dateStr,
//         cartProvider.coiffeuseId.toString(),
//         cartProvider.totalDuration,
//       );
//
//       setState(() {
//         isLoading = false;
//       });
//
//       //print("✅ ${creneaux.length} créneaux récupérés");
//
//       final filteredCreneaux = creneaux.where((slot) {
//         if (pickedDate.year == now.year &&
//             pickedDate.month == now.month &&
//             pickedDate.day == now.day) {
//           final timeParts = slot["debut"]!.split(":");
//           final hour = int.parse(timeParts[0]);
//           final minute = int.parse(timeParts[1]);
//           final slotDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, hour, minute);
//           return slotDateTime.isAfter(now);
//         }
//         return true;
//       }).toList();
//
//       if (filteredCreneaux.isEmpty) {
//         _showCustomSnackBar("Aucun créneau disponible pour cette date.");
//         return;
//       }
//
//       // Utilisation d'un bottom sheet pour la sélection du créneau
//       final selectedSlot = await showModalBottomSheet<Map<String, String>>(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (context) => Container(
//           height: MediaQuery.of(context).size.height * 0.5,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 10,
//                 spreadRadius: 0,
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Container(
//                 margin: EdgeInsets.only(top: 8),
//                 height: 4,
//                 width: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   "Créneaux disponibles",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.deepOrange,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   padding: EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: filteredCreneaux.length,
//                   itemBuilder: (context, index) {
//                     final slot = filteredCreneaux[index];
//                     final debut = slot["debut"]!;
//                     final fin = slot["fin"]!;
//
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 8.0),
//                       child: InkWell(
//                         onTap: () => Navigator.pop(context, slot),
//                         child: Container(
//                           padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.orange.shade100, Colors.white],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.orange.shade200),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "$debut - $fin",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               Icon(
//                                 Icons.access_time_rounded,
//                                 color: Colors.deepOrange,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//
//       if (selectedSlot != null) {
//         final debut = selectedSlot["debut"]!;
//         final dateTime = DateTime.parse("${dateStr}T$debut:00");
//         setState(() {
//           selectedDateTime = dateTime;
//         });
//         print("✅ Créneau sélectionné: $debut");
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       print("❌ Erreur lors de la récupération des créneaux: $e");
//       _showCustomSnackBar("Erreur lors de la récupération des créneaux disponibles.");
//     }
//   }
//
//   void _showCustomSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.info_outline, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         backgroundColor: Colors.deepOrange.shade700,
//         duration: Duration(seconds: 3),
//         margin: EdgeInsets.all(10),
//         elevation: 6,
//       ),
//     );
//   }
//
//   // Remplacez la méthode _confirmRdv avec cette version améliorée
//   Future<void> _confirmRdv() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     // Vérifier si tous les champs requis sont remplis
//     if (currentUserId == null) {
//       _showCustomSnackBar("Erreur: ID utilisateur non trouvé. Veuillez vous reconnecter.");
//       return;
//     }
//
//     if (selectedDateTime == null) {
//       _showCustomSnackBar("Veuillez sélectionner une date et une heure pour votre rendez-vous.");
//       return;
//     }
//
//     if (selectedPaymentMethod == null) {
//       _showCustomSnackBar("Veuillez sélectionner une méthode de paiement.");
//       return;
//     }
//
//     if (cartProvider.cartItems.isEmpty) {
//       _showCustomSnackBar("Votre panier est vide. Veuillez sélectionner au moins un service.");
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       // Vibration de confirmation
//       HapticFeedback.mediumImpact();
//
//       print("🔄 Envoi de la réservation: user=$currentUserId, date=${selectedDateTime.toString()}, paiement=$selectedPaymentMethod");
//
//       final responseData = await cartProvider.envoyerReservation(
//         userId: currentUserId!,
//         dateHeure: selectedDateTime!,
//         methodePaiement: selectedPaymentMethod!,
//       );
//
//       if (responseData != null) {
//         print("✅ Réservation confirmée avec succès: $responseData");
//
//         // Récupérer l'ID du rendez-vous depuis la réponse si disponible
//
//         final rendezVous = responseData['rendez_vous'];
//         if (rendezVous == null || rendezVous['id'] == null) {
//           _showCustomSnackBar("Erreur : ID du rendez-vous non trouvé.");
//           return;
//         }
//         final rendezVousId = rendezVous['id'];
//
//
//         // final rendezVousId = responseData['id'] ??
//         //     responseData['rendez_vous_id'] ??
//         //     responseData['id_rendez_vous'] ??
//         //     1; // Valeur par défaut
//
//         // Rediriger vers la page de paiement si le mode de paiement est "carte"
//         if (selectedPaymentMethod!.toLowerCase() == "carte") {
//           // Aller à la page de paiement avec l'ID du rendez-vous
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PaiementPage(
//                 rendezVousId: rendezVousId,
//               ),
//             ),
//           );
//         } else {
//           // Afficher l'animation de succès pour les autres méthodes de paiement
//           await showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) => AlertDialog(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               content: SizedBox(
//                 height: 250,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircleAvatar(
//                       radius: 45,
//                       backgroundColor: Colors.green.shade100,
//                       child: Icon(
//                         Icons.check,
//                         size: 50,
//                         color: Colors.green,
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       "Réservation confirmée !",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     if (_isLocaleInitialized)
//                       Text(
//                         DateFormat('EEEE dd MMMM à HH:mm', 'fr_FR').format(selectedDateTime!),
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade700,
//                         ),
//                       )
//                     else
//                       Text(
//                         DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                     SizedBox(height: 30),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                       ),
//                       child: Text("Parfait !"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }
//       } else {
//         print("❌ Échec de la confirmation du rendez-vous");
//         _showCustomSnackBar("Erreur lors de la confirmation du RDV.");
//       }
//     } catch (e) {
//       print("❌ Exception lors de la confirmation: $e");
//       _showCustomSnackBar("Erreur de connexion au serveur.");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//
//
//   // Future<void> _confirmRdv() async {
//   //   final cartProvider = Provider.of<CartProvider>(context, listen: false);
//   //
//   //   // Vérifier si tous les champs requis sont remplis
//   //   if (currentUserId == null) {
//   //     _showCustomSnackBar("Erreur: ID utilisateur non trouvé. Veuillez vous reconnecter.");
//   //     return;
//   //   }
//   //
//   //   if (selectedDateTime == null) {
//   //     _showCustomSnackBar("Veuillez sélectionner une date et une heure pour votre rendez-vous.");
//   //     return;
//   //   }
//   //
//   //   if (selectedPaymentMethod == null) {
//   //     _showCustomSnackBar("Veuillez sélectionner une méthode de paiement.");
//   //     return;
//   //   }
//   //
//   //   if (cartProvider.cartItems.isEmpty) {
//   //     _showCustomSnackBar("Votre panier est vide. Veuillez sélectionner au moins un service.");
//   //     return;
//   //   }
//   //
//   //   setState(() => isLoading = true);
//   //
//   //   try {
//   //     // Vibration de confirmation
//   //     HapticFeedback.mediumImpact();
//   //
//   //     print("🔄 Envoi de la réservation: user=$currentUserId, date=${selectedDateTime.toString()}, paiement=$selectedPaymentMethod");
//   //
//   //     final success = await cartProvider.envoyerReservation(
//   //       userId: currentUserId!,
//   //       dateHeure: selectedDateTime!,
//   //       methodePaiement: selectedPaymentMethod!,
//   //     );
//   //
//   //     if (success) {
//   //       print("✅ Réservation confirmée avec succès");
//   //
//   //       // Rediriger vers la page de paiement si le mode de paiement est "carte"
//   //       if (selectedPaymentMethod!.toLowerCase() == "carte") {
//   //         // Aller à la page de paiement
//   //         Navigator.push(
//   //           context,
//   //           MaterialPageRoute(builder: (context) => PaiementPage()),
//   //         );
//   //       } else {
//   //         // Afficher l'animation de succès pour les autres méthodes de paiement
//   //         await showDialog(
//   //           context: context,
//   //           barrierDismissible: false,
//   //           builder: (context) => AlertDialog(
//   //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//   //             content: Container(
//   //               height: 250,
//   //               child: Column(
//   //                 mainAxisSize: MainAxisSize.min,
//   //                 mainAxisAlignment: MainAxisAlignment.center,
//   //                 children: [
//   //                   CircleAvatar(
//   //                     radius: 45,
//   //                     backgroundColor: Colors.green.shade100,
//   //                     child: Icon(
//   //                       Icons.check,
//   //                       size: 50,
//   //                       color: Colors.green,
//   //                     ),
//   //                   ),
//   //                   SizedBox(height: 20),
//   //                   Text(
//   //                     "Réservation confirmée !",
//   //                     style: TextStyle(
//   //                       fontSize: 18,
//   //                       fontWeight: FontWeight.bold,
//   //                     ),
//   //                   ),
//   //                   SizedBox(height: 10),
//   //                   if (_isLocaleInitialized)
//   //                     Text(
//   //                       DateFormat('EEEE dd MMMM à HH:mm', 'fr_FR').format(selectedDateTime!),
//   //                       style: TextStyle(
//   //                         fontSize: 16,
//   //                         color: Colors.grey.shade700,
//   //                       ),
//   //                     )
//   //                   else
//   //                     Text(
//   //                       DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
//   //                       style: TextStyle(
//   //                         fontSize: 16,
//   //                         color: Colors.grey.shade700,
//   //                       ),
//   //                     ),
//   //                   SizedBox(height: 30),
//   //                   ElevatedButton(
//   //                     onPressed: () {
//   //                       Provider.of<CartProvider>(context, listen: false).clearCartFromServer(currentUserId!);
//   //                       Navigator.pop(context);
//   //                       Navigator.pop(context);
//   //                     },
//   //                     style: ElevatedButton.styleFrom(
//   //                       backgroundColor: Colors.green,
//   //                       padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//   //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//   //                     ),
//   //                     child: Text("Parfait !"),
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //           ),
//   //         );
//   //       }
//   //     } else {
//   //       print("❌ Échec de la confirmation du rendez-vous");
//   //       _showCustomSnackBar("Erreur lors de la confirmation du RDV.");
//   //     }
//   //   } catch (e) {
//   //     print("❌ Exception lors de la confirmation: $e");
//   //     _showCustomSnackBar("Erreur de connexion au serveur.");
//   //   } finally {
//   //     setState(() => isLoading = false);
//   //   }
//   // }
//
//
//
//
//   // Future<void> _confirmRdv() async {
//   //   final cartProvider = Provider.of<CartProvider>(context, listen: false);
//   //
//   //   // Vérifier si tous les champs requis sont remplis
//   //   if (currentUserId == null) {
//   //     _showCustomSnackBar("Erreur: ID utilisateur non trouvé. Veuillez vous reconnecter.");
//   //     return;
//   //   }
//   //
//   //   if (selectedDateTime == null) {
//   //     _showCustomSnackBar("Veuillez sélectionner une date et une heure pour votre rendez-vous.");
//   //     return;
//   //   }
//   //
//   //   if (selectedPaymentMethod == null) {
//   //     _showCustomSnackBar("Veuillez sélectionner une méthode de paiement.");
//   //     return;
//   //   }
//   //
//   //   if (cartProvider.cartItems.isEmpty) {
//   //     _showCustomSnackBar("Votre panier est vide. Veuillez sélectionner au moins un service.");
//   //     return;
//   //   }
//   //
//   //   setState(() => isLoading = true);
//   //
//   //   try {
//   //     // Vibration de confirmation
//   //     HapticFeedback.mediumImpact();
//   //
//   //     print("🔄 Envoi de la réservation: user=$currentUserId, date=${selectedDateTime.toString()}, paiement=$selectedPaymentMethod");
//   //
//   //     final success = await cartProvider.envoyerReservation(
//   //       userId: currentUserId!,
//   //       dateHeure: selectedDateTime!,
//   //       methodePaiement: selectedPaymentMethod!,
//   //     );
//   //
//   //     if (success) {
//   //       print("✅ Réservation confirmée avec succès");
//   //       // Animation de succès
//   //       await showDialog(
//   //         context: context,
//   //         barrierDismissible: false,
//   //         builder: (context) => AlertDialog(
//   //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//   //           content: Container(
//   //             height: 250,
//   //             child: Column(
//   //               mainAxisSize: MainAxisSize.min,
//   //               mainAxisAlignment: MainAxisAlignment.center,
//   //               children: [
//   //                 CircleAvatar(
//   //                   radius: 45,
//   //                   backgroundColor: Colors.green.shade100,
//   //                   child: Icon(
//   //                     Icons.check,
//   //                     size: 50,
//   //                     color: Colors.green,
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 20),
//   //                 Text(
//   //                   "Réservation confirmée !",
//   //                   style: TextStyle(
//   //                     fontSize: 18,
//   //                     fontWeight: FontWeight.bold,
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 10),
//   //                 if (_isLocaleInitialized)
//   //                   Text(
//   //                     DateFormat('EEEE dd MMMM à HH:mm', 'fr_FR').format(selectedDateTime!),
//   //                     style: TextStyle(
//   //                       fontSize: 16,
//   //                       color: Colors.grey.shade700,
//   //                     ),
//   //                   )
//   //                 else
//   //                   Text(
//   //                     DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
//   //                     style: TextStyle(
//   //                       fontSize: 16,
//   //                       color: Colors.grey.shade700,
//   //                     ),
//   //                   ),
//   //                 SizedBox(height: 30),
//   //                 ElevatedButton(
//   //                   onPressed: () {
//   //                     Provider.of<CartProvider>(context, listen: false).clearCartFromServer(currentUserId!);
//   //                     Navigator.pop(context);
//   //                     Navigator.pop(context);
//   //                   },
//   //                   style: ElevatedButton.styleFrom(
//   //                     backgroundColor: Colors.green,
//   //                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//   //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//   //                   ),
//   //                   child: Text("Parfait !"),
//   //                 ),
//   //                 // ElevatedButton(
//   //                 //   onPressed: () {
//   //                 //     Provider.of<CartProvider>(context, listen: false).clearCart();
//   //                 //     Navigator.pop(context);
//   //                 //     Navigator.pop(context);
//   //                 //   },
//   //                 //   style: ElevatedButton.styleFrom(
//   //                 //     backgroundColor: Colors.green,
//   //                 //     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//   //                 //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//   //                 //   ),
//   //                 //   child: Text("Parfait !"),
//   //                 // ),
//   //               ],
//   //             ),
//   //           ),
//   //         ),
//   //       );
//   //     } else {
//   //       print("❌ Échec de la confirmation du rendez-vous");
//   //       _showCustomSnackBar("Erreur lors de la confirmation du RDV.");
//   //     }
//   //   } catch (e) {
//   //     print("❌ Exception lors de la confirmation: $e");
//   //     _showCustomSnackBar("Erreur de connexion au serveur.");
//   //   } finally {
//   //     setState(() => isLoading = false);
//   //   }
//   // }
//
//   // Future<void> _confirmRdv() async {
//   //   final cartProvider = Provider.of<CartProvider>(context, listen: false);
//   //
//   //   if (currentUserId == null ||
//   //       selectedDateTime == null ||
//   //       selectedPaymentMethod == null ||
//   //       cartProvider.cartItems.isEmpty) {
//   //     _showCustomSnackBar("Veuillez remplir tous les champs et sélectionner des services.");
//   //     return;
//   //   }
//   //
//   //   setState(() => isLoading = true);
//   //
//   //   try {
//   //     // Vibration de confirmation
//   //     HapticFeedback.mediumImpact();
//   //
//   //     print("🔄 Envoi de la réservation: user=$currentUserId, date=${selectedDateTime.toString()}, paiement=$selectedPaymentMethod");
//   //
//   //     final success = await cartProvider.envoyerReservation(
//   //       userId: currentUserId!,
//   //       dateHeure: selectedDateTime!,
//   //       methodePaiement: selectedPaymentMethod!,
//   //     );
//   //
//   //     if (success) {
//   //       print("✅ Réservation confirmée avec succès");
//   //       // Animation de succès
//   //       await showDialog(
//   //         context: context,
//   //         barrierDismissible: false,
//   //         builder: (context) => AlertDialog(
//   //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//   //           content: Container(
//   //             height: 250,
//   //             child: Column(
//   //               mainAxisSize: MainAxisSize.min,
//   //               mainAxisAlignment: MainAxisAlignment.center,
//   //               children: [
//   //                 CircleAvatar(
//   //                   radius: 45,
//   //                   backgroundColor: Colors.green.shade100,
//   //                   child: Icon(
//   //                     Icons.check,
//   //                     size: 50,
//   //                     color: Colors.green,
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 20),
//   //                 Text(
//   //                   "Réservation confirmée !",
//   //                   style: TextStyle(
//   //                     fontSize: 18,
//   //                     fontWeight: FontWeight.bold,
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 10),
//   //                 if (_isLocaleInitialized)
//   //                   Text(
//   //                     DateFormat('EEEE dd MMMM à HH:mm', 'fr_FR').format(selectedDateTime!),
//   //                     style: TextStyle(
//   //                       fontSize: 16,
//   //                       color: Colors.grey.shade700,
//   //                     ),
//   //                   )
//   //                 else
//   //                   Text(
//   //                     DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
//   //                     style: TextStyle(
//   //                       fontSize: 16,
//   //                       color: Colors.grey.shade700,
//   //                     ),
//   //                   ),
//   //                 SizedBox(height: 30),
//   //                 ElevatedButton(
//   //                   onPressed: () {
//   //                     Navigator.pop(context);
//   //                     Navigator.pop(context);
//   //                   },
//   //                   style: ElevatedButton.styleFrom(
//   //                     backgroundColor: Colors.green,
//   //                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//   //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//   //                   ),
//   //                   child: Text("Parfait !"),
//   //                 ),
//   //               ],
//   //             ),
//   //           ),
//   //         ),
//   //       );
//   //     } else {
//   //       print("❌ Échec de la confirmation du rendez-vous");
//   //       _showCustomSnackBar("Erreur lors de la confirmation du RDV.");
//   //     }
//   //   } catch (e) {
//   //     print("❌ Exception lors de la confirmation: $e");
//   //     _showCustomSnackBar("Erreur de connexion au serveur.");
//   //   } finally {
//   //     setState(() => isLoading = false);
//   //   }
//   // }
//
//   //------------------------------------
//
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//
//     return Scaffold(
//         key: _scaffoldKey,
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//           title: Text(
//             "Confirmation RDV",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: Colors.orange.shade700,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//           ),
//           centerTitle: true,
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back_ios_rounded),
//             onPressed: () => Navigator.pop(context),
//           ),
//           actions: [
//             // Bouton de rechargement des disponibilités
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: _rechargerDisponibilites,
//               tooltip: "Recharger les disponibilités",
//             ),
//           ],
//         ),
//         body: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Colors.orange.shade50, Colors.white],
//               ),
//             ),
//             child: SafeArea(
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: Stack(
//                     children: [
//                     SingleChildScrollView(
//                     physics: BouncingScrollPhysics(),
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isSmallScreen ? 16 : screenWidth * 0.1,
//                   vertical: 16,
//                 ),
//                 child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                 // En-tête animé
//                 Center(
//                 child: Container(
//                 margin: EdgeInsets.only(bottom: 20),
//                 child: AnimatedTextKit(
//                   animatedTexts: [
//                     TypewriterAnimatedText(
//                       'Réservez votre moment bien-être',
//                       textStyle: TextStyle(
//                         fontSize: isSmallScreen ? 18 : 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.deepOrange.shade800,
//                       ),
//                       speed: Duration(milliseconds: 80),
//                     ),
//                   ],
//                   totalRepeatCount: 1,
//                 ),
//               ),
//             ),
//
//             // Indicateur de chargement des disponibilités
//             if (isLoadingDisponibilites)
//         Container(
//     margin: EdgeInsets.only(bottom: 20),
//     padding: EdgeInsets.all(16),
//     decoration: BoxDecoration(
//     color: Colors.blue.shade50,
//     borderRadius: BorderRadius.circular(15),
//     border: Border.all(color: Colors.blue.shade200),
//     ),
//     child: Row(
//     children: [
//     SizedBox(
//     width: 20,
//     height: 20,
//     child: CircularProgressIndicator(
//     strokeWidth: 2,
//     valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//     ),
//     ),
//     SizedBox(width: 16),
//     Expanded(
//     child: Text(
//     "Chargement des disponibilités...",
//     style: TextStyle(
//     color: Colors.blue.shade800,
//     fontWeight: FontWeight.w500,
//     ),
//     ),
//     ),
//     ],
//     ),
//     ),
//
//     // Services sélectionnés
//     _buildSectionHeader("Services sélectionnés"),
//     if (cartProvider.cartItems.isEmpty)
//     _buildEmptyState("Aucun service sélectionné.")
//     else
//     ListView.builder(
//     shrinkWrap: true,
//     physics: NeverScrollableScrollPhysics(),
//     itemCount: cartProvider.cartItems.length,
//     itemBuilder: (context, index) {
//     final item = cartProvider.cartItems[index];
//     return Padding(
//     padding: const EdgeInsets.only(bottom: 10),
//     child: Container(
//     decoration: BoxDecoration(
//     gradient: LinearGradient(
//     colors: [Colors.white, Colors.orange.shade50],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     ),
//     borderRadius: BorderRadius.circular(15),
//     boxShadow: [
//     BoxShadow(
//     color: Colors.black.withOpacity(0.05),
//     blurRadius: 10,
//     offset: Offset(0, 4),
//     ),
//     ],
//     ),
//     child: ListTile(
//     contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     leading: CircleAvatar(
//     backgroundColor: Colors.deepOrange.shade100,
//     child: Icon(
//     Icons.spa_rounded,
//     color: Colors.deepOrange.shade700,
//     ),
//     ),
//     title: Text(
//     item.intitule,
//     style: TextStyle(
//     fontWeight: FontWeight.w600,
//     fontSize: 16,
//     ),
//     ),
//     subtitle: Padding(
//     padding: const EdgeInsets.only(top: 6.0),
//     child: Row(
//     children: [
//     Container(
//     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//     decoration: BoxDecoration(
//     color: Colors.green.shade50,
//     borderRadius: BorderRadius.circular(20),
//     border: Border.all(color: Colors.green.shade200),
//     ),
//     child: Text(
//     "${item.prix_final} €",
//     style: TextStyle(
//     color: Colors.green.shade700,
//     fontWeight: FontWeight.w600,
//     ),
//     ),
//     ),
//     SizedBox(width: 8),
//     Container(
//     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//     decoration: BoxDecoration(
//     color: Colors.blue.shade50,
//     borderRadius: BorderRadius.circular(20),
//     border: Border.all(color: Colors.blue.shade200),
//     ),
//     child: Row(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//     Icon(
//     Icons.access_time_rounded,
//     size: 14,
//     color: Colors.blue.shade700,
//     ),
//     SizedBox(width: 4),
//     Text(
//     "${item.temps} min",
//     style: TextStyle(
//     color: Colors.blue.shade700,
//     fontWeight: FontWeight.w600,
//     ),
//     ),
//     ],
//     ),
//     ),
//     ],
//     ),
//     ),
//     ),
//     ),
//     );
//     },
//     ),
//
//     SizedBox(height: 25),
//
//     // Date et heure
//     _buildSectionHeader("Date et heure"),
//     GestureDetector(
//     onTap: _pickDateTime,
//     child: Container(
//     margin: EdgeInsets.only(bottom: 16),
//     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//     decoration: BoxDecoration(
//     gradient: LinearGradient(
//     colors: selectedDateTime != null
//     ? [Colors.orange.shade200, Colors.orange.shade100]
//         : [Colors.grey.shade200, Colors.grey.shade100],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     ),
//     borderRadius: BorderRadius.circular(15),
//     boxShadow: [
//     BoxShadow(
//     color: Colors.black.withOpacity(0.05),
//     blurRadius: 10,
//     offset: Offset(0, 4),
//     ),
//     ],
//     ),
//     child: Row(
//     children: [
//     Container(
//     padding: EdgeInsets.all(12),
//     decoration: BoxDecoration(
//     color: Colors.white,
//     shape: BoxShape.circle,
//     ),
//     child: Icon(
//     Icons.calendar_today_rounded,
//     color: selectedDateTime != null ? Colors.orange.shade700 : Colors.grey,
//     size: 28,
//     ),
//     ),
//     SizedBox(width: 16),
//     Expanded(
//     child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//     Text(
//     selectedDateTime == null ? "Sélectionner la date et l'heure" : "Rendez-vous prévu",
//     style: TextStyle(
//     color: Colors.grey.shade800,
//     fontWeight: FontWeight.w600,
//     fontSize: 16,
//     ),
//     ),
//     if (selectedDateTime != null)
//     Padding(
//     padding: const EdgeInsets.only(top: 4.0),
//     child: _isLocaleInitialized
//     ? Text(
//     DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR').format(selectedDateTime!),
//     style: TextStyle(
//     color: Colors.orange.shade800,
//     fontWeight: FontWeight.bold,
//     fontSize: 15,
//     ),
//     )
//         : Text(
//     DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
//     style: TextStyle(
//     color: Colors.orange.shade800,
//     fontWeight: FontWeight.bold,
//     fontSize: 15,
//     ),
//     ),
//     ),
//     ],
//     ),
//     ),
//     Icon(
//     Icons.arrow_forward_ios_rounded,
//     color: Colors.grey,
//     size: 16,
//     ),
//     ],
//     ),
//     ),
//     ),
//
//     // Méthode de paiement
//     _buildSectionHeader("Méthode de paiement"),
//     Container(
//     margin: EdgeInsets.only(bottom: 25),
//     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
//     decoration: BoxDecoration(
//     color: Colors.white,
//     borderRadius: BorderRadius.circular(15),
//     boxShadow: [
//     BoxShadow(
//     color: Colors.black.withOpacity(0.05),
//     blurRadius: 10,
//     offset: Offset(0, 4),
//     ),
//     ],
//     ),
//     child: DropdownButtonFormField<String>(
//     decoration: InputDecoration(
//     prefixIcon: Icon(
//     Icons.payment_rounded,
//     color: Colors.blue.shade700,
//     ),
//     border: InputBorder.none,
//     ),
//       hint: Text("Choisir une méthode de paiement"),
//       icon: Icon(Icons.arrow_drop_down_circle_outlined),
//       items: paymentMethods.map((methode) {
//         IconData icon = Icons.credit_card;
//         Color iconColor = Colors.purple;
//
//         if (methode.toLowerCase() == "cash") {
//           icon = Icons.payments_outlined;
//           iconColor = Colors.green;
//         } else if (methode.toLowerCase() == "paypal") {
//           icon = Icons.account_balance_wallet_outlined;
//           iconColor = Colors.blue;
//         }
//
//         return DropdownMenuItem<String>(
//           value: methode.toLowerCase(),
//           child: Row(
//             children: [
//               Icon(icon, color: iconColor),
//               SizedBox(width: 12),
//               Text(methode),
//             ],
//           ),
//         );
//       }).toList(),
//       onChanged: (value) {
//         setState(() => selectedPaymentMethod = value);
//         HapticFeedback.selectionClick();
//       },
//     ),
//     ),
//
//                       // Bouton de confirmation
//                       AnimatedContainer(
//                         duration: Duration(milliseconds: 300),
//                         height: 55,
//                         width: double.infinity,
//                         margin: EdgeInsets.symmetric(vertical: 10),
//                         child: isLoading
//                             ? Center(
//                           child: CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
//                           ),
//                         )
//                             : ElevatedButton(
//                           onPressed: _confirmRdv,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green.shade600,
//                             foregroundColor: Colors.white,
//                             elevation: 5,
//                             shadowColor: Colors.green.shade200,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.check_circle_outline, size: 24),
//                               SizedBox(width: 12),
//                               Text(
//                                 "CONFIRMER LE RENDEZ-VOUS",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: 1,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       // Prix total (ajouté comme information complémentaire)
//                       if (cartProvider.cartItems.isNotEmpty)
//                         Container(
//                           margin: EdgeInsets.only(top: 20),
//                           padding: EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.green.shade50,
//                             borderRadius: BorderRadius.circular(15),
//                             border: Border.all(color: Colors.green.shade200),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Total à payer",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey.shade800,
//                                 ),
//                               ),
//                               Text(
//                                 "${cartProvider.totalPrice.toStringAsFixed(2)} €",
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.green.shade800,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                 ),
//                     ),
//
//                       // Overlay de chargement global
//                       if (isLoading && !isLoadingDisponibilites)
//                         Container(
//                           color: Colors.black.withOpacity(0.3),
//                           child: Center(
//                             child: Container(
//                               padding: EdgeInsets.all(20),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   CircularProgressIndicator(
//                                     valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
//                                   ),
//                                   SizedBox(height: 16),
//                                   Text(
//                                     "Chargement en cours...",
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.grey.shade800,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                 ),
//               ),
//             ),
//         ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Row(
//         children: [
//           Container(
//             width: 4,
//             height: 18,
//             decoration: BoxDecoration(
//               color: Colors.deepOrange,
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           SizedBox(width: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(String message) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(vertical: 30),
//       margin: EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: Colors.grey.shade300, width: 1),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.shopping_basket_outlined,
//             size: 40,
//             color: Colors.grey,
//           ),
//           SizedBox(height: 10),
//           Text(
//             message,
//             style: TextStyle(
//               color: Colors.grey.shade700,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }