import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '../../services/providers/current_user_provider.dart';
import '../authentification/login_page.dart';
import '../salon/create_salon_page.dart';

class ProfileCreationPage extends StatefulWidget {
  final String userUuid; // UUID Firebase
  final String email; // Email Firebase

  const ProfileCreationPage({
    required this.userUuid,
    required this.email,
    super.key,
  });

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  // Nouveaux ajouts
  String? selectedGender; // Sexe sélectionné
  final List<String> genderOptions = ["Homme", "Femme", "Autre"];
  Uint8List? profilePhotoBytes; // Pour les fichiers sur Web
  File? profilePhoto; // Pour les fichiers sur Mobile

  // Controllers existants
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController codePostalController = TextEditingController();
  final TextEditingController communeController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController postalBoxController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController socialNameController = TextEditingController();
  final TextEditingController tvaController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController(); // Nouveau champ

  bool isCoiffeuse = false; // Switch entre Coiffeuse et Client

  @override
  void initState() {
    super.initState();
    // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
    userEmail = widget.email;
    userUuid = widget.userUuid;
  }

  late String userEmail; // Stockage de l'email pour envoi au backend
  late String userUuid; // Stockage de l'UUID pour envoi au backend

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un profil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchRole(),
            const SizedBox(height: 10),
            _buildTextField("Nom", nameController),
            const SizedBox(height: 10),
            _buildTextField("Prénom", surnameController),
            const SizedBox(height: 10),
            _buildGenderDropdown(),
            const SizedBox(height: 10),
            _buildDatePicker(), // Champ pour la date de naissance
            const SizedBox(height: 10),
            _buildCodePostalField(),
            const SizedBox(height: 10),
            _buildTextField("Commune", communeController, readOnly: true),
            const SizedBox(height: 10),
            _buildTextField("Rue", streetController),
            const SizedBox(height: 10),
            _buildStreetAndBoxRow(),
            const SizedBox(height: 10),
            _buildTextField("Téléphone", phoneController,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _buildPhotoPicker(), // Champ pour sélectionner une photo
            if (isCoiffeuse) ...[
              const SizedBox(height: 10),
              _buildTextField("Dénomination Sociale", socialNameController),
              const SizedBox(height: 10),
              _buildTextField("Numéro TVA", tvaController),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,

              child: const Text("Enregistrer"),

            ),
          ],
        ),
      ),
    );
  }

  /// Liste déroulante pour le sexe
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: const InputDecoration(
        labelText: "Sexe",
        border: OutlineInputBorder(),
      ),
      items: genderOptions
          .map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedGender = value;
        });
      },
    );
  }

  /// Switch entre Client et Coiffeuse
  Widget _buildSwitchRole() {
    return Row(
      children: [
        const Text("Client"),
        Switch(
          value: isCoiffeuse,
          onChanged: (value) {
            setState(() {
              isCoiffeuse = value;
            });
          },
        ),
        const Text("Coiffeuse"),
      ],
    );
  }

  /// Widget pour Code Postal
  Widget _buildCodePostalField() {
    return TextField(
      controller: codePostalController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "Code Postal",
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => fetchCommune(value),
    );
  }

  /// Sélecteur de date pour la date de naissance
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          setState(() {
            birthDateController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}-"
                "${selectedDate.month.toString().padLeft(2, '0')}-"
                "${selectedDate.year}";
          });
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: birthDateController,
          decoration: const InputDecoration(
            labelText: "Date de naissance (DD-MM-YYYY)",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  /// Widget pour Numéro et Boîte sur la même ligne
  Widget _buildStreetAndBoxRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField("Numéro", streetNumberController),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextField("N° Boîte", postalBoxController),
        ),
      ],
    );
  }

  /// Widget pour sélectionner une photo
  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Photo de profil"),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: _pickPhoto,
              child: const Text("Choisir une photo"),
            ),
            const SizedBox(width: 10),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: profilePhotoBytes != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  profilePhotoBytes!,
                  fit: BoxFit.cover,
                ),
              )
                  : profilePhoto != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  profilePhoto!,
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



  /// Méthode pour sélectionner une photo
  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // Web : Utilisez les bytes
          profilePhotoBytes = result.files.first.bytes;
          profilePhoto = null; // Reset de la variable File
        } else {
          // Mobile/Desktop : Utilisez le chemin pour créer un objet File
          profilePhoto = File(result.files.first.path!);
          profilePhotoBytes = null; // Reset de la variable Uint8List
        }
      });
    } else {
      debugPrint("Aucune photo sélectionnée.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune photo sélectionnée.")),
      );
    }
  }





  /// Méthode pour sauvegarder le profil
