// lib/pages/salon_geolocalisation/salon_map_page.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hairbnb/pages/coiffeuses/services/city_autocomplete.dart';
import 'package:hairbnb/pages/coiffeuses/services/geocoding_service.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import '../coiffeuses/services/location_service.dart';
import 'api_salon_location_service.dart';  // Import correctement utilisé maintenant

class SalonsListPage extends StatefulWidget {
  const SalonsListPage({super.key});

  @override
  _SalonsListPageState createState() => _SalonsListPageState();
}

class _SalonsListPageState extends State<SalonsListPage> {
  List<dynamic> salons = [];
  Position? _currentPosition;
  Position? _gpsPosition;
  double _gpsRadius = 10.0;
  final TextEditingController cityController = TextEditingController();
  final TextEditingController distanceController = TextEditingController();
  bool showCitySearch = false;
  late CurrentUser? currentUser;
  int _currentIndex = 1;
  String? activeSearchLabel;
  bool isLoading = true;

  // Pour pagination
  int _itemsPerPage = 10;
  int _currentPage = 1;

  // Pour le design
  final Color primaryColor = Color(0xFF8E44AD); // Couleur violette comme dans vos exemples
  final Color accentColor = Color(0xFFE67E22);  // Couleur orange pour les accents
  final Color backgroundColor = Color(0xFFF5F5F5); // Fond gris très clair
  final Color cardColor = Colors.white;

