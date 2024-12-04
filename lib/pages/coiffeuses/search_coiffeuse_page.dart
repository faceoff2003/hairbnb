import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class SearchCoiffeusePage extends StatefulWidget {
  const SearchCoiffeusePage({Key? key}) : super(key: key);

  @override
  State<SearchCoiffeusePage> createState() => _SearchCoiffeusePageState();
}

class _SearchCoiffeusePageState extends State<SearchCoiffeusePage> {
  List<dynamic> coiffeuses = [];
  bool isLoading = false;
  bool hasError = false;

  final String baseUrl = 'http://192.168.0.202:8000'; // Domaine de votre API

  @override
  void initState() {
    super.initState();
    _fetchCoiffeuses();
  }

  Future<void> _fetchCoiffeuses() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/list_coiffeuses/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          coiffeuses = json.decode(response.body)['data'];
        });
      } else {
        setState(() {
          hasError = true;
        });
        _showError("Erreur lors du chargement des coiffeuses.");
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      _showError("Erreur de connexion au serveur.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rechercher des coiffeuses"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Erreur de chargement",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchCoiffeuses,
              child: const Text("Réessayer"),
            ),
          ],
        ),
      )
          : coiffeuses.isEmpty
          ? const Center(
        child: Text(
          "Aucune coiffeuse trouvée.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: coiffeuses.length,
        itemBuilder: (context, index) {
          final coiffeuse = coiffeuses[index];
          final imageUrl =
          coiffeuse['photo_profil'] != null && coiffeuse['photo_profil'].isNotEmpty
              ? '$baseUrl${coiffeuse['photo_profil']}'
              : 'assets/default_avatar.png';

          return Card(
            margin: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 16),
            elevation: 4,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: imageUrl.startsWith('http')
                    ? NetworkImage(imageUrl)
                    : AssetImage(imageUrl) as ImageProvider,
                radius: 30,
              ),
              title: Text(
                "${coiffeuse['nom']} ${coiffeuse['prenom']}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("UUID: ${coiffeuse['uuid']}"),
                  Text("Téléphone: ${coiffeuse['numero_telephone']}"),
                  Text(
                      "Denomination: ${coiffeuse['denomination_sociale'] ?? 'Non définie'}"),
                  Text("TVA: ${coiffeuse['tva'] ?? 'Non définie'}"),
                  Text("Position: ${coiffeuse['position'] ?? 'Non définie'}"),
                ],
              ),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () {
                  print("Start chat with UUID: ${coiffeuse['uuid']}");
                },
                child: const Text("Contacter"),
              ),
            ),
          );
        },
      ),
    );
  }
}





// class SearchCoiffeusePage extends StatefulWidget {
//   const SearchCoiffeusePage({Key? key}) : super(key: key);
//
//   @override
//   State<SearchCoiffeusePage> createState() => _SearchCoiffeusePageState();
// }
//
// class _SearchCoiffeusePageState extends State<SearchCoiffeusePage> {
//   List<dynamic> coiffeuses = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCoiffeuses();
//   }
//
//   Future<void> _fetchCoiffeuses() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.202:8000/api/list_coiffeuses/'),
//       );
//
//       print("Response status: ${response.statusCode}");
//       print("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         // Analyse correcte pour extraire uniquement la liste des coiffeuses
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         setState(() {
//           coiffeuses = jsonResponse['data'];
//         });
//       } else {
//         setState(() {
//           hasError = true;
//         });
//         _showError("Erreur lors du chargement des coiffeuses : ${response.body}");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//       _showError("Erreur de connexion au serveur : $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Rechercher des coiffeuses"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Erreur de chargement",
//               style: TextStyle(
//                   fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _fetchCoiffeuses,
//               child: const Text("Réessayer"),
//             ),
//           ],
//         ),
//       )
//           : coiffeuses.isEmpty
//           ? const Center(
//         child: Text(
//           "Aucune coiffeuse trouvée.",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : ListView.builder(
//         itemCount: coiffeuses.length,
//         itemBuilder: (context, index) {
//           final coiffeuse = coiffeuses[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(
//                 vertical: 8, horizontal: 16),
//             elevation: 4,
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundImage: coiffeuse['photo_profil'] != null
//                     ? NetworkImage(coiffeuse['photo_profil'])
//                     : const AssetImage(
//                     'assets/default_avatar.png')
//                 as ImageProvider,
//                 radius: 30,
//               ),
//               title: Text(
//                 "${coiffeuse['nom']} ${coiffeuse['prenom']}",
//                 style: const TextStyle(
//                     fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("UUID: ${coiffeuse['uuid']}"),
//                   Text(
//                       "Téléphone: ${coiffeuse['numero_telephone']}"),
//                   Text(
//                       "Denomination: ${coiffeuse['denomination_sociale'] ?? 'Non définie'}"),
//                   Text("TVA: ${coiffeuse['tva'] ?? 'Non définie'}"),
//                   Text(
//                       "Position: ${coiffeuse['position'] ?? 'Non définie'}"),
//                 ],
//               ),
//               isThreeLine: true,
//               onTap: () {
//                 // Logique pour démarrer une conversation basée sur UUID
//                 print("Start chat with UUID: ${coiffeuse['uuid']}");
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SearchCoiffeusePage extends StatefulWidget {
//   const SearchCoiffeusePage({Key? key}) : super(key: key);
//
//   @override
//   State<SearchCoiffeusePage> createState() => _SearchCoiffeusePageState();
// }
//
// class _SearchCoiffeusePageState extends State<SearchCoiffeusePage> {
//   List<dynamic> coiffeuses = [];
//   bool isLoading = false;
//   bool hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCoiffeuses();
//   }
//
//   Future<void> _fetchCoiffeuses() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://192.168.0.202:8000/api/list_coiffeuses/'),
//       );
//
//       if (response.statusCode == 200) {
//         setState(() {
//           coiffeuses = json.decode(response.body)['data'];
//         });
//       } else {
//         setState(() {
//           hasError = true;
//         });
//         _showError("Erreur lors du chargement des coiffeuses.");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Rechercher des coiffeuses"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hasError
//           ? Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Erreur de chargement",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _fetchCoiffeuses,
//               child: const Text("Réessayer"),
//             ),
//           ],
//         ),
//       )
//           : coiffeuses.isEmpty
//           ? const Center(
//         child: Text(
//           "Aucune coiffeuse trouvée.",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : ListView.builder(
//         itemCount: coiffeuses.length,
//         itemBuilder: (context, index) {
//           final coiffeuse = coiffeuses[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//             elevation: 4,
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundImage: coiffeuse['photo_profil'] != null
//                     ? NetworkImage(coiffeuse['photo_profil'])
//                     : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                 radius: 30,
//               ),
//               title: Text(
//                 "${coiffeuse['nom']} ${coiffeuse['prenom']}",
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("UUID: ${coiffeuse['uuid']}"),
//                   Text("Téléphone: ${coiffeuse['numero_telephone']}"),
//                   Text("Denomination: ${coiffeuse['denomination_sociale'] ?? 'Non définie'}"),
//                   Text("TVA: ${coiffeuse['tva'] ?? 'Non définie'}"),
//                   Text("Position: ${coiffeuse['position'] ?? 'Non définie'}"),
//                 ],
//               ),
//               isThreeLine: true,
//               onTap: () {
//                 // Logique pour démarrer une conversation basée sur UUID
//                 print("Start chat with UUID: ${coiffeuse['uuid']}");
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
