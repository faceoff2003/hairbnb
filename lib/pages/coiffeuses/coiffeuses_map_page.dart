import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hairbnb/pages/coiffeuses/services/city_autocomplete.dart';
import 'package:hairbnb/pages/coiffeuses/services/geocoding_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hairbnb/pages/coiffeuses/services/api_location_service.dart';
import 'package:hairbnb/pages/coiffeuses/services/location_service.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/Custom_app_bar.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import '../salon/salon_services_list/salon_coiffeuse_page.dart';
import '../chat/chat_page.dart';
import '../../models/coiffeuse.dart';

class CoiffeusesListPage extends StatefulWidget {
  @override
  _CoiffeusesListPageState createState() => _CoiffeusesListPageState();
}

class _CoiffeusesListPageState extends State<CoiffeusesListPage> {
  List<dynamic> coiffeuses = [];
  Position? _currentPosition;
  Position? _gpsPosition;
  double _gpsRadius = 10.0;
  final TextEditingController cityController = TextEditingController();
  final TextEditingController distanceController = TextEditingController();
  bool isTileExpanded = false;
  late CurrentUser? currentUser;
  int _currentIndex = 1;
  String? activeSearchLabel;

  int _itemsPerPage = 10;
  int _currentPage = 1;

  List<dynamic> get _paginatedCoiffeuses {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = _currentPage * _itemsPerPage;
    return coiffeuses.sublist(start, end > coiffeuses.length ? coiffeuses.length : end);
  }

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final position = await LocationService.getUserLocation();
      if (position != null) {
        setState(() {
          _gpsPosition = position;
          _currentPosition = position;
          activeSearchLabel = "📍 Autour de ma position actuelle (${_gpsRadius.toInt()} km)";
        });
        await _fetchCoiffeuses(position, _gpsRadius);
      }
    } catch (e) {
      print("❌ Erreur de localisation : $e");
    }
  }

  Future<void> _fetchCoiffeuses(Position position, double radius) async {
    try {
      final nearbyCoiffeuses = await ApiService.fetchNearbyCoiffeuses(
        position.latitude,
        position.longitude,
        radius,
      );

      currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

      final filtered = nearbyCoiffeuses.where((c) {
        return c['user']['uuid'] != currentUser?.uuid;
      }).toList();

      setState(() {
        coiffeuses = filtered;
        _currentPage = 1;
      });
    } catch (e) {
      print("❌ Erreur API : $e");
    }
  }

  Future<void> _searchByCity() async {
    final city = cityController.text.trim();
    final distanceText = distanceController.text.trim();

    if (city.isEmpty || distanceText.isEmpty) return;

    final parsedDistance = double.tryParse(distanceText);
    if (parsedDistance == null || parsedDistance > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Distance invalide. Maximum 150 km.")),
      );
      return;
    }

    final position = await GeocodingService.getCoordinatesFromCity(city);
    if (position != null) {
      setState(() {
        _currentPosition = position;
        activeSearchLabel = "🏙️ Autour de $city (${parsedDistance.toInt()} km)";
        isTileExpanded = false;
      });
      await _fetchCoiffeuses(position, parsedDistance);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ville introuvable.")),
      );
    }
  }

  double _calculateDistance(String coiffeusePosition) {
    try {
      final parts = coiffeusePosition.split(',');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeSearchLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      activeSearchLabel!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  ),
                const Text("Autour de ma position actuelle :"),
                Slider(
                  value: _gpsRadius,
                  min: 1,
                  max: 50,
                  divisions: 10,
                  label: "${_gpsRadius.toInt()} km",
                  onChanged: (val) {
                    setState(() {
                      _gpsRadius = val;
                      _currentPosition = _gpsPosition;
                      cityController.clear();
                      distanceController.clear();
                      activeSearchLabel = "📍 Autour de ma position actuelle (${_gpsRadius.toInt()} km)";
                    });
                    if (_gpsPosition != null) {
                      _fetchCoiffeuses(_gpsPosition!, _gpsRadius);
                    }
                  },
                ),
                const Divider(),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isTileExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: ListTile(
                    title: const Text("Rechercher autour d'une ville"),
                    trailing: const Icon(Icons.expand_more),
                    onTap: () {
                      setState(() {
                        isTileExpanded = true;
                        cityController.clear();
                        distanceController.clear();
                      });
                    },
                  ),
                  secondChild: Column(
                    children: [
                      ListTile(
                        title: const Text("Rechercher autour d'une ville"),
                        trailing: const Icon(Icons.expand_less),
                        onTap: () {
                          setState(() {
                            isTileExpanded = false;
                            cityController.clear();
                            distanceController.clear();
                          });
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CityAutocompleteField(
                                controller: cityController,
                                apiKey: 'b097f188b11f46d2a02eb55021d168c1',
                                onCitySelected: (ville) {},
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextField(
                                controller: distanceController,
                                onTap: () => distanceController.clear(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Distance (km)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _searchByCity,
                            icon: const Icon(Icons.search, size: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: coiffeuses.isEmpty
                ? const Center(child: Text("Aucune coiffeuse trouvée."))
                : ListView.builder(
              itemCount: _paginatedCoiffeuses.length,
              itemBuilder: (context, index) {
                final c = _paginatedCoiffeuses[index];
                final distance = _calculateDistance(c['position']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: c['user']['photo_profil'] != null &&
                          c['user']['photo_profil'].isNotEmpty
                          ? NetworkImage("https://www.hairbnb.site${c['user']['photo_profil']}")
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                    title: Text("${c['user']['nom']} ${c['user']['prenom']}"),
                    subtitle: Text("Distance : ${distance.toStringAsFixed(1)} km"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.orange),
                          onPressed: () {
                            final coiffeuseObj = Coiffeuse.fromJson(c);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SalonCoiffeusePage(coiffeuse: coiffeuseObj),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue),
                          onPressed: () {
                            if (currentUser?.uuid == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  currentUser: currentUser!,
                                  otherUserId: c['user']['uuid'],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (coiffeuses.isNotEmpty)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Page $_currentPage sur ${((coiffeuses.length - 1) / _itemsPerPage + 1).floor()}"),
                      Row(
                        children: [
                          const Text("Résultats par page : "),
                          DropdownButton<int>(
                            value: _itemsPerPage,
                            items: [5, 10, 20].map((value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_currentPage * _itemsPerPage < coiffeuses.length)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _currentPage++),
                      child: const Text("Afficher plus"),
                    ),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}