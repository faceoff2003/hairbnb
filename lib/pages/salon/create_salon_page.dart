// hairbnb/lib/pages/salon/create_salon_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/select_services/select_services_page.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Ajout pour l'authentification
import '../../models/current_user.dart';
import '../../models/salon_create.dart';
import '../../services/providers/current_user_provider.dart';
import '../profil/profil_widgets/auto_complete_widget.dart';
import '../profil/profil_widgets/commune_autofill_widget.dart';

class CreateSalonPage extends StatefulWidget {
  final CurrentUser currentUser;

  const CreateSalonPage({required this.currentUser, super.key});

  @override
  State<CreateSalonPage> createState() => _CreateSalonPageState();
}

class _CreateSalonPageState extends State<CreateSalonPage> {
  // Contrôleurs pour les champs de base
  final TextEditingController nomSalonController = TextEditingController();
  final TextEditingController sloganController = TextEditingController();
  final TextEditingController aProposController = TextEditingController();
  final TextEditingController numeroTvaController = TextEditingController();

  // Contrôleurs pour l'adresse (nécessaires pour les widgets d'autocomplétion)
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController rueController = TextEditingController();
  final TextEditingController codePostalController = TextEditingController();
  final TextEditingController communeController = TextEditingController();

  // Variables pour le logo et géolocalisation
  Uint8List? logoBytes;
  File? logoFile;
  bool isLoading = false;
  String? calculatedPosition; // Position calculée automatiquement
  int? selectedAdresseId; // ID de l'adresse sélectionnée

  // Clé API Geoapify - À remplacer par votre vraie clé
  final String geoapifyApiKey = "b097f188b11f46d2a02eb55021d168c1";

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
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
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

                    // Informations de base du salon
                    _buildTextField("Nom du salon", nomSalonController, Icons.storefront),
                    const SizedBox(height: 20),
                    _buildTextField("Slogan du salon", sloganController, Icons.short_text),
                    const SizedBox(height: 20),
                    _buildTextField("À propos du salon", aProposController, Icons.info_outline, maxLines: 3),
                    const SizedBox(height: 20),
                    _buildTextField("Numéro de TVA", numeroTvaController, Icons.badge),
                    const SizedBox(height: 30),

                    // Section Adresse
                    const Text(
                      "Adresse du salon",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 20),

                    // Numéro de rue
                    _buildTextField("Numéro", numeroController, Icons.pin_drop),
                    const SizedBox(height: 20),

                    // Autocomplétion des rues
                    StreetAutocomplete(
                      streetController: rueController,
                      communeController: communeController,
                      codePostalController: codePostalController,
                      geoapifyApiKey: geoapifyApiKey,
                    ),
                    const SizedBox(height: 20),

                    // Autocomplétion code postal -> commune
                    CommuneAutoFill(
                      codePostalController: codePostalController,
                      communeController: communeController,
                      geoapifyApiKey: geoapifyApiKey,
                    ),
                    const SizedBox(height: 20),

