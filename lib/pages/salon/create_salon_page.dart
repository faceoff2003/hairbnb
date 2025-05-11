import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/add_service_page.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '../../models/current_user.dart';
import '../../models/salon_create.dart';
import '../../services/providers/current_user_provider.dart';

class CreateSalonPage extends StatefulWidget {
  final CurrentUser currentUser;

  const CreateSalonPage({required this.currentUser, super.key});

  @override
  State<CreateSalonPage> createState() => _CreateSalonPageState();
}

class _CreateSalonPageState extends State<CreateSalonPage> {
  final TextEditingController nomSalonController = TextEditingController();
  final TextEditingController sloganController = TextEditingController();
  Uint8List? logoBytes;
  File? logoFile;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text("Créer un salon"),
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // Supprime la flèche de retour
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Détails du salon",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField("Nom du salon", nomSalonController, Icons.storefront),
                    const SizedBox(height: 20),
                    _buildTextField("Slogan du salon", sloganController, Icons.short_text),
                    const SizedBox(height: 20),
                    _buildLogoPicker(),
                    const SizedBox(height: 40),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onHover: (hovering) {}, // à personnaliser si besoin
                            onPressed: isLoading ? null : _saveSalon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: const Color(0x887B61FF),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.all(const Color(0xFF674ED1)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Créer le salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Logo du salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.image_outlined),
              label: const Text("Choisir une image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF7B61FF),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: logoBytes != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(logoBytes!, fit: BoxFit.cover),
              )
                  : logoFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(logoFile!, fit: BoxFit.cover),
              )
                  : const Center(child: Text("Aucune image", style: TextStyle(fontSize: 12))),
            ),
          ],
        ),
      ],
    );
  }

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

  Future<void> _saveSalon() async {
    final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

    List<String> champsManquants = [];
    if (nomSalonController.text.isEmpty) champsManquants.add("Nom du salon");
    if (sloganController.text.isEmpty) champsManquants.add("Slogan du salon");
    if (logoFile == null && logoBytes == null) champsManquants.add("Logo du salon");

    if (champsManquants.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez renseigner : ${champsManquants.join(", ")}"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final salon = SalonCreateModel(
      idTblUser: utilisateurActuelle!.idTblUser,
      nomSalon: nomSalonController.text,
      slogan: sloganController.text,
      logo: kIsWeb ? logoBytes : logoFile,
    );

    setState(() => isLoading = true);

    final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon_serializer_view/");
    final request = http.MultipartRequest('POST', url)..fields.addAll(salon.toFields());

    if (kIsWeb && logoBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'logo_salon',
        salon.logo,
        filename: 'logo.png',
        contentType: MediaType('image', 'png'),
      ));
    } else if (logoFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'logo_salon',
        (salon.logo as File).path,
        contentType: MediaType('image', 'png'),
      ));
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        final salonId = decoded['salon_id'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Salon créé avec succès!")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddServicePage(
              coiffeuseId: utilisateurActuelle.idTblUser.toString(),
            ),
          ),
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
      setState(() => isLoading = false);
    }
  }
}






// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/add_service_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import '../../models/current_user.dart';
// import '../../models/salon_create.dart';
// import '../../services/providers/current_user_provider.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const CreateSalonPage({required this.currentUser, Key? key}) : super(key: key);
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   final TextEditingController nomSalonController = TextEditingController();
//   final TextEditingController sloganController = TextEditingController();
//   Uint8List? logoBytes;
//   File? logoFile;
//   bool isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Créer un salon"),
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           final isWide = constraints.maxWidth > 700;
//           return SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 600),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Détails du salon",
//                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
//                     ),
//                     const SizedBox(height: 30),
//                     _buildTextField("Nom du salon", nomSalonController, Icons.storefront),
//                     const SizedBox(height: 20),
//                     _buildTextField("Slogan du salon", sloganController, Icons.short_text),
//                     const SizedBox(height: 20),
//                     _buildLogoPicker(),
//                     const SizedBox(height: 40),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : _saveSalon,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF7B61FF),
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                         ),
//                         child: isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : const Text("Créer le salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
//         labelText: label,
//         labelStyle: const TextStyle(color: Color(0xFF555555)),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLogoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Logo du salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             ElevatedButton.icon(
//               onPressed: _pickLogo,
//               icon: const Icon(Icons.image_outlined),
//               label: const Text("Choisir une image"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFF3F4F6),
//                 foregroundColor: const Color(0xFF7B61FF),
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//             ),
//             const SizedBox(width: 20),
//             Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 border: Border.all(color: const Color(0xFFE5E7EB)),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: logoBytes != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.memory(logoBytes!, fit: BoxFit.cover),
//               )
//                   : logoFile != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.file(logoFile!, fit: BoxFit.cover),
//               )
//                   : const Center(child: Text("Aucune image", style: TextStyle(fontSize: 12))),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickLogo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
//   Future<void> _saveSalon() async {
//     final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     List<String> champsManquants = [];
//     if (nomSalonController.text.isEmpty) champsManquants.add("Nom du salon");
//     if (sloganController.text.isEmpty) champsManquants.add("Slogan du salon");
//     if (logoFile == null && logoBytes == null) champsManquants.add("Logo du salon");
//
//     if (champsManquants.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Veuillez renseigner : ${champsManquants.join(", ")}"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }
//
//     final salon = SalonCreateModel(
//       idTblUser: utilisateurActuelle!.idTblUser,
//       nomSalon: nomSalonController.text,
//       slogan: sloganController.text,
//       logo: kIsWeb ? logoBytes : logoFile,
//     );
//
//     setState(() => isLoading = true);
//
//     final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon_serializer_view/");
//     final request = http.MultipartRequest('POST', url)..fields.addAll(salon.toFields());
//
//     if (kIsWeb && logoBytes != null) {
//       request.files.add(http.MultipartFile.fromBytes(
//         'logo_salon',
//         salon.logo,
//         filename: 'logo.png',
//         contentType: MediaType('image', 'png'),
//       ));
//     } else if (logoFile != null) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'logo_salon',
//         (salon.logo as File).path,
//         contentType: MediaType('image', 'png'),
//       ));
//     }
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 201) {
//         final decoded = jsonDecode(responseBody);
//         final salonId = decoded['salon_id'];
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Salon créé avec succès!")),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => AddServicePage(
//               coiffeuseId: utilisateurActuelle.idTblUser.toString(),
//             ),
//           ),
//         );
//       } else {
//         debugPrint("Erreur backend : $responseBody");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//         );
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
// }




// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/add_service_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import '../../models/current_user.dart';
// import '../../models/salon_create.dart';
// import '../../services/providers/current_user_provider.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const CreateSalonPage({required this.currentUser, Key? key}) : super(key: key);
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   final TextEditingController nomSalonController = TextEditingController();
//   final TextEditingController sloganController = TextEditingController();
//   Uint8List? logoBytes;
//   File? logoFile;
//   bool isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Créer un salon"),
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Détails du salon",
//               style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
//             ),
//             const SizedBox(height: 30),
//             _buildTextField("Nom du salon", nomSalonController, Icons.storefront),
//             const SizedBox(height: 20),
//             _buildTextField("Slogan du salon", sloganController, Icons.short_text),
//             const SizedBox(height: 20),
//             _buildLogoPicker(),
//             const SizedBox(height: 40),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: isLoading ? null : _saveSalon,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF7B61FF),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                 ),
//                 child: isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text("Créer le salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
//         labelText: label,
//         labelStyle: const TextStyle(color: Color(0xFF555555)),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLogoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Logo du salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             ElevatedButton.icon(
//               onPressed: _pickLogo,
//               icon: const Icon(Icons.image_outlined),
//               label: const Text("Choisir une image"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFF3F4F6),
//                 foregroundColor: const Color(0xFF7B61FF),
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//             ),
//             const SizedBox(width: 20),
//             Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 border: Border.all(color: const Color(0xFFE5E7EB)),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: logoBytes != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.memory(logoBytes!, fit: BoxFit.cover),
//               )
//                   : logoFile != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.file(logoFile!, fit: BoxFit.cover),
//               )
//                   : const Center(child: Text("Aucune image", style: TextStyle(fontSize: 12))),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickLogo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
//   Future<void> _saveSalon() async {
//     final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     List<String> champsManquants = [];
//     if (nomSalonController.text.isEmpty) champsManquants.add("Nom du salon");
//     if (sloganController.text.isEmpty) champsManquants.add("Slogan du salon");
//     if (logoFile == null && logoBytes == null) champsManquants.add("Logo du salon");
//
//     if (champsManquants.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Veuillez renseigner : ${champsManquants.join(", ")}"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }
//
//     final salon = SalonCreateModel(
//       idTblUser: utilisateurActuelle!.idTblUser,
//       nomSalon: nomSalonController.text,
//       slogan: sloganController.text,
//       logo: kIsWeb ? logoBytes : logoFile,
//     );
//
//     setState(() => isLoading = true);
//
//     final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon_serializer_view/");
//     final request = http.MultipartRequest('POST', url)..fields.addAll(salon.toFields());
//
//     if (kIsWeb && logoBytes != null) {
//       request.files.add(http.MultipartFile.fromBytes(
//         'logo_salon',
//         salon.logo,
//         filename: 'logo.png',
//         contentType: MediaType('image', 'png'),
//       ));
//     } else if (logoFile != null) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'logo_salon',
//         (salon.logo as File).path,
//         contentType: MediaType('image', 'png'),
//       ));
//     }
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 201) {
//         final decoded = jsonDecode(responseBody);
//         final salonId = decoded['salon_id'];
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Salon créé avec succès!")),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => AddServicePage(
//               coiffeuseId: utilisateurActuelle.idTblUser.toString(),
//             ),
//           ),
//         );
//       } else {
//         debugPrint("Erreur backend : $responseBody");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//         );
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
// }






// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/add_service_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import '../../models/current_user.dart';
// import '../../models/salon_create.dart';
// import '../../services/providers/current_user_provider.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const CreateSalonPage({required this.currentUser, Key? key}) : super(key: key);
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   final TextEditingController nomSalonController = TextEditingController();
//   final TextEditingController sloganController = TextEditingController();
//   Uint8List? logoBytes;
//   File? logoFile;
//   bool isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer un salon"),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Informations du salon", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 20),
//             _buildTextField("Nom du salon", nomSalonController),
//             const SizedBox(height: 20),
//             _buildTextField("Slogan du salon", sloganController),
//             const SizedBox(height: 20),
//             _buildLogoPicker(),
//             const SizedBox(height: 30),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.save),
//                 label: isLoading ? const CircularProgressIndicator() : const Text("Enregistrer le salon"),
//                 onPressed: isLoading ? null : _saveSalon,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   textStyle: const TextStyle(fontSize: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       ),
//     );
//   }
//
//   Widget _buildLogoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Logo du salon", style: TextStyle(fontSize: 16)),
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
//                 child: Image.memory(logoBytes!, fit: BoxFit.cover),
//               )
//                   : logoFile != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(logoFile!, fit: BoxFit.cover),
//               )
//                   : const Center(
//                 child: Text("Aucune image", style: TextStyle(fontSize: 12)),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickLogo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
//   Future<void> _saveSalon() async {
//     final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     List<String> champsManquants = [];
//     if (nomSalonController.text.isEmpty) champsManquants.add("Nom du salon");
//     if (sloganController.text.isEmpty) champsManquants.add("Slogan du salon");
//     if (logoFile == null && logoBytes == null) champsManquants.add("Logo du salon");
//
//     if (champsManquants.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Veuillez renseigner : ${champsManquants.join(", ")}")),
//       );
//       return;
//     }
//
//     final salon = SalonCreateModel(
//       idTblUser: utilisateurActuelle!.idTblUser,
//       nomSalon: nomSalonController.text,
//       slogan: sloganController.text,
//       logo: kIsWeb ? logoBytes : logoFile,
//     );
//
//     setState(() => isLoading = true);
//
//     final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon_serializer_view/");
//     final request = http.MultipartRequest('POST', url)..fields.addAll(salon.toFields());
//
//     if (kIsWeb && logoBytes != null) {
//       request.files.add(http.MultipartFile.fromBytes(
//         'logo_salon',
//         salon.logo,
//         filename: 'logo.png',
//         contentType: MediaType('image', 'png'),
//       ));
//     } else if (logoFile != null) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'logo_salon',
//         (salon.logo as File).path,
//         contentType: MediaType('image', 'png'),
//       ));
//     }
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 201) {
//         final decoded = jsonDecode(responseBody);
//         final salonId = decoded['salon_id'];
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Salon créé avec succès!")),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => AddServicePage(
//               coiffeuseId: utilisateurActuelle.idTblUser.toString(),
//             ),
//           ),
//         );
//       } else {
//         debugPrint("Erreur backend : $responseBody");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//         );
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
// }


























// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/add_service_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import '../../models/current_user.dart';
// import '../../models/salon_create.dart';
// import '../../services/providers/current_user_provider.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const CreateSalonPage({required this.currentUser, Key? key}) : super(key: key);
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   final TextEditingController nomSalonController = TextEditingController();
//   final TextEditingController sloganController = TextEditingController();
//   Uint8List? logoBytes;
//   File? logoFile;
//   bool isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Créer un salon")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Créer un salon", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 20),
//             _buildTextField("Nom du salon", nomSalonController),
//             const SizedBox(height: 20),
//             _buildTextField("Slogan du salon", sloganController),
//             const SizedBox(height: 20),
//             _buildLogoPicker(),
//             const SizedBox(height: 20),
//             isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ElevatedButton(
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
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }
//
//   Widget _buildLogoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Logo du salon", style: TextStyle(fontSize: 16)),
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
//                 child: Image.memory(logoBytes!, fit: BoxFit.cover),
//               )
//                   : logoFile != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(logoFile!, fit: BoxFit.cover),
//               )
//                   : const Center(
//                 child: Text("Aucune image", style: TextStyle(fontSize: 12)),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickLogo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
//   Future<void> _saveSalon() async {
//     final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     if (nomSalonController.text.isEmpty || sloganController.text.isEmpty || (logoFile == null && logoBytes == null)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Tous les champs sont obligatoires.")),
//       );
//       return;
//     }
//
//     final salon = SalonCreateModel(
//       idTblUser: utilisateurActuelle!.idTblUser,
//       nomSalon: nomSalonController.text,
//       slogan: sloganController.text,
//       logo: kIsWeb ? logoBytes : logoFile,
//     );
//
//     setState(() => isLoading = true);
//
//     final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon_serializer_view/");
//     final request = http.MultipartRequest('POST', url)..fields.addAll(salon.toFields());
//
//     if (kIsWeb && logoBytes != null) {
//       request.files.add(http.MultipartFile.fromBytes(
//         'logo_salon',
//         salon.logo,
//         filename: 'logo.png',
//         contentType: MediaType('image', 'png'),
//       ));
//     } else if (logoFile != null) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'logo_salon',
//         (salon.logo as File).path,
//         contentType: MediaType('image', 'png'),
//       ));
//     }
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 201) {
//         final decoded = jsonDecode(responseBody);
//         final salonId = decoded['salon_id'];
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Salon créé avec succès!")),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => AddServicePage(
//               coiffeuseId: utilisateurActuelle!.idTblUser.toString(),
//               //salonId: salonId.toString(), // ✅ utilisé ici
//             ),
//           ),
//         );
//       } else {
//         debugPrint("Erreur backend : $responseBody");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//         );
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _skipCreation() {
//     // tu peux y mettre un Navigator vers une page par défaut si ignorée
//   }
// }





// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/add_service_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import '../../models/current_user.dart';
// import '../../models/salon_create.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../services/providers/get_user_type_service.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const CreateSalonPage({required this.currentUser, Key? key}) : super(key: key);
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   final TextEditingController nomSalonController = TextEditingController();
//   final TextEditingController sloganController = TextEditingController();
//   Uint8List? logoBytes;
//   File? logoFile;
//   bool isLoading = false;
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
//             _buildTextField("Nom du salon", nomSalonController),
//             const SizedBox(height: 20),
//             _buildTextField("Slogan du salon", sloganController),
//             const SizedBox(height: 20),
//             _buildLogoPicker(),
//             const SizedBox(height: 20),
//             isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ElevatedButton(
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
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }
//
//   Widget _buildLogoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Logo du salon", style: TextStyle(fontSize: 16)),
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
//                 child: Image.memory(logoBytes!, fit: BoxFit.cover),
//               )
//                   : logoFile != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(logoFile!, fit: BoxFit.cover),
//               )
//                   : const Center(
//                 child: Text("Aucune image", style: TextStyle(fontSize: 12)),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickLogo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
//   Future<void> _saveSalon() async {
//     final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     if (nomSalonController.text.isEmpty || sloganController.text.isEmpty || (logoFile == null && logoBytes == null)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Tous les champs sont obligatoires.")),
//       );
//       return;
//     }
//
//     final salon = SalonCreateModel(
//       userUuid: widget.currentUser.uuid,
//       nomSalon: nomSalonController.text,
//       slogan: sloganController.text,
//       logo: kIsWeb ? logoBytes : logoFile,
//     );
//
//     setState(() {
//       isLoading = true;
//     });
//
//     final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon_serializer_view/");
//     final request = http.MultipartRequest('POST', url);
//     request.fields.addAll(salon.toFields());
//
//     if (kIsWeb && logoBytes != null) {
//       request.files.add(http.MultipartFile.fromBytes(
//         'logo_salon',
//         salon.logo,
//         filename: 'logo.png',
//         contentType: MediaType('image', 'png'),
//       ));
//     } else if (logoFile != null) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'logo_salon',
//         (salon.logo as File).path,
//         contentType: MediaType('image', 'png'),
//       ));
//     }
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 201) {
//         final decoded = jsonDecode(responseBody);
//         final salonId = decoded['salon_id'];
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Salon créé avec succès!")),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => AddServicePage(
//               coiffeuseId: utilisateurActuelle!.idTblUser.toString(),
//               //salonId: salonId.toString(),
//             ),
//           ),
//         );
//       } else {
//         debugPrint("Erreur backend : $responseBody");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//         );
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _skipCreation() {
//     // Navigation alternative si on ignore
//   }
// }











// import 'dart:io';
// import 'dart:typed_data';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/add_service_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import '../../models/current_user.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../services/providers/get_user_type_service.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   //final String userUuid;
//   final CurrentUser currentUser;
//
//   const CreateSalonPage({required this.currentUser, Key? key}) : super(key: key);
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   final TextEditingController sloganController = TextEditingController();
//   Uint8List? logoBytes; // Pour les fichiers sur Web
//   File? logoFile; // Pour les fichiers sur Mobile/Desktop
//   bool isLoading = false; // Indicateur de chargement
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
//             isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ElevatedButton(
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
//
//   /// Méthode pour sauvegarder le salon
//   Future<void> _saveSalon() async {
//     final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     if (sloganController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Le slogan est obligatoire.")),
//       );
//       return;
//     }
//
//     if (logoFile == null && logoBytes == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Le logo est obligatoire.")),
//       );
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//     });
//
//     final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon_serializer_view/");
//     final request = http.MultipartRequest('POST', url);
//
//     // Ajouter les champs de formulaire
//     request.fields['userUuid'] = widget.currentUser.uuid;
//     request.fields['slogan'] = sloganController.text;
//
//     // Ajouter le logo si présent
//     if (logoBytes != null && kIsWeb) {
//       request.files.add(
//         http.MultipartFile.fromBytes(
//           'logo_salon',
//           logoBytes!,
//           filename: 'salon_logo.png',
//           contentType: MediaType('image', 'png'),
//         ),
//       );
//     } else if (logoFile != null) {
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'logo_salon',
//           logoFile!.path,
//           contentType: MediaType('image', 'png'),
//         ),
//       );
//     }
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser != null) {
//
//         // Récupérer les détails de l'utilisateur depuis le backend
//         final userDetails = await getIdAndTypeFromUuid(currentUser.uid);
//         final usertype = userDetails?['type'];
//
//         if (response.statusCode == 201) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Salon créé avec succès!")),
//           );
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => AddServicePage(coiffeuseId: utilisateurActuelle!.idTblUser.toString()),
//           )
//           );
//         } else {
//           debugPrint("Erreur backend : $responseBody");
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
//   /// Méthode pour ignorer la création du salon
//   void _skipCreation() {
//     //Navigator.push(
//       //context,
//       //MaterialPageRoute(builder: (_) => const CreateServicesPage()),
//     //);
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
//

















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
