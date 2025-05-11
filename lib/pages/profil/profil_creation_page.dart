import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '../../services/providers/current_user_provider.dart';
import '../home_page.dart';
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
  // Variables pour le thème
  final Color primaryColor = const Color(0xFF8E44AD); // Couleur violette comme dans l'image
  final Color secondaryColor = const Color(0xFFF39C12); // Couleur orange pour les accents

  // Variables de l'état
  String? selectedGender;
  final List<String> genderOptions = ["Homme", "Femme"];
  Uint8List? profilePhotoBytes;
  File? profilePhoto;
  bool isCoiffeuse = false;
  late String userEmail;
  late String userUuid;
  int _currentStep = 0; // Pour la progression par étapes

  // Controllers
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
  final TextEditingController birthDateController = TextEditingController();

  // Form keys pour validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    userEmail = widget.email;
    userUuid = widget.userUuid;
  }

  @override
  void dispose() {
    // Libérer les contrôleurs
    nameController.dispose();
    surnameController.dispose();
    codePostalController.dispose();
    communeController.dispose();
    streetController.dispose();
    streetNumberController.dispose();
    postalBoxController.dispose();
    phoneController.dispose();
    socialNameController.dispose();
    tvaController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfilePhoto(),
                      const SizedBox(height: 16),
                      _buildRoleSelector(),
                      const SizedBox(height: 24),
                      _buildStepIndicator(),
                      const SizedBox(height: 20),
                      _buildCurrentStep(),
                      const SizedBox(height: 20),
                      _buildNavigationButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // En-tête de l'application avec une apparence moderne
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "Créer votre profil",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour l'affichage et la sélection de la photo de profil
  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profilePhotoBytes != null
                        ? Image.memory(
                      profilePhotoBytes!,
                      fit: BoxFit.cover,
                    )
                        : profilePhoto != null
                        ? Image.file(
                      profilePhoto!,
                      fit: BoxFit.cover,
                    )
                        : Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Photo de profil",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Sélecteur de rôle avec design moderne
  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Je suis :",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              Text(
                "Client",
                style: TextStyle(
                  color: !isCoiffeuse ? primaryColor : Colors.grey,
                  fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Switch(
                value: isCoiffeuse,
                onChanged: (value) {
                  setState(() {
                    isCoiffeuse = value;
                  });
                },
                activeColor: secondaryColor,
                activeTrackColor: secondaryColor.withOpacity(0.5),
              ),
              Text(
                "Coiffeuse",
                style: TextStyle(
                  color: isCoiffeuse ? primaryColor : Colors.grey,
                  fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Indicateur de progression des étapes
  Widget _buildStepIndicator() {
    final int totalSteps = isCoiffeuse ? 3 : 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= _currentStep ? primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Affiche l'étape actuelle selon _currentStep
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildAddressStep();
      case 2:
        return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  // Étape 1 : Informations personnelles
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Informations personnelles",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: "Nom",
          controller: nameController,
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre nom';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Prénom",
          controller: surnameController,
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre prénom';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildGenderDropdown(),
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Téléphone",
          controller: phoneController,
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre numéro de téléphone';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Étape 2 : Adresse
  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Adresse",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: "Code Postal",
          controller: codePostalController,
          icon: Icons.location_on_outlined,
          keyboardType: TextInputType.number,
          onChanged: fetchCommune,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre code postal';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Commune",
          controller: communeController,
          icon: Icons.location_city,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Rue",
          controller: streetController,
          icon: Icons.streetview,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre rue';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: "Numéro",
                controller: streetNumberController,
                icon: Icons.home,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Obligatoire';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                label: "Boîte",
                controller: postalBoxController,
                icon: Icons.inbox,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Étape 3 : Informations professionnelles (pour les coiffeuses)
  Widget _buildProfessionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Informations professionnelles",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: "Dénomination Sociale",
          controller: socialNameController,
          icon: Icons.business,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre dénomination sociale';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Numéro TVA",
          controller: tvaController,
          icon: Icons.receipt_long,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre numéro TVA';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Input field stylisé avec validation
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // Dropdown stylisé pour le genre
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: "Sexe",
        prefixIcon: Icon(Icons.person, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner votre genre';
        }
        return null;
      },
    );
  }

  // Date picker stylisé
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
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
        child: TextFormField(
          controller: birthDateController,
          decoration: InputDecoration(
            labelText: "Date de naissance",
            prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre date de naissance';
            }
            if (!_isValidDate(value)) {
              return 'Format invalide (JJ-MM-AAAA)';
            }
            return null;
          },
        ),
      ),
    );
  }

  // Boutons de navigation
  Widget _buildNavigationButtons() {
    final int totalSteps = isCoiffeuse ? 3 : 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _currentStep > 0
            ? ElevatedButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: const Text("Précédent"),
          onPressed: () {
            setState(() {
              _currentStep--;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        )
            : const SizedBox(width: 120),
        _currentStep < totalSteps - 1
            ? ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: const Text("Suivant"),
          onPressed: () {
            if (_validateCurrentStep()) {
              setState(() {
                _currentStep++;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        )
            : ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text("Enregistrer"),
          onPressed: () {
            if (_validateCurrentStep()) {
              _saveProfile();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Validation de l'étape actuelle
  bool _validateCurrentStep() {
    return _formKey.currentState?.validate() ?? false;
  }

  // Méthode pour sélectionner une photo
  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            profilePhotoBytes = result.files.first.bytes;
            profilePhoto = null;
          } else {
            profilePhoto = File(result.files.first.path!);
            profilePhotoBytes = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la sélection de la photo: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Validation du format de la date
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

  // Méthode pour récupérer la commune depuis le Code Postal
  Future<void> fetchCommune(String codePostal) async {
    if (codePostal.length < 4) return;

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");

    try {
      final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final addressDetailsUrl = Uri.parse(
              "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
          final addressResponse = await http.get(addressDetailsUrl,
              headers: {'User-Agent': 'FlutterApp/1.0'});
          if (addressResponse.statusCode == 200) {
            final addressData = json.decode(addressResponse.body);
            if (mounted) {
              setState(() {
                communeController.text = addressData['address']['city'] ??
                    addressData['address']['town'] ??
                    addressData['address']['village'] ??
                    "Commune introuvable";
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur commune : $e");
    }
  }

  // Sauvegarde du profil
  void _saveProfile() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      ),
    );

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

      // Fermer la boîte de dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Animation de succès
        _showSuccessDialog();

        final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        await userProvider.fetchCurrentUser();

        if (!mounted) return;

        if (isCoiffeuse) {
          // Redirection vers la création de salon pour les coiffeuses
          if (userProvider.currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
            );
          }
        } else {
          // Redirection vers la page d'accueil pour les clients
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $responseBody"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fermer la boîte de dialogue de chargement
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de connexion: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Animation de succès
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            const SizedBox(width: 10),
            const Text("Profil créé !"),
          ],
        ),
        content: const Text(
          "Votre profil a été créé avec succès.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Continuer",
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

//-----------------------------------------------Avant modernisation / avant token---------------------------
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:file_picker/file_picker.dart';
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../home_page.dart';
// import '../salon/create_salon_page.dart';
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
//   final List<String> genderOptions = ["Homme", "Femme"];
//   Uint8List? profilePhotoBytes; // Pour les fichiers sur Web
//   File? profilePhoto; // Pour les fichiers sur Mobile
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
//
//               child: const Text("Enregistrer"),
//
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
//             Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: profilePhotoBytes != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.memory(
//                   profilePhotoBytes!,
//                   fit: BoxFit.cover,
//                 ),
//               )
//                   : profilePhoto != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(
//                   profilePhoto!,
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
//
//
//   /// Méthode pour sélectionner une photo
//   Future<void> _pickPhoto() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//
//     if (result != null) {
//       setState(() {
//         if (kIsWeb) {
//           // Web : Utilisez les bytes
//           profilePhotoBytes = result.files.first.bytes;
//           profilePhoto = null; // Reset de la variable File
//         } else {
//           // Mobile/Desktop : Utilisez le chemin pour créer un objet File
//           profilePhoto = File(result.files.first.path!);
//           profilePhotoBytes = null; // Reset de la variable Uint8List
//         }
//       });
//     } else {
//       debugPrint("Aucune photo sélectionnée.");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Aucune photo sélectionnée.")),
//       );
//     }
//   }
//
//
//   void _saveProfile() async {
//     if (!_isValidDate(birthDateController.text)) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Le format de la date de naissance doit être DD-MM-YYYY.")),
//         );
//       }
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
//       if (kIsWeb && profilePhotoBytes != null) {
//         request.files.add(
//           http.MultipartFile.fromBytes(
//             'photo_profil',
//             profilePhotoBytes!,
//             filename: 'profile_photo.png',
//             contentType: MediaType('image', 'png'),
//           ),
//         );
//       } else if (profilePhoto != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'photo_profil',
//             profilePhoto!.path,
//           ),
//         );
//       }
//     }
//
//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (!mounted) return; // 🔥 Vérifie si le widget est encore actif avant d'utiliser `context`
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Profil créé avec succès!")),
//         );
//
//         if (isCoiffeuse) {
//           final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//           await userProvider.fetchCurrentUser(); // 🔄 Mettre à jour le profil
//
//           if (mounted && userProvider.currentUser != null) {
//             // 🔥 Vérifie encore si le widget est monté avant de naviguer
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
//             );
//           }
//         } else {
//
//           final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//           await userProvider.fetchCurrentUser(); // 🔄 Mettre à jour le profil
//
//           if (mounted && userProvider.currentUser != null) {
//             // 🔥 Vérifie encore si le widget est monté avant de naviguer
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const HomePage()),
//             );
//           }
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Bienvenue! Votre profil a été créé.")),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la création du profil : $responseBody")),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erreur de connexion au serveur.")),
//         );
//       }
//     }
//   }
//
//
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
