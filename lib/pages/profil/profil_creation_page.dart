import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/profil/services/profile_creation_api.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_token/token_service.dart';
import '../../services/providers/current_user_provider.dart';
import '../home_page.dart';
import '../salon/create_salon_page.dart';
import '../../models/user_creation.dart';
import 'profil_widgets/auto_complete_widget.dart';
import 'profil_widgets/commune_autofill_widget.dart';


class ProfileCreationPage extends StatefulWidget {
  final String userUuid;
  final String email;

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
  final Color primaryColor = const Color(0xFF8E44AD); // Couleur violette principale
  final Color secondaryColor = const Color(0xFFF39C12); // Couleur orange secondaire

  // Clé API pour Geoapify (à garder sécurisée en production)
  static const String geoapifyApiKey = 'b097f188b11f46d2a02eb55021d168c1';

  // Variables d'état pour les données du profil et le flux de l'interface utilisateur
  String? selectedGender; // Sexe sélectionné (Homme/Femme)
  final List<String> genderOptions = ["Homme", "Femme"]; // Options de sexe
  Uint8List? profilePhotoBytes; // Données binaires de la photo pour le web
  File? profilePhoto; // Objet fichier pour la photo (mobile/desktop)
  bool isCoiffeuse = false; // Vrai si le rôle est "Coiffeuse", Faux pour "Client"
  late String userEmail; // Email de l'utilisateur
  late String userUuid; // UUID de l'utilisateur Firebase
  int _currentStep = 0; // Étape actuelle du formulaire (0, 1, 2)

  // Variables d'état pour la validation visuelle des champs d'adresse
  bool _isStreetSelected = false; // Vrai si une rue a été sélectionnée depuis l'autocomplétion
  bool _isCommuneValid = false; // Vrai si la commune a été trouvée pour le code postal

  // Map pour suivre l'état de validation de chaque champ (pour l'affichage de l'icône verte)
  final Map<String, bool> _fieldValidationStatus = {
    'name': false,
    'surname': false,
    'gender': false,
    'birthDate': false,
    'phone': false,
    'codePostal': false,
    'commune': false, // Géré par _isCommuneValid
    'street': false,  // Géré par _isStreetSelected
    'streetNumber': false,
    'postalBox': true, // Champ optionnel, supposé valide par défaut sauf si invalide
    'socialName': false, // Pour le profil coiffeuse
  };

  // Contrôleurs de texte pour les champs du formulaire
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController codePostalController = TextEditingController();
  final TextEditingController communeController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController postalBoxController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController socialNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  // Clé globale pour le formulaire, utilisée pour la validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    userEmail = widget.email;
    userUuid = widget.userUuid;

    // Ajouter des écouteurs aux contrôleurs de texte pour mettre à jour l'état de validation en temps réel
    nameController.addListener(() => _validateField('name', nameController.text));
    surnameController.addListener(() => _validateField('surname', surnameController.text));
    phoneController.addListener(() => _validateField('phone', phoneController.text));
    birthDateController.addListener(() => _validateField('birthDate', birthDateController.text));
    codePostalController.addListener(() => _validateField('codePostal', codePostalController.text));
    streetNumberController.addListener(() => _validateField('streetNumber', streetNumberController.text));
    postalBoxController.addListener(() => _validateField('postalBox', postalBoxController.text));
    socialNameController.addListener(() => _validateField('socialName', socialNameController.text));