                    // Affichage de la commune (en lecture seule)
                    TextField(
                      controller: communeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Commune",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Affichage de la position calculée (optionnel, pour debug)
                    if (calculatedPosition != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Position calculée : $calculatedPosition",
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),

                    // Section Logo
                    _buildLogoPicker(),
                    const SizedBox(height: 40),

                    // Bouton de création
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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

  /// Calcule automatiquement la position géographique en fonction de l'adresse
  Future<void> _calculatePosition() async {
    if (numeroController.text.isEmpty ||
        rueController.text.isEmpty ||
        codePostalController.text.isEmpty ||
        communeController.text.isEmpty) {
      return;
    }

    // Construire l'adresse complète
    final fullAddress = "${numeroController.text} ${rueController.text}, ${codePostalController.text} ${communeController.text}, Belgique";

    // Appel à l'API Geoapify pour obtenir les coordonnées
    final url = Uri.parse(
        "https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(fullAddress)}&lang=fr&limit=1&apiKey=$geoapifyApiKey"
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final coordinates = data['features'][0]['geometry']['coordinates'];
          final longitude = coordinates[0];
          final latitude = coordinates[1];

          setState(() {
            calculatedPosition = "$latitude,$longitude";
          });

          if (kDebugMode) {
            print("Position calculée : $calculatedPosition pour l'adresse : $fullAddress");
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du calcul de la position : $e");
    }
  }

  /// Récupère ou crée l'ID de l'adresse dans la base de données
  Future<int?> _getOrCreateAdresseId() async {
    if (numeroController.text.isEmpty ||
        rueController.text.isEmpty ||
        codePostalController.text.isEmpty ||
        communeController.text.isEmpty) {
      return null;
    }

    // TODO: Implémenter l'appel API pour créer/récupérer l'adresse
    // Cette fonction devrait :
    // 1. Vérifier si l'adresse existe déjà
    // 2. Si non, créer la localité, la rue et l'adresse
    // 3. Retourner l'ID de l'adresse

    // Pour l'instant, retournons un ID fictif
    // Vous devrez remplacer ceci par un vrai appel API
    return 1; // ID fictif temporaire
  }

  Future<void> _saveSalon() async {
    final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

    // Vérification des champs obligatoires
    List<String> champsManquants = [];
    if (nomSalonController.text.isEmpty) champsManquants.add("Nom du salon");
    if (sloganController.text.isEmpty) champsManquants.add("Slogan du salon");
    if (aProposController.text.isEmpty) champsManquants.add("À propos du salon");
    if (numeroTvaController.text.isEmpty) champsManquants.add("Numéro de TVA");
    if (numeroController.text.isEmpty) champsManquants.add("Numéro de rue");
    if (rueController.text.isEmpty) champsManquants.add("Rue");
    if (codePostalController.text.isEmpty) champsManquants.add("Code postal");
    if (communeController.text.isEmpty) champsManquants.add("Commune");
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

    setState(() => isLoading = true);

    try {
      // Calcul automatique de la position
      await _calculatePosition();

      // Récupération de l'ID de l'adresse
      final adresseId = await _getOrCreateAdresseId();

      if (adresseId == null) {
        throw Exception("Impossible de créer l'adresse");
      }

      if (calculatedPosition == null) {
        throw Exception("Impossible de calculer la position géographique");
      }

      // Création du modèle avec tous les champs obligatoires
      final salon = SalonCreateModel(
        idTblUser: utilisateurActuelle!.idTblUser,
        nomSalon: nomSalonController.text,
        slogan: sloganController.text,
        logo: kIsWeb ? logoBytes : logoFile,
        aPropos: aProposController.text,
        numeroTva: numeroTvaController.text,
        position: calculatedPosition!,
        adresse: adresseId,
      );

      // Envoi vers l'API avec authentification Firebase
      final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon/");
      final request = http.MultipartRequest('POST', url);

      // ✅ Ajout du token d'authentification Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firebaseToken = await user.getIdToken();
        request.headers['Authorization'] = 'Bearer $firebaseToken';
      } else {
        throw Exception("Utilisateur non authentifié");
      }

      // Ajout des champs du formulaire
      request.fields.addAll(salon.toFields());

      // Ajout du fichier logo
      if (kIsWeb && salon.logo is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes(
          'logo_salon',
          salon.logo as Uint8List,
          filename: 'logo.png',
          contentType: MediaType('image', 'png'),
        ));
      } else if (salon.logo is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'logo_salon',
          (salon.logo as File).path,
          contentType: MediaType('image', 'png'),
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Salon créé avec succès!")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectServicesPage(
              //coiffeuseId: utilisateurActuelle.idTblUser.toString(),
              currentUser: utilisateurActuelle,
            ),
          ),
        );
      } else {
        debugPrint("Erreur backend : $responseBody");

        // Gestion des erreurs de validation du backend
        try {
          final errorData = jsonDecode(responseBody);
          if (errorData['errors'] != null) {
            String errorMessage = "Erreurs de validation :\n";
            errorData['errors'].forEach((key, value) {
              errorMessage += "• $key : ${value.join(', ')}\n";
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage.trim()),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            throw Exception(errorData['message'] ?? 'Erreur inconnue');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de la création : $responseBody")),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la création du salon : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}