  List<dynamic> get _paginatedSalons {
    if (salons.isEmpty) return [];
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = _currentPage * _itemsPerPage;
    return salons.sublist(start, end > salons.length ? salons.length : end);
  }

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      final position = await LocationService.getUserLocation();
      if (position != null) {
        setState(() {
          _gpsPosition = position;
          _currentPosition = position;
          activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
        });
        await _fetchSalons(position, _gpsRadius);
      }
    } catch (e) {
      print("❌ Erreur de localisation : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSalons(Position position, double radius) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Appel à l'API réelle pour obtenir les vrais salons
      final nearbySalons = await ApiSalonService.fetchNearbySalons(
        position.latitude,
        position.longitude,
        radius,
      );

      currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

      setState(() {
        salons = nearbySalons;
        _currentPage = 1;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur API : $e");
      setState(() {
        isLoading = false;
      });
      // Afficher un message d'erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Impossible de charger les salons: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchByCity() async {
    final city = cityController.text.trim();
    final distanceText = distanceController.text.trim();

    if (city.isEmpty || distanceText.isEmpty) return;

    final parsedDistance = double.tryParse(distanceText);
    if (parsedDistance == null || parsedDistance > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Distance invalide. Maximum 150 km."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final position = await GeocodingService.getCoordinatesFromCity(city);
    if (position != null) {
      setState(() {
        _currentPosition = position;
        activeSearchLabel = "🏙️ Autour de $city (${parsedDistance.toInt()} km)";
        showCitySearch = false;
      });
      await _fetchSalons(position, parsedDistance);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ville introuvable."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateDistance(String salonPosition) {
    try {
      final parts = salonPosition.split(',');
      if (parts.length != 2) return 0.0;

      final lat = double.parse(parts[0]);
      final lon = double.parse(parts[1]);
      if (_currentPosition == null) return 0.0;

      final dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lon,
      );

      return dist / 1000;
    } catch (e) {
      print("❌ Erreur distance : $e");
      return 0.0;
    }
  }

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  void _viewSalonDetails(dynamic salon) {
    // Naviguer vers la page de détails du salon
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => SalonDetailsPage(salonId: salon['idTblSalon']),
    //   ),
    // );

    // En attendant d'avoir une page de détails, affichez un modal avec les informations
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Poignée du ModalSheet
            Container(
              width: 40,
              height: 5,
              margin: EdgeInsets.only(top: 15, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du salon
                  Text(
                    salon['nom'] ?? "Salon",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),

                  // Slogan du salon
                  if (salon['slogan'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        salon['slogan'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                  // Distance
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "📍 ${(salon['distance'] ?? _calculateDistance(salon['position'])).toStringAsFixed(1)} km",
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 30),

            // Liste des coiffeuses
            if (salon['coiffeuses_details'] != null && salon['coiffeuses_details'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "L'équipe du salon",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...salon['coiffeuses_details'].map<Widget>((coiffeuse) =>
                        Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: coiffeuse['est_proprietaire']
                                    ? primaryColor.withOpacity(0.2)
                                    : Colors.grey[200],
                                child: coiffeuse['photo_profil'] != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.network(
                                    "https://www.hairbnb.site${coiffeuse['photo_profil']}",
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, obj, st) => Icon(
                                      Icons.person,
                                      color: coiffeuse['est_proprietaire']
                                          ? primaryColor
                                          : Colors.grey[500],
                                      size: 24,
                                    ),
                                  ),
                                )
                                    : Icon(
                                  Icons.person,
                                  color: coiffeuse['est_proprietaire']
                                      ? primaryColor
                                      : Colors.grey[500],
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),

                              // Infos de la coiffeuse
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "${coiffeuse['prenom']} ${coiffeuse['nom']}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (coiffeuse['est_proprietaire'])
                                          Container(
                                            margin: EdgeInsets.only(left: 8),
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Propriétaire",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (coiffeuse['nom_commercial'] != null)
                                      Text(
                                        coiffeuse['nom_commercial'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Boutons d'action
                              Icon(
                                Icons.message_outlined,
                                color: accentColor,
                              ),
                            ],
                          ),
                        ),
                    ).toList(),
                  ],
                ),
              ),

            // Actions en bas de la fiche
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.map_outlined),
                      label: Text("Itinéraire"),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: accentColor),
                        foregroundColor: accentColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Action de réservation
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.calendar_today),
                      label: Text("Réserver"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          "Salons à proximité",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.map_outlined, color: Colors.white),
            onPressed: () {
              // Basculer vers la vue carte
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, backgroundColor],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
            children: [
        // En-tête avec recherche
        Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage du mode de recherche actuel
            if (activeSearchLabel != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activeSearchLabel!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),

            // Contrôle du rayon de recherche
            showCitySearch
                ? Column(
              children: [
                // Recherche par ville
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: CityAutocompleteField(
                          controller: cityController,
                          apiKey: 'b097f188b11f46d2a02eb55021d168c1',
                          onCitySelected: (ville) {},
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: distanceController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'km',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: accentColor,
                      child: IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: _searchByCity,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                TextButton.icon(
                  icon: Icon(Icons.my_location),
                  label: Text("Revenir à ma position"),
                  onPressed: () {
                    setState(() {
                      showCitySearch = false;
                      if (_gpsPosition != null) {
                        _currentPosition = _gpsPosition;
                        activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
                        _fetchSalons(_gpsPosition!, _gpsRadius);
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slider de distance
                Row(
                  children: [
                    Text(
                      "Rayon de recherche",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _gpsRadius,
                        min: 1,
                        max: 50,
                        divisions: 10,
                        label: "${_gpsRadius.toInt()} km",
                        onChanged: (val) {
                          setState(() {
                            _gpsRadius = val;
                            activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
                          });
                          if (_gpsPosition != null) {
                            _fetchSalons(_gpsPosition!, _gpsRadius);
                          }
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_gpsRadius.toInt()} km",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.location_city),
                    label: Text("Rechercher par ville"),
                    onPressed: () {
                      setState(() {
                        showCitySearch = true;
                        cityController.clear();
                        distanceController.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Liste des salons
      Expanded(
      child: Container(
      decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    child: isLoading
    ? Center(
    child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
    ),
    )
        : salons.isEmpty
    ? Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(
    Icons.location_off,
    size: 64,
    color: Colors.grey[400],
    ),
    SizedBox(height: 16),
    Text(
    "Aucun salon trouvé",
    style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.grey[600],
    ),
    ),
    SizedBox(height: 8),
    Text(
    "Essayez d'augmenter la distance ou de rechercher dans une autre zone",
    textAlign: TextAlign.center,
    style: TextStyle(color: Colors.grey[500]),
    ),
    SizedBox(height: 24),
    ElevatedButton.icon(
    onPressed: () {
    if (_currentPosition != null) {
    _fetchSalons(_currentPosition!, _gpsRadius);
    }
    },
    icon: Icon(Icons.refresh),
    label: Text("Actualiser"),
    style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
    ),
    ],
    ),
    )
        : ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: _paginatedSalons.length,
    itemBuilder: (context, index) {
    final salon = _paginatedSalons[index];
    final distance = salon['distance'] ?? _calculateDistance(salon['position'] ?? "0,0");
    final coiffeuses = salon['coiffeuses_details'] ?? [];

    return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: Offset(0, 4),
    ),
    ],
    ),
    child: Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
    onTap: () => _viewSalonDetails(salon),
    borderRadius: BorderRadius.circular(16),
    child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    // Logo/Avatar du salon
    Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: salon['logo'] != null && salon['logo'].toString().isNotEmpty
    ? ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
    "https://www.hairbnb.site${salon['logo']}",
    fit: BoxFit.cover,
    errorBuilder: (ctx, obj, st) => Icon(
    Icons.spa,
    color: primaryColor,
    size: 30,
    ),
    ),
    )
        : Icon(
    Icons.spa,
    color: primaryColor,
    size: 30,
    ),
    ),
    SizedBox(width: 16),

    // Informations du salon
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    salon['nom'] ?? "Salon sans nom",
    style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    ),
    ),
    if (salon['slogan'] != null && salon['slogan'].toString().isNotEmpty)
    Text(
    salon['slogan'],
    style: TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
    fontStyle: FontStyle.italic,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    ),
    SizedBox(height: 8),
    Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
    color: accentColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
    "${distance.toStringAsFixed(1)} km",
    style: TextStyle(
    fontSize: 12,
    color: accentColor,
    fontWeight: FontWeight.w500,
    ),
    ),
    ),
    ],
    ),
    ),

    // Flèche pour accéder aux détails
    Icon(
    Icons.arrow_forward_ios,
    color: Colors.grey[400],
    size: 16,
    ),
    ],
    ),

    // Affichage des coiffeuses (si présentes)
    if (coiffeuses.isNotEmpty)
    Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    "L'équipe :",
    style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryColor,
    ),
    ),
    SizedBox(height: 8),
    Wrap(
    spacing: 8,
    runSpacing: 8,
    children: coiffeuses.take(3).map<Widget>((coiffeuse) {
    return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: coiffeuse['est_proprietaire']
    ? primaryColor.withOpacity(0.1)
        : Colors.grey[100],
    borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    CircleAvatar(
    radius: 12,
    backgroundColor: coiffeuse['est_proprietaire']
    ? primaryColor.withOpacity(0.2)
        : Colors.transparent,
    child: coiffeuse['photo_profil'] != null && coiffeuse['photo_profil'].toString().isNotEmpty
    ? ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
    "https://www.hairbnb.site${coiffeuse['photo_profil']}",
    width: 24,
    height: 24,
    fit: BoxFit.cover,
    errorBuilder: (ctx, obj, st) => Icon(
    Icons.person,
    size: 16,
    color: coiffeuse['est_proprietaire']
    ? primaryColor
        : Colors.grey[500],
    ),
    ),
    )
        : Icon(
      Icons.person,
      size: 16,
      color: coiffeuse['est_proprietaire']
          ? primaryColor
          : Colors.grey[500],
    ),
    ),
      SizedBox(width: 6),
      Text(
        "${coiffeuse['prenom']}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: coiffeuse['est_proprietaire']
              ? primaryColor
              : Colors.grey[800],
        ),
      ),
    ],
    ),
    );
    }).toList(),
    ),
      if (coiffeuses.length > 3)
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            "+${coiffeuses.length - 3} autres",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
    ],
    ),
    ),

      // Actions pour le salon
      Padding(
        padding: EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // Action d'itinéraire
              },
              icon: Icon(Icons.directions, size: 16),
              label: Text("Itinéraire"),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
                textStyle: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Action de réservation
              },
              icon: Icon(Icons.date_range, size: 16),
              label: Text("Réserver"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
                textStyle: TextStyle(fontSize: 12),
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
      ),
      ),

              // Pagination (si nécessaire)
              if (salons.length > _itemsPerPage)
                Container(
                  color: backgroundColor,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Boutons de navigation
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, size: 16),
                            onPressed: _currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                            color: primaryColor,
                            disabledColor: Colors.grey[300],
                          ),
                          Text(
                            "Page $_currentPage/${((salons.length - 1) / _itemsPerPage + 1).floor()}",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: _currentPage * _itemsPerPage < salons.length
                                ? () => setState(() => _currentPage++)
                                : null,
                            color: primaryColor,
                            disabledColor: Colors.grey[300],
                          ),
                        ],
                      ),

                      // Sélecteur du nombre d'éléments par page
                      Row(
                        children: [
                          Text(
                            "Afficher:",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButton<int>(
                              value: _itemsPerPage,
                              items: [5, 10, 20].map((value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    '$value',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _itemsPerPage = value;
                                    _currentPage = 1;
                                  });
                                }
                              },
                              underline: SizedBox(),
                              icon: Icon(Icons.arrow_drop_down, size: 18),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}








// // lib/pages/salon_geolocalisation/salon_map_page.dart
//
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hairbnb/pages/coiffeuses/services/city_autocomplete.dart';
// import 'package:hairbnb/pages/coiffeuses/services/geocoding_service.dart';
// import 'package:provider/provider.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/bottom_nav_bar.dart';
//
// import '../coiffeuses/services/location_service.dart';
// import 'api_salon_location_service.dart';
//
// class SalonsListPage extends StatefulWidget {
//   const SalonsListPage({super.key});
//
//   @override
//   _SalonsListPageState createState() => _SalonsListPageState();
// }
//
// class _SalonsListPageState extends State<SalonsListPage> {
//   List<dynamic> salons = [];
//   Position? _currentPosition;
//   Position? _gpsPosition;
//   double _gpsRadius = 10.0;
//   final TextEditingController cityController = TextEditingController();
//   final TextEditingController distanceController = TextEditingController();
//   bool showCitySearch = false;
//   late CurrentUser? currentUser;
//   int _currentIndex = 1;
//   String? activeSearchLabel;
//   bool isLoading = true;
//
//   // Pour pagination
//   int _itemsPerPage = 10;
//   int _currentPage = 1;
//
//   // Pour le design
//   final Color primaryColor = Color(0xFF8E44AD); // Couleur violette comme dans vos exemples
//   final Color accentColor = Color(0xFFE67E22);  // Couleur orange pour les accents
//   final Color backgroundColor = Color(0xFFF5F5F5); // Fond gris très clair
//   final Color cardColor = Colors.white;
//
//   List<dynamic> get _paginatedSalons {
//     if (salons.isEmpty) return [];
//     final start = (_currentPage - 1) * _itemsPerPage;
//     final end = _currentPage * _itemsPerPage;
//     return salons.sublist(start, end > salons.length ? salons.length : end);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserLocation();
//   }
//
//   Future<void> _loadUserLocation() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       final position = await LocationService.getUserLocation();
//       if (position != null) {
//         setState(() {
//           _gpsPosition = position;
//           _currentPosition = position;
//           activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
//         });
//         await _fetchSalons(position, _gpsRadius);
//       }
//     } catch (e) {
//       print("❌ Erreur de localisation : $e");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _fetchSalons(Position position, double radius) async {
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       // Pour le développement, renvoyer des données factices
//       await Future.delayed(Duration(seconds: 1)); // Simulation du délai réseau
//
//       // Données de test pour le développement frontend
//       final fakeSalons = [
//         {
//           "idTblSalon": 1,
//           "nom": "Le Salon Élégance",
//           "slogan": "L'art de la beauté au service de vos cheveux",
//           "logo": null,
//           "position": "${position.latitude-0.01},${position.longitude+0.01}",
//           "latitude": position.latitude - 0.01,
//           "longitude": position.longitude + 0.01,
//           "coiffeuse_ids": [1, 2],
//           "distance": 1.5,
//           "coiffeuses_details": [
//             {
//               "idTblCoiffeuse": 1,
//               "nom": "Dupont",
//               "prenom": "Marie",
//               "photo_profil": null,
//               "est_proprietaire": true,
//               "nom_commercial": "Élégance Coiffure"
//             },
//             {
//               "idTblCoiffeuse": 2,
//               "nom": "Martin",
//               "prenom": "Sophie",
//               "photo_profil": null,
//               "est_proprietaire": false,
//               "nom_commercial": null
//             }
//           ]
//         },
//         {
//           "idTblSalon": 2,
//           "nom": "Studio Coiffure",
//           "slogan": "Votre beauté, notre passion",
//           "logo": null,
//           "position": "${position.latitude+0.02},${position.longitude-0.02}",
//           "latitude": position.latitude + 0.02,
//           "longitude": position.longitude - 0.02,
//           "coiffeuse_ids": [3],
//           "distance": 2.8,
//           "coiffeuses_details": [
//             {
//               "idTblCoiffeuse": 3,
//               "nom": "Petit",
//               "prenom": "Julie",
//               "photo_profil": null,
//               "est_proprietaire": true,
//               "nom_commercial": "Studio Coiffure"
//             }
//           ]
//         },
//         {
//           "idTblSalon": 3,
//           "nom": "Hair Fusion",
//           "slogan": "L'innovation capillaire",
//           "logo": null,
//           "position": "${position.latitude+0.008},${position.longitude+0.015}",
//           "latitude": position.latitude + 0.008,
//           "longitude": position.longitude + 0.015,
//           "coiffeuse_ids": [4, 5, 6],
//           "distance": 3.2,
//           "coiffeuses_details": [
//             {
//               "idTblCoiffeuse": 4,
//               "nom": "Leroy",
//               "prenom": "Antoine",
//               "photo_profil": null,
//               "est_proprietaire": true,
//               "nom_commercial": "Hair Fusion"
//             },
//             {
//               "idTblCoiffeuse": 5,
//               "nom": "Garcia",
//               "prenom": "Lucie",
//               "photo_profil": null,
//               "est_proprietaire": false,
//               "nom_commercial": null
//             },
//             {
//               "idTblCoiffeuse": 6,
//               "nom": "Bernard",
//               "prenom": "Thomas",
//               "photo_profil": null,
//               "est_proprietaire": false,
//               "nom_commercial": null
//             }
//           ]
//         }
//       ];
//
//       // Utiliser les données factices ou l'API selon vos besoins
//       // Décommentez pour utiliser l'API réelle
//       /*
//       final nearbySalons = await ApiSalonService.fetchNearbySalons(
//         position.latitude,
//         position.longitude,
//         radius,
//       );
//       */
//
//       currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//       setState(() {
//         // Utiliser les données factices pour le développement
//         salons = fakeSalons;
//         // Utilisez cette ligne pour l'API réelle
//         // salons = nearbySalons;
//         _currentPage = 1;
//         isLoading = false;
//       });
//     } catch (e) {
//       print("❌ Erreur API : $e");
//       setState(() {
//         isLoading = false;
//       });
//       // Afficher un message d'erreur à l'utilisateur
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Impossible de charger les salons"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> _searchByCity() async {
//     final city = cityController.text.trim();
//     final distanceText = distanceController.text.trim();
//
//     if (city.isEmpty || distanceText.isEmpty) return;
//
//     final parsedDistance = double.tryParse(distanceText);
//     if (parsedDistance == null || parsedDistance > 150) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Distance invalide. Maximum 150 km."),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     final position = await GeocodingService.getCoordinatesFromCity(city);
//     if (position != null) {
//       setState(() {
//         _currentPosition = position;
//         activeSearchLabel = "🏙️ Autour de $city (${parsedDistance.toInt()} km)";
//         showCitySearch = false;
//       });
//       await _fetchSalons(position, parsedDistance);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Ville introuvable."),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   double _calculateDistance(String salonPosition) {
//     try {
//       final parts = salonPosition.split(',');
//       if (parts.length != 2) return 0.0;
//
//       final lat = double.parse(parts[0]);
//       final lon = double.parse(parts[1]);
//       if (_currentPosition == null) return 0.0;
//
//       final dist = Geolocator.distanceBetween(
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
//         lat,
//         lon,
//       );
//
//       return dist / 1000;
//     } catch (e) {
//       print("❌ Erreur distance : $e");
//       return 0.0;
//     }
//   }
//
//   void _onTabTapped(int index) => setState(() => _currentIndex = index);
//
//   void _viewSalonDetails(dynamic salon) {
//     // Naviguer vers la page de détails du salon
//     // Navigator.push(
//     //   context,
//     //   MaterialPageRoute(
//     //     builder: (context) => SalonDetailsPage(salonId: salon['idTblSalon']),
//     //   ),
//     // );
//
//     // En attendant d'avoir une page de détails, affichez un modal avec les informations
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.7,
//         decoration: BoxDecoration(
//           color: cardColor,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           children: [
//             // Poignée du ModalSheet
//             Container(
//               width: 40,
//               height: 5,
//               margin: EdgeInsets.only(top: 15, bottom: 20),
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Titre du salon
//                   Text(
//                     salon['nom'] ?? "Salon",
//                     style: GoogleFonts.poppins(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w600,
//                       color: primaryColor,
//                     ),
//                   ),
//
//                   // Slogan du salon
//                   if (salon['slogan'] != null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: Text(
//                         salon['slogan'],
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontStyle: FontStyle.italic,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ),
//
//                   // Distance
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: accentColor.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       "📍 ${(salon['distance'] ?? _calculateDistance(salon['position'])).toStringAsFixed(1)} km",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: accentColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             Divider(height: 30),
//
//             // Liste des coiffeuses
//             if (salon['coiffeuses_details'] != null && salon['coiffeuses_details'].isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "L'équipe du salon",
//                       style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: primaryColor,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     ...salon['coiffeuses_details'].map<Widget>((coiffeuse) =>
//                         Container(
//                           margin: EdgeInsets.only(bottom: 12),
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[50],
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 5,
//                                 offset: Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               // Avatar
//                               CircleAvatar(
//                                 radius: 25,
//                                 backgroundColor: coiffeuse['est_proprietaire']
//                                     ? primaryColor.withOpacity(0.2)
//                                     : Colors.grey[200],
//                                 child: coiffeuse['photo_profil'] != null
//                                     ? null // Image serait ici
//                                     : Icon(
//                                   Icons.person,
//                                   color: coiffeuse['est_proprietaire']
//                                       ? primaryColor
//                                       : Colors.grey[500],
//                                   size: 24,
//                                 ),
//                               ),
//                               SizedBox(width: 16),
//
//                               // Infos de la coiffeuse
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Text(
//                                           "${coiffeuse['prenom']} ${coiffeuse['nom']}",
//                                           style: GoogleFonts.poppins(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                         if (coiffeuse['est_proprietaire'])
//                                           Container(
//                                             margin: EdgeInsets.only(left: 8),
//                                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                             decoration: BoxDecoration(
//                                               color: primaryColor.withOpacity(0.2),
//                                               borderRadius: BorderRadius.circular(12),
//                                             ),
//                                             child: Text(
//                                               "Propriétaire",
//                                               style: TextStyle(
//                                                 fontSize: 10,
//                                                 color: primaryColor,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                     if (coiffeuse['nom_commercial'] != null)
//                                       Text(
//                                         coiffeuse['nom_commercial'],
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//
//                               // Boutons d'action
//                               Icon(
//                                 Icons.message_outlined,
//                                 color: accentColor,
//                               ),
//                             ],
//                           ),
//                         ),
//                     ).toList(),
//                   ],
//                 ),
//               ),
//
//             // Actions en bas de la fiche
//             Spacer(),
//             Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       icon: Icon(Icons.map_outlined),
//                       label: Text("Itinéraire"),
//                       style: OutlinedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(vertical: 12),
//                         side: BorderSide(color: accentColor),
//                         foregroundColor: accentColor,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         // Action de réservation
//                         Navigator.pop(context);
//                       },
//                       icon: Icon(Icons.calendar_today),
//                       label: Text("Réserver"),
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(vertical: 12),
//                         backgroundColor: primaryColor,
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         backgroundColor: primaryColor,
//         elevation: 0,
//         title: Text(
//           "Salons à proximité",
//           style: GoogleFonts.poppins(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.map_outlined, color: Colors.white),
//             onPressed: () {
//               // Basculer vers la vue carte
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [primaryColor, backgroundColor],
//             stops: [0.0, 0.3],
//           ),
//         ),
//         child: Column(
//             children: [
//         // En-tête avec recherche
//         Container(
//         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Affichage du mode de recherche actuel
//             if (activeSearchLabel != null)
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 margin: EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white30,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   activeSearchLabel!,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//
//             // Contrôle du rayon de recherche
//             showCitySearch
//                 ? Column(
//               children: [
//                 // Recherche par ville
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: EdgeInsets.symmetric(horizontal: 8),
//                         child: CityAutocompleteField(
//                           controller: cityController,
//                           apiKey: 'b097f188b11f46d2a02eb55021d168c1',
//                           onCitySelected: (ville) {},
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Container(
//                       width: 70,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: TextField(
//                         controller: distanceController,
//                         keyboardType: TextInputType.number,
//                         textAlign: TextAlign.center,
//                         decoration: InputDecoration(
//                           hintText: 'km',
//                           border: InputBorder.none,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     CircleAvatar(
//                       backgroundColor: accentColor,
//                       child: IconButton(
//                         icon: Icon(Icons.search, color: Colors.white),
//                         onPressed: _searchByCity,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 TextButton.icon(
//                   icon: Icon(Icons.my_location),
//                   label: Text("Revenir à ma position"),
//                   onPressed: () {
//                     setState(() {
//                       showCitySearch = false;
//                       if (_gpsPosition != null) {
//                         _currentPosition = _gpsPosition;
//                         activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
//                         _fetchSalons(_gpsPosition!, _gpsRadius);
//                       }
//                     });
//                   },
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             )
//                 : Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Slider de distance
//                 Row(
//                   children: [
//                     Text(
//                       "Rayon de recherche",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Expanded(
//                       child: Slider(
//                         value: _gpsRadius,
//                         min: 1,
//                         max: 50,
//                         divisions: 10,
//                         label: "${_gpsRadius.toInt()} km",
//                         onChanged: (val) {
//                           setState(() {
//                             _gpsRadius = val;
//                             activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
//                           });
//                           if (_gpsPosition != null) {
//                             _fetchSalons(_gpsPosition!, _gpsRadius);
//                           }
//                         },
//                         activeColor: Colors.white,
//                         inactiveColor: Colors.white30,
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.white30,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         "${_gpsRadius.toInt()} km",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Center(
//                   child: TextButton.icon(
//                     icon: Icon(Icons.location_city),
//                     label: Text("Rechercher par ville"),
//                     onPressed: () {
//                       setState(() {
//                         showCitySearch = true;
//                         cityController.clear();
//                         distanceController.clear();
//                       });
//                     },
//                     style: TextButton.styleFrom(
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//
//       // Liste des salons
//       Expanded(
//       child: Container(
//       decoration: BoxDecoration(
//       color: backgroundColor,
//       borderRadius: BorderRadius.only(
//         topLeft: Radius.circular(24),
//         topRight: Radius.circular(24),
//       ),
//     ),
//     child: isLoading
//     ? Center(
//     child: CircularProgressIndicator(
//     valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//     ),
//     )
//         : salons.isEmpty
//     ? Center(
//     child: Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//     Icon(
//     Icons.location_off,
//     size: 64,
//     color: Colors.grey[400],
//     ),
//     SizedBox(height: 16),
//     Text(
//     "Aucun salon trouvé",
//     style: GoogleFonts.poppins(
//     fontSize: 18,
//     fontWeight: FontWeight.w500,
//     color: Colors.grey[600],
//     ),
//     ),
//     SizedBox(height: 8),
//     Text(
//     "Essayez d'augmenter la distance ou de rechercher dans une autre zone",
//     textAlign: TextAlign.center,
//     style: TextStyle(color: Colors.grey[500]),
//     ),
//     SizedBox(height: 24),
//     ElevatedButton.icon(
//     onPressed: () {
//     if (_currentPosition != null) {
//     _fetchSalons(_currentPosition!, _gpsRadius);
//     }
//     },
//     icon: Icon(Icons.refresh),
//     label: Text("Actualiser"),
//     style: ElevatedButton.styleFrom(
//     backgroundColor: primaryColor,
//     foregroundColor: Colors.white,
//     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//     ),
//     ),
//     ],
//     ),
//     )
//         : ListView.builder(
//     padding: EdgeInsets.all(16),
//     itemCount: _paginatedSalons.length,
//     itemBuilder: (context, index) {
//     final salon = _paginatedSalons[index];
//     final distance = salon['distance'] ?? _calculateDistance(salon['position'] ?? "0,0");
//     final coiffeuses = salon['coiffeuses_details'] ?? [];
//
//     return Container(
//     margin: EdgeInsets.only(bottom: 16),
//     decoration: BoxDecoration(
//     color: cardColor,
//     borderRadius: BorderRadius.circular(16),
//     boxShadow: [
//     BoxShadow(
//     color: Colors.black.withOpacity(0.05),
//     blurRadius: 10,
//     offset: Offset(0, 4),
//     ),
//     ],
//     ),
//     child: Material(
//     color: Colors.transparent,
//     borderRadius: BorderRadius.circular(16),
//     child: InkWell(
//     onTap: () => _viewSalonDetails(salon),
//     borderRadius: BorderRadius.circular(16),
//     child: Padding(
//     padding: EdgeInsets.all(16),
//     child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//     Row(
//     children: [
//     // Logo/Avatar du salon
//     Container(
//     width: 70,
//     height: 70,
//     decoration: BoxDecoration(
//     color: primaryColor.withOpacity(0.1),
//     borderRadius: BorderRadius.circular(12),
//     ),
//     child: salon['logo'] != null
//     ? ClipRRect(
//     borderRadius: BorderRadius.circular(12),
//     child: Image.network(
//     "https://www.hairbnb.site${salon['logo']}",
//     fit: BoxFit.cover,
//     ),
//     )
//         : Icon(
//     Icons.spa,
//     color: primaryColor,
//     size: 30,
//     ),
//     ),
//     SizedBox(width: 16),
//
//     // Informations du salon
//     Expanded(
//     child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//     Text(
//     salon['nom'] ?? "Salon sans nom",
//     style: GoogleFonts.poppins(
//     fontSize: 18,
//     fontWeight: FontWeight.w600,
//     ),
//     ),
//     if (salon['slogan'] != null)
//     Text(
//     salon['slogan'],
//     style: TextStyle(
//     fontSize: 12,
//     color: Colors.grey[600],
//     fontStyle: FontStyle.italic,
//     ),
//     maxLines: 1,
//     overflow: TextOverflow.ellipsis,
//     ),
//     SizedBox(height: 8),
//     Container(
//     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//     decoration: BoxDecoration(
//     color: accentColor.withOpacity(0.1),
//     borderRadius: BorderRadius.circular(12),
//     ),
//     child: Text(
//     "${distance.toStringAsFixed(1)} km",
//     style: TextStyle(
//     fontSize: 12,
//     color: accentColor,
//     fontWeight: FontWeight.w500,
//     ),
//     ),
//     ),
//     ],
//     ),
//     ),
// // Flèche pour accéder aux détails
//       Icon(
//         Icons.arrow_forward_ios,
//         color: Colors.grey[400],
//         size: 16,
//       ),
//     ],
//     ),
//
//       // Affichage des coiffeuses (si présentes)
//       if (coiffeuses.isNotEmpty)
//         Padding(
//           padding: const EdgeInsets.only(top: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "L'équipe :",
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: primaryColor,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: coiffeuses.take(3).map<Widget>((coiffeuse) {
//                   return Container(
//                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: coiffeuse['est_proprietaire']
//                           ? primaryColor.withOpacity(0.1)
//                           : Colors.grey[100],
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircleAvatar(
//                           radius: 12,
//                           backgroundColor: coiffeuse['est_proprietaire']
//                               ? primaryColor.withOpacity(0.2)
//                               : Colors.transparent,
//                           child: coiffeuse['photo_profil'] != null
//                               ? null // Image ici si disponible
//                               : Icon(
//                             Icons.person,
//                             size: 16,
//                             color: coiffeuse['est_proprietaire']
//                                 ? primaryColor
//                                 : Colors.grey[500],
//                           ),
//                         ),
//                         SizedBox(width: 6),
//                         Text(
//                           "${coiffeuse['prenom']}",
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: coiffeuse['est_proprietaire']
//                                 ? primaryColor
//                                 : Colors.grey[800],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
//               if (coiffeuses.length > 3)
//                 Padding(
//                   padding: EdgeInsets.only(top: 8),
//                   child: Text(
//                     "+${coiffeuses.length - 3} autres",
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[500],
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//
//       // Actions pour le salon
//       Padding(
//         padding: EdgeInsets.only(top: 16),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             OutlinedButton.icon(
//               onPressed: () {
//                 // Action d'itinéraire
//               },
//               icon: Icon(Icons.directions, size: 16),
//               label: Text("Itinéraire"),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: accentColor,
//                 side: BorderSide(color: accentColor),
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 visualDensity: VisualDensity.compact,
//                 textStyle: TextStyle(fontSize: 12),
//               ),
//             ),
//             SizedBox(width: 8),
//             ElevatedButton.icon(
//               onPressed: () {
//                 // Action de réservation
//               },
//               icon: Icon(Icons.date_range, size: 16),
//               label: Text("Réserver"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 visualDensity: VisualDensity.compact,
//                 textStyle: TextStyle(fontSize: 12),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ],
//     ),
//     ),
//     ),
//     ),
//     );
//     },
//     ),
//       ),
//       ),
//
//               // Pagination (si nécessaire)
//               if (salons.length > _itemsPerPage)
//                 Container(
//                   color: backgroundColor,
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Boutons de navigation
//                       Row(
//                         children: [
//                           IconButton(
//                             icon: Icon(Icons.arrow_back_ios, size: 16),
//                             onPressed: _currentPage > 1
//                                 ? () => setState(() => _currentPage--)
//                                 : null,
//                             color: primaryColor,
//                             disabledColor: Colors.grey[300],
//                           ),
//                           Text(
//                             "Page $_currentPage/${((salons.length - 1) / _itemsPerPage + 1).floor()}",
//                             style: TextStyle(
//                               color: Colors.grey[700],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.arrow_forward_ios, size: 16),
//                             onPressed: _currentPage * _itemsPerPage < salons.length
//                                 ? () => setState(() => _currentPage++)
//                                 : null,
//                             color: primaryColor,
//                             disabledColor: Colors.grey[300],
//                           ),
//                         ],
//                       ),
//
//                       // Sélecteur du nombre d'éléments par page
//                       Row(
//                         children: [
//                           Text(
//                             "Afficher:",
//                             style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                           ),
//                           SizedBox(width: 4),
//                           Container(
//                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.grey[300]!),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: DropdownButton<int>(
//                               value: _itemsPerPage,
//                               items: [5, 10, 20].map((value) {
//                                 return DropdownMenuItem<int>(
//                                   value: value,
//                                   child: Text(
//                                     '$value',
//                                     style: TextStyle(fontSize: 12),
//                                   ),
//                                 );
//                               }).toList(),
//                               onChanged: (value) {
//                                 if (value != null) {
//                                   setState(() {
//                                     _itemsPerPage = value;
//                                     _currentPage = 1;
//                                   });
//                                 }
//                               },
//                               underline: SizedBox(),
//                               icon: Icon(Icons.arrow_drop_down, size: 18),
//                               isDense: true,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: _onTabTapped,
//       ),
//     );
//   }
// }
//
//
//
//
// // // lib/pages/geolocalisation/salons_list_page.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:hairbnb/pages/coiffeuses/services/city_autocomplete.dart';
// // import 'package:hairbnb/pages/coiffeuses/services/geocoding_service.dart';
// // import 'package:provider/provider.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:hairbnb/services/providers/current_user_provider.dart';
// // import 'package:hairbnb/widgets/custom_app_bar.dart';
// // import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// //
// // import '../coiffeuses/services/location_service.dart';
// // import 'api_salon_location_service.dart';
// //
// // class SalonsListPage extends StatefulWidget {
// //   const SalonsListPage({super.key});
// //
// //   @override
// //   _SalonsListPageState createState() => _SalonsListPageState();
// // }
// //
// // class _SalonsListPageState extends State<SalonsListPage> {
// //   List<dynamic> salons = [];
// //   Position? _currentPosition;
// //   Position? _gpsPosition;
// //   double _gpsRadius = 10.0;
// //   final TextEditingController cityController = TextEditingController();
// //   final TextEditingController distanceController = TextEditingController();
// //   bool isTileExpanded = false;
// //   late CurrentUser? currentUser;
// //   int _currentIndex = 1;
// //   String? activeSearchLabel;
// //
// //   int _itemsPerPage = 10;
// //   int _currentPage = 1;
// //
// //   List<dynamic> get _paginatedSalons {
// //     if (salons.isEmpty) return [];
// //     final start = (_currentPage - 1) * _itemsPerPage;
// //     final end = _currentPage * _itemsPerPage;
// //     return salons.sublist(start, end > salons.length ? salons.length : end);
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadUserLocation();
// //   }
// //
// //   Future<void> _loadUserLocation() async {
// //     try {
// //       final position = await LocationService.getUserLocation();
// //       if (position != null) {
// //         setState(() {
// //           _gpsPosition = position;
// //           _currentPosition = position;
// //           activeSearchLabel = "📍 Autour de ma position actuelle (${_gpsRadius.toInt()} km)";
// //         });
// //         await _fetchSalons(position, _gpsRadius);
// //       }
// //     } catch (e) {
// //       print("❌ Erreur de localisation : $e");
// //     }
// //   }
// //
// //   Future<void> _fetchSalons(Position position, double radius) async {
// //     try {
// //       final nearbySalons = await ApiSalonService.fetchNearbySalons(
// //         position.latitude,
// //         position.longitude,
// //         radius,
// //       );
// //
// //       currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
// //
// //       setState(() {
// //         salons = nearbySalons;
// //         _currentPage = 1;
// //       });
// //     } catch (e) {
// //       print("❌ Erreur API : $e");
// //       // Afficher un message d'erreur à l'utilisateur
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Erreur de chargement des salons: $e")),
// //       );
// //     }
// //   }
// //
// //   Future<void> _searchByCity() async {
// //     final city = cityController.text.trim();
// //     final distanceText = distanceController.text.trim();
// //
// //     if (city.isEmpty || distanceText.isEmpty) return;
// //
// //     final parsedDistance = double.tryParse(distanceText);
// //     if (parsedDistance == null || parsedDistance > 150) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Distance invalide. Maximum 150 km.")),
// //       );
// //       return;
// //     }
// //
// //     final position = await GeocodingService.getCoordinatesFromCity(city);
// //     if (position != null) {
// //       setState(() {
// //         _currentPosition = position;
// //         activeSearchLabel = "🏙️ Autour de $city (${parsedDistance.toInt()} km)";
// //         isTileExpanded = false;
// //       });
// //       await _fetchSalons(position, parsedDistance);
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Ville introuvable.")),
// //       );
// //     }
// //   }
// //
// //   double _calculateDistance(String salonPosition) {
// //     try {
// //       final parts = salonPosition.split(',');
// //       if (parts.length != 2) return 0.0;
// //
// //       final lat = double.parse(parts[0]);
// //       final lon = double.parse(parts[1]);
// //       if (_currentPosition == null) return 0.0;
// //
// //       final dist = Geolocator.distanceBetween(
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //         lat,
// //         lon,
// //       );
// //
// //       return dist / 1000;
// //     } catch (e) {
// //       print("❌ Erreur distance : $e");
// //       return 0.0;
// //     }
// //   }
// //
// //   void _onTabTapped(int index) => setState(() => _currentIndex = index);
// //
// //   void _viewSalonDetails(dynamic salon) {
// //     // Naviguer vers la page de détails du salon
// //     // Navigator.push(
// //     //   context,
// //     //   MaterialPageRoute(
// //     //     builder: (context) => SalonDetailsPage(salonId: salon['idTblSalon']),
// //     //   ),
// //     // );
// //
// //     // En attendant d'avoir une page de détails, affichez un modal avec les informations
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text(salon['nom'] ?? "Salon"),
// //         content: SingleChildScrollView(
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               if (salon['slogan'] != null)
// //                 Text(
// //                   salon['slogan'],
// //                   style: TextStyle(fontStyle: FontStyle.italic),
// //                 ),
// //               SizedBox(height: 16),
// //               Text("Distance: ${(salon['distance'] ?? _calculateDistance(salon['position'])).toStringAsFixed(1)} km"),
// //               Divider(),
// //               if (salon['coiffeuses_details'] != null && salon['coiffeuses_details'].isNotEmpty)
// //                 Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text("Coiffeuses de ce salon:", style: TextStyle(fontWeight: FontWeight.bold)),
// //                     SizedBox(height: 8),
// //                     ...salon['coiffeuses_details'].map<Widget>((coiffeuse) =>
// //                         Padding(
// //                           padding: const EdgeInsets.only(bottom: 4.0),
// //                           child: Row(
// //                             children: [
// //                               Icon(
// //                                 coiffeuse['est_proprietaire'] ? Icons.star : Icons.person,
// //                                 size: 16,
// //                                 color: coiffeuse['est_proprietaire'] ? Colors.amber : Colors.grey,
// //                               ),
// //                               SizedBox(width: 4),
// //                               Text("${coiffeuse['prenom']} ${coiffeuse['nom']}"),
// //                             ],
// //                           ),
// //                         )
// //                     ).toList(),
// //                   ],
// //                 ),
// //             ],
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text("Fermer"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: CustomAppBar(),
// //       body: _currentPosition == null
// //           ? const Center(child: CircularProgressIndicator())
// //           : Column(
// //         children: [
// //           Padding(
// //             padding: const EdgeInsets.all(16.0),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 if (activeSearchLabel != null)
// //                   Padding(
// //                     padding: const EdgeInsets.only(bottom: 10.0),
// //                     child: Text(
// //                       activeSearchLabel!,
// //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
// //                     ),
// //                   ),
// //                 const Text("Autour de ma position actuelle :"),
// //                 Slider(
// //                   value: _gpsRadius,
// //                   min: 1,
// //                   max: 50,
// //                   divisions: 10,
// //                   label: "${_gpsRadius.toInt()} km",
// //                   onChanged: (val) {
// //                     setState(() {
// //                       _gpsRadius = val;
// //                       _currentPosition = _gpsPosition;
// //                       cityController.clear();
// //                       distanceController.clear();
// //                       activeSearchLabel = "📍 Autour de ma position actuelle (${_gpsRadius.toInt()} km)";
// //                     });
// //                     if (_gpsPosition != null) {
// //                       _fetchSalons(_gpsPosition!, _gpsRadius);
// //                     }
// //                   },
// //                 ),
// //                 const Divider(),
// //                 AnimatedCrossFade(
// //                   duration: const Duration(milliseconds: 200),
// //                   crossFadeState: isTileExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
// //                   firstChild: ListTile(
// //                     title: const Text("Rechercher autour d'une ville"),
// //                     trailing: const Icon(Icons.expand_more),
// //                     onTap: () {
// //                       setState(() {
// //                         isTileExpanded = true;
// //                         cityController.clear();
// //                         distanceController.clear();
// //                       });
// //                     },
// //                   ),
// //                   secondChild: Column(
// //                     children: [
// //                       ListTile(
// //                         title: const Text("Rechercher autour d'une ville"),
// //                         trailing: const Icon(Icons.expand_less),
// //                         onTap: () {
// //                           setState(() {
// //                             isTileExpanded = false;
// //                             cityController.clear();
// //                             distanceController.clear();
// //                           });
// //                         },
// //                       ),
// //                       Row(
// //                         children: [
// //                           Expanded(
// //                             child: Padding(
// //                               padding: const EdgeInsets.only(right: 8.0),
// //                               child: CityAutocompleteField(
// //                                 controller: cityController,
// //                                 apiKey: 'b097f188b11f46d2a02eb55021d168c1',
// //                                 onCitySelected: (ville) {},
// //                               ),
// //                             ),
// //                           ),
// //                           Expanded(
// //                             child: Padding(
// //                               padding: const EdgeInsets.only(right: 8.0),
// //                               child: TextField(
// //                                 controller: distanceController,
// //                                 onTap: () => distanceController.clear(),
// //                                 keyboardType: TextInputType.number,
// //                                 decoration: const InputDecoration(
// //                                   labelText: 'Distance (km)',
// //                                   border: OutlineInputBorder(),
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                           IconButton(
// //                             onPressed: _searchByCity,
// //                             icon: const Icon(Icons.search, size: 28),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Expanded(
// //             child: salons.isEmpty
// //                 ? const Center(child: Text("Aucun salon trouvé."))
// //                 : ListView.builder(
// //               itemCount: _paginatedSalons.length,
// //               itemBuilder: (context, index) {
// //                 final salon = _paginatedSalons[index];
// //
// //                 // Obtenir la distance, soit directement de l'API soit calculer localement
// //                 final distance = salon['distance'] ?? _calculateDistance(salon['position'] ?? "0,0");
// //
// //                 // Liste des coiffeuses pour ce salon (si disponible)
// //                 final List<dynamic> coiffeuses = salon['coiffeuses_details'] ?? [];
// //
// //                 return Card(
// //                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //                   child: InkWell(
// //                     onTap: () => _viewSalonDetails(salon),
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(8.0),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           ListTile(
// //                             leading: salon['logo'] != null && salon['logo'].toString().isNotEmpty
// //                                 ? CircleAvatar(
// //                               backgroundImage: NetworkImage("https://www.hairbnb.site${salon['logo']}"),
// //                             )
// //                                 : CircleAvatar(
// //                               child: Icon(Icons.spa),
// //                               backgroundColor: Colors.amber.shade100,
// //                             ),
// //                             title: Text(salon['nom'] ?? "Salon sans nom"),
// //                             subtitle: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 if (salon['slogan'] != null && salon['slogan'].toString().isNotEmpty)
// //                                   Text(
// //                                     salon['slogan'],
// //                                     style: TextStyle(fontStyle: FontStyle.italic),
// //                                   ),
// //                                 Text("Distance : ${distance.toStringAsFixed(1)} km"),
// //                               ],
// //                             ),
// //                             trailing: Icon(Icons.chevron_right),
// //                           ),
// //                           if (coiffeuses.isNotEmpty)
// //                             Padding(
// //                               padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
// //                               child: Wrap(
// //                                 spacing: 8.0,
// //                                 children: coiffeuses.take(3).map<Widget>((coiffeuse) {
// //                                   return Chip(
// //                                     avatar: coiffeuse['photo_profil'] != null && coiffeuse['photo_profil'].toString().isNotEmpty
// //                                         ? CircleAvatar(
// //                                       backgroundImage: NetworkImage("https://www.hairbnb.site${coiffeuse['photo_profil']}"),
// //                                     )
// //                                         : null,
// //                                     label: Text(
// //                                       "${coiffeuse['prenom']} ${coiffeuse['nom']}",
// //                                       style: TextStyle(fontSize: 12),
// //                                     ),
// //                                     backgroundColor: coiffeuse['est_proprietaire'] == true
// //                                         ? Colors.amber.shade100
// //                                         : Colors.grey.shade100,
// //                                   );
// //                                 }).toList(),
// //                               ),
// //                             ),
// //                           if (coiffeuses.length > 3)
// //                             Padding(
// //                               padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
// //                               child: Text(
// //                                 "+${coiffeuses.length - 3} autres coiffeuses",
// //                                 style: TextStyle(color: Colors.grey, fontSize: 12),
// //                               ),
// //                             ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //           if (salons.isNotEmpty)
// //             Column(
// //               children: [
// //                 Padding(
// //                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text("Page $_currentPage sur ${((salons.length - 1) / _itemsPerPage + 1).floor()}"),
// //                       Row(
// //                         children: [
// //                           const Text("Résultats par page : "),
// //                           DropdownButton<int>(
// //                             value: _itemsPerPage,
// //                             items: [5, 10, 20].map((value) {
// //                               return DropdownMenuItem<int>(
// //                                 value: value,
// //                                 child: Text('$value'),
// //                               );
// //                             }).toList(),
// //                             onChanged: (value) {
// //                               if (value != null) {
// //                                 setState(() {
// //                                   _itemsPerPage = value;
// //                                   _currentPage = 1;
// //                                 });
// //                               }
// //                             },
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 if (_currentPage * _itemsPerPage < salons.length)
// //                   Padding(
// //                     padding: const EdgeInsets.all(8.0),
// //                     child: ElevatedButton(
// //                       onPressed: () => setState(() => _currentPage++),
// //                       child: const Text("Afficher plus"),
// //                     ),
// //                   ),
// //               ],
// //             ),
// //         ],
// //       ),
// //       bottomNavigationBar: BottomNavBar(
// //         currentIndex: _currentIndex,
// //         onTap: _onTabTapped,
// //       ),
// //     );
// //   }
// // }