    // Initialiser l'état de validation du sexe et de la rue
    if (selectedGender != null && selectedGender!.isNotEmpty) {
      _fieldValidationStatus['gender'] = true;
    }
    _fieldValidationStatus['street'] = _isStreetSelected; // Synchroniser avec la sélection de rue
    _fieldValidationStatus['commune'] = _isCommuneValid; // Synchroniser avec la validation de commune
  }

  @override
  void dispose() {
    // Retirer les écouteurs pour éviter les fuites de mémoire
    nameController.removeListener(() => _validateField('name', nameController.text));
    surnameController.removeListener(() => _validateField('surname', surnameController.text));
    phoneController.removeListener(() => _validateField('phone', phoneController.text));
    birthDateController.removeListener(() => _validateField('birthDate', birthDateController.text));
    codePostalController.removeListener(() => _validateField('codePostal', codePostalController.text));
    streetNumberController.removeListener(() => _validateField('streetNumber', streetNumberController.text));
    postalBoxController.removeListener(() => _validateField('postalBox', postalBoxController.text));
    socialNameController.removeListener(() => _validateField('socialName', socialNameController.text));

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
    birthDateController.dispose();
    super.dispose();
  }

  // Méthode générique pour mettre à jour l'état de validation et déclencher un rafraîchissement de l'UI
  void _validateField(String fieldName, String? value) {
    String? error; // Variable pour stocker le message d'erreur
    switch (fieldName) {
      case 'name':
        error = _validateNameSurname(value, 'nom');
        break;
      case 'surname':
        error = _validateNameSurname(value, 'prénom');
        break;
      case 'phone':
        error = _validatePhone(value);
        break;
      case 'birthDate':
        error = _validateBirthDate(value);
        break;
      case 'codePostal':
      // La validation visuelle du code postal est liée à celle de la commune.
      // Le validateur du champ TextForm_Field s'occupera d'afficher le message si on appuie sur Suivant.
        error = (value == null || value.isEmpty || value.length < 4) ? 'Code postal requis' : null;
        break;
      case 'streetNumber':
        error = _validateStreetNumber(value);
        break;
      case 'postalBox':
        error = _validatePostalBox(value);
        break;
      case 'socialName':
        error = (value == null || value.isEmpty) ? 'Nom commercial requis' : null;
        break;
    }
    // Mettre à jour l'état de validation dans la map et forcer un rafraîchissement de l'UI.
    setState(() {
      _fieldValidationStatus[fieldName] = error == null;
    });
  }

  // --- Méthodes de validation individuelles (retournent un message d'erreur ou null) ---

  String? _validateNameSurname(String? value, String fieldLabel) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre $fieldLabel';
    }
    // Regex pour autoriser uniquement les lettres, apostrophes, tirets et espaces.
    if (!RegExp(r"^[a-zA-Zà-öø-ÿ' -]+$").hasMatch(value)) {
      return 'Le $fieldLabel ne peut contenir que des lettres, apostrophes, tirets et espaces.';
    }
    return null; // Pas d'erreur
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    // Regex pour les numéros de téléphone belges : commence par 0, suivi de 8 ou 9 chiffres.
    // Accepte les espaces, points ou tirets comme séparateurs.
    // Exemples: 0471 23 45 67, 02.123.45.67, 0471-234567, 0471234567
    if (!RegExp(r"^0\d{1,}(\s*\d{2}){3}\s*\d{2}$|^0\d{8}$|^0\d{9}$").hasMatch(value.replaceAll(RegExp(r'[ .\-]'), ''))) {
      return 'Numéro de téléphone belge invalide (doit commencer par 0 et avoir 9 ou 10 chiffres)';
    }
    return null; // Pas d'erreur
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre date de naissance';
    }
    if (!_isValidDateLogic(value)) {
      return 'Format invalide (JJ-MM-AAAA) ou vous devez avoir au moins 16 ans.';
    }
    return null; // Pas d'erreur
  }

  String? _validateStreetNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Obligatoire';
    }
    // Autoriser les chiffres et optionnellement une lettre (ex: "12", "12A")
    if (!RegExp(r"^[0-9]+[a-zA-Z]?$").hasMatch(value)) {
      return 'Numéro invalide (ex: 12, 12A)';
    }
    return null; // Pas d'erreur
  }

  String? _validatePostalBox(String? value) {
    // Ce champ est optionnel, donc on ne valide que s'il n'est pas vide.
    if (value != null && value.isNotEmpty) {
      // Autoriser les chiffres et les lettres pour la boîte postale (ex: "B", "10")
      if (!RegExp(r"^[a-zA-Z0-9]+$").hasMatch(value)) {
        return 'Boîte invalide (ex: B, 10)';
      }
    }
    return null; // Pas d'erreur
  }

  // --- Fin des méthodes de validation ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(), // En-tête de l'application
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey, // Clé du formulaire pour la validation
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfilePhoto(), // Widget de sélection de photo de profil
                      const SizedBox(height: 16),
                      // Afficher le sélecteur de rôle SEULEMENT à l'étape 0
                      if (_currentStep == 0) ...[
                        _buildRoleSelector(), // Sélecteur de rôle (Client/Coiffeuse)
                        const SizedBox(height: 24),
                      ],
                      _buildStepIndicator(), // Indicateur de progression des étapes
                      const SizedBox(height: 20),
                      _buildCurrentStep(), // Contenu de l'étape actuelle
                      const SizedBox(height: 20),
                      _buildNavigationButtons(), // Boutons de navigation (Précédent/Suivant/Enregistrer)
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
        title: const Text(
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
            onTap: _pickPhoto, // Appeler la fonction de sélection de photo au tap
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
                  child: ClipOval( // Pour arrondir l'image
                    child: profilePhotoBytes != null
                        ? Image.memory(
                      profilePhotoBytes!, // Afficher l'image à partir des bytes (pour le web)
                      fit: BoxFit.cover,
                    )
                        : profilePhoto != null
                        ? Image.file(
                      profilePhoto!, // Afficher l'image à partir du fichier (pour mobile/desktop)
                      fit: BoxFit.cover,
                    )
                        : Icon(
                      Icons.person, // Icône par défaut si pas de photo
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
                    Icons.camera_alt, // Icône de caméra
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

  // Sélecteur de rôle (Client/Coiffeuse) avec design moderne
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
                    isCoiffeuse = value; // Basculer le rôle
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
    final int totalSteps = isCoiffeuse ? 3 : 2; // 3 étapes pour coiffeuse, 2 pour client
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= _currentStep ? primaryColor : Colors.grey[300], // Couleur de la progression
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Affiche l'étape actuelle du formulaire
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep(); // Étape Informations personnelles
      case 1:
        return _buildAddressStep(); // Étape Adresse
      case 2:
        return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep(); // Étape Pro ou retour aux infos perso
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
          fieldName: 'name', // Identifiant unique pour le champ
          validator: (value) => _validateNameSurname(value, 'nom'), // Utiliser la méthode de validation dédiée
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Prénom",
          controller: surnameController,
          icon: Icons.person_outline,
          fieldName: 'surname', // Identifiant unique pour le champ
          validator: (value) => _validateNameSurname(value, 'prénom'), // Utiliser la méthode de validation dédiée
        ),
        const SizedBox(height: 16),
        _buildGenderDropdown(), // Champ de sélection du sexe
        const SizedBox(height: 16),
        _buildDatePicker(), // Champ de sélection de la date de naissance
        const SizedBox(height: 16),
        _buildInputField(
          label: "Téléphone",
          controller: phoneController,
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          fieldName: 'phone', // Identifiant unique pour le champ
          validator: _validatePhone, // Utiliser la méthode de validation dédiée
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
        // Champ Code Postal avec CommuneAutoFill et icône de validation
        Stack(
          alignment: Alignment.centerRight,
          children: [
            CommuneAutoFill(
              codePostalController: codePostalController,
              communeController: communeController,
              geoapifyApiKey: geoapifyApiKey,
              onCommuneFound: () {
                setState(() {
                  _isCommuneValid = true;
                  _fieldValidationStatus['commune'] = true; // Mettre à jour l'état de validation de la commune
                  _fieldValidationStatus['codePostal'] = true; // Mettre à jour l'état de validation du code postal
                });
              },
              onCommuneNotFound: () {
                setState(() {
                  _isCommuneValid = false;
                  _fieldValidationStatus['commune'] = false; // Mettre à jour l'état de validation de la commune
                  _fieldValidationStatus['codePostal'] = false; // Mettre à jour l'état de validation du code postal
                });
              },
            ),
            // Afficher l'icône verte si le code postal est valide et la commune trouvée
            if (_fieldValidationStatus['codePostal'] == true && _isCommuneValid)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Champ Commune (lecture seule, rempli par CommuneAutoFill)
        _buildInputField(
          label: "Commune",
          controller: communeController,
          icon: Icons.location_city,
          readOnly: true,
          fieldName: 'commune', // Identifiant unique pour le champ
          validator: (value) {
            // Le validateur s'assure que la commune est valide si l'utilisateur appuie sur "Suivant"
            if (value == null || value.isEmpty || value == "Commune introuvable" || value == "Erreur de recherche" || value == "Erreur réseau") {
              return 'Veuillez entrer un code postal valide pour obtenir la commune.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Champ Rue avec StreetAutocomplete et icône de validation
        Stack(
          alignment: Alignment.centerRight,
          children: [
            StreetAutocomplete(
              streetController: streetController,
              communeController: communeController,
              codePostalController: codePostalController,
              geoapifyApiKey: geoapifyApiKey,
              onStreetSelected: () {
                setState(() {
                  _isStreetSelected = true; // Marquer la rue comme sélectionnée
                  _fieldValidationStatus['street'] = true; // Mettre à jour l'état de validation de la rue
                });
              },
              onStreetChanged: () {
                setState(() {
                  _isStreetSelected = false; // Réinitialiser si l'utilisateur tape manuellement
                  _fieldValidationStatus['street'] = false; // Réinitialiser l'état de validation de la rue
                });
              },
            ),
            // Afficher l'icône verte si une rue a été sélectionnée depuis l'autocomplétion
            if (_fieldValidationStatus['street'] == true)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Champs Numéro et Boîte sur la même ligne
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: "Numéro",
                controller: streetNumberController,
                icon: Icons.home,
                fieldName: 'streetNumber', // Identifiant unique pour le champ
                validator: _validateStreetNumber, // Utiliser la méthode de validation dédiée
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                label: "Boîte",
                controller: postalBoxController,
                icon: Icons.inbox,
                fieldName: 'postalBox', // Identifiant unique pour le champ
                validator: _validatePostalBox, // Utiliser la méthode de validation dédiée
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
          label: "Nom Commercial",
          controller: socialNameController,
          icon: Icons.business,
          fieldName: 'socialName', // Identifiant unique pour le champ
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre nom commercial';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Champ de saisie stylisé avec validation et affichage d'icône de validation
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    required String fieldName, // Identifiant unique pour le champ (ex: 'name', 'phone')
  }) {
    // Déterminer si le champ est actuellement valide pour afficher l'icône verte
    bool isValid = _fieldValidationStatus[fieldName] ?? false;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: (text) {
        onChanged?.call(text); // Appeler le callback onChanged fourni s'il existe
        _validateField(fieldName, text); // Déclencher la mise à jour de l'état de validation pour l'icône
      },
      validator: (value) {
        // Ce validateur est appelé par Form.validate().
        // Il retourne le message d'erreur. Les messages d'erreur ne sont visibles qu'après Form.validate().
        final error = validator?.call(value);
        // Mettre à jour l'état interne pour l'icône, mais sans afficher le texte d'erreur ici.
        // Utiliser addPostFrameCallback pour éviter les changements d'état pendant la construction du widget.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _fieldValidationStatus[fieldName] = error == null;
            });
          }
        });
        return error; // Retourner l'erreur pour que Form.validate() fonctionne comme prévu
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        // Afficher l'icône de succès si le champ est valide, non vide et non en lecture seule
        suffixIcon: isValid && controller.text.isNotEmpty && !readOnly
            ? Icon(Icons.check_circle, color: Colors.green[700], size: 24)
            : null,
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

  // Menu déroulant stylisé pour le genre avec icône de validation
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: "Sexe",
        prefixIcon: Icon(Icons.person, color: primaryColor),
        // Afficher l'icône de succès si le genre est sélectionné et valide
        suffixIcon: (_fieldValidationStatus['gender'] ?? false)
            ? Icon(Icons.check_circle, color: Colors.green[700], size: 24)
            : null,
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
          // Mettre à jour l'état de validation du genre
          _fieldValidationStatus['gender'] = (value != null && value.isNotEmpty);
        });
      },
      validator: (value) {
        final error = (value == null || value.isEmpty) ? 'Veuillez sélectionner votre genre' : null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _fieldValidationStatus['gender'] = error == null;
            });
          }
        });
        return error;
      },
    );
  }

  // Sélecteur de date stylisé avec icône de validation
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)), // Date initiale pour 16 ans
          firstDate: DateTime(1900), // Date la plus ancienne
          lastDate: DateTime.now(), // Date la plus récente
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
            _validateField('birthDate', birthDateController.text); // Déclencher la validation pour l'icône
          });
        }
      },
      child: AbsorbPointer( // Empêcher l'édition manuelle du champ
        child: TextFormField(
          controller: birthDateController,
          decoration: InputDecoration(
            labelText: "Date de naissance",
            prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
            // Afficher l'icône de succès si la date de naissance est valide
            suffixIcon: (_fieldValidationStatus['birthDate'] ?? false)
                ? Icon(Icons.check_circle, color: Colors.green[700], size: 24)
                : null,
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
            final error = _validateBirthDate(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _fieldValidationStatus['birthDate'] = error == null;
                });
              }
            });
            return error;
          },
        ),
      ),
    );
  }

  // Boutons de navigation (Précédent, Suivant, Enregistrer)
  Widget _buildNavigationButtons() {
    final int totalSteps = isCoiffeuse ? 3 : 2; // Nombre total d'étapes
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _currentStep > 0
            ? ElevatedButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: const Text("Précédent"),
          onPressed: () {
            setState(() {
              _currentStep--; // Revenir à l'étape précédente
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
            : const SizedBox(width: 120), // Espace vide si c'est la première étape
        _currentStep < totalSteps - 1
            ? ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: const Text("Suivant"),
          onPressed: () {
            // Déclencher la validation complète du formulaire de l'étape actuelle
            if (_formKey.currentState?.validate() == true) {
              // Vérifications manuelles pour les widgets qui n'utilisent pas TextFormField directement
              if (_currentStep == 1) { // Si on est à l'étape d'adresse
                if (!_isStreetSelected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez sélectionner une rue de la liste des suggestions.")),
                  );
                  return; // Arrêter si la rue n'est pas sélectionnée
                }
                if (!_isCommuneValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez entrer un code postal valide pour obtenir la commune.")),
                  );
                  return; // Arrêter si la commune n'est pas valide
                }
              }

              setState(() {
                _currentStep++; // Passer à l'étape suivante
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
            // Déclencher la validation complète du formulaire
            if (_formKey.currentState?.validate() == true) {
              // Vérifications manuelles pour les widgets qui n'utilisent pas TextFormField directement
              if (_currentStep == 1) { // Si on est à l'étape d'adresse
                if (!_isStreetSelected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez sélectionner une rue de la liste des suggestions.")),
                  );
                  return;
                }
                if (!_isCommuneValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez entrer un code postal valide pour obtenir la commune.")),
                  );
                  return;
                }
              }
              _saveProfile(); // Appeler la fonction de sauvegarde du profil
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

  // Méthode pour sélectionner une photo de profil
  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image, // Autoriser uniquement les fichiers image
        allowMultiple: false, // Ne pas autoriser la sélection multiple
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            profilePhotoBytes = result.files.first.bytes; // Pour le web, utiliser les bytes
            profilePhoto = null;
          } else {
            profilePhoto = File(result.files.first.path!); // Pour mobile/desktop, utiliser le chemin du fichier
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

  // Logique de validation de la date de naissance et de l'âge (minimum 16 ans)
  bool _isValidDateLogic(String date) {
    final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$'); // Regex pour le format JJ-MM-AAAA
    if (!regex.hasMatch(date)) return false; // Si le format ne correspond pas, c'est invalide

    try {
      final parts = date.split('-');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final parsedDate = DateTime(year, month, day);

      // Vérifier si la date parsée est une date de calendrier valide (ex: pas 31 février)
      if (parsedDate.year != year || parsedDate.month != month || parsedDate.day != day) {
        return false;
      }

      // Vérifier si la personne a au moins 16 ans
      final sixteenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 16));
      return parsedDate.isBefore(sixteenYearsAgo) || parsedDate.isAtSameMomentAs(sixteenYearsAgo);
    } catch (e) {
      return false; // En cas d'erreur de parsing ou autre
    }
  }

  // Créer le modèle utilisateur à partir des données du formulaire
  UserCreationModel _createUserModel() {
    String formattedStreetNumber = streetNumberController.text;
    // Si la boîte postale est présente, l'ajouter au numéro de rue
    if (postalBoxController.text.isNotEmpty) {
      formattedStreetNumber += "/${postalBoxController.text}";
    }

    return UserCreationModel.fromForm(
      userUuid: userUuid,
      email: userEmail,
      isCoiffeuse: isCoiffeuse,
      nom: nameController.text,
      prenom: surnameController.text,
      sexe: selectedGender ?? "", // Passer la valeur exacte (ex: "Homme")
      telephone: phoneController.text,
      dateNaissance: birthDateController.text,
      codePostal: codePostalController.text,
      commune: communeController.text,
      rue: streetController.text,
      numero: formattedStreetNumber, // Utiliser le numéro de rue formaté (incluant la boîte si nécessaire)
      boitePostale: null, // Ce champ est maintenant intégré dans 'numero'
      nomCommercial: isCoiffeuse ? socialNameController.text : null, // Nom commercial si coiffeuse
      photoProfilFile: profilePhoto,
      photoProfilBytes: profilePhotoBytes,
      photoProfilName: 'profile_photo.png',
    );
  }

  // Sauvegarde du profil via l'API
  void _saveProfile() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false, // Empêcher de fermer la boîte de dialogue en tapant à l'extérieur
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      ),
    );

    try {
      // Créer le modèle utilisateur avec les données du formulaire
      final userModel = _createUserModel();

      // --- DÉBUT DES LOGS DÉTAILLÉS (pour le débogage) ---
      if (kDebugMode) {
        print("--- Données du UserCreationModel avant envoi ---");
        print("userUuid: ${userModel.userUuid}");
        print("email: ${userModel.email}");
        print("type: ${userModel.type}");
        print("nom: ${userModel.nom}");
        print("prenom: ${userModel.prenom}");
        print("sexe: ${userModel.sexe}");
        print("telephone: ${userModel.telephone}");
        print("dateNaissance: ${userModel.dateNaissance}");
        print("codePostal: ${userModel.codePostal}");
        print("commune: ${userModel.commune}");
        print("rue: ${userModel.rue}");
        print("numero: ${userModel.numero}");
        print("boitePostale: ${userModel.boitePostale}");
        print("nomCommercial: ${userModel.nomCommercial}");
        print("photoProfilFile present: ${userModel.photoProfilFile != null}");
        print("photoProfilBytes present: ${userModel.photoProfilBytes != null}");
        print("photoProfilName: ${userModel.photoProfilName}");
        print("--- Fin des données du UserCreationModel ---");

        print("--- Champs envoyés à l'API (via toApiFields()) ---");
        userModel.toApiFields().forEach((key, value) {
          print("$key: $value");
        });
        print("--- Fin des champs envoyés ---");

        final String requestUrl = "${ProfileApiService.baseUrl}/create-profile/";
        print("URL de la requête POST: $requestUrl");
      }
      // --- FIN DES LOGS DÉTAILLÉS ---

      // Récupérer le token Firebase via TokenService pour l'authentification API
      String? firebaseToken;
      try {
        firebaseToken = await TokenService.getAuthToken();
        if (kDebugMode) {
          print("🔍 Token Firebase récupéré: ${firebaseToken != null ? 'Oui' : 'Non'}");
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ Erreur récupération token Firebase: $e");
        }
      }

      // Appeler l'API via le service ProfileApiService
      final response = await ProfileApiService.createUserProfile(
        userModel: userModel,
        firebaseToken: firebaseToken,
      );

      // Fermer la boîte de dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return; // S'assurer que le widget est toujours monté avant de continuer

      if (response.success) {
        // Afficher l'animation de succès
        _showSuccessDialog();

        // Mettre à jour les informations de l'utilisateur courant via le fournisseur
        final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        await userProvider.fetchCurrentUser();

        if (!mounted) return;

        // Redirection en fonction du rôle de l'utilisateur
        if (isCoiffeuse) {
          // Rediriger vers la création de salon pour les coiffeuses
          if (userProvider.currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
            );
          }
        } else {
          // Rediriger vers la page d'accueil pour les clients
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        // Gestion des erreurs de l'API
        String errorMessage = response.message;

        if (response.isAuthError) {
          errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
          await TokenService.clearAuthToken(); // Nettoyer le token en cas d'erreur d'auth
        } else if (response.isValidationError && response.validationErrors != null) {
          // Afficher les erreurs de validation spécifiques du backend
          errorMessage = response.validationErrors!.values.join('\n');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs inattendues (ex: problèmes réseau)
      if (mounted) {
        // Fermer la boîte de dialogue de chargement
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur inattendue: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Boîte de dialogue de succès après la création du profil
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30), // Icône de succès
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
            onPressed: () => Navigator.pop(context), // Fermer la boîte de dialogue
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





 // // profil_creation_page.dart
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/profil/services/profile_creation_api.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:provider/provider.dart';
// import '../../services/firebase_token/token_service.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../home_page.dart';
// import '../salon/create_salon_page.dart';
// import '../../models/user_creation.dart';
// import 'profil_widgets/auto_complete_widget.dart';
// import 'profil_widgets/commune_autofill_widget.dart';
//
//
// class ProfileCreationPage extends StatefulWidget {
//   final String userUuid;
//   final String email;
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
//   // Variables pour le thème
//   final Color primaryColor = const Color(0xFF8E44AD);
//   final Color secondaryColor = const Color(0xFFF39C12);
//
//   static const String geoapifyApiKey = 'b097f188b11f46d2a02eb55021d168c1';
//
//
//   // Variables de l'état
//   String? selectedGender;
//   final List<String> genderOptions = ["Homme", "Femme"];
//   Uint8List? profilePhotoBytes;
//   File? profilePhoto;
//   bool isCoiffeuse = false;
//   late String userEmail;
//   late String userUuid;
//   int _currentStep = 0;
//   bool _isStreetSelected = false; // New state variable for street validation
//
//   // Controllers
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController surnameController = TextEditingController();
//   final TextEditingController codePostalController = TextEditingController();
//   final TextEditingController communeController = TextEditingController();
//   final TextEditingController streetController = TextEditingController();
//   final TextEditingController streetNumberController = TextEditingController();
//   final TextEditingController postalBoxController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController socialNameController = TextEditingController();
//   final TextEditingController birthDateController = TextEditingController();
//
//   // Form keys pour validation
//   final _formKey = GlobalKey<FormState>();
//
//   @override
//   void initState() {
//     super.initState();
//     userEmail = widget.email;
//     userUuid = widget.userUuid;
//   }
//
//   @override
//   void dispose() {
//     // Libérer les contrôleurs
//     nameController.dispose();
//     surnameController.dispose();
//     codePostalController.dispose();
//     communeController.dispose();
//     streetController.dispose();
//     streetNumberController.dispose();
//     postalBoxController.dispose();
//     phoneController.dispose();
//     socialNameController.dispose();
//     birthDateController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             _buildAppBar(),
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       _buildProfilePhoto(),
//                       const SizedBox(height: 16),
//                       // Afficher le sélecteur de rôle SEULEMENT sur l'étape 0
//                       if (_currentStep == 0) ...[
//                         _buildRoleSelector(),
//                         const SizedBox(height: 24),
//                       ],
//                       _buildStepIndicator(),
//                       const SizedBox(height: 20),
//                       _buildCurrentStep(),
//                       const SizedBox(height: 20),
//                       _buildNavigationButtons(),
//                       const SizedBox(height: 40),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // En-tête de l'application avec une apparence moderne
//   Widget _buildAppBar() {
//     return SliverAppBar(
//       expandedHeight: 120,
//       floating: true,
//       pinned: true,
//       flexibleSpace: FlexibleSpaceBar(
//         title: Text(
//           "Créer votre profil",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         background: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [primaryColor, primaryColor.withOpacity(0.7)],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Widget pour l'affichage et la sélection de la photo de profil
//   Widget _buildProfilePhoto() {
//     return Center(
//       child: Column(
//         children: [
//           const SizedBox(height: 20),
//           GestureDetector(
//             onTap: _pickPhoto,
//             child: Stack(
//               alignment: Alignment.bottomRight,
//               children: [
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                   child: ClipOval(
//                     child: profilePhotoBytes != null
//                         ? Image.memory(
//                       profilePhotoBytes!,
//                       fit: BoxFit.cover,
//                     )
//                         : profilePhoto != null
//                         ? Image.file(
//                       profilePhoto!,
//                       fit: BoxFit.cover,
//                     )
//                         : Icon(
//                       Icons.person,
//                       size: 70,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: secondaryColor,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.camera_alt,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Photo de profil",
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Sélecteur de rôle avec design moderne
//   Widget _buildRoleSelector() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             "Je suis :",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           Row(
//             children: [
//               Text(
//                 "Client",
//                 style: TextStyle(
//                   color: !isCoiffeuse ? primaryColor : Colors.grey,
//                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//               Switch(
//                 value: isCoiffeuse,
//                 onChanged: (value) {
//                   setState(() {
//                     isCoiffeuse = value;
//                   });
//                 },
//                 activeColor: secondaryColor,
//                 activeTrackColor: secondaryColor.withOpacity(0.5),
//               ),
//               Text(
//                 "Coiffeuse",
//                 style: TextStyle(
//                   color: isCoiffeuse ? primaryColor : Colors.grey,
//                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Indicateur de progression des étapes
//   Widget _buildStepIndicator() {
//     final int totalSteps = isCoiffeuse ? 3 : 2;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         children: List.generate(totalSteps, (index) {
//           return Expanded(
//             child: Container(
//               height: 4,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
//
//   // Affiche l'étape actuelle selon _currentStep
//   Widget _buildCurrentStep() {
//     switch (_currentStep) {
//       case 0:
//         return _buildPersonalInfoStep();
//       case 1:
//         return _buildAddressStep();
//       case 2:
//         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
//       default:
//         return _buildPersonalInfoStep();
//     }
//   }
//
//   // Étape 1 : Informations personnelles
//   Widget _buildPersonalInfoStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Informations personnelles",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: primaryColor,
//           ),
//         ),
//         const SizedBox(height: 20),
//         _buildInputField(
//           label: "Nom",
//           controller: nameController,
//           icon: Icons.person_outline,
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer votre nom';
//             }
//             // Regex to allow only letters and apostrophes
//             if (!RegExp(r"^[a-zA-Zà-öø-ÿ' -]+$").hasMatch(value)) {
//               return 'Le nom ne peut contenir que des lettres, apostrophes, tirets et espaces.';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),
//         _buildInputField(
//           label: "Prénom",
//           controller: surnameController,
//           icon: Icons.person_outline,
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer votre prénom';
//             }
//             // Regex to allow only letters and apostrophes
//             if (!RegExp(r"^[a-zA-Zà-öø-ÿ' -]+$").hasMatch(value)) {
//               return 'Le prénom ne peut contenir que des lettres, apostrophes, tirets et espaces.';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),
//         _buildGenderDropdown(),
//         const SizedBox(height: 16),
//         _buildDatePicker(),
//         const SizedBox(height: 16),
//         _buildInputField(
//           label: "Téléphone",
//           controller: phoneController,
//           icon: Icons.phone,
//           keyboardType: TextInputType.phone,
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer votre numéro de téléphone';
//             }
//             // Belgian phone number regex: starts with 0, followed by 8 or 9 digits
//             // Allows for spaces, dots, or dashes as separators
//             if (!RegExp(r"^0\d{1,}(\s*\d{2}){3}\s*\d{2}$|^0\d{8}$|^0\d{9}$").hasMatch(value.replaceAll(RegExp(r'[ .\-]'), ''))) {
//               return 'Numéro de téléphone belge invalide (doit commencer par 0 et avoir 9 ou 10 chiffres)';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }
//
//   // Étape 2 : Adresse
//   Widget _buildAddressStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Adresse",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: primaryColor,
//           ),
//         ),
//         const SizedBox(height: 20),
//         // Utilisation du nouveau widget CommuneAutoFill
//         CommuneAutoFill(
//           codePostalController: codePostalController,
//           communeController: communeController,
//           geoapifyApiKey: geoapifyApiKey, // Passez la clé API ici
//         ),
//         const SizedBox(height: 16),
//         // Le champ Commune est maintenant géré par CommuneAutoFill
//         // Vous pouvez le laisser comme un champ de lecture seule ou le supprimer si non nécessaire
//         _buildInputField(
//           label: "Commune",
//           controller: communeController,
//           icon: Icons.location_city,
//           readOnly: true,
//           validator: (value) {
//             if (value == null || value.isEmpty || value == "Commune introuvable" || value == "Erreur de recherche" || value == "Erreur réseau") {
//               return 'Veuillez entrer un code postal valide pour obtenir la commune.';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),
//         // Utilisation du nouveau widget StreetAutocomplete
//         StreetAutocomplete(
//           streetController: streetController,
//           communeController: communeController, // Passez la commune pour un meilleur filtrage
//           codePostalController: codePostalController, // Passez le code postal pour un meilleur filtrage
//           geoapifyApiKey: geoapifyApiKey,
//           onStreetSelected: () {
//             setState(() {
//               _isStreetSelected = true;
//             });
//           },
//           onStreetChanged: () {
//             setState(() {
//               _isStreetSelected = false;
//             });
//           },
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: _buildInputField(
//                 label: "Numéro",
//                 controller: streetNumberController,
//                 icon: Icons.home,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Obligatoire';
//                   }
//                   // Allow numbers and optionally letters (e.g., "12A")
//                   if (!RegExp(r"^[0-9]+[a-zA-Z]?$").hasMatch(value)) {
//                     return 'Numéro invalide (ex: 12, 12A)';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: _buildInputField(
//                 label: "Boîte",
//                 controller: postalBoxController,
//                 icon: Icons.inbox,
//                 validator: (value) {
//                   // Only validate if not empty
//                   if (value != null && value.isNotEmpty) {
//                     if (!RegExp(r"^[a-zA-Z0-9]+$").hasMatch(value)) {
//                       return 'Boîte invalide (ex: B, 10)';
//                     }
//                   }
//                   return null;
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   // Étape 3 : Informations professionnelles (pour les coiffeuses)
//   Widget _buildProfessionalInfoStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Informations professionnelles",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: primaryColor,
//           ),
//         ),
//         const SizedBox(height: 20),
//         _buildInputField(
//           label: "Nom Commercial",
//           controller: socialNameController,
//           icon: Icons.business,
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer votre nom commercial';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }
//
//   // Input field stylisé avec validation
//   Widget _buildInputField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     bool readOnly = false,
//     TextInputType keyboardType = TextInputType.text,
//     Function(String)? onChanged,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       readOnly: readOnly,
//       keyboardType: keyboardType,
//       onChanged: onChanged,
//       validator: validator,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: primaryColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: primaryColor, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(vertical: 16),
//       ),
//     );
//   }
//
//   // Dropdown stylisé pour le genre
//   Widget _buildGenderDropdown() {
//     return DropdownButtonFormField<String>(
//       value: selectedGender,
//       decoration: InputDecoration(
//         labelText: "Sexe",
//         prefixIcon: Icon(Icons.person, color: primaryColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: primaryColor, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Veuillez sélectionner votre genre';
//         }
//         return null;
//       },
//     );
//   }
//
//   // Date picker stylisé
//   Widget _buildDatePicker() {
//     return GestureDetector(
//       onTap: () async {
//         final selectedDate = await showDatePicker(
//           context: context,
//           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
//           firstDate: DateTime(1900),
//           lastDate: DateTime.now(),
//           builder: (context, child) {
//             return Theme(
//               data: Theme.of(context).copyWith(
//                 colorScheme: ColorScheme.light(
//                   primary: primaryColor,
//                   onPrimary: Colors.white,
//                   onSurface: Colors.black,
//                 ),
//               ),
//               child: child!,
//             );
//           },
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
//         child: TextFormField(
//           controller: birthDateController,
//           decoration: InputDecoration(
//             labelText: "Date de naissance",
//             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: primaryColor, width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(vertical: 16),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer votre date de naissance';
//             }
//             if (!_isValidDate(value)) {
//               return 'Format invalide (JJ-MM-AAAA) ou vous devez avoir au moins 16 ans.';
//             }
//             return null;
//           },
//         ),
//       ),
//     );
//   }
//
//   // Boutons de navigation
//   Widget _buildNavigationButtons() {
//     final int totalSteps = isCoiffeuse ? 3 : 2;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _currentStep > 0
//             ? ElevatedButton.icon(
//           icon: const Icon(Icons.arrow_back),
//           label: const Text("Précédent"),
//           onPressed: () {
//             setState(() {
//               _currentStep--;
//             });
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.grey[200],
//             foregroundColor: Colors.black87,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         )
//             : const SizedBox(width: 120),
//         _currentStep < totalSteps - 1
//             ? ElevatedButton.icon(
//           icon: const Icon(Icons.arrow_forward),
//           label: const Text("Suivant"),
//           onPressed: () {
//             if (_validateCurrentStep()) {
//               setState(() {
//                 _currentStep++;
//               });
//             }
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: primaryColor,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         )
//             : ElevatedButton.icon(
//           icon: const Icon(Icons.check),
//           label: const Text("Enregistrer"),
//           onPressed: () {
//             if (_validateCurrentStep()) {
//               _saveProfile();
//             }
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: secondaryColor,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Validation de l'étape actuelle
//   bool _validateCurrentStep() {
//     // Manually validate the street field if it's the address step
//     if (_currentStep == 1) {
//       if (streetController.text.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Veuillez entrer votre rue.")),
//         );
//         return false;
//       }
//       if (!_isStreetSelected) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Veuillez sélectionner une rue de la liste des suggestions.")),
//         );
//         return false;
//       }
//     }
//     return _formKey.currentState?.validate() ?? false;
//   }
//
//   // Méthode pour sélectionner une photo
//   Future<void> _pickPhoto() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         allowMultiple: false,
//       );
//
//       if (result != null) {
//         setState(() {
//           if (kIsWeb) {
//             profilePhotoBytes = result.files.first.bytes;
//             profilePhoto = null;
//           } else {
//             profilePhoto = File(result.files.first.path!);
//             profilePhotoBytes = null;
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Erreur lors de la sélection de la photo: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // Validation du format de la date et de l'âge (min 16 ans)
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
//
//       // Check if the date is a valid calendar date
//       if (parsedDate.year != year || parsedDate.month != month || parsedDate.day != day) {
//         return false;
//       }
//
//       // Check if the person is at least 16 years old
//       final eighteenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 16)); // Changed to 16 years
//       return parsedDate.isBefore(eighteenYearsAgo) || parsedDate.isAtSameMomentAs(eighteenYearsAgo);
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Méthode pour récupérer la commune depuis le Code Postal (cette méthode est remplacée par le widget CommuneAutoFill)
//   // Future<void> fetchCommune(String codePostal) async { /* ... */ }
//
//
//   // Créer le modèle utilisateur à partir des données du formulaire
//   UserCreationModel _createUserModel() {
//     String formattedStreetNumber = streetNumberController.text;
//     if (postalBoxController.text.isNotEmpty) {
//       formattedStreetNumber += "/${postalBoxController.text}";
//     }
//
//     return UserCreationModel.fromForm(
//       userUuid: userUuid,
//       email: userEmail,
//       isCoiffeuse: isCoiffeuse,
//       nom: nameController.text,
//       prenom: surnameController.text,
//       sexe: selectedGender ?? "", // Passe la valeur exacte (ex: "Homme")
//       telephone: phoneController.text,
//       dateNaissance: birthDateController.text,
//       codePostal: codePostalController.text,
//       commune: communeController.text,
//       rue: streetController.text,
//       numero: formattedStreetNumber, // Use the formatted string
//       boitePostale: null, // This field is now incorporated into 'numero'
//       nomCommercial: isCoiffeuse ? socialNameController.text : null,
//       photoProfilFile: profilePhoto,
//       photoProfilBytes: profilePhotoBytes,
//       photoProfilName: 'profile_photo.png',
//     );
//   }
//
//   // Sauvegarde du profil avec le nouveau système
//   void _saveProfile() async {
//     // Afficher un indicateur de chargement
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Center(
//         child: CircularProgressIndicator(
//           color: primaryColor,
//         ),
//       ),
//     );
//
//     try {
//       // Créer le modèle utilisateur
//       final userModel = _createUserModel();
//
//       // --- DÉBUT DES LOGS DÉTAILLÉS ---
//       if (kDebugMode) {
//         print("--- Données du UserCreationModel avant envoi ---");
//         print("userUuid: ${userModel.userUuid}");
//         print("email: ${userModel.email}");
//         print("type: ${userModel.type}");
//         print("nom: ${userModel.nom}");
//         print("prenom: ${userModel.prenom}");
//         print("sexe: ${userModel.sexe}");
//         print("telephone: ${userModel.telephone}");
//         print("dateNaissance: ${userModel.dateNaissance}");
//         print("codePostal: ${userModel.codePostal}");
//         print("commune: ${userModel.commune}");
//         print("rue: ${userModel.rue}");
//         print("numero: ${userModel.numero}");
//         print("boitePostale: ${userModel.boitePostale}");
//         print("nomCommercial: ${userModel.nomCommercial}");
//         print("photoProfilFile present: ${userModel.photoProfilFile != null}");
//         print("photoProfilBytes present: ${userModel.photoProfilBytes != null}");
//         print("photoProfilName: ${userModel.photoProfilName}");
//         print("--- Fin des données du UserCreationModel ---");
//
//         // Afficher les champs qui seront envoyés via toApiFields()
//         print("--- Champs envoyés à l'API (toApiFields()) ---");
//         userModel.toApiFields().forEach((key, value) {
//           print("$key: $value");
//         });
//         print("--- Fin des champs envoyés ---");
//
//         // Afficher l'URL complète de la requête
//         final String requestUrl = "${ProfileApiService.baseUrl}/create-profile/";
//         print("URL de la requête POST: $requestUrl");
//       }
//       // --- FIN DES LOGS DÉTAILLÉS ---
//
//       // Récupérer le token Firebase via TokenService
//       String? firebaseToken;
//       try {
//         firebaseToken = await TokenService.getAuthToken();
//         if (kDebugMode) {
//           print("🔍 Token Firebase récupéré: ${firebaseToken != null ? 'Oui' : 'Non'}");
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print("❌ Erreur récupération token Firebase: $e");
//         }
//       }
//
//       // Appeler l'API via le service
//       final response = await ProfileApiService.createUserProfile(
//         userModel: userModel,
//         firebaseToken: firebaseToken,
//       );
//
//       // Fermer la boîte de dialogue de chargement
//       if (mounted) Navigator.of(context).pop();
//
//       if (!mounted) return;
//
//       if (response.success) {
//         // Animation de succès
//         _showSuccessDialog();
//
//         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         await userProvider.fetchCurrentUser();
//
//         if (!mounted) return;
//
//         if (isCoiffeuse) {
//           // Redirection vers la création de salon pour les coiffeuses
//           if (userProvider.currentUser != null) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
//             );
//           }
//         } else {
//           // Redirection vers la page d'accueil pour les clients
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const HomePage()),
//           );
//         }
//       } else {
//         // Gestion des erreurs
//         String errorMessage = response.message;
//
//         if (response.isAuthError) {
//           errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
//           // Optionnel: Nettoyer le token en cas d'erreur d'auth
//           await TokenService.clearAuthToken();
//         } else if (response.isValidationError && response.validationErrors != null) {
//           // Afficher les erreurs de validation
//           errorMessage = response.validationErrors!.values.join('\n');
//         }
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMessage),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 4),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         // Fermer la boîte de dialogue de chargement
//         Navigator.of(context).pop();
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Erreur inattendue: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // Animation de succès
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.green, size: 30),
//             const SizedBox(width: 10),
//             const Text("Profil créé !"),
//           ],
//         ),
//         content: const Text(
//           "Votre profil a été créé avec succès.",
//           textAlign: TextAlign.center,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "Continuer",
//               style: TextStyle(color: primaryColor),
//             ),
//           ),
//         ],
//       ),
//     );
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
//
// // import 'dart:io';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/pages/profil/services/profile_creation_api.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:file_picker/file_picker.dart';
// // import 'package:provider/provider.dart';
// // import '../../services/firebase_token/token_service.dart';
// // import '../../services/providers/current_user_provider.dart';
// // import '../home_page.dart';
// // import '../salon/create_salon_page.dart';
// // import '../../models/user_creation.dart';
// // import 'profil_widgets/auto_complete_widget.dart';
// // import 'profil_widgets/commune_autofill_widget.dart';
// //
// //
// // class ProfileCreationPage extends StatefulWidget {
// //   final String userUuid;
// //   final String email;
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
// //   // Variables pour le thème
// //   final Color primaryColor = const Color(0xFF8E44AD);
// //   final Color secondaryColor = const Color(0xFFF39C12);
// //
// //   static const String geoapifyApiKey = 'b097f188b11f46d2a02eb55021d168c1';
// //
// //
// //   // Variables de l'état
// //   String? selectedGender;
// //   final List<String> genderOptions = ["Homme", "Femme"];
// //   Uint8List? profilePhotoBytes;
// //   File? profilePhoto;
// //   bool isCoiffeuse = false;
// //   late String userEmail;
// //   late String userUuid;
// //   int _currentStep = 0;
// //
// //   // Controllers
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController surnameController = TextEditingController();
// //   final TextEditingController codePostalController = TextEditingController();
// //   final TextEditingController communeController = TextEditingController();
// //   final TextEditingController streetController = TextEditingController();
// //   final TextEditingController streetNumberController = TextEditingController();
// //   final TextEditingController postalBoxController = TextEditingController();
// //   final TextEditingController phoneController = TextEditingController();
// //   final TextEditingController socialNameController = TextEditingController();
// //   final TextEditingController birthDateController = TextEditingController();
// //
// //   // Form keys pour validation
// //   final _formKey = GlobalKey<FormState>();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     userEmail = widget.email;
// //     userUuid = widget.userUuid;
// //   }
// //
// //   @override
// //   void dispose() {
// //     // Libérer les contrôleurs
// //     nameController.dispose();
// //     surnameController.dispose();
// //     codePostalController.dispose();
// //     communeController.dispose();
// //     streetController.dispose();
// //     streetNumberController.dispose();
// //     postalBoxController.dispose();
// //     phoneController.dispose();
// //     socialNameController.dispose();
// //     birthDateController.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: CustomScrollView(
// //           slivers: [
// //             _buildAppBar(),
// //             SliverToBoxAdapter(
// //               child: Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //                 child: Form(
// //                   key: _formKey,
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// //                     children: [
// //                       _buildProfilePhoto(),
// //                       const SizedBox(height: 16),
// //                       // Afficher le sélecteur de rôle SEULEMENT sur l'étape 0
// //                       if (_currentStep == 0) ...[
// //                         _buildRoleSelector(),
// //                         const SizedBox(height: 24),
// //                       ],
// //                       _buildStepIndicator(),
// //                       const SizedBox(height: 20),
// //                       _buildCurrentStep(),
// //                       const SizedBox(height: 20),
// //                       _buildNavigationButtons(),
// //                       const SizedBox(height: 40),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // En-tête de l'application avec une apparence moderne
// //   Widget _buildAppBar() {
// //     return SliverAppBar(
// //       expandedHeight: 120,
// //       floating: true,
// //       pinned: true,
// //       flexibleSpace: FlexibleSpaceBar(
// //         title: Text(
// //           "Créer votre profil",
// //           style: TextStyle(
// //             color: Colors.white,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         background: Container(
// //           decoration: BoxDecoration(
// //             gradient: LinearGradient(
// //               begin: Alignment.topLeft,
// //               end: Alignment.bottomRight,
// //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // Widget pour l'affichage et la sélection de la photo de profil
// //   Widget _buildProfilePhoto() {
// //     return Center(
// //       child: Column(
// //         children: [
// //           const SizedBox(height: 20),
// //           GestureDetector(
// //             onTap: _pickPhoto,
// //             child: Stack(
// //               alignment: Alignment.bottomRight,
// //               children: [
// //                 Container(
// //                   width: 120,
// //                   height: 120,
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey[200],
// //                     shape: BoxShape.circle,
// //                     boxShadow: [
// //                       BoxShadow(
// //                         color: Colors.black.withOpacity(0.1),
// //                         blurRadius: 10,
// //                         spreadRadius: 1,
// //                       ),
// //                     ],
// //                   ),
// //                   child: ClipOval(
// //                     child: profilePhotoBytes != null
// //                         ? Image.memory(
// //                       profilePhotoBytes!,
// //                       fit: BoxFit.cover,
// //                     )
// //                         : profilePhoto != null
// //                         ? Image.file(
// //                       profilePhoto!,
// //                       fit: BoxFit.cover,
// //                     )
// //                         : Icon(
// //                       Icons.person,
// //                       size: 70,
// //                       color: Colors.grey[400],
// //                     ),
// //                   ),
// //                 ),
// //                 Container(
// //                   padding: const EdgeInsets.all(8),
// //                   decoration: BoxDecoration(
// //                     color: secondaryColor,
// //                     shape: BoxShape.circle,
// //                   ),
// //                   child: const Icon(
// //                     Icons.camera_alt,
// //                     color: Colors.white,
// //                     size: 20,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             "Photo de profil",
// //             style: TextStyle(
// //               color: Colors.grey[600],
// //               fontSize: 14,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // Sélecteur de rôle avec design moderne
// //   Widget _buildRoleSelector() {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(16),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.05),
// //             blurRadius: 10,
// //             spreadRadius: 1,
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           const Text(
// //             "Je suis :",
// //             style: TextStyle(
// //               fontWeight: FontWeight.bold,
// //               fontSize: 16,
// //             ),
// //           ),
// //           Row(
// //             children: [
// //               Text(
// //                 "Client",
// //                 style: TextStyle(
// //                   color: !isCoiffeuse ? primaryColor : Colors.grey,
// //                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// //                 ),
// //               ),
// //               Switch(
// //                 value: isCoiffeuse,
// //                 onChanged: (value) {
// //                   setState(() {
// //                     isCoiffeuse = value;
// //                   });
// //                 },
// //                 activeColor: secondaryColor,
// //                 activeTrackColor: secondaryColor.withOpacity(0.5),
// //               ),
// //               Text(
// //                 "Coiffeuse",
// //                 style: TextStyle(
// //                   color: isCoiffeuse ? primaryColor : Colors.grey,
// //                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // Indicateur de progression des étapes
// //   Widget _buildStepIndicator() {
// //     final int totalSteps = isCoiffeuse ? 3 : 2;
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16),
// //       child: Row(
// //         children: List.generate(totalSteps, (index) {
// //           return Expanded(
// //             child: Container(
// //               height: 4,
// //               margin: const EdgeInsets.symmetric(horizontal: 4),
// //               decoration: BoxDecoration(
// //                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
// //                 borderRadius: BorderRadius.circular(2),
// //               ),
// //             ),
// //           );
// //         }),
// //       ),
// //     );
// //   }
// //
// //   // Affiche l'étape actuelle selon _currentStep
// //   Widget _buildCurrentStep() {
// //     switch (_currentStep) {
// //       case 0:
// //         return _buildPersonalInfoStep();
// //       case 1:
// //         return _buildAddressStep();
// //       case 2:
// //         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
// //       default:
// //         return _buildPersonalInfoStep();
// //     }
// //   }
// //
// //   // Étape 1 : Informations personnelles
// //   Widget _buildPersonalInfoStep() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           "Informations personnelles",
// //           style: TextStyle(
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //             color: primaryColor,
// //           ),
// //         ),
// //         const SizedBox(height: 20),
// //         _buildInputField(
// //           label: "Nom",
// //           controller: nameController,
// //           icon: Icons.person_outline,
// //           validator: (value) {
// //             if (value == null || value.isEmpty) {
// //               return 'Veuillez entrer votre nom';
// //             }
// //             return null;
// //           },
// //         ),
// //         const SizedBox(height: 16),
// //         _buildInputField(
// //           label: "Prénom",
// //           controller: surnameController,
// //           icon: Icons.person_outline,
// //           validator: (value) {
// //             if (value == null || value.isEmpty) {
// //               return 'Veuillez entrer votre prénom';
// //             }
// //             return null;
// //           },
// //         ),
// //         const SizedBox(height: 16),
// //         _buildGenderDropdown(),
// //         const SizedBox(height: 16),
// //         _buildDatePicker(),
// //         const SizedBox(height: 16),
// //         _buildInputField(
// //           label: "Téléphone",
// //           controller: phoneController,
// //           icon: Icons.phone,
// //           keyboardType: TextInputType.phone,
// //           validator: (value) {
// //             if (value == null || value.isEmpty) {
// //               return 'Veuillez entrer votre numéro de téléphone';
// //             }
// //             return null;
// //           },
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // Étape 2 : Adresse
// //   Widget _buildAddressStep() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           "Adresse",
// //           style: TextStyle(
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //             color: primaryColor,
// //           ),
// //         ),
// //         const SizedBox(height: 20),
// //         // Utilisation du nouveau widget CommuneAutoFill
// //         CommuneAutoFill(
// //           codePostalController: codePostalController,
// //           communeController: communeController,
// //           geoapifyApiKey: geoapifyApiKey, // Passez la clé API ici
// //         ),
// //         const SizedBox(height: 16),
// //         // Le champ Commune est maintenant géré par CommuneAutoFill
// //         // Vous pouvez le laisser comme un champ de lecture seule ou le supprimer si non nécessaire
// //         _buildInputField(
// //           label: "Commune",
// //           controller: communeController,
// //           icon: Icons.location_city,
// //           readOnly: true,
// //         ),
// //         const SizedBox(height: 16),
// //         // Utilisation du nouveau widget StreetAutocomplete
// //         StreetAutocomplete(
// //           streetController: streetController,
// //           communeController: communeController, // Passez la commune pour un meilleur filtrage
// //           codePostalController: codePostalController, // Passez le code postal pour un meilleur filtrage
// //           geoapifyApiKey: geoapifyApiKey,
// //         ),
// //         const SizedBox(height: 16),
// //         Row(
// //           children: [
// //             Expanded(
// //               child: _buildInputField(
// //                 label: "Numéro",
// //                 controller: streetNumberController,
// //                 icon: Icons.home,
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Obligatoire';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //             ),
// //             const SizedBox(width: 16),
// //             Expanded(
// //               child: _buildInputField(
// //                 label: "Boîte",
// //                 controller: postalBoxController,
// //                 icon: Icons.inbox,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // Étape 3 : Informations professionnelles (pour les coiffeuses)
// //   Widget _buildProfessionalInfoStep() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           "Informations professionnelles",
// //           style: TextStyle(
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //             color: primaryColor,
// //           ),
// //         ),
// //         const SizedBox(height: 20),
// //         _buildInputField(
// //           label: "Nom Commercial",
// //           controller: socialNameController,
// //           icon: Icons.business,
// //           validator: (value) {
// //             if (value == null || value.isEmpty) {
// //               return 'Veuillez entrer votre nom commercial';
// //             }
// //             return null;
// //           },
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // Input field stylisé avec validation
// //   Widget _buildInputField({
// //     required String label,
// //     required TextEditingController controller,
// //     required IconData icon,
// //     bool readOnly = false,
// //     TextInputType keyboardType = TextInputType.text,
// //     Function(String)? onChanged,
// //     String? Function(String?)? validator,
// //   }) {
// //     return TextFormField(
// //       controller: controller,
// //       readOnly: readOnly,
// //       keyboardType: keyboardType,
// //       onChanged: onChanged,
// //       validator: validator,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         prefixIcon: Icon(icon, color: primaryColor),
// //         border: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(12),
// //           borderSide: BorderSide(color: Colors.grey[300]!),
// //         ),
// //         enabledBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(12),
// //           borderSide: BorderSide(color: Colors.grey[300]!),
// //         ),
// //         focusedBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(12),
// //           borderSide: BorderSide(color: primaryColor, width: 2),
// //         ),
// //         filled: true,
// //         fillColor: Colors.white,
// //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// //       ),
// //     );
// //   }
// //
// //   // Dropdown stylisé pour le genre
// //   Widget _buildGenderDropdown() {
// //     return DropdownButtonFormField<String>(
// //       value: selectedGender,
// //       decoration: InputDecoration(
// //         labelText: "Sexe",
// //         prefixIcon: Icon(Icons.person, color: primaryColor),
// //         border: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(12),
// //           borderSide: BorderSide(color: Colors.grey[300]!),
// //         ),
// //         enabledBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(12),
// //           borderSide: BorderSide(color: Colors.grey[300]!),
// //         ),
// //         focusedBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(12),
// //           borderSide: BorderSide(color: primaryColor, width: 2),
// //         ),
// //         filled: true,
// //         fillColor: Colors.white,
// //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
// //       validator: (value) {
// //         if (value == null || value.isEmpty) {
// //           return 'Veuillez sélectionner votre genre';
// //         }
// //         return null;
// //       },
// //     );
// //   }
// //
// //   // Date picker stylisé
// //   Widget _buildDatePicker() {
// //     return GestureDetector(
// //       onTap: () async {
// //         final selectedDate = await showDatePicker(
// //           context: context,
// //           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
// //           firstDate: DateTime(1900),
// //           lastDate: DateTime.now(),
// //           builder: (context, child) {
// //             return Theme(
// //               data: Theme.of(context).copyWith(
// //                 colorScheme: ColorScheme.light(
// //                   primary: primaryColor,
// //                   onPrimary: Colors.white,
// //                   onSurface: Colors.black,
// //                 ),
// //               ),
// //               child: child!,
// //             );
// //           },
// //         );
// //         if (selectedDate != null) {
// //           setState(() {
// //             birthDateController.text =
// //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// //                 "${selectedDate.year}";
// //           });
// //         }
// //       },
// //       child: AbsorbPointer(
// //         child: TextFormField(
// //           controller: birthDateController,
// //           decoration: InputDecoration(
// //             labelText: "Date de naissance",
// //             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
// //             border: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(12),
// //               borderSide: BorderSide(color: Colors.grey[300]!),
// //             ),
// //             enabledBorder: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(12),
// //               borderSide: BorderSide(color: Colors.grey[300]!),
// //             ),
// //             focusedBorder: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(12),
// //               borderSide: BorderSide(color: primaryColor, width: 2),
// //             ),
// //             filled: true,
// //             fillColor: Colors.white,
// //             contentPadding: const EdgeInsets.symmetric(vertical: 16),
// //           ),
// //           validator: (value) {
// //             if (value == null || value.isEmpty) {
// //               return 'Veuillez entrer votre date de naissance';
// //             }
// //             if (!_isValidDate(value)) {
// //               return 'Format invalide (JJ-MM-AAAA)';
// //             }
// //             return null;
// //           },
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // Boutons de navigation
// //   Widget _buildNavigationButtons() {
// //     final int totalSteps = isCoiffeuse ? 3 : 2;
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: [
// //         _currentStep > 0
// //             ? ElevatedButton.icon(
// //           icon: const Icon(Icons.arrow_back),
// //           label: const Text("Précédent"),
// //           onPressed: () {
// //             setState(() {
// //               _currentStep--;
// //             });
// //           },
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: Colors.grey[200],
// //             foregroundColor: Colors.black87,
// //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //           ),
// //         )
// //             : const SizedBox(width: 120),
// //         _currentStep < totalSteps - 1
// //             ? ElevatedButton.icon(
// //           icon: const Icon(Icons.arrow_forward),
// //           label: const Text("Suivant"),
// //           onPressed: () {
// //             if (_validateCurrentStep()) {
// //               setState(() {
// //                 _currentStep++;
// //               });
// //             }
// //           },
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: primaryColor,
// //             foregroundColor: Colors.white,
// //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //           ),
// //         )
// //             : ElevatedButton.icon(
// //           icon: const Icon(Icons.check),
// //           label: const Text("Enregistrer"),
// //           onPressed: () {
// //             if (_validateCurrentStep()) {
// //               _saveProfile();
// //             }
// //           },
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: secondaryColor,
// //             foregroundColor: Colors.white,
// //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // Validation de l'étape actuelle
// //   bool _validateCurrentStep() {
// //     return _formKey.currentState?.validate() ?? false;
// //   }
// //
// //   // Méthode pour sélectionner une photo
// //   Future<void> _pickPhoto() async {
// //     try {
// //       final result = await FilePicker.platform.pickFiles(
// //         type: FileType.image,
// //         allowMultiple: false,
// //       );
// //
// //       if (result != null) {
// //         setState(() {
// //           if (kIsWeb) {
// //             profilePhotoBytes = result.files.first.bytes;
// //             profilePhoto = null;
// //           } else {
// //             profilePhoto = File(result.files.first.path!);
// //             profilePhotoBytes = null;
// //           }
// //         });
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Erreur lors de la sélection de la photo: $e"),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }
// //
// //   // Validation du format de la date
// //   bool _isValidDate(String date) {
// //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// //     if (!regex.hasMatch(date)) return false;
// //
// //     try {
// //       final parts = date.split('-');
// //       final day = int.parse(parts[0]);
// //       final month = int.parse(parts[1]);
// //       final year = int.parse(parts[2]);
// //       final parsedDate = DateTime(year, month, day);
// //       return parsedDate.year == year &&
// //           parsedDate.month == month &&
// //           parsedDate.day == day;
// //     } catch (e) {
// //       return false;
// //     }
// //   }
// //
// //   // Méthode pour récupérer la commune depuis le Code Postal (cette méthode est remplacée par le widget CommuneAutoFill)
// //   // Future<void> fetchCommune(String codePostal) async { /* ... */ }
// //
// //
// //   // Créer le modèle utilisateur à partir des données du formulaire
// //   UserCreationModel _createUserModel() {
// //     return UserCreationModel.fromForm(
// //       userUuid: userUuid,
// //       email: userEmail,
// //       isCoiffeuse: isCoiffeuse,
// //       nom: nameController.text,
// //       prenom: surnameController.text,
// //       sexe: selectedGender ?? "", // Passe la valeur exacte (ex: "Homme")
// //       telephone: phoneController.text,
// //       dateNaissance: birthDateController.text,
// //       codePostal: codePostalController.text,
// //       commune: communeController.text,
// //       rue: streetController.text,
// //       numero: streetNumberController.text,
// //       boitePostale: postalBoxController.text.isNotEmpty ? postalBoxController.text : null,
// //       nomCommercial: isCoiffeuse ? socialNameController.text : null,
// //       photoProfilFile: profilePhoto,
// //       photoProfilBytes: profilePhotoBytes,
// //       photoProfilName: 'profile_photo.png',
// //     );
// //   }
// //
// //   // Sauvegarde du profil avec le nouveau système
// //   void _saveProfile() async {
// //     // Afficher un indicateur de chargement
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => Center(
// //         child: CircularProgressIndicator(
// //           color: primaryColor,
// //         ),
// //       ),
// //     );
// //
// //     try {
// //       // Créer le modèle utilisateur
// //       final userModel = _createUserModel();
// //
// //       // --- DÉBUT DES LOGS DÉTAILLÉS ---
// //       if (kDebugMode) {
// //         print("--- Données du UserCreationModel avant envoi ---");
// //         print("userUuid: ${userModel.userUuid}");
// //         print("email: ${userModel.email}");
// //         print("type: ${userModel.type}");
// //         print("nom: ${userModel.nom}");
// //         print("prenom: ${userModel.prenom}");
// //         print("sexe: ${userModel.sexe}");
// //         print("telephone: ${userModel.telephone}");
// //         print("dateNaissance: ${userModel.dateNaissance}");
// //         print("codePostal: ${userModel.codePostal}");
// //         print("commune: ${userModel.commune}");
// //         print("rue: ${userModel.rue}");
// //         print("numero: ${userModel.numero}");
// //         print("boitePostale: ${userModel.boitePostale}");
// //         print("nomCommercial: ${userModel.nomCommercial}");
// //         print("photoProfilFile present: ${userModel.photoProfilFile != null}");
// //         print("photoProfilBytes present: ${userModel.photoProfilBytes != null}");
// //         print("photoProfilName: ${userModel.photoProfilName}");
// //         print("--- Fin des données du UserCreationModel ---");
// //
// //         // Afficher les champs qui seront envoyés via toApiFields()
// //         print("--- Champs envoyés à l'API (toApiFields()) ---");
// //         userModel.toApiFields().forEach((key, value) {
// //           print("$key: $value");
// //         });
// //         print("--- Fin des champs envoyés ---");
// //
// //         // Afficher l'URL complète de la requête
// //         final String requestUrl = "${ProfileApiService.baseUrl}/create-profile/";
// //         print("URL de la requête POST: $requestUrl");
// //       }
// //       // --- FIN DES LOGS DÉTAILLÉS ---
// //
// //       // Récupérer le token Firebase via TokenService
// //       String? firebaseToken;
// //       try {
// //         firebaseToken = await TokenService.getAuthToken();
// //         if (kDebugMode) {
// //           print("🔍 Token Firebase récupéré: ${firebaseToken != null ? 'Oui' : 'Non'}");
// //         }
// //       } catch (e) {
// //         if (kDebugMode) {
// //           print("❌ Erreur récupération token Firebase: $e");
// //         }
// //       }
// //
// //       // Appeler l'API via le service
// //       final response = await ProfileApiService.createUserProfile(
// //         userModel: userModel,
// //         firebaseToken: firebaseToken,
// //       );
// //
// //       // Fermer la boîte de dialogue de chargement
// //       if (mounted) Navigator.of(context).pop();
// //
// //       if (!mounted) return;
// //
// //       if (response.success) {
// //         // Animation de succès
// //         _showSuccessDialog();
// //
// //         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// //         await userProvider.fetchCurrentUser();
// //
// //         if (!mounted) return;
// //
// //         if (isCoiffeuse) {
// //           // Redirection vers la création de salon pour les coiffeuses
// //           if (userProvider.currentUser != null) {
// //             Navigator.push(
// //               context,
// //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// //             );
// //           }
// //         } else {
// //           // Redirection vers la page d'accueil pour les clients
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(builder: (_) => const HomePage()),
// //           );
// //         }
// //       } else {
// //         // Gestion des erreurs
// //         String errorMessage = response.message;
// //
// //         if (response.isAuthError) {
// //           errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
// //           // Optionnel: Nettoyer le token en cas d'erreur d'auth
// //           await TokenService.clearAuthToken();
// //         } else if (response.isValidationError && response.validationErrors != null) {
// //           // Afficher les erreurs de validation
// //           errorMessage = response.validationErrors!.values.join('\n');
// //         }
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(errorMessage),
// //             backgroundColor: Colors.red,
// //             duration: const Duration(seconds: 4),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         // Fermer la boîte de dialogue de chargement
// //         Navigator.of(context).pop();
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Erreur inattendue: $e"),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }
// //
// //   // Animation de succès
// //   void _showSuccessDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(20),
// //         ),
// //         title: Row(
// //           children: [
// //             Icon(Icons.check_circle, color: Colors.green, size: 30),
// //             const SizedBox(width: 10),
// //             const Text("Profil créé !"),
// //           ],
// //         ),
// //         content: const Text(
// //           "Votre profil a été créé avec succès.",
// //           textAlign: TextAlign.center,
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text(
// //               "Continuer",
// //               style: TextStyle(color: primaryColor),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// // // import 'dart:convert';
// // // import 'dart:io';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/pages/profil/services/profile_creation_api.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:file_picker/file_picker.dart';
// // // import 'package:provider/provider.dart';
// // // import '../../services/firebase_token/token_service.dart';
// // // import '../../services/providers/current_user_provider.dart';
// // // import '../home_page.dart';
// // // import '../salon/create_salon_page.dart';
// // // import '../../models/user_creation.dart';
// // //
// // // class ProfileCreationPage extends StatefulWidget {
// // //   final String userUuid;
// // //   final String email;
// // //
// // //   const ProfileCreationPage({
// // //     required this.userUuid,
// // //     required this.email,
// // //     super.key,
// // //   });
// // //
// // //   @override
// // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // }
// // //
// // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // //   // Variables pour le thème
// // //   final Color primaryColor = const Color(0xFF8E44AD);
// // //   final Color secondaryColor = const Color(0xFFF39C12);
// // //
// // //   // Variables de l'état
// // //   String? selectedGender;
// // //   final List<String> genderOptions = ["Homme", "Femme"];
// // //   Uint8List? profilePhotoBytes;
// // //   File? profilePhoto;
// // //   bool isCoiffeuse = false; // Ceci détermine si le type est "Coiffeuse" ou "Client"
// // //   late String userEmail;
// // //   late String userUuid;
// // //   int _currentStep = 0;
// // //
// // //   // Controllers
// // //   final TextEditingController nameController = TextEditingController();
// // //   final TextEditingController surnameController = TextEditingController();
// // //   final TextEditingController codePostalController = TextEditingController();
// // //   final TextEditingController communeController = TextEditingController();
// // //   final TextEditingController streetController = TextEditingController();
// // //   final TextEditingController streetNumberController = TextEditingController();
// // //   final TextEditingController postalBoxController = TextEditingController();
// // //   final TextEditingController phoneController = TextEditingController();
// // //   final TextEditingController socialNameController = TextEditingController();
// // //   final TextEditingController birthDateController = TextEditingController();
// // //
// // //   // Form keys pour validation
// // //   final _formKey = GlobalKey<FormState>();
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     userEmail = widget.email;
// // //     userUuid = widget.userUuid;
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     // Libérer les contrôleurs
// // //     nameController.dispose();
// // //     surnameController.dispose();
// // //     codePostalController.dispose();
// // //     communeController.dispose();
// // //     streetController.dispose();
// // //     streetNumberController.dispose();
// // //     postalBoxController.dispose();
// // //     phoneController.dispose();
// // //     socialNameController.dispose();
// // //     birthDateController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       body: SafeArea(
// // //         child: CustomScrollView(
// // //           slivers: [
// // //             _buildAppBar(),
// // //             SliverToBoxAdapter(
// // //               child: Padding(
// // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // //                 child: Form(
// // //                   key: _formKey,
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // //                     children: [
// // //                       _buildProfilePhoto(),
// // //                       const SizedBox(height: 16),
// // //                       _buildRoleSelector(),
// // //                       const SizedBox(height: 24),
// // //                       _buildStepIndicator(),
// // //                       const SizedBox(height: 20),
// // //                       _buildCurrentStep(),
// // //                       const SizedBox(height: 20),
// // //                       _buildNavigationButtons(),
// // //                       const SizedBox(height: 40),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // En-tête de l'application avec une apparence moderne
// // //   Widget _buildAppBar() {
// // //     return SliverAppBar(
// // //       expandedHeight: 120,
// // //       floating: true,
// // //       pinned: true,
// // //       flexibleSpace: FlexibleSpaceBar(
// // //         title: Text(
// // //           "Créer votre profil",
// // //           style: TextStyle(
// // //             color: Colors.white,
// // //             fontWeight: FontWeight.bold,
// // //           ),
// // //         ),
// // //         background: Container(
// // //           decoration: BoxDecoration(
// // //             gradient: LinearGradient(
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Widget pour l'affichage et la sélection de la photo de profil
// // //   Widget _buildProfilePhoto() {
// // //     return Center(
// // //       child: Column(
// // //         children: [
// // //           const SizedBox(height: 20),
// // //           GestureDetector(
// // //             onTap: _pickPhoto,
// // //             child: Stack(
// // //               alignment: Alignment.bottomRight,
// // //               children: [
// // //                 Container(
// // //                   width: 120,
// // //                   height: 120,
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.grey[200],
// // //                     shape: BoxShape.circle,
// // //                     boxShadow: [
// // //                       BoxShadow(
// // //                         color: Colors.black.withOpacity(0.1),
// // //                         blurRadius: 10,
// // //                         spreadRadius: 1,
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   child: ClipOval(
// // //                     child: profilePhotoBytes != null
// // //                         ? Image.memory(
// // //                       profilePhotoBytes!,
// // //                       fit: BoxFit.cover,
// // //                     )
// // //                         : profilePhoto != null
// // //                         ? Image.file(
// // //                       profilePhoto!,
// // //                       fit: BoxFit.cover,
// // //                     )
// // //                         : Icon(
// // //                       Icons.person,
// // //                       size: 70,
// // //                       color: Colors.grey[400],
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 Container(
// // //                   padding: const EdgeInsets.all(8),
// // //                   decoration: BoxDecoration(
// // //                     color: secondaryColor,
// // //                     shape: BoxShape.circle,
// // //                   ),
// // //                   child: const Icon(
// // //                     Icons.camera_alt,
// // //                     color: Colors.white,
// // //                     size: 20,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           Text(
// // //             "Photo de profil",
// // //             style: TextStyle(
// // //               color: Colors.grey[600],
// // //               fontSize: 14,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Sélecteur de rôle avec design moderne
// // //   Widget _buildRoleSelector() {
// // //     return Container(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(16),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.05),
// // //             blurRadius: 10,
// // //             spreadRadius: 1,
// // //           ),
// // //         ],
// // //       ),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //         children: [
// // //           const Text(
// // //             "Je suis :",
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontSize: 16,
// // //             ),
// // //           ),
// // //           Row(
// // //             children: [
// // //               Text(
// // //                 "Client",
// // //                 style: TextStyle(
// // //                   color: !isCoiffeuse ? primaryColor : Colors.grey,
// // //                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // //                 ),
// // //               ),
// // //               Switch(
// // //                 value: isCoiffeuse,
// // //                 onChanged: (value) {
// // //                   setState(() {
// // //                     isCoiffeuse = value;
// // //                   });
// // //                 },
// // //                 activeColor: secondaryColor,
// // //                 activeTrackColor: secondaryColor.withOpacity(0.5),
// // //               ),
// // //               Text(
// // //                 "Coiffeuse",
// // //                 style: TextStyle(
// // //                   color: isCoiffeuse ? primaryColor : Colors.grey,
// // //                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Indicateur de progression des étapes
// // //   Widget _buildStepIndicator() {
// // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // //       child: Row(
// // //         children: List.generate(totalSteps, (index) {
// // //           return Expanded(
// // //             child: Container(
// // //               height: 4,
// // //               margin: const EdgeInsets.symmetric(horizontal: 4),
// // //               decoration: BoxDecoration(
// // //                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
// // //                 borderRadius: BorderRadius.circular(2),
// // //               ),
// // //             ),
// // //           );
// // //         }),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Affiche l'étape actuelle selon _currentStep
// // //   Widget _buildCurrentStep() {
// // //     switch (_currentStep) {
// // //       case 0:
// // //         return _buildPersonalInfoStep();
// // //       case 1:
// // //         return _buildAddressStep();
// // //       case 2:
// // //         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
// // //       default:
// // //         return _buildPersonalInfoStep();
// // //     }
// // //   }
// // //
// // //   // Étape 1 : Informations personnelles
// // //   Widget _buildPersonalInfoStep() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           "Informations personnelles",
// // //           style: TextStyle(
// // //             fontSize: 20,
// // //             fontWeight: FontWeight.bold,
// // //             color: primaryColor,
// // //           ),
// // //         ),
// // //         const SizedBox(height: 20),
// // //         _buildInputField(
// // //           label: "Nom",
// // //           controller: nameController,
// // //           icon: Icons.person_outline,
// // //           validator: (value) {
// // //             if (value == null || value.isEmpty) {
// // //               return 'Veuillez entrer votre nom';
// // //             }
// // //             return null;
// // //           },
// // //         ),
// // //         const SizedBox(height: 16),
// // //         _buildInputField(
// // //           label: "Prénom",
// // //           controller: surnameController,
// // //           icon: Icons.person_outline,
// // //           validator: (value) {
// // //             if (value == null || value.isEmpty) {
// // //               return 'Veuillez entrer votre prénom';
// // //             }
// // //             return null;
// // //           },
// // //         ),
// // //         const SizedBox(height: 16),
// // //         _buildGenderDropdown(),
// // //         const SizedBox(height: 16),
// // //         _buildDatePicker(),
// // //         const SizedBox(height: 16),
// // //         _buildInputField(
// // //           label: "Téléphone",
// // //           controller: phoneController,
// // //           icon: Icons.phone,
// // //           keyboardType: TextInputType.phone,
// // //           validator: (value) {
// // //             if (value == null || value.isEmpty) {
// // //               return 'Veuillez entrer votre numéro de téléphone';
// // //             }
// // //             return null;
// // //           },
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   // Étape 2 : Adresse
// // //   Widget _buildAddressStep() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           "Adresse",
// // //           style: TextStyle(
// // //             fontSize: 20,
// // //             fontWeight: FontWeight.bold,
// // //             color: primaryColor,
// // //           ),
// // //         ),
// // //         const SizedBox(height: 20),
// // //         _buildInputField(
// // //           label: "Code Postal",
// // //           controller: codePostalController,
// // //           icon: Icons.location_on_outlined,
// // //           keyboardType: TextInputType.number,
// // //           onChanged: fetchCommune,
// // //           validator: (value) {
// // //             if (value == null || value.isEmpty) {
// // //               return 'Veuillez entrer votre code postal';
// // //             }
// // //             return null;
// // //           },
// // //         ),
// // //         const SizedBox(height: 16),
// // //         _buildInputField(
// // //           label: "Commune",
// // //           controller: communeController,
// // //           icon: Icons.location_city,
// // //           readOnly: true,
// // //         ),
// // //         const SizedBox(height: 16),
// // //         _buildInputField(
// // //           label: "Rue",
// // //           controller: streetController,
// // //           icon: Icons.streetview,
// // //           validator: (value) {
// // //             if (value == null || value.isEmpty) {
// // //               return 'Veuillez entrer votre rue';
// // //             }
// // //             return null;
// // //           },
// // //         ),
// // //         const SizedBox(height: 16),
// // //         Row(
// // //           children: [
// // //             Expanded(
// // //               child: _buildInputField(
// // //                 label: "Numéro",
// // //                 controller: streetNumberController,
// // //                 icon: Icons.home,
// // //                 validator: (value) {
// // //                   if (value == null || value.isEmpty) {
// // //                     return 'Obligatoire';
// // //                   }
// // //                   return null;
// // //                 },
// // //               ),
// // //             ),
// // //             const SizedBox(width: 16),
// // //             Expanded(
// // //               child: _buildInputField(
// // //                 label: "Boîte",
// // //                 controller: postalBoxController,
// // //                 icon: Icons.inbox,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   // Étape 3 : Informations professionnelles (pour les coiffeuses)
// // //   Widget _buildProfessionalInfoStep() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           "Informations professionnelles",
// // //           style: TextStyle(
// // //             fontSize: 20,
// // //             fontWeight: FontWeight.bold,
// // //             color: primaryColor,
// // //           ),
// // //         ),
// // //         const SizedBox(height: 20),
// // //         _buildInputField(
// // //           label: "Nom Commercial",
// // //           controller: socialNameController,
// // //           icon: Icons.business,
// // //           validator: (value) {
// // //             if (value == null || value.isEmpty) {
// // //               return 'Veuillez entrer votre nom commercial';
// // //             }
// // //             return null;
// // //           },
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   // Input field stylisé avec validation
// // //   Widget _buildInputField({
// // //     required String label,
// // //     required TextEditingController controller,
// // //     required IconData icon,
// // //     bool readOnly = false,
// // //     TextInputType keyboardType = TextInputType.text,
// // //     Function(String)? onChanged,
// // //     String? Function(String?)? validator,
// // //   }) {
// // //     return TextFormField(
// // //       controller: controller,
// // //       readOnly: readOnly,
// // //       keyboardType: keyboardType,
// // //       onChanged: onChanged,
// // //       validator: validator,
// // //       decoration: InputDecoration(
// // //         labelText: label,
// // //         prefixIcon: Icon(icon, color: primaryColor),
// // //         border: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(12),
// // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // //         ),
// // //         enabledBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(12),
// // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // //         ),
// // //         focusedBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(12),
// // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // //         ),
// // //         filled: true,
// // //         fillColor: Colors.white,
// // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Dropdown stylisé pour le genre
// // //   Widget _buildGenderDropdown() {
// // //     return DropdownButtonFormField<String>(
// // //       value: selectedGender,
// // //       decoration: InputDecoration(
// // //         labelText: "Sexe",
// // //         prefixIcon: Icon(Icons.person, color: primaryColor),
// // //         border: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(12),
// // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // //         ),
// // //         enabledBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(12),
// // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // //         ),
// // //         focusedBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(12),
// // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // //         ),
// // //         filled: true,
// // //         fillColor: Colors.white,
// // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // //       ),
// // //       items: genderOptions
// // //           .map((gender) => DropdownMenuItem(
// // //         value: gender,
// // //         child: Text(gender),
// // //       ))
// // //           .toList(),
// // //       onChanged: (value) {
// // //         setState(() {
// // //           selectedGender = value;
// // //         });
// // //       },
// // //       validator: (value) {
// // //         if (value == null || value.isEmpty) {
// // //           return 'Veuillez sélectionner votre genre';
// // //         }
// // //         return null;
// // //       },
// // //     );
// // //   }
// // //
// // //   // Date picker stylisé
// // //   Widget _buildDatePicker() {
// // //     return GestureDetector(
// // //       onTap: () async {
// // //         final selectedDate = await showDatePicker(
// // //           context: context,
// // //           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
// // //           firstDate: DateTime(1900),
// // //           lastDate: DateTime.now(),
// // //           builder: (context, child) {
// // //             return Theme(
// // //               data: Theme.of(context).copyWith(
// // //                 colorScheme: ColorScheme.light(
// // //                   primary: primaryColor,
// // //                   onPrimary: Colors.white,
// // //                   onSurface: Colors.black,
// // //                 ),
// // //               ),
// // //               child: child!,
// // //             );
// // //           },
// // //         );
// // //         if (selectedDate != null) {
// // //           setState(() {
// // //             birthDateController.text =
// // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // //                 "${selectedDate.year}";
// // //           });
// // //         }
// // //       },
// // //       child: AbsorbPointer(
// // //         child: TextFormField(
// // //           controller: birthDateController,
// // //           decoration: InputDecoration(
// // //             labelText: "Date de naissance",
// // //             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
// // //             border: OutlineInputBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // //             ),
// // //             enabledBorder: OutlineInputBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // //             ),
// // //             focusedBorder: OutlineInputBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //               borderSide: BorderSide(color: primaryColor, width: 2),
// // //             ),
// // //             filled: true,
// // //             fillColor: Colors.white,
// // //             contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // //           ),
// // //           validator: (value) {
// // //             if (value == null || value.isEmpty) {
// // //               return 'Veuillez entrer votre date de naissance';
// // //             }
// // //             if (!_isValidDate(value)) {
// // //               return 'Format invalide (JJ-MM-AAAA)';
// // //             }
// // //             return null;
// // //           },
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // Boutons de navigation
// // //   Widget _buildNavigationButtons() {
// // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // //     return Row(
// // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //       children: [
// // //         _currentStep > 0
// // //             ? ElevatedButton.icon(
// // //           icon: const Icon(Icons.arrow_back),
// // //           label: const Text("Précédent"),
// // //           onPressed: () {
// // //             setState(() {
// // //               _currentStep--;
// // //             });
// // //           },
// // //           style: ElevatedButton.styleFrom(
// // //             backgroundColor: Colors.grey[200],
// // //             foregroundColor: Colors.black87,
// // //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //           ),
// // //         )
// // //             : const SizedBox(width: 120),
// // //         _currentStep < totalSteps - 1
// // //             ? ElevatedButton.icon(
// // //           icon: const Icon(Icons.arrow_forward),
// // //           label: const Text("Suivant"),
// // //           onPressed: () {
// // //             if (_validateCurrentStep()) {
// // //               setState(() {
// // //                 _currentStep++;
// // //               });
// // //             }
// // //           },
// // //           style: ElevatedButton.styleFrom(
// // //             backgroundColor: primaryColor,
// // //             foregroundColor: Colors.white,
// // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //           ),
// // //         )
// // //             : ElevatedButton.icon(
// // //           icon: const Icon(Icons.check),
// // //           label: const Text("Enregistrer"),
// // //           onPressed: () {
// // //             if (_validateCurrentStep()) {
// // //               _saveProfile();
// // //             }
// // //           },
// // //           style: ElevatedButton.styleFrom(
// // //             backgroundColor: secondaryColor,
// // //             foregroundColor: Colors.white,
// // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   // Validation de l'étape actuelle
// // //   bool _validateCurrentStep() {
// // //     return _formKey.currentState?.validate() ?? false;
// // //   }
// // //
// // //   // Méthode pour sélectionner une photo
// // //   Future<void> _pickPhoto() async {
// // //     try {
// // //       final result = await FilePicker.platform.pickFiles(
// // //         type: FileType.image,
// // //         allowMultiple: false,
// // //       );
// // //
// // //       if (result != null) {
// // //         setState(() {
// // //           if (kIsWeb) {
// // //             profilePhotoBytes = result.files.first.bytes;
// // //             profilePhoto = null;
// // //           } else {
// // //             profilePhoto = File(result.files.first.path!);
// // //             profilePhotoBytes = null;
// // //           }
// // //         });
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text("Erreur lors de la sélection de la photo: $e"),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     }
// // //   }
// // //
// // //   // Validation du format de la date
// // //   bool _isValidDate(String date) {
// // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // //     if (!regex.hasMatch(date)) return false;
// // //
// // //     try {
// // //       final parts = date.split('-');
// // //       final day = int.parse(parts[0]);
// // //       final month = int.parse(parts[1]);
// // //       final year = int.parse(parts[2]);
// // //       final parsedDate = DateTime(year, month, day);
// // //       return parsedDate.year == year &&
// // //           parsedDate.month == month &&
// // //           parsedDate.day == day;
// // //     } catch (e) {
// // //       return false;
// // //     }
// // //   }
// // //
// // //   // Méthode pour récupérer la commune depuis le Code Postal
// // //   Future<void> fetchCommune(String codePostal) async {
// // //     if (codePostal.length < 4) return;
// // //
// // //     final url = Uri.parse(
// // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // //
// // //     try {
// // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body) as List;
// // //         if (data.isNotEmpty) {
// // //           final addressDetailsUrl = Uri.parse(
// // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // //           final addressResponse = await http.get(addressDetailsUrl,
// // //               headers: {'User-Agent': 'FlutterApp/1.0'});
// // //           if (addressResponse.statusCode == 200) {
// // //             final addressData = json.decode(addressResponse.body);
// // //             if (mounted) {
// // //               setState(() {
// // //                 communeController.text = addressData['address']['city'] ??
// // //                     addressData['address']['town'] ??
// // //                     addressData['address']['village'] ??
// // //                     "Commune introuvable";
// // //               });
// // //             }
// // //           }
// // //         }
// // //       }
// // //     } catch (e) {
// // //       debugPrint("Erreur commune : $e");
// // //     }
// // //   }
// // //
// // //   // Créer le modèle utilisateur à partir des données du formulaire
// // //   UserCreationModel _createUserModel() {
// // //     return UserCreationModel.fromForm(
// // //       userUuid: userUuid,
// // //       email: userEmail,
// // //       isCoiffeuse: isCoiffeuse,
// // //       nom: nameController.text,
// // //       prenom: surnameController.text,
// // //       sexe: selectedGender ?? "", // CHANGEMENT : Passer la valeur exacte de selectedGender
// // //       telephone: phoneController.text,
// // //       dateNaissance: birthDateController.text,
// // //       codePostal: codePostalController.text,
// // //       commune: communeController.text,
// // //       rue: streetController.text,
// // //       numero: streetNumberController.text,
// // //       boitePostale: postalBoxController.text.isNotEmpty ? postalBoxController.text : null,
// // //       nomCommercial: isCoiffeuse ? socialNameController.text : null,
// // //       photoProfilFile: profilePhoto,
// // //       photoProfilBytes: profilePhotoBytes,
// // //       photoProfilName: 'profile_photo.png',
// // //     );
// // //   }
// // //
// // //   // Sauvegarde du profil avec le nouveau système
// // //   void _saveProfile() async {
// // //     // Afficher un indicateur de chargement
// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (context) => Center(
// // //         child: CircularProgressIndicator(
// // //           color: primaryColor,
// // //         ),
// // //       ),
// // //     );
// // //
// // //     try {
// // //       // Créer le modèle utilisateur
// // //       final userModel = _createUserModel();
// // //
// // //       // --- DÉBUT DES LOGS DÉTAILLÉS ---
// // //       if (kDebugMode) {
// // //         print("--- Données du UserCreationModel avant envoi ---");
// // //         print("userUuid: ${userModel.userUuid}");
// // //         print("email: ${userModel.email}");
// // //         print("type: ${userModel.type}");
// // //         print("nom: ${userModel.nom}");
// // //         print("prenom: ${userModel.prenom}");
// // //         print("sexe: ${userModel.sexe}");
// // //         print("telephone: ${userModel.telephone}");
// // //         print("dateNaissance: ${userModel.dateNaissance}");
// // //         print("codePostal: ${userModel.codePostal}");
// // //         print("commune: ${userModel.commune}");
// // //         print("rue: ${userModel.rue}");
// // //         print("numero: ${userModel.numero}");
// // //         print("boitePostale: ${userModel.boitePostale}");
// // //         print("nomCommercial: ${userModel.nomCommercial}");
// // //         print("photoProfilFile present: ${userModel.photoProfilFile != null}");
// // //         print("photoProfilBytes present: ${userModel.photoProfilBytes != null}");
// // //         print("photoProfilName: ${userModel.photoProfilName}");
// // //         print("--- Fin des données du UserCreationModel ---");
// // //
// // //         // Afficher les champs qui seront envoyés via toApiFields()
// // //         print("--- Champs envoyés à l'API (toApiFields()) ---");
// // //         userModel.toApiFields().forEach((key, value) {
// // //           print("$key: $value");
// // //         });
// // //         print("--- Fin des champs envoyés ---");
// // //
// // //         // Afficher l'URL complète de la requête
// // //         final String requestUrl = "${ProfileApiService.baseUrl}/create-profile/";
// // //         print("URL de la requête POST: $requestUrl");
// // //       }
// // //       // --- FIN DES LOGS DÉTAILLÉS ---
// // //
// // //       // Récupérer le token Firebase via TokenService
// // //       String? firebaseToken;
// // //       try {
// // //         firebaseToken = await TokenService.getAuthToken();
// // //         if (kDebugMode) {
// // //           print("🔍 Token Firebase récupéré: ${firebaseToken != null ? 'Oui' : 'Non'}");
// // //         }
// // //       } catch (e) {
// // //         if (kDebugMode) {
// // //           print("❌ Erreur récupération token Firebase: $e");
// // //         }
// // //       }
// // //
// // //       // Appeler l'API via le service
// // //       final response = await ProfileApiService.createUserProfile(
// // //         userModel: userModel,
// // //         firebaseToken: firebaseToken,
// // //       );
// // //
// // //       // Fermer la boîte de dialogue de chargement
// // //       if (mounted) Navigator.of(context).pop();
// // //
// // //       if (!mounted) return;
// // //
// // //       if (response.success) {
// // //         // Animation de succès
// // //         _showSuccessDialog();
// // //
// // //         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // //         await userProvider.fetchCurrentUser();
// // //
// // //         if (!mounted) return;
// // //
// // //         if (isCoiffeuse) {
// // //           // Redirection vers la création de salon pour les coiffeuses
// // //           if (userProvider.currentUser != null) {
// // //             Navigator.push(
// // //               context,
// // //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// // //             );
// // //           }
// // //         } else {
// // //           // Redirection vers la page d'accueil pour les clients
// // //           Navigator.pushReplacement(
// // //             context,
// // //             MaterialPageRoute(builder: (_) => const HomePage()),
// // //           );
// // //         }
// // //       } else {
// // //         // Gestion des erreurs
// // //         String errorMessage = response.message;
// // //
// // //         if (response.isAuthError) {
// // //           errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
// // //           // Optionnel: Nettoyer le token en cas d'erreur d'auth
// // //           await TokenService.clearAuthToken();
// // //         } else if (response.isValidationError && response.validationErrors != null) {
// // //           // Afficher les erreurs de validation
// // //           errorMessage = response.validationErrors!.values.join('\n');
// // //         }
// // //
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text(errorMessage),
// // //             backgroundColor: Colors.red,
// // //             duration: const Duration(seconds: 4),
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         // Fermer la boîte de dialogue de chargement
// // //         Navigator.of(context).pop();
// // //
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text("Erreur inattendue: $e"),
// // //             backgroundColor: Colors.red,
// // //           ),
// // //         );
// // //       }
// // //     }
// // //   }
// // //
// // //   // Animation de succès
// // //   void _showSuccessDialog() {
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) => AlertDialog(
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(20),
// // //         ),
// // //         title: Row(
// // //           children: [
// // //             Icon(Icons.check_circle, color: Colors.green, size: 30),
// // //             const SizedBox(width: 10),
// // //             const Text("Profil créé !"),
// // //           ],
// // //         ),
// // //         content: const Text(
// // //           "Votre profil a été créé avec succès.",
// // //           textAlign: TextAlign.center,
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(context),
// // //             child: Text(
// // //               "Continuer",
// // //               style: TextStyle(color: primaryColor),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // // // import 'dart:convert';
// // // // import 'dart:io';
// // // // import 'package:flutter/foundation.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:hairbnb/pages/profil/services/profile_creation_api.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'package:file_picker/file_picker.dart';
// // // // import 'package:provider/provider.dart';
// // // // import '../../services/firebase_token/token_service.dart';
// // // // import '../../services/providers/current_user_provider.dart';
// // // // import '../home_page.dart';
// // // // import '../salon/create_salon_page.dart';
// // // // import '../../models/user_creation.dart';
// // // //
// // // // class ProfileCreationPage extends StatefulWidget {
// // // //   final String userUuid;
// // // //   final String email;
// // // //
// // // //   const ProfileCreationPage({
// // // //     required this.userUuid,
// // // //     required this.email,
// // // //     super.key,
// // // //   });
// // // //
// // // //   @override
// // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // }
// // // //
// // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // //   // Variables pour le thème
// // // //   final Color primaryColor = const Color(0xFF8E44AD);
// // // //   final Color secondaryColor = const Color(0xFFF39C12);
// // // //
// // // //   // Variables de l'état
// // // //   String? selectedGender;
// // // //   final List<String> genderOptions = ["Homme", "Femme"];
// // // //   Uint8List? profilePhotoBytes;
// // // //   File? profilePhoto;
// // // //   bool isCoiffeuse = false;
// // // //   late String userEmail;
// // // //   late String userUuid;
// // // //   int _currentStep = 0;
// // // //
// // // //   // Controllers
// // // //   final TextEditingController nameController = TextEditingController();
// // // //   final TextEditingController surnameController = TextEditingController();
// // // //   final TextEditingController codePostalController = TextEditingController();
// // // //   final TextEditingController communeController = TextEditingController();
// // // //   final TextEditingController streetController = TextEditingController();
// // // //   final TextEditingController streetNumberController = TextEditingController();
// // // //   final TextEditingController postalBoxController = TextEditingController();
// // // //   final TextEditingController phoneController = TextEditingController();
// // // //   final TextEditingController socialNameController = TextEditingController();
// // // //   final TextEditingController birthDateController = TextEditingController();
// // // //
// // // //   // Form keys pour validation
// // // //   final _formKey = GlobalKey<FormState>();
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     userEmail = widget.email;
// // // //     userUuid = widget.userUuid;
// // // //   }
// // // //
// // // //   @override
// // // //   void dispose() {
// // // //     // Libérer les contrôleurs
// // // //     nameController.dispose();
// // // //     surnameController.dispose();
// // // //     codePostalController.dispose();
// // // //     communeController.dispose();
// // // //     streetController.dispose();
// // // //     streetNumberController.dispose();
// // // //     postalBoxController.dispose();
// // // //     phoneController.dispose();
// // // //     socialNameController.dispose();
// // // //     birthDateController.dispose();
// // // //     super.dispose();
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       body: SafeArea(
// // // //         child: CustomScrollView(
// // // //           slivers: [
// // // //             _buildAppBar(),
// // // //             SliverToBoxAdapter(
// // // //               child: Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // //                 child: Form(
// // // //                   key: _formKey,
// // // //                   child: Column(
// // // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // // //                     children: [
// // // //                       _buildProfilePhoto(),
// // // //                       const SizedBox(height: 16),
// // // //                       _buildRoleSelector(),
// // // //                       const SizedBox(height: 24),
// // // //                       _buildStepIndicator(),
// // // //                       const SizedBox(height: 20),
// // // //                       _buildCurrentStep(),
// // // //                       const SizedBox(height: 20),
// // // //                       _buildNavigationButtons(),
// // // //                       const SizedBox(height: 40),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // En-tête de l'application avec une apparence moderne
// // // //   Widget _buildAppBar() {
// // // //     return SliverAppBar(
// // // //       expandedHeight: 120,
// // // //       floating: true,
// // // //       pinned: true,
// // // //       flexibleSpace: FlexibleSpaceBar(
// // // //         title: Text(
// // // //           "Créer votre profil",
// // // //           style: TextStyle(
// // // //             color: Colors.white,
// // // //             fontWeight: FontWeight.bold,
// // // //           ),
// // // //         ),
// // // //         background: Container(
// // // //           decoration: BoxDecoration(
// // // //             gradient: LinearGradient(
// // // //               begin: Alignment.topLeft,
// // // //               end: Alignment.bottomRight,
// // // //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Widget pour l'affichage et la sélection de la photo de profil
// // // //   Widget _buildProfilePhoto() {
// // // //     return Center(
// // // //       child: Column(
// // // //         children: [
// // // //           const SizedBox(height: 20),
// // // //           GestureDetector(
// // // //             onTap: _pickPhoto,
// // // //             child: Stack(
// // // //               alignment: Alignment.bottomRight,
// // // //               children: [
// // // //                 Container(
// // // //                   width: 120,
// // // //                   height: 120,
// // // //                   decoration: BoxDecoration(
// // // //                     color: Colors.grey[200],
// // // //                     shape: BoxShape.circle,
// // // //                     boxShadow: [
// // // //                       BoxShadow(
// // // //                         color: Colors.black.withOpacity(0.1),
// // // //                         blurRadius: 10,
// // // //                         spreadRadius: 1,
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   child: ClipOval(
// // // //                     child: profilePhotoBytes != null
// // // //                         ? Image.memory(
// // // //                       profilePhotoBytes!,
// // // //                       fit: BoxFit.cover,
// // // //                     )
// // // //                         : profilePhoto != null
// // // //                         ? Image.file(
// // // //                       profilePhoto!,
// // // //                       fit: BoxFit.cover,
// // // //                     )
// // // //                         : Icon(
// // // //                       Icons.person,
// // // //                       size: 70,
// // // //                       color: Colors.grey[400],
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //                 Container(
// // // //                   padding: const EdgeInsets.all(8),
// // // //                   decoration: BoxDecoration(
// // // //                     color: secondaryColor,
// // // //                     shape: BoxShape.circle,
// // // //                   ),
// // // //                   child: const Icon(
// // // //                     Icons.camera_alt,
// // // //                     color: Colors.white,
// // // //                     size: 20,
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //           const SizedBox(height: 8),
// // // //           Text(
// // // //             "Photo de profil",
// // // //             style: TextStyle(
// // // //               color: Colors.grey[600],
// // // //               fontSize: 14,
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Sélecteur de rôle avec design moderne
// // // //   Widget _buildRoleSelector() {
// // // //     return Container(
// // // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.white,
// // // //         borderRadius: BorderRadius.circular(16),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.05),
// // // //             blurRadius: 10,
// // // //             spreadRadius: 1,
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Row(
// // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //         children: [
// // // //           const Text(
// // // //             "Je suis :",
// // // //             style: TextStyle(
// // // //               fontWeight: FontWeight.bold,
// // // //               fontSize: 16,
// // // //             ),
// // // //           ),
// // // //           Row(
// // // //             children: [
// // // //               Text(
// // // //                 "Client",
// // // //                 style: TextStyle(
// // // //                   color: !isCoiffeuse ? primaryColor : Colors.grey,
// // // //                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // //                 ),
// // // //               ),
// // // //               Switch(
// // // //                 value: isCoiffeuse,
// // // //                 onChanged: (value) {
// // // //                   setState(() {
// // // //                     isCoiffeuse = value;
// // // //                   });
// // // //                 },
// // // //                 activeColor: secondaryColor,
// // // //                 activeTrackColor: secondaryColor.withOpacity(0.5),
// // // //               ),
// // // //               Text(
// // // //                 "Coiffeuse",
// // // //                 style: TextStyle(
// // // //                   color: isCoiffeuse ? primaryColor : Colors.grey,
// // // //                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Indicateur de progression des étapes
// // // //   Widget _buildStepIndicator() {
// // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // //     return Padding(
// // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //       child: Row(
// // // //         children: List.generate(totalSteps, (index) {
// // // //           return Expanded(
// // // //             child: Container(
// // // //               height: 4,
// // // //               margin: const EdgeInsets.symmetric(horizontal: 4),
// // // //               decoration: BoxDecoration(
// // // //                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
// // // //                 borderRadius: BorderRadius.circular(2),
// // // //               ),
// // // //             ),
// // // //           );
// // // //         }),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Affiche l'étape actuelle selon _currentStep
// // // //   Widget _buildCurrentStep() {
// // // //     switch (_currentStep) {
// // // //       case 0:
// // // //         return _buildPersonalInfoStep();
// // // //       case 1:
// // // //         return _buildAddressStep();
// // // //       case 2:
// // // //         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
// // // //       default:
// // // //         return _buildPersonalInfoStep();
// // // //     }
// // // //   }
// // // //
// // // //   // Étape 1 : Informations personnelles
// // // //   Widget _buildPersonalInfoStep() {
// // // //     return Column(
// // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //       children: [
// // // //         Text(
// // // //           "Informations personnelles",
// // // //           style: TextStyle(
// // // //             fontSize: 20,
// // // //             fontWeight: FontWeight.bold,
// // // //             color: primaryColor,
// // // //           ),
// // // //         ),
// // // //         const SizedBox(height: 20),
// // // //         _buildInputField(
// // // //           label: "Nom",
// // // //           controller: nameController,
// // // //           icon: Icons.person_outline,
// // // //           validator: (value) {
// // // //             if (value == null || value.isEmpty) {
// // // //               return 'Veuillez entrer votre nom';
// // // //             }
// // // //             return null;
// // // //           },
// // // //         ),
// // // //         const SizedBox(height: 16),
// // // //         _buildInputField(
// // // //           label: "Prénom",
// // // //           controller: surnameController,
// // // //           icon: Icons.person_outline,
// // // //           validator: (value) {
// // // //             if (value == null || value.isEmpty) {
// // // //               return 'Veuillez entrer votre prénom';
// // // //             }
// // // //             return null;
// // // //           },
// // // //         ),
// // // //         const SizedBox(height: 16),
// // // //         _buildGenderDropdown(),
// // // //         const SizedBox(height: 16),
// // // //         _buildDatePicker(),
// // // //         const SizedBox(height: 16),
// // // //         _buildInputField(
// // // //           label: "Téléphone",
// // // //           controller: phoneController,
// // // //           icon: Icons.phone,
// // // //           keyboardType: TextInputType.phone,
// // // //           validator: (value) {
// // // //             if (value == null || value.isEmpty) {
// // // //               return 'Veuillez entrer votre numéro de téléphone';
// // // //             }
// // // //             return null;
// // // //           },
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // Étape 2 : Adresse
// // // //   Widget _buildAddressStep() {
// // // //     return Column(
// // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //       children: [
// // // //         Text(
// // // //           "Adresse",
// // // //           style: TextStyle(
// // // //             fontSize: 20,
// // // //             fontWeight: FontWeight.bold,
// // // //             color: primaryColor,
// // // //           ),
// // // //         ),
// // // //         const SizedBox(height: 20),
// // // //         _buildInputField(
// // // //           label: "Code Postal",
// // // //           controller: codePostalController,
// // // //           icon: Icons.location_on_outlined,
// // // //           keyboardType: TextInputType.number,
// // // //           onChanged: fetchCommune,
// // // //           validator: (value) {
// // // //             if (value == null || value.isEmpty) {
// // // //               return 'Veuillez entrer votre code postal';
// // // //             }
// // // //             return null;
// // // //           },
// // // //         ),
// // // //         const SizedBox(height: 16),
// // // //         _buildInputField(
// // // //           label: "Commune",
// // // //           controller: communeController,
// // // //           icon: Icons.location_city,
// // // //           readOnly: true,
// // // //         ),
// // // //         const SizedBox(height: 16),
// // // //         _buildInputField(
// // // //           label: "Rue",
// // // //           controller: streetController,
// // // //           icon: Icons.streetview,
// // // //           validator: (value) {
// // // //             if (value == null || value.isEmpty) {
// // // //               return 'Veuillez entrer votre rue';
// // // //             }
// // // //             return null;
// // // //           },
// // // //         ),
// // // //         const SizedBox(height: 16),
// // // //         Row(
// // // //           children: [
// // // //             Expanded(
// // // //               child: _buildInputField(
// // // //                 label: "Numéro",
// // // //                 controller: streetNumberController,
// // // //                 icon: Icons.home,
// // // //                 validator: (value) {
// // // //                   if (value == null || value.isEmpty) {
// // // //                     return 'Obligatoire';
// // // //                   }
// // // //                   return null;
// // // //                 },
// // // //               ),
// // // //             ),
// // // //             const SizedBox(width: 16),
// // // //             Expanded(
// // // //               child: _buildInputField(
// // // //                 label: "Boîte",
// // // //                 controller: postalBoxController,
// // // //                 icon: Icons.inbox,
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // Étape 3 : Informations professionnelles (pour les coiffeuses)
// // // //   Widget _buildProfessionalInfoStep() {
// // // //     return Column(
// // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //       children: [
// // // //         Text(
// // // //           "Informations professionnelles",
// // // //           style: TextStyle(
// // // //             fontSize: 20,
// // // //             fontWeight: FontWeight.bold,
// // // //             color: primaryColor,
// // // //           ),
// // // //         ),
// // // //         const SizedBox(height: 20),
// // // //         _buildInputField(
// // // //           label: "Nom Commercial",
// // // //           controller: socialNameController,
// // // //           icon: Icons.business,
// // // //           validator: (value) {
// // // //             if (value == null || value.isEmpty) {
// // // //               return 'Veuillez entrer votre nom commercial';
// // // //             }
// // // //             return null;
// // // //           },
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // Input field stylisé avec validation
// // // //   Widget _buildInputField({
// // // //     required String label,
// // // //     required TextEditingController controller,
// // // //     required IconData icon,
// // // //     bool readOnly = false,
// // // //     TextInputType keyboardType = TextInputType.text,
// // // //     Function(String)? onChanged,
// // // //     String? Function(String?)? validator,
// // // //   }) {
// // // //     return TextFormField(
// // // //       controller: controller,
// // // //       readOnly: readOnly,
// // // //       keyboardType: keyboardType,
// // // //       onChanged: onChanged,
// // // //       validator: validator,
// // // //       decoration: InputDecoration(
// // // //         labelText: label,
// // // //         prefixIcon: Icon(icon, color: primaryColor),
// // // //         border: OutlineInputBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // //         ),
// // // //         enabledBorder: OutlineInputBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // //         ),
// // // //         focusedBorder: OutlineInputBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // //         ),
// // // //         filled: true,
// // // //         fillColor: Colors.white,
// // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Dropdown stylisé pour le genre
// // // //   Widget _buildGenderDropdown() {
// // // //     return DropdownButtonFormField<String>(
// // // //       value: selectedGender,
// // // //       decoration: InputDecoration(
// // // //         labelText: "Sexe",
// // // //         prefixIcon: Icon(Icons.person, color: primaryColor),
// // // //         border: OutlineInputBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // //         ),
// // // //         enabledBorder: OutlineInputBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // //         ),
// // // //         focusedBorder: OutlineInputBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // //         ),
// // // //         filled: true,
// // // //         fillColor: Colors.white,
// // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // //       ),
// // // //       items: genderOptions
// // // //           .map((gender) => DropdownMenuItem(
// // // //         value: gender,
// // // //         child: Text(gender),
// // // //       ))
// // // //           .toList(),
// // // //       onChanged: (value) {
// // // //         setState(() {
// // // //           selectedGender = value;
// // // //         });
// // // //       },
// // // //       validator: (value) {
// // // //         if (value == null || value.isEmpty) {
// // // //           return 'Veuillez sélectionner votre genre';
// // // //         }
// // // //         return null;
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // Date picker stylisé
// // // //   Widget _buildDatePicker() {
// // // //     return GestureDetector(
// // // //       onTap: () async {
// // // //         final selectedDate = await showDatePicker(
// // // //           context: context,
// // // //           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
// // // //           firstDate: DateTime(1900),
// // // //           lastDate: DateTime.now(),
// // // //           builder: (context, child) {
// // // //             return Theme(
// // // //               data: Theme.of(context).copyWith(
// // // //                 colorScheme: ColorScheme.light(
// // // //                   primary: primaryColor,
// // // //                   onPrimary: Colors.white,
// // // //                   onSurface: Colors.black,
// // // //                 ),
// // // //               ),
// // // //               child: child!,
// // // //             );
// // // //           },
// // // //         );
// // // //         if (selectedDate != null) {
// // // //           setState(() {
// // // //             birthDateController.text =
// // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // //                 "${selectedDate.year}";
// // // //           });
// // // //         }
// // // //       },
// // // //       child: AbsorbPointer(
// // // //         child: TextFormField(
// // // //           controller: birthDateController,
// // // //           decoration: InputDecoration(
// // // //             labelText: "Date de naissance",
// // // //             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
// // // //             border: OutlineInputBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // //             ),
// // // //             enabledBorder: OutlineInputBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // //             ),
// // // //             focusedBorder: OutlineInputBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               borderSide: BorderSide(color: primaryColor, width: 2),
// // // //             ),
// // // //             filled: true,
// // // //             fillColor: Colors.white,
// // // //             contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // //           ),
// // // //           validator: (value) {
// // // //             if (value == null || value.isEmpty) {
// // // //               return 'Veuillez entrer votre date de naissance';
// // // //             }
// // // //             if (!_isValidDate(value)) {
// // // //               return 'Format invalide (JJ-MM-AAAA)';
// // // //             }
// // // //             return null;
// // // //           },
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Boutons de navigation
// // // //   Widget _buildNavigationButtons() {
// // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // //     return Row(
// // // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //       children: [
// // // //         _currentStep > 0
// // // //             ? ElevatedButton.icon(
// // // //           icon: const Icon(Icons.arrow_back),
// // // //           label: const Text("Précédent"),
// // // //           onPressed: () {
// // // //             setState(() {
// // // //               _currentStep--;
// // // //             });
// // // //           },
// // // //           style: ElevatedButton.styleFrom(
// // // //             backgroundColor: Colors.grey[200],
// // // //             foregroundColor: Colors.black87,
// // // //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //             ),
// // // //           ),
// // // //         )
// // // //             : const SizedBox(width: 120),
// // // //         _currentStep < totalSteps - 1
// // // //             ? ElevatedButton.icon(
// // // //           icon: const Icon(Icons.arrow_forward),
// // // //           label: const Text("Suivant"),
// // // //           onPressed: () {
// // // //             if (_validateCurrentStep()) {
// // // //               setState(() {
// // // //                 _currentStep++;
// // // //               });
// // // //             }
// // // //           },
// // // //           style: ElevatedButton.styleFrom(
// // // //             backgroundColor: primaryColor,
// // // //             foregroundColor: Colors.white,
// // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //             ),
// // // //           ),
// // // //         )
// // // //             : ElevatedButton.icon(
// // // //           icon: const Icon(Icons.check),
// // // //           label: const Text("Enregistrer"),
// // // //           onPressed: () {
// // // //             if (_validateCurrentStep()) {
// // // //               _saveProfile();
// // // //             }
// // // //           },
// // // //           style: ElevatedButton.styleFrom(
// // // //             backgroundColor: secondaryColor,
// // // //             foregroundColor: Colors.white,
// // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // Validation de l'étape actuelle
// // // //   bool _validateCurrentStep() {
// // // //     return _formKey.currentState?.validate() ?? false;
// // // //   }
// // // //
// // // //   // Méthode pour sélectionner une photo
// // // //   Future<void> _pickPhoto() async {
// // // //     try {
// // // //       final result = await FilePicker.platform.pickFiles(
// // // //         type: FileType.image,
// // // //         allowMultiple: false,
// // // //       );
// // // //
// // // //       if (result != null) {
// // // //         setState(() {
// // // //           if (kIsWeb) {
// // // //             profilePhotoBytes = result.files.first.bytes;
// // // //             profilePhoto = null;
// // // //           } else {
// // // //             profilePhoto = File(result.files.first.path!);
// // // //             profilePhotoBytes = null;
// // // //           }
// // // //         });
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text("Erreur lors de la sélection de la photo: $e"),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // Validation du format de la date
// // // //   bool _isValidDate(String date) {
// // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // //     if (!regex.hasMatch(date)) return false;
// // // //
// // // //     try {
// // // //       final parts = date.split('-');
// // // //       final day = int.parse(parts[0]);
// // // //       final month = int.parse(parts[1]);
// // // //       final year = int.parse(parts[2]);
// // // //       final parsedDate = DateTime(year, month, day);
// // // //       return parsedDate.year == year &&
// // // //           parsedDate.month == month &&
// // // //           parsedDate.day == day;
// // // //     } catch (e) {
// // // //       return false;
// // // //     }
// // // //   }
// // // //
// // // //   // Méthode pour récupérer la commune depuis le Code Postal
// // // //   Future<void> fetchCommune(String codePostal) async {
// // // //     if (codePostal.length < 4) return;
// // // //
// // // //     final url = Uri.parse(
// // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // //
// // // //     try {
// // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // //       if (response.statusCode == 200) {
// // // //         final data = json.decode(response.body) as List;
// // // //         if (data.isNotEmpty) {
// // // //           final addressDetailsUrl = Uri.parse(
// // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // //           final addressResponse = await http.get(addressDetailsUrl,
// // // //               headers: {'User-Agent': 'FlutterApp/1.0'});
// // // //           if (addressResponse.statusCode == 200) {
// // // //             final addressData = json.decode(addressResponse.body);
// // // //             if (mounted) {
// // // //               setState(() {
// // // //                 communeController.text = addressData['address']['city'] ??
// // // //                     addressData['address']['town'] ??
// // // //                     addressData['address']['village'] ??
// // // //                     "Commune introuvable";
// // // //               });
// // // //             }
// // // //           }
// // // //         }
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint("Erreur commune : $e");
// // // //     }
// // // //   }
// // // //
// // // //   // Créer le modèle utilisateur à partir des données du formulaire
// // // //   UserCreationModel _createUserModel() {
// // // //     return UserCreationModel.fromForm(
// // // //       userUuid: userUuid,
// // // //       email: userEmail,
// // // //       isCoiffeuse: isCoiffeuse,
// // // //       nom: nameController.text,
// // // //       prenom: surnameController.text,
// // // //       sexe: selectedGender ?? "",
// // // //       telephone: phoneController.text,
// // // //       dateNaissance: birthDateController.text,
// // // //       codePostal: codePostalController.text,
// // // //       commune: communeController.text,
// // // //       rue: streetController.text,
// // // //       numero: streetNumberController.text,
// // // //       boitePostale: postalBoxController.text.isNotEmpty ? postalBoxController.text : null,
// // // //       nomCommercial: isCoiffeuse ? socialNameController.text : null,
// // // //       photoProfilFile: profilePhoto,
// // // //       photoProfilBytes: profilePhotoBytes,
// // // //       photoProfilName: 'profile_photo.png',
// // // //     );
// // // //   }
// // // //
// // // //   // Sauvegarde du profil avec le nouveau système
// // // //   void _saveProfile() async {
// // // //     // Afficher un indicateur de chargement
// // // //     showDialog(
// // // //       context: context,
// // // //       barrierDismissible: false,
// // // //       builder: (context) => Center(
// // // //         child: CircularProgressIndicator(
// // // //           color: primaryColor,
// // // //         ),
// // // //       ),
// // // //     );
// // // //
// // // //     try {
// // // //       // Créer le modèle utilisateur
// // // //       final userModel = _createUserModel();
// // // //
// // // //       // Récupérer le token Firebase via TokenService
// // // //       String? firebaseToken;
// // // //       try {
// // // //         firebaseToken = await TokenService.getAuthToken();
// // // //         if (kDebugMode) {
// // // //           print("🔍 Token Firebase récupéré: ${firebaseToken != null ? 'Oui' : 'Non'}");
// // // //         }
// // // //       } catch (e) {
// // // //         if (kDebugMode) {
// // // //           print("❌ Erreur récupération token Firebase: $e");
// // // //         }
// // // //       }
// // // //
// // // //       // Appeler l'API via le service
// // // //       final response = await ProfileApiService.createUserProfile(
// // // //         userModel: userModel,
// // // //         firebaseToken: firebaseToken,
// // // //       );
// // // //
// // // //       // Fermer la boîte de dialogue de chargement
// // // //       if (mounted) Navigator.of(context).pop();
// // // //
// // // //       if (!mounted) return;
// // // //
// // // //       if (response.success) {
// // // //         // Animation de succès
// // // //         _showSuccessDialog();
// // // //
// // // //         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // // //         await userProvider.fetchCurrentUser();
// // // //
// // // //         if (!mounted) return;
// // // //
// // // //         if (isCoiffeuse) {
// // // //           // Redirection vers la création de salon pour les coiffeuses
// // // //           if (userProvider.currentUser != null) {
// // // //             Navigator.push(
// // // //               context,
// // // //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// // // //             );
// // // //           }
// // // //         } else {
// // // //           // Redirection vers la page d'accueil pour les clients
// // // //           Navigator.pushReplacement(
// // // //             context,
// // // //             MaterialPageRoute(builder: (_) => const HomePage()),
// // // //           );
// // // //         }
// // // //       } else {
// // // //         // Gestion des erreurs
// // // //         String errorMessage = response.message;
// // // //
// // // //         if (response.isAuthError) {
// // // //           errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
// // // //           // Optionnel: Nettoyer le token en cas d'erreur d'auth
// // // //           await TokenService.clearAuthToken();
// // // //         } else if (response.isValidationError && response.validationErrors != null) {
// // // //           // Afficher les erreurs de validation
// // // //           errorMessage = response.validationErrors!.values.join('\n');
// // // //         }
// // // //
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text(errorMessage),
// // // //             backgroundColor: Colors.red,
// // // //             duration: const Duration(seconds: 4),
// // // //           ),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         // Fermer la boîte de dialogue de chargement
// // // //         Navigator.of(context).pop();
// // // //
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text("Erreur inattendue: $e"),
// // // //             backgroundColor: Colors.red,
// // // //           ),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // Animation de succès
// // // //   void _showSuccessDialog() {
// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (context) => AlertDialog(
// // // //         shape: RoundedRectangleBorder(
// // // //           borderRadius: BorderRadius.circular(20),
// // // //         ),
// // // //         title: Row(
// // // //           children: [
// // // //             Icon(Icons.check_circle, color: Colors.green, size: 30),
// // // //             const SizedBox(width: 10),
// // // //             const Text("Profil créé !"),
// // // //           ],
// // // //         ),
// // // //         content: const Text(
// // // //           "Votre profil a été créé avec succès.",
// // // //           textAlign: TextAlign.center,
// // // //         ),
// // // //         actions: [
// // // //           TextButton(
// // // //             onPressed: () => Navigator.pop(context),
// // // //             child: Text(
// // // //               "Continuer",
// // // //               style: TextStyle(color: primaryColor),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // // // import 'dart:convert';
// // // // // import 'dart:io';
// // // // // import 'package:flutter/foundation.dart';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:hairbnb/pages/profil/services/profile_api_service.dart';
// // // // // import 'package:http/http.dart' as http;
// // // // // import 'package:file_picker/file_picker.dart';
// // // // // import 'package:provider/provider.dart';
// // // // // import '../../services/firebase_token/token_service.dart';
// // // // // import '../../services/providers/current_user_provider.dart';
// // // // // import '../home_page.dart';
// // // // // import '../salon/create_salon_page.dart';
// // // // // import '../../models/user_creation.dart';
// // // // //
// // // // // class ProfileCreationPage extends StatefulWidget {
// // // // //   final String userUuid;
// // // // //   final String email;
// // // // //
// // // // //   const ProfileCreationPage({
// // // // //     required this.userUuid,
// // // // //     required this.email,
// // // // //     super.key,
// // // // //   });
// // // // //
// // // // //   @override
// // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // }
// // // // //
// // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // //   // Variables pour le thème
// // // // //   final Color primaryColor = const Color(0xFF8E44AD);
// // // // //   final Color secondaryColor = const Color(0xFFF39C12);
// // // // //
// // // // //   // Variables de l'état
// // // // //   String? selectedGender;
// // // // //   final List<String> genderOptions = ["Homme", "Femme"];
// // // // //   Uint8List? profilePhotoBytes;
// // // // //   File? profilePhoto;
// // // // //   bool isCoiffeuse = false;
// // // // //   late String userEmail;
// // // // //   late String userUuid;
// // // // //   int _currentStep = 0;
// // // // //
// // // // //   // Variable pour stocker le modèle utilisateur
// // // // //
// // // // //   // Controllers
// // // // //   final TextEditingController nameController = TextEditingController();
// // // // //   final TextEditingController surnameController = TextEditingController();
// // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // //   final TextEditingController communeController = TextEditingController();
// // // // //   final TextEditingController streetController = TextEditingController();
// // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // //   final TextEditingController phoneController = TextEditingController();
// // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // //   final TextEditingController birthDateController = TextEditingController();
// // // // //
// // // // //   // Form keys pour validation
// // // // //   final _formKey = GlobalKey<FormState>();
// // // // //
// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     userEmail = widget.email;
// // // // //     userUuid = widget.userUuid;
// // // // //   }
// // // // //
// // // // //   @override
// // // // //   void dispose() {
// // // // //     // Libérer les contrôleurs
// // // // //     nameController.dispose();
// // // // //     surnameController.dispose();
// // // // //     codePostalController.dispose();
// // // // //     communeController.dispose();
// // // // //     streetController.dispose();
// // // // //     streetNumberController.dispose();
// // // // //     postalBoxController.dispose();
// // // // //     phoneController.dispose();
// // // // //     socialNameController.dispose();
// // // // //     birthDateController.dispose();
// // // // //     super.dispose();
// // // // //   }
// // // // //
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       body: SafeArea(
// // // // //         child: CustomScrollView(
// // // // //           slivers: [
// // // // //             _buildAppBar(),
// // // // //             SliverToBoxAdapter(
// // // // //               child: Padding(
// // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // // //                 child: Form(
// // // // //                   key: _formKey,
// // // // //                   child: Column(
// // // // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //                     children: [
// // // // //                       _buildProfilePhoto(),
// // // // //                       const SizedBox(height: 16),
// // // // //                       _buildRoleSelector(),
// // // // //                       const SizedBox(height: 24),
// // // // //                       _buildStepIndicator(),
// // // // //                       const SizedBox(height: 20),
// // // // //                       _buildCurrentStep(),
// // // // //                       const SizedBox(height: 20),
// // // // //                       _buildNavigationButtons(),
// // // // //                       const SizedBox(height: 40),
// // // // //                     ],
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // En-tête de l'application avec une apparence moderne
// // // // //   Widget _buildAppBar() {
// // // // //     return SliverAppBar(
// // // // //       expandedHeight: 120,
// // // // //       floating: true,
// // // // //       pinned: true,
// // // // //       flexibleSpace: FlexibleSpaceBar(
// // // // //         title: Text(
// // // // //           "Créer votre profil",
// // // // //           style: TextStyle(
// // // // //             color: Colors.white,
// // // // //             fontWeight: FontWeight.bold,
// // // // //           ),
// // // // //         ),
// // // // //         background: Container(
// // // // //           decoration: BoxDecoration(
// // // // //             gradient: LinearGradient(
// // // // //               begin: Alignment.topLeft,
// // // // //               end: Alignment.bottomRight,
// // // // //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Widget pour l'affichage et la sélection de la photo de profil
// // // // //   Widget _buildProfilePhoto() {
// // // // //     return Center(
// // // // //       child: Column(
// // // // //         children: [
// // // // //           const SizedBox(height: 20),
// // // // //           GestureDetector(
// // // // //             onTap: _pickPhoto,
// // // // //             child: Stack(
// // // // //               alignment: Alignment.bottomRight,
// // // // //               children: [
// // // // //                 Container(
// // // // //                   width: 120,
// // // // //                   height: 120,
// // // // //                   decoration: BoxDecoration(
// // // // //                     color: Colors.grey[200],
// // // // //                     shape: BoxShape.circle,
// // // // //                     boxShadow: [
// // // // //                       BoxShadow(
// // // // //                         color: Colors.black.withOpacity(0.1),
// // // // //                         blurRadius: 10,
// // // // //                         spreadRadius: 1,
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   child: ClipOval(
// // // // //                     child: profilePhotoBytes != null
// // // // //                         ? Image.memory(
// // // // //                       profilePhotoBytes!,
// // // // //                       fit: BoxFit.cover,
// // // // //                     )
// // // // //                         : profilePhoto != null
// // // // //                         ? Image.file(
// // // // //                       profilePhoto!,
// // // // //                       fit: BoxFit.cover,
// // // // //                     )
// // // // //                         : Icon(
// // // // //                       Icons.person,
// // // // //                       size: 70,
// // // // //                       color: Colors.grey[400],
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //                 Container(
// // // // //                   padding: const EdgeInsets.all(8),
// // // // //                   decoration: BoxDecoration(
// // // // //                     color: secondaryColor,
// // // // //                     shape: BoxShape.circle,
// // // // //                   ),
// // // // //                   child: const Icon(
// // // // //                     Icons.camera_alt,
// // // // //                     color: Colors.white,
// // // // //                     size: 20,
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //           const SizedBox(height: 8),
// // // // //           Text(
// // // // //             "Photo de profil",
// // // // //             style: TextStyle(
// // // // //               color: Colors.grey[600],
// // // // //               fontSize: 14,
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Sélecteur de rôle avec design moderne
// // // // //   Widget _buildRoleSelector() {
// // // // //     return Container(
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // //       decoration: BoxDecoration(
// // // // //         color: Colors.white,
// // // // //         borderRadius: BorderRadius.circular(16),
// // // // //         boxShadow: [
// // // // //           BoxShadow(
// // // // //             color: Colors.black.withOpacity(0.05),
// // // // //             blurRadius: 10,
// // // // //             spreadRadius: 1,
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //       child: Row(
// // // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //         children: [
// // // // //           const Text(
// // // // //             "Je suis :",
// // // // //             style: TextStyle(
// // // // //               fontWeight: FontWeight.bold,
// // // // //               fontSize: 16,
// // // // //             ),
// // // // //           ),
// // // // //           Row(
// // // // //             children: [
// // // // //               Text(
// // // // //                 "Client",
// // // // //                 style: TextStyle(
// // // // //                   color: !isCoiffeuse ? primaryColor : Colors.grey,
// // // // //                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // //                 ),
// // // // //               ),
// // // // //               Switch(
// // // // //                 value: isCoiffeuse,
// // // // //                 onChanged: (value) {
// // // // //                   setState(() {
// // // // //                     isCoiffeuse = value;
// // // // //                   });
// // // // //                 },
// // // // //                 activeColor: secondaryColor,
// // // // //                 activeTrackColor: secondaryColor.withOpacity(0.5),
// // // // //               ),
// // // // //               Text(
// // // // //                 "Coiffeuse",
// // // // //                 style: TextStyle(
// // // // //                   color: isCoiffeuse ? primaryColor : Colors.grey,
// // // // //                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Indicateur de progression des étapes
// // // // //   Widget _buildStepIndicator() {
// // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // //       child: Row(
// // // // //         children: List.generate(totalSteps, (index) {
// // // // //           return Expanded(
// // // // //             child: Container(
// // // // //               height: 4,
// // // // //               margin: const EdgeInsets.symmetric(horizontal: 4),
// // // // //               decoration: BoxDecoration(
// // // // //                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
// // // // //                 borderRadius: BorderRadius.circular(2),
// // // // //               ),
// // // // //             ),
// // // // //           );
// // // // //         }),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Affiche l'étape actuelle selon _currentStep
// // // // //   Widget _buildCurrentStep() {
// // // // //     switch (_currentStep) {
// // // // //       case 0:
// // // // //         return _buildPersonalInfoStep();
// // // // //       case 1:
// // // // //         return _buildAddressStep();
// // // // //       case 2:
// // // // //         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
// // // // //       default:
// // // // //         return _buildPersonalInfoStep();
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Étape 1 : Informations personnelles
// // // // //   Widget _buildPersonalInfoStep() {
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Text(
// // // // //           "Informations personnelles",
// // // // //           style: TextStyle(
// // // // //             fontSize: 20,
// // // // //             fontWeight: FontWeight.bold,
// // // // //             color: primaryColor,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 20),
// // // // //         _buildInputField(
// // // // //           label: "Nom",
// // // // //           controller: nameController,
// // // // //           icon: Icons.person_outline,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre nom';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Prénom",
// // // // //           controller: surnameController,
// // // // //           icon: Icons.person_outline,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre prénom';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildGenderDropdown(),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildDatePicker(),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Téléphone",
// // // // //           controller: phoneController,
// // // // //           icon: Icons.phone,
// // // // //           keyboardType: TextInputType.phone,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre numéro de téléphone';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Étape 2 : Adresse
// // // // //   Widget _buildAddressStep() {
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Text(
// // // // //           "Adresse",
// // // // //           style: TextStyle(
// // // // //             fontSize: 20,
// // // // //             fontWeight: FontWeight.bold,
// // // // //             color: primaryColor,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 20),
// // // // //         _buildInputField(
// // // // //           label: "Code Postal",
// // // // //           controller: codePostalController,
// // // // //           icon: Icons.location_on_outlined,
// // // // //           keyboardType: TextInputType.number,
// // // // //           onChanged: fetchCommune,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre code postal';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Commune",
// // // // //           controller: communeController,
// // // // //           icon: Icons.location_city,
// // // // //           readOnly: true,
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Rue",
// // // // //           controller: streetController,
// // // // //           icon: Icons.streetview,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre rue';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         Row(
// // // // //           children: [
// // // // //             Expanded(
// // // // //               child: _buildInputField(
// // // // //                 label: "Numéro",
// // // // //                 controller: streetNumberController,
// // // // //                 icon: Icons.home,
// // // // //                 validator: (value) {
// // // // //                   if (value == null || value.isEmpty) {
// // // // //                     return 'Obligatoire';
// // // // //                   }
// // // // //                   return null;
// // // // //                 },
// // // // //               ),
// // // // //             ),
// // // // //             const SizedBox(width: 16),
// // // // //             Expanded(
// // // // //               child: _buildInputField(
// // // // //                 label: "Boîte",
// // // // //                 controller: postalBoxController,
// // // // //                 icon: Icons.inbox,
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Étape 3 : Informations professionnelles (pour les coiffeuses)
// // // // //   Widget _buildProfessionalInfoStep() {
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Text(
// // // // //           "Informations professionnelles",
// // // // //           style: TextStyle(
// // // // //             fontSize: 20,
// // // // //             fontWeight: FontWeight.bold,
// // // // //             color: primaryColor,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 20),
// // // // //         _buildInputField(
// // // // //           label: "Nom Commercial",
// // // // //           controller: socialNameController,
// // // // //           icon: Icons.business,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre nom commercial';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Input field stylisé avec validation
// // // // //   Widget _buildInputField({
// // // // //     required String label,
// // // // //     required TextEditingController controller,
// // // // //     required IconData icon,
// // // // //     bool readOnly = false,
// // // // //     TextInputType keyboardType = TextInputType.text,
// // // // //     Function(String)? onChanged,
// // // // //     String? Function(String?)? validator,
// // // // //   }) {
// // // // //     return TextFormField(
// // // // //       controller: controller,
// // // // //       readOnly: readOnly,
// // // // //       keyboardType: keyboardType,
// // // // //       onChanged: onChanged,
// // // // //       validator: validator,
// // // // //       decoration: InputDecoration(
// // // // //         labelText: label,
// // // // //         prefixIcon: Icon(icon, color: primaryColor),
// // // // //         border: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         enabledBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         focusedBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // //         ),
// // // // //         filled: true,
// // // // //         fillColor: Colors.white,
// // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Dropdown stylisé pour le genre
// // // // //   Widget _buildGenderDropdown() {
// // // // //     return DropdownButtonFormField<String>(
// // // // //       value: selectedGender,
// // // // //       decoration: InputDecoration(
// // // // //         labelText: "Sexe",
// // // // //         prefixIcon: Icon(Icons.person, color: primaryColor),
// // // // //         border: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         enabledBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         focusedBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // //         ),
// // // // //         filled: true,
// // // // //         fillColor: Colors.white,
// // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // //       ),
// // // // //       items: genderOptions
// // // // //           .map((gender) => DropdownMenuItem(
// // // // //         value: gender,
// // // // //         child: Text(gender),
// // // // //       ))
// // // // //           .toList(),
// // // // //       onChanged: (value) {
// // // // //         setState(() {
// // // // //           selectedGender = value;
// // // // //         });
// // // // //       },
// // // // //       validator: (value) {
// // // // //         if (value == null || value.isEmpty) {
// // // // //           return 'Veuillez sélectionner votre genre';
// // // // //         }
// // // // //         return null;
// // // // //       },
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Date picker stylisé
// // // // //   Widget _buildDatePicker() {
// // // // //     return GestureDetector(
// // // // //       onTap: () async {
// // // // //         final selectedDate = await showDatePicker(
// // // // //           context: context,
// // // // //           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
// // // // //           firstDate: DateTime(1900),
// // // // //           lastDate: DateTime.now(),
// // // // //           builder: (context, child) {
// // // // //             return Theme(
// // // // //               data: Theme.of(context).copyWith(
// // // // //                 colorScheme: ColorScheme.light(
// // // // //                   primary: primaryColor,
// // // // //                   onPrimary: Colors.white,
// // // // //                   onSurface: Colors.black,
// // // // //                 ),
// // // // //               ),
// // // // //               child: child!,
// // // // //             );
// // // // //           },
// // // // //         );
// // // // //         if (selectedDate != null) {
// // // // //           setState(() {
// // // // //             birthDateController.text =
// // // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // // //                 "${selectedDate.year}";
// // // // //           });
// // // // //         }
// // // // //       },
// // // // //       child: AbsorbPointer(
// // // // //         child: TextFormField(
// // // // //           controller: birthDateController,
// // // // //           decoration: InputDecoration(
// // // // //             labelText: "Date de naissance",
// // // // //             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
// // // // //             border: OutlineInputBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //             ),
// // // // //             enabledBorder: OutlineInputBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //             ),
// // // // //             focusedBorder: OutlineInputBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               borderSide: BorderSide(color: primaryColor, width: 2),
// // // // //             ),
// // // // //             filled: true,
// // // // //             fillColor: Colors.white,
// // // // //             contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // //           ),
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre date de naissance';
// // // // //             }
// // // // //             if (!_isValidDate(value)) {
// // // // //               return 'Format invalide (JJ-MM-AAAA)';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Boutons de navigation
// // // // //   Widget _buildNavigationButtons() {
// // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // //     return Row(
// // // // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //       children: [
// // // // //         _currentStep > 0
// // // // //             ? ElevatedButton.icon(
// // // // //           icon: const Icon(Icons.arrow_back),
// // // // //           label: const Text("Précédent"),
// // // // //           onPressed: () {
// // // // //             setState(() {
// // // // //               _currentStep--;
// // // // //             });
// // // // //           },
// // // // //           style: ElevatedButton.styleFrom(
// // // // //             backgroundColor: Colors.grey[200],
// // // // //             foregroundColor: Colors.black87,
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // // //             shape: RoundedRectangleBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //             ),
// // // // //           ),
// // // // //         )
// // // // //             : const SizedBox(width: 120),
// // // // //         _currentStep < totalSteps - 1
// // // // //             ? ElevatedButton.icon(
// // // // //           icon: const Icon(Icons.arrow_forward),
// // // // //           label: const Text("Suivant"),
// // // // //           onPressed: () {
// // // // //             if (_validateCurrentStep()) {
// // // // //               setState(() {
// // // // //                 _currentStep++;
// // // // //               });
// // // // //             }
// // // // //           },
// // // // //           style: ElevatedButton.styleFrom(
// // // // //             backgroundColor: primaryColor,
// // // // //             foregroundColor: Colors.white,
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // //             shape: RoundedRectangleBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //             ),
// // // // //           ),
// // // // //         )
// // // // //             : ElevatedButton.icon(
// // // // //           icon: const Icon(Icons.check),
// // // // //           label: const Text("Enregistrer"),
// // // // //           onPressed: () {
// // // // //             if (_validateCurrentStep()) {
// // // // //               _saveProfile();
// // // // //             }
// // // // //           },
// // // // //           style: ElevatedButton.styleFrom(
// // // // //             backgroundColor: secondaryColor,
// // // // //             foregroundColor: Colors.white,
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // //             shape: RoundedRectangleBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Validation de l'étape actuelle
// // // // //   bool _validateCurrentStep() {
// // // // //     return _formKey.currentState?.validate() ?? false;
// // // // //   }
// // // // //
// // // // //   // Méthode pour sélectionner une photo
// // // // //   Future<void> _pickPhoto() async {
// // // // //     try {
// // // // //       final result = await FilePicker.platform.pickFiles(
// // // // //         type: FileType.image,
// // // // //         allowMultiple: false,
// // // // //       );
// // // // //
// // // // //       if (result != null) {
// // // // //         setState(() {
// // // // //           if (kIsWeb) {
// // // // //             profilePhotoBytes = result.files.first.bytes;
// // // // //             profilePhoto = null;
// // // // //           } else {
// // // // //             profilePhoto = File(result.files.first.path!);
// // // // //             profilePhotoBytes = null;
// // // // //           }
// // // // //         });
// // // // //       }
// // // // //     } catch (e) {
// // // // //       if (mounted) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text("Erreur lors de la sélection de la photo: $e"),
// // // // //             backgroundColor: Colors.red,
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Validation du format de la date
// // // // //   bool _isValidDate(String date) {
// // // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // // //         if (!regex.hasMatch(date)) return false;
// // // // //
// // // // //     try {
// // // // //     final parts = date.split('-');
// // // // //     final day = int.parse(parts[0]);
// // // // //     final month = int.parse(parts[1]);
// // // // //     final year = int.parse(parts[2]);
// // // // //     final parsedDate = DateTime(year, month, day);
// // // // //     return parsedDate.year == year &&
// // // // //     parsedDate.month == month &&
// // // // //     parsedDate.day == day;
// // // // //     } catch (e) {
// // // // //     return false;
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Méthode pour récupérer la commune depuis le Code Postal
// // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // //     if (codePostal.length < 4) return;
// // // // //
// // // // //     final url = Uri.parse(
// // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // //
// // // // //     try {
// // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // //       if (response.statusCode == 200) {
// // // // //         final data = json.decode(response.body) as List;
// // // // //         if (data.isNotEmpty) {
// // // // //           final addressDetailsUrl = Uri.parse(
// // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // //           final addressResponse = await http.get(addressDetailsUrl,
// // // // //               headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // //           if (addressResponse.statusCode == 200) {
// // // // //             final addressData = json.decode(addressResponse.body);
// // // // //             if (mounted) {
// // // // //               setState(() {
// // // // //                 communeController.text = addressData['address']['city'] ??
// // // // //                     addressData['address']['town'] ??
// // // // //                     addressData['address']['village'] ??
// // // // //                     "Commune introuvable";
// // // // //               });
// // // // //             }
// // // // //           }
// // // // //         }
// // // // //       }
// // // // //     } catch (e) {
// // // // //       debugPrint("Erreur commune : $e");
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Créer le modèle utilisateur à partir des données du formulaire
// // // // //   UserCreationModel _createUserModel() {
// // // // //     return UserCreationModel.fromForm(
// // // // //       userUuid: userUuid,
// // // // //       email: userEmail,
// // // // //       isCoiffeuse: isCoiffeuse,
// // // // //       nom: nameController.text,
// // // // //       prenom: surnameController.text,
// // // // //       sexe: selectedGender ?? "",
// // // // //       telephone: phoneController.text,
// // // // //       dateNaissance: birthDateController.text,
// // // // //       codePostal: codePostalController.text,
// // // // //       commune: communeController.text,
// // // // //       rue: streetController.text,
// // // // //       numero: streetNumberController.text,
// // // // //       boitePostale: postalBoxController.text.isNotEmpty ? postalBoxController.text : null,
// // // // //       nomCommercial: isCoiffeuse ? socialNameController.text : null,
// // // // //       photoProfilFile: profilePhoto,
// // // // //       photoProfilBytes: profilePhotoBytes,
// // // // //       photoProfilName: 'profile_photo.png',
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Sauvegarde du profil avec le nouveau système
// // // // //   void _saveProfile() async {
// // // // //     // Afficher un indicateur de chargement
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       barrierDismissible: false,
// // // // //       builder: (context) => Center(
// // // // //         child: CircularProgressIndicator(
// // // // //           color: primaryColor,
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //
// // // // //     try {
// // // // //       // Créer le modèle utilisateur
// // // // //       final userModel = _createUserModel();
// // // // //
// // // // //       // Récupérer le token Firebase via TokenService
// // // // //       String? firebaseToken;
// // // // //       try {
// // // // //         firebaseToken = await TokenService.getAuthToken();
// // // // //         if (kDebugMode) {
// // // // //           print("🔍 Token Firebase récupéré: ${firebaseToken != null ? 'Oui' : 'Non'}");
// // // // //         }
// // // // //       } catch (e) {
// // // // //         if (kDebugMode) {
// // // // //           print("❌ Erreur récupération token Firebase: $e");
// // // // //         }
// // // // //       }
// // // // //
// // // // //       // Appeler l'API via le service
// // // // //       final response = await ProfileApiService.createUserProfile(
// // // // //         userModel: userModel,
// // // // //         firebaseToken: firebaseToken,
// // // // //       );
// // // // //
// // // // //       // Fermer la boîte de dialogue de chargement
// // // // //       if (mounted) Navigator.of(context).pop();
// // // // //
// // // // //       if (!mounted) return;
// // // // //
// // // // //       if (response.success) {
// // // // //         // Animation de succès
// // // // //         _showSuccessDialog();
// // // // //
// // // // //         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // // // //         await userProvider.fetchCurrentUser();
// // // // //
// // // // //         if (!mounted) return;
// // // // //
// // // // //         if (isCoiffeuse) {
// // // // //           // Redirection vers la création de salon pour les coiffeuses
// // // // //           if (userProvider.currentUser != null) {
// // // // //             Navigator.push(
// // // // //               context,
// // // // //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// // // // //             );
// // // // //           }
// // // // //         } else {
// // // // //           // Redirection vers la page d'accueil pour les clients
// // // // //           Navigator.pushReplacement(
// // // // //             context,
// // // // //             MaterialPageRoute(builder: (_) => const HomePage()),
// // // // //           );
// // // // //         }
// // // // //       } else {
// // // // //         // Gestion des erreurs
// // // // //         String errorMessage = response.message;
// // // // //
// // // // //         if (response.isAuthError) {
// // // // //           errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
// // // // //           // Optionnel: Nettoyer le token en cas d'erreur d'auth
// // // // //           await TokenService.clearAuthToken();
// // // // //         } else if (response.isValidationError && response.validationErrors != null) {
// // // // //           // Afficher les erreurs de validation
// // // // //           errorMessage = response.validationErrors!.values.join('\n');
// // // // //         }
// // // // //
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text(errorMessage),
// // // // //             backgroundColor: Colors.red,
// // // // //             duration: const Duration(seconds: 4),
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     } catch (e) {
// // // // //       if (mounted) {
// // // // //         // Fermer la boîte de dialogue de chargement
// // // // //         Navigator.of(context).pop();
// // // // //
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text("Erreur inattendue: $e"),
// // // // //             backgroundColor: Colors.red,
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Animation de succès
// // // // //   void _showSuccessDialog() {
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       builder: (context) => AlertDialog(
// // // // //         shape: RoundedRectangleBorder(
// // // // //           borderRadius: BorderRadius.circular(20),
// // // // //         ),
// // // // //         title: Row(
// // // // //           children: [
// // // // //             Icon(Icons.check_circle, color: Colors.green, size: 30),
// // // // //             const SizedBox(width: 10),
// // // // //             const Text("Profil créé !"),
// // // // //           ],
// // // // //         ),
// // // // //         content: const Text(
// // // // //           "Votre profil a été créé avec succès.",
// // // // //           textAlign: TextAlign.center,
// // // // //         ),
// // // // //         actions: [
// // // // //           TextButton(
// // // // //             onPressed: () => Navigator.pop(context),
// // // // //             child: Text(
// // // // //               "Continuer",
// // // // //               style: TextStyle(color: primaryColor),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // // // import 'dart:convert';
// // // // // import 'dart:io';
// // // // // import 'package:flutter/foundation.dart';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:hairbnb/pages/profil/services/profile_api_service.dart';
// // // // // import 'package:http/http.dart' as http;
// // // // // import 'package:file_picker/file_picker.dart';
// // // // // import 'package:provider/provider.dart';
// // // // // import '../../services/providers/current_user_provider.dart';
// // // // // import '../home_page.dart';
// // // // // import '../salon/create_salon_page.dart';
// // // // // import '../../models/user_creation.dart';
// // // // //
// // // // // class ProfileCreationPage extends StatefulWidget {
// // // // //   final String userUuid;
// // // // //   final String email;
// // // // //
// // // // //   const ProfileCreationPage({
// // // // //     required this.userUuid,
// // // // //     required this.email,
// // // // //     super.key,
// // // // //   });
// // // // //
// // // // //   @override
// // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // }
// // // // //
// // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // //   // Variables pour le thème
// // // // //   final Color primaryColor = const Color(0xFF8E44AD);
// // // // //   final Color secondaryColor = const Color(0xFFF39C12);
// // // // //
// // // // //   // Variables de l'état
// // // // //   String? selectedGender;
// // // // //   final List<String> genderOptions = ["Homme", "Femme"];
// // // // //   Uint8List? profilePhotoBytes;
// // // // //   File? profilePhoto;
// // // // //   bool isCoiffeuse = false;
// // // // //   late String userEmail;
// // // // //   late String userUuid;
// // // // //   int _currentStep = 0;
// // // // //
// // // // //   // Variable pour stocker le modèle utilisateur
// // // // //   UserCreationModel? _userModel;
// // // // //
// // // // //   // Controllers
// // // // //   final TextEditingController nameController = TextEditingController();
// // // // //   final TextEditingController surnameController = TextEditingController();
// // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // //   final TextEditingController communeController = TextEditingController();
// // // // //   final TextEditingController streetController = TextEditingController();
// // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // //   final TextEditingController phoneController = TextEditingController();
// // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // //   final TextEditingController birthDateController = TextEditingController();
// // // // //
// // // // //   // Form keys pour validation
// // // // //   final _formKey = GlobalKey<FormState>();
// // // // //
// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     userEmail = widget.email;
// // // // //     userUuid = widget.userUuid;
// // // // //   }
// // // // //
// // // // //   @override
// // // // //   void dispose() {
// // // // //     // Libérer les contrôleurs
// // // // //     nameController.dispose();
// // // // //     surnameController.dispose();
// // // // //     codePostalController.dispose();
// // // // //     communeController.dispose();
// // // // //     streetController.dispose();
// // // // //     streetNumberController.dispose();
// // // // //     postalBoxController.dispose();
// // // // //     phoneController.dispose();
// // // // //     socialNameController.dispose();
// // // // //     birthDateController.dispose();
// // // // //     super.dispose();
// // // // //   }
// // // // //
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       body: SafeArea(
// // // // //         child: CustomScrollView(
// // // // //           slivers: [
// // // // //             _buildAppBar(),
// // // // //             SliverToBoxAdapter(
// // // // //               child: Padding(
// // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // // //                 child: Form(
// // // // //                   key: _formKey,
// // // // //                   child: Column(
// // // // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //                     children: [
// // // // //                       _buildProfilePhoto(),
// // // // //                       const SizedBox(height: 16),
// // // // //                       _buildRoleSelector(),
// // // // //                       const SizedBox(height: 24),
// // // // //                       _buildStepIndicator(),
// // // // //                       const SizedBox(height: 20),
// // // // //                       _buildCurrentStep(),
// // // // //                       const SizedBox(height: 20),
// // // // //                       _buildNavigationButtons(),
// // // // //                       const SizedBox(height: 40),
// // // // //                     ],
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // En-tête de l'application avec une apparence moderne
// // // // //   Widget _buildAppBar() {
// // // // //     return SliverAppBar(
// // // // //       expandedHeight: 120,
// // // // //       floating: true,
// // // // //       pinned: true,
// // // // //       flexibleSpace: FlexibleSpaceBar(
// // // // //         title: Text(
// // // // //           "Créer votre profil",
// // // // //           style: TextStyle(
// // // // //             color: Colors.white,
// // // // //             fontWeight: FontWeight.bold,
// // // // //           ),
// // // // //         ),
// // // // //         background: Container(
// // // // //           decoration: BoxDecoration(
// // // // //             gradient: LinearGradient(
// // // // //               begin: Alignment.topLeft,
// // // // //               end: Alignment.bottomRight,
// // // // //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Widget pour l'affichage et la sélection de la photo de profil
// // // // //   Widget _buildProfilePhoto() {
// // // // //     return Center(
// // // // //       child: Column(
// // // // //         children: [
// // // // //           const SizedBox(height: 20),
// // // // //           GestureDetector(
// // // // //             onTap: _pickPhoto,
// // // // //             child: Stack(
// // // // //               alignment: Alignment.bottomRight,
// // // // //               children: [
// // // // //                 Container(
// // // // //                   width: 120,
// // // // //                   height: 120,
// // // // //                   decoration: BoxDecoration(
// // // // //                     color: Colors.grey[200],
// // // // //                     shape: BoxShape.circle,
// // // // //                     boxShadow: [
// // // // //                       BoxShadow(
// // // // //                         color: Colors.black.withOpacity(0.1),
// // // // //                         blurRadius: 10,
// // // // //                         spreadRadius: 1,
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   child: ClipOval(
// // // // //                     child: profilePhotoBytes != null
// // // // //                         ? Image.memory(
// // // // //                       profilePhotoBytes!,
// // // // //                       fit: BoxFit.cover,
// // // // //                     )
// // // // //                         : profilePhoto != null
// // // // //                         ? Image.file(
// // // // //                       profilePhoto!,
// // // // //                       fit: BoxFit.cover,
// // // // //                     )
// // // // //                         : Icon(
// // // // //                       Icons.person,
// // // // //                       size: 70,
// // // // //                       color: Colors.grey[400],
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //                 Container(
// // // // //                   padding: const EdgeInsets.all(8),
// // // // //                   decoration: BoxDecoration(
// // // // //                     color: secondaryColor,
// // // // //                     shape: BoxShape.circle,
// // // // //                   ),
// // // // //                   child: const Icon(
// // // // //                     Icons.camera_alt,
// // // // //                     color: Colors.white,
// // // // //                     size: 20,
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //           const SizedBox(height: 8),
// // // // //           Text(
// // // // //             "Photo de profil",
// // // // //             style: TextStyle(
// // // // //               color: Colors.grey[600],
// // // // //               fontSize: 14,
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Sélecteur de rôle avec design moderne
// // // // //   Widget _buildRoleSelector() {
// // // // //     return Container(
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // //       decoration: BoxDecoration(
// // // // //         color: Colors.white,
// // // // //         borderRadius: BorderRadius.circular(16),
// // // // //         boxShadow: [
// // // // //           BoxShadow(
// // // // //             color: Colors.black.withOpacity(0.05),
// // // // //             blurRadius: 10,
// // // // //             spreadRadius: 1,
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //       child: Row(
// // // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //         children: [
// // // // //           const Text(
// // // // //             "Je suis :",
// // // // //             style: TextStyle(
// // // // //               fontWeight: FontWeight.bold,
// // // // //               fontSize: 16,
// // // // //             ),
// // // // //           ),
// // // // //           Row(
// // // // //             children: [
// // // // //               Text(
// // // // //                 "Client",
// // // // //                 style: TextStyle(
// // // // //                   color: !isCoiffeuse ? primaryColor : Colors.grey,
// // // // //                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // //                 ),
// // // // //               ),
// // // // //               Switch(
// // // // //                 value: isCoiffeuse,
// // // // //                 onChanged: (value) {
// // // // //                   setState(() {
// // // // //                     isCoiffeuse = value;
// // // // //                   });
// // // // //                 },
// // // // //                 activeColor: secondaryColor,
// // // // //                 activeTrackColor: secondaryColor.withOpacity(0.5),
// // // // //               ),
// // // // //               Text(
// // // // //                 "Coiffeuse",
// // // // //                 style: TextStyle(
// // // // //                   color: isCoiffeuse ? primaryColor : Colors.grey,
// // // // //                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Indicateur de progression des étapes
// // // // //   Widget _buildStepIndicator() {
// // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // //       child: Row(
// // // // //         children: List.generate(totalSteps, (index) {
// // // // //           return Expanded(
// // // // //             child: Container(
// // // // //               height: 4,
// // // // //               margin: const EdgeInsets.symmetric(horizontal: 4),
// // // // //               decoration: BoxDecoration(
// // // // //                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
// // // // //                 borderRadius: BorderRadius.circular(2),
// // // // //               ),
// // // // //             ),
// // // // //           );
// // // // //         }),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Affiche l'étape actuelle selon _currentStep
// // // // //   Widget _buildCurrentStep() {
// // // // //     switch (_currentStep) {
// // // // //       case 0:
// // // // //         return _buildPersonalInfoStep();
// // // // //       case 1:
// // // // //         return _buildAddressStep();
// // // // //       case 2:
// // // // //         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
// // // // //       default:
// // // // //         return _buildPersonalInfoStep();
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Étape 1 : Informations personnelles
// // // // //   Widget _buildPersonalInfoStep() {
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Text(
// // // // //           "Informations personnelles",
// // // // //           style: TextStyle(
// // // // //             fontSize: 20,
// // // // //             fontWeight: FontWeight.bold,
// // // // //             color: primaryColor,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 20),
// // // // //         _buildInputField(
// // // // //           label: "Nom",
// // // // //           controller: nameController,
// // // // //           icon: Icons.person_outline,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre nom';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Prénom",
// // // // //           controller: surnameController,
// // // // //           icon: Icons.person_outline,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre prénom';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildGenderDropdown(),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildDatePicker(),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Téléphone",
// // // // //           controller: phoneController,
// // // // //           icon: Icons.phone,
// // // // //           keyboardType: TextInputType.phone,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre numéro de téléphone';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Étape 2 : Adresse
// // // // //   Widget _buildAddressStep() {
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Text(
// // // // //           "Adresse",
// // // // //           style: TextStyle(
// // // // //             fontSize: 20,
// // // // //             fontWeight: FontWeight.bold,
// // // // //             color: primaryColor,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 20),
// // // // //         _buildInputField(
// // // // //           label: "Code Postal",
// // // // //           controller: codePostalController,
// // // // //           icon: Icons.location_on_outlined,
// // // // //           keyboardType: TextInputType.number,
// // // // //           onChanged: fetchCommune,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre code postal';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Commune",
// // // // //           controller: communeController,
// // // // //           icon: Icons.location_city,
// // // // //           readOnly: true,
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         _buildInputField(
// // // // //           label: "Rue",
// // // // //           controller: streetController,
// // // // //           icon: Icons.streetview,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre rue';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //         const SizedBox(height: 16),
// // // // //         Row(
// // // // //           children: [
// // // // //             Expanded(
// // // // //               child: _buildInputField(
// // // // //                 label: "Numéro",
// // // // //                 controller: streetNumberController,
// // // // //                 icon: Icons.home,
// // // // //                 validator: (value) {
// // // // //                   if (value == null || value.isEmpty) {
// // // // //                     return 'Obligatoire';
// // // // //                   }
// // // // //                   return null;
// // // // //                 },
// // // // //               ),
// // // // //             ),
// // // // //             const SizedBox(width: 16),
// // // // //             Expanded(
// // // // //               child: _buildInputField(
// // // // //                 label: "Boîte",
// // // // //                 controller: postalBoxController,
// // // // //                 icon: Icons.inbox,
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Étape 3 : Informations professionnelles (pour les coiffeuses)
// // // // //   Widget _buildProfessionalInfoStep() {
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Text(
// // // // //           "Informations professionnelles",
// // // // //           style: TextStyle(
// // // // //             fontSize: 20,
// // // // //             fontWeight: FontWeight.bold,
// // // // //             color: primaryColor,
// // // // //           ),
// // // // //         ),
// // // // //         const SizedBox(height: 20),
// // // // //         _buildInputField(
// // // // //           label: "Nom Commercial",
// // // // //           controller: socialNameController,
// // // // //           icon: Icons.business,
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre nom commercial';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Input field stylisé avec validation
// // // // //   Widget _buildInputField({
// // // // //     required String label,
// // // // //     required TextEditingController controller,
// // // // //     required IconData icon,
// // // // //     bool readOnly = false,
// // // // //     TextInputType keyboardType = TextInputType.text,
// // // // //     Function(String)? onChanged,
// // // // //     String? Function(String?)? validator,
// // // // //   }) {
// // // // //     return TextFormField(
// // // // //       controller: controller,
// // // // //       readOnly: readOnly,
// // // // //       keyboardType: keyboardType,
// // // // //       onChanged: onChanged,
// // // // //       validator: validator,
// // // // //       decoration: InputDecoration(
// // // // //         labelText: label,
// // // // //         prefixIcon: Icon(icon, color: primaryColor),
// // // // //         border: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         enabledBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         focusedBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // //         ),
// // // // //         filled: true,
// // // // //         fillColor: Colors.white,
// // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Dropdown stylisé pour le genre
// // // // //   Widget _buildGenderDropdown() {
// // // // //     return DropdownButtonFormField<String>(
// // // // //       value: selectedGender,
// // // // //       decoration: InputDecoration(
// // // // //         labelText: "Sexe",
// // // // //         prefixIcon: Icon(Icons.person, color: primaryColor),
// // // // //         border: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         enabledBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //         ),
// // // // //         focusedBorder: OutlineInputBorder(
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // //         ),
// // // // //         filled: true,
// // // // //         fillColor: Colors.white,
// // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // //       ),
// // // // //       items: genderOptions
// // // // //           .map((gender) => DropdownMenuItem(
// // // // //         value: gender,
// // // // //         child: Text(gender),
// // // // //       ))
// // // // //           .toList(),
// // // // //       onChanged: (value) {
// // // // //         setState(() {
// // // // //           selectedGender = value;
// // // // //         });
// // // // //       },
// // // // //       validator: (value) {
// // // // //         if (value == null || value.isEmpty) {
// // // // //           return 'Veuillez sélectionner votre genre';
// // // // //         }
// // // // //         return null;
// // // // //       },
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Date picker stylisé
// // // // //   Widget _buildDatePicker() {
// // // // //     return GestureDetector(
// // // // //       onTap: () async {
// // // // //         final selectedDate = await showDatePicker(
// // // // //           context: context,
// // // // //           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
// // // // //           firstDate: DateTime(1900),
// // // // //           lastDate: DateTime.now(),
// // // // //           builder: (context, child) {
// // // // //             return Theme(
// // // // //               data: Theme.of(context).copyWith(
// // // // //                 colorScheme: ColorScheme.light(
// // // // //                   primary: primaryColor,
// // // // //                   onPrimary: Colors.white,
// // // // //                   onSurface: Colors.black,
// // // // //                 ),
// // // // //               ),
// // // // //               child: child!,
// // // // //             );
// // // // //           },
// // // // //         );
// // // // //         if (selectedDate != null) {
// // // // //           setState(() {
// // // // //             birthDateController.text =
// // // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // // //                 "${selectedDate.year}";
// // // // //           });
// // // // //         }
// // // // //       },
// // // // //       child: AbsorbPointer(
// // // // //         child: TextFormField(
// // // // //           controller: birthDateController,
// // // // //           decoration: InputDecoration(
// // // // //             labelText: "Date de naissance",
// // // // //             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
// // // // //             border: OutlineInputBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //             ),
// // // // //             enabledBorder: OutlineInputBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // //             ),
// // // // //             focusedBorder: OutlineInputBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //               borderSide: BorderSide(color: primaryColor, width: 2),
// // // // //             ),
// // // // //             filled: true,
// // // // //             fillColor: Colors.white,
// // // // //             contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // //           ),
// // // // //           validator: (value) {
// // // // //             if (value == null || value.isEmpty) {
// // // // //               return 'Veuillez entrer votre date de naissance';
// // // // //             }
// // // // //             if (!_isValidDate(value)) {
// // // // //               return 'Format invalide (JJ-MM-AAAA)';
// // // // //             }
// // // // //             return null;
// // // // //           },
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Boutons de navigation
// // // // //   Widget _buildNavigationButtons() {
// // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // //     return Row(
// // // // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //       children: [
// // // // //         _currentStep > 0
// // // // //             ? ElevatedButton.icon(
// // // // //           icon: const Icon(Icons.arrow_back),
// // // // //           label: const Text("Précédent"),
// // // // //           onPressed: () {
// // // // //             setState(() {
// // // // //               _currentStep--;
// // // // //             });
// // // // //           },
// // // // //           style: ElevatedButton.styleFrom(
// // // // //             backgroundColor: Colors.grey[200],
// // // // //             foregroundColor: Colors.black87,
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // // //             shape: RoundedRectangleBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //             ),
// // // // //           ),
// // // // //         )
// // // // //             : const SizedBox(width: 120),
// // // // //         _currentStep < totalSteps - 1
// // // // //             ? ElevatedButton.icon(
// // // // //           icon: const Icon(Icons.arrow_forward),
// // // // //           label: const Text("Suivant"),
// // // // //           onPressed: () {
// // // // //             if (_validateCurrentStep()) {
// // // // //               setState(() {
// // // // //                 _currentStep++;
// // // // //               });
// // // // //             }
// // // // //           },
// // // // //           style: ElevatedButton.styleFrom(
// // // // //             backgroundColor: primaryColor,
// // // // //             foregroundColor: Colors.white,
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // //             shape: RoundedRectangleBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //             ),
// // // // //           ),
// // // // //         )
// // // // //             : ElevatedButton.icon(
// // // // //           icon: const Icon(Icons.check),
// // // // //           label: const Text("Enregistrer"),
// // // // //           onPressed: () {
// // // // //             if (_validateCurrentStep()) {
// // // // //               _saveProfile();
// // // // //             }
// // // // //           },
// // // // //           style: ElevatedButton.styleFrom(
// // // // //             backgroundColor: secondaryColor,
// // // // //             foregroundColor: Colors.white,
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // //             shape: RoundedRectangleBorder(
// // // // //               borderRadius: BorderRadius.circular(12),
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Validation de l'étape actuelle
// // // // //   bool _validateCurrentStep() {
// // // // //     return _formKey.currentState?.validate() ?? false;
// // // // //   }
// // // // //
// // // // //   // Méthode pour sélectionner une photo
// // // // //   Future<void> _pickPhoto() async {
// // // // //     try {
// // // // //       final result = await FilePicker.platform.pickFiles(
// // // // //         type: FileType.image,
// // // // //         allowMultiple: false,
// // // // //       );
// // // // //
// // // // //       if (result != null) {
// // // // //         setState(() {
// // // // //           if (kIsWeb) {
// // // // //             profilePhotoBytes = result.files.first.bytes;
// // // // //             profilePhoto = null;
// // // // //           } else {
// // // // //             profilePhoto = File(result.files.first.path!);
// // // // //             profilePhotoBytes = null;
// // // // //           }
// // // // //         });
// // // // //       }
// // // // //     } catch (e) {
// // // // //       if (mounted) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text("Erreur lors de la sélection de la photo: $e"),
// // // // //             backgroundColor: Colors.red,
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Validation du format de la date
// // // // //   bool _isValidDate(String date) {
// // // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // // //         if (!regex.hasMatch(date)) return false;
// // // // //
// // // // //     try {
// // // // //     final parts = date.split('-');
// // // // //     final day = int.parse(parts[0]);
// // // // //     final month = int.parse(parts[1]);
// // // // //     final year = int.parse(parts[2]);
// // // // //     final parsedDate = DateTime(year, month, day);
// // // // //     return parsedDate.year == year &&
// // // // //     parsedDate.month == month &&
// // // // //     parsedDate.day == day;
// // // // //     } catch (e) {
// // // // //     return false;
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Méthode pour récupérer la commune depuis le Code Postal
// // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // //     if (codePostal.length < 4) return;
// // // // //
// // // // //     final url = Uri.parse(
// // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // //
// // // // //     try {
// // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // //       if (response.statusCode == 200) {
// // // // //         final data = json.decode(response.body) as List;
// // // // //         if (data.isNotEmpty) {
// // // // //           final addressDetailsUrl = Uri.parse(
// // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // //           final addressResponse = await http.get(addressDetailsUrl,
// // // // //               headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // //           if (addressResponse.statusCode == 200) {
// // // // //             final addressData = json.decode(addressResponse.body);
// // // // //             if (mounted) {
// // // // //               setState(() {
// // // // //                 communeController.text = addressData['address']['city'] ??
// // // // //                     addressData['address']['town'] ??
// // // // //                     addressData['address']['village'] ??
// // // // //                     "Commune introuvable";
// // // // //               });
// // // // //             }
// // // // //           }
// // // // //         }
// // // // //       }
// // // // //     } catch (e) {
// // // // //       debugPrint("Erreur commune : $e");
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Créer le modèle utilisateur à partir des données du formulaire
// // // // //   UserCreationModel _createUserModel() {
// // // // //     return UserCreationModel.fromForm(
// // // // //       userUuid: userUuid,
// // // // //       email: userEmail,
// // // // //       isCoiffeuse: isCoiffeuse,
// // // // //       nom: nameController.text,
// // // // //       prenom: surnameController.text,
// // // // //       sexe: selectedGender ?? "",
// // // // //       telephone: phoneController.text,
// // // // //       dateNaissance: birthDateController.text,
// // // // //       codePostal: codePostalController.text,
// // // // //       commune: communeController.text,
// // // // //       rue: streetController.text,
// // // // //       numero: streetNumberController.text,
// // // // //       boitePostale: postalBoxController.text.isNotEmpty ? postalBoxController.text : null,
// // // // //       nomCommercial: isCoiffeuse ? socialNameController.text : null,
// // // // //       photoProfilFile: profilePhoto,
// // // // //       photoProfilBytes: profilePhotoBytes,
// // // // //       photoProfilName: 'profile_photo.png',
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // Sauvegarde du profil avec le nouveau système
// // // // //   void _saveProfile() async {
// // // // //     // Afficher un indicateur de chargement
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       barrierDismissible: false,
// // // // //       builder: (context) => Center(
// // // // //         child: CircularProgressIndicator(
// // // // //           color: primaryColor,
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //
// // // // //     try {
// // // // //       // Créer le modèle utilisateur
// // // // //       final userModel = _createUserModel();
// // // // //
// // // // //       // Appeler l'API via le service
// // // // //       final response = await ProfileApiService.createUserProfile(
// // // // //         userModel: userModel,
// // // // //         firebaseToken: null, // Vous pouvez ajouter le token Firebase ici si nécessaire
// // // // //       );
// // // // //
// // // // //       // Fermer la boîte de dialogue de chargement
// // // // //       if (mounted) Navigator.of(context).pop();
// // // // //
// // // // //       if (!mounted) return;
// // // // //
// // // // //       if (response.success) {
// // // // //         // Animation de succès
// // // // //         _showSuccessDialog();
// // // // //
// // // // //         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // // // //         await userProvider.fetchCurrentUser();
// // // // //
// // // // //         if (!mounted) return;
// // // // //
// // // // //         if (isCoiffeuse) {
// // // // //           // Redirection vers la création de salon pour les coiffeuses
// // // // //           if (userProvider.currentUser != null) {
// // // // //             Navigator.push(
// // // // //               context,
// // // // //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// // // // //             );
// // // // //           }
// // // // //         } else {
// // // // //           // Redirection vers la page d'accueil pour les clients
// // // // //           Navigator.pushReplacement(
// // // // //             context,
// // // // //             MaterialPageRoute(builder: (_) => const HomePage()),
// // // // //           );
// // // // //         }
// // // // //       } else {
// // // // //         // Gestion des erreurs
// // // // //         String errorMessage = response.message;
// // // // //
// // // // //         if (response.isValidationError && response.validationErrors != null) {
// // // // //           // Afficher les erreurs de validation
// // // // //           errorMessage = response.validationErrors!.values.join('\n');
// // // // //         }
// // // // //
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text(errorMessage),
// // // // //             backgroundColor: Colors.red,
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     } catch (e) {
// // // // //       if (mounted) {
// // // // //         // Fermer la boîte de dialogue de chargement
// // // // //         Navigator.of(context).pop();
// // // // //
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           SnackBar(
// // // // //             content: Text("Erreur inattendue: $e"),
// // // // //             backgroundColor: Colors.red,
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     }
// // // // //   }
// // // // //
// // // // //   // Animation de succès
// // // // //   void _showSuccessDialog() {
// // // // //     showDialog(
// // // // //       context: context,
// // // // //       builder: (context) => AlertDialog(
// // // // //         shape: RoundedRectangleBorder(
// // // // //           borderRadius: BorderRadius.circular(20),
// // // // //         ),
// // // // //         title: Row(
// // // // //           children: [
// // // // //             Icon(Icons.check_circle, color: Colors.green, size: 30),
// // // // //             const SizedBox(width: 10),
// // // // //             const Text("Profil créé !"),
// // // // //           ],
// // // // //         ),
// // // // //         content: const Text(
// // // // //           "Votre profil a été créé avec succès.",
// // // // //           textAlign: TextAlign.center,
// // // // //         ),
// // // // //         actions: [
// // // // //           TextButton(
// // // // //             onPressed: () => Navigator.pop(context),
// // // // //             child: Text(
// // // // //               "Continuer",
// // // // //               style: TextStyle(color: primaryColor),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // // // import 'dart:convert';
// // // // // // import 'dart:io';
// // // // // // import 'package:flutter/foundation.dart';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:hairbnb/pages/profil/services/profile_api_service.dart';
// // // // // // import 'package:http/http.dart' as http;
// // // // // // import 'package:file_picker/file_picker.dart';
// // // // // // import 'package:provider/provider.dart';
// // // // // // import '../../services/providers/current_user_provider.dart';
// // // // // // import '../home_page.dart';
// // // // // // import '../salon/create_salon_page.dart';
// // // // // // import '../../models/user_creation.dart';
// // // // // //
// // // // // // class ProfileCreationPage extends StatefulWidget {
// // // // // //   final String userUuid;
// // // // // //   final String email;
// // // // // //
// // // // // //   const ProfileCreationPage({
// // // // // //     required this.userUuid,
// // // // // //     required this.email,
// // // // // //     super.key,
// // // // // //   });
// // // // // //
// // // // // //   @override
// // // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // // }
// // // // // //
// // // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // // //   // Variables pour le thème
// // // // // //   final Color primaryColor = const Color(0xFF8E44AD);
// // // // // //   final Color secondaryColor = const Color(0xFFF39C12);
// // // // // //
// // // // // //   // Variables de l'état
// // // // // //   String? selectedGender;
// // // // // //   final List<String> genderOptions = ["Homme", "Femme"];
// // // // // //   Uint8List? profilePhotoBytes;
// // // // // //   File? profilePhoto;
// // // // // //   bool isCoiffeuse = false;
// // // // // //   late String userEmail;
// // // // // //   late String userUuid;
// // // // // //   int _currentStep = 0;
// // // // // //
// // // // // //   // Variable pour stocker le modèle utilisateur
// // // // // //   //UserCreationModel? _userModel;
// // // // // //
// // // // // //   // Controllers
// // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // //   final TextEditingController surnameController = TextEditingController();
// // // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // // //   final TextEditingController communeController = TextEditingController();
// // // // // //   final TextEditingController streetController = TextEditingController();
// // // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // // //   final TextEditingController phoneController = TextEditingController();
// // // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // // //   final TextEditingController tvaController = TextEditingController();
// // // // // //   final TextEditingController birthDateController = TextEditingController();
// // // // // //
// // // // // //   // Form keys pour validation
// // // // // //   final _formKey = GlobalKey<FormState>();
// // // // // //
// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     userEmail = widget.email;
// // // // // //     userUuid = widget.userUuid;
// // // // // //   }
// // // // // //
// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     // Libérer les contrôleurs
// // // // // //     nameController.dispose();
// // // // // //     surnameController.dispose();
// // // // // //     codePostalController.dispose();
// // // // // //     communeController.dispose();
// // // // // //     streetController.dispose();
// // // // // //     streetNumberController.dispose();
// // // // // //     postalBoxController.dispose();
// // // // // //     phoneController.dispose();
// // // // // //     socialNameController.dispose();
// // // // // //     tvaController.dispose();
// // // // // //     birthDateController.dispose();
// // // // // //     super.dispose();
// // // // // //   }
// // // // // //
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       body: SafeArea(
// // // // // //         child: CustomScrollView(
// // // // // //           slivers: [
// // // // // //             _buildAppBar(),
// // // // // //             SliverToBoxAdapter(
// // // // // //               child: Padding(
// // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // // // //                 child: Form(
// // // // // //                   key: _formKey,
// // // // // //                   child: Column(
// // // // // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // // //                     children: [
// // // // // //                       _buildProfilePhoto(),
// // // // // //                       const SizedBox(height: 16),
// // // // // //                       _buildRoleSelector(),
// // // // // //                       const SizedBox(height: 24),
// // // // // //                       _buildStepIndicator(),
// // // // // //                       const SizedBox(height: 20),
// // // // // //                       _buildCurrentStep(),
// // // // // //                       const SizedBox(height: 20),
// // // // // //                       _buildNavigationButtons(),
// // // // // //                       const SizedBox(height: 40),
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // En-tête de l'application avec une apparence moderne
// // // // // //   Widget _buildAppBar() {
// // // // // //     return SliverAppBar(
// // // // // //       expandedHeight: 120,
// // // // // //       floating: true,
// // // // // //       pinned: true,
// // // // // //       flexibleSpace: FlexibleSpaceBar(
// // // // // //         title: Text(
// // // // // //           "Créer votre profil",
// // // // // //           style: TextStyle(
// // // // // //             color: Colors.white,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //           ),
// // // // // //         ),
// // // // // //         background: Container(
// // // // // //           decoration: BoxDecoration(
// // // // // //             gradient: LinearGradient(
// // // // // //               begin: Alignment.topLeft,
// // // // // //               end: Alignment.bottomRight,
// // // // // //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Widget pour l'affichage et la sélection de la photo de profil
// // // // // //   Widget _buildProfilePhoto() {
// // // // // //     return Center(
// // // // // //       child: Column(
// // // // // //         children: [
// // // // // //           const SizedBox(height: 20),
// // // // // //           GestureDetector(
// // // // // //             onTap: _pickPhoto,
// // // // // //             child: Stack(
// // // // // //               alignment: Alignment.bottomRight,
// // // // // //               children: [
// // // // // //                 Container(
// // // // // //                   width: 120,
// // // // // //                   height: 120,
// // // // // //                   decoration: BoxDecoration(
// // // // // //                     color: Colors.grey[200],
// // // // // //                     shape: BoxShape.circle,
// // // // // //                     boxShadow: [
// // // // // //                       BoxShadow(
// // // // // //                         color: Colors.black.withOpacity(0.1),
// // // // // //                         blurRadius: 10,
// // // // // //                         spreadRadius: 1,
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                   child: ClipOval(
// // // // // //                     child: profilePhotoBytes != null
// // // // // //                         ? Image.memory(
// // // // // //                       profilePhotoBytes!,
// // // // // //                       fit: BoxFit.cover,
// // // // // //                     )
// // // // // //                         : profilePhoto != null
// // // // // //                         ? Image.file(
// // // // // //                       profilePhoto!,
// // // // // //                       fit: BoxFit.cover,
// // // // // //                     )
// // // // // //                         : Icon(
// // // // // //                       Icons.person,
// // // // // //                       size: 70,
// // // // // //                       color: Colors.grey[400],
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 Container(
// // // // // //                   padding: const EdgeInsets.all(8),
// // // // // //                   decoration: BoxDecoration(
// // // // // //                     color: secondaryColor,
// // // // // //                     shape: BoxShape.circle,
// // // // // //                   ),
// // // // // //                   child: const Icon(
// // // // // //                     Icons.camera_alt,
// // // // // //                     color: Colors.white,
// // // // // //                     size: 20,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //           const SizedBox(height: 8),
// // // // // //           Text(
// // // // // //             "Photo de profil",
// // // // // //             style: TextStyle(
// // // // // //               color: Colors.grey[600],
// // // // // //               fontSize: 14,
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Sélecteur de rôle avec design moderne
// // // // // //   Widget _buildRoleSelector() {
// // // // // //     return Container(
// // // // // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // //       decoration: BoxDecoration(
// // // // // //         color: Colors.white,
// // // // // //         borderRadius: BorderRadius.circular(16),
// // // // // //         boxShadow: [
// // // // // //           BoxShadow(
// // // // // //             color: Colors.black.withOpacity(0.05),
// // // // // //             blurRadius: 10,
// // // // // //             spreadRadius: 1,
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //       child: Row(
// // // // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // // //         children: [
// // // // // //           const Text(
// // // // // //             "Je suis :",
// // // // // //             style: TextStyle(
// // // // // //               fontWeight: FontWeight.bold,
// // // // // //               fontSize: 16,
// // // // // //             ),
// // // // // //           ),
// // // // // //           Row(
// // // // // //             children: [
// // // // // //               Text(
// // // // // //                 "Client",
// // // // // //                 style: TextStyle(
// // // // // //                   color: !isCoiffeuse ? primaryColor : Colors.grey,
// // // // // //                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // // //                 ),
// // // // // //               ),
// // // // // //               Switch(
// // // // // //                 value: isCoiffeuse,
// // // // // //                 onChanged: (value) {
// // // // // //                   setState(() {
// // // // // //                     isCoiffeuse = value;
// // // // // //                   });
// // // // // //                 },
// // // // // //                 activeColor: secondaryColor,
// // // // // //                 activeTrackColor: secondaryColor.withOpacity(0.5),
// // // // // //               ),
// // // // // //               Text(
// // // // // //                 "Coiffeuse",
// // // // // //                 style: TextStyle(
// // // // // //                   color: isCoiffeuse ? primaryColor : Colors.grey,
// // // // // //                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Indicateur de progression des étapes
// // // // // //   Widget _buildStepIndicator() {
// // // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // // //       child: Row(
// // // // // //         children: List.generate(totalSteps, (index) {
// // // // // //           return Expanded(
// // // // // //             child: Container(
// // // // // //               height: 4,
// // // // // //               margin: const EdgeInsets.symmetric(horizontal: 4),
// // // // // //               decoration: BoxDecoration(
// // // // // //                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
// // // // // //                 borderRadius: BorderRadius.circular(2),
// // // // // //               ),
// // // // // //             ),
// // // // // //           );
// // // // // //         }),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Affiche l'étape actuelle selon _currentStep
// // // // // //   Widget _buildCurrentStep() {
// // // // // //     switch (_currentStep) {
// // // // // //       case 0:
// // // // // //         return _buildPersonalInfoStep();
// // // // // //       case 1:
// // // // // //         return _buildAddressStep();
// // // // // //       case 2:
// // // // // //         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
// // // // // //       default:
// // // // // //         return _buildPersonalInfoStep();
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   // Étape 1 : Informations personnelles
// // // // // //   Widget _buildPersonalInfoStep() {
// // // // // //     return Column(
// // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //       children: [
// // // // // //         Text(
// // // // // //           "Informations personnelles",
// // // // // //           style: TextStyle(
// // // // // //             fontSize: 20,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //             color: primaryColor,
// // // // // //           ),
// // // // // //         ),
// // // // // //         const SizedBox(height: 20),
// // // // // //         _buildInputField(
// // // // // //           label: "Nom",
// // // // // //           controller: nameController,
// // // // // //           icon: Icons.person_outline,
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre nom';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //         const SizedBox(height: 16),
// // // // // //         _buildInputField(
// // // // // //           label: "Prénom",
// // // // // //           controller: surnameController,
// // // // // //           icon: Icons.person_outline,
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre prénom';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //         const SizedBox(height: 16),
// // // // // //         _buildGenderDropdown(),
// // // // // //         const SizedBox(height: 16),
// // // // // //         _buildDatePicker(),
// // // // // //         const SizedBox(height: 16),
// // // // // //         _buildInputField(
// // // // // //           label: "Téléphone",
// // // // // //           controller: phoneController,
// // // // // //           icon: Icons.phone,
// // // // // //           keyboardType: TextInputType.phone,
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre numéro de téléphone';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //       ],
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Étape 2 : Adresse
// // // // // //   Widget _buildAddressStep() {
// // // // // //     return Column(
// // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //       children: [
// // // // // //         Text(
// // // // // //           "Adresse",
// // // // // //           style: TextStyle(
// // // // // //             fontSize: 20,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //             color: primaryColor,
// // // // // //           ),
// // // // // //         ),
// // // // // //         const SizedBox(height: 20),
// // // // // //         _buildInputField(
// // // // // //           label: "Code Postal",
// // // // // //           controller: codePostalController,
// // // // // //           icon: Icons.location_on_outlined,
// // // // // //           keyboardType: TextInputType.number,
// // // // // //           onChanged: fetchCommune,
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre code postal';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //         const SizedBox(height: 16),
// // // // // //         _buildInputField(
// // // // // //           label: "Commune",
// // // // // //           controller: communeController,
// // // // // //           icon: Icons.location_city,
// // // // // //           readOnly: true,
// // // // // //         ),
// // // // // //         const SizedBox(height: 16),
// // // // // //         _buildInputField(
// // // // // //           label: "Rue",
// // // // // //           controller: streetController,
// // // // // //           icon: Icons.streetview,
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre rue';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //         const SizedBox(height: 16),
// // // // // //         Row(
// // // // // //           children: [
// // // // // //             Expanded(
// // // // // //               child: _buildInputField(
// // // // // //                 label: "Numéro",
// // // // // //                 controller: streetNumberController,
// // // // // //                 icon: Icons.home,
// // // // // //                 validator: (value) {
// // // // // //                   if (value == null || value.isEmpty) {
// // // // // //                     return 'Obligatoire';
// // // // // //                   }
// // // // // //                   return null;
// // // // // //                 },
// // // // // //               ),
// // // // // //             ),
// // // // // //             const SizedBox(width: 16),
// // // // // //             Expanded(
// // // // // //               child: _buildInputField(
// // // // // //                 label: "Boîte",
// // // // // //                 controller: postalBoxController,
// // // // // //                 icon: Icons.inbox,
// // // // // //               ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ],
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Étape 3 : Informations professionnelles (pour les coiffeuses)
// // // // // //   Widget _buildProfessionalInfoStep() {
// // // // // //     return Column(
// // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //       children: [
// // // // // //         Text(
// // // // // //           "Informations professionnelles",
// // // // // //           style: TextStyle(
// // // // // //             fontSize: 20,
// // // // // //             fontWeight: FontWeight.bold,
// // // // // //             color: primaryColor,
// // // // // //           ),
// // // // // //         ),
// // // // // //         const SizedBox(height: 20),
// // // // // //         _buildInputField(
// // // // // //           label: "Dénomination Sociale",
// // // // // //           controller: socialNameController,
// // // // // //           icon: Icons.business,
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre dénomination sociale';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //         const SizedBox(height: 16),
// // // // // //         _buildInputField(
// // // // // //           label: "Numéro TVA",
// // // // // //           controller: tvaController,
// // // // // //           icon: Icons.receipt_long,
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre numéro TVA';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //       ],
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Input field stylisé avec validation
// // // // // //   Widget _buildInputField({
// // // // // //     required String label,
// // // // // //     required TextEditingController controller,
// // // // // //     required IconData icon,
// // // // // //     bool readOnly = false,
// // // // // //     TextInputType keyboardType = TextInputType.text,
// // // // // //     Function(String)? onChanged,
// // // // // //     String? Function(String?)? validator,
// // // // // //   }) {
// // // // // //     return TextFormField(
// // // // // //       controller: controller,
// // // // // //       readOnly: readOnly,
// // // // // //       keyboardType: keyboardType,
// // // // // //       onChanged: onChanged,
// // // // // //       validator: validator,
// // // // // //       decoration: InputDecoration(
// // // // // //         labelText: label,
// // // // // //         prefixIcon: Icon(icon, color: primaryColor),
// // // // // //         border: OutlineInputBorder(
// // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // //         ),
// // // // // //         enabledBorder: OutlineInputBorder(
// // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // //         ),
// // // // // //         focusedBorder: OutlineInputBorder(
// // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // // //         ),
// // // // // //         filled: true,
// // // // // //         fillColor: Colors.white,
// // // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Dropdown stylisé pour le genre
// // // // // //   Widget _buildGenderDropdown() {
// // // // // //     return DropdownButtonFormField<String>(
// // // // // //       value: selectedGender,
// // // // // //       decoration: InputDecoration(
// // // // // //         labelText: "Sexe",
// // // // // //         prefixIcon: Icon(Icons.person, color: primaryColor),
// // // // // //         border: OutlineInputBorder(
// // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // //         ),
// // // // // //         enabledBorder: OutlineInputBorder(
// // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // //         ),
// // // // // //         focusedBorder: OutlineInputBorder(
// // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // // //         ),
// // // // // //         filled: true,
// // // // // //         fillColor: Colors.white,
// // // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // // //       ),
// // // // // //       items: genderOptions
// // // // // //           .map((gender) => DropdownMenuItem(
// // // // // //         value: gender,
// // // // // //         child: Text(gender),
// // // // // //       ))
// // // // // //           .toList(),
// // // // // //       onChanged: (value) {
// // // // // //         setState(() {
// // // // // //           selectedGender = value;
// // // // // //         });
// // // // // //       },
// // // // // //       validator: (value) {
// // // // // //         if (value == null || value.isEmpty) {
// // // // // //           return 'Veuillez sélectionner votre genre';
// // // // // //         }
// // // // // //         return null;
// // // // // //       },
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Date picker stylisé
// // // // // //   Widget _buildDatePicker() {
// // // // // //     return GestureDetector(
// // // // // //       onTap: () async {
// // // // // //         final selectedDate = await showDatePicker(
// // // // // //           context: context,
// // // // // //           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
// // // // // //           firstDate: DateTime(1900),
// // // // // //           lastDate: DateTime.now(),
// // // // // //           builder: (context, child) {
// // // // // //             return Theme(
// // // // // //               data: Theme.of(context).copyWith(
// // // // // //                 colorScheme: ColorScheme.light(
// // // // // //                   primary: primaryColor,
// // // // // //                   onPrimary: Colors.white,
// // // // // //                   onSurface: Colors.black,
// // // // // //                 ),
// // // // // //               ),
// // // // // //               child: child!,
// // // // // //             );
// // // // // //           },
// // // // // //         );
// // // // // //         if (selectedDate != null) {
// // // // // //           setState(() {
// // // // // //             birthDateController.text =
// // // // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // // // //                 "${selectedDate.year}";
// // // // // //           });
// // // // // //         }
// // // // // //       },
// // // // // //       child: AbsorbPointer(
// // // // // //         child: TextFormField(
// // // // // //           controller: birthDateController,
// // // // // //           decoration: InputDecoration(
// // // // // //             labelText: "Date de naissance",
// // // // // //             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
// // // // // //             border: OutlineInputBorder(
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // //             ),
// // // // // //             enabledBorder: OutlineInputBorder(
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // //             ),
// // // // // //             focusedBorder: OutlineInputBorder(
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //               borderSide: BorderSide(color: primaryColor, width: 2),
// // // // // //             ),
// // // // // //             filled: true,
// // // // // //             fillColor: Colors.white,
// // // // // //             contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // // //           ),
// // // // // //           validator: (value) {
// // // // // //             if (value == null || value.isEmpty) {
// // // // // //               return 'Veuillez entrer votre date de naissance';
// // // // // //             }
// // // // // //             if (!_isValidDate(value)) {
// // // // // //               return 'Format invalide (JJ-MM-AAAA)';
// // // // // //             }
// // // // // //             return null;
// // // // // //           },
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Boutons de navigation
// // // // // //   Widget _buildNavigationButtons() {
// // // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // // //     return Row(
// // // // // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // // //       children: [
// // // // // //         _currentStep > 0
// // // // // //             ? ElevatedButton.icon(
// // // // // //           icon: const Icon(Icons.arrow_back),
// // // // // //           label: const Text("Précédent"),
// // // // // //           onPressed: () {
// // // // // //             setState(() {
// // // // // //               _currentStep--;
// // // // // //             });
// // // // // //           },
// // // // // //           style: ElevatedButton.styleFrom(
// // // // // //             backgroundColor: Colors.grey[200],
// // // // // //             foregroundColor: Colors.black87,
// // // // // //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // // // //             shape: RoundedRectangleBorder(
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //             ),
// // // // // //           ),
// // // // // //         )
// // // // // //             : const SizedBox(width: 120),
// // // // // //         _currentStep < totalSteps - 1
// // // // // //             ? ElevatedButton.icon(
// // // // // //           icon: const Icon(Icons.arrow_forward),
// // // // // //           label: const Text("Suivant"),
// // // // // //           onPressed: () {
// // // // // //             if (_validateCurrentStep()) {
// // // // // //               setState(() {
// // // // // //                 _currentStep++;
// // // // // //               });
// // // // // //             }
// // // // // //           },
// // // // // //           style: ElevatedButton.styleFrom(
// // // // // //             backgroundColor: primaryColor,
// // // // // //             foregroundColor: Colors.white,
// // // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // // //             shape: RoundedRectangleBorder(
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //             ),
// // // // // //           ),
// // // // // //         )
// // // // // //             : ElevatedButton.icon(
// // // // // //           icon: const Icon(Icons.check),
// // // // // //           label: const Text("Enregistrer"),
// // // // // //           onPressed: () {
// // // // // //             if (_validateCurrentStep()) {
// // // // // //               _saveProfile();
// // // // // //             }
// // // // // //           },
// // // // // //           style: ElevatedButton.styleFrom(
// // // // // //             backgroundColor: secondaryColor,
// // // // // //             foregroundColor: Colors.white,
// // // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // // //             shape: RoundedRectangleBorder(
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       ],
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Validation de l'étape actuelle
// // // // // //   bool _validateCurrentStep() {
// // // // // //     return _formKey.currentState?.validate() ?? false;
// // // // // //   }
// // // // // //
// // // // // //   // Méthode pour sélectionner une photo
// // // // // //   Future<void> _pickPhoto() async {
// // // // // //     try {
// // // // // //       final result = await FilePicker.platform.pickFiles(
// // // // // //         type: FileType.image,
// // // // // //         allowMultiple: false,
// // // // // //       );
// // // // // //
// // // // // //       if (result != null) {
// // // // // //         setState(() {
// // // // // //           if (kIsWeb) {
// // // // // //             profilePhotoBytes = result.files.first.bytes;
// // // // // //             profilePhoto = null;
// // // // // //           } else {
// // // // // //             profilePhoto = File(result.files.first.path!);
// // // // // //             profilePhotoBytes = null;
// // // // // //           }
// // // // // //         });
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       if (mounted) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(
// // // // // //             content: Text("Erreur lors de la sélection de la photo: $e"),
// // // // // //             backgroundColor: Colors.red,
// // // // // //           ),
// // // // // //         );
// // // // // //       }
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   // Validation du format de la date
// // // // // //   bool _isValidDate(String date) {
// // // // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // // // //         if (!regex.hasMatch(date)) return false;
// // // // // //
// // // // // //     try {
// // // // // //     final parts = date.split('-');
// // // // // //     final day = int.parse(parts[0]);
// // // // // //     final month = int.parse(parts[1]);
// // // // // //     final year = int.parse(parts[2]);
// // // // // //     final parsedDate = DateTime(year, month, day);
// // // // // //     return parsedDate.year == year &&
// // // // // //     parsedDate.month == month &&
// // // // // //     parsedDate.day == day;
// // // // // //     } catch (e) {
// // // // // //     return false;
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   // Méthode pour récupérer la commune depuis le Code Postal
// // // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // // //     if (codePostal.length < 4) return;
// // // // // //
// // // // // //     final url = Uri.parse(
// // // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // // //
// // // // // //     try {
// // // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // //       if (response.statusCode == 200) {
// // // // // //         final data = json.decode(response.body) as List;
// // // // // //         if (data.isNotEmpty) {
// // // // // //           final addressDetailsUrl = Uri.parse(
// // // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // // //           final addressResponse = await http.get(addressDetailsUrl,
// // // // // //               headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // //           if (addressResponse.statusCode == 200) {
// // // // // //             final addressData = json.decode(addressResponse.body);
// // // // // //             if (mounted) {
// // // // // //               setState(() {
// // // // // //                 communeController.text = addressData['address']['city'] ??
// // // // // //                     addressData['address']['town'] ??
// // // // // //                     addressData['address']['village'] ??
// // // // // //                     "Commune introuvable";
// // // // // //               });
// // // // // //             }
// // // // // //           }
// // // // // //         }
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       debugPrint("Erreur commune : $e");
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   // Créer le modèle utilisateur à partir des données du formulaire
// // // // // //   UserCreationModel _createUserModel() {
// // // // // //     return UserCreationModel.fromForm(
// // // // // //       userUuid: userUuid,
// // // // // //       email: userEmail,
// // // // // //       isCoiffeuse: isCoiffeuse,
// // // // // //       nom: nameController.text,
// // // // // //       prenom: surnameController.text,
// // // // // //       sexe: selectedGender ?? "",
// // // // // //       telephone: phoneController.text,
// // // // // //       dateNaissance: birthDateController.text,
// // // // // //       codePostal: codePostalController.text,
// // // // // //       commune: communeController.text,
// // // // // //       rue: streetController.text,
// // // // // //       numero: streetNumberController.text,
// // // // // //       boitePostale: postalBoxController.text.isNotEmpty ? postalBoxController.text : null,
// // // // // //       denominationSociale: isCoiffeuse ? socialNameController.text : null,
// // // // // //       tva: isCoiffeuse ? tvaController.text : null,
// // // // // //       photoProfilFile: profilePhoto,
// // // // // //       photoProfilBytes: profilePhotoBytes,
// // // // // //       photoProfilName: 'profile_photo.png',
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // Sauvegarde du profil avec le nouveau système
// // // // // //   void _saveProfile() async {
// // // // // //     // Afficher un indicateur de chargement
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       barrierDismissible: false,
// // // // // //       builder: (context) => Center(
// // // // // //         child: CircularProgressIndicator(
// // // // // //           color: primaryColor,
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //
// // // // // //     try {
// // // // // //       // Créer le modèle utilisateur
// // // // // //       final userModel = _createUserModel();
// // // // // //
// // // // // //       // Appeler l'API via le service
// // // // // //       final response = await ProfileApiService.createUserProfile(
// // // // // //         userModel: userModel,
// // // // // //         firebaseToken: null, // Vous pouvez ajouter le token Firebase ici si nécessaire
// // // // // //       );
// // // // // //
// // // // // //       // Fermer la boîte de dialogue de chargement
// // // // // //       if (mounted) Navigator.of(context).pop();
// // // // // //
// // // // // //       if (!mounted) return;
// // // // // //
// // // // // //       if (response.success) {
// // // // // //         // Animation de succès
// // // // // //         _showSuccessDialog();
// // // // // //
// // // // // //         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // // // // //         await userProvider.fetchCurrentUser();
// // // // // //
// // // // // //         if (!mounted) return;
// // // // // //
// // // // // //         if (isCoiffeuse) {
// // // // // //           // Redirection vers la création de salon pour les coiffeuses
// // // // // //           if (userProvider.currentUser != null) {
// // // // // //             Navigator.push(
// // // // // //               context,
// // // // // //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// // // // // //             );
// // // // // //           }
// // // // // //         } else {
// // // // // //           // Redirection vers la page d'accueil pour les clients
// // // // // //           Navigator.pushReplacement(
// // // // // //             context,
// // // // // //             MaterialPageRoute(builder: (_) => const HomePage()),
// // // // // //           );
// // // // // //         }
// // // // // //       } else {
// // // // // //         // Gestion des erreurs
// // // // // //         String errorMessage = response.message;
// // // // // //
// // // // // //         if (response.isValidationError && response.validationErrors != null) {
// // // // // //           // Afficher les erreurs de validation
// // // // // //           errorMessage = response.validationErrors!.values.join('\n');
// // // // // //         }
// // // // // //
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(
// // // // // //             content: Text(errorMessage),
// // // // // //             backgroundColor: Colors.red,
// // // // // //           ),
// // // // // //         );
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       if (mounted) {
// // // // // //         // Fermer la boîte de dialogue de chargement
// // // // // //         Navigator.of(context).pop();
// // // // // //
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(
// // // // // //             content: Text("Erreur inattendue: $e"),
// // // // // //             backgroundColor: Colors.red,
// // // // // //           ),
// // // // // //         );
// // // // // //       }
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   // Animation de succès
// // // // // //   void _showSuccessDialog() {
// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       builder: (context) => AlertDialog(
// // // // // //         shape: RoundedRectangleBorder(
// // // // // //           borderRadius: BorderRadius.circular(20),
// // // // // //         ),
// // // // // //         title: Row(
// // // // // //           children: [
// // // // // //             Icon(Icons.check_circle, color: Colors.green, size: 30),
// // // // // //             const SizedBox(width: 10),
// // // // // //             const Text("Profil créé !"),
// // // // // //           ],
// // // // // //         ),
// // // // // //         content: const Text(
// // // // // //           "Votre profil a été créé avec succès.",
// // // // // //           textAlign: TextAlign.center,
// // // // // //         ),
// // // // // //         actions: [
// // // // // //           TextButton(
// // // // // //             onPressed: () => Navigator.pop(context),
// // // // // //             child: Text(
// // // // // //               "Continuer",
// // // // // //               style: TextStyle(color: primaryColor),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // //
// // // // // // // import 'dart:convert';
// // // // // // // import 'dart:io';
// // // // // // // import 'package:flutter/foundation.dart';
// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:http/http.dart' as http;
// // // // // // // import 'package:file_picker/file_picker.dart';
// // // // // // // import 'package:http_parser/http_parser.dart';
// // // // // // // import 'package:provider/provider.dart';
// // // // // // // import '../../services/providers/current_user_provider.dart';
// // // // // // // import '../home_page.dart';
// // // // // // // import '../salon/create_salon_page.dart';
// // // // // // //
// // // // // // // class ProfileCreationPage extends StatefulWidget {
// // // // // // //   final String userUuid;
// // // // // // //   final String email;
// // // // // // //
// // // // // // //   const ProfileCreationPage({
// // // // // // //     required this.userUuid,
// // // // // // //     required this.email,
// // // // // // //     super.key,
// // // // // // //   });
// // // // // // //
// // // // // // //   @override
// // // // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // // // }
// // // // // // //
// // // // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // // // //   // Variables pour le thème
// // // // // // //   final Color primaryColor = const Color(0xFF8E44AD); // Couleur violette comme dans l'image
// // // // // // //   final Color secondaryColor = const Color(0xFFF39C12); // Couleur orange pour les accents
// // // // // // //
// // // // // // //   // Variables de l'état
// // // // // // //   String? selectedGender;
// // // // // // //   final List<String> genderOptions = ["Homme", "Femme"];
// // // // // // //   Uint8List? profilePhotoBytes;
// // // // // // //   File? profilePhoto;
// // // // // // //   bool isCoiffeuse = false;
// // // // // // //   late String userEmail;
// // // // // // //   late String userUuid;
// // // // // // //   int _currentStep = 0; // Pour la progression par étapes
// // // // // // //
// // // // // // //   // Controllers
// // // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // // //   final TextEditingController surnameController = TextEditingController();
// // // // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // // // //   final TextEditingController communeController = TextEditingController();
// // // // // // //   final TextEditingController streetController = TextEditingController();
// // // // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // // // //   final TextEditingController phoneController = TextEditingController();
// // // // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // // // //   final TextEditingController tvaController = TextEditingController();
// // // // // // //   final TextEditingController birthDateController = TextEditingController();
// // // // // // //
// // // // // // //   // Form keys pour validation
// // // // // // //   final _formKey = GlobalKey<FormState>();
// // // // // // //
// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();
// // // // // // //     userEmail = widget.email;
// // // // // // //     userUuid = widget.userUuid;
// // // // // // //   }
// // // // // // //
// // // // // // //   @override
// // // // // // //   void dispose() {
// // // // // // //     // Libérer les contrôleurs
// // // // // // //     nameController.dispose();
// // // // // // //     surnameController.dispose();
// // // // // // //     codePostalController.dispose();
// // // // // // //     communeController.dispose();
// // // // // // //     streetController.dispose();
// // // // // // //     streetNumberController.dispose();
// // // // // // //     postalBoxController.dispose();
// // // // // // //     phoneController.dispose();
// // // // // // //     socialNameController.dispose();
// // // // // // //     tvaController.dispose();
// // // // // // //     birthDateController.dispose();
// // // // // // //     super.dispose();
// // // // // // //   }
// // // // // // //
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Scaffold(
// // // // // // //       body: SafeArea(
// // // // // // //         child: CustomScrollView(
// // // // // // //           slivers: [
// // // // // // //             _buildAppBar(),
// // // // // // //             SliverToBoxAdapter(
// // // // // // //               child: Padding(
// // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // // // // //                 child: Form(
// // // // // // //                   key: _formKey,
// // // // // // //                   child: Column(
// // // // // // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // // // //                     children: [
// // // // // // //                       _buildProfilePhoto(),
// // // // // // //                       const SizedBox(height: 16),
// // // // // // //                       _buildRoleSelector(),
// // // // // // //                       const SizedBox(height: 24),
// // // // // // //                       _buildStepIndicator(),
// // // // // // //                       const SizedBox(height: 20),
// // // // // // //                       _buildCurrentStep(),
// // // // // // //                       const SizedBox(height: 20),
// // // // // // //                       _buildNavigationButtons(),
// // // // // // //                       const SizedBox(height: 40),
// // // // // // //                     ],
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // En-tête de l'application avec une apparence moderne
// // // // // // //   Widget _buildAppBar() {
// // // // // // //     return SliverAppBar(
// // // // // // //       expandedHeight: 120,
// // // // // // //       floating: true,
// // // // // // //       pinned: true,
// // // // // // //       flexibleSpace: FlexibleSpaceBar(
// // // // // // //         title: Text(
// // // // // // //           "Créer votre profil",
// // // // // // //           style: TextStyle(
// // // // // // //             color: Colors.white,
// // // // // // //             fontWeight: FontWeight.bold,
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         background: Container(
// // // // // // //           decoration: BoxDecoration(
// // // // // // //             gradient: LinearGradient(
// // // // // // //               begin: Alignment.topLeft,
// // // // // // //               end: Alignment.bottomRight,
// // // // // // //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Widget pour l'affichage et la sélection de la photo de profil
// // // // // // //   Widget _buildProfilePhoto() {
// // // // // // //     return Center(
// // // // // // //       child: Column(
// // // // // // //         children: [
// // // // // // //           const SizedBox(height: 20),
// // // // // // //           GestureDetector(
// // // // // // //             onTap: _pickPhoto,
// // // // // // //             child: Stack(
// // // // // // //               alignment: Alignment.bottomRight,
// // // // // // //               children: [
// // // // // // //                 Container(
// // // // // // //                   width: 120,
// // // // // // //                   height: 120,
// // // // // // //                   decoration: BoxDecoration(
// // // // // // //                     color: Colors.grey[200],
// // // // // // //                     shape: BoxShape.circle,
// // // // // // //                     boxShadow: [
// // // // // // //                       BoxShadow(
// // // // // // //                         color: Colors.black.withOpacity(0.1),
// // // // // // //                         blurRadius: 10,
// // // // // // //                         spreadRadius: 1,
// // // // // // //                       ),
// // // // // // //                     ],
// // // // // // //                   ),
// // // // // // //                   child: ClipOval(
// // // // // // //                     child: profilePhotoBytes != null
// // // // // // //                         ? Image.memory(
// // // // // // //                       profilePhotoBytes!,
// // // // // // //                       fit: BoxFit.cover,
// // // // // // //                     )
// // // // // // //                         : profilePhoto != null
// // // // // // //                         ? Image.file(
// // // // // // //                       profilePhoto!,
// // // // // // //                       fit: BoxFit.cover,
// // // // // // //                     )
// // // // // // //                         : Icon(
// // // // // // //                       Icons.person,
// // // // // // //                       size: 70,
// // // // // // //                       color: Colors.grey[400],
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 Container(
// // // // // // //                   padding: const EdgeInsets.all(8),
// // // // // // //                   decoration: BoxDecoration(
// // // // // // //                     color: secondaryColor,
// // // // // // //                     shape: BoxShape.circle,
// // // // // // //                   ),
// // // // // // //                   child: const Icon(
// // // // // // //                     Icons.camera_alt,
// // // // // // //                     color: Colors.white,
// // // // // // //                     size: 20,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //               ],
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //           const SizedBox(height: 8),
// // // // // // //           Text(
// // // // // // //             "Photo de profil",
// // // // // // //             style: TextStyle(
// // // // // // //               color: Colors.grey[600],
// // // // // // //               fontSize: 14,
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Sélecteur de rôle avec design moderne
// // // // // // //   Widget _buildRoleSelector() {
// // // // // // //     return Container(
// // // // // // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // // // // //       decoration: BoxDecoration(
// // // // // // //         color: Colors.white,
// // // // // // //         borderRadius: BorderRadius.circular(16),
// // // // // // //         boxShadow: [
// // // // // // //           BoxShadow(
// // // // // // //             color: Colors.black.withOpacity(0.05),
// // // // // // //             blurRadius: 10,
// // // // // // //             spreadRadius: 1,
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //       child: Row(
// // // // // // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // // // //         children: [
// // // // // // //           const Text(
// // // // // // //             "Je suis :",
// // // // // // //             style: TextStyle(
// // // // // // //               fontWeight: FontWeight.bold,
// // // // // // //               fontSize: 16,
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //           Row(
// // // // // // //             children: [
// // // // // // //               Text(
// // // // // // //                 "Client",
// // // // // // //                 style: TextStyle(
// // // // // // //                   color: !isCoiffeuse ? primaryColor : Colors.grey,
// // // // // // //                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //               Switch(
// // // // // // //                 value: isCoiffeuse,
// // // // // // //                 onChanged: (value) {
// // // // // // //                   setState(() {
// // // // // // //                     isCoiffeuse = value;
// // // // // // //                   });
// // // // // // //                 },
// // // // // // //                 activeColor: secondaryColor,
// // // // // // //                 activeTrackColor: secondaryColor.withOpacity(0.5),
// // // // // // //               ),
// // // // // // //               Text(
// // // // // // //                 "Coiffeuse",
// // // // // // //                 style: TextStyle(
// // // // // // //                   color: isCoiffeuse ? primaryColor : Colors.grey,
// // // // // // //                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Indicateur de progression des étapes
// // // // // // //   Widget _buildStepIndicator() {
// // // // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // // // //     return Padding(
// // // // // // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // // // //       child: Row(
// // // // // // //         children: List.generate(totalSteps, (index) {
// // // // // // //           return Expanded(
// // // // // // //             child: Container(
// // // // // // //               height: 4,
// // // // // // //               margin: const EdgeInsets.symmetric(horizontal: 4),
// // // // // // //               decoration: BoxDecoration(
// // // // // // //                 color: index <= _currentStep ? primaryColor : Colors.grey[300],
// // // // // // //                 borderRadius: BorderRadius.circular(2),
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           );
// // // // // // //         }),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Affiche l'étape actuelle selon _currentStep
// // // // // // //   Widget _buildCurrentStep() {
// // // // // // //     switch (_currentStep) {
// // // // // // //       case 0:
// // // // // // //         return _buildPersonalInfoStep();
// // // // // // //       case 1:
// // // // // // //         return _buildAddressStep();
// // // // // // //       case 2:
// // // // // // //         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
// // // // // // //       default:
// // // // // // //         return _buildPersonalInfoStep();
// // // // // // //     }
// // // // // // //   }
// // // // // // //
// // // // // // //   // Étape 1 : Informations personnelles
// // // // // // //   Widget _buildPersonalInfoStep() {
// // // // // // //     return Column(
// // // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //       children: [
// // // // // // //         Text(
// // // // // // //           "Informations personnelles",
// // // // // // //           style: TextStyle(
// // // // // // //             fontSize: 20,
// // // // // // //             fontWeight: FontWeight.bold,
// // // // // // //             color: primaryColor,
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 20),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Nom",
// // // // // // //           controller: nameController,
// // // // // // //           icon: Icons.person_outline,
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre nom';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Prénom",
// // // // // // //           controller: surnameController,
// // // // // // //           icon: Icons.person_outline,
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre prénom';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         _buildGenderDropdown(),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         _buildDatePicker(),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Téléphone",
// // // // // // //           controller: phoneController,
// // // // // // //           icon: Icons.phone,
// // // // // // //           keyboardType: TextInputType.phone,
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre numéro de téléphone';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //       ],
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Étape 2 : Adresse
// // // // // // //   Widget _buildAddressStep() {
// // // // // // //     return Column(
// // // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //       children: [
// // // // // // //         Text(
// // // // // // //           "Adresse",
// // // // // // //           style: TextStyle(
// // // // // // //             fontSize: 20,
// // // // // // //             fontWeight: FontWeight.bold,
// // // // // // //             color: primaryColor,
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 20),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Code Postal",
// // // // // // //           controller: codePostalController,
// // // // // // //           icon: Icons.location_on_outlined,
// // // // // // //           keyboardType: TextInputType.number,
// // // // // // //           onChanged: fetchCommune,
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre code postal';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Commune",
// // // // // // //           controller: communeController,
// // // // // // //           icon: Icons.location_city,
// // // // // // //           readOnly: true,
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Rue",
// // // // // // //           controller: streetController,
// // // // // // //           icon: Icons.streetview,
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre rue';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         Row(
// // // // // // //           children: [
// // // // // // //             Expanded(
// // // // // // //               child: _buildInputField(
// // // // // // //                 label: "Numéro",
// // // // // // //                 controller: streetNumberController,
// // // // // // //                 icon: Icons.home,
// // // // // // //                 validator: (value) {
// // // // // // //                   if (value == null || value.isEmpty) {
// // // // // // //                     return 'Obligatoire';
// // // // // // //                   }
// // // // // // //                   return null;
// // // // // // //                 },
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //             const SizedBox(width: 16),
// // // // // // //             Expanded(
// // // // // // //               child: _buildInputField(
// // // // // // //                 label: "Boîte",
// // // // // // //                 controller: postalBoxController,
// // // // // // //                 icon: Icons.inbox,
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //       ],
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Étape 3 : Informations professionnelles (pour les coiffeuses)
// // // // // // //   Widget _buildProfessionalInfoStep() {
// // // // // // //     return Column(
// // // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //       children: [
// // // // // // //         Text(
// // // // // // //           "Informations professionnelles",
// // // // // // //           style: TextStyle(
// // // // // // //             fontSize: 20,
// // // // // // //             fontWeight: FontWeight.bold,
// // // // // // //             color: primaryColor,
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 20),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Dénomination Sociale",
// // // // // // //           controller: socialNameController,
// // // // // // //           icon: Icons.business,
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre dénomination sociale';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //         const SizedBox(height: 16),
// // // // // // //         _buildInputField(
// // // // // // //           label: "Numéro TVA",
// // // // // // //           controller: tvaController,
// // // // // // //           icon: Icons.receipt_long,
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre numéro TVA';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //       ],
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Input field stylisé avec validation
// // // // // // //   Widget _buildInputField({
// // // // // // //     required String label,
// // // // // // //     required TextEditingController controller,
// // // // // // //     required IconData icon,
// // // // // // //     bool readOnly = false,
// // // // // // //     TextInputType keyboardType = TextInputType.text,
// // // // // // //     Function(String)? onChanged,
// // // // // // //     String? Function(String?)? validator,
// // // // // // //   }) {
// // // // // // //     return TextFormField(
// // // // // // //       controller: controller,
// // // // // // //       readOnly: readOnly,
// // // // // // //       keyboardType: keyboardType,
// // // // // // //       onChanged: onChanged,
// // // // // // //       validator: validator,
// // // // // // //       decoration: InputDecoration(
// // // // // // //         labelText: label,
// // // // // // //         prefixIcon: Icon(icon, color: primaryColor),
// // // // // // //         border: OutlineInputBorder(
// // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // // //         ),
// // // // // // //         enabledBorder: OutlineInputBorder(
// // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // // //         ),
// // // // // // //         focusedBorder: OutlineInputBorder(
// // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // // // //         ),
// // // // // // //         filled: true,
// // // // // // //         fillColor: Colors.white,
// // // // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Dropdown stylisé pour le genre
// // // // // // //   Widget _buildGenderDropdown() {
// // // // // // //     return DropdownButtonFormField<String>(
// // // // // // //       value: selectedGender,
// // // // // // //       decoration: InputDecoration(
// // // // // // //         labelText: "Sexe",
// // // // // // //         prefixIcon: Icon(Icons.person, color: primaryColor),
// // // // // // //         border: OutlineInputBorder(
// // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // // //         ),
// // // // // // //         enabledBorder: OutlineInputBorder(
// // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // //           borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // // //         ),
// // // // // // //         focusedBorder: OutlineInputBorder(
// // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // //           borderSide: BorderSide(color: primaryColor, width: 2),
// // // // // // //         ),
// // // // // // //         filled: true,
// // // // // // //         fillColor: Colors.white,
// // // // // // //         contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // // // //       ),
// // // // // // //       items: genderOptions
// // // // // // //           .map((gender) => DropdownMenuItem(
// // // // // // //         value: gender,
// // // // // // //         child: Text(gender),
// // // // // // //       ))
// // // // // // //           .toList(),
// // // // // // //       onChanged: (value) {
// // // // // // //         setState(() {
// // // // // // //           selectedGender = value;
// // // // // // //         });
// // // // // // //       },
// // // // // // //       validator: (value) {
// // // // // // //         if (value == null || value.isEmpty) {
// // // // // // //           return 'Veuillez sélectionner votre genre';
// // // // // // //         }
// // // // // // //         return null;
// // // // // // //       },
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Date picker stylisé
// // // // // // //   Widget _buildDatePicker() {
// // // // // // //     return GestureDetector(
// // // // // // //       onTap: () async {
// // // // // // //         final selectedDate = await showDatePicker(
// // // // // // //           context: context,
// // // // // // //           initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans par défaut
// // // // // // //           firstDate: DateTime(1900),
// // // // // // //           lastDate: DateTime.now(),
// // // // // // //           builder: (context, child) {
// // // // // // //             return Theme(
// // // // // // //               data: Theme.of(context).copyWith(
// // // // // // //                 colorScheme: ColorScheme.light(
// // // // // // //                   primary: primaryColor,
// // // // // // //                   onPrimary: Colors.white,
// // // // // // //                   onSurface: Colors.black,
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //               child: child!,
// // // // // // //             );
// // // // // // //           },
// // // // // // //         );
// // // // // // //         if (selectedDate != null) {
// // // // // // //           setState(() {
// // // // // // //             birthDateController.text =
// // // // // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // // // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // // // // //                 "${selectedDate.year}";
// // // // // // //           });
// // // // // // //         }
// // // // // // //       },
// // // // // // //       child: AbsorbPointer(
// // // // // // //         child: TextFormField(
// // // // // // //           controller: birthDateController,
// // // // // // //           decoration: InputDecoration(
// // // // // // //             labelText: "Date de naissance",
// // // // // // //             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
// // // // // // //             border: OutlineInputBorder(
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // // //             ),
// // // // // // //             enabledBorder: OutlineInputBorder(
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //               borderSide: BorderSide(color: Colors.grey[300]!),
// // // // // // //             ),
// // // // // // //             focusedBorder: OutlineInputBorder(
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //               borderSide: BorderSide(color: primaryColor, width: 2),
// // // // // // //             ),
// // // // // // //             filled: true,
// // // // // // //             fillColor: Colors.white,
// // // // // // //             contentPadding: const EdgeInsets.symmetric(vertical: 16),
// // // // // // //           ),
// // // // // // //           validator: (value) {
// // // // // // //             if (value == null || value.isEmpty) {
// // // // // // //               return 'Veuillez entrer votre date de naissance';
// // // // // // //             }
// // // // // // //             if (!_isValidDate(value)) {
// // // // // // //               return 'Format invalide (JJ-MM-AAAA)';
// // // // // // //             }
// // // // // // //             return null;
// // // // // // //           },
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Boutons de navigation
// // // // // // //   Widget _buildNavigationButtons() {
// // // // // // //     final int totalSteps = isCoiffeuse ? 3 : 2;
// // // // // // //     return Row(
// // // // // // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // // // //       children: [
// // // // // // //         _currentStep > 0
// // // // // // //             ? ElevatedButton.icon(
// // // // // // //           icon: const Icon(Icons.arrow_back),
// // // // // // //           label: const Text("Précédent"),
// // // // // // //           onPressed: () {
// // // // // // //             setState(() {
// // // // // // //               _currentStep--;
// // // // // // //             });
// // // // // // //           },
// // // // // // //           style: ElevatedButton.styleFrom(
// // // // // // //             backgroundColor: Colors.grey[200],
// // // // // // //             foregroundColor: Colors.black87,
// // // // // // //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // // // // //             shape: RoundedRectangleBorder(
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         )
// // // // // // //             : const SizedBox(width: 120),
// // // // // // //         _currentStep < totalSteps - 1
// // // // // // //             ? ElevatedButton.icon(
// // // // // // //           icon: const Icon(Icons.arrow_forward),
// // // // // // //           label: const Text("Suivant"),
// // // // // // //           onPressed: () {
// // // // // // //             if (_validateCurrentStep()) {
// // // // // // //               setState(() {
// // // // // // //                 _currentStep++;
// // // // // // //               });
// // // // // // //             }
// // // // // // //           },
// // // // // // //           style: ElevatedButton.styleFrom(
// // // // // // //             backgroundColor: primaryColor,
// // // // // // //             foregroundColor: Colors.white,
// // // // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // // // //             shape: RoundedRectangleBorder(
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         )
// // // // // // //             : ElevatedButton.icon(
// // // // // // //           icon: const Icon(Icons.check),
// // // // // // //           label: const Text("Enregistrer"),
// // // // // // //           onPressed: () {
// // // // // // //             if (_validateCurrentStep()) {
// // // // // // //               _saveProfile();
// // // // // // //             }
// // // // // // //           },
// // // // // // //           style: ElevatedButton.styleFrom(
// // // // // // //             backgroundColor: secondaryColor,
// // // // // // //             foregroundColor: Colors.white,
// // // // // // //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // // // // //             shape: RoundedRectangleBorder(
// // // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       ],
// // // // // // //     );
// // // // // // //   }
// // // // // // //
// // // // // // //   // Validation de l'étape actuelle
// // // // // // //   bool _validateCurrentStep() {
// // // // // // //     return _formKey.currentState?.validate() ?? false;
// // // // // // //   }
// // // // // // //
// // // // // // //   // Méthode pour sélectionner une photo
// // // // // // //   Future<void> _pickPhoto() async {
// // // // // // //     try {
// // // // // // //       final result = await FilePicker.platform.pickFiles(
// // // // // // //         type: FileType.image,
// // // // // // //         allowMultiple: false,
// // // // // // //       );
// // // // // // //
// // // // // // //       if (result != null) {
// // // // // // //         setState(() {
// // // // // // //           if (kIsWeb) {
// // // // // // //             profilePhotoBytes = result.files.first.bytes;
// // // // // // //             profilePhoto = null;
// // // // // // //           } else {
// // // // // // //             profilePhoto = File(result.files.first.path!);
// // // // // // //             profilePhotoBytes = null;
// // // // // // //           }
// // // // // // //         });
// // // // // // //       }
// // // // // // //     } catch (e) {
// // // // // // //       if (mounted) {
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           SnackBar(
// // // // // // //             content: Text("Erreur lors de la sélection de la photo: $e"),
// // // // // // //             backgroundColor: Colors.red,
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }
// // // // // // //     }
// // // // // // //   }
// // // // // // //
// // // // // // //   // Validation du format de la date
// // // // // // //   bool _isValidDate(String date) {
// // // // // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // // // // //     if (!regex.hasMatch(date)) return false;
// // // // // // //
// // // // // // //     try {
// // // // // // //       final parts = date.split('-');
// // // // // // //       final day = int.parse(parts[0]);
// // // // // // //       final month = int.parse(parts[1]);
// // // // // // //       final year = int.parse(parts[2]);
// // // // // // //       final parsedDate = DateTime(year, month, day);
// // // // // // //       return parsedDate.year == year &&
// // // // // // //           parsedDate.month == month &&
// // // // // // //           parsedDate.day == day;
// // // // // // //     } catch (e) {
// // // // // // //       return false;
// // // // // // //     }
// // // // // // //   }
// // // // // // //
// // // // // // //   // Méthode pour récupérer la commune depuis le Code Postal
// // // // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // // // //     if (codePostal.length < 4) return;
// // // // // // //
// // // // // // //     final url = Uri.parse(
// // // // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // // // //
// // // // // // //     try {
// // // // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // // //       if (response.statusCode == 200) {
// // // // // // //         final data = json.decode(response.body) as List;
// // // // // // //         if (data.isNotEmpty) {
// // // // // // //           final addressDetailsUrl = Uri.parse(
// // // // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // // // //           final addressResponse = await http.get(addressDetailsUrl,
// // // // // // //               headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // // //           if (addressResponse.statusCode == 200) {
// // // // // // //             final addressData = json.decode(addressResponse.body);
// // // // // // //             if (mounted) {
// // // // // // //               setState(() {
// // // // // // //                 communeController.text = addressData['address']['city'] ??
// // // // // // //                     addressData['address']['town'] ??
// // // // // // //                     addressData['address']['village'] ??
// // // // // // //                     "Commune introuvable";
// // // // // // //               });
// // // // // // //             }
// // // // // // //           }
// // // // // // //         }
// // // // // // //       }
// // // // // // //     } catch (e) {
// // // // // // //       debugPrint("Erreur commune : $e");
// // // // // // //     }
// // // // // // //   }
// // // // // // //
// // // // // // //   // Sauvegarde du profil
// // // // // // //   void _saveProfile() async {
// // // // // // //     // Afficher un indicateur de chargement
// // // // // // //     showDialog(
// // // // // // //       context: context,
// // // // // // //       barrierDismissible: false,
// // // // // // //       builder: (context) => Center(
// // // // // // //         child: CircularProgressIndicator(
// // // // // // //           color: primaryColor,
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //
// // // // // // //     final url = Uri.parse("https://www.hairbnb.site/api/create-profile/");
// // // // // // //     var request = http.MultipartRequest('POST', url);
// // // // // // //
// // // // // // //     // Ajouter les champs de formulaire
// // // // // // //     request.fields['userUuid'] = userUuid;
// // // // // // //     request.fields['role'] = isCoiffeuse ? "coiffeuse" : "client";
// // // // // // //     request.fields['nom'] = nameController.text;
// // // // // // //     request.fields['prenom'] = surnameController.text;
// // // // // // //     request.fields['sexe'] = selectedGender?.toLowerCase() ?? "autre";
// // // // // // //     request.fields['code_postal'] = codePostalController.text;
// // // // // // //     request.fields['commune'] = communeController.text;
// // // // // // //     request.fields['rue'] = streetController.text;
// // // // // // //     request.fields['numero'] = streetNumberController.text;
// // // // // // //     request.fields['boite_postale'] = postalBoxController.text;
// // // // // // //     request.fields['telephone'] = phoneController.text;
// // // // // // //     request.fields['email'] = userEmail;
// // // // // // //     request.fields['date_naissance'] = birthDateController.text;
// // // // // // //
// // // // // // //     if (isCoiffeuse) {
// // // // // // //       request.fields['denomination_sociale'] = socialNameController.text;
// // // // // // //       request.fields['tva'] = tvaController.text;
// // // // // // //     }
// // // // // // //
// // // // // // //     // Ajouter le fichier si sélectionné
// // // // // // //     if (profilePhoto != null || profilePhotoBytes != null) {
// // // // // // //       if (kIsWeb && profilePhotoBytes != null) {
// // // // // // //         request.files.add(
// // // // // // //           http.MultipartFile.fromBytes(
// // // // // // //             'photo_profil',
// // // // // // //             profilePhotoBytes!,
// // // // // // //             filename: 'profile_photo.png',
// // // // // // //             contentType: MediaType('image', 'png'),
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       } else if (profilePhoto != null) {
// // // // // // //         request.files.add(
// // // // // // //           await http.MultipartFile.fromPath(
// // // // // // //             'photo_profil',
// // // // // // //             profilePhoto!.path,
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }
// // // // // // //     }
// // // // // // //
// // // // // // //     try {
// // // // // // //       final response = await request.send();
// // // // // // //       final responseBody = await response.stream.bytesToString();
// // // // // // //
// // // // // // //       // Fermer la boîte de dialogue de chargement
// // // // // // //       if (mounted) Navigator.of(context).pop();
// // // // // // //
// // // // // // //       if (!mounted) return;
// // // // // // //
// // // // // // //       if (response.statusCode == 201) {
// // // // // // //         // Animation de succès
// // // // // // //         _showSuccessDialog();
// // // // // // //
// // // // // // //         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // // // // // //         await userProvider.fetchCurrentUser();
// // // // // // //
// // // // // // //         if (!mounted) return;
// // // // // // //
// // // // // // //         if (isCoiffeuse) {
// // // // // // //           // Redirection vers la création de salon pour les coiffeuses
// // // // // // //           if (userProvider.currentUser != null) {
// // // // // // //             Navigator.push(
// // // // // // //               context,
// // // // // // //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// // // // // // //             );
// // // // // // //           }
// // // // // // //         } else {
// // // // // // //           // Redirection vers la page d'accueil pour les clients
// // // // // // //           Navigator.pushReplacement(
// // // // // // //             context,
// // // // // // //             MaterialPageRoute(builder: (_) => const HomePage()),
// // // // // // //           );
// // // // // // //         }
// // // // // // //       } else {
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           SnackBar(
// // // // // // //             content: Text("Erreur: $responseBody"),
// // // // // // //             backgroundColor: Colors.red,
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }
// // // // // // //     } catch (e) {
// // // // // // //       if (mounted) {
// // // // // // //         // Fermer la boîte de dialogue de chargement
// // // // // // //         Navigator.of(context).pop();
// // // // // // //
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           SnackBar(
// // // // // // //             content: Text("Erreur de connexion: $e"),
// // // // // // //             backgroundColor: Colors.red,
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       }
// // // // // // //     }
// // // // // // //   }
// // // // // // //
// // // // // // //   // Animation de succès
// // // // // // //   void _showSuccessDialog() {
// // // // // // //     showDialog(
// // // // // // //       context: context,
// // // // // // //       builder: (context) => AlertDialog(
// // // // // // //         shape: RoundedRectangleBorder(
// // // // // // //           borderRadius: BorderRadius.circular(20),
// // // // // // //         ),
// // // // // // //         title: Row(
// // // // // // //           children: [
// // // // // // //             Icon(Icons.check_circle, color: Colors.green, size: 30),
// // // // // // //             const SizedBox(width: 10),
// // // // // // //             const Text("Profil créé !"),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //         content: const Text(
// // // // // // //           "Votre profil a été créé avec succès.",
// // // // // // //           textAlign: TextAlign.center,
// // // // // // //         ),
// // // // // // //         actions: [
// // // // // // //           TextButton(
// // // // // // //             onPressed: () => Navigator.pop(context),
// // // // // // //             child: Text(
// // // // // // //               "Continuer",
// // // // // // //               style: TextStyle(color: primaryColor),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }
// // // // // // //
// // // // // // // //-----------------------------------------------Avant modernisation / avant token---------------------------
// // // // // // // // import 'dart:convert';
// // // // // // // // import 'dart:io';
// // // // // // // // import 'package:flutter/foundation.dart';
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:http/http.dart' as http;
// // // // // // // // import 'package:file_picker/file_picker.dart';
// // // // // // // // import 'package:http_parser/http_parser.dart';
// // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // import '../../services/providers/current_user_provider.dart';
// // // // // // // // import '../home_page.dart';
// // // // // // // // import '../salon/create_salon_page.dart';
// // // // // // // //
// // // // // // // // class ProfileCreationPage extends StatefulWidget {
// // // // // // // //   final String userUuid; // UUID Firebase
// // // // // // // //   final String email; // Email Firebase
// // // // // // // //
// // // // // // // //   const ProfileCreationPage({
// // // // // // // //     required this.userUuid,
// // // // // // // //     required this.email,
// // // // // // // //     super.key,
// // // // // // // //   });
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // // // // }
// // // // // // // //
// // // // // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // // // // //   // Nouveaux ajouts
// // // // // // // //   String? selectedGender; // Sexe sélectionné
// // // // // // // //   final List<String> genderOptions = ["Homme", "Femme"];
// // // // // // // //   Uint8List? profilePhotoBytes; // Pour les fichiers sur Web
// // // // // // // //   File? profilePhoto; // Pour les fichiers sur Mobile
// // // // // // // //
// // // // // // // //   // Controllers existants
// // // // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // // // //   final TextEditingController surnameController = TextEditingController();
// // // // // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // // // // //   final TextEditingController communeController = TextEditingController();
// // // // // // // //   final TextEditingController streetController = TextEditingController();
// // // // // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // // // // //   final TextEditingController phoneController = TextEditingController();
// // // // // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // // // // //   final TextEditingController tvaController = TextEditingController();
// // // // // // // //   final TextEditingController birthDateController = TextEditingController(); // Nouveau champ
// // // // // // // //
// // // // // // // //   bool isCoiffeuse = false; // Switch entre Coiffeuse et Client
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
// // // // // // // //     userEmail = widget.email;
// // // // // // // //     userUuid = widget.userUuid;
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   late String userEmail; // Stockage de l'email pour envoi au backend
// // // // // // // //   late String userUuid; // Stockage de l'UUID pour envoi au backend
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Scaffold(
// // // // // // // //       appBar: AppBar(
// // // // // // // //         title: const Text("Créer un profil"),
// // // // // // // //       ),
// // // // // // // //       body: SingleChildScrollView(
// // // // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // // // //         child: Column(
// // // // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //           children: [
// // // // // // // //             _buildSwitchRole(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Nom", nameController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Prénom", surnameController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildGenderDropdown(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildDatePicker(), // Champ pour la date de naissance
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildCodePostalField(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Commune", communeController, readOnly: true),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Rue", streetController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildStreetAndBoxRow(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Téléphone", phoneController,
// // // // // // // //                 keyboardType: TextInputType.phone),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildPhotoPicker(), // Champ pour sélectionner une photo
// // // // // // // //             if (isCoiffeuse) ...[
// // // // // // // //               const SizedBox(height: 10),
// // // // // // // //               _buildTextField("Dénomination Sociale", socialNameController),
// // // // // // // //               const SizedBox(height: 10),
// // // // // // // //               _buildTextField("Numéro TVA", tvaController),
// // // // // // // //             ],
// // // // // // // //             const SizedBox(height: 20),
// // // // // // // //             ElevatedButton(
// // // // // // // //               onPressed: _saveProfile,
// // // // // // // //
// // // // // // // //               child: const Text("Enregistrer"),
// // // // // // // //
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Liste déroulante pour le sexe
// // // // // // // //   Widget _buildGenderDropdown() {
// // // // // // // //     return DropdownButtonFormField<String>(
// // // // // // // //       value: selectedGender,
// // // // // // // //       decoration: const InputDecoration(
// // // // // // // //         labelText: "Sexe",
// // // // // // // //         border: OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //       items: genderOptions
// // // // // // // //           .map((gender) => DropdownMenuItem(
// // // // // // // //         value: gender,
// // // // // // // //         child: Text(gender),
// // // // // // // //       ))
// // // // // // // //           .toList(),
// // // // // // // //       onChanged: (value) {
// // // // // // // //         setState(() {
// // // // // // // //           selectedGender = value;
// // // // // // // //         });
// // // // // // // //       },
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Switch entre Client et Coiffeuse
// // // // // // // //   Widget _buildSwitchRole() {
// // // // // // // //     return Row(
// // // // // // // //       children: [
// // // // // // // //         const Text("Client"),
// // // // // // // //         Switch(
// // // // // // // //           value: isCoiffeuse,
// // // // // // // //           onChanged: (value) {
// // // // // // // //             setState(() {
// // // // // // // //               isCoiffeuse = value;
// // // // // // // //             });
// // // // // // // //           },
// // // // // // // //         ),
// // // // // // // //         const Text("Coiffeuse"),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour Code Postal
// // // // // // // //   Widget _buildCodePostalField() {
// // // // // // // //     return TextField(
// // // // // // // //       controller: codePostalController,
// // // // // // // //       keyboardType: TextInputType.number,
// // // // // // // //       decoration: const InputDecoration(
// // // // // // // //         labelText: "Code Postal",
// // // // // // // //         border: OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //       onChanged: (value) => fetchCommune(value),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Sélecteur de date pour la date de naissance
// // // // // // // //   Widget _buildDatePicker() {
// // // // // // // //     return GestureDetector(
// // // // // // // //       onTap: () async {
// // // // // // // //         final selectedDate = await showDatePicker(
// // // // // // // //           context: context,
// // // // // // // //           initialDate: DateTime.now(),
// // // // // // // //           firstDate: DateTime(1900),
// // // // // // // //           lastDate: DateTime.now(),
// // // // // // // //         );
// // // // // // // //         if (selectedDate != null) {
// // // // // // // //           setState(() {
// // // // // // // //             birthDateController.text =
// // // // // // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // // // // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // // // // // //                 "${selectedDate.year}";
// // // // // // // //           });
// // // // // // // //         }
// // // // // // // //       },
// // // // // // // //       child: AbsorbPointer(
// // // // // // // //         child: TextField(
// // // // // // // //           controller: birthDateController,
// // // // // // // //           decoration: const InputDecoration(
// // // // // // // //             labelText: "Date de naissance (DD-MM-YYYY)",
// // // // // // // //             border: OutlineInputBorder(),
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour Numéro et Boîte sur la même ligne
// // // // // // // //   Widget _buildStreetAndBoxRow() {
// // // // // // // //     return Row(
// // // // // // // //       children: [
// // // // // // // //         Expanded(
// // // // // // // //           child: _buildTextField("Numéro", streetNumberController),
// // // // // // // //         ),
// // // // // // // //         const SizedBox(width: 10),
// // // // // // // //         Expanded(
// // // // // // // //           child: _buildTextField("N° Boîte", postalBoxController),
// // // // // // // //         ),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour sélectionner une photo
// // // // // // // //   Widget _buildPhotoPicker() {
// // // // // // // //     return Column(
// // // // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //       children: [
// // // // // // // //         const Text("Photo de profil"),
// // // // // // // //         const SizedBox(height: 10),
// // // // // // // //         Row(
// // // // // // // //           children: [
// // // // // // // //             ElevatedButton(
// // // // // // // //               onPressed: _pickPhoto,
// // // // // // // //               child: const Text("Choisir une photo"),
// // // // // // // //             ),
// // // // // // // //             const SizedBox(width: 10),
// // // // // // // //             Container(
// // // // // // // //               width: 100,
// // // // // // // //               height: 100,
// // // // // // // //               decoration: BoxDecoration(
// // // // // // // //                 border: Border.all(color: Colors.grey),
// // // // // // // //                 borderRadius: BorderRadius.circular(10),
// // // // // // // //               ),
// // // // // // // //               child: profilePhotoBytes != null
// // // // // // // //                   ? ClipRRect(
// // // // // // // //                 borderRadius: BorderRadius.circular(10),
// // // // // // // //                 child: Image.memory(
// // // // // // // //                   profilePhotoBytes!,
// // // // // // // //                   fit: BoxFit.cover,
// // // // // // // //                 ),
// // // // // // // //               )
// // // // // // // //                   : profilePhoto != null
// // // // // // // //                   ? ClipRRect(
// // // // // // // //                 borderRadius: BorderRadius.circular(10),
// // // // // // // //                 child: Image.file(
// // // // // // // //                   profilePhoto!,
// // // // // // // //                   fit: BoxFit.cover,
// // // // // // // //                 ),
// // // // // // // //               )
// // // // // // // //                   : const Center(
// // // // // // // //                 child: Text(
// // // // // // // //                   "Aucune image",
// // // // // // // //                   textAlign: TextAlign.center,
// // // // // // // //                   style: TextStyle(fontSize: 12),
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //   /// Méthode pour sélectionner une photo
// // // // // // // //   Future<void> _pickPhoto() async {
// // // // // // // //     final result = await FilePicker.platform.pickFiles(type: FileType.image);
// // // // // // // //
// // // // // // // //     if (result != null) {
// // // // // // // //       setState(() {
// // // // // // // //         if (kIsWeb) {
// // // // // // // //           // Web : Utilisez les bytes
// // // // // // // //           profilePhotoBytes = result.files.first.bytes;
// // // // // // // //           profilePhoto = null; // Reset de la variable File
// // // // // // // //         } else {
// // // // // // // //           // Mobile/Desktop : Utilisez le chemin pour créer un objet File
// // // // // // // //           profilePhoto = File(result.files.first.path!);
// // // // // // // //           profilePhotoBytes = null; // Reset de la variable Uint8List
// // // // // // // //         }
// // // // // // // //       });
// // // // // // // //     } else {
// // // // // // // //       debugPrint("Aucune photo sélectionnée.");
// // // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //         const SnackBar(content: Text("Aucune photo sélectionnée.")),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //
// // // // // // // //   void _saveProfile() async {
// // // // // // // //     if (!_isValidDate(birthDateController.text)) {
// // // // // // // //       if (mounted) {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text("Le format de la date de naissance doit être DD-MM-YYYY.")),
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //       return;
// // // // // // // //     }
// // // // // // // //
// // // // // // // //     final url = Uri.parse("https://www.hairbnb.site/api/create-profile/");
// // // // // // // //     var request = http.MultipartRequest('POST', url);
// // // // // // // //
// // // // // // // //     // Ajouter les champs de formulaire
// // // // // // // //     request.fields['userUuid'] = userUuid;
// // // // // // // //     request.fields['role'] = isCoiffeuse ? "coiffeuse" : "client";
// // // // // // // //     request.fields['nom'] = nameController.text;
// // // // // // // //     request.fields['prenom'] = surnameController.text;
// // // // // // // //     request.fields['sexe'] = selectedGender?.toLowerCase() ?? "autre";
// // // // // // // //     request.fields['code_postal'] = codePostalController.text;
// // // // // // // //     request.fields['commune'] = communeController.text;
// // // // // // // //     request.fields['rue'] = streetController.text;
// // // // // // // //     request.fields['numero'] = streetNumberController.text;
// // // // // // // //     request.fields['boite_postale'] = postalBoxController.text;
// // // // // // // //     request.fields['telephone'] = phoneController.text;
// // // // // // // //     request.fields['email'] = userEmail;
// // // // // // // //     request.fields['date_naissance'] = birthDateController.text;
// // // // // // // //
// // // // // // // //     if (isCoiffeuse) {
// // // // // // // //       request.fields['denomination_sociale'] = socialNameController.text;
// // // // // // // //       request.fields['tva'] = tvaController.text;
// // // // // // // //     }
// // // // // // // //
// // // // // // // //     // Ajouter le fichier si sélectionné
// // // // // // // //     if (profilePhoto != null || profilePhotoBytes != null) {
// // // // // // // //       if (kIsWeb && profilePhotoBytes != null) {
// // // // // // // //         request.files.add(
// // // // // // // //           http.MultipartFile.fromBytes(
// // // // // // // //             'photo_profil',
// // // // // // // //             profilePhotoBytes!,
// // // // // // // //             filename: 'profile_photo.png',
// // // // // // // //             contentType: MediaType('image', 'png'),
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       } else if (profilePhoto != null) {
// // // // // // // //         request.files.add(
// // // // // // // //           await http.MultipartFile.fromPath(
// // // // // // // //             'photo_profil',
// // // // // // // //             profilePhoto!.path,
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //     }
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final response = await request.send();
// // // // // // // //       final responseBody = await response.stream.bytesToString();
// // // // // // // //
// // // // // // // //       if (!mounted) return; // 🔥 Vérifie si le widget est encore actif avant d'utiliser `context`
// // // // // // // //
// // // // // // // //       if (response.statusCode == 201) {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text("Profil créé avec succès!")),
// // // // // // // //         );
// // // // // // // //
// // // // // // // //         if (isCoiffeuse) {
// // // // // // // //           final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // // // // // // //           await userProvider.fetchCurrentUser(); // 🔄 Mettre à jour le profil
// // // // // // // //
// // // // // // // //           if (mounted && userProvider.currentUser != null) {
// // // // // // // //             // 🔥 Vérifie encore si le widget est monté avant de naviguer
// // // // // // // //             Navigator.push(
// // // // // // // //               context,
// // // // // // // //               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
// // // // // // // //             );
// // // // // // // //           }
// // // // // // // //         } else {
// // // // // // // //
// // // // // // // //           final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // // // // // // //           await userProvider.fetchCurrentUser(); // 🔄 Mettre à jour le profil
// // // // // // // //
// // // // // // // //           if (mounted && userProvider.currentUser != null) {
// // // // // // // //             // 🔥 Vérifie encore si le widget est monté avant de naviguer
// // // // // // // //             Navigator.pushReplacement(
// // // // // // // //               context,
// // // // // // // //               MaterialPageRoute(builder: (_) => const HomePage()),
// // // // // // // //             );
// // // // // // // //           }
// // // // // // // //
// // // // // // // //           ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //             const SnackBar(content: Text("Bienvenue! Votre profil a été créé.")),
// // // // // // // //           );
// // // // // // // //         }
// // // // // // // //       } else {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           SnackBar(content: Text("Erreur lors de la création du profil : $responseBody")),
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //     } catch (e) {
// // // // // // // //       if (mounted) {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //   /// Validation du format de la date
// // // // // // // //   bool _isValidDate(String date) {
// // // // // // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // // // // // //     if (!regex.hasMatch(date)) return false;
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final parts = date.split('-');
// // // // // // // //       final day = int.parse(parts[0]);
// // // // // // // //       final month = int.parse(parts[1]);
// // // // // // // //       final year = int.parse(parts[2]);
// // // // // // // //       final parsedDate = DateTime(year, month, day);
// // // // // // // //       return parsedDate.year == year &&
// // // // // // // //           parsedDate.month == month &&
// // // // // // // //           parsedDate.day == day;
// // // // // // // //     } catch (e) {
// // // // // // // //       return false;
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Fonction générique pour TextField
// // // // // // // //   Widget _buildTextField(String label, TextEditingController controller,
// // // // // // // //       {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
// // // // // // // //     return TextField(
// // // // // // // //       controller: controller,
// // // // // // // //       readOnly: readOnly,
// // // // // // // //       keyboardType: keyboardType,
// // // // // // // //       decoration: InputDecoration(
// // // // // // // //         labelText: label,
// // // // // // // //         border: const OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Méthode pour récupérer la commune depuis le Code Postal
// // // // // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // // // // //     final url = Uri.parse(
// // // // // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // // // //       if (response.statusCode == 200) {
// // // // // // // //         final data = json.decode(response.body) as List;
// // // // // // // //         if (data.isNotEmpty) {
// // // // // // // //           final addressDetailsUrl = Uri.parse(
// // // // // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // // // // //           final addressResponse = await http.get(addressDetailsUrl);
// // // // // // // //           if (addressResponse.statusCode == 200) {
// // // // // // // //             final addressData = json.decode(addressResponse.body);
// // // // // // // //             setState(() {
// // // // // // // //               communeController.text = addressData['address']['city'] ??
// // // // // // // //                   addressData['address']['town'] ??
// // // // // // // //                   addressData['address']['village'] ??
// // // // // // // //                   "Commune introuvable";
// // // // // // // //             });
// // // // // // // //           }
// // // // // // // //         }
// // // // // // // //       }
// // // // // // // //     } catch (e) {
// // // // // // // //       debugPrint("Erreur commune : $e");
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // // }
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // // // import 'dart:convert';
// // // // // // // // import 'dart:io';
// // // // // // // // import 'package:flutter/foundation.dart';
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:http/http.dart' as http;
// // // // // // // // import 'package:file_picker/file_picker.dart';
// // // // // // // //
// // // // // // // // class ProfileCreationPage extends StatefulWidget {
// // // // // // // //   final String userUuid; // UUID Firebase
// // // // // // // //   final String email; // Email Firebase
// // // // // // // //
// // // // // // // //   const ProfileCreationPage({
// // // // // // // //     required this.userUuid,
// // // // // // // //     required this.email,
// // // // // // // //     super.key,
// // // // // // // //   });
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // // // // }
// // // // // // // //
// // // // // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // // // // //   // Nouveaux ajouts
// // // // // // // //   String? selectedGender; // Sexe sélectionné
// // // // // // // //   final List<String> genderOptions = ["Homme", "Femme", "Autre"];
// // // // // // // //   File? profilePhoto; // Fichier pour la photo de profil
// // // // // // // //
// // // // // // // //   // Controllers existants
// // // // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // // // //   final TextEditingController surnameController = TextEditingController();
// // // // // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // // // // //   final TextEditingController communeController = TextEditingController();
// // // // // // // //   final TextEditingController streetController = TextEditingController();
// // // // // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // // // // //   final TextEditingController phoneController = TextEditingController();
// // // // // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // // // // //   final TextEditingController tvaController = TextEditingController();
// // // // // // // //   final TextEditingController birthDateController = TextEditingController(); // Nouveau champ
// // // // // // // //
// // // // // // // //   bool isCoiffeuse = false; // Switch entre Coiffeuse et Client
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
// // // // // // // //     userEmail = widget.email;
// // // // // // // //     userUuid = widget.userUuid;
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   late String userEmail; // Stockage de l'email pour envoi au backend
// // // // // // // //   late String userUuid; // Stockage de l'UUID pour envoi au backend
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Scaffold(
// // // // // // // //       appBar: AppBar(
// // // // // // // //         title: const Text("Créer un profil"),
// // // // // // // //       ),
// // // // // // // //       body: SingleChildScrollView(
// // // // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // // // //         child: Column(
// // // // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //           children: [
// // // // // // // //             _buildSwitchRole(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Nom", nameController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Prénom", surnameController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildGenderDropdown(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildDatePicker(), // Champ pour la date de naissance
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildCodePostalField(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Commune", communeController, readOnly: true),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Rue", streetController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildStreetAndBoxRow(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Téléphone", phoneController,
// // // // // // // //                 keyboardType: TextInputType.phone),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildPhotoPicker(), // Champ pour sélectionner une photo
// // // // // // // //             if (isCoiffeuse) ...[
// // // // // // // //               const SizedBox(height: 10),
// // // // // // // //               _buildTextField("Dénomination Sociale", socialNameController),
// // // // // // // //               const SizedBox(height: 10),
// // // // // // // //               _buildTextField("Numéro TVA", tvaController),
// // // // // // // //             ],
// // // // // // // //             const SizedBox(height: 20),
// // // // // // // //             ElevatedButton(
// // // // // // // //               onPressed: _saveProfile,
// // // // // // // //               child: const Text("Enregistrer"),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Liste déroulante pour le sexe
// // // // // // // //   Widget _buildGenderDropdown() {
// // // // // // // //     return DropdownButtonFormField<String>(
// // // // // // // //       value: selectedGender,
// // // // // // // //       decoration: const InputDecoration(
// // // // // // // //         labelText: "Sexe",
// // // // // // // //         border: OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //       items: genderOptions
// // // // // // // //           .map((gender) => DropdownMenuItem(
// // // // // // // //         value: gender,
// // // // // // // //         child: Text(gender),
// // // // // // // //       ))
// // // // // // // //           .toList(),
// // // // // // // //       onChanged: (value) {
// // // // // // // //         setState(() {
// // // // // // // //           selectedGender = value;
// // // // // // // //         });
// // // // // // // //       },
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Switch entre Client et Coiffeuse
// // // // // // // //   Widget _buildSwitchRole() {
// // // // // // // //     return Row(
// // // // // // // //       children: [
// // // // // // // //         const Text("Client"),
// // // // // // // //         Switch(
// // // // // // // //           value: isCoiffeuse,
// // // // // // // //           onChanged: (value) {
// // // // // // // //             setState(() {
// // // // // // // //               isCoiffeuse = value;
// // // // // // // //             });
// // // // // // // //           },
// // // // // // // //         ),
// // // // // // // //         const Text("Coiffeuse"),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour Code Postal
// // // // // // // //   Widget _buildCodePostalField() {
// // // // // // // //     return TextField(
// // // // // // // //       controller: codePostalController,
// // // // // // // //       keyboardType: TextInputType.number,
// // // // // // // //       decoration: const InputDecoration(
// // // // // // // //         labelText: "Code Postal",
// // // // // // // //         border: OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //       onChanged: (value) => fetchCommune(value),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Sélecteur de date pour la date de naissance
// // // // // // // //   Widget _buildDatePicker() {
// // // // // // // //     return GestureDetector(
// // // // // // // //       onTap: () async {
// // // // // // // //         final selectedDate = await showDatePicker(
// // // // // // // //           context: context,
// // // // // // // //           initialDate: DateTime.now(),
// // // // // // // //           firstDate: DateTime(1900),
// // // // // // // //           lastDate: DateTime.now(),
// // // // // // // //         );
// // // // // // // //         if (selectedDate != null) {
// // // // // // // //           setState(() {
// // // // // // // //             birthDateController.text =
// // // // // // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // // // // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // // // // // //                 "${selectedDate.year}";
// // // // // // // //           });
// // // // // // // //         }
// // // // // // // //       },
// // // // // // // //       child: AbsorbPointer(
// // // // // // // //         child: TextField(
// // // // // // // //           controller: birthDateController,
// // // // // // // //           decoration: const InputDecoration(
// // // // // // // //             labelText: "Date de naissance (DD-MM-YYYY)",
// // // // // // // //             border: OutlineInputBorder(),
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour Numéro et Boîte sur la même ligne
// // // // // // // //   Widget _buildStreetAndBoxRow() {
// // // // // // // //     return Row(
// // // // // // // //       children: [
// // // // // // // //         Expanded(
// // // // // // // //           child: _buildTextField("Numéro", streetNumberController),
// // // // // // // //         ),
// // // // // // // //         const SizedBox(width: 10),
// // // // // // // //         Expanded(
// // // // // // // //           child: _buildTextField("N° Boîte", postalBoxController),
// // // // // // // //         ),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour sélectionner une photo
// // // // // // // //   Widget _buildPhotoPicker() {
// // // // // // // //     return Column(
// // // // // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //       children: [
// // // // // // // //         const Text("Photo de profil"),
// // // // // // // //         const SizedBox(height: 10),
// // // // // // // //         Row(
// // // // // // // //           children: [
// // // // // // // //             ElevatedButton(
// // // // // // // //               onPressed: _pickPhoto,
// // // // // // // //               child: const Text("Choisir une photo"),
// // // // // // // //             ),
// // // // // // // //             const SizedBox(width: 10),
// // // // // // // //             Text(
// // // // // // // //               profilePhoto != null
// // // // // // // //                   ? profilePhoto!.path.split('/').last
// // // // // // // //                   : "Aucune photo sélectionnée",
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Méthode pour sélectionner une photo
// // // // // // // //   Future<void> _pickPhoto() async {
// // // // // // // //     final result = await FilePicker.platform.pickFiles(type: FileType.image);
// // // // // // // //
// // // // // // // //     if (result != null) {
// // // // // // // //       setState(() {
// // // // // // // //         if (kIsWeb) {
// // // // // // // //           // Web : utiliser bytes
// // // // // // // //           print("Bytes : ${result.files.first.bytes}");
// // // // // // // //         } else {
// // // // // // // //           // Mobile/Desktop : utiliser path
// // // // // // // //           print("Path : ${result.files.first.path}");
// // // // // // // //         }
// // // // // // // //       });
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //   /// Méthode pour sauvegarder le profil
// // // // // // // //   void _saveProfile() async {
// // // // // // // //     if (!_isValidDate(birthDateController.text)) {
// // // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //         const SnackBar(
// // // // // // // //           content: Text("Le format de la date de naissance doit être DD-MM-YYYY."),
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //       return;
// // // // // // // //     }
// // // // // // // //
// // // // // // // //     final url = Uri.parse("http://192.168.0.202:8000/api/create-profile/");
// // // // // // // //     var request = http.MultipartRequest('POST', url);
// // // // // // // //
// // // // // // // //     // Ajouter les champs de formulaire
// // // // // // // //     request.fields['userUuid'] = userUuid;
// // // // // // // //     request.fields['role'] = isCoiffeuse ? "coiffeuse" : "client";
// // // // // // // //     request.fields['nom'] = nameController.text;
// // // // // // // //     request.fields['prenom'] = surnameController.text;
// // // // // // // //     request.fields['sexe'] = selectedGender?.toLowerCase() ?? "autre";
// // // // // // // //     request.fields['code_postal'] = codePostalController.text;
// // // // // // // //     request.fields['commune'] = communeController.text;
// // // // // // // //     request.fields['rue'] = streetController.text;
// // // // // // // //     request.fields['numero'] = streetNumberController.text;
// // // // // // // //     request.fields['boite_postale'] = postalBoxController.text;
// // // // // // // //     request.fields['telephone'] = phoneController.text;
// // // // // // // //     request.fields['email'] = userEmail;
// // // // // // // //     request.fields['date_naissance'] = birthDateController.text;
// // // // // // // //
// // // // // // // //     if (isCoiffeuse) {
// // // // // // // //       request.fields['denomination_sociale'] = socialNameController.text;
// // // // // // // //       request.fields['tva'] = tvaController.text;
// // // // // // // //     }
// // // // // // // //
// // // // // // // //     // Ajouter le fichier si sélectionné
// // // // // // // //     if (profilePhoto != null) {
// // // // // // // //       request.files.add(
// // // // // // // //         await http.MultipartFile.fromPath('photo_profil', profilePhoto!.path),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final response = await request.send();
// // // // // // // //       if (response.statusCode == 201) {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text("Profil créé avec succès!")),
// // // // // // // //         );
// // // // // // // //       } else {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text("Erreur lors de la création du profil.")),
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //     } catch (e) {
// // // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Validation du format de la date
// // // // // // // //   bool _isValidDate(String date) {
// // // // // // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // // // // // //     if (!regex.hasMatch(date)) return false;
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final parts = date.split('-');
// // // // // // // //       final day = int.parse(parts[0]);
// // // // // // // //       final month = int.parse(parts[1]);
// // // // // // // //       final year = int.parse(parts[2]);
// // // // // // // //       final parsedDate = DateTime(year, month, day);
// // // // // // // //       return parsedDate.year == year &&
// // // // // // // //           parsedDate.month == month &&
// // // // // // // //           parsedDate.day == day;
// // // // // // // //     } catch (e) {
// // // // // // // //       return false;
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Fonction générique pour TextField
// // // // // // // //   Widget _buildTextField(String label, TextEditingController controller,
// // // // // // // //       {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
// // // // // // // //     return TextField(
// // // // // // // //       controller: controller,
// // // // // // // //       readOnly: readOnly,
// // // // // // // //       keyboardType: keyboardType,
// // // // // // // //       decoration: InputDecoration(
// // // // // // // //         labelText: label,
// // // // // // // //         border: const OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Méthode pour récupérer la commune depuis le Code Postal
// // // // // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // // // // //     final url = Uri.parse(
// // // // // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // // // //       if (response.statusCode == 200) {
// // // // // // // //         final data = json.decode(response.body) as List;
// // // // // // // //         if (data.isNotEmpty) {
// // // // // // // //           final addressDetailsUrl = Uri.parse(
// // // // // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // // // // //           final addressResponse = await http.get(addressDetailsUrl);
// // // // // // // //           if (addressResponse.statusCode == 200) {
// // // // // // // //             final addressData = json.decode(addressResponse.body);
// // // // // // // //             setState(() {
// // // // // // // //               communeController.text = addressData['address']['city'] ??
// // // // // // // //                   addressData['address']['town'] ??
// // // // // // // //                   addressData['address']['village'] ??
// // // // // // // //                   "Commune introuvable";
// // // // // // // //             });
// // // // // // // //           }
// // // // // // // //         }
// // // // // // // //       }
// // // // // // // //     } catch (e) {
// // // // // // // //       debugPrint("Erreur commune : $e");
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // // }
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // //
// // // // // // // // import 'dart:convert';
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:http/http.dart' as http;
// // // // // // // //
// // // // // // // // class ProfileCreationPage extends StatefulWidget {
// // // // // // // //   final String userUuid; // UUID Firebase
// // // // // // // //   final String email; // Email Firebase
// // // // // // // //
// // // // // // // //   const ProfileCreationPage({
// // // // // // // //     required this.userUuid,
// // // // // // // //     required this.email,
// // // // // // // //     super.key,
// // // // // // // //   });
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // // // // }
// // // // // // // //
// // // // // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // // // // //   // Nouveaux ajouts
// // // // // // // //   String? selectedGender; // Sexe sélectionné
// // // // // // // //   final List<String> genderOptions = ["Homme", "Femme", "Autre"];
// // // // // // // //
// // // // // // // //   // Controllers existants
// // // // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // // // //   final TextEditingController surnameController = TextEditingController();
// // // // // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // // // // //   final TextEditingController communeController = TextEditingController();
// // // // // // // //   final TextEditingController streetController = TextEditingController();
// // // // // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // // // // //   final TextEditingController phoneController = TextEditingController();
// // // // // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // // // // //   final TextEditingController tvaController = TextEditingController();
// // // // // // // //   final TextEditingController birthDateController = TextEditingController(); // Nouveau champ
// // // // // // // //
// // // // // // // //   bool isCoiffeuse = false; // Switch entre Coiffeuse et Client
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
// // // // // // // //     userEmail = widget.email;
// // // // // // // //     userUuid = widget.userUuid;
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   late String userEmail; // Stockage de l'email pour envoi au backend
// // // // // // // //   late String userUuid; // Stockage de l'UUID pour envoi au backend
// // // // // // // //
// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Scaffold(
// // // // // // // //       appBar: AppBar(
// // // // // // // //         title: const Text("Créer un profil"),
// // // // // // // //       ),
// // // // // // // //       body: SingleChildScrollView(
// // // // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // // // //         child: Column(
// // // // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //           children: [
// // // // // // // //             _buildSwitchRole(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Nom", nameController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Prénom", surnameController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildGenderDropdown(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildDatePicker(), // Champ pour la date de naissance
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildCodePostalField(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Commune", communeController, readOnly: true),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Rue", streetController),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildStreetAndBoxRow(),
// // // // // // // //             const SizedBox(height: 10),
// // // // // // // //             _buildTextField("Téléphone", phoneController,
// // // // // // // //                 keyboardType: TextInputType.phone),
// // // // // // // //             if (isCoiffeuse) ...[
// // // // // // // //               const SizedBox(height: 10),
// // // // // // // //               _buildTextField("Dénomination Sociale", socialNameController),
// // // // // // // //               const SizedBox(height: 10),
// // // // // // // //               _buildTextField("Numéro TVA", tvaController),
// // // // // // // //             ],
// // // // // // // //             const SizedBox(height: 20),
// // // // // // // //             ElevatedButton(
// // // // // // // //               onPressed: _saveProfile,
// // // // // // // //               child: const Text("Enregistrer"),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Liste déroulante pour le sexe
// // // // // // // //   Widget _buildGenderDropdown() {
// // // // // // // //     return DropdownButtonFormField<String>(
// // // // // // // //       value: selectedGender,
// // // // // // // //       decoration: const InputDecoration(
// // // // // // // //         labelText: "Sexe",
// // // // // // // //         border: OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //       items: genderOptions
// // // // // // // //           .map((gender) => DropdownMenuItem(
// // // // // // // //         value: gender,
// // // // // // // //         child: Text(gender),
// // // // // // // //       ))
// // // // // // // //           .toList(),
// // // // // // // //       onChanged: (value) {
// // // // // // // //         setState(() {
// // // // // // // //           selectedGender = value;
// // // // // // // //         });
// // // // // // // //       },
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Switch entre Client et Coiffeuse
// // // // // // // //   Widget _buildSwitchRole() {
// // // // // // // //     return Row(
// // // // // // // //       children: [
// // // // // // // //         const Text("Client"),
// // // // // // // //         Switch(
// // // // // // // //           value: isCoiffeuse,
// // // // // // // //           onChanged: (value) {
// // // // // // // //             setState(() {
// // // // // // // //               isCoiffeuse = value;
// // // // // // // //             });
// // // // // // // //           },
// // // // // // // //         ),
// // // // // // // //         const Text("Coiffeuse"),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour Code Postal
// // // // // // // //   Widget _buildCodePostalField() {
// // // // // // // //     return TextField(
// // // // // // // //       controller: codePostalController,
// // // // // // // //       keyboardType: TextInputType.number,
// // // // // // // //       decoration: const InputDecoration(
// // // // // // // //         labelText: "Code Postal",
// // // // // // // //         border: OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //       onChanged: (value) => fetchCommune(value),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Sélecteur de date pour la date de naissance
// // // // // // // //   Widget _buildDatePicker() {
// // // // // // // //     return GestureDetector(
// // // // // // // //       onTap: () async {
// // // // // // // //         final selectedDate = await showDatePicker(
// // // // // // // //           context: context,
// // // // // // // //           initialDate: DateTime.now(),
// // // // // // // //           firstDate: DateTime(1900),
// // // // // // // //           lastDate: DateTime.now(),
// // // // // // // //         );
// // // // // // // //         if (selectedDate != null) {
// // // // // // // //           setState(() {
// // // // // // // //             birthDateController.text =
// // // // // // // //             "${selectedDate.day.toString().padLeft(2, '0')}-"
// // // // // // // //                 "${selectedDate.month.toString().padLeft(2, '0')}-"
// // // // // // // //                 "${selectedDate.year}";
// // // // // // // //           });
// // // // // // // //         }
// // // // // // // //       },
// // // // // // // //       child: AbsorbPointer(
// // // // // // // //         child: TextField(
// // // // // // // //           controller: birthDateController,
// // // // // // // //           decoration: const InputDecoration(
// // // // // // // //             labelText: "Date de naissance (DD-MM-YYYY)",
// // // // // // // //             border: OutlineInputBorder(),
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Widget pour Numéro et Boîte sur la même ligne
// // // // // // // //   Widget _buildStreetAndBoxRow() {
// // // // // // // //     return Row(
// // // // // // // //       children: [
// // // // // // // //         Expanded(
// // // // // // // //           child: _buildTextField("Numéro", streetNumberController),
// // // // // // // //         ),
// // // // // // // //         const SizedBox(width: 10),
// // // // // // // //         Expanded(
// // // // // // // //           child: _buildTextField("N° Boîte", postalBoxController),
// // // // // // // //         ),
// // // // // // // //       ],
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Méthode pour sauvegarder le profil
// // // // // // // //   void _saveProfile() async {
// // // // // // // //     if (!_isValidDate(birthDateController.text)) {
// // // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //         const SnackBar(
// // // // // // // //           content: Text("Le format de la date de naissance doit être DD-MM-YYYY."),
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //       return;
// // // // // // // //     }
// // // // // // // //
// // // // // // // //     final url = Uri.parse("http://192.168.0.202:8000/api/create-profile/");
// // // // // // // //     final Map<String, dynamic> data = {
// // // // // // // //       "userUuid": userUuid,
// // // // // // // //       "role": isCoiffeuse ? "coiffeuse" : "client",
// // // // // // // //       "nom": nameController.text,
// // // // // // // //       "prenom": surnameController.text,
// // // // // // // //       "sexe": selectedGender?.toLowerCase(),
// // // // // // // //       "code_postal": codePostalController.text,
// // // // // // // //       "commune": communeController.text,
// // // // // // // //       "rue": streetController.text,
// // // // // // // //       "numero": streetNumberController.text,
// // // // // // // //       "boite_postale": postalBoxController.text,
// // // // // // // //       "telephone": phoneController.text,
// // // // // // // //       "email": userEmail,
// // // // // // // //       "denomination_sociale": isCoiffeuse ? socialNameController.text : null,
// // // // // // // //       "tva": isCoiffeuse ? tvaController.text : null,
// // // // // // // //       "date_naissance": birthDateController.text,
// // // // // // // //     };
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final response = await http.post(
// // // // // // // //         url,
// // // // // // // //         headers: {"Content-Type": "application/json"},
// // // // // // // //         body: jsonEncode(data),
// // // // // // // //       );
// // // // // // // //
// // // // // // // //       if (response.statusCode == 201) {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text("Profil créé avec succès!")),
// // // // // // // //         );
// // // // // // // //       } else {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text("Erreur lors de la création du profil.")),
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //     } catch (e) {
// // // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Validation du format de la date
// // // // // // // //   bool _isValidDate(String date) {
// // // // // // // //     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
// // // // // // // //     if (!regex.hasMatch(date)) return false;
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final parts = date.split('-');
// // // // // // // //       final day = int.parse(parts[0]);
// // // // // // // //       final month = int.parse(parts[1]);
// // // // // // // //       final year = int.parse(parts[2]);
// // // // // // // //       final parsedDate = DateTime(year, month, day);
// // // // // // // //       return parsedDate.year == year && parsedDate.month == month && parsedDate.day == day;
// // // // // // // //     } catch (e) {
// // // // // // // //       return false;
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Fonction générique pour TextField
// // // // // // // //   Widget _buildTextField(String label, TextEditingController controller,
// // // // // // // //       {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
// // // // // // // //     return TextField(
// // // // // // // //       controller: controller,
// // // // // // // //       readOnly: readOnly,
// // // // // // // //       keyboardType: keyboardType,
// // // // // // // //       decoration: InputDecoration(
// // // // // // // //         labelText: label,
// // // // // // // //         border: const OutlineInputBorder(),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // //
// // // // // // // //   /// Méthode pour récupérer la commune depuis le Code Postal
// // // // // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // // // // //     final url = Uri.parse(
// // // // // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // // // // //
// // // // // // // //     try {
// // // // // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // // // //       if (response.statusCode == 200) {
// // // // // // // //         final data = json.decode(response.body) as List;
// // // // // // // //         if (data.isNotEmpty) {
// // // // // // // //           final addressDetailsUrl = Uri.parse(
// // // // // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // // // // //           final addressResponse = await http.get(addressDetailsUrl);
// // // // // // // //           if (addressResponse.statusCode == 200) {
// // // // // // // //             final addressData = json.decode(addressResponse.body);
// // // // // // // //             setState(() {
// // // // // // // //               communeController.text = addressData['address']['city'] ??
// // // // // // // //                   addressData['address']['town'] ??
// // // // // // // //                   addressData['address']['village'] ??
// // // // // // // //                   "Commune introuvable";
// // // // // // // //             });
// // // // // // // //           }
// // // // // // // //         }
// // // // // // // //       }
// // // // // // // //     } catch (e) {
// // // // // // // //       debugPrint("Erreur commune : $e");
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // // }
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // //
// // // // // // // // // import 'dart:convert';
// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:http/http.dart' as http;
// // // // // // // // //
// // // // // // // // // class ProfileCreationPage extends StatefulWidget {
// // // // // // // // //   final String userUuid; // UUID Firebase
// // // // // // // // //   final String email;    // Email Firebase
// // // // // // // // //
// // // // // // // // //   const ProfileCreationPage({
// // // // // // // // //     required this.userUuid,
// // // // // // // // //     required this.email,
// // // // // // // // //     super.key,
// // // // // // // // //   });
// // // // // // // // //
// // // // // // // // //   @override
// // // // // // // // //   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// // // // // // // // // }
// // // // // // // // //
// // // // // // // // // class _ProfileCreationPageState extends State<ProfileCreationPage> {
// // // // // // // // //   // Nouveaux ajouts
// // // // // // // // //   String? selectedGender; // Sexe sélectionné
// // // // // // // // //   final List<String> genderOptions = ["Homme", "Femme", "Autre"];
// // // // // // // // //
// // // // // // // // //   // Autres controllers existants
// // // // // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // // // // //   final TextEditingController surnameController = TextEditingController();
// // // // // // // // //   final TextEditingController codePostalController = TextEditingController();
// // // // // // // // //   final TextEditingController communeController = TextEditingController();
// // // // // // // // //   final TextEditingController streetController = TextEditingController();
// // // // // // // // //   final TextEditingController streetNumberController = TextEditingController();
// // // // // // // // //   final TextEditingController postalBoxController = TextEditingController();
// // // // // // // // //   final TextEditingController phoneController = TextEditingController();
// // // // // // // // //   final TextEditingController socialNameController = TextEditingController();
// // // // // // // // //   final TextEditingController tvaController = TextEditingController();
// // // // // // // // //
// // // // // // // // //   bool isCoiffeuse = false; // Switch entre Coiffeuse et Client
// // // // // // // // //
// // // // // // // // //   @override
// // // // // // // // //   void initState() {
// // // // // // // // //     super.initState();
// // // // // // // // //     // Pré-remplir l'email et l'UUID avec les valeurs passées depuis AuthService
// // // // // // // // //     userEmail = widget.email;
// // // // // // // // //     userUuid = widget.userUuid;
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   late String userEmail; // Stockage de l'email pour envoi au backend
// // // // // // // // //   late String userUuid;  // Stockage de l'UUID pour envoi au backend
// // // // // // // // //
// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return Scaffold(
// // // // // // // // //       appBar: AppBar(
// // // // // // // // //         title: const Text("Créer un profil"),
// // // // // // // // //       ),
// // // // // // // // //       body: SingleChildScrollView(
// // // // // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // // // // //         child: Column(
// // // // // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // //           children: [
// // // // // // // // //             _buildSwitchRole(),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildTextField("Nom", nameController),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildTextField("Prénom", surnameController),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildGenderDropdown(),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildCodePostalField(),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildTextField("Commune", communeController, readOnly: true),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildTextField("Rue", streetController),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildStreetAndBoxRow(),
// // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // //             _buildTextField("Téléphone", phoneController,
// // // // // // // // //                 keyboardType: TextInputType.phone),
// // // // // // // // //             if (isCoiffeuse) ...[
// // // // // // // // //               const SizedBox(height: 10),
// // // // // // // // //               _buildTextField("Dénomination Sociale", socialNameController),
// // // // // // // // //               const SizedBox(height: 10),
// // // // // // // // //               _buildTextField("Numéro TVA", tvaController),
// // // // // // // // //             ],
// // // // // // // // //             const SizedBox(height: 20),
// // // // // // // // //             ElevatedButton(
// // // // // // // // //               onPressed: _saveProfile,
// // // // // // // // //               child: const Text("Enregistrer"),
// // // // // // // // //             ),
// // // // // // // // //           ],
// // // // // // // // //         ),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   /// Liste déroulante pour le sexe
// // // // // // // // //   Widget _buildGenderDropdown() {
// // // // // // // // //     return DropdownButtonFormField<String>(
// // // // // // // // //       value: selectedGender,
// // // // // // // // //       decoration: const InputDecoration(
// // // // // // // // //         labelText: "Sexe",
// // // // // // // // //         border: OutlineInputBorder(),
// // // // // // // // //       ),
// // // // // // // // //       items: genderOptions
// // // // // // // // //           .map((gender) => DropdownMenuItem(
// // // // // // // // //         value: gender,
// // // // // // // // //         child: Text(gender),
// // // // // // // // //       ))
// // // // // // // // //           .toList(),
// // // // // // // // //       onChanged: (value) {
// // // // // // // // //         setState(() {
// // // // // // // // //           selectedGender = value;
// // // // // // // // //         });
// // // // // // // // //       },
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   /// Switch entre Client et Coiffeuse
// // // // // // // // //   Widget _buildSwitchRole() {
// // // // // // // // //     return Row(
// // // // // // // // //       children: [
// // // // // // // // //         const Text("Client"),
// // // // // // // // //         Switch(
// // // // // // // // //           value: isCoiffeuse,
// // // // // // // // //           onChanged: (value) {
// // // // // // // // //             setState(() {
// // // // // // // // //               isCoiffeuse = value;
// // // // // // // // //             });
// // // // // // // // //           },
// // // // // // // // //         ),
// // // // // // // // //         const Text("Coiffeuse"),
// // // // // // // // //       ],
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   /// Widget pour Code Postal
// // // // // // // // //   Widget _buildCodePostalField() {
// // // // // // // // //     return TextField(
// // // // // // // // //       controller: codePostalController,
// // // // // // // // //       keyboardType: TextInputType.number,
// // // // // // // // //       decoration: const InputDecoration(
// // // // // // // // //         labelText: "Code Postal",
// // // // // // // // //         border: OutlineInputBorder(),
// // // // // // // // //       ),
// // // // // // // // //       onChanged: (value) => fetchCommune(value),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   /// Widget pour l'auto-complétion des rues
// // // // // // // // //   /// Widget pour l'auto-complétion des rues
// // // // // // // // //   // Widget _buildStreetAutocomplete() {
// // // // // // // // //   //   return Autocomplete<String>(
// // // // // // // // //   //     optionsBuilder: (TextEditingValue textEditingValue) async {
// // // // // // // // //   //       return await fetchStreetSuggestions(textEditingValue.text);
// // // // // // // // //   //     },
// // // // // // // // //   //     onSelected: (String selection) {
// // // // // // // // //   //       streetController.text = selection;
// // // // // // // // //   //     },
// // // // // // // // //   //     fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
// // // // // // // // //   //       streetController.text = controller.text;
// // // // // // // // //   //       return TextField(
// // // // // // // // //   //         controller: controller,
// // // // // // // // //   //         focusNode: focusNode,
// // // // // // // // //   //         onEditingComplete: onEditingComplete,
// // // // // // // // //   //         decoration: const InputDecoration(
// // // // // // // // //   //           labelText: "Rue",
// // // // // // // // //   //           border: OutlineInputBorder(),
// // // // // // // // //   //         ),
// // // // // // // // //   //       );
// // // // // // // // //   //     },
// // // // // // // // //   //   );
// // // // // // // // //   // }
// // // // // // // // //
// // // // // // // // //   /// Méthode pour récupérer la commune depuis le Code Postal
// // // // // // // // //   Future<void> fetchCommune(String codePostal) async {
// // // // // // // // //     final url = Uri.parse(
// // // // // // // // //         "https://nominatim.openstreetmap.org/search?postalcode=$codePostal&country=Belgium&format=json");
// // // // // // // // //
// // // // // // // // //     try {
// // // // // // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // // // // //       if (response.statusCode == 200) {
// // // // // // // // //         final data = json.decode(response.body) as List;
// // // // // // // // //         if (data.isNotEmpty) {
// // // // // // // // //           final addressDetailsUrl = Uri.parse(
// // // // // // // // //               "https://nominatim.openstreetmap.org/reverse?lat=${data[0]['lat']}&lon=${data[0]['lon']}&format=json");
// // // // // // // // //           final addressResponse = await http.get(addressDetailsUrl);
// // // // // // // // //           if (addressResponse.statusCode == 200) {
// // // // // // // // //             final addressData = json.decode(addressResponse.body);
// // // // // // // // //             setState(() {
// // // // // // // // //               communeController.text = addressData['address']['city'] ??
// // // // // // // // //                   addressData['address']['town'] ??
// // // // // // // // //                   addressData['address']['village'] ??
// // // // // // // // //                   "Commune introuvable";
// // // // // // // // //             });
// // // // // // // // //           }
// // // // // // // // //         }
// // // // // // // // //       }
// // // // // // // // //     } catch (e) {
// // // // // // // // //       debugPrint("Erreur commune : $e");
// // // // // // // // //     }
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   /// Méthode pour suggestions de rues
// // // // // // // // //   Future<List<String>> fetchStreetSuggestions(String query) async {
// // // // // // // // //     if (query.isEmpty || communeController.text.isEmpty) return [];
// // // // // // // // //     final url = Uri.parse(
// // // // // // // // //         "https://nominatim.openstreetmap.org/search?street=${query.toLowerCase()}&city=${communeController.text}&country=Belgium&format=json");
// // // // // // // // //     try {
// // // // // // // // //       final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
// // // // // // // // //       if (response.statusCode == 200) {
// // // // // // // // //         final data = json.decode(response.body) as List;
// // // // // // // // //         return data.map<String>((item) => item['display_name'].split(",")[0].trim()).toList();
// // // // // // // // //       }
// // // // // // // // //     } catch (e) {
// // // // // // // // //       debugPrint("Erreur auto-complétion : $e");
// // // // // // // // //     }
// // // // // // // // //     return [];
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //
// // // // // // // // //
// // // // // // // // //
// // // // // // // // //
// // // // // // // // //   /// Widget pour Numéro et Boîte sur la même ligne
// // // // // // // // //   Widget _buildStreetAndBoxRow() {
// // // // // // // // //     return Row(
// // // // // // // // //       children: [
// // // // // // // // //         Expanded(
// // // // // // // // //           child: _buildTextField("Numéro", streetNumberController),
// // // // // // // // //         ),
// // // // // // // // //         const SizedBox(width: 10),
// // // // // // // // //         Expanded(
// // // // // // // // //           child: _buildTextField("N° Boîte", postalBoxController),
// // // // // // // // //         ),
// // // // // // // // //       ],
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //
// // // // // // // // // //************** Afficher les données du formulaire dans la console *************
// // // // // // // // //
// // // // // // // // //   void _printFormData() {
// // // // // // // // //     debugPrint("===== Données du formulaire =====");
// // // // // // // // //     debugPrint("userUuid : $userUuid");
// // // // // // // // //     debugPrint("Email : $userEmail");
// // // // // // // // //     debugPrint("Nom : ${nameController.text}");
// // // // // // // // //     debugPrint("Prénom : ${surnameController.text}");
// // // // // // // // //     debugPrint("Sexe : ${selectedGender ?? 'Non sélectionné'}");
// // // // // // // // //     debugPrint("Code postal : ${codePostalController.text}");
// // // // // // // // //     debugPrint("Commune : ${communeController.text}");
// // // // // // // // //     debugPrint("Rue : ${streetController.text}");
// // // // // // // // //     debugPrint("Numéro : ${streetNumberController.text}");
// // // // // // // // //     debugPrint("Boîte postale : ${postalBoxController.text}");
// // // // // // // // //     debugPrint("Téléphone : ${phoneController.text}");
// // // // // // // // //     if (isCoiffeuse) {
// // // // // // // // //       debugPrint("Dénomination Sociale : ${socialNameController.text}");
// // // // // // // // //       debugPrint("Numéro TVA : ${tvaController.text}");
// // // // // // // // //     }
// // // // // // // // //     debugPrint("Rôle : ${isCoiffeuse ? "Coiffeuse" : "Client"}");
// // // // // // // // //     debugPrint("===== Fin des données =====");
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   //**********************************************************************************
// // // // // // // // //
// // // // // // // // //   /// Méthode pour sauvegarder le profil
// // // // // // // // //   void _saveProfile() async {
// // // // // // // // //
// // // // // // // // //     final url = Uri.parse("http://192.168.0.202:8000/api/create-profile/");
// // // // // // // // //     final Map<String, dynamic> data = {
// // // // // // // // //       "userUuid": userUuid,
// // // // // // // // //       "role": isCoiffeuse ? "coiffeuse" : "client",
// // // // // // // // //       "nom": nameController.text,
// // // // // // // // //       "prenom": surnameController.text,
// // // // // // // // //       "sexe": selectedGender?.toLowerCase(),
// // // // // // // // //       "code_postal": codePostalController.text,
// // // // // // // // //       "commune": communeController.text,
// // // // // // // // //       "rue": streetController.text,
// // // // // // // // //       "numero": streetNumberController.text,
// // // // // // // // //       "boite_postale": postalBoxController.text,
// // // // // // // // //       "telephone": phoneController.text,
// // // // // // // // //       "email": userEmail,
// // // // // // // // //       "denomination_sociale": isCoiffeuse ? socialNameController.text : null,
// // // // // // // // //       "tva": isCoiffeuse ? tvaController.text : null,
// // // // // // // // //     };
// // // // // // // // //
// // // // // // // // //
// // // // // // // // //
// // // // // // // // //     try {
// // // // // // // // //       _printFormData();
// // // // // // // // //       final response = await http.post(
// // // // // // // // //         url,
// // // // // // // // //         headers: {"Content-Type": "application/json"},
// // // // // // // // //         body: jsonEncode(data),
// // // // // // // // //       );
// // // // // // // // //
// // // // // // // // //       if (response.statusCode == 201) {
// // // // // // // // //         debugPrint("Profil créé avec succès : ${response.body}");
// // // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // // //           const SnackBar(content: Text("Profil créé avec succès!")),
// // // // // // // // //         );
// // // // // // // // //       } else {
// // // // // // // // //         debugPrint("Erreur serveur : ${response.body}");
// // // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // // //           const SnackBar(content: Text("Erreur lors de la création du profil.")),
// // // // // // // // //         );
// // // // // // // // //       }
// // // // // // // // //     } catch (e) {
// // // // // // // // //       debugPrint("Erreur de connexion : $e");
// // // // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // // //         const SnackBar(content: Text("Erreur de connexion au serveur.")),
// // // // // // // // //       );
// // // // // // // // //     }
// // // // // // // // //   }
// // // // // // // // //
// // // // // // // // //   /// Fonction générique pour TextField
// // // // // // // // //   Widget _buildTextField(String label, TextEditingController controller,
// // // // // // // // //       {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
// // // // // // // // //     return TextField(
// // // // // // // // //       controller: controller,
// // // // // // // // //       readOnly: readOnly,
// // // // // // // // //       keyboardType: keyboardType,
// // // // // // // // //       decoration: InputDecoration(
// // // // // // // // //         labelText: label,
// // // // // // // // //         border: const OutlineInputBorder(),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }
