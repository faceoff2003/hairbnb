// lib/pages/salon_geolocalisation/modals/show_salon_details_modal.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/salon_details_geo.dart';
import '../../../models/public_salon_details.dart';
import '../../../public_salon_details/api/PublicSalonDetailsApi.dart';
import '../../../public_salon_details/modals/show_horaires_modal.dart';
import '../../../public_salon_details/services/favorites_services.dart';
import '../../chat/chat_page.dart';
import '../itineraire_page.dart';
import 'show_salon_services_modal_service/show_salon_services_modal_service.dart';

class SalonDetailsModal extends StatefulWidget {
  final CurrentUser currentUser;
  final SalonDetailsForGeo salon;
  final Function(SalonDetailsForGeo) calculateDistance;
  final Color primaryColor;
  final Color accentColor;

  const SalonDetailsModal({
    super.key,
    required this.salon,
    required this.calculateDistance,
    required this.primaryColor,
    required this.accentColor,
    required this.currentUser,
  });

  @override
  State<SalonDetailsModal> createState() => _SalonDetailsModalState();
}

class _SalonDetailsModalState extends State<SalonDetailsModal> {
  bool isLoadingDetails = false;
  PublicSalonDetails? salonDetails;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _chargerDetailsComplets();
    _verifierFavori();
  }

  /// ✅ NOUVEAU : Récupérer les détails complets du salon (avec horaires)
  Future<void> _chargerDetailsComplets() async {
    setState(() {
      isLoadingDetails = true;
    });

    try {
      final details = await PublicSalonDetailsApi.getSalonDetails(widget.salon.idTblSalon);
      setState(() {
        salonDetails = details;
      });
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur chargement détails salon: $e");
      }
      // Ne pas afficher d'erreur, les fonctionnalités de base restent disponibles
    } finally {
      setState(() {
        isLoadingDetails = false;
      });
    }
  }

  Future<void> _toggleFavori() async {
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final newState = await FavoritesService.toggleFavorite(
        widget.currentUser.idTblUser,
        widget.salon.idTblSalon,
      );

      setState(() {
        _isFavorite = newState;
      });

      // Message centré à la place du SnackBar
      _showFavoriteDialog(_isFavorite);

    } catch (e) {
      if (kDebugMode) {
        print('Erreur toggle favori: $e');
      }
      _showErrorDialog();
    } finally {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  void _showFavoriteDialog(bool isFavorite) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isFavorite ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.heart_broken,
                    color: isFavorite ? Colors.red : Colors.orange,
                    size: 30,
                  ),
                ),
                SizedBox(height: 16),

                // Message
                Text(
                  isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isFavorite ? Colors.red : Colors.orange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isFavorite
                      ? 'Le salon a été ajouté à vos favoris'
                      : 'Le salon a été retiré de vos favoris',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),

                // Bouton OK
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFavorite ? Colors.red : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.red, size: 50),
                SizedBox(height: 16),
                Text(
                  'Erreur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Impossible de mettre à jour les favoris',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  // Future<void> _toggleFavori() async {
  //   setState(() {
  //     _isLoadingFavorite = true;
  //   });
  //
  //   try {
  //     final newState = await FavoritesService.toggleFavorite(
  //       widget.currentUser.idTblUser,
  //       widget.salon.idTblSalon,
  //     );
  //
  //     setState(() {
  //       _isFavorite = newState;
  //     });
  //
  //     // Afficher un message de confirmation
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //             _isFavorite
  //                 ? '💖 Salon ajouté aux favoris'
  //                 : '💔 Salon retiré des favoris'
  //         ),
  //         backgroundColor: _isFavorite ? Colors.green : Colors.orange,
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   } catch (e) {
  //     print('Erreur toggle favori: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Erreur lors de la mise à jour des favoris'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   } finally {
  //     setState(() {
  //       _isLoadingFavorite = false;
  //     });
  //   }
  // }

  /// ✅ NOUVEAU : Afficher les horaires du salon
  void _afficherHoraires() {
    if (salonDetails?.horaires != null && salonDetails!.horaires!.isNotEmpty) {
      showHorairesModal(context, salonDetails!.horaires!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Horaires non disponibles pour ce salon"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// ✅ NOUVEAU : Appeler le salon
  void _appelerSalon() {
    final numeroTelephone = salonDetails?.coiffeuse.idTblUser.numeroTelephone;

    if (numeroTelephone != null && numeroTelephone.isNotEmpty) {
      _lancerAppel(numeroTelephone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Numéro de téléphone non disponible"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Lancer l'appel téléphonique
  Future<void> _lancerAppel(String numeroTelephone) async {
    final url = 'tel:$numeroTelephone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Impossible d'ouvrir l'application téléphone"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ NOUVEAU : Afficher les évaluations
  void _afficherEvaluations() {
    if (salonDetails != null && salonDetails!.avis.isNotEmpty) {
      _showEvaluationsModal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Aucune évaluation disponible pour ce salon"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// ✅ NOUVEAU : Modal pour afficher les évaluations
  void _showEvaluationsModal() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Évaluations',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        salonDetails!.noteMoyenne.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                      Text(
                        ' (${salonDetails!.nombreAvis} avis)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: salonDetails!.avis.length,
                itemBuilder: (context, index) {
                  final avis = salonDetails!.avis[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: widget.primaryColor.withAlpha((255 * 0.1).round()),
                              child: Text(
                                avis.clientNom.isNotEmpty ? avis.clientNom[0].toUpperCase() : 'A',
                                style: TextStyle(
                                  color: widget.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    avis.clientNom,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    avis.dateFormat,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: List.generate(5, (i) => Icon(
                                Icons.star,
                                size: 16,
                                color: i < avis.note ? Colors.amber : Colors.grey[300],
                              )),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          avis.commentaire,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = widget.salon.distance;
    final coiffeuses = widget.salon.coiffeusesDetails;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: EdgeInsets.only(top: 15, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSalonHeader(),
                    SizedBox(height: 20),
                    _buildSalonInfo(distance),
                    SizedBox(height: 20),
                    if (coiffeuses.isNotEmpty) _buildTeamSection(coiffeuses),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildSalonHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.primaryColor.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack( // 👈 NOUVEAU : Stack pour superposer le bouton
        children: [
          // Image du salon (existant)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.salon.hasLogo
                ? Image.network(
              widget.salon.getLogoUrl("https://www.hairbnb.site") ?? "",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (ctx, obj, st) => _buildDefaultSalonIcon(),
            )
                : _buildDefaultSalonIcon(),
          ),

          // Bouton cœur en haut à droite
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoadingFavorite
                  ? Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                  ),
                ),
              )
                  : FutureBuilder<bool>(
                future: FavoritesService.isSalonFavorite(
                  widget.currentUser.idTblUser,
                  widget.salon.idTblSalon,
                ),
                builder: (context, snapshot) {
                  // Si on a déjà une réponse locale, l'utiliser
                  bool isCurrentlyFavorite = snapshot.hasData ? snapshot.data! : _isFavorite;

                  return IconButton(
                    onPressed: _toggleFavori,
                    icon: Icon(
                      isCurrentlyFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isCurrentlyFavorite ? Colors.red : Colors.grey[600],
                      size: 24,
                    ),
                    padding: EdgeInsets.all(8),
                  );
                },
              ),
            ),
          ),
          // Positioned(
          //   top: 12,
          //   right: 12,
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       shape: BoxShape.circle,
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.2),
          //           blurRadius: 6,
          //           offset: Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: _isLoadingFavorite
          //         ? Padding(
          //       padding: EdgeInsets.all(12),
          //       child: SizedBox(
          //         width: 20,
          //         height: 20,
          //         child: CircularProgressIndicator(
          //           strokeWidth: 2,
          //           valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
          //         ),
          //       ),
          //     )
          //         : IconButton(
          //       onPressed: _toggleFavori,
          //       icon: Icon(
          //         _isFavorite ? Icons.favorite : Icons.favorite_border,
          //         color: _isFavorite ? Colors.red : Colors.grey[600],
          //         size: 24,
          //       ),
          //       padding: EdgeInsets.all(8),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildSalonHeader() {
  //   return Container(
  //     height: 200,
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: widget.primaryColor.withAlpha((255 * 0.1).round()),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: widget.salon.hasLogo
  //         ? ClipRRect(
  //       borderRadius: BorderRadius.circular(16),
  //       child: Image.network(
  //         widget.salon.getLogoUrl("https://www.hairbnb.site") ?? "",
  //         fit: BoxFit.cover,
  //         errorBuilder: (ctx, obj, st) => _buildDefaultSalonIcon(),
  //       ),
  //     )
  //         : _buildDefaultSalonIcon(),
  //   );
  // }

  Widget _buildDefaultSalonIcon() {
    return Center(
      child: Icon(
        Icons.spa,
        color: widget.primaryColor,
        size: 60,
      ),
    );
  }

  // 🔧 MODIFICATION COMPLÈTE: Méthode _buildSalonInfo mise à jour
  Widget _buildSalonInfo(double distance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom du salon
        Text(
          widget.salon.nom,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: widget.primaryColor,
          ),
        ),
        SizedBox(height: 8),

        // Slogan
        if (widget.salon.slogan != null && widget.salon.slogan!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.salon.slogan!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),

        // Distance
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.accentColor.withAlpha((255 * 0.2).round()),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: widget.accentColor, size: 18),
              SizedBox(width: 6),
              Text(
                "${widget.salon.distanceFormatee} de vous",
                style: TextStyle(
                  fontSize: 14,
                  color: widget.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // ✅ NOUVEAU: Adresse complète
        if (salonDetails?.adresse != null && salonDetails!.adresse!.isNotEmpty)
          _buildDetailCard(
            icon: Icons.location_city,
            title: "Adresse",
            content: salonDetails!.adresse!,
            color: Colors.blue,
          ),

        // ✅ NOUVEAU: Description du salon
        if (salonDetails?.aPropos != null && salonDetails!.aPropos!.isNotEmpty)
          _buildDetailCard(
            icon: Icons.info_outline,
            title: "À propos du salon",
            content: salonDetails!.aPropos!,
            color: Colors.green,
            isExpandable: true,
          ),

        // ✅ NOUVEAU: Dénomination sociale/nom commercial
        if (salonDetails?.coiffeuse.nomCommercial != null && salonDetails!.coiffeuse.nomCommercial!.isNotEmpty)
          _buildDetailCard(
            icon: Icons.business,
            title: "Dénomination sociale",
            content: salonDetails!.coiffeuse.nomCommercial!,
            color: Colors.purple,
          ),

        // ✅ NOUVEAU: Numéro de TVA
        if (salonDetails?.numeroTva != null && salonDetails!.numeroTva!.isNotEmpty)
          _buildDetailCard(
            icon: Icons.receipt_long,
            title: "N° TVA",
            content: salonDetails!.numeroTva!,
            color: Colors.orange,
          ),

        SizedBox(height: 20),

        // ✅ NOUVEAU: Photos du salon
        if (salonDetails?.images != null && salonDetails!.images.isNotEmpty)
          _buildSalonPhotos(),

        SizedBox(height: 20),

        // Informations existantes (horaires, contact, évaluations)
        _buildInfoTiles(),

        // ✅ NOUVEAU: Section avis intégrée
        _buildAvisSection(),
      ],
    );
  }

  /// ✅ NOUVELLE SECTION: Affichage des avis directement dans le modal
  Widget _buildAvisSection() {
    if (salonDetails == null || salonDetails!.avis.isEmpty) {
      return SizedBox.shrink(); // Ne rien afficher s'il n'y a pas d'avis
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),

        // 🌟 En-tête section avis
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.star, color: Colors.amber, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Avis clients",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star,
                          size: 16,
                          color: i < salonDetails!.noteMoyenne.round()
                              ? Colors.amber
                              : Colors.grey[300],
                        )),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${salonDetails!.noteMoyenne.toStringAsFixed(1)} sur 5",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        " • ${salonDetails!.nombreAvis} avis",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (salonDetails!.avis.length > 3)
              TextButton(
                onPressed: _afficherEvaluations,
                child: Text(
                  "Voir tous",
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 16),

        // 📋 Liste des avis (affichage des 3 premiers)
        ...salonDetails!.avis.take(3).map((avis) => _buildAvisCard(avis)),

        // 👀 Bouton "Voir plus" si il y a plus de 3 avis
        if (salonDetails!.avis.length > 3)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _afficherEvaluations,
                icon: Icon(Icons.visibility),
                label: Text("Voir les ${salonDetails!.avis.length - 3} autres avis"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.primaryColor,
                  side: BorderSide(color: widget.primaryColor.withOpacity(0.3)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 🎨 Carte individuelle d'avis
  Widget _buildAvisCard(Avis avis) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 En-tête client + note
          Row(
            children: [
              // Avatar client
              CircleAvatar(
                radius: 18,
                backgroundColor: widget.primaryColor.withOpacity(0.1),
                child: Text(
                  avis.clientNom.isNotEmpty
                      ? avis.clientNom[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: 12),

              // Nom + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avis.clientNom.isNotEmpty ? avis.clientNom : "Client anonyme",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      avis.dateFormat,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Note avec étoiles
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBackgroundColorForNote(avis.note),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      avis.note.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 💬 Commentaire
          Text(
            avis.commentaire,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 🎨 Couleur de fond selon la note
  Color _getBackgroundColorForNote(int note) {
    switch (note) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


// Carte pour afficher les détails
  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    bool isExpandable = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          isExpandable && content.length > 150
              ? _buildExpandableText(content)
              : Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

// ✅ NOUVELLE MÉTHODE: Texte extensible pour les longues descriptions
  Widget _buildExpandableText(String text) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isExpanded = false;
        final shortText = text.length > 150 ? "${text.substring(0, 150)}..." : text;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExpanded ? text : shortText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (text.length > 150)
              TextButton(
                onPressed: () => setState(() => isExpanded = !isExpanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isExpanded ? "Voir moins" : "Voir plus",
                  style: TextStyle(color: widget.primaryColor),
                ),
              ),
          ],
        );
      },
    );
  }

// ✅ NOUVELLE MÉTHODE: Galerie photos du salon
  Widget _buildSalonPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.photo_library, color: Colors.pink, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              "Photos du salon",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${salonDetails!.images.length} photo${salonDetails!.images.length > 1 ? 's' : ''}",
                style: TextStyle(
                  fontSize: 12,
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: salonDetails!.images.length,
            itemBuilder: (context, index) {
              final image = salonDetails!.images[index];
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    image.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  ///  Ajouter les actions aux tuiles
  Widget _buildInfoTiles() {
    return Column(
      children: [
        _buildInfoTile(
          icon: Icons.access_time,
          title: "Horaires",
          subtitle: isLoadingDetails
              ? "Chargement..."
              : (salonDetails?.horaires != null ? "Voir les disponibilités" : "Non disponibles"),
          onTap: isLoadingDetails ? null : _afficherHoraires,
          isEnabled: !isLoadingDetails && salonDetails?.horaires != null,
        ),
        SizedBox(height: 12),
        _buildInfoTile(
          icon: Icons.phone,
          title: "Contact",
          subtitle: isLoadingDetails
              ? "Chargement..."
              : (salonDetails?.coiffeuse.idTblUser.numeroTelephone != null ? "Appeler le salon" : "Non disponible"),
          onTap: isLoadingDetails ? null : _appelerSalon,
          isEnabled: !isLoadingDetails && salonDetails?.coiffeuse.idTblUser.numeroTelephone != null,
        ),
        SizedBox(height: 12),
        _buildInfoTile(
          icon: Icons.star,
          title: "Évaluations",
          subtitle: isLoadingDetails
              ? "Chargement..."
              : (salonDetails != null && salonDetails!.avis.isNotEmpty
              ? "${salonDetails!.noteMoyenne.toStringAsFixed(1)} ⭐ (${salonDetails!.nombreAvis} avis)"
              : "Aucun avis"),
          onTap: isLoadingDetails ? null : _afficherEvaluations,
          isEnabled: !isLoadingDetails && salonDetails != null && salonDetails!.avis.isNotEmpty,
        ),
      ],
    );
  }

  /// ✅ MODIFIÉ : Ajouter support pour onTap et état activé/désactivé
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled ? Colors.grey[200]! : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? widget.primaryColor.withAlpha((255 * 0.1).round())
                      : Colors.grey.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? widget.primaryColor : Colors.grey[400],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.black : Colors.grey[500],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16)
              else
                SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection(List<CoiffeuseDetailsForGeo> coiffeuses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "L'équipe du salon",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: widget.primaryColor,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.primaryColor.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${widget.salon.nombreCoiffeuses} membre${widget.salon.nombreCoiffeuses > 1 ? 's' : ''}",
                style: TextStyle(
                  fontSize: 12,
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...coiffeuses.map<Widget>((coiffeuse) => _buildTeamMember(coiffeuse)),
      ],
    );
  }

  // 🔧 CORRECTION : Méthode _buildTeamMember responsive
  Widget _buildTeamMember(CoiffeuseDetailsForGeo coiffeuse) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          // 🔧 PREMIÈRE LIGNE : Avatar + Nom + Badge propriétaire + Bouton chat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 25, // ✅ Réduit de 30 à 25 pour plus d'espace
                backgroundColor: coiffeuse.estProprietaire
                    ? widget.primaryColor.withAlpha((255 * 0.2).round())
                    : Colors.grey[200],
                child: Icon(
                  Icons.person,
                  color: coiffeuse.estProprietaire ? widget.primaryColor : Colors.grey[500],
                  size: 24, // ✅ Réduit de 28 à 24
                ),
              ),
              SizedBox(width: 12),

              // ✅ Expanded pour éviter le débordement
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom avec badge propriétaire sur la même ligne si possible
                    Row(
                      children: [
                        // ✅ Flexible pour permettre le wrap du nom
                        Flexible(
                          child: Text(
                            coiffeuse.nomComplet,
                            style: GoogleFonts.poppins(
                              fontSize: 16, // ✅ Réduit de 18 à 16
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),

                        // Badge propriétaire conditionnel
                        if (coiffeuse.estProprietaire) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withAlpha((255 * 0.2).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Propriétaire",
                              style: TextStyle(
                                fontSize: 10, // ✅ Réduit de 11 à 10
                                color: widget.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Nom commercial (si existe)
                    if (coiffeuse.nomCommercial != null && coiffeuse.nomCommercial!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        coiffeuse.affichageNom,
                        style: TextStyle(
                          fontSize: 12, // ✅ Réduit de 14 à 12
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),

              // Bouton chat
              Container(
                decoration: BoxDecoration(
                  color: widget.primaryColor.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  constraints: BoxConstraints(
                    minWidth: 40, // ✅ Taille minimale définie
                    minHeight: 40,
                  ),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: widget.primaryColor,
                    size: 18, // ✅ Réduit de 24 à 18
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          currentUser: widget.currentUser,
                          otherUserId: coiffeuse.uuid,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 🔧 DEUXIÈME LIGNE : Chips d'information dans un Wrap responsive
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              _buildInfoChip(
                icon: Icons.badge,
                label: coiffeuse.role,
                color: Colors.blue,
              ),
              _buildInfoChip(
                icon: Icons.work,
                label: coiffeuse.type,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

// 🔧 CORRECTION : Méthode _buildInfoChip plus compacte
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          // ✅ Texte flexible pour éviter le débordement
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10, // ✅ Réduit de 11 à 10
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCompact(CoiffeuseDetailsForGeo coiffeuse) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          // Avatar plus petit
          CircleAvatar(
            radius: 20,
            backgroundColor: coiffeuse.estProprietaire
                ? widget.primaryColor.withAlpha((255 * 0.2).round())
                : Colors.grey[200],
            child: Icon(
              Icons.person,
              color: coiffeuse.estProprietaire ? widget.primaryColor : Colors.grey[500],
              size: 20,
            ),
          ),
          SizedBox(width: 12),

          // Informations principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                Text(
                  coiffeuse.nomComplet,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),

                // Badges en ligne
                SizedBox(height: 4),
                Row(
                  children: [
                    if (coiffeuse.estProprietaire)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Propriétaire",
                          style: TextStyle(
                            fontSize: 9,
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (coiffeuse.estProprietaire) SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "${coiffeuse.role} • ${coiffeuse.type}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bouton chat compact
          Material(
            color: widget.primaryColor.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      currentUser: widget.currentUser,
                      otherUserId: coiffeuse.uuid,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: widget.primaryColor,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// 🔧 MISE À JOUR : Section équipe avec détection de taille d'écran
//   Widget _buildTeamSection(List<CoiffeuseDetailsForGeo> coiffeuses) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // Détection de la taille d'écran
//         final isSmallScreen = constraints.maxWidth < 400;
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // En-tête responsive
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     "L'équipe du salon",
//                     style: GoogleFonts.poppins(
//                       fontSize: isSmallScreen ? 18 : 20,
//                       fontWeight: FontWeight.w700,
//                       color: widget.primaryColor,
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                       horizontal: isSmallScreen ? 6 : 8,
//                       vertical: 4
//                   ),
//                   decoration: BoxDecoration(
//                     color: widget.primaryColor.withAlpha((255 * 0.1).round()),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     "${widget.salon.nombreCoiffeuses} membre${widget.salon.nombreCoiffeuses > 1 ? 's' : ''}",
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 10 : 12,
//                       color: widget.primaryColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//
//             // Liste des membres avec version appropriée
//             ...coiffeuses.map<Widget>((coiffeuse) =>
//             isSmallScreen
//                 ? _buildTeamMemberCompact(coiffeuse)
//                 : _buildTeamMember(coiffeuse)
//             ),
//           ],
//         );
//       },
//     );
//   }

  // Widget _buildTeamMember(CoiffeuseDetailsForGeo coiffeuse) {
  //   return Container(
  //     margin: EdgeInsets.only(bottom: 16),
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withAlpha((255 * 0.05).round()),
  //           blurRadius: 10,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //       border: Border.all(color: Colors.grey[100]!),
  //     ),
  //     child: Row(
  //       children: [
  //         CircleAvatar(
  //           radius: 30,
  //           backgroundColor: coiffeuse.estProprietaire
  //               ? widget.primaryColor.withAlpha((255 * 0.2).round())
  //               : Colors.grey[200],
  //           child: Icon(
  //             Icons.person,
  //             color: coiffeuse.estProprietaire ? widget.primaryColor : Colors.grey[500],
  //             size: 28,
  //           ),
  //         ),
  //         SizedBox(width: 16),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: Text(
  //                       coiffeuse.nomComplet,
  //                       style: GoogleFonts.poppins(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ),
  //                   if (coiffeuse.estProprietaire)
  //                     Container(
  //                       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //                       decoration: BoxDecoration(
  //                         color: widget.primaryColor.withAlpha((255 * 0.2).round()),
  //                         borderRadius: BorderRadius.circular(15),
  //                       ),
  //                       child: Text(
  //                         "Propriétaire",
  //                         style: TextStyle(
  //                           fontSize: 11,
  //                           color: widget.primaryColor,
  //                           fontWeight: FontWeight.w700,
  //                         ),
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //               SizedBox(height: 4),
  //               if (coiffeuse.nomCommercial != null && coiffeuse.nomCommercial!.isNotEmpty)
  //                 Text(
  //                   coiffeuse.affichageNom,
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: Colors.grey[600],
  //                     fontStyle: FontStyle.italic,
  //                   ),
  //                 ),
  //               SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   _buildInfoChip(
  //                     icon: Icons.badge,
  //                     label: coiffeuse.role,
  //                     color: Colors.blue,
  //                   ),
  //                   SizedBox(width: 8),
  //                   _buildInfoChip(
  //                     icon: Icons.work,
  //                     label: coiffeuse.type,
  //                     color: Colors.green,
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         Container(
  //           decoration: BoxDecoration(
  //             color: widget.primaryColor.withAlpha((255 * 0.1).round()),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: IconButton(
  //             icon: Icon(Icons.chat_bubble_outline, color: widget.primaryColor),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => ChatPage(
  //                     currentUser: widget.currentUser,
  //                     otherUserId: coiffeuse.uuid,
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildInfoChip({
  //   required IconData icon,
  //   required String label,
  //   required Color color,
  // }) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: color.withAlpha((255 * 0.1).round()),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, size: 12, color: color),
  //         SizedBox(width: 4),
  //         Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 11,
  //             color: color,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  Widget _buildActionButtons(BuildContext context) {
    CoiffeuseDetailsForGeo? contactPersonne = widget.salon.proprietaire;
    final coiffeuses = widget.salon.coiffeusesDetails;

    if (contactPersonne == null && coiffeuses.isNotEmpty) {
      contactPersonne = coiffeuses.first;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItinerairePage(
                      salon: widget.salon,
                      primaryColor: widget.primaryColor,
                      accentColor: widget.accentColor,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.directions),
              label: Text("Itinéraire"),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.accentColor,
                side: BorderSide(color: widget.accentColor),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                if (contactPersonne != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        currentUser: widget.currentUser,
                        otherUserId: contactPersonne!.uuid,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Aucun contact disponible pour ce salon."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(Icons.chat_bubble_outline),
              label: Text("Contacter"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // ✅ NOUVEAU : Le modal gère maintenant tout l'ajout au panier avec notifications centrées
                await SalonServicesModalService.afficherServicesModal(
                  context,
                  salon: widget.salon,
                  currentUser: widget.currentUser, // ✅ NOUVEAU : Passer currentUser
                  primaryColor: widget.primaryColor,
                  accentColor: widget.accentColor,
                );

                // ✅ Plus besoin de logique d'ajout au panier ici - le modal gère tout !
                if (kDebugMode) {
                  print("✅ Modal services fermé pour ${widget.salon.nom}");
                }
              },
              icon: Icon(Icons.date_range),
              label: Text("Services"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifierFavori() async {
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final isFavorite = await FavoritesService.isSalonFavorite(
          widget.currentUser.idTblUser,
          widget.salon.idTblSalon
      );
      setState(() {
        _isFavorite = isFavorite;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur vérification favori: $e');
      }
    } finally {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

}
