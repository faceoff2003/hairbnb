import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/show_favorites.dart';
import 'show_salon_page.dart';
import '../services/my_drawer_service/hairbnb_scaffold.dart';
import '../widgets/bottom_nav_bar.dart';
import 'api/favorites_api.dart';

class FavoriteSalonsPage extends StatefulWidget {
  final int currentUserId;

  const FavoriteSalonsPage({super.key, required this.currentUserId});

  @override
  State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
}

class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
  late Future<List<ShowFavorite>> _favoritesFuture;
  final url = 'https://www.hairbnb.site';
  final int _currentIndex = 4; // Index pour le profil dans la BottomNavBar

  @override
  void initState() {
    super.initState();
    _favoritesFuture = fetchFavorites(widget.currentUserId);
  }

  Future<List<ShowFavorite>> fetchFavorites(int userId) async {
    final url = Uri.parse('https://hairbnb.site/api/get_user_favorites/?user=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ShowFavorite.fromJson(json)).toList();
    } else {
      throw Exception("Impossible de charger les salons favoris");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilisation du HairbnbScaffold à la place du Scaffold standard
    return HairbnbScaffold(
      body: Container(
        color: Colors.grey[100], // Fond gris clair comme sur l'image
        child: FutureBuilder<List<ShowFavorite>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.purple));
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Aucun salon favori trouvé.'));
            } else {
              final favorites = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec titre stylisé
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: const Text(
                      'Favoris',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final salon = favorites[index].salon;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalonDetailsPage(
                                    salonId: salon.idTblSalon,
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    url + salon.logoSalon,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(url + salon.logoSalon),
                                        radius: 25,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              salon.nomSalon,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              salon.slogan,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Supprimer ce favori ?'),
                                              content: const Text('Cette action est irréversible.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Annuler'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              final success = await FavoritesApi.removeFavorite(favorites[index].idTblFavorite);
                                              if (success) {
                                                setState(() {
                                                  favorites.removeAt(index);
                                                });
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Favori supprimé avec succès'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Erreur : $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Gérer la navigation si nécessaire
        },
      ),
    );
  }
}





// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../models/show_favorites.dart';
// import '../pages/profil/profil_widgets/show_salon_page.dart';
// import '../widgets/custom_app_bar.dart'; // Import de la CustomAppBar
// import '../widgets/bottom_nav_bar.dart'; // Import de la BottomNavBar
// import 'api/favorites_api.dart';
//
// class FavoriteSalonsPage extends StatefulWidget {
//   final int currentUserId;
//
//   const FavoriteSalonsPage({super.key, required this.currentUserId});
//
//   @override
//   State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
// }
//
// class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
//   late Future<List<ShowFavorite>> _favoritesFuture;
//   final url = 'https://www.hairbnb.site';
//   final int _currentIndex = 4; // Index pour le profil dans la BottomNavBar
//
//   @override
//   void initState() {
//     super.initState();
//     _favoritesFuture = fetchFavorites(widget.currentUserId);
//   }
//
//   Future<List<ShowFavorite>> fetchFavorites(int userId) async {
//     final url = Uri.parse('https://hairbnb.site/api/get_user_favorites/?user=$userId');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((json) => ShowFavorite.fromJson(json)).toList();
//     } else {
//       throw Exception("Impossible de charger les salons favoris");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(), // Utilisation de la CustomAppBar
//       body: Container(
//         color: Colors.grey[100], // Fond gris clair comme sur l'image
//         child: FutureBuilder<List<ShowFavorite>>(
//           future: _favoritesFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator(color: Colors.purple));
//             } else if (snapshot.hasError) {
//               return Center(child: Text('Erreur : ${snapshot.error}'));
//             } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return const Center(child: Text('Aucun salon favori trouvé.'));
//             } else {
//               final favorites = snapshot.data!;
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // En-tête avec titre stylisé
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
//                     child: const Text(
//                       'Favoris',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.purple,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       itemCount: favorites.length,
//                       itemBuilder: (context, index) {
//                         final salon = favorites[index].salon;
//                         return Container(
//                           margin: const EdgeInsets.only(bottom: 16),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.withOpacity(0.2),
//                                 spreadRadius: 1,
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: InkWell(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => SalonDetailsPage(
//                                     salonId: salon.idTblSalon,
//                                     currentUserId: widget.currentUserId,
//                                   ),
//                                 ),
//                               );
//                             },
//                             borderRadius: BorderRadius.circular(16),
//                             child: Column(
//                               children: [
//                                 ClipRRect(
//                                   borderRadius: const BorderRadius.only(
//                                     topLeft: Radius.circular(16),
//                                     topRight: Radius.circular(16),
//                                   ),
//                                   child: Image.network(
//                                     url + salon.logoSalon,
//                                     height: 120,
//                                     width: double.infinity,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return Container(
//                                         height: 120,
//                                         color: Colors.grey[300],
//                                         child: const Center(
//                                           child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Row(
//                                     children: [
//                                       CircleAvatar(
//                                         backgroundImage: NetworkImage(url + salon.logoSalon),
//                                         radius: 25,
//                                       ),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               salon.nomSalon,
//                                               style: const TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               salon.slogan,
//                                               style: TextStyle(
//                                                 fontSize: 14,
//                                                 color: Colors.grey[600],
//                                               ),
//                                               maxLines: 2,
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.delete, color: Colors.red),
//                                         onPressed: () async {
//                                           final confirm = await showDialog<bool>(
//                                             context: context,
//                                             builder: (context) => AlertDialog(
//                                               title: const Text('Supprimer ce favori ?'),
//                                               content: const Text('Cette action est irréversible.'),
//                                               actions: [
//                                                 TextButton(
//                                                   onPressed: () => Navigator.pop(context, false),
//                                                   child: const Text('Annuler'),
//                                                 ),
//                                                 TextButton(
//                                                   onPressed: () => Navigator.pop(context, true),
//                                                   child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//
//                                           if (confirm == true) {
//                                             try {
//                                               final success = await FavoritesApi.removeFavorite(favorites[index].idTblFavorite);
//                                               if (success) {
//                                                 setState(() {
//                                                   favorites.removeAt(index);
//                                                 });
//                                                 if (!mounted) return;
//                                                 ScaffoldMessenger.of(context).showSnackBar(
//                                                   const SnackBar(
//                                                     content: Text('Favori supprimé avec succès'),
//                                                     backgroundColor: Colors.green,
//                                                   ),
//                                                 );
//                                               }
//                                             } catch (e) {
//                                               if (!mounted) return;
//                                               ScaffoldMessenger.of(context).showSnackBar(
//                                                 SnackBar(
//                                                   content: Text('Erreur : $e'),
//                                                   backgroundColor: Colors.red,
//                                                 ),
//                                               );
//                                             }
//                                           }
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               );
//             }
//           },
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           // Gérer la navigation si nécessaire
//         },
//       ),
//     );
//   }
// }




// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../models/show_favorites.dart';
// import '../pages/profil/profil_widgets/show_salon_page.dart';
// import 'api/favorites_api.dart'; // Assure-toi que ce fichier contient ton modèle corrigé
//
// class FavoriteSalonsPage extends StatefulWidget {
//   final int currentUserId;
//
//   const FavoriteSalonsPage({Key? key, required this.currentUserId}) : super(key: key);
//
//   @override
//   State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
// }
//
// class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
//   late Future<List<ShowFavorite>> _favoritesFuture;
//   final url = 'https://www.hairbnb.site';
//
//   @override
//   void initState() {
//     super.initState();
//     _favoritesFuture = fetchFavorites(widget.currentUserId);
//   }
//
//   Future<List<ShowFavorite>> fetchFavorites(int userId) async {
//     final url = Uri.parse('https://hairbnb.site/api/get_user_favorites/?user=$userId');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((json) => ShowFavorite.fromJson(json)).toList();
//     } else {
//       throw Exception("Impossible de charger les salons favoris");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mes salons favoris'),
//       ),
//       body: FutureBuilder<List<ShowFavorite>>(
//         future: _favoritesFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Erreur : ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('Aucun salon favori trouvé.'));
//           } else {
//             final favorites = snapshot.data!;
//             return ListView.builder(
//               itemCount: favorites.length,
//               itemBuilder: (context, index) {
//                 final salon = favorites[index].salon;
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: NetworkImage(url+salon.logoSalon),
//                     ),
//                     title: Text(salon.nomSalon),
//                     subtitle: Text(salon.slogan),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => SalonDetailsPage(
//                             salonId: salon.idTblSalon,
//                             currentUserId: widget.currentUserId,
//                           ),
//                         ),
//                       );
//                     },
//                     trailing: IconButton(
//                       icon: Icon(Icons.delete, color: Colors.red),
//                       onPressed: () async {
//                         final confirm = await showDialog<bool>(
//                           context: context,
//                           builder: (context) => AlertDialog(
//                             title: Text('Supprimer ce favori ?'),
//                             content: Text('Cette action est irréversible.'),
//                             actions: [
//                               TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
//                               TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Supprimer')),
//                             ],
//                           ),
//                         );
//
//                         if (confirm == true) {
//                           try {
//                             final success = await FavoritesApi.removeFavorite(favorites[index].idTblFavorite);
//                             if (success) {
//                               setState(() {
//                                 favorites.removeAt(index);
//                               });
//                             }
//                           } catch (e) {
//                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
//                           }
//                         }
//                       },
//                     ),
//                   )
//
//
//
//                   // child: ListTile(
//                   //   leading: CircleAvatar(
//                   //     backgroundImage: NetworkImage(url+salon.logoSalon),
//                   //   ),
//                   //   title: Text(salon.nomSalon),
//                   //   subtitle: Text(salon.slogan),
//                   //   onTap: () {
//                   //     Navigator.push(
//                   //       context,
//                   //       MaterialPageRoute(
//                   //         builder: (context) => SalonDetailsPage(
//                   //           salonId: salon.idTblSalon,
//                   //           currentUserId: widget.currentUserId,
//                   //         ),
//                   //       ),
//                   //     );
//                   //   },
//                   // ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../models/favorites.dart';
// import '../services/favorites_service.dart';
// import '../widgets/custom_app_bar.dart';
// import '../widgets/bottom_nav_bar.dart';
// import '../models/salon_preview.dart'; // Créer ce modèle si tu ne l'as pas déjà
// import 'salon_details_page.dart';
//
// class FavoriteSalonsPage extends StatefulWidget {
//   final int currentUserId;
//
//   const FavoriteSalonsPage({Key? key, required this.currentUserId}) : super(key: key);
//
//   @override
//   _FavoriteSalonsPageState createState() => _FavoriteSalonsPageState();
// }
//
// class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
//   late Future<List<SalonPreview>> _favoritesFuture;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadFavorites();
//   }
//
//   Future<void> _loadFavorites() async {
//     setState(() {
//       _isLoading = true;
//       _favoritesFuture = _getFavoriteSalons();
//     });
//   }
//
//   Future<List<SalonPreview>> _getFavoriteSalons() async {
//     try {
//       // Récupérer les favoris
//       final favorites = await FavoritesService.getUserFavorites(widget.currentUserId);
//
//       // Convertir les IDs de salon en objets SalonPreview
//       final List<SalonPreview> salons = [];
//
//       for (var favorite in favorites) {
//         // Tu devras créer cette méthode dans ton API pour récupérer les détails simplifiés d'un salon
//         final salonDetails = await SalonApi.getSalonPreview(favorite.salon);
//         if (salonDetails != null) {
//           salons.add(salonDetails);
//         }
//       }
//
//       setState(() => _isLoading = false);
//       return salons;
//     } catch (e) {
//       setState(() => _isLoading = false);
//       print('Erreur lors du chargement des favoris: $e');
//       throw Exception('Impossible de charger les favoris');
//     }
//   }
//
//   Future<void> _removeFavorite(FavoriteModel favorite) async {
//     try {
//       setState(() => _isLoading = true);
//
//       final success = await FavoritesService.removeFavorite(favorite.idTblFavorite);
//
//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Salon retiré des favoris'),
//             duration: Duration(seconds: 1),
//           ),
//         );
//
//         // Recharger la liste
//         _loadFavorites();
//       } else {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Échec de la suppression du favori')),
//         );
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9FB),
//       appBar: const CustomAppBar(title: 'Mes favoris'),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 2, // Ajuste selon ton application
//         onTap: (index) {
//           // Gérer la navigation
//         },
//       ),
//       body: SafeArea(
//         child: _isLoading && !_favoritesFuture.isCompleted
//             ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
//             : FutureBuilder<List<SalonPreview>>(
//           future: _favoritesFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(color: Colors.deepPurple),
//               );
//             } else if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 60),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Erreur lors du chargement des favoris',
//                       style: GoogleFonts.poppins(fontSize: 16),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: _loadFavorites,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: const Text('Réessayer'),
//                     ),
//                   ],
//                 ),
//               );
//             } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Vous n\'avez pas encore de favoris',
//                       style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Explorez nos salons et ajoutez-les à vos favoris',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey[500],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         // Naviguer vers la page d'exploration des salons
//                         Navigator.pop(context);
//                       },
//                       icon: const Icon(Icons.search),
//                       label: const Text('Explorer les salons'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             final salons = snapshot.data!;
//             return RefreshIndicator(
//               onRefresh: _loadFavorites,
//               color: Colors.deepPurple,
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: salons.length,
//                 itemBuilder: (context, index) {
//                   final salon = salons[index];
//                   return _buildSalonCard(salon);
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSalonCard(SalonPreview salon) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => SalonDetailsPage(
//                 salonId: salon.idTblSalon,
//                 currentUserId: widget.currentUserId,
//               ),
//             ),
//           ).then((_) => _loadFavorites()); // Recharger après retour
//         },
//         borderRadius: BorderRadius.circular(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image du salon
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//               child: salon.logoSalon != null && salon.logoSalon!.isNotEmpty
//                   ? Image.network(
//                 salon.logoSalon!,
//                 height: 150,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               )
//                   : Container(
//                 height: 150,
//                 width: double.infinity,
//                 color: Colors.grey[300],
//                 child: const Icon(Icons.storefront, size: 50, color: Colors.grey),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           salon.nomSalon,
//                           style: GoogleFonts.poppins(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.shade600,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.star, size: 14, color: Colors.white),
//                             const SizedBox(width: 4),
//                             Text(
//                               salon.noteMoyenne.toString(),
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   if (salon.adresse != null)
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             salon.adresse!,
//                             style: GoogleFonts.poppins(
//                               fontSize: 13,
//                               color: Colors.grey[600],
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => SalonDetailsPage(
//                                 salonId: salon.idTblSalon,
//                                 currentUserId: widget.currentUserId,
//                               ),
//                             ),
//                           ).then((_) => _loadFavorites());
//                         },
//                         icon: const Icon(Icons.visibility, size: 18),
//                         label: const Text('Voir détails'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.deepPurple,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () async {
//                           // Tu devras implémenter une méthode pour retrouver le FavoriteModel à partir de l'ID du salon
//                           final favorite = await FavoritesService.getFavoriteForSalon(widget.currentUserId, salon.idTblSalon);
//                           if (favorite != null) {
//                             _removeFavorite(favorite);
//                           }
//                         },
//                         icon: const Icon(Icons.favorite, color: Colors.red),
//                         tooltip: 'Retirer des favoris',
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Extension pour vérifier si un Future est complété (pour éviter des erreurs d'interface)
// extension FutureExtension<T> on Future<T> {
//   bool get isCompleted {
//     bool isCompleted = false;
//     whenComplete(() => isCompleted = true);
//     return isCompleted;
//   }
// }