//   void _saveProfile() async {
//     if (!_isValidDate(birthDateController.text)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Le format de la date de naissance doit être DD-MM-YYYY."),
//         ),
//       );
//       return;
//     }
//
//     final url = Uri.parse("https://www.hairbnb.site/api/create-profile/");
//     var request = http.MultipartRequest('POST', url);
//
//     // Ajouter les champs de formulaire
//     request.fields['userUuid'] = userUuid;
//     request.fields['role'] = isCoiffeuse ? "coiffeuse" : "client";
//     request.fields['nom'] = nameController.text;
//     request.fields['prenom'] = surnameController.text;
//     request.fields['sexe'] = selectedGender?.toLowerCase() ?? "autre";
//     request.fields['code_postal'] = codePostalController.text;
//     request.fields['commune'] = communeController.text;
//     request.fields['rue'] = streetController.text;
//     request.fields['numero'] = streetNumberController.text;
//     request.fields['boite_postale'] = postalBoxController.text;
//     request.fields['telephone'] = phoneController.text;
//     request.fields['email'] = userEmail;
//     request.fields['date_naissance'] = birthDateController.text;
//
//     if (isCoiffeuse) {
//       request.fields['denomination_sociale'] = socialNameController.text;
//       request.fields['tva'] = tvaController.text;
//     }
//
//     // Ajouter le fichier si sélectionné
//     if (profilePhoto != null || profilePhotoBytes != null) {
//       debugPrint("Photo envoyée : ${profilePhoto?.path ?? 'bytes sélectionnés'}");
//
//       if (kIsWeb) {
//         if (profilePhotoBytes != null) {
//           request.files.add(
//             http.MultipartFile.fromBytes(
//               'photo_profil',
//               profilePhotoBytes!,
//               filename: 'profile_photo.png',
//               contentType: MediaType('image', 'png'),
//             ),
//           );
//         }
//       } else if (profilePhoto != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'photo_profil',
//             profilePhoto!.path,
//           ),
//         );
//       }
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//             (Route<dynamic> route) => false, // Supprime toutes les pages précédentes
//       );
//     } else {
//       print("Aucune photo sélectionnée, envoi de l'avatar par défaut.");
//     }
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     debugPrint("Données envoyées : ${request.fields}");
//     if (profilePhoto != null || profilePhotoBytes != null) {
//       debugPrint("Fichier attaché : ${profilePhoto?.path ?? 'Bytes sélectionnés'}");
//     }
// //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Profil créé avec succès!")),
//         );
//         if (isCoiffeuse) {
//           // 🔴 🔴 Attendre que le profil soit bien créé et mis à jour dans le provider
//           final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//           await userProvider.fetchCurrentUser(); // Récupérer les infos mises à jour depuis Django
//
//           if (userProvider.currentUser != null) {
//             // 🔥 Maintenant, on a l'utilisateur complet, on peut aller vers CreateSalonPage
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
//             );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Bienvenue! Votre profil a été créé.")),
//           );
//         }
//       } else {
//         debugPrint("Erreur backend : $responseBody");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la création du profil : $responseBody")),
//         );
//       }
//         }
//     } catch (e) {
//       debugPrint("Erreur de connexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     }
//   }

  void _saveProfile() async {
    if (!_isValidDate(birthDateController.text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le format de la date de naissance doit être DD-MM-YYYY.")),
        );
      }
      return;
    }

    final url = Uri.parse("https://www.hairbnb.site/api/create-profile/");
    var request = http.MultipartRequest('POST', url);

    // Ajouter les champs de formulaire
    request.fields['userUuid'] = userUuid;
    request.fields['role'] = isCoiffeuse ? "coiffeuse" : "client";
    request.fields['nom'] = nameController.text;
    request.fields['prenom'] = surnameController.text;
    request.fields['sexe'] = selectedGender?.toLowerCase() ?? "autre";
    request.fields['code_postal'] = codePostalController.text;
    request.fields['commune'] = communeController.text;
    request.fields['rue'] = streetController.text;
    request.fields['numero'] = streetNumberController.text;
    request.fields['boite_postale'] = postalBoxController.text;
    request.fields['telephone'] = phoneController.text;
    request.fields['email'] = userEmail;
    request.fields['date_naissance'] = birthDateController.text;

    if (isCoiffeuse) {
      request.fields['denomination_sociale'] = socialNameController.text;
      request.fields['tva'] = tvaController.text;
    }

    // Ajouter le fichier si sélectionné
    if (profilePhoto != null || profilePhotoBytes != null) {
      if (kIsWeb && profilePhotoBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo_profil',
            profilePhotoBytes!,
            filename: 'profile_photo.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      } else if (profilePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo_profil',
            profilePhoto!.path,
          ),
        );
      }
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (!mounted) return; // 🔥 Vérifie si le widget est encore actif avant d'utiliser `context`

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil créé avec succès!")),
        );

        if (isCoiffeuse) {
          final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
          await userProvider.fetchCurrentUser(); // 🔄 Mettre à jour le profil

          if (mounted && userProvider.currentUser != null) {
            // 🔥 Vérifie encore si le widget est monté avant de naviguer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bienvenue! Votre profil a été créé.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la création du profil : $responseBody")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion au serveur.")),
        );
      }
    }
  }



  /// Validation du format de la date
  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!regex.hasMatch(date)) return false;

    try {
      final parts = date.split('-');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final parsedDate = DateTime(year, month, day);
      return parsedDate.year == year &&
          parsedDate.month == month &&
          parsedDate.day == day;
    } catch (e) {
      return false;
    }
  }

  /// Fonction générique pour TextField
  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Méthode pour récupérer la commune depuis le Code Postal
  Future<void> fetchCommune(String codePostal) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");

    try {
      final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final addressDetailsUrl = Uri.parse(
              "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
          final addressResponse = await http.get(addressDetailsUrl);
          if (addressResponse.statusCode == 200) {
            final addressData = json.decode(addressResponse.body);
            setState(() {
              communeController.text = addressData['address']['city'] ??
                  addressData['address']['town'] ??
                  addressData['address']['village'] ??
                  "Commune introuvable";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur commune : $e");
    }
  }
}














// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:file_picker/file_picker.dart';
//
// class ProfileCreationPage extends StatefulWidget {
//   final String userUuid; // UUID Firebase
//   final String email; // Email Firebase
//
//   const ProfileCreationPage({
//     required this.userUuid,
//     required this.email,
//     super.key,
//   });
//
//   @override
//   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// }
//
// class _ProfileCreationPageState extends State<ProfileCreationPage> {
//   // Nouveaux ajouts
//   String? selectedGender; // Sexe sélectionné
//   final List<String> genderOptions = ["Homme", "Femme", "Autre"];
//   File? profilePhoto; // Fichier pour la photo de profil
//
//   // Controllers existants
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController surnameController = TextEditingController();
//   final TextEditingController codePostalController = TextEditingController();
//   final TextEditingController communeController = TextEditingController();
//   final TextEditingController streetController = TextEditingController();
//   final TextEditingController streetNumberController = TextEditingController();
//   final TextEditingController postalBoxController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController socialNameController = TextEditingController();
//   final TextEditingController tvaController = TextEditingController();
//   final TextEditingController birthDateController = TextEditingController(); // Nouveau champ
//
//   bool isCoiffeuse = false; // Switch entre Coiffeuse et Client
//
//   @override
//   void initState() {
//     super.initState();
//     // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
//     userEmail = widget.email;
//     userUuid = widget.userUuid;
//   }
//
//   late String userEmail; // Stockage de l'email pour envoi au backend
//   late String userUuid; // Stockage de l'UUID pour envoi au backend
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer un profil"),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSwitchRole(),
//             const SizedBox(height: 10),
//             _buildTextField("Nom", nameController),
//             const SizedBox(height: 10),
//             _buildTextField("Prénom", surnameController),
//             const SizedBox(height: 10),
//             _buildGenderDropdown(),
//             const SizedBox(height: 10),
//             _buildDatePicker(), // Champ pour la date de naissance
//             const SizedBox(height: 10),
//             _buildCodePostalField(),
//             const SizedBox(height: 10),
//             _buildTextField("Commune", communeController, readOnly: true),
//             const SizedBox(height: 10),
//             _buildTextField("Rue", streetController),
//             const SizedBox(height: 10),
//             _buildStreetAndBoxRow(),
//             const SizedBox(height: 10),
//             _buildTextField("Téléphone", phoneController,
//                 keyboardType: TextInputType.phone),
//             const SizedBox(height: 10),
//             _buildPhotoPicker(), // Champ pour sélectionner une photo
//             if (isCoiffeuse) ...[
//               const SizedBox(height: 10),
//               _buildTextField("Dénomination Sociale", socialNameController),
//               const SizedBox(height: 10),
//               _buildTextField("Numéro TVA", tvaController),
//             ],
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _saveProfile,
//               child: const Text("Enregistrer"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Liste déroulante pour le sexe
//   Widget _buildGenderDropdown() {
//     return DropdownButtonFormField<String>(
//       value: selectedGender,
//       decoration: const InputDecoration(
//         labelText: "Sexe",
//         border: OutlineInputBorder(),
//       ),
//       items: genderOptions
//           .map((gender) => DropdownMenuItem(
//         value: gender,
//         child: Text(gender),
//       ))
//           .toList(),
//       onChanged: (value) {
//         setState(() {
//           selectedGender = value;
//         });
//       },
//     );
//   }
//
//   /// Switch entre Client et Coiffeuse
//   Widget _buildSwitchRole() {
//     return Row(
//       children: [
//         const Text("Client"),
//         Switch(
//           value: isCoiffeuse,
//           onChanged: (value) {
//             setState(() {
//               isCoiffeuse = value;
//             });
//           },
//         ),
//         const Text("Coiffeuse"),
//       ],
//     );
//   }
//
//   /// Widget pour Code Postal
//   Widget _buildCodePostalField() {
//     return TextField(
//       controller: codePostalController,
//       keyboardType: TextInputType.number,
//       decoration: const InputDecoration(
//         labelText: "Code Postal",
//         border: OutlineInputBorder(),
//       ),
//       onChanged: (value) => fetchCommune(value),
//     );
//   }
//
//   /// Sélecteur de date pour la date de naissance
//   Widget _buildDatePicker() {
//     return GestureDetector(
//       onTap: () async {
//         final selectedDate = await showDatePicker(
//           context: context,
//           initialDate: DateTime.now(),
//           firstDate: DateTime(1900),
//           lastDate: DateTime.now(),
//         );
//         if (selectedDate != null) {
//           setState(() {
//             birthDateController.text =
//             "${selectedDate.day.toString().padLeft(2, '0')}-"
//                 "${selectedDate.month.toString().padLeft(2, '0')}-"
//                 "${selectedDate.year}";
//           });
//         }
//       },
//       child: AbsorbPointer(
//         child: TextField(
//           controller: birthDateController,
//           decoration: const InputDecoration(
//             labelText: "Date de naissance (DD-MM-YYYY)",
//             border: OutlineInputBorder(),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Widget pour Numéro et Boîte sur la même ligne
//   Widget _buildStreetAndBoxRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildTextField("Numéro", streetNumberController),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: _buildTextField("N° Boîte", postalBoxController),
//         ),
//       ],
//     );
//   }
//
//   /// Widget pour sélectionner une photo
//   Widget _buildPhotoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Photo de profil"),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             ElevatedButton(
//               onPressed: _pickPhoto,
//               child: const Text("Choisir une photo"),
//             ),
//             const SizedBox(width: 10),
//             Text(
//               profilePhoto != null
//                   ? profilePhoto!.path.split('/').last
//                   : "Aucune photo sélectionnée",
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   /// Méthode pour sélectionner une photo
//   Future<void> _pickPhoto() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//
//     if (result != null) {
//       setState(() {
//         if (kIsWeb) {
//           // Web : utiliser bytes
//           print("Bytes : ${result.files.first.bytes}");
//         } else {
//           // Mobile/Desktop : utiliser path
//           print("Path : ${result.files.first.path}");
//         }
//       });
//     }
//   }
//
//
//
//
//   /// Méthode pour sauvegarder le profil
//   void _saveProfile() async {
//     if (!_isValidDate(birthDateController.text)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Le format de la date de naissance doit être DD-MM-YYYY."),
//         ),
//       );
//       return;
//     }
//
//     final url = Uri.parse("http://192.168.0.202:8000/api/create-profile/");
//     var request = http.MultipartRequest('POST', url);
//
//     // Ajouter les champs de formulaire
//     request.fields['userUuid'] = userUuid;
//     request.fields['role'] = isCoiffeuse ? "coiffeuse" : "client";
//     request.fields['nom'] = nameController.text;
//     request.fields['prenom'] = surnameController.text;
//     request.fields['sexe'] = selectedGender?.toLowerCase() ?? "autre";
//     request.fields['code_postal'] = codePostalController.text;
//     request.fields['commune'] = communeController.text;
//     request.fields['rue'] = streetController.text;
//     request.fields['numero'] = streetNumberController.text;
//     request.fields['boite_postale'] = postalBoxController.text;
//     request.fields['telephone'] = phoneController.text;
//     request.fields['email'] = userEmail;
//     request.fields['date_naissance'] = birthDateController.text;
//
//     if (isCoiffeuse) {
//       request.fields['denomination_sociale'] = socialNameController.text;
//       request.fields['tva'] = tvaController.text;
//     }
//
//     // Ajouter le fichier si sélectionné
//     if (profilePhoto != null) {
//       request.files.add(
//         await http.MultipartFile.fromPath('photo_profil', profilePhoto!.path),
//       );
//     }
//
//     try {
//       final response = await request.send();
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Profil créé avec succès!")),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erreur lors de la création du profil.")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     }
//   }
//
//   /// Validation du format de la date
//   bool _isValidDate(String date) {
//     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
//     if (!regex.hasMatch(date)) return false;
//
//     try {
//       final parts = date.split('-');
//       final day = int.parse(parts[0]);
//       final month = int.parse(parts[1]);
//       final year = int.parse(parts[2]);
//       final parsedDate = DateTime(year, month, day);
//       return parsedDate.year == year &&
//           parsedDate.month == month &&
//           parsedDate.day == day;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   /// Fonction générique pour TextField
//   Widget _buildTextField(String label, TextEditingController controller,
//       {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
//     return TextField(
//       controller: controller,
//       readOnly: readOnly,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }
//
//   /// Méthode pour récupérer la commune depuis le Code Postal
//   Future<void> fetchCommune(String codePostal) async {
//     final url = Uri.parse(
//         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
//
//     try {
//       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body) as List;
//         if (data.isNotEmpty) {
//           final addressDetailsUrl = Uri.parse(
//               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
//           final addressResponse = await http.get(addressDetailsUrl);
//           if (addressResponse.statusCode == 200) {
//             final addressData = json.decode(addressResponse.body);
//             setState(() {
//               communeController.text = addressData['address']['city'] ??
//                   addressData['address']['town'] ??
//                   addressData['address']['village'] ??
//                   "Commune introuvable";
//             });
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur commune : $e");
//     }
//   }
// }



















// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// class ProfileCreationPage extends StatefulWidget {
//   final String userUuid; // UUID Firebase
//   final String email; // Email Firebase
//
//   const ProfileCreationPage({
//     required this.userUuid,
//     required this.email,
//     super.key,
//   });
//
//   @override
//   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// }
//
// class _ProfileCreationPageState extends State<ProfileCreationPage> {
//   // Nouveaux ajouts
//   String? selectedGender; // Sexe sélectionné
//   final List<String> genderOptions = ["Homme", "Femme", "Autre"];
//
//   // Controllers existants
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController surnameController = TextEditingController();
//   final TextEditingController codePostalController = TextEditingController();
//   final TextEditingController communeController = TextEditingController();
//   final TextEditingController streetController = TextEditingController();
//   final TextEditingController streetNumberController = TextEditingController();
//   final TextEditingController postalBoxController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController socialNameController = TextEditingController();
//   final TextEditingController tvaController = TextEditingController();
//   final TextEditingController birthDateController = TextEditingController(); // Nouveau champ
//
//   bool isCoiffeuse = false; // Switch entre Coiffeuse et Client
//
//   @override
//   void initState() {
//     super.initState();
//     // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
//     userEmail = widget.email;
//     userUuid = widget.userUuid;
//   }
//
//   late String userEmail; // Stockage de l'email pour envoi au backend
//   late String userUuid; // Stockage de l'UUID pour envoi au backend
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer un profil"),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSwitchRole(),
//             const SizedBox(height: 10),
//             _buildTextField("Nom", nameController),
//             const SizedBox(height: 10),
//             _buildTextField("Prénom", surnameController),
//             const SizedBox(height: 10),
//             _buildGenderDropdown(),
//             const SizedBox(height: 10),
//             _buildDatePicker(), // Champ pour la date de naissance
//             const SizedBox(height: 10),
//             _buildCodePostalField(),
//             const SizedBox(height: 10),
//             _buildTextField("Commune", communeController, readOnly: true),
//             const SizedBox(height: 10),
//             _buildTextField("Rue", streetController),
//             const SizedBox(height: 10),
//             _buildStreetAndBoxRow(),
//             const SizedBox(height: 10),
//             _buildTextField("Téléphone", phoneController,
//                 keyboardType: TextInputType.phone),
//             if (isCoiffeuse) ...[
//               const SizedBox(height: 10),
//               _buildTextField("Dénomination Sociale", socialNameController),
//               const SizedBox(height: 10),
//               _buildTextField("Numéro TVA", tvaController),
//             ],
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _saveProfile,
//               child: const Text("Enregistrer"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Liste déroulante pour le sexe
//   Widget _buildGenderDropdown() {
//     return DropdownButtonFormField<String>(
//       value: selectedGender,
//       decoration: const InputDecoration(
//         labelText: "Sexe",
//         border: OutlineInputBorder(),
//       ),
//       items: genderOptions
//           .map((gender) => DropdownMenuItem(
//         value: gender,
//         child: Text(gender),
//       ))
//           .toList(),
//       onChanged: (value) {
//         setState(() {
//           selectedGender = value;
//         });
//       },
//     );
//   }
//
//   /// Switch entre Client et Coiffeuse
//   Widget _buildSwitchRole() {
//     return Row(
//       children: [
//         const Text("Client"),
//         Switch(
//           value: isCoiffeuse,
//           onChanged: (value) {
//             setState(() {
//               isCoiffeuse = value;
//             });
//           },
//         ),
//         const Text("Coiffeuse"),
//       ],
//     );
//   }
//
//   /// Widget pour Code Postal
//   Widget _buildCodePostalField() {
//     return TextField(
//       controller: codePostalController,
//       keyboardType: TextInputType.number,
//       decoration: const InputDecoration(
//         labelText: "Code Postal",
//         border: OutlineInputBorder(),
//       ),
//       onChanged: (value) => fetchCommune(value),
//     );
//   }
//
//   /// Sélecteur de date pour la date de naissance
//   Widget _buildDatePicker() {
//     return GestureDetector(
//       onTap: () async {
//         final selectedDate = await showDatePicker(
//           context: context,
//           initialDate: DateTime.now(),
//           firstDate: DateTime(1900),
//           lastDate: DateTime.now(),
//         );
//         if (selectedDate != null) {
//           setState(() {
//             birthDateController.text =
//             "${selectedDate.day.toString().padLeft(2, '0')}-"
//                 "${selectedDate.month.toString().padLeft(2, '0')}-"
//                 "${selectedDate.year}";
//           });
//         }
//       },
//       child: AbsorbPointer(
//         child: TextField(
//           controller: birthDateController,
//           decoration: const InputDecoration(
//             labelText: "Date de naissance (DD-MM-YYYY)",
//             border: OutlineInputBorder(),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Widget pour Numéro et Boîte sur la même ligne
//   Widget _buildStreetAndBoxRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildTextField("Numéro", streetNumberController),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: _buildTextField("N° Boîte", postalBoxController),
//         ),
//       ],
//     );
//   }
//
//   /// Méthode pour sauvegarder le profil
//   void _saveProfile() async {
//     if (!_isValidDate(birthDateController.text)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Le format de la date de naissance doit être DD-MM-YYYY."),
//         ),
//       );
//       return;
//     }
//
//     final url = Uri.parse("http://192.168.0.202:8000/api/create-profile/");
//     final Map<String, dynamic> data = {
//       "userUuid": userUuid,
//       "role": isCoiffeuse ? "coiffeuse" : "client",
//       "nom": nameController.text,
//       "prenom": surnameController.text,
//       "sexe": selectedGender?.toLowerCase(),
//       "code_postal": codePostalController.text,
//       "commune": communeController.text,
//       "rue": streetController.text,
//       "numero": streetNumberController.text,
//       "boite_postale": postalBoxController.text,
//       "telephone": phoneController.text,
//       "email": userEmail,
//       "denomination_sociale": isCoiffeuse ? socialNameController.text : null,
//       "tva": isCoiffeuse ? tvaController.text : null,
//       "date_naissance": birthDateController.text,
//     };
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(data),
//       );
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Profil créé avec succès!")),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erreur lors de la création du profil.")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur de connexion au serveur.")),
//       );
//     }
//   }
//
//   /// Validation du format de la date
//   bool _isValidDate(String date) {
//     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
//     if (!regex.hasMatch(date)) return false;
//
//     try {
//       final parts = date.split('-');
//       final day = int.parse(parts[0]);
//       final month = int.parse(parts[1]);
//       final year = int.parse(parts[2]);
//       final parsedDate = DateTime(year, month, day);
//       return parsedDate.year == year && parsedDate.month == month && parsedDate.day == day;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   /// Fonction générique pour TextField
//   Widget _buildTextField(String label, TextEditingController controller,
//       {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
//     return TextField(
//       controller: controller,
//       readOnly: readOnly,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }
//
//   /// Méthode pour récupérer la commune depuis le Code Postal
//   Future<void> fetchCommune(String codePostal) async {
//     final url = Uri.parse(
//         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
//
//     try {
//       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body) as List;
//         if (data.isNotEmpty) {
//           final addressDetailsUrl = Uri.parse(
//               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
//           final addressResponse = await http.get(addressDetailsUrl);
//           if (addressResponse.statusCode == 200) {
//             final addressData = json.decode(addressResponse.body);
//             setState(() {
//               communeController.text = addressData['address']['city'] ??
//                   addressData['address']['town'] ??
//                   addressData['address']['village'] ??
//                   "Commune introuvable";
//             });
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur commune : $e");
//     }
//   }
// }
//
//
//
//
//
//
//
//
//
//
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// //
// // class ProfileCreationPage extends StatefulWidget {
// //   final String userUuid; // UUID Firebase
// //   final String email;    // Email Firebase
// //
// //   const ProfileCreationPage({
// //     required this.userUuid,
// //     required this.email,
// //     super.key,
// //   });
// //
// //   @override
// //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // }
// //
// // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// //   // Nouveaux ajouts
// //   String? selectedGender; // Sexe sélectionné
// //   final List<String> genderOptions = ["Homme", "Femme", "Autre"];
// //
// //   // Autres controllers existants
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController surnameController = TextEditingController();
// //   final TextEditingController codePostalController = TextEditingController();
// //   final TextEditingController communeController = TextEditingController();
// //   final TextEditingController streetController = TextEditingController();
// //   final TextEditingController streetNumberController = TextEditingController();
// //   final TextEditingController postalBoxController = TextEditingController();
// //   final TextEditingController phoneController = TextEditingController();
// //   final TextEditingController socialNameController = TextEditingController();
// //   final TextEditingController tvaController = TextEditingController();
// //
// //   bool isCoiffeuse = false; // Switch entre Coiffeuse et Client
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
// //     userEmail = widget.email;
// //     userUuid = widget.userUuid;
// //   }
// //
// //   late String userEmail; // Stockage de l'email pour envoi au backend
// //   late String userUuid;  // Stockage de l'UUID pour envoi au backend
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Créer un profil"),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             _buildSwitchRole(),
// //             const SizedBox(height: 10),
// //             _buildTextField("Nom", nameController),
// //             const SizedBox(height: 10),
// //             _buildTextField("Prénom", surnameController),
// //             const SizedBox(height: 10),
// //             _buildGenderDropdown(),
// //             const SizedBox(height: 10),
// //             _buildCodePostalField(),
// //             const SizedBox(height: 10),
// //             _buildTextField("Commune", communeController, readOnly: true),
// //             const SizedBox(height: 10),
// //             _buildTextField("Rue", streetController),
// //             const SizedBox(height: 10),
// //             _buildStreetAndBoxRow(),
// //             const SizedBox(height: 10),
// //             _buildTextField("Téléphone", phoneController,
// //                 keyboardType: TextInputType.phone),
// //             if (isCoiffeuse) ...[
// //               const SizedBox(height: 10),
// //               _buildTextField("Dénomination Sociale", socialNameController),
// //               const SizedBox(height: 10),
// //               _buildTextField("Numéro TVA", tvaController),
// //             ],
// //             const SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: _saveProfile,
// //               child: const Text("Enregistrer"),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// Liste déroulante pour le sexe
// //   Widget _buildGenderDropdown() {
// //     return DropdownButtonFormField<String>(
// //       value: selectedGender,
// //       decoration: const InputDecoration(
// //         labelText: "Sexe",
// //         border: OutlineInputBorder(),
// //       ),
// //       items: genderOptions
// //           .map((gender) => DropdownMenuItem(
// //         value: gender,
// //         child: Text(gender),
// //       ))
// //           .toList(),
// //       onChanged: (value) {
// //         setState(() {
// //           selectedGender = value;
// //         });
// //       },
// //     );
// //   }
// //
// //   /// Switch entre Client et Coiffeuse
// //   Widget _buildSwitchRole() {
// //     return Row(
// //       children: [
// //         const Text("Client"),
// //         Switch(
// //           value: isCoiffeuse,
// //           onChanged: (value) {
// //             setState(() {
// //               isCoiffeuse = value;
// //             });
// //           },
// //         ),
// //         const Text("Coiffeuse"),
// //       ],
// //     );
// //   }
// //
// //   /// Widget pour Code Postal
// //   Widget _buildCodePostalField() {
// //     return TextField(
// //       controller: codePostalController,
// //       keyboardType: TextInputType.number,
// //       decoration: const InputDecoration(
// //         labelText: "Code Postal",
// //         border: OutlineInputBorder(),
// //       ),
// //       onChanged: (value) => fetchCommune(value),
// //     );
// //   }
// //
// //   /// Widget pour l'auto-complétion des rues
// //   /// Widget pour l'auto-complétion des rues
// //   // Widget _buildStreetAutocomplete() {
// //   //   return Autocomplete<String>(
// //   //     optionsBuilder: (TextEditingValue textEditingValue) async {
// //   //       return await fetchStreetSuggestions(textEditingValue.text);
// //   //     },
// //   //     onSelected: (String selection) {
// //   //       streetController.text = selection;
// //   //     },
// //   //     fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
// //   //       streetController.text = controller.text;
// //   //       return TextField(
// //   //         controller: controller,
// //   //         focusNode: focusNode,
// //   //         onEditingComplete: onEditingComplete,
// //   //         decoration: const InputDecoration(
// //   //           labelText: "Rue",
// //   //           border: OutlineInputBorder(),
// //   //         ),
// //   //       );
// //   //     },
// //   //   );
// //   // }
// //
// //   /// Méthode pour récupérer la commune depuis le Code Postal
// //   Future<void> fetchCommune(String codePostal) async {
// //     final url = Uri.parse(
// //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// //
// //     try {
// //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body) as List;
// //         if (data.isNotEmpty) {
// //           final addressDetailsUrl = Uri.parse(
// //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// //           final addressResponse = await http.get(addressDetailsUrl);
// //           if (addressResponse.statusCode == 200) {
// //             final addressData = json.decode(addressResponse.body);
// //             setState(() {
// //               communeController.text = addressData['address']['city'] ??
// //                   addressData['address']['town'] ??
// //                   addressData['address']['village'] ??
// //                   "Commune introuvable";
// //             });
// //           }
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint("Erreur commune : $e");
// //     }
// //   }
// //
// //   /// Méthode pour suggestions de rues
// //   Future<List<String>> fetchStreetSuggestions(String query) async {
// //     if (query.isEmpty || communeController.text.isEmpty) return [];
// //     final url = Uri.parse(
// //         "https://nominatim.openstreetmap.org/search?street=${query.toLowerCase()}&city=${communeController.text}&country=Belgium&format=json");
// //     try {
// //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body) as List;
// //         return data.map<String>((item) => item['display_name'].split(",")[0].trim()).toList();
// //       }
// //     } catch (e) {
// //       debugPrint("Erreur auto-complétion : $e");
// //     }
// //     return [];
// //   }
// //
// //
// //
// //
// //
// //   /// Widget pour Numéro et Boîte sur la même ligne
// //   Widget _buildStreetAndBoxRow() {
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: _buildTextField("Numéro", streetNumberController),
// //         ),
// //         const SizedBox(width: 10),
// //         Expanded(
// //           child: _buildTextField("N° Boîte", postalBoxController),
// //         ),
// //       ],
// //     );
// //   }
// //
// //
// // //************** Afficher les données du formulaire dans la console *************
// //
// //   void _printFormData() {
// //     debugPrint("===== Données du formulaire =====");
// //     debugPrint("userUuid : $userUuid");
// //     debugPrint("Email : $userEmail");
// //     debugPrint("Nom : ${nameController.text}");
// //     debugPrint("Prénom : ${surnameController.text}");
// //     debugPrint("Sexe : ${selectedGender ?? 'Non sélectionné'}");
// //     debugPrint("Code postal : ${codePostalController.text}");
// //     debugPrint("Commune : ${communeController.text}");
// //     debugPrint("Rue : ${streetController.text}");
// //     debugPrint("Numéro : ${streetNumberController.text}");
// //     debugPrint("Boîte postale : ${postalBoxController.text}");
// //     debugPrint("Téléphone : ${phoneController.text}");
// //     if (isCoiffeuse) {
// //       debugPrint("Dénomination Sociale : ${socialNameController.text}");
// //       debugPrint("Numéro TVA : ${tvaController.text}");
// //     }
// //     debugPrint("Rôle : ${isCoiffeuse ? "Coiffeuse" : "Client"}");
// //     debugPrint("===== Fin des données =====");
// //   }
// //
// //   //**********************************************************************************
// //
// //   /// Méthode pour sauvegarder le profil
// //   void _saveProfile() async {
// //
// //     final url = Uri.parse("http://192.168.0.202:8000/api/create-profile/");
// //     final Map<String, dynamic> data = {
// //       "userUuid": userUuid,
// //       "role": isCoiffeuse ? "coiffeuse" : "client",
// //       "nom": nameController.text,
// //       "prenom": surnameController.text,
// //       "sexe": selectedGender?.toLowerCase(),
// //       "code_postal": codePostalController.text,
// //       "commune": communeController.text,
// //       "rue": streetController.text,
// //       "numero": streetNumberController.text,
// //       "boite_postale": postalBoxController.text,
// //       "telephone": phoneController.text,
// //       "email": userEmail,
// //       "denomination_sociale": isCoiffeuse ? socialNameController.text : null,
// //       "tva": isCoiffeuse ? tvaController.text : null,
// //     };
// //
// //
// //
// //     try {
// //       _printFormData();
// //       final response = await http.post(
// //         url,
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode(data),
// //       );
// //
// //       if (response.statusCode == 201) {
// //         debugPrint("Profil créé avec succès : ${response.body}");
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Profil créé avec succès!")),
// //         );
// //       } else {
// //         debugPrint("Erreur serveur : ${response.body}");
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Erreur lors de la création du profil.")),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint("Erreur de connexion : $e");
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// //       );
// //     }
// //   }
// //
// //   /// Fonction générique pour TextField
// //   Widget _buildTextField(String label, TextEditingController controller,
// //       {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
// //     return TextField(
// //       controller: controller,
// //       readOnly: readOnly,
// //       keyboardType: keyboardType,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         border: const OutlineInputBorder(),
// //       ),
// //     );
// //   }
// // }
