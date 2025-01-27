import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hairbnb/pages/salon/salon_services_list/create_services_page.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CreateSalonPage extends StatefulWidget {
  final String userUuid;

  const CreateSalonPage({required this.userUuid, Key? key}) : super(key: key);

  @override
  State<CreateSalonPage> createState() => _CreateSalonPageState();
}

class _CreateSalonPageState extends State<CreateSalonPage> {
  final TextEditingController sloganController = TextEditingController();
  Uint8List? logoBytes; // Pour les fichiers sur Web
  File? logoFile; // Pour les fichiers sur Mobile/Desktop
  bool isLoading = false; // Indicateur de chargement

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un salon"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Créer un salon",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildLogoPicker(),
            const SizedBox(height: 20),
            _buildTextField("Slogan du salon", sloganController),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _saveSalon,
              child: const Text("Enregistrer"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _skipCreation,
              child: const Text("Ignorer cette étape"),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour sélectionner un logo
  Widget _buildLogoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Logo du salon (facultatif)",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: _pickLogo,
              child: const Text("Choisir un logo"),
            ),
            const SizedBox(width: 10),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: logoBytes != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  logoBytes!,
                  fit: BoxFit.cover,
                ),
              )
                  : logoFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  logoFile!,
                  fit: BoxFit.cover,
                ),
              )
                  : const Center(
                child: Text(
                  "Aucune image",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Méthode pour choisir un logo
  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          logoBytes = result.files.first.bytes;
          logoFile = null;
        } else {
          logoFile = File(result.files.first.path!);
          logoBytes = null;
        }
      });
    }
  }


  /// Méthode pour sauvegarder le salon
  Future<void> _saveSalon() async {
    if (sloganController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le slogan est obligatoire.")),
      );
      return;
    }

    if (logoFile == null && logoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le logo est obligatoire.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("http://192.168.0.248:8000/api/create_salon/");
    final request = http.MultipartRequest('POST', url);

    // Ajouter les champs de formulaire
    request.fields['userUuid'] = widget.userUuid;
    request.fields['slogan'] = sloganController.text;

    // Ajouter le logo si présent
    if (logoBytes != null && kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'logo_salon',
          logoBytes!,
          filename: 'salon_logo.png',
          contentType: MediaType('image', 'png'),
        ),
      );
    } else if (logoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'logo_salon',
          logoFile!.path,
          contentType: MediaType('image', 'png'),
        ),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Salon créé avec succès!")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateServicesPage()),
        );
      } else {
        debugPrint("Erreur backend : $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la création : $responseBody")),
        );
      }
    } catch (e) {
      debugPrint("Erreur de connexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion au serveur.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  /// Méthode pour ignorer la création du salon
  void _skipCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateServicesPage()),
    );
  }

  /// Fonction générique pour TextField
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}



















// /// Méthode pour sauvegarder le salon
// Future<void> _saveSalon() async {
//   if (sloganController.text.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Le slogan est obligatoire.")),
//     );
//     return;
//   }
//
//   setState(() {
//     isLoading = true;
//   });
//
//   final url = Uri.parse("http://127.0.0.1:8000/api/create_salon/");
//   final request = http.MultipartRequest('POST', url);
//
//   // Ajouter les champs de formulaire
//   request.fields['userUuid'] = "WSmkeiUCcKWaJBBrTSaV99puXw83";//widget.userUuid;
//   request.fields['slogan'] = sloganController.text;
//
//   // Ajouter le logo si présent
//   if (logoBytes != null && kIsWeb) {
//     request.files.add(
//       http.MultipartFile.fromBytes(
//         'logo_salon',
//         logoBytes!,
//         filename: 'salon_logo.png',
//         contentType: MediaType('image', 'png'),
//       ),
//     );
//   } else if (logoFile != null) {
//     request.files.add(
//       await http.MultipartFile.fromPath(
//         'logo_salon',
//         logoFile!.path,
//         contentType: MediaType('image', 'png'),
//       ),
//     );
//   }
//
//   try {
//     final response = await request.send();
//     final responseBody = await response.stream.bytesToString();
//
//     if (response.statusCode == 201) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Salon créé avec succès!")),
//       );
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const CreateServicesPage()),
//       );
//     } else {
//       debugPrint("Erreur backend : $responseBody");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//       );
//     }
//   } catch (e) {
//     debugPrint("Erreur de connexion : $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Erreur de connexion au serveur.")),
//     );
//   } finally {
//     setState(() {
//       isLoading = false;
//     });
//   }
// }




// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   final String userUuid;
//
//   const CreateSalonPage({required this.userUuid, Key? key}) : super(key: key);
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   final TextEditingController sloganController = TextEditingController();
//   Uint8List? logoBytes; // Pour les fichiers sur Web
//   File? logoFile; // Pour les fichiers sur Mobile/Desktop
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer un salon"),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Créer un salon",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             _buildLogoPicker(),
//             const SizedBox(height: 20),
//             _buildTextField("Slogan du salon", sloganController),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _saveSalon,
//               child: const Text("Enregistrer"),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: _skipCreation,
//               child: const Text("Ignorer cette étape"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Widget pour sélectionner un logo
//   Widget _buildLogoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Logo du salon (facultatif)",
//           style: TextStyle(fontSize: 16),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             ElevatedButton(
//               onPressed: _pickLogo,
//               child: const Text("Choisir un logo"),
//             ),
//             const SizedBox(width: 10),
//             Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: logoBytes != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.memory(
//                   logoBytes!,
//                   fit: BoxFit.cover,
//                 ),
//               )
//                   : logoFile != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(
//                   logoFile!,
//                   fit: BoxFit.cover,
//                 ),
//               )
//                   : const Center(
//                 child: Text(
//                   "Aucune image",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   /// Méthode pour choisir un logo
//   Future<void> _pickLogo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//
//     if (result != null) {
//       setState(() {
//         if (kIsWeb) {
//           logoBytes = result.files.first.bytes;
//           logoFile = null;
//         } else {
//           logoFile = File(result.files.first.path!);
//           logoBytes = null;
//         }
//       });
//     }
//   }
//
//   /// Méthode pour sauvegarder le salon
//   void _saveSalon() {
//     // Préparez les données à envoyer au backend
//     final Map<String, dynamic> salonData = {
//       "userUuid": widget.userUuid,
//       "slogan": sloganController.text,
//     };
//
//     if (logoBytes != null) {
//       salonData['logo'] = "Bytes sélectionnés"; // Placeholder pour les bytes
//     } else if (logoFile != null) {
//       salonData['logo'] = "Fichier sélectionné : ${logoFile!.path}";
//     }
//
//     // Simulez une action d'enregistrement
//     debugPrint("Données salon : $salonData");
//
//     // Une fois enregistré, redirigez vers la page services
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const CreateServicesPage()),
//     );
//   }
//
//   /// Méthode pour ignorer la création du salon
//   void _skipCreation() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const CreateServicesPage()),
//     );
//   }
//
//   /// Fonction générique pour TextField
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }
// }
//
// /// Placeholder pour la page des services
// class CreateServicesPage extends StatelessWidget {
//   const CreateServicesPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer des services"),
//       ),
//       body: const Center(
//         child: Text("Page de création de services"),
//       ),
//     );
//   }
// }
//
//








// import 'package:flutter/material.dart';
//
// class CreateSalonPage extends StatelessWidget {
//   final String userUuid;
//
//   const CreateSalonPage({required this.userUuid, Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer un salon"),
//       ),
//       body: Center(
//         child: Text("Page de création de salon pour l'utilisateur: $userUuid"),
//       ),
//     );
//   }
// }
