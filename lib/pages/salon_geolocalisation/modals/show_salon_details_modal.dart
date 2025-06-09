// lib/pages/salon_geolocalisation/modals/show_salon_details_modal.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/salon_details_geo.dart';
import '../../../models/public_salon_details.dart';
import '../../../public_salon_details/api/PublicSalonDetailsApi.dart';
import '../../../public_salon_details/modals/show_horaires_modal.dart';
import '../../../services/providers/cart_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _chargerDetailsComplets();
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
      child: widget.salon.hasLogo
          ? ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          widget.salon.getLogoUrl("https://www.hairbnb.site") ?? "",
          fit: BoxFit.cover,
          errorBuilder: (ctx, obj, st) => _buildDefaultSalonIcon(),
        ),
      )
          : _buildDefaultSalonIcon(),
    );
  }

  Widget _buildDefaultSalonIcon() {
    return Center(
      child: Icon(
        Icons.spa,
        color: widget.primaryColor,
        size: 60,
      ),
    );
  }

  // 🔧 CORRECTION COMPLÈTE: show_salon_details_modal.dart
// Remplacez la méthode _buildSalonInfo() par ceci pour afficher TOUTES les informations :

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
            isExpandable: true, // Pour les longs textes
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
      ],
    );
  }

// ✅ NOUVELLE MÉTHODE: Carte pour afficher les détails
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
        final shortText = text.length > 150 ? text.substring(0, 150) + "..." : text;

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
                child: Text(
                  isExpanded ? "Voir moins" : "Voir plus",
                  style: TextStyle(color: widget.primaryColor),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        Container(
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




  // Widget _buildSalonInfo(double distance) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         widget.salon.nom,
  //         style: GoogleFonts.poppins(
  //           fontSize: 28,
  //           fontWeight: FontWeight.w700,
  //           color: widget.primaryColor,
  //         ),
  //       ),
  //       SizedBox(height: 8),
  //       if (widget.salon.slogan != null && widget.salon.slogan!.isNotEmpty)
  //         Padding(
  //           padding: const EdgeInsets.only(bottom: 16),
  //           child: Text(
  //             widget.salon.slogan!,
  //             style: GoogleFonts.poppins(
  //               fontSize: 16,
  //               fontStyle: FontStyle.italic,
  //               color: Colors.grey[600],
  //             ),
  //           ),
  //         ),
  //       Container(
  //         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //         decoration: BoxDecoration(
  //           color: widget.accentColor.withAlpha((255 * 0.2).round()),
  //           borderRadius: BorderRadius.circular(25),
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(Icons.location_on, color: widget.accentColor, size: 18),
  //             SizedBox(width: 6),
  //             Text(
  //               "${widget.salon.distanceFormatee} de vous",
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 color: widget.accentColor,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       SizedBox(height: 20),
  //       _buildInfoTiles(),
  //     ],
  //   );
  // }

  /// ✅ MODIFIÉ : Ajouter les actions aux tuiles
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: coiffeuse.estProprietaire
                ? widget.primaryColor.withAlpha((255 * 0.2).round())
                : Colors.grey[200],
            child: Icon(
              Icons.person,
              color: coiffeuse.estProprietaire ? widget.primaryColor : Colors.grey[500],
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        coiffeuse.nomComplet,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (coiffeuse.estProprietaire)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Propriétaire",
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                if (coiffeuse.nomCommercial != null && coiffeuse.nomCommercial!.isNotEmpty)
                  Text(
                    coiffeuse.affichageNom,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.badge,
                      label: coiffeuse.role,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.work,
                      label: coiffeuse.type,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: widget.primaryColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: widget.primaryColor),
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
    );
  }

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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


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
                try {
                  // 🔄 Afficher le modal et récupérer les services sélectionnés
                  final selectedServices = await SalonServicesModalService.afficherServicesModal(
                    context,
                    salon: widget.salon,
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                  );

                  // ✅ Si des services ont été sélectionnés, les ajouter au panier
                  if (selectedServices != null && selectedServices.isNotEmpty) {
                    final cartProvider = Provider.of<CartProvider>(context, listen: false);

                    // 📦 Ajouter chaque service au panier via l'API
                    for (var service in selectedServices) {
                      await cartProvider.addToCart(service, widget.currentUser.idTblUser.toString());
                    }

                    // 🎯 SOLUTION 1: rootNavigator pour afficher AU-DESSUS du modal
                    final rootContext = Navigator.of(context, rootNavigator: true).context;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("✅ ${selectedServices.length} service(s) ajouté(s) au panier !"),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2), // Plus court pour pas gêner
                        action: SnackBarAction(
                          label: "Voir panier",
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.of(context).pop(); // Fermer modal détails seulement
                            Navigator.pushNamed(context, '/cart');
                          },
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.1, // Au-dessus du modal
                          left: 16,
                          right: 16,
                        ),
                      ),
                    );

                    print("✅ ${selectedServices.length} services ajoutés au panier depuis le modal détails pour ${widget.salon.nom}");
                  }
                } catch (e) {
                  // ❌ Gestion des erreurs (modal reste ouvert)
                  print("❌ Erreur lors de l'ajout au panier depuis le modal détails : $e");

                  final rootContext = Navigator.of(context, rootNavigator: true).context;
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text("Erreur lors de l'ajout au panier. Veuillez réessayer."),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.1,
                        left: 16,
                        right: 16,
                      ),
                    ),
                  );
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

  // Widget _buildActionButtons(BuildContext context) {
  //   CoiffeuseDetailsForGeo? contactPersonne = widget.salon.proprietaire;
  //   final coiffeuses = widget.salon.coiffeusesDetails;
  //
  //   if (contactPersonne == null && coiffeuses.isNotEmpty) {
  //     contactPersonne = coiffeuses.first;
  //   }
  //
  //   return Container(
  //     padding: EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withAlpha((255 * 0.05).round()),
  //           blurRadius: 10,
  //           offset: Offset(0, -5),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: OutlinedButton.icon(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             icon: Icon(Icons.directions),
  //             label: Text("Itinéraire"),
  //             style: OutlinedButton.styleFrom(
  //               foregroundColor: widget.accentColor,
  //               side: BorderSide(color: widget.accentColor),
  //               padding: EdgeInsets.symmetric(vertical: 16),
  //             ),
  //           ),
  //         ),
  //         SizedBox(width: 12),
  //         Expanded(
  //           child: OutlinedButton.icon(
  //             onPressed: () {
  //               if (contactPersonne != null) {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => ChatPage(
  //                       currentUser: widget.currentUser,
  //                       otherUserId: contactPersonne!.uuid,
  //                     ),
  //                   ),
  //                 );
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text("Aucun contact disponible pour ce salon."),
  //                     backgroundColor: Colors.red,
  //                   ),
  //                 );
  //               }
  //             },
  //             icon: Icon(Icons.chat_bubble_outline),
  //             label: Text("Contacter"),
  //             style: OutlinedButton.styleFrom(
  //               foregroundColor: Colors.green,
  //               side: BorderSide(color: Colors.green),
  //               padding: EdgeInsets.symmetric(vertical: 16),
  //             ),
  //           ),
  //         ),
  //         SizedBox(width: 12),
  //         Expanded(
  //           child: ElevatedButton.icon(
  //             onPressed: () {
  //               SalonServicesModalService.afficherServicesModal(
  //                 context,
  //                 salon: widget.salon,
  //                 primaryColor: widget.primaryColor,
  //                 accentColor: widget.accentColor,
  //                 onServicesSelected: (services) {
  //                 },
  //               );
  //             },
  //             icon: Icon(Icons.date_range),
  //             label: Text("Services"),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: widget.primaryColor,
  //               foregroundColor: Colors.white,
  //               padding: EdgeInsets.symmetric(vertical: 16),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
