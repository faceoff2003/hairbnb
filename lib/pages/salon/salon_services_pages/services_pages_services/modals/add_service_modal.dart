import 'package:flutter/material.dart';
import 'package:hairbnb/models/categorie.dart';
import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
import 'package:hairbnb/services/providers/services_categories_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../../services/firebase_token/token_service.dart';
import '../components/show_dialog.dart';

Future<void> showAddServiceModal(
    BuildContext context,
    String coiffeuseId,
    VoidCallback onSuccess,
    CategoriesProvider categoriesProvider,
    ServicesProvider servicesProvider,
    ) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  // ✅ Gestion de la catégorie sélectionnée
  Categorie? selectedCategory;

  // ✅ Gestion du mode et service sélectionné
  bool isAddExistingMode = true; // Mode par défaut : ajouter service existant
  ServiceSuggestion? selectedExistingService;

  bool isLoading = false;
  final Color primaryViolet = const Color(0xFF7B61FF);

  // ✅ Charger les services au démarrage si pas encore fait
  if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
    servicesProvider.loadAllServices();
  }

  Widget buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
          labelText: label,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ✅ Widget pour basculer entre les modes
  Widget buildModeToggle(StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setModalState(() {
                  isAddExistingMode = true;
                  selectedExistingService = null;
                  nameController.clear();
                  descriptionController.clear();
                  priceController.clear();
                  durationController.clear();
                  selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isAddExistingMode ? primaryViolet : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: isAddExistingMode ? Colors.white : primaryViolet,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Ajouter existant",
                      style: TextStyle(
                        color: isAddExistingMode ? Colors.white : primaryViolet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setModalState(() {
                  isAddExistingMode = false;
                  selectedExistingService = null;
                  nameController.clear();
                  descriptionController.clear();
                  priceController.clear();
                  durationController.clear();
                  selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isAddExistingMode ? primaryViolet : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.create,
                      color: !isAddExistingMode ? Colors.white : primaryViolet,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Créer nouveau",
                      style: TextStyle(
                        color: !isAddExistingMode ? Colors.white : primaryViolet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU : Dropdown pour sélectionner un service existant (mis à jour)
  Widget buildExistingServiceSelector(StateSetter setModalState) {
    if (!isAddExistingMode) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading state
          if (servicesProvider.isLoading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.design_services, color: Color(0xFF7B61FF)),
                  SizedBox(width: 12),
                  Text("Chargement des services..."),
                  Spacer(),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          ]
          // Error state
          else if (servicesProvider.hasError) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Erreur: ${servicesProvider.errorMessage}",
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      servicesProvider.loadAllServices();
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            ),
          ]
          // Services disponibles
          else if (servicesProvider.allServices.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownButtonFormField<ServiceSuggestion>(
                      value: selectedExistingService,
                      isExpanded: true, // ✅ AJOUTÉ : Force l'expansion dans l'espace disponible
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.design_services, color: primaryViolet),
                        labelText: "Service à ajouter *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: const Text("Sélectionner un service"),
                      items: servicesProvider.allServices.map((ServiceSuggestion service) {
                        return DropdownMenuItem<ServiceSuggestion>(
                          value: service,
                          child: SizedBox(
                            width: constraints.maxWidth - 80, // ✅ Contrainte de largeur
                            child: Text(
                              "${service.intituleService}${service.categorieNom != null ? ' • ${service.categorieNom}' : ''}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (ServiceSuggestion? newValue) {
                        setModalState(() {
                          selectedExistingService = newValue;
                          if (newValue != null) {
                            nameController.text = newValue.intituleService;
                            // ✅ SUPPRIMÉ : Plus de description à pré-remplir
                            descriptionController.clear();
                            // ✅ SUPPRIMÉ : Plus de prix/durée suggérés
                            priceController.clear();
                            durationController.clear();
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              // ✅ NOUVEAU : Info du service sélectionné (simplifiée)
              if (selectedExistingService != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            "Service sélectionné",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Service: ${selectedExistingService!.intituleService}",
                        style: TextStyle(color: Colors.blue[600], fontSize: 13),
                      ),
                      if (selectedExistingService!.categorieNom != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Catégorie: ${selectedExistingService!.categorieNom}",
                          style: TextStyle(color: Colors.blue[600], fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        "Veuillez définir le prix et la durée pour votre salon.",
                        style: TextStyle(
                          color: Colors.blue[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]
            // Aucun service disponible
            else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Aucun service disponible",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              "Passez en mode 'Créer nouveau' pour ajouter un service",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        ],
      ),
    );
  }

  // ✅ NOUVEAU : Widget pour afficher la catégorie en lecture seule
  Widget buildCategoryDisplay() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.category, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Catégorie",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedExistingService?.categorieNom ?? "Sans catégorie",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Automatique",
                style: TextStyle(
                  color: primaryViolet,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildCategorySelector(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Builder(
          builder: (context) {
            if (categoriesProvider.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Color(0xFF7B61FF)),
                    SizedBox(width: 12),
                    Text("Chargement des catégories..."),
                    Spacer(),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              );
            }

            if (categoriesProvider.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Erreur : ${categoriesProvider.errorMessage}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        categoriesProvider.refreshCategories();
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
              );
            }

            final categories = categoriesProvider.categoriesSorted;

            if (categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.grey),
                    SizedBox(width: 12),
                    Text("Aucune catégorie disponible"),
                  ],
                ),
              );
            }

            return DropdownButtonFormField<Categorie>(
              value: selectedCategory,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.category, color: primaryViolet),
                labelText: "Catégorie *",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              hint: const Text("Sélectionner une catégorie"),
              items: categories.map((Categorie category) {
                return DropdownMenuItem<Categorie>(
                  value: category,
                  child: Text(
                    category.nom,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (Categorie? newValue) {
                setModalState(() {
                  selectedCategory = newValue;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> addService(StateSetter setModalState) async {
    // ✅ Validation selon le mode
    if (isAddExistingMode) {
      // Mode ajouter existant
      if (selectedExistingService == null) {
        showErrorDialog(context, "Veuillez sélectionner un service.");
        return;
      }
      // ✅ SUPPRIMÉ : Pas besoin de vérifier selectedCategory pour service existant
      if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) {
        showErrorDialog(context, "Le prix et la durée sont obligatoires.");
        return;
      }
    } else {
      // Mode créer nouveau
      if (selectedCategory == null) {
        showErrorDialog(context, "Veuillez sélectionner une catégorie.");
        return;
      }
      if (nameController.text.trim().isEmpty ||
          descriptionController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty ||
          durationController.text.trim().isEmpty) {
        showErrorDialog(context, "Tous les champs sont obligatoires.");
        return;
      }
    }

    final String intitule = nameController.text.trim();
    final String description = descriptionController.text.trim();
    final String prixText = priceController.text.trim();
    final String durationText = durationController.text.trim();

    // Validation des nombres
    final double? prix = double.tryParse(prixText);
    final int? temps = int.tryParse(durationText);

    if (prix == null || temps == null) {
      showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
      return;
    }

    if (prix > 999) {
      showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
      return;
    }

    if (temps > 480) {
      showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
      return;
    }

    // Validation supplémentaire pour nouveau service
    if (!isAddExistingMode) {
      if (intitule.length > 100) {
        showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
        return;
      }
      if (description.length > 700) {
        showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
        return;
      }
    }

    setModalState(() => isLoading = true);

    try {
      final String? idToken = await TokenService.getAuthToken();

      if (idToken == null) {
        showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
        setModalState(() => isLoading = false);
        return;
      }

      http.Response response;

      if (isAddExistingMode) {
        // ✅ API pour ajouter un service existant (sans categorie_id)
        response = await http.post(
          Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: json.encode({
            'userId': int.parse(coiffeuseId),
            'service_id': selectedExistingService!.id,
            'prix': prix,
            'temps_minutes': temps,
            // ✅ SUPPRIMÉ : 'categorie_id' car le service a déjà sa catégorie
          }),
        );
      } else {
        // ✅ API pour créer un nouveau service
        response = await http.post(
          Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: json.encode({
            'userId': int.parse(coiffeuseId),
            'intitule_service': intitule,
            'description': description,
            'prix': prix,
            'temps_minutes': temps,
            'categorie_id': selectedCategory!.id,
          }),
        );
      }

      if (kDebugMode) {
        print("📊 Status code: ${response.statusCode}");
        print("📋 Réponse: ${response.body}");
      }

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        onSuccess();

        showSuccessDialog(
            context,
            isAddExistingMode
                ? "Service '$intitule' ajouté avec succès !"
                : "Service '$intitule' créé et ajouté avec succès !"
        );
      } else {
        Map<String, dynamic> errorResponse = {};
        try {
          errorResponse = json.decode(response.body);
        } catch (e) {
          // Si la réponse n'est pas du JSON valide
        }

        String errorMessage = errorResponse['message'] ??
            errorResponse['detail'] ??
            "Erreur lors de l'ajout du service (${response.statusCode})";

        if (response.statusCode == 401) {
          await TokenService.clearAuthToken();
        }

        showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      showErrorDialog(context, "Erreur de connexion: $e");
    } finally {
      setModalState(() => isLoading = false);
    }
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    Text(
                      "Ajouter un service",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),

                    // ✅ Toggle entre les modes
                    buildModeToggle(setModalState),

                    // ✅ Sélecteur de service existant (mis à jour)
                    buildExistingServiceSelector(setModalState),

                    // ✅ Champs selon le mode
                    if (!isAddExistingMode) ...[
                      buildTextField("Nom du service *", nameController, Icons.design_services),
                      buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
                      // ✅ Catégorie seulement pour nouveau service
                      buildCategorySelector(setModalState),
                    ] else if (selectedExistingService != null) ...[
                      buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
                      // ✅ Affichage de la catégorie en lecture seule
                      buildCategoryDisplay(),
                    ],

                    // ✅ Prix et durée (toujours modifiables)
                    buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
                    buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => addService(setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryViolet,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                            isAddExistingMode ? "Ajouter au salon" : "Créer le service",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}







// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/categorie.dart';
// import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// import 'package:hairbnb/services/providers/services_categories_provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import '../../../../../services/firebase_token/token_service.dart';
// import '../components/show_dialog.dart';
//
// Future<void> showAddServiceModal(
//     BuildContext context,
//     String coiffeuseId,
//     VoidCallback onSuccess,
//     CategoriesProvider categoriesProvider,
//     ServicesProvider servicesProvider,
//     ) {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController durationController = TextEditingController();
//
//   // ✅ Gestion de la catégorie sélectionnée
//   Categorie? selectedCategory;
//
//   // ✅ Gestion du mode et service sélectionné
//   bool isAddExistingMode = true; // Mode par défaut : ajouter service existant
//   ServiceSuggestion? selectedExistingService;
//
//   bool isLoading = false;
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   // ✅ Charger les services au démarrage si pas encore fait
//   if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
//     servicesProvider.loadAllServices();
//   }
//
//   Widget buildTextField(String label, TextEditingController controller, IconData icon,
//       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         enabled: enabled,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
//           labelText: label,
//           filled: true,
//           fillColor: enabled ? Colors.white : Colors.grey[100],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ✅ Widget pour basculer entre les modes
//   Widget buildModeToggle(StateSetter setModalState) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setModalState(() {
//                   isAddExistingMode = true;
//                   selectedExistingService = null;
//                   nameController.clear();
//                   descriptionController.clear();
//                   priceController.clear();
//                   durationController.clear();
//                   selectedCategory = null;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   color: isAddExistingMode ? primaryViolet : Colors.transparent,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     bottomLeft: Radius.circular(12),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.add_circle_outline,
//                       color: isAddExistingMode ? Colors.white : primaryViolet,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Ajouter existant",
//                       style: TextStyle(
//                         color: isAddExistingMode ? Colors.white : primaryViolet,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setModalState(() {
//                   isAddExistingMode = false;
//                   selectedExistingService = null;
//                   nameController.clear();
//                   descriptionController.clear();
//                   priceController.clear();
//                   durationController.clear();
//                   selectedCategory = null;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   color: !isAddExistingMode ? primaryViolet : Colors.transparent,
//                   borderRadius: const BorderRadius.only(
//                     topRight: Radius.circular(12),
//                     bottomRight: Radius.circular(12),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.create,
//                       color: !isAddExistingMode ? Colors.white : primaryViolet,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Créer nouveau",
//                       style: TextStyle(
//                         color: !isAddExistingMode ? Colors.white : primaryViolet,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ NOUVEAU : Dropdown pour sélectionner un service existant (mis à jour)
//   Widget buildExistingServiceSelector(StateSetter setModalState) {
//     if (!isAddExistingMode) return const SizedBox.shrink();
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Loading state
//           if (servicesProvider.isLoading) ...[
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.design_services, color: Color(0xFF7B61FF)),
//                   SizedBox(width: 12),
//                   Text("Chargement des services..."),
//                   Spacer(),
//                   SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                 ],
//               ),
//             ),
//           ]
//           // Error state
//           else if (servicesProvider.hasError) ...[
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red[50],
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: Colors.red[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.error, color: Colors.red[700]),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       "Erreur: ${servicesProvider.errorMessage}",
//                       style: TextStyle(color: Colors.red[700]),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.refresh),
//                     onPressed: () {
//                       servicesProvider.loadAllServices();
//                       setModalState(() {});
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ]
//           // Services disponibles
//           else if (servicesProvider.allServices.isNotEmpty) ...[
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     return DropdownButtonFormField<ServiceSuggestion>(
//                       value: selectedExistingService,
//                       isExpanded: true, // ✅ AJOUTÉ : Force l'expansion dans l'espace disponible
//                       decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.design_services, color: primaryViolet),
//                         labelText: "Service à ajouter *",
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                       hint: const Text("Sélectionner un service"),
//                       items: servicesProvider.allServices.map((ServiceSuggestion service) {
//                         return DropdownMenuItem<ServiceSuggestion>(
//                           value: service,
//                           child: SizedBox(
//                             width: constraints.maxWidth - 80, // ✅ AJOUTÉ : Contrainte de largeur
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   service.intituleService,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 // ✅ NOUVEAU : Affichage de la catégorie au lieu de la description
//                                 if (service.categorieNom != null)
//                                   Text(
//                                     service.categorieNom!,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey[600],
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                       onChanged: (ServiceSuggestion? newValue) {
//                         setModalState(() {
//                           selectedExistingService = newValue;
//                           if (newValue != null) {
//                             nameController.text = newValue.intituleService;
//                             // ✅ SUPPRIMÉ : Plus de description à pré-remplir
//                             descriptionController.clear();
//                             // ✅ SUPPRIMÉ : Plus de prix/durée suggérés
//                             priceController.clear();
//                             durationController.clear();
//                           }
//                         });
//                       },
//                     );
//                   },
//                 ),
//               ),
//
//               // ✅ NOUVEAU : Info du service sélectionné (simplifiée)
//               if (selectedExistingService != null) ...[
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blue[200]!),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.blue[700]),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Service sélectionné",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Service: ${selectedExistingService!.intituleService}",
//                         style: TextStyle(color: Colors.blue[600], fontSize: 13),
//                       ),
//                       if (selectedExistingService!.categorieNom != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           "Catégorie: ${selectedExistingService!.categorieNom}",
//                           style: TextStyle(color: Colors.blue[600], fontSize: 13),
//                         ),
//                       ],
//                       const SizedBox(height: 8),
//                       Text(
//                         "Veuillez définir le prix et la durée pour votre salon.",
//                         style: TextStyle(
//                           color: Colors.blue[500],
//                           fontSize: 12,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ]
//             // Aucun service disponible
//             else ...[
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info_outline, color: Colors.grey[600]),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Aucun service disponible",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey[700],
//                               ),
//                             ),
//                             Text(
//                               "Passez en mode 'Créer nouveau' pour ajouter un service",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//         ],
//       ),
//     );
//   }
//
//   // ✅ NOUVEAU : Widget pour afficher la catégorie en lecture seule
//   Widget buildCategoryDisplay() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.category, color: Colors.grey[600]),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Catégorie",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   selectedExistingService?.categorieNom ?? "Sans catégorie",
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const Spacer(),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: primaryViolet.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Text(
//                 "Automatique",
//                 style: TextStyle(
//                   color: primaryViolet,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget buildCategorySelector(StateSetter setModalState) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Builder(
//           builder: (context) {
//             if (categoriesProvider.isLoading) {
//               return const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(Icons.category, color: Color(0xFF7B61FF)),
//                     SizedBox(width: 12),
//                     Text("Chargement des catégories..."),
//                     Spacer(),
//                     SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             if (categoriesProvider.hasError) {
//               return Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.error, color: Colors.red),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         "Erreur : ${categoriesProvider.errorMessage}",
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.refresh),
//                       onPressed: () {
//                         categoriesProvider.refreshCategories();
//                         setModalState(() {});
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             final categories = categoriesProvider.categoriesSorted;
//
//             if (categories.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(Icons.category, color: Colors.grey),
//                     SizedBox(width: 12),
//                     Text("Aucune catégorie disponible"),
//                   ],
//                 ),
//               );
//             }
//
//             return DropdownButtonFormField<Categorie>(
//               value: selectedCategory,
//               decoration: InputDecoration(
//                 prefixIcon: Icon(Icons.category, color: primaryViolet),
//                 labelText: "Catégorie *",
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//               hint: const Text("Sélectionner une catégorie"),
//               items: categories.map((Categorie category) {
//                 return DropdownMenuItem<Categorie>(
//                   value: category,
//                   child: Text(
//                     category.nom,
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 );
//               }).toList(),
//               onChanged: (Categorie? newValue) {
//                 setModalState(() {
//                   selectedCategory = newValue;
//                 });
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<void> addService(StateSetter setModalState) async {
//     // ✅ Validation selon le mode
//     if (isAddExistingMode) {
//       // Mode ajouter existant
//       if (selectedExistingService == null) {
//         showErrorDialog(context, "Veuillez sélectionner un service.");
//         return;
//       }
//       // ✅ SUPPRIMÉ : Pas besoin de vérifier selectedCategory pour service existant
//       if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) {
//         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
//         return;
//       }
//     } else {
//       // Mode créer nouveau
//       if (selectedCategory == null) {
//         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
//         return;
//       }
//       if (nameController.text.trim().isEmpty ||
//           descriptionController.text.trim().isEmpty ||
//           priceController.text.trim().isEmpty ||
//           durationController.text.trim().isEmpty) {
//         showErrorDialog(context, "Tous les champs sont obligatoires.");
//         return;
//       }
//     }
//
//     final String intitule = nameController.text.trim();
//     final String description = descriptionController.text.trim();
//     final String prixText = priceController.text.trim();
//     final String durationText = durationController.text.trim();
//
//     // Validation des nombres
//     final double? prix = double.tryParse(prixText);
//     final int? temps = int.tryParse(durationText);
//
//     if (prix == null || temps == null) {
//       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
//       return;
//     }
//
//     if (prix > 999) {
//       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
//       return;
//     }
//
//     if (temps > 480) {
//       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
//       return;
//     }
//
//     // Validation supplémentaire pour nouveau service
//     if (!isAddExistingMode) {
//       if (intitule.length > 100) {
//         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
//         return;
//       }
//       if (description.length > 700) {
//         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
//         return;
//       }
//     }
//
//     setModalState(() => isLoading = true);
//
//     try {
//       final String? idToken = await TokenService.getAuthToken();
//
//       if (idToken == null) {
//         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
//         setModalState(() => isLoading = false);
//         return;
//       }
//
//       http.Response response;
//
//       if (isAddExistingMode) {
//         // ✅ API pour ajouter un service existant (sans categorie_id)
//         response = await http.post(
//           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $idToken',
//           },
//           body: json.encode({
//             'userId': int.parse(coiffeuseId),
//             'service_id': selectedExistingService!.id,
//             'prix': prix,
//             'temps_minutes': temps,
//             // ✅ SUPPRIMÉ : 'categorie_id' car le service a déjà sa catégorie
//           }),
//         );
//       } else {
//         // ✅ API pour créer un nouveau service
//         response = await http.post(
//           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $idToken',
//           },
//           body: json.encode({
//             'userId': int.parse(coiffeuseId),
//             'intitule_service': intitule,
//             'description': description,
//             'prix': prix,
//             'temps_minutes': temps,
//             'categorie_id': selectedCategory!.id,
//           }),
//         );
//       }
//
//       if (kDebugMode) {
//         print("📊 Status code: ${response.statusCode}");
//         print("📋 Réponse: ${response.body}");
//       }
//
//       if (response.statusCode == 201) {
//         Navigator.pop(context, true);
//         onSuccess();
//
//         showSuccessDialog(
//             context,
//             isAddExistingMode
//                 ? "Service '$intitule' ajouté avec succès !"
//                 : "Service '$intitule' créé et ajouté avec succès !"
//         );
//       } else {
//         Map<String, dynamic> errorResponse = {};
//         try {
//           errorResponse = json.decode(response.body);
//         } catch (e) {
//           // Si la réponse n'est pas du JSON valide
//         }
//
//         String errorMessage = errorResponse['message'] ??
//             errorResponse['detail'] ??
//             "Erreur lors de l'ajout du service (${response.statusCode})";
//
//         if (response.statusCode == 401) {
//           await TokenService.clearAuthToken();
//         }
//
//         showErrorDialog(context, errorMessage);
//       }
//     } catch (e) {
//       showErrorDialog(context, "Erreur de connexion: $e");
//     } finally {
//       setModalState(() => isLoading = false);
//     }
//   }
//
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setModalState) {
//           return AnimatedPadding(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//             child: DraggableScrollableSheet(
//               initialChildSize: 0.85,
//               maxChildSize: 0.95,
//               minChildSize: 0.5,
//               expand: false,
//               builder: (context, scrollController) => Container(
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF7F7F9),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: ListView(
//                   controller: scrollController,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//
//                     Text(
//                       "Ajouter un service",
//                       style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // ✅ Toggle entre les modes
//                     buildModeToggle(setModalState),
//
//                     // ✅ Sélecteur de service existant (mis à jour)
//                     buildExistingServiceSelector(setModalState),
//
//                     // ✅ Champs selon le mode
//                     if (!isAddExistingMode) ...[
//                       buildTextField("Nom du service *", nameController, Icons.design_services),
//                       buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
//                       // ✅ Catégorie seulement pour nouveau service
//                       buildCategorySelector(setModalState),
//                     ] else if (selectedExistingService != null) ...[
//                       buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
//                       // ✅ Affichage de la catégorie en lecture seule
//                       buildCategoryDisplay(),
//                     ],
//
//                     // ✅ Prix et durée (toujours modifiables)
//                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
//                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
//
//                     const SizedBox(height: 20),
//
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : () => addService(setModalState),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryViolet,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                           elevation: 4,
//                         ),
//                         child: isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : Text(
//                             isAddExistingMode ? "Ajouter au salon" : "Créer le service",
//                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/categorie.dart';
// // import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:flutter/foundation.dart';
// // import '../../../../../services/firebase_token/token_service.dart';
// // import '../components/show_dialog.dart';
// //
// // Future<void> showAddServiceModal(
// //     BuildContext context,
// //     String coiffeuseId,
// //     VoidCallback onSuccess,
// //     CategoriesProvider categoriesProvider,
// //     ServicesProvider servicesProvider,
// //     ) {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //
// //   // ✅ Gestion de la catégorie sélectionnée
// //   Categorie? selectedCategory;
// //
// //   // ✅ Gestion du mode et service sélectionné
// //   bool isAddExistingMode = true; // Mode par défaut : ajouter service existant
// //   ServiceSuggestion? selectedExistingService;
// //
// //   bool isLoading = false;
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //
// //   // ✅ Charger les services au démarrage si pas encore fait
// //   if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
// //     servicesProvider.loadAllServices();
// //   }
// //
// //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// //       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         enabled: enabled,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
// //           labelText: label,
// //           filled: true,
// //           fillColor: enabled ? Colors.white : Colors.grey[100],
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ✅ Widget pour basculer entre les modes
// //   Widget buildModeToggle(StateSetter setModalState) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 24),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey[300]!),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: GestureDetector(
// //               onTap: () {
// //                 setModalState(() {
// //                   isAddExistingMode = true;
// //                   selectedExistingService = null;
// //                   nameController.clear();
// //                   descriptionController.clear();
// //                   priceController.clear();
// //                   durationController.clear();
// //                   selectedCategory = null;
// //                 });
// //               },
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(vertical: 12),
// //                 decoration: BoxDecoration(
// //                   color: isAddExistingMode ? primaryViolet : Colors.transparent,
// //                   borderRadius: const BorderRadius.only(
// //                     topLeft: Radius.circular(12),
// //                     bottomLeft: Radius.circular(12),
// //                   ),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(
// //                       Icons.add_circle_outline,
// //                       color: isAddExistingMode ? Colors.white : primaryViolet,
// //                       size: 20,
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Text(
// //                       "Ajouter existant",
// //                       style: TextStyle(
// //                         color: isAddExistingMode ? Colors.white : primaryViolet,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: GestureDetector(
// //               onTap: () {
// //                 setModalState(() {
// //                   isAddExistingMode = false;
// //                   selectedExistingService = null;
// //                   nameController.clear();
// //                   descriptionController.clear();
// //                   priceController.clear();
// //                   durationController.clear();
// //                   selectedCategory = null;
// //                 });
// //               },
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(vertical: 12),
// //                 decoration: BoxDecoration(
// //                   color: !isAddExistingMode ? primaryViolet : Colors.transparent,
// //                   borderRadius: const BorderRadius.only(
// //                     topRight: Radius.circular(12),
// //                     bottomRight: Radius.circular(12),
// //                   ),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(
// //                       Icons.create,
// //                       color: !isAddExistingMode ? Colors.white : primaryViolet,
// //                       size: 20,
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Text(
// //                       "Créer nouveau",
// //                       style: TextStyle(
// //                         color: !isAddExistingMode ? Colors.white : primaryViolet,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ NOUVEAU : Dropdown pour sélectionner un service existant (mis à jour)
// //   Widget buildExistingServiceSelector(StateSetter setModalState) {
// //     if (!isAddExistingMode) return const SizedBox.shrink();
// //
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Loading state
// //           if (servicesProvider.isLoading) ...[
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(14),
// //               ),
// //               child: const Row(
// //                 children: [
// //                   Icon(Icons.design_services, color: Color(0xFF7B61FF)),
// //                   SizedBox(width: 12),
// //                   Text("Chargement des services..."),
// //                   Spacer(),
// //                   SizedBox(
// //                     width: 20,
// //                     height: 20,
// //                     child: CircularProgressIndicator(strokeWidth: 2),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ]
// //           // Error state
// //           else if (servicesProvider.hasError) ...[
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: Colors.red[50],
// //                 borderRadius: BorderRadius.circular(14),
// //                 border: Border.all(color: Colors.red[200]!),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Icon(Icons.error, color: Colors.red[700]),
// //                   const SizedBox(width: 12),
// //                   Expanded(
// //                     child: Text(
// //                       "Erreur: ${servicesProvider.errorMessage}",
// //                       style: TextStyle(color: Colors.red[700]),
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(Icons.refresh),
// //                     onPressed: () {
// //                       servicesProvider.loadAllServices();
// //                       setModalState(() {});
// //                     },
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ]
// //           // Services disponibles
// //           else if (servicesProvider.allServices.isNotEmpty) ...[
// //               Container(
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(14),
// //                 ),
// //                 child: DropdownButtonFormField<ServiceSuggestion>(
// //                   value: selectedExistingService,
// //                   decoration: InputDecoration(
// //                     prefixIcon: Icon(Icons.design_services, color: primaryViolet),
// //                     labelText: "Service à ajouter *",
// //                     filled: true,
// //                     fillColor: Colors.white,
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(14),
// //                       borderSide: BorderSide.none,
// //                     ),
// //                   ),
// //                   hint: const Text("Sélectionner un service"),
// //                   items: servicesProvider.allServices.map((ServiceSuggestion service) {
// //                     return DropdownMenuItem<ServiceSuggestion>(
// //                       value: service,
// //                       child: Container(
// //                         width: double.infinity,
// //                         constraints: const BoxConstraints(maxWidth: 300),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           mainAxisSize: MainAxisSize.min,
// //                           children: [
// //                             Text(
// //                               service.intituleService,
// //                               style: const TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                               ),
// //                               maxLines: 1,
// //                               overflow: TextOverflow.ellipsis,
// //                             ),
// //                             // ✅ NOUVEAU : Affichage de la catégorie au lieu de la description
// //                             if (service.categorieNom != null)
// //                               Text(
// //                                 service.categorieNom!,
// //                                 style: TextStyle(
// //                                   fontSize: 12,
// //                                   color: Colors.grey[600],
// //                                 ),
// //                                 maxLines: 1,
// //                                 overflow: TextOverflow.ellipsis,
// //                               ),
// //                           ],
// //                         ),
// //                       ),
// //                     );
// //                   }).toList(),
// //                   onChanged: (ServiceSuggestion? newValue) {
// //                     setModalState(() {
// //                       selectedExistingService = newValue;
// //                       if (newValue != null) {
// //                         nameController.text = newValue.intituleService;
// //                         // ✅ SUPPRIMÉ : Plus de description à pré-remplir
// //                         descriptionController.clear();
// //                         // ✅ SUPPRIMÉ : Plus de prix/durée suggérés
// //                         priceController.clear();
// //                         durationController.clear();
// //                       }
// //                     });
// //                   },
// //                 ),
// //               ),
// //
// //               // ✅ NOUVEAU : Info du service sélectionné (simplifiée)
// //               if (selectedExistingService != null) ...[
// //                 const SizedBox(height: 16),
// //                 Container(
// //                   padding: const EdgeInsets.all(16),
// //                   decoration: BoxDecoration(
// //                     color: Colors.blue[50],
// //                     borderRadius: BorderRadius.circular(12),
// //                     border: Border.all(color: Colors.blue[200]!),
// //                   ),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Row(
// //                         children: [
// //                           Icon(Icons.info_outline, color: Colors.blue[700]),
// //                           const SizedBox(width: 8),
// //                           Text(
// //                             "Service sélectionné",
// //                             style: TextStyle(
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.blue[700],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         "Service: ${selectedExistingService!.intituleService}",
// //                         style: TextStyle(color: Colors.blue[600], fontSize: 13),
// //                       ),
// //                       if (selectedExistingService!.categorieNom != null) ...[
// //                         const SizedBox(height: 4),
// //                         Text(
// //                           "Catégorie: ${selectedExistingService!.categorieNom}",
// //                           style: TextStyle(color: Colors.blue[600], fontSize: 13),
// //                         ),
// //                       ],
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         "Veuillez définir le prix et la durée pour votre salon.",
// //                         style: TextStyle(
// //                           color: Colors.blue[500],
// //                           fontSize: 12,
// //                           fontStyle: FontStyle.italic,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ]
// //             // Aucun service disponible
// //             else ...[
// //                 Container(
// //                   padding: const EdgeInsets.all(16),
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey[50],
// //                     borderRadius: BorderRadius.circular(14),
// //                     border: Border.all(color: Colors.grey[300]!),
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.info_outline, color: Colors.grey[600]),
// //                       const SizedBox(width: 12),
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text(
// //                               "Aucun service disponible",
// //                               style: TextStyle(
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Colors.grey[700],
// //                               ),
// //                             ),
// //                             Text(
// //                               "Passez en mode 'Créer nouveau' pour ajouter un service",
// //                               style: TextStyle(
// //                                 fontSize: 12,
// //                                 color: Colors.grey[600],
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ NOUVEAU : Widget pour afficher la catégorie en lecture seule
// //   Widget buildCategoryDisplay() {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: Container(
// //         padding: const EdgeInsets.all(16),
// //         decoration: BoxDecoration(
// //           color: Colors.grey[100],
// //           borderRadius: BorderRadius.circular(14),
// //           border: Border.all(color: Colors.grey[300]!),
// //         ),
// //         child: Row(
// //           children: [
// //             Icon(Icons.category, color: Colors.grey[600]),
// //             const SizedBox(width: 12),
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   "Catégorie",
// //                   style: TextStyle(
// //                     fontSize: 12,
// //                     color: Colors.grey[600],
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   selectedExistingService?.categorieNom ?? "Sans catégorie",
// //                   style: const TextStyle(
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const Spacer(),
// //             Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //               decoration: BoxDecoration(
// //                 color: primaryViolet.withOpacity(0.1),
// //                 borderRadius: BorderRadius.circular(6),
// //               ),
// //               child: Text(
// //                 "Automatique",
// //                 style: TextStyle(
// //                   color: primaryViolet,
// //                   fontSize: 12,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //   Widget buildCategorySelector(StateSetter setModalState) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: Container(
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(14),
// //         ),
// //         child: Builder(
// //           builder: (context) {
// //             if (categoriesProvider.isLoading) {
// //               return const Padding(
// //                 padding: EdgeInsets.all(16),
// //                 child: Row(
// //                   children: [
// //                     Icon(Icons.category, color: Color(0xFF7B61FF)),
// //                     SizedBox(width: 12),
// //                     Text("Chargement des catégories..."),
// //                     Spacer(),
// //                     SizedBox(
// //                       width: 20,
// //                       height: 20,
// //                       child: CircularProgressIndicator(strokeWidth: 2),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             }
// //
// //             if (categoriesProvider.hasError) {
// //               return Padding(
// //                 padding: const EdgeInsets.all(16),
// //                 child: Row(
// //                   children: [
// //                     const Icon(Icons.error, color: Colors.red),
// //                     const SizedBox(width: 12),
// //                     Expanded(
// //                       child: Text(
// //                         "Erreur : ${categoriesProvider.errorMessage}",
// //                         style: const TextStyle(color: Colors.red),
// //                       ),
// //                     ),
// //                     IconButton(
// //                       icon: const Icon(Icons.refresh),
// //                       onPressed: () {
// //                         categoriesProvider.refreshCategories();
// //                         setModalState(() {});
// //                       },
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             }
// //
// //             final categories = categoriesProvider.categoriesSorted;
// //
// //             if (categories.isEmpty) {
// //               return const Padding(
// //                 padding: EdgeInsets.all(16),
// //                 child: Row(
// //                   children: [
// //                     Icon(Icons.category, color: Colors.grey),
// //                     SizedBox(width: 12),
// //                     Text("Aucune catégorie disponible"),
// //                   ],
// //                 ),
// //               );
// //             }
// //
// //             return DropdownButtonFormField<Categorie>(
// //               value: selectedCategory,
// //               decoration: InputDecoration(
// //                 prefixIcon: Icon(Icons.category, color: primaryViolet),
// //                 labelText: "Catégorie *",
// //                 filled: true,
// //                 fillColor: Colors.white,
// //                 border: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(14),
// //                   borderSide: BorderSide.none,
// //                 ),
// //               ),
// //               hint: const Text("Sélectionner une catégorie"),
// //               items: categories.map((Categorie category) {
// //                 return DropdownMenuItem<Categorie>(
// //                   value: category,
// //                   child: Text(
// //                     category.nom,
// //                     style: const TextStyle(fontSize: 16),
// //                   ),
// //                 );
// //               }).toList(),
// //               onChanged: (Categorie? newValue) {
// //                 setModalState(() {
// //                   selectedCategory = newValue;
// //                 });
// //               },
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Future<void> addService(StateSetter setModalState) async {
// //     // ✅ Validation selon le mode
// //     if (isAddExistingMode) {
// //       // Mode ajouter existant
// //       if (selectedExistingService == null) {
// //         showErrorDialog(context, "Veuillez sélectionner un service.");
// //         return;
// //       }
// //       // ✅ SUPPRIMÉ : Pas besoin de vérifier selectedCategory pour service existant
// //       if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) {
// //         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
// //         return;
// //       }
// //     } else {
// //       // Mode créer nouveau
// //       if (selectedCategory == null) {
// //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// //         return;
// //       }
// //       if (nameController.text.trim().isEmpty ||
// //           descriptionController.text.trim().isEmpty ||
// //           priceController.text.trim().isEmpty ||
// //           durationController.text.trim().isEmpty) {
// //         showErrorDialog(context, "Tous les champs sont obligatoires.");
// //         return;
// //       }
// //     }
// //
// //     final String intitule = nameController.text.trim();
// //     final String description = descriptionController.text.trim();
// //     final String prixText = priceController.text.trim();
// //     final String durationText = durationController.text.trim();
// //
// //     // Validation des nombres
// //     final double? prix = double.tryParse(prixText);
// //     final int? temps = int.tryParse(durationText);
// //
// //     if (prix == null || temps == null) {
// //       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
// //       return;
// //     }
// //
// //     if (prix > 999) {
// //       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
// //       return;
// //     }
// //
// //     if (temps > 480) {
// //       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
// //       return;
// //     }
// //
// //     // Validation supplémentaire pour nouveau service
// //     if (!isAddExistingMode) {
// //       if (intitule.length > 100) {
// //         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
// //         return;
// //       }
// //       if (description.length > 700) {
// //         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
// //         return;
// //       }
// //     }
// //
// //     setModalState(() => isLoading = true);
// //
// //     try {
// //       final String? idToken = await TokenService.getAuthToken();
// //
// //       if (idToken == null) {
// //         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
// //         setModalState(() => isLoading = false);
// //         return;
// //       }
// //
// //       http.Response response;
// //
// //       if (isAddExistingMode) {
// //         // ✅ API pour ajouter un service existant (sans categorie_id)
// //         response = await http.post(
// //           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// //           headers: {
// //             'Content-Type': 'application/json',
// //             'Authorization': 'Bearer $idToken',
// //           },
// //           body: json.encode({
// //             'userId': int.parse(coiffeuseId),
// //             'service_id': selectedExistingService!.id,
// //             'prix': prix,
// //             'temps_minutes': temps,
// //             // ✅ SUPPRIMÉ : 'categorie_id' car le service a déjà sa catégorie
// //           }),
// //         );
// //       } else {
// //         // ✅ API pour créer un nouveau service
// //         response = await http.post(
// //           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// //           headers: {
// //             'Content-Type': 'application/json',
// //             'Authorization': 'Bearer $idToken',
// //           },
// //           body: json.encode({
// //             'userId': int.parse(coiffeuseId),
// //             'intitule_service': intitule,
// //             'description': description,
// //             'prix': prix,
// //             'temps_minutes': temps,
// //             'categorie_id': selectedCategory!.id,
// //           }),
// //         );
// //       }
// //
// //       if (kDebugMode) {
// //         print("📊 Status code: ${response.statusCode}");
// //         print("📋 Réponse: ${response.body}");
// //       }
// //
// //       if (response.statusCode == 201) {
// //         Navigator.pop(context, true);
// //         onSuccess();
// //
// //         showSuccessDialog(
// //             context,
// //             isAddExistingMode
// //                 ? "Service '$intitule' ajouté avec succès !"
// //                 : "Service '$intitule' créé et ajouté avec succès !"
// //         );
// //       } else {
// //         Map<String, dynamic> errorResponse = {};
// //         try {
// //           errorResponse = json.decode(response.body);
// //         } catch (e) {
// //           // Si la réponse n'est pas du JSON valide
// //         }
// //
// //         String errorMessage = errorResponse['message'] ??
// //             errorResponse['detail'] ??
// //             "Erreur lors de l'ajout du service (${response.statusCode})";
// //
// //         if (response.statusCode == 401) {
// //           await TokenService.clearAuthToken();
// //         }
// //
// //         showErrorDialog(context, errorMessage);
// //       }
// //     } catch (e) {
// //       showErrorDialog(context, "Erreur de connexion: $e");
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   return showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) {
// //       return StatefulBuilder(
// //         builder: (BuildContext context, StateSetter setModalState) {
// //           return AnimatedPadding(
// //             duration: const Duration(milliseconds: 300),
// //             curve: Curves.easeOut,
// //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// //             child: DraggableScrollableSheet(
// //               initialChildSize: 0.85,
// //               maxChildSize: 0.95,
// //               minChildSize: 0.5,
// //               expand: false,
// //               builder: (context, scrollController) => Container(
// //                 decoration: const BoxDecoration(
// //                   color: Color(0xFFF7F7F9),
// //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //                 ),
// //                 padding: const EdgeInsets.all(20),
// //                 child: ListView(
// //                   controller: scrollController,
// //                   children: [
// //                     Center(
// //                       child: Container(
// //                         width: 40,
// //                         height: 5,
// //                         margin: const EdgeInsets.only(bottom: 20),
// //                         decoration: BoxDecoration(
// //                           color: Colors.grey[300],
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                       ),
// //                     ),
// //
// //                     Text(
// //                       "Ajouter un service",
// //                       style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
// //                     ),
// //                     const SizedBox(height: 20),
// //
// //                     // ✅ Toggle entre les modes
// //                     buildModeToggle(setModalState),
// //
// //                     // ✅ Sélecteur de service existant (mis à jour)
// //                     buildExistingServiceSelector(setModalState),
// //
// //                     // ✅ Champs selon le mode
// //                     if (!isAddExistingMode) ...[
// //                       buildTextField("Nom du service *", nameController, Icons.design_services),
// //                       buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
// //                       // ✅ Catégorie seulement pour nouveau service
// //                       buildCategorySelector(setModalState),
// //                     ] else if (selectedExistingService != null) ...[
// //                       buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
// //                       // ✅ Affichage de la catégorie en lecture seule
// //                       buildCategoryDisplay(),
// //                     ],
// //
// //                     // ✅ Prix et durée (toujours modifiables)
// //                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
// //
// //                     const SizedBox(height: 20),
// //
// //                     SizedBox(
// //                       width: double.infinity,
// //                       child: ElevatedButton(
// //                         onPressed: isLoading ? null : () => addService(setModalState),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: primaryViolet,
// //                           padding: const EdgeInsets.symmetric(vertical: 16),
// //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                           elevation: 4,
// //                         ),
// //                         child: isLoading
// //                             ? const CircularProgressIndicator(color: Colors.white)
// //                             : Text(
// //                             isAddExistingMode ? "Ajouter au salon" : "Créer le service",
// //                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       );
// //     },
// //   );
// // }
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/categorie.dart';
// // import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:flutter/foundation.dart';
// // import '../../../../../services/firebase_token/token_service.dart';
// // import '../components/show_dialog.dart';
// //
// // Future<void> showAddServiceModal(
// //     BuildContext context,
// //     String coiffeuseId,
// //     VoidCallback onSuccess,
// //     CategoriesProvider categoriesProvider,
// //     ServicesProvider servicesProvider,
// //     ) {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   final TextEditingController durationController = TextEditingController();
// //
// //   // ✅ Gestion de la catégorie sélectionnée
// //   Categorie? selectedCategory;
// //
// //   // ✅ Gestion du mode et service sélectionné
// //   bool isAddExistingMode = true; // Mode par défaut : ajouter service existant
// //   ServiceSuggestion? selectedExistingService;
// //
// //   bool isLoading = false;
// //   final Color primaryViolet = const Color(0xFF7B61FF);
// //
// //   // ✅ Charger les services au démarrage si pas encore fait
// //   if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
// //     servicesProvider.loadAllServices();
// //   }
// //
// //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// //       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         keyboardType: keyboardType,
// //         enabled: enabled,
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
// //           labelText: label,
// //           filled: true,
// //           fillColor: enabled ? Colors.white : Colors.grey[100],
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(14),
// //             borderSide: BorderSide.none,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ✅ Widget pour basculer entre les modes
// //   Widget buildModeToggle(StateSetter setModalState) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 24),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey[300]!),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: GestureDetector(
// //               onTap: () {
// //                 setModalState(() {
// //                   isAddExistingMode = true;
// //                   selectedExistingService = null;
// //                   nameController.clear();
// //                   descriptionController.clear();
// //                   priceController.clear();
// //                   durationController.clear();
// //                   selectedCategory = null;
// //                 });
// //               },
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(vertical: 12),
// //                 decoration: BoxDecoration(
// //                   color: isAddExistingMode ? primaryViolet : Colors.transparent,
// //                   borderRadius: const BorderRadius.only(
// //                     topLeft: Radius.circular(12),
// //                     bottomLeft: Radius.circular(12),
// //                   ),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(
// //                       Icons.add_circle_outline,
// //                       color: isAddExistingMode ? Colors.white : primaryViolet,
// //                       size: 20,
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Text(
// //                       "Ajouter existant",
// //                       style: TextStyle(
// //                         color: isAddExistingMode ? Colors.white : primaryViolet,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: GestureDetector(
// //               onTap: () {
// //                 setModalState(() {
// //                   isAddExistingMode = false;
// //                   selectedExistingService = null;
// //                   nameController.clear();
// //                   descriptionController.clear();
// //                   priceController.clear();
// //                   durationController.clear();
// //                   selectedCategory = null;
// //                 });
// //               },
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(vertical: 12),
// //                 decoration: BoxDecoration(
// //                   color: !isAddExistingMode ? primaryViolet : Colors.transparent,
// //                   borderRadius: const BorderRadius.only(
// //                     topRight: Radius.circular(12),
// //                     bottomRight: Radius.circular(12),
// //                   ),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(
// //                       Icons.create,
// //                       color: !isAddExistingMode ? Colors.white : primaryViolet,
// //                       size: 20,
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Text(
// //                       "Créer nouveau",
// //                       style: TextStyle(
// //                         color: !isAddExistingMode ? Colors.white : primaryViolet,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ NOUVEAU : Dropdown pour sélectionner un service existant (mis à jour)
// //   Widget buildExistingServiceSelector(StateSetter setModalState) {
// //     if (!isAddExistingMode) return const SizedBox.shrink();
// //
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Loading state
// //           if (servicesProvider.isLoading) ...[
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(14),
// //               ),
// //               child: const Row(
// //                 children: [
// //                   Icon(Icons.design_services, color: Color(0xFF7B61FF)),
// //                   SizedBox(width: 12),
// //                   Text("Chargement des services..."),
// //                   Spacer(),
// //                   SizedBox(
// //                     width: 20,
// //                     height: 20,
// //                     child: CircularProgressIndicator(strokeWidth: 2),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ]
// //           // Error state
// //           else if (servicesProvider.hasError) ...[
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: Colors.red[50],
// //                 borderRadius: BorderRadius.circular(14),
// //                 border: Border.all(color: Colors.red[200]!),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Icon(Icons.error, color: Colors.red[700]),
// //                   const SizedBox(width: 12),
// //                   Expanded(
// //                     child: Text(
// //                       "Erreur: ${servicesProvider.errorMessage}",
// //                       style: TextStyle(color: Colors.red[700]),
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(Icons.refresh),
// //                     onPressed: () {
// //                       servicesProvider.loadAllServices();
// //                       setModalState(() {});
// //                     },
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ]
// //           // Services disponibles
// //           else if (servicesProvider.allServices.isNotEmpty) ...[
// //               Container(
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(14),
// //                 ),
// //                 child: DropdownButtonFormField<ServiceSuggestion>(
// //                   value: selectedExistingService,
// //                   decoration: InputDecoration(
// //                     prefixIcon: Icon(Icons.design_services, color: primaryViolet),
// //                     labelText: "Service à ajouter *",
// //                     filled: true,
// //                     fillColor: Colors.white,
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(14),
// //                       borderSide: BorderSide.none,
// //                     ),
// //                   ),
// //                   hint: const Text("Sélectionner un service"),
// //                   items: servicesProvider.allServices.map((ServiceSuggestion service) {
// //                     return DropdownMenuItem<ServiceSuggestion>(
// //                       value: service,
// //                       child: Container(
// //                         width: double.infinity,
// //                         constraints: const BoxConstraints(maxWidth: 300),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           mainAxisSize: MainAxisSize.min,
// //                           children: [
// //                             Text(
// //                               service.intituleService,
// //                               style: const TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                               ),
// //                               maxLines: 1,
// //                               overflow: TextOverflow.ellipsis,
// //                             ),
// //                             // ✅ NOUVEAU : Affichage de la catégorie au lieu de la description
// //                             if (service.categorieNom != null)
// //                               Text(
// //                                 service.categorieNom!,
// //                                 style: TextStyle(
// //                                   fontSize: 12,
// //                                   color: Colors.grey[600],
// //                                 ),
// //                                 maxLines: 1,
// //                                 overflow: TextOverflow.ellipsis,
// //                               ),
// //                           ],
// //                         ),
// //                       ),
// //                     );
// //                   }).toList(),
// //                   onChanged: (ServiceSuggestion? newValue) {
// //                     setModalState(() {
// //                       selectedExistingService = newValue;
// //                       if (newValue != null) {
// //                         nameController.text = newValue.intituleService;
// //                         // ✅ SUPPRIMÉ : Plus de description à pré-remplir
// //                         descriptionController.clear();
// //                         // ✅ SUPPRIMÉ : Plus de prix/durée suggérés
// //                         priceController.clear();
// //                         durationController.clear();
// //                       }
// //                     });
// //                   },
// //                 ),
// //               ),
// //
// //               // ✅ NOUVEAU : Info du service sélectionné (simplifiée)
// //               if (selectedExistingService != null) ...[
// //                 const SizedBox(height: 16),
// //                 Container(
// //                   padding: const EdgeInsets.all(16),
// //                   decoration: BoxDecoration(
// //                     color: Colors.blue[50],
// //                     borderRadius: BorderRadius.circular(12),
// //                     border: Border.all(color: Colors.blue[200]!),
// //                   ),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Row(
// //                         children: [
// //                           Icon(Icons.info_outline, color: Colors.blue[700]),
// //                           const SizedBox(width: 8),
// //                           Text(
// //                             "Service sélectionné",
// //                             style: TextStyle(
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.blue[700],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         "Service: ${selectedExistingService!.intituleService}",
// //                         style: TextStyle(color: Colors.blue[600], fontSize: 13),
// //                       ),
// //                       if (selectedExistingService!.categorieNom != null) ...[
// //                         const SizedBox(height: 4),
// //                         Text(
// //                           "Catégorie: ${selectedExistingService!.categorieNom}",
// //                           style: TextStyle(color: Colors.blue[600], fontSize: 13),
// //                         ),
// //                       ],
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         "Veuillez définir le prix et la durée pour votre salon.",
// //                         style: TextStyle(
// //                           color: Colors.blue[500],
// //                           fontSize: 12,
// //                           fontStyle: FontStyle.italic,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ]
// //             // Aucun service disponible
// //             else ...[
// //                 Container(
// //                   padding: const EdgeInsets.all(16),
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey[50],
// //                     borderRadius: BorderRadius.circular(14),
// //                     border: Border.all(color: Colors.grey[300]!),
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.info_outline, color: Colors.grey[600]),
// //                       const SizedBox(width: 12),
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text(
// //                               "Aucun service disponible",
// //                               style: TextStyle(
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Colors.grey[700],
// //                               ),
// //                             ),
// //                             Text(
// //                               "Passez en mode 'Créer nouveau' pour ajouter un service",
// //                               style: TextStyle(
// //                                 fontSize: 12,
// //                                 color: Colors.grey[600],
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ Widget pour sélectionner la catégorie (inchangé)
// //   Widget buildCategorySelector(StateSetter setModalState) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 20),
// //       child: Container(
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(14),
// //         ),
// //         child: Builder(
// //           builder: (context) {
// //             if (categoriesProvider.isLoading) {
// //               return const Padding(
// //                 padding: EdgeInsets.all(16),
// //                 child: Row(
// //                   children: [
// //                     Icon(Icons.category, color: Color(0xFF7B61FF)),
// //                     SizedBox(width: 12),
// //                     Text("Chargement des catégories..."),
// //                     Spacer(),
// //                     SizedBox(
// //                       width: 20,
// //                       height: 20,
// //                       child: CircularProgressIndicator(strokeWidth: 2),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             }
// //
// //             if (categoriesProvider.hasError) {
// //               return Padding(
// //                 padding: const EdgeInsets.all(16),
// //                 child: Row(
// //                   children: [
// //                     const Icon(Icons.error, color: Colors.red),
// //                     const SizedBox(width: 12),
// //                     Expanded(
// //                       child: Text(
// //                         "Erreur : ${categoriesProvider.errorMessage}",
// //                         style: const TextStyle(color: Colors.red),
// //                       ),
// //                     ),
// //                     IconButton(
// //                       icon: const Icon(Icons.refresh),
// //                       onPressed: () {
// //                         categoriesProvider.refreshCategories();
// //                         setModalState(() {});
// //                       },
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             }
// //
// //             final categories = categoriesProvider.categoriesSorted;
// //
// //             if (categories.isEmpty) {
// //               return const Padding(
// //                 padding: EdgeInsets.all(16),
// //                 child: Row(
// //                   children: [
// //                     Icon(Icons.category, color: Colors.grey),
// //                     SizedBox(width: 12),
// //                     Text("Aucune catégorie disponible"),
// //                   ],
// //                 ),
// //               );
// //             }
// //
// //             return DropdownButtonFormField<Categorie>(
// //               value: selectedCategory,
// //               decoration: InputDecoration(
// //                 prefixIcon: Icon(Icons.category, color: primaryViolet),
// //                 labelText: "Catégorie *",
// //                 filled: true,
// //                 fillColor: Colors.white,
// //                 border: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(14),
// //                   borderSide: BorderSide.none,
// //                 ),
// //               ),
// //               hint: const Text("Sélectionner une catégorie"),
// //               items: categories.map((Categorie category) {
// //                 return DropdownMenuItem<Categorie>(
// //                   value: category,
// //                   child: Text(
// //                     category.nom,
// //                     style: const TextStyle(fontSize: 16),
// //                   ),
// //                 );
// //               }).toList(),
// //               onChanged: (Categorie? newValue) {
// //                 setModalState(() {
// //                   selectedCategory = newValue;
// //                 });
// //               },
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Future<void> addService(StateSetter setModalState) async {
// //     // ✅ Validation selon le mode
// //     if (isAddExistingMode) {
// //       // Mode ajouter existant
// //       if (selectedExistingService == null) {
// //         showErrorDialog(context, "Veuillez sélectionner un service.");
// //         return;
// //       }
// //       if (selectedCategory == null) {
// //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// //         return;
// //       }
// //       if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) {
// //         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
// //         return;
// //       }
// //     } else {
// //       // Mode créer nouveau
// //       if (selectedCategory == null) {
// //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// //         return;
// //       }
// //       if (nameController.text.trim().isEmpty ||
// //           descriptionController.text.trim().isEmpty ||
// //           priceController.text.trim().isEmpty ||
// //           durationController.text.trim().isEmpty) {
// //         showErrorDialog(context, "Tous les champs sont obligatoires.");
// //         return;
// //       }
// //     }
// //
// //     final String intitule = nameController.text.trim();
// //     final String description = descriptionController.text.trim();
// //     final String prixText = priceController.text.trim();
// //     final String durationText = durationController.text.trim();
// //
// //     // Validation des nombres
// //     final double? prix = double.tryParse(prixText);
// //     final int? temps = int.tryParse(durationText);
// //
// //     if (prix == null || temps == null) {
// //       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
// //       return;
// //     }
// //
// //     if (prix > 999) {
// //       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
// //       return;
// //     }
// //
// //     if (temps > 480) {
// //       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
// //       return;
// //     }
// //
// //     // Validation supplémentaire pour nouveau service
// //     if (!isAddExistingMode) {
// //       if (intitule.length > 100) {
// //         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
// //         return;
// //       }
// //       if (description.length > 700) {
// //         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
// //         return;
// //       }
// //     }
// //
// //     setModalState(() => isLoading = true);
// //
// //     try {
// //       final String? idToken = await TokenService.getAuthToken();
// //
// //       if (idToken == null) {
// //         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
// //         setModalState(() => isLoading = false);
// //         return;
// //       }
// //
// //       http.Response response;
// //
// //       if (isAddExistingMode) {
// //         // ✅ API pour ajouter un service existant
// //         response = await http.post(
// //           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// //           headers: {
// //             'Content-Type': 'application/json',
// //             'Authorization': 'Bearer $idToken',
// //           },
// //           body: json.encode({
// //             'userId': int.parse(coiffeuseId),
// //             'service_id': selectedExistingService!.id,
// //             'prix': prix,
// //             'temps_minutes': temps,
// //             'categorie_id': selectedCategory!.id,
// //           }),
// //         );
// //       } else {
// //         // ✅ API pour créer un nouveau service
// //         response = await http.post(
// //           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// //           headers: {
// //             'Content-Type': 'application/json',
// //             'Authorization': 'Bearer $idToken',
// //           },
// //           body: json.encode({
// //             'userId': int.parse(coiffeuseId),
// //             'intitule_service': intitule,
// //             'description': description,
// //             'prix': prix,
// //             'temps_minutes': temps,
// //             'categorie_id': selectedCategory!.id,
// //           }),
// //         );
// //       }
// //
// //       if (kDebugMode) {
// //         print("📊 Status code: ${response.statusCode}");
// //         print("📋 Réponse: ${response.body}");
// //       }
// //
// //       if (response.statusCode == 201) {
// //         Navigator.pop(context, true);
// //         onSuccess();
// //
// //         showSuccessDialog(
// //             context,
// //             isAddExistingMode
// //                 ? "Service '$intitule' ajouté avec succès !"
// //                 : "Service '$intitule' créé et ajouté avec succès !"
// //         );
// //       } else {
// //         Map<String, dynamic> errorResponse = {};
// //         try {
// //           errorResponse = json.decode(response.body);
// //         } catch (e) {
// //           // Si la réponse n'est pas du JSON valide
// //         }
// //
// //         String errorMessage = errorResponse['message'] ??
// //             errorResponse['detail'] ??
// //             "Erreur lors de l'ajout du service (${response.statusCode})";
// //
// //         if (response.statusCode == 401) {
// //           await TokenService.clearAuthToken();
// //         }
// //
// //         showErrorDialog(context, errorMessage);
// //       }
// //     } catch (e) {
// //       showErrorDialog(context, "Erreur de connexion: $e");
// //     } finally {
// //       setModalState(() => isLoading = false);
// //     }
// //   }
// //
// //   return showModalBottomSheet(
// //     context: context,
// //     isScrollControlled: true,
// //     backgroundColor: Colors.transparent,
// //     builder: (context) {
// //       return StatefulBuilder(
// //         builder: (BuildContext context, StateSetter setModalState) {
// //           return AnimatedPadding(
// //             duration: const Duration(milliseconds: 300),
// //             curve: Curves.easeOut,
// //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// //             child: DraggableScrollableSheet(
// //               initialChildSize: 0.85,
// //               maxChildSize: 0.95,
// //               minChildSize: 0.5,
// //               expand: false,
// //               builder: (context, scrollController) => Container(
// //                 decoration: const BoxDecoration(
// //                   color: Color(0xFFF7F7F9),
// //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// //                 ),
// //                 padding: const EdgeInsets.all(20),
// //                 child: ListView(
// //                   controller: scrollController,
// //                   children: [
// //                     Center(
// //                       child: Container(
// //                         width: 40,
// //                         height: 5,
// //                         margin: const EdgeInsets.only(bottom: 20),
// //                         decoration: BoxDecoration(
// //                           color: Colors.grey[300],
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                       ),
// //                     ),
// //
// //                     Text(
// //                       "Ajouter un service",
// //                       style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
// //                     ),
// //                     const SizedBox(height: 20),
// //
// //                     // ✅ Toggle entre les modes
// //                     buildModeToggle(setModalState),
// //
// //                     // ✅ Sélecteur de service existant (mis à jour)
// //                     buildExistingServiceSelector(setModalState),
// //
// //                     // ✅ Champs selon le mode
// //                     if (!isAddExistingMode) ...[
// //                       buildTextField("Nom du service *", nameController, Icons.design_services),
// //                       buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
// //                     ] else if (selectedExistingService != null) ...[
// //                       buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
// //                       // ✅ SUPPRIMÉ : Champ description pour le mode existant
// //                     ],
// //
// //                     // ✅ Catégorie (obligatoire dans les deux modes)
// //                     buildCategorySelector(setModalState),
// //
// //                     // ✅ Prix et durée (toujours modifiables)
// //                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
// //                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
// //
// //                     const SizedBox(height: 20),
// //
// //                     SizedBox(
// //                       width: double.infinity,
// //                       child: ElevatedButton(
// //                         onPressed: isLoading ? null : () => addService(setModalState),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: primaryViolet,
// //                           padding: const EdgeInsets.symmetric(vertical: 16),
// //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //                           elevation: 4,
// //                         ),
// //                         child: isLoading
// //                             ? const CircularProgressIndicator(color: Colors.white)
// //                             : Text(
// //                             isAddExistingMode ? "Ajouter au salon" : "Créer le service",
// //                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       );
// //     },
// //   );
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/models/categorie.dart';
// // // import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// // // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import 'package:flutter/foundation.dart';
// // // import '../../../../../services/firebase_token/token_service.dart';
// // // import '../components/show_dialog.dart';
// // //
// // // Future<void> showAddServiceModal(
// // //     BuildContext context,
// // //     String coiffeuseId,
// // //     VoidCallback onSuccess,
// // //     CategoriesProvider categoriesProvider,
// // //     ServicesProvider servicesProvider,
// // //     ) {
// // //   final TextEditingController nameController = TextEditingController();
// // //   final TextEditingController descriptionController = TextEditingController();
// // //   final TextEditingController priceController = TextEditingController();
// // //   final TextEditingController durationController = TextEditingController();
// // //
// // //   // ✅ Gestion de la catégorie sélectionnée
// // //   Categorie? selectedCategory;
// // //
// // //   // ✅ NOUVEAU : Gestion du mode et service sélectionné
// // //   bool isAddExistingMode = true; // Mode par défaut : ajouter service existant
// // //   ServiceSuggestion? selectedExistingService;
// // //
// // //   bool isLoading = false;
// // //   final Color primaryViolet = const Color(0xFF7B61FF);
// // //
// // //   // ✅ Charger les services au démarrage si pas encore fait
// // //   if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
// // //     servicesProvider.loadAllServices();
// // //   }
// // //
// // //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// // //       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 20),
// // //       child: TextField(
// // //         controller: controller,
// // //         maxLines: maxLines,
// // //         keyboardType: keyboardType,
// // //         enabled: enabled,
// // //         decoration: InputDecoration(
// // //           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
// // //           labelText: label,
// // //           filled: true,
// // //           fillColor: enabled ? Colors.white : Colors.grey[100],
// // //           border: OutlineInputBorder(
// // //             borderRadius: BorderRadius.circular(14),
// // //             borderSide: BorderSide.none,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ NOUVEAU : Widget pour basculer entre les modes
// // //   Widget buildModeToggle(StateSetter setModalState) {
// // //     return Container(
// // //       margin: const EdgeInsets.only(bottom: 24),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: Colors.grey[300]!),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           Expanded(
// // //             child: GestureDetector(
// // //               onTap: () {
// // //                 setModalState(() {
// // //                   isAddExistingMode = true;
// // //                   selectedExistingService = null;
// // //                   nameController.clear();
// // //                   descriptionController.clear();
// // //                   priceController.clear();
// // //                   durationController.clear();
// // //                   selectedCategory = null;
// // //                 });
// // //               },
// // //               child: Container(
// // //                 padding: const EdgeInsets.symmetric(vertical: 12),
// // //                 decoration: BoxDecoration(
// // //                   color: isAddExistingMode ? primaryViolet : Colors.transparent,
// // //                   borderRadius: const BorderRadius.only(
// // //                     topLeft: Radius.circular(12),
// // //                     bottomLeft: Radius.circular(12),
// // //                   ),
// // //                 ),
// // //                 child: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     Icon(
// // //                       Icons.add_circle_outline,
// // //                       color: isAddExistingMode ? Colors.white : primaryViolet,
// // //                       size: 20,
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     Text(
// // //                       "Ajouter existant",
// // //                       style: TextStyle(
// // //                         color: isAddExistingMode ? Colors.white : primaryViolet,
// // //                         fontWeight: FontWeight.w600,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //           Expanded(
// // //             child: GestureDetector(
// // //               onTap: () {
// // //                 setModalState(() {
// // //                   isAddExistingMode = false;
// // //                   selectedExistingService = null;
// // //                   nameController.clear();
// // //                   descriptionController.clear();
// // //                   priceController.clear();
// // //                   durationController.clear();
// // //                   selectedCategory = null;
// // //                 });
// // //               },
// // //               child: Container(
// // //                 padding: const EdgeInsets.symmetric(vertical: 12),
// // //                 decoration: BoxDecoration(
// // //                   color: !isAddExistingMode ? primaryViolet : Colors.transparent,
// // //                   borderRadius: const BorderRadius.only(
// // //                     topRight: Radius.circular(12),
// // //                     bottomRight: Radius.circular(12),
// // //                   ),
// // //                 ),
// // //                 child: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     Icon(
// // //                       Icons.create,
// // //                       color: !isAddExistingMode ? Colors.white : primaryViolet,
// // //                       size: 20,
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     Text(
// // //                       "Créer nouveau",
// // //                       style: TextStyle(
// // //                         color: !isAddExistingMode ? Colors.white : primaryViolet,
// // //                         fontWeight: FontWeight.w600,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ NOUVEAU : Dropdown pour sélectionner un service existant
// // //   Widget buildExistingServiceSelector(StateSetter setModalState) {
// // //     if (!isAddExistingMode) return const SizedBox.shrink();
// // //
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 20),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           // Loading state
// // //           if (servicesProvider.isLoading) ...[
// // //             Container(
// // //               padding: const EdgeInsets.all(16),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white,
// // //                 borderRadius: BorderRadius.circular(14),
// // //               ),
// // //               child: const Row(
// // //                 children: [
// // //                   Icon(Icons.design_services, color: Color(0xFF7B61FF)),
// // //                   SizedBox(width: 12),
// // //                   Text("Chargement des services..."),
// // //                   Spacer(),
// // //                   SizedBox(
// // //                     width: 20,
// // //                     height: 20,
// // //                     child: CircularProgressIndicator(strokeWidth: 2),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ]
// // //           // Error state
// // //           else if (servicesProvider.hasError) ...[
// // //             Container(
// // //               padding: const EdgeInsets.all(16),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.red[50],
// // //                 borderRadius: BorderRadius.circular(14),
// // //                 border: Border.all(color: Colors.red[200]!),
// // //               ),
// // //               child: Row(
// // //                 children: [
// // //                   Icon(Icons.error, color: Colors.red[700]),
// // //                   const SizedBox(width: 12),
// // //                   Expanded(
// // //                     child: Text(
// // //                       "Erreur: ${servicesProvider.errorMessage}",
// // //                       style: TextStyle(color: Colors.red[700]),
// // //                     ),
// // //                   ),
// // //                   IconButton(
// // //                     icon: const Icon(Icons.refresh),
// // //                     onPressed: () {
// // //                       servicesProvider.loadAllServices();
// // //                       setModalState(() {});
// // //                     },
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ]
// // //           // Services disponibles
// // //           else if (servicesProvider.allServices.isNotEmpty) ...[
// // //               Container(
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white,
// // //                   borderRadius: BorderRadius.circular(14),
// // //                 ),
// // //                 child: DropdownButtonFormField<ServiceSuggestion>(
// // //                   value: selectedExistingService,
// // //                   decoration: InputDecoration(
// // //                     prefixIcon: Icon(Icons.design_services, color: primaryViolet),
// // //                     labelText: "Service à ajouter *",
// // //                     filled: true,
// // //                     fillColor: Colors.white,
// // //                     border: OutlineInputBorder(
// // //                       borderRadius: BorderRadius.circular(14),
// // //                       borderSide: BorderSide.none,
// // //                     ),
// // //                   ),
// // //                   hint: const Text("Sélectionner un service"),
// // //                   items: servicesProvider.allServices.map((ServiceSuggestion service) {
// // //                     return DropdownMenuItem<ServiceSuggestion>(
// // //                       value: service,
// // //                       child: Container(
// // //                         width: double.infinity,
// // //                         constraints: const BoxConstraints(maxWidth: 300),
// // //                         child: Column(
// // //                           crossAxisAlignment: CrossAxisAlignment.start,
// // //                           mainAxisSize: MainAxisSize.min,
// // //                           children: [
// // //                             Text(
// // //                               service.intituleService,
// // //                               style: const TextStyle(
// // //                                 fontSize: 16,
// // //                                 fontWeight: FontWeight.w600,
// // //                               ),
// // //                               maxLines: 1,
// // //                               overflow: TextOverflow.ellipsis,
// // //                             ),
// // //                             if (service.description.isNotEmpty)
// // //                               Text(
// // //                                 service.description,
// // //                                 style: TextStyle(
// // //                                   fontSize: 12,
// // //                                   color: Colors.grey[600],
// // //                                 ),
// // //                                 maxLines: 1,
// // //                                 overflow: TextOverflow.ellipsis,
// // //                               ),
// // //                           ],
// // //                         ),
// // //                       ),
// // //                     );
// // //                   }).toList(),
// // //                   onChanged: (ServiceSuggestion? newValue) {
// // //                     setModalState(() {
// // //                       selectedExistingService = newValue;
// // //                       if (newValue != null) {
// // //                         nameController.text = newValue.intituleService;
// // //                         descriptionController.text = newValue.description;
// // //                         // Pré-remplir prix et durée si disponibles
// // //                         if (newValue.prixSuggere != null) {
// // //                           priceController.text = newValue.prixSuggere.toString();
// // //                         }
// // //                         if (newValue.dureeSuggeree != null) {
// // //                           durationController.text = newValue.dureeSuggeree.toString();
// // //                         }
// // //                       }
// // //                     });
// // //                   },
// // //                 ),
// // //               ),
// // //
// // //               // Info du service sélectionné
// // //               if (selectedExistingService != null) ...[
// // //                 const SizedBox(height: 16),
// // //                 Container(
// // //                   padding: const EdgeInsets.all(16),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.blue[50],
// // //                     borderRadius: BorderRadius.circular(12),
// // //                     border: Border.all(color: Colors.blue[200]!),
// // //                   ),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Row(
// // //                         children: [
// // //                           Icon(Icons.info_outline, color: Colors.blue[700]),
// // //                           const SizedBox(width: 8),
// // //                           Text(
// // //                             "Service sélectionné",
// // //                             style: TextStyle(
// // //                               fontWeight: FontWeight.bold,
// // //                               color: Colors.blue[700],
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                       const SizedBox(height: 8),
// // //                       Text(
// // //                         selectedExistingService!.description,
// // //                         style: TextStyle(color: Colors.blue[600], fontSize: 13),
// // //                       ),
// // //                       const SizedBox(height: 8),
// // //                       Row(
// // //                         children: [
// // //                           if (selectedExistingService!.prixSuggere != null) ...[
// // //                             Container(
// // //                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                               decoration: BoxDecoration(
// // //                                 color: Colors.green.withOpacity(0.1),
// // //                                 borderRadius: BorderRadius.circular(6),
// // //                               ),
// // //                               child: Text(
// // //                                 "Prix suggéré: ${selectedExistingService!.prixSuggere}€",
// // //                                 style: const TextStyle(
// // //                                   color: Colors.green,
// // //                                   fontSize: 12,
// // //                                   fontWeight: FontWeight.w600,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                             const SizedBox(width: 8),
// // //                           ],
// // //                           if (selectedExistingService!.dureeSuggeree != null)
// // //                             Container(
// // //                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                               decoration: BoxDecoration(
// // //                                 color: primaryViolet.withOpacity(0.1),
// // //                                 borderRadius: BorderRadius.circular(6),
// // //                               ),
// // //                               child: Text(
// // //                                 "Durée suggérée: ${selectedExistingService!.dureeSuggeree}min",
// // //                                 style: TextStyle(
// // //                                   color: primaryViolet,
// // //                                   fontSize: 12,
// // //                                   fontWeight: FontWeight.w600,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                         ],
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ],
// // //             ]
// // //             // Aucun service disponible
// // //             else ...[
// // //                 Container(
// // //                   padding: const EdgeInsets.all(16),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.grey[50],
// // //                     borderRadius: BorderRadius.circular(14),
// // //                     border: Border.all(color: Colors.grey[300]!),
// // //                   ),
// // //                   child: Row(
// // //                     children: [
// // //                       Icon(Icons.info_outline, color: Colors.grey[600]),
// // //                       const SizedBox(width: 12),
// // //                       Expanded(
// // //                         child: Column(
// // //                           crossAxisAlignment: CrossAxisAlignment.start,
// // //                           children: [
// // //                             Text(
// // //                               "Aucun service disponible",
// // //                               style: TextStyle(
// // //                                 fontWeight: FontWeight.w600,
// // //                                 color: Colors.grey[700],
// // //                               ),
// // //                             ),
// // //                             Text(
// // //                               "Passez en mode 'Créer nouveau' pour ajouter un service",
// // //                               style: TextStyle(
// // //                                 fontSize: 12,
// // //                                 color: Colors.grey[600],
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ],
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ Widget pour sélectionner la catégorie
// // //   Widget buildCategorySelector(StateSetter setModalState) {
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 20),
// // //       child: Container(
// // //         decoration: BoxDecoration(
// // //           color: Colors.white,
// // //           borderRadius: BorderRadius.circular(14),
// // //         ),
// // //         child: Builder(
// // //           builder: (context) {
// // //             if (categoriesProvider.isLoading) {
// // //               return const Padding(
// // //                 padding: EdgeInsets.all(16),
// // //                 child: Row(
// // //                   children: [
// // //                     Icon(Icons.category, color: Color(0xFF7B61FF)),
// // //                     SizedBox(width: 12),
// // //                     Text("Chargement des catégories..."),
// // //                     Spacer(),
// // //                     SizedBox(
// // //                       width: 20,
// // //                       height: 20,
// // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             }
// // //
// // //             if (categoriesProvider.hasError) {
// // //               return Padding(
// // //                 padding: const EdgeInsets.all(16),
// // //                 child: Row(
// // //                   children: [
// // //                     const Icon(Icons.error, color: Colors.red),
// // //                     const SizedBox(width: 12),
// // //                     Expanded(
// // //                       child: Text(
// // //                         "Erreur : ${categoriesProvider.errorMessage}",
// // //                         style: const TextStyle(color: Colors.red),
// // //                       ),
// // //                     ),
// // //                     IconButton(
// // //                       icon: const Icon(Icons.refresh),
// // //                       onPressed: () {
// // //                         categoriesProvider.refreshCategories();
// // //                         setModalState(() {});
// // //                       },
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             }
// // //
// // //             final categories = categoriesProvider.categoriesSorted;
// // //
// // //             if (categories.isEmpty) {
// // //               return const Padding(
// // //                 padding: EdgeInsets.all(16),
// // //                 child: Row(
// // //                   children: [
// // //                     Icon(Icons.category, color: Colors.grey),
// // //                     SizedBox(width: 12),
// // //                     Text("Aucune catégorie disponible"),
// // //                   ],
// // //                 ),
// // //               );
// // //             }
// // //
// // //             return DropdownButtonFormField<Categorie>(
// // //               value: selectedCategory,
// // //               decoration: InputDecoration(
// // //                 prefixIcon: Icon(Icons.category, color: primaryViolet),
// // //                 labelText: "Catégorie *",
// // //                 filled: true,
// // //                 fillColor: Colors.white,
// // //                 border: OutlineInputBorder(
// // //                   borderRadius: BorderRadius.circular(14),
// // //                   borderSide: BorderSide.none,
// // //                 ),
// // //               ),
// // //               hint: const Text("Sélectionner une catégorie"),
// // //               items: categories.map((Categorie category) {
// // //                 return DropdownMenuItem<Categorie>(
// // //                   value: category,
// // //                   child: Text(
// // //                     category.nom,
// // //                     style: const TextStyle(fontSize: 16),
// // //                   ),
// // //                 );
// // //               }).toList(),
// // //               onChanged: (Categorie? newValue) {
// // //                 setModalState(() {
// // //                   selectedCategory = newValue;
// // //                 });
// // //               },
// // //             );
// // //           },
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Future<void> addService(StateSetter setModalState) async {
// // //     // ✅ Validation selon le mode
// // //     if (isAddExistingMode) {
// // //       // Mode ajouter existant
// // //       if (selectedExistingService == null) {
// // //         showErrorDialog(context, "Veuillez sélectionner un service.");
// // //         return;
// // //       }
// // //       if (selectedCategory == null) {
// // //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// // //         return;
// // //       }
// // //       if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) {
// // //         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
// // //         return;
// // //       }
// // //     } else {
// // //       // Mode créer nouveau
// // //       if (selectedCategory == null) {
// // //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// // //         return;
// // //       }
// // //       if (nameController.text.trim().isEmpty ||
// // //           descriptionController.text.trim().isEmpty ||
// // //           priceController.text.trim().isEmpty ||
// // //           durationController.text.trim().isEmpty) {
// // //         showErrorDialog(context, "Tous les champs sont obligatoires.");
// // //         return;
// // //       }
// // //     }
// // //
// // //     final String intitule = nameController.text.trim();
// // //     final String description = descriptionController.text.trim();
// // //     final String prixText = priceController.text.trim();
// // //     final String durationText = durationController.text.trim();
// // //
// // //     // Validation des nombres
// // //     final double? prix = double.tryParse(prixText);
// // //     final int? temps = int.tryParse(durationText);
// // //
// // //     if (prix == null || temps == null) {
// // //       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
// // //       return;
// // //     }
// // //
// // //     if (prix > 999) {
// // //       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
// // //       return;
// // //     }
// // //
// // //     if (temps > 480) {
// // //       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
// // //       return;
// // //     }
// // //
// // //     // Validation supplémentaire pour nouveau service
// // //     if (!isAddExistingMode) {
// // //       if (intitule.length > 100) {
// // //         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
// // //         return;
// // //       }
// // //       if (description.length > 700) {
// // //         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
// // //         return;
// // //       }
// // //     }
// // //
// // //     setModalState(() => isLoading = true);
// // //
// // //     try {
// // //       final String? idToken = await TokenService.getAuthToken();
// // //
// // //       if (idToken == null) {
// // //         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
// // //         setModalState(() => isLoading = false);
// // //         return;
// // //       }
// // //
// // //       http.Response response;
// // //
// // //       if (isAddExistingMode) {
// // //         // ✅ API pour ajouter un service existant
// // //         response = await http.post(
// // //           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// // //           headers: {
// // //             'Content-Type': 'application/json',
// // //             'Authorization': 'Bearer $idToken',
// // //           },
// // //           body: json.encode({
// // //             'userId': int.parse(coiffeuseId),
// // //             'service_id': selectedExistingService!.id,
// // //             'prix': prix,
// // //             'temps_minutes': temps,
// // //             'categorie_id': selectedCategory!.id,
// // //           }),
// // //         );
// // //       } else {
// // //         // ✅ API pour créer un nouveau service
// // //         response = await http.post(
// // //           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// // //           headers: {
// // //             'Content-Type': 'application/json',
// // //             'Authorization': 'Bearer $idToken',
// // //           },
// // //           body: json.encode({
// // //             'userId': int.parse(coiffeuseId),
// // //             'intitule_service': intitule,
// // //             'description': description,
// // //             'prix': prix,
// // //             'temps_minutes': temps,
// // //             'categorie_id': selectedCategory!.id,
// // //           }),
// // //         );
// // //       }
// // //
// // //       if (kDebugMode) {
// // //         print("📊 Status code: ${response.statusCode}");
// // //         print("📋 Réponse: ${response.body}");
// // //       }
// // //
// // //       if (response.statusCode == 201) {
// // //         Navigator.pop(context, true);
// // //         onSuccess();
// // //
// // //         showSuccessDialog(
// // //             context,
// // //             isAddExistingMode
// // //                 ? "Service '$intitule' ajouté avec succès !"
// // //                 : "Service '$intitule' créé et ajouté avec succès !"
// // //         );
// // //       } else {
// // //         Map<String, dynamic> errorResponse = {};
// // //         try {
// // //           errorResponse = json.decode(response.body);
// // //         } catch (e) {
// // //           // Si la réponse n'est pas du JSON valide
// // //         }
// // //
// // //         String errorMessage = errorResponse['message'] ??
// // //             errorResponse['detail'] ??
// // //             "Erreur lors de l'ajout du service (${response.statusCode})";
// // //
// // //         if (response.statusCode == 401) {
// // //           await TokenService.clearAuthToken();
// // //         }
// // //
// // //         showErrorDialog(context, errorMessage);
// // //       }
// // //     } catch (e) {
// // //       showErrorDialog(context, "Erreur de connexion: $e");
// // //     } finally {
// // //       setModalState(() => isLoading = false);
// // //     }
// // //   }
// // //
// // //   return showModalBottomSheet(
// // //     context: context,
// // //     isScrollControlled: true,
// // //     backgroundColor: Colors.transparent,
// // //     builder: (context) {
// // //       return StatefulBuilder(
// // //         builder: (BuildContext context, StateSetter setModalState) {
// // //           return AnimatedPadding(
// // //             duration: const Duration(milliseconds: 300),
// // //             curve: Curves.easeOut,
// // //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// // //             child: DraggableScrollableSheet(
// // //               initialChildSize: 0.85,
// // //               maxChildSize: 0.95,
// // //               minChildSize: 0.5,
// // //               expand: false,
// // //               builder: (context, scrollController) => Container(
// // //                 decoration: const BoxDecoration(
// // //                   color: Color(0xFFF7F7F9),
// // //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// // //                 ),
// // //                 padding: const EdgeInsets.all(20),
// // //                 child: ListView(
// // //                   controller: scrollController,
// // //                   children: [
// // //                     Center(
// // //                       child: Container(
// // //                         width: 40,
// // //                         height: 5,
// // //                         margin: const EdgeInsets.only(bottom: 20),
// // //                         decoration: BoxDecoration(
// // //                           color: Colors.grey[300],
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                       ),
// // //                     ),
// // //
// // //                     Text(
// // //                       "Ajouter un service",
// // //                       style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
// // //                     ),
// // //                     const SizedBox(height: 20),
// // //
// // //                     // ✅ NOUVEAU : Toggle entre les modes
// // //                     buildModeToggle(setModalState),
// // //
// // //                     // ✅ NOUVEAU : Sélecteur de service existant
// // //                     buildExistingServiceSelector(setModalState),
// // //
// // //                     // ✅ Champs selon le mode
// // //                     if (!isAddExistingMode) ...[
// // //                       buildTextField("Nom du service *", nameController, Icons.design_services),
// // //                       buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
// // //                     ] else if (selectedExistingService != null) ...[
// // //                       buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
// // //                       buildTextField("Description", descriptionController, Icons.description, maxLines: 3, enabled: false),
// // //                     ],
// // //
// // //                     // ✅ Catégorie (obligatoire dans les deux modes)
// // //                     buildCategorySelector(setModalState),
// // //
// // //                     // ✅ Prix et durée (toujours modifiables)
// // //                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
// // //                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
// // //
// // //                     const SizedBox(height: 20),
// // //
// // //                     SizedBox(
// // //                       width: double.infinity,
// // //                       child: ElevatedButton(
// // //                         onPressed: isLoading ? null : () => addService(setModalState),
// // //                         style: ElevatedButton.styleFrom(
// // //                           backgroundColor: primaryViolet,
// // //                           padding: const EdgeInsets.symmetric(vertical: 16),
// // //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // //                           elevation: 4,
// // //                         ),
// // //                         child: isLoading
// // //                             ? const CircularProgressIndicator(color: Colors.white)
// // //                             : Text(
// // //                             isAddExistingMode ? "Ajouter au salon" : "Créer le service",
// // //                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       );
// // //     },
// // //   );
// // // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/models/categorie.dart';
// // // import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// // // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import 'package:flutter/foundation.dart';
// // // import '../../../../../services/firebase_token/token_service.dart';
// // // import '../components/show_dialog.dart';
// // //
// // // Future<void> showAddServiceModal(
// // //     BuildContext context,
// // //     String coiffeuseId,
// // //     VoidCallback onSuccess,
// // //     CategoriesProvider categoriesProvider,
// // //     ServicesProvider servicesProvider,
// // //     ) {
// // //   final TextEditingController nameController = TextEditingController();
// // //   final TextEditingController descriptionController = TextEditingController();
// // //   final TextEditingController priceController = TextEditingController();
// // //   final TextEditingController durationController = TextEditingController();
// // //
// // //   // ✅ Gestion de la catégorie sélectionnée
// // //   Categorie? selectedCategory;
// // //
// // //   // ✅ NOUVEAU : Gestion du mode et service sélectionné
// // //   bool isAddExistingMode = true; // Mode par défaut : ajouter service existant
// // //   ServiceSuggestion? selectedExistingService;
// // //
// // //   bool isLoading = false;
// // //   final Color primaryViolet = const Color(0xFF7B61FF);
// // //
// // //   // ✅ Charger les services au démarrage si pas encore fait
// // //   if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
// // //     servicesProvider.loadAllServices();
// // //   }
// // //
// // //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// // //       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 20),
// // //       child: TextField(
// // //         controller: controller,
// // //         maxLines: maxLines,
// // //         keyboardType: keyboardType,
// // //         enabled: enabled,
// // //         decoration: InputDecoration(
// // //           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
// // //           labelText: label,
// // //           filled: true,
// // //           fillColor: enabled ? Colors.white : Colors.grey[100],
// // //           border: OutlineInputBorder(
// // //             borderRadius: BorderRadius.circular(14),
// // //             borderSide: BorderSide.none,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ NOUVEAU : Widget pour basculer entre les modes
// // //   Widget buildModeToggle(StateSetter setModalState) {
// // //     return Container(
// // //       margin: const EdgeInsets.only(bottom: 24),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: Colors.grey[300]!),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           Expanded(
// // //             child: GestureDetector(
// // //               onTap: () {
// // //                 setModalState(() {
// // //                   isAddExistingMode = true;
// // //                   selectedExistingService = null;
// // //                   nameController.clear();
// // //                   descriptionController.clear();
// // //                   priceController.clear();
// // //                   durationController.clear();
// // //                   selectedCategory = null;
// // //                 });
// // //               },
// // //               child: Container(
// // //                 padding: const EdgeInsets.symmetric(vertical: 12),
// // //                 decoration: BoxDecoration(
// // //                   color: isAddExistingMode ? primaryViolet : Colors.transparent,
// // //                   borderRadius: const BorderRadius.only(
// // //                     topLeft: Radius.circular(12),
// // //                     bottomLeft: Radius.circular(12),
// // //                   ),
// // //                 ),
// // //                 child: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     Icon(
// // //                       Icons.add_circle_outline,
// // //                       color: isAddExistingMode ? Colors.white : primaryViolet,
// // //                       size: 20,
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     Text(
// // //                       "Ajouter existant",
// // //                       style: TextStyle(
// // //                         color: isAddExistingMode ? Colors.white : primaryViolet,
// // //                         fontWeight: FontWeight.w600,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //           Expanded(
// // //             child: GestureDetector(
// // //               onTap: () {
// // //                 setModalState(() {
// // //                   isAddExistingMode = false;
// // //                   selectedExistingService = null;
// // //                   nameController.clear();
// // //                   descriptionController.clear();
// // //                   priceController.clear();
// // //                   durationController.clear();
// // //                   selectedCategory = null;
// // //                 });
// // //               },
// // //               child: Container(
// // //                 padding: const EdgeInsets.symmetric(vertical: 12),
// // //                 decoration: BoxDecoration(
// // //                   color: !isAddExistingMode ? primaryViolet : Colors.transparent,
// // //                   borderRadius: const BorderRadius.only(
// // //                     topRight: Radius.circular(12),
// // //                     bottomRight: Radius.circular(12),
// // //                   ),
// // //                 ),
// // //                 child: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     Icon(
// // //                       Icons.create,
// // //                       color: !isAddExistingMode ? Colors.white : primaryViolet,
// // //                       size: 20,
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     Text(
// // //                       "Créer nouveau",
// // //                       style: TextStyle(
// // //                         color: !isAddExistingMode ? Colors.white : primaryViolet,
// // //                         fontWeight: FontWeight.w600,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ NOUVEAU : Dropdown pour sélectionner un service existant
// // //   Widget buildExistingServiceSelector(StateSetter setModalState) {
// // //     if (!isAddExistingMode) return const SizedBox.shrink();
// // //
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 20),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           // Loading state
// // //           if (servicesProvider.isLoading) ...[
// // //             Container(
// // //               padding: const EdgeInsets.all(16),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white,
// // //                 borderRadius: BorderRadius.circular(14),
// // //               ),
// // //               child: const Row(
// // //                 children: [
// // //                   Icon(Icons.design_services, color: Color(0xFF7B61FF)),
// // //                   SizedBox(width: 12),
// // //                   Text("Chargement des services..."),
// // //                   Spacer(),
// // //                   SizedBox(
// // //                     width: 20,
// // //                     height: 20,
// // //                     child: CircularProgressIndicator(strokeWidth: 2),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ]
// // //           // Error state
// // //           else if (servicesProvider.hasError) ...[
// // //             Container(
// // //               padding: const EdgeInsets.all(16),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.red[50],
// // //                 borderRadius: BorderRadius.circular(14),
// // //                 border: Border.all(color: Colors.red[200]!),
// // //               ),
// // //               child: Row(
// // //                 children: [
// // //                   Icon(Icons.error, color: Colors.red[700]),
// // //                   const SizedBox(width: 12),
// // //                   Expanded(
// // //                     child: Text(
// // //                       "Erreur: ${servicesProvider.errorMessage}",
// // //                       style: TextStyle(color: Colors.red[700]),
// // //                     ),
// // //                   ),
// // //                   IconButton(
// // //                     icon: const Icon(Icons.refresh),
// // //                     onPressed: () {
// // //                       servicesProvider.loadAllServices();
// // //                       setModalState(() {});
// // //                     },
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ]
// // //           // Services disponibles
// // //           else if (servicesProvider.allServices.isNotEmpty) ...[
// // //               Container(
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white,
// // //                   borderRadius: BorderRadius.circular(14),
// // //                 ),
// // //                 child: DropdownButtonFormField<ServiceSuggestion>(
// // //                   value: selectedExistingService,
// // //                   decoration: InputDecoration(
// // //                     prefixIcon: Icon(Icons.design_services, color: primaryViolet),
// // //                     labelText: "Service à ajouter *",
// // //                     filled: true,
// // //                     fillColor: Colors.white,
// // //                     border: OutlineInputBorder(
// // //                       borderRadius: BorderRadius.circular(14),
// // //                       borderSide: BorderSide.none,
// // //                     ),
// // //                   ),
// // //                   hint: const Text("Sélectionner un service"),
// // //                   items: servicesProvider.allServices.map((ServiceSuggestion service) {
// // //                     return DropdownMenuItem<ServiceSuggestion>(
// // //                       value: service,
// // //                       child: Column(
// // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // //                         mainAxisSize: MainAxisSize.min,
// // //                         children: [
// // //                           Text(
// // //                             service.intituleService,
// // //                             style: const TextStyle(
// // //                               fontSize: 16,
// // //                               fontWeight: FontWeight.w600,
// // //                             ),
// // //                           ),
// // //                           if (service.description.isNotEmpty)
// // //                             Text(
// // //                               service.description,
// // //                               style: TextStyle(
// // //                                 fontSize: 12,
// // //                                 color: Colors.grey[600],
// // //                               ),
// // //                               maxLines: 1,
// // //                               overflow: TextOverflow.ellipsis,
// // //                             ),
// // //                         ],
// // //                       ),
// // //                     );
// // //                   }).toList(),
// // //                   onChanged: (ServiceSuggestion? newValue) {
// // //                     setModalState(() {
// // //                       selectedExistingService = newValue;
// // //                       if (newValue != null) {
// // //                         nameController.text = newValue.intituleService;
// // //                         descriptionController.text = newValue.description;
// // //                         // Pré-remplir prix et durée si disponibles
// // //                         if (newValue.prixSuggere != null) {
// // //                           priceController.text = newValue.prixSuggere.toString();
// // //                         }
// // //                         if (newValue.dureeSuggeree != null) {
// // //                           durationController.text = newValue.dureeSuggeree.toString();
// // //                         }
// // //                       }
// // //                     });
// // //                   },
// // //                 ),
// // //               ),
// // //
// // //               // Info du service sélectionné
// // //               if (selectedExistingService != null) ...[
// // //                 const SizedBox(height: 16),
// // //                 Container(
// // //                   padding: const EdgeInsets.all(16),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.blue[50],
// // //                     borderRadius: BorderRadius.circular(12),
// // //                     border: Border.all(color: Colors.blue[200]!),
// // //                   ),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Row(
// // //                         children: [
// // //                           Icon(Icons.info_outline, color: Colors.blue[700]),
// // //                           const SizedBox(width: 8),
// // //                           Text(
// // //                             "Service sélectionné",
// // //                             style: TextStyle(
// // //                               fontWeight: FontWeight.bold,
// // //                               color: Colors.blue[700],
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                       const SizedBox(height: 8),
// // //                       Text(
// // //                         selectedExistingService!.description,
// // //                         style: TextStyle(color: Colors.blue[600], fontSize: 13),
// // //                       ),
// // //                       const SizedBox(height: 8),
// // //                       Row(
// // //                         children: [
// // //                           if (selectedExistingService!.prixSuggere != null) ...[
// // //                             Container(
// // //                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                               decoration: BoxDecoration(
// // //                                 color: Colors.green.withOpacity(0.1),
// // //                                 borderRadius: BorderRadius.circular(6),
// // //                               ),
// // //                               child: Text(
// // //                                 "Prix suggéré: ${selectedExistingService!.prixSuggere}€",
// // //                                 style: const TextStyle(
// // //                                   color: Colors.green,
// // //                                   fontSize: 12,
// // //                                   fontWeight: FontWeight.w600,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                             const SizedBox(width: 8),
// // //                           ],
// // //                           if (selectedExistingService!.dureeSuggeree != null)
// // //                             Container(
// // //                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                               decoration: BoxDecoration(
// // //                                 color: primaryViolet.withOpacity(0.1),
// // //                                 borderRadius: BorderRadius.circular(6),
// // //                               ),
// // //                               child: Text(
// // //                                 "Durée suggérée: ${selectedExistingService!.dureeSuggeree}min",
// // //                                 style: TextStyle(
// // //                                   color: primaryViolet,
// // //                                   fontSize: 12,
// // //                                   fontWeight: FontWeight.w600,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                         ],
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ],
// // //             ]
// // //             // Aucun service disponible
// // //             else ...[
// // //                 Container(
// // //                   padding: const EdgeInsets.all(16),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.grey[50],
// // //                     borderRadius: BorderRadius.circular(14),
// // //                     border: Border.all(color: Colors.grey[300]!),
// // //                   ),
// // //                   child: Row(
// // //                     children: [
// // //                       Icon(Icons.info_outline, color: Colors.grey[600]),
// // //                       const SizedBox(width: 12),
// // //                       Expanded(
// // //                         child: Column(
// // //                           crossAxisAlignment: CrossAxisAlignment.start,
// // //                           children: [
// // //                             Text(
// // //                               "Aucun service disponible",
// // //                               style: TextStyle(
// // //                                 fontWeight: FontWeight.w600,
// // //                                 color: Colors.grey[700],
// // //                               ),
// // //                             ),
// // //                             Text(
// // //                               "Passez en mode 'Créer nouveau' pour ajouter un service",
// // //                               style: TextStyle(
// // //                                 fontSize: 12,
// // //                                 color: Colors.grey[600],
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ],
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ Widget pour sélectionner la catégorie
// // //   Widget buildCategorySelector(StateSetter setModalState) {
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 20),
// // //       child: Container(
// // //         decoration: BoxDecoration(
// // //           color: Colors.white,
// // //           borderRadius: BorderRadius.circular(14),
// // //         ),
// // //         child: Builder(
// // //           builder: (context) {
// // //             if (categoriesProvider.isLoading) {
// // //               return const Padding(
// // //                 padding: EdgeInsets.all(16),
// // //                 child: Row(
// // //                   children: [
// // //                     Icon(Icons.category, color: Color(0xFF7B61FF)),
// // //                     SizedBox(width: 12),
// // //                     Text("Chargement des catégories..."),
// // //                     Spacer(),
// // //                     SizedBox(
// // //                       width: 20,
// // //                       height: 20,
// // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             }
// // //
// // //             if (categoriesProvider.hasError) {
// // //               return Padding(
// // //                 padding: const EdgeInsets.all(16),
// // //                 child: Row(
// // //                   children: [
// // //                     const Icon(Icons.error, color: Colors.red),
// // //                     const SizedBox(width: 12),
// // //                     Expanded(
// // //                       child: Text(
// // //                         "Erreur : ${categoriesProvider.errorMessage}",
// // //                         style: const TextStyle(color: Colors.red),
// // //                       ),
// // //                     ),
// // //                     IconButton(
// // //                       icon: const Icon(Icons.refresh),
// // //                       onPressed: () {
// // //                         categoriesProvider.refreshCategories();
// // //                         setModalState(() {});
// // //                       },
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             }
// // //
// // //             final categories = categoriesProvider.categoriesSorted;
// // //
// // //             if (categories.isEmpty) {
// // //               return const Padding(
// // //                 padding: EdgeInsets.all(16),
// // //                 child: Row(
// // //                   children: [
// // //                     Icon(Icons.category, color: Colors.grey),
// // //                     SizedBox(width: 12),
// // //                     Text("Aucune catégorie disponible"),
// // //                   ],
// // //                 ),
// // //               );
// // //             }
// // //
// // //             return DropdownButtonFormField<Categorie>(
// // //               value: selectedCategory,
// // //               decoration: InputDecoration(
// // //                 prefixIcon: Icon(Icons.category, color: primaryViolet),
// // //                 labelText: "Catégorie *",
// // //                 filled: true,
// // //                 fillColor: Colors.white,
// // //                 border: OutlineInputBorder(
// // //                   borderRadius: BorderRadius.circular(14),
// // //                   borderSide: BorderSide.none,
// // //                 ),
// // //               ),
// // //               hint: const Text("Sélectionner une catégorie"),
// // //               items: categories.map((Categorie category) {
// // //                 return DropdownMenuItem<Categorie>(
// // //                   value: category,
// // //                   child: Text(
// // //                     category.nom,
// // //                     style: const TextStyle(fontSize: 16),
// // //                   ),
// // //                 );
// // //               }).toList(),
// // //               onChanged: (Categorie? newValue) {
// // //                 setModalState(() {
// // //                   selectedCategory = newValue;
// // //                 });
// // //               },
// // //             );
// // //           },
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Future<void> addService(StateSetter setModalState) async {
// // //     // ✅ Validation selon le mode
// // //     if (isAddExistingMode) {
// // //       // Mode ajouter existant
// // //       if (selectedExistingService == null) {
// // //         showErrorDialog(context, "Veuillez sélectionner un service.");
// // //         return;
// // //       }
// // //       if (selectedCategory == null) {
// // //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// // //         return;
// // //       }
// // //       if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) {
// // //         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
// // //         return;
// // //       }
// // //     } else {
// // //       // Mode créer nouveau
// // //       if (selectedCategory == null) {
// // //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// // //         return;
// // //       }
// // //       if (nameController.text.trim().isEmpty ||
// // //           descriptionController.text.trim().isEmpty ||
// // //           priceController.text.trim().isEmpty ||
// // //           durationController.text.trim().isEmpty) {
// // //         showErrorDialog(context, "Tous les champs sont obligatoires.");
// // //         return;
// // //       }
// // //     }
// // //
// // //     final String intitule = nameController.text.trim();
// // //     final String description = descriptionController.text.trim();
// // //     final String prixText = priceController.text.trim();
// // //     final String durationText = durationController.text.trim();
// // //
// // //     // Validation des nombres
// // //     final double? prix = double.tryParse(prixText);
// // //     final int? temps = int.tryParse(durationText);
// // //
// // //     if (prix == null || temps == null) {
// // //       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
// // //       return;
// // //     }
// // //
// // //     if (prix > 999) {
// // //       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
// // //       return;
// // //     }
// // //
// // //     if (temps > 480) {
// // //       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
// // //       return;
// // //     }
// // //
// // //     // Validation supplémentaire pour nouveau service
// // //     if (!isAddExistingMode) {
// // //       if (intitule.length > 100) {
// // //         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
// // //         return;
// // //       }
// // //       if (description.length > 700) {
// // //         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
// // //         return;
// // //       }
// // //     }
// // //
// // //     setModalState(() => isLoading = true);
// // //
// // //     try {
// // //       final String? idToken = await TokenService.getAuthToken();
// // //
// // //       if (idToken == null) {
// // //         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
// // //         setModalState(() => isLoading = false);
// // //         return;
// // //       }
// // //
// // //       http.Response response;
// // //
// // //       if (isAddExistingMode) {
// // //         // ✅ API pour ajouter un service existant
// // //         response = await http.post(
// // //           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// // //           headers: {
// // //             'Content-Type': 'application/json',
// // //             'Authorization': 'Bearer $idToken',
// // //           },
// // //           body: json.encode({
// // //             'userId': int.parse(coiffeuseId),
// // //             'service_id': selectedExistingService!.id,
// // //             'prix': prix,
// // //             'temps_minutes': temps,
// // //             'categorie_id': selectedCategory!.id,
// // //           }),
// // //         );
// // //       } else {
// // //         // ✅ API pour créer un nouveau service
// // //         response = await http.post(
// // //           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// // //           headers: {
// // //             'Content-Type': 'application/json',
// // //             'Authorization': 'Bearer $idToken',
// // //           },
// // //           body: json.encode({
// // //             'userId': int.parse(coiffeuseId),
// // //             'intitule_service': intitule,
// // //             'description': description,
// // //             'prix': prix,
// // //             'temps_minutes': temps,
// // //             'categorie_id': selectedCategory!.id,
// // //           }),
// // //         );
// // //       }
// // //
// // //       if (kDebugMode) {
// // //         print("📊 Status code: ${response.statusCode}");
// // //         print("📋 Réponse: ${response.body}");
// // //       }
// // //
// // //       if (response.statusCode == 201) {
// // //         Navigator.pop(context, true);
// // //         onSuccess();
// // //
// // //         showSuccessDialog(
// // //             context,
// // //             isAddExistingMode
// // //                 ? "Service '$intitule' ajouté avec succès !"
// // //                 : "Service '$intitule' créé et ajouté avec succès !"
// // //         );
// // //       } else {
// // //         Map<String, dynamic> errorResponse = {};
// // //         try {
// // //           errorResponse = json.decode(response.body);
// // //         } catch (e) {
// // //           // Si la réponse n'est pas du JSON valide
// // //         }
// // //
// // //         String errorMessage = errorResponse['message'] ??
// // //             errorResponse['detail'] ??
// // //             "Erreur lors de l'ajout du service (${response.statusCode})";
// // //
// // //         if (response.statusCode == 401) {
// // //           await TokenService.clearAuthToken();
// // //         }
// // //
// // //         showErrorDialog(context, errorMessage);
// // //       }
// // //     } catch (e) {
// // //       showErrorDialog(context, "Erreur de connexion: $e");
// // //     } finally {
// // //       setModalState(() => isLoading = false);
// // //     }
// // //   }
// // //
// // //   return showModalBottomSheet(
// // //     context: context,
// // //     isScrollControlled: true,
// // //     backgroundColor: Colors.transparent,
// // //     builder: (context) {
// // //       return StatefulBuilder(
// // //         builder: (BuildContext context, StateSetter setModalState) {
// // //           return AnimatedPadding(
// // //             duration: const Duration(milliseconds: 300),
// // //             curve: Curves.easeOut,
// // //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// // //             child: DraggableScrollableSheet(
// // //               initialChildSize: 0.85,
// // //               maxChildSize: 0.95,
// // //               minChildSize: 0.5,
// // //               expand: false,
// // //               builder: (context, scrollController) => Container(
// // //                 decoration: const BoxDecoration(
// // //                   color: Color(0xFFF7F7F9),
// // //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// // //                 ),
// // //                 padding: const EdgeInsets.all(20),
// // //                 child: ListView(
// // //                   controller: scrollController,
// // //                   children: [
// // //                     Center(
// // //                       child: Container(
// // //                         width: 40,
// // //                         height: 5,
// // //                         margin: const EdgeInsets.only(bottom: 20),
// // //                         decoration: BoxDecoration(
// // //                           color: Colors.grey[300],
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                       ),
// // //                     ),
// // //
// // //                     Text(
// // //                       "Ajouter un service",
// // //                       style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
// // //                     ),
// // //                     const SizedBox(height: 20),
// // //
// // //                     // ✅ NOUVEAU : Toggle entre les modes
// // //                     buildModeToggle(setModalState),
// // //
// // //                     // ✅ NOUVEAU : Sélecteur de service existant
// // //                     buildExistingServiceSelector(setModalState),
// // //
// // //                     // ✅ Champs selon le mode
// // //                     if (!isAddExistingMode) ...[
// // //                       buildTextField("Nom du service *", nameController, Icons.design_services),
// // //                       buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
// // //                     ] else if (selectedExistingService != null) ...[
// // //                       buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
// // //                       buildTextField("Description", descriptionController, Icons.description, maxLines: 3, enabled: false),
// // //                     ],
// // //
// // //                     // ✅ Catégorie (obligatoire dans les deux modes)
// // //                     buildCategorySelector(setModalState),
// // //
// // //                     // ✅ Prix et durée (toujours modifiables)
// // //                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
// // //                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
// // //
// // //                     const SizedBox(height: 20),
// // //
// // //                     SizedBox(
// // //                       width: double.infinity,
// // //                       child: ElevatedButton(
// // //                         onPressed: isLoading ? null : () => addService(setModalState),
// // //                         style: ElevatedButton.styleFrom(
// // //                           backgroundColor: primaryViolet,
// // //                           padding: const EdgeInsets.symmetric(vertical: 16),
// // //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // //                           elevation: 4,
// // //                         ),
// // //                         child: isLoading
// // //                             ? const CircularProgressIndicator(color: Colors.white)
// // //                             : Text(
// // //                             isAddExistingMode ? "Ajouter au salon" : "Créer le service",
// // //                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       );
// // //     },
// // //   );
// // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // // // import 'package:flutter/material.dart';
// // // // import 'package:hairbnb/models/categorie.dart';
// // // // import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// // // // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'dart:convert';
// // // // import 'package:flutter/foundation.dart';
// // // // import '../../../../../services/firebase_token/token_service.dart';
// // // // import '../components/show_dialog.dart';
// // // //
// // // // Future<void> showAddServiceModal(
// // // //     BuildContext context,
// // // //     String coiffeuseId,
// // // //     VoidCallback onSuccess,
// // // //     CategoriesProvider categoriesProvider,
// // // //     ServicesProvider servicesProvider, // ✅ NOUVEAU : Provider pour la recherche
// // // //     ) {
// // // //   final TextEditingController nameController = TextEditingController();
// // // //   final TextEditingController descriptionController = TextEditingController();
// // // //   final TextEditingController priceController = TextEditingController();
// // // //   final TextEditingController durationController = TextEditingController();
// // // //
// // // //   // ✅ Gestion de la catégorie sélectionnée
// // // //   Categorie? selectedCategory;
// // // //
// // // //   // ✅ NOUVEAU : Gestion du service existant sélectionné
// // // //   ServiceSuggestion? selectedExistingService;
// // // //   bool isNewService = true; // Mode par défaut : nouveau service
// // // //
// // // //   bool isLoading = false;
// // // //   final Color primaryViolet = const Color(0xFF7B61FF);
// // // //
// // // //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// // // //       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 20),
// // // //       child: TextField(
// // // //         controller: controller,
// // // //         maxLines: maxLines,
// // // //         keyboardType: keyboardType,
// // // //         enabled: enabled,
// // // //         decoration: InputDecoration(
// // // //           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
// // // //           labelText: label,
// // // //           filled: true,
// // // //           fillColor: enabled ? Colors.white : Colors.grey[100],
// // // //           border: OutlineInputBorder(
// // // //             borderRadius: BorderRadius.circular(14),
// // // //             borderSide: BorderSide.none,
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ NOUVEAU : Widget de recherche de services existants
// // // //   Widget buildServiceSearchField(StateSetter setModalState) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 20),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           TextField(
// // // //             controller: nameController,
// // // //             decoration: InputDecoration(
// // // //               prefixIcon: Icon(Icons.search, color: primaryViolet),
// // // //               labelText: "Nom du service *",
// // // //               hintText: "Tapez pour rechercher ou créer un nouveau service",
// // // //               filled: true,
// // // //               fillColor: Colors.white,
// // // //               border: OutlineInputBorder(
// // // //                 borderRadius: BorderRadius.circular(14),
// // // //                 borderSide: BorderSide.none,
// // // //               ),
// // // //               suffixIcon: servicesProvider.isSearching
// // // //                   ? const Padding(
// // // //                 padding: EdgeInsets.all(12),
// // // //                 child: SizedBox(
// // // //                   width: 20,
// // // //                   height: 20,
// // // //                   child: CircularProgressIndicator(strokeWidth: 2),
// // // //                 ),
// // // //               )
// // // //                   : null,
// // // //             ),
// // // //             onChanged: (value) {
// // // //               // ✅ Déclencher la recherche
// // // //               if (value.trim().length >= 2) {
// // // //                 servicesProvider.searchServices(value.trim());
// // // //               } else {
// // // //                 servicesProvider.resetSearch();
// // // //               }
// // // //
// // // //               // ✅ Reset de la sélection si l'utilisateur tape
// // // //               if (selectedExistingService != null) {
// // // //                 setModalState(() {
// // // //                   selectedExistingService = null;
// // // //                   isNewService = true;
// // // //                   descriptionController.clear();
// // // //                   priceController.clear();
// // // //                   durationController.clear();
// // // //                   selectedCategory = null;
// // // //                 });
// // // //               }
// // // //             },
// // // //           ),
// // // //
// // // //           // ✅ Liste des suggestions
// // // //           if (servicesProvider.searchResults.isNotEmpty) ...[
// // // //             const SizedBox(height: 8),
// // // //             Container(
// // // //               constraints: const BoxConstraints(maxHeight: 200),
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.white,
// // // //                 borderRadius: BorderRadius.circular(12),
// // // //                 border: Border.all(color: Colors.grey[300]!),
// // // //               ),
// // // //               child: ListView.builder(
// // // //                 shrinkWrap: true,
// // // //                 itemCount: servicesProvider.searchResults.length,
// // // //                 itemBuilder: (context, index) {
// // // //                   final service = servicesProvider.searchResults[index];
// // // //                   return ListTile(
// // // //                     leading: Icon(Icons.history, color: primaryViolet, size: 20),
// // // //                     title: Text(
// // // //                       service.intituleService,
// // // //                       style: const TextStyle(fontWeight: FontWeight.w600),
// // // //                     ),
// // // //                     subtitle: Column(
// // // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // // //                       children: [
// // // //                         Text(
// // // //                           service.description,
// // // //                           maxLines: 1,
// // // //                           overflow: TextOverflow.ellipsis,
// // // //                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// // // //                         ),
// // // //                         const SizedBox(height: 4),
// // // //                         Row(
// // // //                           children: [
// // // //                             Container(
// // // //                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// // // //                               decoration: BoxDecoration(
// // // //                                 color: primaryViolet.withOpacity(0.1),
// // // //                                 borderRadius: BorderRadius.circular(4),
// // // //                               ),
// // // //                               child: Text(
// // // //                                 "Service global",
// // // //                                 style: TextStyle(
// // // //                                   fontSize: 10,
// // // //                                   color: primaryViolet,
// // // //                                   fontWeight: FontWeight.w600,
// // // //                                 ),
// // // //                               ),
// // // //                             ),
// // // //                             const SizedBox(width: 8),
// // // //                             Text(
// // // //                               "Réutilisable",
// // // //                               style: TextStyle(fontSize: 10, color: Colors.grey[500]),
// // // //                             ),
// // // //                           ],
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                     trailing: Column(
// // // //                       mainAxisAlignment: MainAxisAlignment.center,
// // // //                       crossAxisAlignment: CrossAxisAlignment.end,
// // // //                       children: [
// // // //                         if (service.prixSuggere != null)
// // // //                           Text(
// // // //                             "${service.prixSuggere}€",
// // // //                             style: TextStyle(
// // // //                               color: Colors.green,
// // // //                               fontWeight: FontWeight.bold,
// // // //                               fontSize: 12,
// // // //                             ),
// // // //                           ),
// // // //                         if (service.dureeSuggeree != null)
// // // //                           Text(
// // // //                             "${service.dureeSuggeree}min",
// // // //                             style: TextStyle(
// // // //                               color: primaryViolet,
// // // //                               fontSize: 11,
// // // //                             ),
// // // //                           ),
// // // //                       ],
// // // //                     ),
// // // //                     onTap: () {
// // // //                       setModalState(() {
// // // //                         selectedExistingService = service;
// // // //                         isNewService = false;
// // // //                         nameController.text = service.intituleService;
// // // //                         descriptionController.text = service.description;
// // // //
// // // //                         // ✅ Pré-remplir avec les valeurs suggérées
// // // //                         if (service.prixSuggere != null) {
// // // //                           priceController.text = service.prixSuggere.toString();
// // // //                         }
// // // //                         if (service.dureeSuggeree != null) {
// // // //                           durationController.text = service.dureeSuggeree.toString();
// // // //                         }
// // // //
// // // //                         // ✅ Pas de pré-sélection de catégorie car pas d'info dans l'API
// // // //                         // Tu devras demander à l'utilisateur de choisir la catégorie
// // // //                       });
// // // //
// // // //                       // ✅ Reset de la recherche
// // // //                       servicesProvider.resetSearch();
// // // //                     },
// // // //                   );
// // // //                 },
// // // //               ),
// // // //             ),
// // // //           ],
// // // //
// // // //           // ✅ Message d'erreur de recherche
// // // //           if (servicesProvider.hasSearchError) ...[
// // // //             const SizedBox(height: 8),
// // // //             Container(
// // // //               padding: const EdgeInsets.all(12),
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.red[50],
// // // //                 borderRadius: BorderRadius.circular(8),
// // // //                 border: Border.all(color: Colors.red[200]!),
// // // //               ),
// // // //               child: Row(
// // // //                 children: [
// // // //                   Icon(Icons.error_outline, color: Colors.red[700], size: 20),
// // // //                   const SizedBox(width: 8),
// // // //                   Expanded(
// // // //                     child: Text(
// // // //                       servicesProvider.searchError!,
// // // //                       style: TextStyle(color: Colors.red[700], fontSize: 12),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Widget pour sélectionner la catégorie (améliorer pour supporter les services existants)
// // // //   Widget buildCategorySelector(StateSetter setModalState) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 20),
// // // //       child: Container(
// // // //         decoration: BoxDecoration(
// // // //           color: Colors.white,
// // // //           borderRadius: BorderRadius.circular(14),
// // // //         ),
// // // //         child: Builder(
// // // //           builder: (context) {
// // // //             if (categoriesProvider.isLoading) {
// // // //               return const Padding(
// // // //                 padding: EdgeInsets.all(16),
// // // //                 child: Row(
// // // //                   children: [
// // // //                     Icon(Icons.category, color: Color(0xFF7B61FF)),
// // // //                     SizedBox(width: 12),
// // // //                     Text("Chargement des catégories..."),
// // // //                     Spacer(),
// // // //                     SizedBox(
// // // //                       width: 20,
// // // //                       height: 20,
// // // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               );
// // // //             }
// // // //
// // // //             if (categoriesProvider.hasError) {
// // // //               return Padding(
// // // //                 padding: const EdgeInsets.all(16),
// // // //                 child: Row(
// // // //                   children: [
// // // //                     const Icon(Icons.error, color: Colors.red),
// // // //                     const SizedBox(width: 12),
// // // //                     Expanded(
// // // //                       child: Text(
// // // //                         "Erreur : ${categoriesProvider.errorMessage}",
// // // //                         style: const TextStyle(color: Colors.red),
// // // //                       ),
// // // //                     ),
// // // //                     IconButton(
// // // //                       icon: const Icon(Icons.refresh),
// // // //                       onPressed: () {
// // // //                         categoriesProvider.refreshCategories();
// // // //                         setModalState(() {});
// // // //                       },
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               );
// // // //             }
// // // //
// // // //             final categories = categoriesProvider.categoriesSorted;
// // // //
// // // //             if (categories.isEmpty) {
// // // //               return const Padding(
// // // //                 padding: EdgeInsets.all(16),
// // // //                 child: Row(
// // // //                   children: [
// // // //                     Icon(Icons.category, color: Colors.grey),
// // // //                     SizedBox(width: 12),
// // // //                     Text("Aucune catégorie disponible"),
// // // //                   ],
// // // //                 ),
// // // //               );
// // // //             }
// // // //
// // // //             return DropdownButtonFormField<Categorie>(
// // // //               value: selectedCategory,
// // // //               decoration: InputDecoration(
// // // //                 prefixIcon: Icon(Icons.category, color: primaryViolet),
// // // //                 labelText: "Catégorie *",
// // // //                 filled: true,
// // // //                 fillColor: Colors.white,
// // // //                 border: OutlineInputBorder(
// // // //                   borderRadius: BorderRadius.circular(14),
// // // //                   borderSide: BorderSide.none,
// // // //                 ),
// // // //               ),
// // // //               hint: const Text("Sélectionner une catégorie"),
// // // //               items: categories.map((Categorie category) {
// // // //                 return DropdownMenuItem<Categorie>(
// // // //                   value: category,
// // // //                   child: Text(
// // // //                     category.nom,
// // // //                     style: const TextStyle(fontSize: 16),
// // // //                   ),
// // // //                 );
// // // //               }).toList(),
// // // //               onChanged: (Categorie? newValue) {
// // // //                 setModalState(() {
// // // //                   selectedCategory = newValue;
// // // //                 });
// // // //               },
// // // //             );
// // // //           },
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Widget d'information du service existant
// // // //   Widget buildExistingServiceInfo() {
// // // //     if (selectedExistingService == null) return const SizedBox.shrink();
// // // //
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 20),
// // // //       child: Container(
// // // //         padding: const EdgeInsets.all(16),
// // // //         decoration: BoxDecoration(
// // // //           color: Colors.blue[50],
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           border: Border.all(color: Colors.blue[200]!),
// // // //         ),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             Row(
// // // //               children: [
// // // //                 Icon(Icons.info_outline, color: Colors.blue[700]),
// // // //                 const SizedBox(width: 8),
// // // //                 Text(
// // // //                   "Service existant sélectionné",
// // // //                   style: TextStyle(
// // // //                     fontWeight: FontWeight.bold,
// // // //                     color: Colors.blue[700],
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             const SizedBox(height: 8),
// // // //             Text(
// // // //               "Vous ajoutez un service global existant à votre salon. Vous devez choisir une catégorie et pouvez personnaliser le prix et la durée.",
// // // //               style: TextStyle(color: Colors.blue[600], fontSize: 13),
// // // //             ),
// // // //             const SizedBox(height: 8),
// // // //             Text(
// // // //               "Utilisé par ${selectedExistingService!.nbSalonsUtilisant} salon(s)",
// // // //               style: TextStyle(color: Colors.blue[500], fontSize: 12),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Future<void> addService(StateSetter setModalState) async {
// // // //     final intitule = nameController.text.trim();
// // // //     final description = descriptionController.text.trim();
// // // //     final prixText = priceController.text.trim();
// // // //     final durationText = durationController.text.trim();
// // // //
// // // //     // ✅ Vérifications spécifiques selon le mode
// // // //     if (isNewService) {
// // // //       // Mode nouveau service : tous les champs obligatoires
// // // //       if (selectedCategory == null) {
// // // //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// // // //         return;
// // // //       }
// // // //
// // // //       if (intitule.isEmpty || description.isEmpty || prixText.isEmpty || durationText.isEmpty) {
// // // //         showErrorDialog(context, "Tous les champs sont obligatoires.");
// // // //         return;
// // // //       }
// // // //     } else {
// // // //       // Mode service existant : catégorie obligatoire + prix et durée
// // // //       if (selectedCategory == null) {
// // // //         showErrorDialog(context, "Veuillez sélectionner une catégorie pour ce service global.");
// // // //         return;
// // // //       }
// // // //
// // // //       if (prixText.isEmpty || durationText.isEmpty) {
// // // //         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
// // // //         return;
// // // //       }
// // // //     }
// // // //
// // // //     bool hasAtMostTwoDecimalPlaces(double value) {
// // // //       return ((value * 100).roundToDouble() == (value * 100));
// // // //     }
// // // //
// // // //     // Vérifications supplémentaires pour nouveau service
// // // //     if (isNewService) {
// // // //       if (intitule.length > 100) {
// // // //         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
// // // //         return;
// // // //       }
// // // //
// // // //       if (description.length > 700) {
// // // //         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
// // // //         return;
// // // //       }
// // // //     }
// // // //
// // // //     final double? prix = double.tryParse(prixText);
// // // //     final int? temps = int.tryParse(durationText);
// // // //
// // // //     if (prix == null || temps == null) {
// // // //       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
// // // //       return;
// // // //     }
// // // //
// // // //     if (prix > 999) {
// // // //       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
// // // //       return;
// // // //     }
// // // //
// // // //     if (!hasAtMostTwoDecimalPlaces(prix)) {
// // // //       showErrorDialog(context, "Le prix doit avoir au maximum 2 chiffres après la virgule.");
// // // //       return;
// // // //     }
// // // //
// // // //     if (temps > 480) {
// // // //       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
// // // //       return;
// // // //     }
// // // //
// // // //     setModalState(() => isLoading = true);
// // // //
// // // //     try {
// // // //       final String? idToken = await TokenService.getAuthToken();
// // // //
// // // //       if (idToken == null) {
// // // //         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
// // // //         setModalState(() => isLoading = false);
// // // //         return;
// // // //       }
// // // //
// // // //       if (kDebugMode) {
// // // //         print("🚀 Mode: ${isNewService ? 'Nouveau service' : 'Service existant'}");
// // // //         if (isNewService) {
// // // //           print("📁 Catégorie: ${selectedCategory!.nom} (ID: ${selectedCategory!.id})");
// // // //         } else {
// // // //           print("🔄 Service existant ID: ${selectedExistingService!.id}");
// // // //         }
// // // //       }
// // // //
// // // //       http.Response response;
// // // //
// // // //       if (isNewService) {
// // // //         // ✅ API pour créer un nouveau service global
// // // //         response = await http.post(
// // // //           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// // // //           headers: {
// // // //             'Content-Type': 'application/json',
// // // //             'Authorization': 'Bearer $idToken',
// // // //           },
// // // //           body: json.encode({
// // // //             'userId': int.parse(coiffeuseId),
// // // //             'intitule_service': intitule,
// // // //             'description': description,
// // // //             'prix': prix,
// // // //             'temps_minutes': temps,
// // // //             'categorie_id': selectedCategory!.id,
// // // //           }),
// // // //         );
// // // //       } else {
// // // //         // ✅ API pour ajouter un service existant (à créer côté backend)
// // // //         response = await http.post(
// // // //           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// // // //           headers: {
// // // //             'Content-Type': 'application/json',
// // // //             'Authorization': 'Bearer $idToken',
// // // //           },
// // // //           body: json.encode({
// // // //             'userId': int.parse(coiffeuseId),
// // // //             'service_id': selectedExistingService!.id,
// // // //             'prix': prix,
// // // //             'temps_minutes': temps,
// // // //           }),
// // // //         );
// // // //       }
// // // //
// // // //       if (kDebugMode) {
// // // //         print("📊 Status code: ${response.statusCode}");
// // // //         print("📋 Réponse: ${response.body}");
// // // //       }
// // // //
// // // //       if (response.statusCode == 201) {
// // // //         Navigator.pop(context, true);
// // // //         onSuccess();
// // // //
// // // //         showSuccessDialog(
// // // //             context,
// // // //             isNewService
// // // //                 ? "Service '$intitule' créé et ajouté avec succès !"
// // // //                 : "Service '$intitule' ajouté à votre salon !"
// // // //         );
// // // //       } else {
// // // //         Map<String, dynamic> errorResponse = {};
// // // //         try {
// // // //           errorResponse = json.decode(response.body);
// // // //         } catch (e) {
// // // //           // Si la réponse n'est pas du JSON valide
// // // //         }
// // // //
// // // //         String errorMessage = errorResponse['message'] ??
// // // //             errorResponse['detail'] ??
// // // //             "Erreur lors de l'ajout du service (${response.statusCode})";
// // // //
// // // //         if (response.statusCode == 401) {
// // // //           await TokenService.clearAuthToken();
// // // //         }
// // // //
// // // //         showErrorDialog(context, errorMessage);
// // // //       }
// // // //     } catch (e) {
// // // //       showErrorDialog(context, "Erreur de connexion: $e");
// // // //     } finally {
// // // //       setModalState(() => isLoading = false);
// // // //     }
// // // //   }
// // // //
// // // //   return showModalBottomSheet(
// // // //     context: context,
// // // //     isScrollControlled: true,
// // // //     backgroundColor: Colors.transparent,
// // // //     builder: (context) {
// // // //       return StatefulBuilder(
// // // //         builder: (BuildContext context, StateSetter setModalState) {
// // // //           return AnimatedPadding(
// // // //             duration: const Duration(milliseconds: 300),
// // // //             curve: Curves.easeOut,
// // // //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// // // //             child: DraggableScrollableSheet(
// // // //               initialChildSize: 0.85,
// // // //               maxChildSize: 0.95,
// // // //               minChildSize: 0.5,
// // // //               expand: false,
// // // //               builder: (context, scrollController) => Container(
// // // //                 decoration: const BoxDecoration(
// // // //                   color: Color(0xFFF7F7F9),
// // // //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// // // //                 ),
// // // //                 padding: const EdgeInsets.all(20),
// // // //                 child: ListView(
// // // //                   controller: scrollController,
// // // //                   children: [
// // // //                     Center(
// // // //                       child: Container(
// // // //                         width: 40,
// // // //                         height: 5,
// // // //                         margin: const EdgeInsets.only(bottom: 20),
// // // //                         decoration: BoxDecoration(
// // // //                           color: Colors.grey[300],
// // // //                           borderRadius: BorderRadius.circular(8),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                     Text(
// // // //                         isNewService ? "Ajouter un service" : "Ajouter un service existant",
// // // //                         style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)
// // // //                     ),
// // // //                     const SizedBox(height: 30),
// // // //
// // // //                     // ✅ NOUVEAU : Champ de recherche intelligent
// // // //                     buildServiceSearchField(setModalState),
// // // //
// // // //                     // ✅ Info du service existant
// // // //                     buildExistingServiceInfo(),
// // // //
// // // //                     // ✅ Description (masquée pour service existant)
// // // //                     if (isNewService)
// // // //                       buildTextField(
// // // //                           "Description *",
// // // //                           descriptionController,
// // // //                           Icons.description,
// // // //                           maxLines: 3
// // // //                       )
// // // //                     else
// // // //                       buildTextField(
// // // //                           "Description",
// // // //                           descriptionController,
// // // //                           Icons.description,
// // // //                           maxLines: 3,
// // // //                           enabled: false
// // // //                       ),
// // // //
// // // //                     // ✅ Catégorie (obligatoire dans les deux modes maintenant)
// // // //                     buildCategorySelector(setModalState),
// // // //
// // // //                     // ✅ Prix et durée (toujours modifiables)
// // // //                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
// // // //                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
// // // //
// // // //                     const SizedBox(height: 20),
// // // //
// // // //                     SizedBox(
// // // //                       width: double.infinity,
// // // //                       child: ElevatedButton(
// // // //                         onPressed: isLoading ? null : () => addService(setModalState),
// // // //                         style: ElevatedButton.styleFrom(
// // // //                           backgroundColor: primaryViolet,
// // // //                           padding: const EdgeInsets.symmetric(vertical: 16),
// // // //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // // //                           elevation: 4,
// // // //                         ),
// // // //                         child: isLoading
// // // //                             ? const CircularProgressIndicator(color: Colors.white)
// // // //                             : Text(
// // // //                             isNewService ? "Créer le service" : "Ajouter au salon",
// // // //                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           );
// // // //         },
// // // //       );
// // // //     },
// // // //   );
// // // // }
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:hairbnb/models/categorie.dart';
// // // // // import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// // // // // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // // // // import 'package:http/http.dart' as http;
// // // // // import 'dart:convert';
// // // // // import 'package:flutter/foundation.dart';
// // // // // import '../../../../../services/firebase_token/token_service.dart';
// // // // // import '../components/show_dialog.dart';
// // // // //
// // // // // Future<void> showAddServiceModal(
// // // // //     BuildContext context,
// // // // //     String coiffeuseId,
// // // // //     VoidCallback onSuccess,
// // // // //     CategoriesProvider categoriesProvider,
// // // // //     ServicesProvider servicesProvider, // ✅ NOUVEAU : Provider pour la recherche
// // // // //     ) {
// // // // //   final TextEditingController nameController = TextEditingController();
// // // // //   final TextEditingController descriptionController = TextEditingController();
// // // // //   final TextEditingController priceController = TextEditingController();
// // // // //   final TextEditingController durationController = TextEditingController();
// // // // //
// // // // //   // ✅ Gestion de la catégorie sélectionnée
// // // // //   Categorie? selectedCategory;
// // // // //
// // // // //   // ✅ NOUVEAU : Gestion du service existant sélectionné
// // // // //   ServiceSuggestion? selectedExistingService;
// // // // //   bool isNewService = true; // Mode par défaut : nouveau service
// // // // //
// // // // //   bool isLoading = false;
// // // // //   final Color primaryViolet = const Color(0xFF7B61FF);
// // // // //
// // // // //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// // // // //       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.only(bottom: 20),
// // // // //       child: TextField(
// // // // //         controller: controller,
// // // // //         maxLines: maxLines,
// // // // //         keyboardType: keyboardType,
// // // // //         enabled: enabled,
// // // // //         decoration: InputDecoration(
// // // // //           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
// // // // //           labelText: label,
// // // // //           filled: true,
// // // // //           fillColor: enabled ? Colors.white : Colors.grey[100],
// // // // //           border: OutlineInputBorder(
// // // // //             borderRadius: BorderRadius.circular(14),
// // // // //             borderSide: BorderSide.none,
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // ✅ NOUVEAU : Widget de recherche de services existants
// // // // //   Widget buildServiceSearchField(StateSetter setModalState) {
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.only(bottom: 20),
// // // // //       child: Column(
// // // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //         children: [
// // // // //           TextField(
// // // // //             controller: nameController,
// // // // //             decoration: InputDecoration(
// // // // //               prefixIcon: Icon(Icons.search, color: primaryViolet),
// // // // //               labelText: "Nom du service *",
// // // // //               hintText: "Tapez pour rechercher ou créer un nouveau service",
// // // // //               filled: true,
// // // // //               fillColor: Colors.white,
// // // // //               border: OutlineInputBorder(
// // // // //                 borderRadius: BorderRadius.circular(14),
// // // // //                 borderSide: BorderSide.none,
// // // // //               ),
// // // // //               suffixIcon: servicesProvider.isSearching
// // // // //                   ? const Padding(
// // // // //                 padding: EdgeInsets.all(12),
// // // // //                 child: SizedBox(
// // // // //                   width: 20,
// // // // //                   height: 20,
// // // // //                   child: CircularProgressIndicator(strokeWidth: 2),
// // // // //                 ),
// // // // //               )
// // // // //                   : null,
// // // // //             ),
// // // // //             onChanged: (value) {
// // // // //               // ✅ Déclencher la recherche
// // // // //               if (value.trim().length >= 2) {
// // // // //                 servicesProvider.searchServices(value.trim());
// // // // //               } else {
// // // // //                 servicesProvider.resetSearch();
// // // // //               }
// // // // //
// // // // //               // ✅ Reset de la sélection si l'utilisateur tape
// // // // //               if (selectedExistingService != null) {
// // // // //                 setModalState(() {
// // // // //                   selectedExistingService = null;
// // // // //                   isNewService = true;
// // // // //                   descriptionController.clear();
// // // // //                   priceController.clear();
// // // // //                   durationController.clear();
// // // // //                   selectedCategory = null;
// // // // //                 });
// // // // //               }
// // // // //             },
// // // // //           ),
// // // // //
// // // // //           // ✅ Liste des suggestions
// // // // //           if (servicesProvider.searchResults.isNotEmpty) ...[
// // // // //             const SizedBox(height: 8),
// // // // //             Container(
// // // // //               constraints: const BoxConstraints(maxHeight: 200),
// // // // //               decoration: BoxDecoration(
// // // // //                 color: Colors.white,
// // // // //                 borderRadius: BorderRadius.circular(12),
// // // // //                 border: Border.all(color: Colors.grey[300]!),
// // // // //               ),
// // // // //               child: ListView.builder(
// // // // //                 shrinkWrap: true,
// // // // //                 itemCount: servicesProvider.searchResults.length,
// // // // //                 itemBuilder: (context, index) {
// // // // //                   final service = servicesProvider.searchResults[index];
// // // // //                   return ListTile(
// // // // //                     leading: Icon(Icons.history, color: primaryViolet, size: 20),
// // // // //                     title: Text(
// // // // //                       service.intituleService,
// // // // //                       style: const TextStyle(fontWeight: FontWeight.w600),
// // // // //                     ),
// // // // //                     subtitle: Column(
// // // // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                       children: [
// // // // //                         Text(
// // // // //                           service.description,
// // // // //                           maxLines: 1,
// // // // //                           overflow: TextOverflow.ellipsis,
// // // // //                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// // // // //                         ),
// // // // //                         const SizedBox(height: 4),
// // // // //                         Row(
// // // // //                           children: [
// // // // //                             Container(
// // // // //                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// // // // //                               decoration: BoxDecoration(
// // // // //                                 color: primaryViolet.withOpacity(0.1),
// // // // //                                 borderRadius: BorderRadius.circular(4),
// // // // //                               ),
// // // // //                               child: Text(
// // // // //                                 "Service global",
// // // // //                                 style: TextStyle(
// // // // //                                   fontSize: 10,
// // // // //                                   color: primaryViolet,
// // // // //                                   fontWeight: FontWeight.w600,
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ),
// // // // //                             const SizedBox(width: 8),
// // // // //                             Text(
// // // // //                               "Réutilisable",
// // // // //                               style: TextStyle(fontSize: 10, color: Colors.grey[500]),
// // // // //                             ),
// // // // //                           ],
// // // // //                         ),
// // // // //                       ],
// // // // //                     ),
// // // // //                     trailing: Column(
// // // // //                       mainAxisAlignment: MainAxisAlignment.center,
// // // // //                       crossAxisAlignment: CrossAxisAlignment.end,
// // // // //                       children: [
// // // // //                         if (service.prixSuggere != null)
// // // // //                           Text(
// // // // //                             "${service.prixSuggere}€",
// // // // //                             style: TextStyle(
// // // // //                               color: Colors.green,
// // // // //                               fontWeight: FontWeight.bold,
// // // // //                               fontSize: 12,
// // // // //                             ),
// // // // //                           ),
// // // // //                         if (service.dureeSuggeree != null)
// // // // //                           Text(
// // // // //                             "${service.dureeSuggeree}min",
// // // // //                             style: TextStyle(
// // // // //                               color: primaryViolet,
// // // // //                               fontSize: 11,
// // // // //                             ),
// // // // //                           ),
// // // // //                       ],
// // // // //                     ),
// // // // //                     onTap: () {
// // // // //                       setModalState(() {
// // // // //                         selectedExistingService = service;
// // // // //                         isNewService = false;
// // // // //                         nameController.text = service.intituleService;
// // // // //                         descriptionController.text = service.description;
// // // // //
// // // // //                         // ✅ Pré-remplir avec les valeurs suggérées
// // // // //                         if (service.prixSuggere != null) {
// // // // //                           priceController.text = service.prixSuggere.toString();
// // // // //                         }
// // // // //                         if (service.dureeSuggeree != null) {
// // // // //                           durationController.text = service.dureeSuggeree.toString();
// // // // //                         }
// // // // //
// // // // //                         // ✅ Pas de pré-sélection de catégorie car pas d'info dans l'API
// // // // //                         // Tu devras demander à l'utilisateur de choisir la catégorie
// // // // //                       });
// // // // //
// // // // //                       // ✅ Reset de la recherche
// // // // //                       servicesProvider.resetSearch();
// // // // //                     },
// // // // //                   );
// // // // //                 },
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //
// // // // //           // ✅ Message d'erreur de recherche
// // // // //           if (servicesProvider.hasSearchError) ...[
// // // // //             const SizedBox(height: 8),
// // // // //             Container(
// // // // //               padding: const EdgeInsets.all(12),
// // // // //               decoration: BoxDecoration(
// // // // //                 color: Colors.red[50],
// // // // //                 borderRadius: BorderRadius.circular(8),
// // // // //                 border: Border.all(color: Colors.red[200]!),
// // // // //               ),
// // // // //               child: Row(
// // // // //                 children: [
// // // // //                   Icon(Icons.error_outline, color: Colors.red[700], size: 20),
// // // // //                   const SizedBox(width: 8),
// // // // //                   Expanded(
// // // // //                     child: Text(
// // // // //                       servicesProvider.searchError!,
// // // // //                       style: TextStyle(color: Colors.red[700], fontSize: 12),
// // // // //                     ),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // ✅ Widget pour sélectionner la catégorie (améliorer pour supporter les services existants)
// // // // //   Widget buildCategorySelector(StateSetter setModalState) {
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.only(bottom: 20),
// // // // //       child: Container(
// // // // //         decoration: BoxDecoration(
// // // // //           color: Colors.white,
// // // // //           borderRadius: BorderRadius.circular(14),
// // // // //         ),
// // // // //         child: Builder(
// // // // //           builder: (context) {
// // // // //             if (categoriesProvider.isLoading) {
// // // // //               return const Padding(
// // // // //                 padding: EdgeInsets.all(16),
// // // // //                 child: Row(
// // // // //                   children: [
// // // // //                     Icon(Icons.category, color: Color(0xFF7B61FF)),
// // // // //                     SizedBox(width: 12),
// // // // //                     Text("Chargement des catégories..."),
// // // // //                     Spacer(),
// // // // //                     SizedBox(
// // // // //                       width: 20,
// // // // //                       height: 20,
// // // // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //               );
// // // // //             }
// // // // //
// // // // //             if (categoriesProvider.hasError) {
// // // // //               return Padding(
// // // // //                 padding: const EdgeInsets.all(16),
// // // // //                 child: Row(
// // // // //                   children: [
// // // // //                     const Icon(Icons.error, color: Colors.red),
// // // // //                     const SizedBox(width: 12),
// // // // //                     Expanded(
// // // // //                       child: Text(
// // // // //                         "Erreur : ${categoriesProvider.errorMessage}",
// // // // //                         style: const TextStyle(color: Colors.red),
// // // // //                       ),
// // // // //                     ),
// // // // //                     IconButton(
// // // // //                       icon: const Icon(Icons.refresh),
// // // // //                       onPressed: () {
// // // // //                         categoriesProvider.refreshCategories();
// // // // //                         setModalState(() {});
// // // // //                       },
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //               );
// // // // //             }
// // // // //
// // // // //             final categories = categoriesProvider.categoriesSorted;
// // // // //
// // // // //             if (categories.isEmpty) {
// // // // //               return const Padding(
// // // // //                 padding: EdgeInsets.all(16),
// // // // //                 child: Row(
// // // // //                   children: [
// // // // //                     Icon(Icons.category, color: Colors.grey),
// // // // //                     SizedBox(width: 12),
// // // // //                     Text("Aucune catégorie disponible"),
// // // // //                   ],
// // // // //                 ),
// // // // //               );
// // // // //             }
// // // // //
// // // // //             return DropdownButtonFormField<Categorie>(
// // // // //               value: selectedCategory,
// // // // //               decoration: InputDecoration(
// // // // //                 prefixIcon: Icon(Icons.category, color: primaryViolet),
// // // // //                 labelText: "Catégorie *",
// // // // //                 filled: true,
// // // // //                 fillColor: Colors.white,
// // // // //                 border: OutlineInputBorder(
// // // // //                   borderRadius: BorderRadius.circular(14),
// // // // //                   borderSide: BorderSide.none,
// // // // //                 ),
// // // // //               ),
// // // // //               hint: const Text("Sélectionner une catégorie"),
// // // // //               items: categories.map((Categorie category) {
// // // // //                 return DropdownMenuItem<Categorie>(
// // // // //                   value: category,
// // // // //                   child: Text(
// // // // //                     category.nom,
// // // // //                     style: const TextStyle(fontSize: 16),
// // // // //                   ),
// // // // //                 );
// // // // //               }).toList(),
// // // // //               onChanged: (Categorie? newValue) {
// // // // //                 setModalState(() {
// // // // //                   selectedCategory = newValue;
// // // // //                 });
// // // // //               },
// // // // //             );
// // // // //           },
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   // ✅ Widget d'information du service existant
// // // // //   Widget buildExistingServiceInfo() {
// // // // //     if (selectedExistingService == null) return const SizedBox.shrink();
// // // // //
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.only(bottom: 20),
// // // // //       child: Container(
// // // // //         padding: const EdgeInsets.all(16),
// // // // //         decoration: BoxDecoration(
// // // // //           color: Colors.blue[50],
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           border: Border.all(color: Colors.blue[200]!),
// // // // //         ),
// // // // //         child: Column(
// // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // //           children: [
// // // // //             Row(
// // // // //               children: [
// // // // //                 Icon(Icons.info_outline, color: Colors.blue[700]),
// // // // //                 const SizedBox(width: 8),
// // // // //                 Text(
// // // // //                   "Service existant sélectionné",
// // // // //                   style: TextStyle(
// // // // //                     fontWeight: FontWeight.bold,
// // // // //                     color: Colors.blue[700],
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //             const SizedBox(height: 8),
// // // // //             Text(
// // // // //               "Vous ajoutez un service global existant à votre salon. Vous devez choisir une catégorie et pouvez personnaliser le prix et la durée.",
// // // // //               style: TextStyle(color: Colors.blue[600], fontSize: 13),
// // // // //             ),
// // // // //             const SizedBox(height: 8),
// // // // //             Text(
// // // // //               "Service global réutilisable",
// // // // //               style: TextStyle(color: Colors.blue[500], fontSize: 12),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // //
// // // // //   Future<void> addService(StateSetter setModalState) async {
// // // // //     final intitule = nameController.text.trim();
// // // // //     final description = descriptionController.text.trim();
// // // // //     final prixText = priceController.text.trim();
// // // // //     final durationText = durationController.text.trim();
// // // // //
// // // // //     // ✅ Vérifications spécifiques selon le mode
// // // // //     if (isNewService) {
// // // // //       // Mode nouveau service : tous les champs obligatoires
// // // // //       if (selectedCategory == null) {
// // // // //         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// // // // //         return;
// // // // //       }
// // // // //
// // // // //       if (intitule.isEmpty || description.isEmpty || prixText.isEmpty || durationText.isEmpty) {
// // // // //         showErrorDialog(context, "Tous les champs sont obligatoires.");
// // // // //         return;
// // // // //       }
// // // // //     } else {
// // // // //       // Mode service existant : catégorie obligatoire + prix et durée
// // // // //       if (selectedCategory == null) {
// // // // //         showErrorDialog(context, "Veuillez sélectionner une catégorie pour ce service global.");
// // // // //         return;
// // // // //       }
// // // // //
// // // // //       if (prixText.isEmpty || durationText.isEmpty) {
// // // // //         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
// // // // //         return;
// // // // //       }
// // // // //     }
// // // // //
// // // // //     bool hasAtMostTwoDecimalPlaces(double value) {
// // // // //       return ((value * 100).roundToDouble() == (value * 100));
// // // // //     }
// // // // //
// // // // //     // Vérifications supplémentaires pour nouveau service
// // // // //     if (isNewService) {
// // // // //       if (intitule.length > 100) {
// // // // //         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
// // // // //         return;
// // // // //       }
// // // // //
// // // // //       if (description.length > 700) {
// // // // //         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
// // // // //         return;
// // // // //       }
// // // // //     }
// // // // //
// // // // //     final double? prix = double.tryParse(prixText);
// // // // //     final int? temps = int.tryParse(durationText);
// // // // //
// // // // //     if (prix == null || temps == null) {
// // // // //       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
// // // // //       return;
// // // // //     }
// // // // //
// // // // //     if (prix > 999) {
// // // // //       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
// // // // //       return;
// // // // //     }
// // // // //
// // // // //     if (!hasAtMostTwoDecimalPlaces(prix)) {
// // // // //       showErrorDialog(context, "Le prix doit avoir au maximum 2 chiffres après la virgule.");
// // // // //       return;
// // // // //     }
// // // // //
// // // // //     if (temps > 480) {
// // // // //       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
// // // // //       return;
// // // // //     }
// // // // //
// // // // //     setModalState(() => isLoading = true);
// // // // //
// // // // //     try {
// // // // //       final String? idToken = await TokenService.getAuthToken();
// // // // //
// // // // //       if (idToken == null) {
// // // // //         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
// // // // //         setModalState(() => isLoading = false);
// // // // //         return;
// // // // //       }
// // // // //
// // // // //       if (kDebugMode) {
// // // // //         print("🚀 Mode: ${isNewService ? 'Nouveau service' : 'Service existant'}");
// // // // //         if (isNewService) {
// // // // //           print("📁 Catégorie: ${selectedCategory!.nom} (ID: ${selectedCategory!.id})");
// // // // //         } else {
// // // // //           print("🔄 Service existant ID: ${selectedExistingService!.id}");
// // // // //         }
// // // // //       }
// // // // //
// // // // //       http.Response response;
// // // // //
// // // // //       if (isNewService) {
// // // // //         // ✅ API pour créer un nouveau service global
// // // // //         response = await http.post(
// // // // //           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// // // // //           headers: {
// // // // //             'Content-Type': 'application/json',
// // // // //             'Authorization': 'Bearer $idToken',
// // // // //           },
// // // // //           body: json.encode({
// // // // //             'userId': int.parse(coiffeuseId),
// // // // //             'intitule_service': intitule,
// // // // //             'description': description,
// // // // //             'prix': prix,
// // // // //             'temps_minutes': temps,
// // // // //             'categorie_id': selectedCategory!.id,
// // // // //           }),
// // // // //         );
// // // // //       } else {
// // // // //         // ✅ API pour ajouter un service existant (à créer côté backend)
// // // // //         response = await http.post(
// // // // //           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
// // // // //           headers: {
// // // // //             'Content-Type': 'application/json',
// // // // //             'Authorization': 'Bearer $idToken',
// // // // //           },
// // // // //           body: json.encode({
// // // // //             'userId': int.parse(coiffeuseId),
// // // // //             'service_id': selectedExistingService!.id,
// // // // //             'prix': prix,
// // // // //             'temps_minutes': temps,
// // // // //           }),
// // // // //         );
// // // // //       }
// // // // //
// // // // //       if (kDebugMode) {
// // // // //         print("📊 Status code: ${response.statusCode}");
// // // // //         print("📋 Réponse: ${response.body}");
// // // // //       }
// // // // //
// // // // //       if (response.statusCode == 201) {
// // // // //         Navigator.pop(context, true);
// // // // //         onSuccess();
// // // // //
// // // // //         showSuccessDialog(
// // // // //             context,
// // // // //             isNewService
// // // // //                 ? "Service '$intitule' créé et ajouté avec succès !"
// // // // //                 : "Service '$intitule' ajouté à votre salon !"
// // // // //         );
// // // // //       } else {
// // // // //         Map<String, dynamic> errorResponse = {};
// // // // //         try {
// // // // //           errorResponse = json.decode(response.body);
// // // // //         } catch (e) {
// // // // //           // Si la réponse n'est pas du JSON valide
// // // // //         }
// // // // //
// // // // //         String errorMessage = errorResponse['message'] ??
// // // // //             errorResponse['detail'] ??
// // // // //             "Erreur lors de l'ajout du service (${response.statusCode})";
// // // // //
// // // // //         if (response.statusCode == 401) {
// // // // //           await TokenService.clearAuthToken();
// // // // //         }
// // // // //
// // // // //         showErrorDialog(context, errorMessage);
// // // // //       }
// // // // //     } catch (e) {
// // // // //       showErrorDialog(context, "Erreur de connexion: $e");
// // // // //     } finally {
// // // // //       setModalState(() => isLoading = false);
// // // // //     }
// // // // //   }
// // // // //
// // // // //   return showModalBottomSheet(
// // // // //     context: context,
// // // // //     isScrollControlled: true,
// // // // //     backgroundColor: Colors.transparent,
// // // // //     builder: (context) {
// // // // //       return StatefulBuilder(
// // // // //         builder: (BuildContext context, StateSetter setModalState) {
// // // // //           return AnimatedPadding(
// // // // //             duration: const Duration(milliseconds: 300),
// // // // //             curve: Curves.easeOut,
// // // // //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// // // // //             child: DraggableScrollableSheet(
// // // // //               initialChildSize: 0.85,
// // // // //               maxChildSize: 0.95,
// // // // //               minChildSize: 0.5,
// // // // //               expand: false,
// // // // //               builder: (context, scrollController) => Container(
// // // // //                 decoration: const BoxDecoration(
// // // // //                   color: Color(0xFFF7F7F9),
// // // // //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// // // // //                 ),
// // // // //                 padding: const EdgeInsets.all(20),
// // // // //                 child: ListView(
// // // // //                   controller: scrollController,
// // // // //                   children: [
// // // // //                     Center(
// // // // //                       child: Container(
// // // // //                         width: 40,
// // // // //                         height: 5,
// // // // //                         margin: const EdgeInsets.only(bottom: 20),
// // // // //                         decoration: BoxDecoration(
// // // // //                           color: Colors.grey[300],
// // // // //                           borderRadius: BorderRadius.circular(8),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ),
// // // // //                     Text(
// // // // //                         isNewService ? "Ajouter un service" : "Ajouter un service existant",
// // // // //                         style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)
// // // // //                     ),
// // // // //                     const SizedBox(height: 30),
// // // // //
// // // // //                     // ✅ NOUVEAU : Champ de recherche intelligent
// // // // //                     buildServiceSearchField(setModalState),
// // // // //
// // // // //                     // ✅ Info du service existant
// // // // //                     buildExistingServiceInfo(),
// // // // //
// // // // //                     // ✅ Description (masquée pour service existant)
// // // // //                     if (isNewService)
// // // // //                       buildTextField(
// // // // //                           "Description *",
// // // // //                           descriptionController,
// // // // //                           Icons.description,
// // // // //                           maxLines: 3
// // // // //                       )
// // // // //                     else
// // // // //                       buildTextField(
// // // // //                           "Description",
// // // // //                           descriptionController,
// // // // //                           Icons.description,
// // // // //                           maxLines: 3,
// // // // //                           enabled: false
// // // // //                       ),
// // // // //
// // // // //                     // ✅ Catégorie (obligatoire dans les deux modes maintenant)
// // // // //                     buildCategorySelector(setModalState),
// // // // //
// // // // //                     // ✅ Prix et durée (toujours modifiables)
// // // // //                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
// // // // //                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
// // // // //
// // // // //                     const SizedBox(height: 20),
// // // // //
// // // // //                     SizedBox(
// // // // //                       width: double.infinity,
// // // // //                       child: ElevatedButton(
// // // // //                         onPressed: isLoading ? null : () => addService(setModalState),
// // // // //                         style: ElevatedButton.styleFrom(
// // // // //                           backgroundColor: primaryViolet,
// // // // //                           padding: const EdgeInsets.symmetric(vertical: 16),
// // // // //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // // // //                           elevation: 4,
// // // // //                         ),
// // // // //                         child: isLoading
// // // // //                             ? const CircularProgressIndicator(color: Colors.white)
// // // // //                             : Text(
// // // // //                             isNewService ? "Créer le service" : "Ajouter au salon",
// // // // //                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
// // // // //                         ),
// // // // //                       ),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           );
// // // // //         },
// // // // //       );
// // // // //     },
// // // // //   );
// // // // // }
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:hairbnb/models/categorie.dart';
// // // // // // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // // // // // import 'package:http/http.dart' as http;
// // // // // // import 'dart:convert';
// // // // // // import 'package:flutter/foundation.dart';
// // // // // // import '../../../../../services/firebase_token/token_service.dart';
// // // // // // import '../components/show_dialog.dart';
// // // // // //
// // // // // //
// // // // // // Future<void> showAddServiceModal(
// // // // // //     BuildContext context,
// // // // // //     String coiffeuseId,
// // // // // //     VoidCallback onSuccess,
// // // // // //     CategoriesProvider categoriesProvider  // ✅ Provider passé directement
// // // // // //     ) {
// // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // //   final TextEditingController descriptionController = TextEditingController();
// // // // // //   final TextEditingController priceController = TextEditingController();
// // // // // //   final TextEditingController durationController = TextEditingController();
// // // // // //
// // // // // //   // ✅ Gestion de la catégorie sélectionnée
// // // // // //   Categorie? selectedCategory;
// // // // // //
// // // // // //   bool isLoading = false;
// // // // // //   final Color primaryViolet = const Color(0xFF7B61FF);
// // // // // //
// // // // // //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// // // // // //       {TextInputType? keyboardType, int maxLines = 1}) {
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.only(bottom: 20),
// // // // // //       child: TextField(
// // // // // //         controller: controller,
// // // // // //         maxLines: maxLines,
// // // // // //         keyboardType: keyboardType,
// // // // // //         decoration: InputDecoration(
// // // // // //           prefixIcon: Icon(icon, color: primaryViolet),
// // // // // //           labelText: label,
// // // // // //           filled: true,
// // // // // //           fillColor: Colors.white,
// // // // // //           border: OutlineInputBorder(
// // // // // //             borderRadius: BorderRadius.circular(14),
// // // // // //             borderSide: BorderSide.none,
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   // ✅ Widget pour sélectionner la catégorie (SANS Consumer)
// // // // // //   Widget buildCategorySelector(StateSetter setModalState) {
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.only(bottom: 20),
// // // // // //       child: Container(
// // // // // //         decoration: BoxDecoration(
// // // // // //           color: Colors.white,
// // // // // //           borderRadius: BorderRadius.circular(14),
// // // // // //         ),
// // // // // //         child: Builder(  // ✅ Utilise Builder au lieu de Consumer
// // // // // //           builder: (context) {
// // // // // //             // ✅ Utilise directement le provider passé en paramètre
// // // // // //             if (categoriesProvider.isLoading) {
// // // // // //               return const Padding(
// // // // // //                 padding: EdgeInsets.all(16),
// // // // // //                 child: Row(
// // // // // //                   children: [
// // // // // //                     Icon(Icons.category, color: Color(0xFF7B61FF)),
// // // // // //                     SizedBox(width: 12),
// // // // // //                     Text("Chargement des catégories..."),
// // // // // //                     Spacer(),
// // // // // //                     SizedBox(
// // // // // //                       width: 20,
// // // // // //                       height: 20,
// // // // // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               );
// // // // // //             }
// // // // // //
// // // // // //             if (categoriesProvider.hasError) {
// // // // // //               return Padding(
// // // // // //                 padding: const EdgeInsets.all(16),
// // // // // //                 child: Row(
// // // // // //                   children: [
// // // // // //                     const Icon(Icons.error, color: Colors.red),
// // // // // //                     const SizedBox(width: 12),
// // // // // //                     Expanded(
// // // // // //                       child: Text(
// // // // // //                         "Erreur : ${categoriesProvider.errorMessage}",
// // // // // //                         style: const TextStyle(color: Colors.red),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                     IconButton(
// // // // // //                       icon: const Icon(Icons.refresh),
// // // // // //                       onPressed: () {
// // // // // //                         categoriesProvider.refreshCategories();
// // // // // //                         setModalState(() {}); // ✅ Force la mise à jour du modal
// // // // // //                       },
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               );
// // // // // //             }
// // // // // //
// // // // // //             final categories = categoriesProvider.categoriesSorted;
// // // // // //
// // // // // //             if (categories.isEmpty) {
// // // // // //               return const Padding(
// // // // // //                 padding: EdgeInsets.all(16),
// // // // // //                 child: Row(
// // // // // //                   children: [
// // // // // //                     Icon(Icons.category, color: Colors.grey),
// // // // // //                     SizedBox(width: 12),
// // // // // //                     Text("Aucune catégorie disponible"),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               );
// // // // // //             }
// // // // // //
// // // // // //             return DropdownButtonFormField<Categorie>(
// // // // // //               value: selectedCategory,
// // // // // //               decoration: InputDecoration(
// // // // // //                 prefixIcon: Icon(Icons.category, color: primaryViolet),
// // // // // //                 labelText: "Catégorie *",
// // // // // //                 filled: true,
// // // // // //                 fillColor: Colors.white,
// // // // // //                 border: OutlineInputBorder(
// // // // // //                   borderRadius: BorderRadius.circular(14),
// // // // // //                   borderSide: BorderSide.none,
// // // // // //                 ),
// // // // // //               ),
// // // // // //               hint: const Text("Sélectionner une catégorie"),
// // // // // //               items: categories.map((Categorie category) {
// // // // // //                 return DropdownMenuItem<Categorie>(
// // // // // //                   value: category,
// // // // // //                   child: Text(
// // // // // //                     category.nom,
// // // // // //                     style: const TextStyle(fontSize: 16),
// // // // // //                   ),
// // // // // //                 );
// // // // // //               }).toList(),
// // // // // //               onChanged: (Categorie? newValue) {
// // // // // //                 setModalState(() {
// // // // // //                   selectedCategory = newValue;
// // // // // //                 });
// // // // // //               },
// // // // // //             );
// // // // // //           },
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   Future<void> addService(StateSetter setModalState) async {
// // // // // //     final intitule = nameController.text.trim();
// // // // // //     final description = descriptionController.text.trim();
// // // // // //     final prixText = priceController.text.trim();
// // // // // //     final durationText = durationController.text.trim();
// // // // // //
// // // // // //     // ✅ Vérification de la catégorie
// // // // // //     if (selectedCategory == null) {
// // // // // //       showErrorDialog(context, "Veuillez sélectionner une catégorie.");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     // Vérifications des champs vides
// // // // // //     if (intitule.isEmpty || description.isEmpty || prixText.isEmpty || durationText.isEmpty) {
// // // // // //       showErrorDialog(context, "Tous les champs sont obligatoires.");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     bool hasAtMostTwoDecimalPlaces(double value) {
// // // // // //       return ((value * 100).roundToDouble() == (value * 100));
// // // // // //     }
// // // // // //
// // // // // //     // Vérifications supplémentaires
// // // // // //     if (intitule.length > 100) {
// // // // // //       showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (description.length > 700) {
// // // // // //       showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     final double? prix = double.tryParse(prixText);
// // // // // //     final int? temps = int.tryParse(durationText);
// // // // // //
// // // // // //     if (prix == null || temps == null) {
// // // // // //       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (prix > 999) {
// // // // // //       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (!hasAtMostTwoDecimalPlaces(prix)) {
// // // // // //       showErrorDialog(context, "Le prix doit avoir au maximum 2 chiffres après la virgule.");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (temps > 480) {
// // // // // //       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     setModalState(() => isLoading = true);
// // // // // //
// // // // // //     try {
// // // // // //       final String? idToken = await TokenService.getAuthToken();
// // // // // //
// // // // // //       if (idToken == null) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           const SnackBar(
// // // // // //             content: Text("Erreur d'authentification. Veuillez vous reconnecter."),
// // // // // //             backgroundColor: Colors.red,
// // // // // //           ),
// // // // // //         );
// // // // // //         setModalState(() => isLoading = false);
// // // // // //         return;
// // // // // //       }
// // // // // //
// // // // // //       if (kDebugMode) {
// // // // // //         print("🚀 Envoi de la requête avec token authentifié");
// // // // // //         print("📁 Catégorie sélectionnée: ${selectedCategory!.nom} (ID: ${selectedCategory!.id})");
// // // // // //       }
// // // // // //
// // // // // //       // ✅ Envoyer la requête avec l'ID de la catégorie - NOUVELLE API
// // // // // //       final response = await http.post(
// // // // // //         Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
// // // // // //         headers: {
// // // // // //           'Content-Type': 'application/json',
// // // // // //           'Authorization': 'Bearer $idToken',
// // // // // //         },
// // // // // //         body: json.encode({
// // // // // //           'userId': int.parse(coiffeuseId),  // ✅ Convertir en int
// // // // // //           'intitule_service': intitule,
// // // // // //           'description': description,
// // // // // //           'prix': prix,
// // // // // //           'temps_minutes': temps,
// // // // // //           'categorie_id': selectedCategory!.id,  // ✅ Nom correct du champ
// // // // // //         }),
// // // // // //       );
// // // // // //
// // // // // //       if (kDebugMode) {
// // // // // //         print("📊 Status code: ${response.statusCode}");
// // // // // //         print("📋 Réponse: ${response.body}");
// // // // // //       }
// // // // // //
// // // // // //       if (response.statusCode == 201) {
// // // // // //         // ✅ Succès
// // // // // //         Navigator.pop(context, true);
// // // // // //         onSuccess();
// // // // // //
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(
// // // // // //             content: Text("Service '$intitule' ajouté avec succès !"),
// // // // // //             backgroundColor: Colors.green,
// // // // // //             behavior: SnackBarBehavior.floating,
// // // // // //           ),
// // // // // //         );
// // // // // //       } else {
// // // // // //         Map<String, dynamic> errorResponse = {};
// // // // // //         try {
// // // // // //           errorResponse = json.decode(response.body);
// // // // // //         } catch (e) {
// // // // // //           // Si la réponse n'est pas du JSON valide
// // // // // //         }
// // // // // //
// // // // // //         String errorMessage = errorResponse['message'] ??
// // // // // //             errorResponse['detail'] ??
// // // // // //             "Erreur lors de l'ajout du service (${response.statusCode})";
// // // // // //
// // // // // //         if (response.statusCode == 401) {
// // // // // //           await TokenService.clearAuthToken();
// // // // // //         }
// // // // // //
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
// // // // // //         );
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //     } finally {
// // // // // //       setModalState(() => isLoading = false);
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   return showModalBottomSheet(
// // // // // //     context: context,
// // // // // //     isScrollControlled: true,
// // // // // //     backgroundColor: Colors.transparent,
// // // // // //     builder: (context) {
// // // // // //       return StatefulBuilder(
// // // // // //         builder: (BuildContext context, StateSetter setModalState) {
// // // // // //           return AnimatedPadding(
// // // // // //             duration: const Duration(milliseconds: 300),
// // // // // //             curve: Curves.easeOut,
// // // // // //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// // // // // //             child: DraggableScrollableSheet(
// // // // // //               initialChildSize: 0.85,
// // // // // //               maxChildSize: 0.95,
// // // // // //               minChildSize: 0.5,
// // // // // //               expand: false,
// // // // // //               builder: (context, scrollController) => Container(
// // // // // //                 decoration: const BoxDecoration(
// // // // // //                   color: Color(0xFFF7F7F9),
// // // // // //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// // // // // //                 ),
// // // // // //                 padding: const EdgeInsets.all(20),
// // // // // //                 child: ListView(
// // // // // //                   controller: scrollController,
// // // // // //                   children: [
// // // // // //                     Center(
// // // // // //                       child: Container(
// // // // // //                         width: 40,
// // // // // //                         height: 5,
// // // // // //                         margin: const EdgeInsets.only(bottom: 20),
// // // // // //                         decoration: BoxDecoration(
// // // // // //                           color: Colors.grey[300],
// // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                     const Text(
// // // // // //                         "Ajouter un service",
// // // // // //                         style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)
// // // // // //                     ),
// // // // // //                     const SizedBox(height: 30),
// // // // // //
// // // // // //                     buildTextField("Nom du service *", nameController, Icons.design_services),
// // // // // //                     buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
// // // // // //
// // // // // //                     // ✅ Sélecteur de catégorie (SANS Consumer)
// // // // // //                     buildCategorySelector(setModalState),
// // // // // //
// // // // // //                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
// // // // // //                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
// // // // // //
// // // // // //                     const SizedBox(height: 20),
// // // // // //
// // // // // //                     SizedBox(
// // // // // //                       width: double.infinity,
// // // // // //                       child: ElevatedButton(
// // // // // //                         onPressed: isLoading ? null : () => addService(setModalState),
// // // // // //                         style: ElevatedButton.styleFrom(
// // // // // //                           backgroundColor: primaryViolet,
// // // // // //                           padding: const EdgeInsets.symmetric(vertical: 16),
// // // // // //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // // // // //                           elevation: 4,
// // // // // //                         ),
// // // // // //                         child: isLoading
// // // // // //                             ? const CircularProgressIndicator(color: Colors.white)
// // // // // //                             : const Text(
// // // // // //                             "Ajouter le service",
// // // // // //                             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           );
// // // // // //         },
// // // // // //       );
// // // // // //     },
// // // // // //   );
// // // // // // }
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // //
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:hairbnb/services/providers/services_categories_provider.dart';
// // // // // // import 'package:http/http.dart' as http;
// // // // // // import 'dart:convert';
// // // // // // import 'package:flutter/foundation.dart';
// // // // // // import '../../../../../services/firebase_token/token_service.dart';
// // // // // //
// // // // // // Future<void> showAddServiceModal(BuildContext context, String coiffeuseId, VoidCallback onSuccess, CategoriesProvider categoriesProvider) {
// // // // // //   final TextEditingController nameController = TextEditingController();
// // // // // //   final TextEditingController descriptionController = TextEditingController();
// // // // // //   final TextEditingController priceController = TextEditingController();
// // // // // //   final TextEditingController durationController = TextEditingController();
// // // // // //   bool isLoading = false;
// // // // // //   final Color primaryViolet = const Color(0xFF7B61FF);
// // // // // //
// // // // // //   Widget buildTextField(String label, TextEditingController controller, IconData icon,
// // // // // //       {TextInputType? keyboardType, int maxLines = 1}) {
// // // // // //     return Padding(
// // // // // //       padding: const EdgeInsets.only(bottom: 20),
// // // // // //       child: TextField(
// // // // // //         controller: controller,
// // // // // //         maxLines: maxLines,
// // // // // //         keyboardType: keyboardType,
// // // // // //         decoration: InputDecoration(
// // // // // //           prefixIcon: Icon(icon, color: primaryViolet),
// // // // // //           labelText: label,
// // // // // //           filled: true,
// // // // // //           fillColor: Colors.white,
// // // // // //           border: OutlineInputBorder(
// // // // // //             borderRadius: BorderRadius.circular(14),
// // // // // //             borderSide: BorderSide.none,
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // //
// // // // // //   Future<void> addService(StateSetter setModalState) async {
// // // // // //     final intitule = nameController.text.trim();
// // // // // //     final description = descriptionController.text.trim();
// // // // // //     final prixText = priceController.text.trim();
// // // // // //     final durationText = durationController.text.trim();
// // // // // //
// // // // // //     // Vérifications des champs vides
// // // // // //     if (intitule.isEmpty || description.isEmpty || prixText.isEmpty || durationText.isEmpty) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("Tous les champs sont obligatoires."), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     bool hasAtMostTwoDecimalPlaces(double value) {
// // // // // //       return ((value * 100).roundToDouble() == (value * 100));
// // // // // //     }
// // // // // //
// // // // // //     // Vérifications supplémentaires
// // // // // //     if (intitule.length > 100) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("L'intitulé ne doit pas dépasser 100 caractères."), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (description.length > 700) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("La description ne doit pas dépasser 700 caractères."), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     final double? prix = double.tryParse(prixText);
// // // // // //     final int? temps = int.tryParse(durationText);
// // // // // //
// // // // // //     if (prix == null || temps == null) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("Prix et durée doivent être des nombres valides."), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (prix > 999) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("Le prix ne doit pas dépasser 999 €."), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (!hasAtMostTwoDecimalPlaces(prix)) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("Le prix doit avoir au maximum 2 chiffres après la virgule."), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     if (temps > 480) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(content: Text("La durée ne doit pas dépasser 8 heures (480 minutes)."), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //       return;
// // // // // //     }
// // // // // //
// // // // // //     setModalState(() => isLoading = true);
// // // // // //
// // // // // //     try {
// // // // // //       // Utiliser TokenService au lieu de Firebase Auth directement
// // // // // //       final String? idToken = await TokenService.getAuthToken();
// // // // // //
// // // // // //       if (idToken == null) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           const SnackBar(
// // // // // //             content: Text("Erreur d'authentification. Veuillez vous reconnecter."),
// // // // // //             backgroundColor: Colors.red,
// // // // // //           ),
// // // // // //         );
// // // // // //         setModalState(() => isLoading = false);
// // // // // //         return;
// // // // // //       }
// // // // // //
// // // // // //       if (kDebugMode) {
// // // // // //         print("Envoi de la requête avec token authentifié");
// // // // // //       }
// // // // // //
// // // // // //       // Envoyer la requête avec le token d'authentification
// // // // // //       final response = await http.post(
// // // // // //         Uri.parse('https://www.hairbnb.site/api/add_service_to_salon/'),
// // // // // //         headers: {
// // // // // //           'Content-Type': 'application/json',
// // // // // //           'Authorization': 'Bearer $idToken',
// // // // // //         },
// // // // // //         body: json.encode({
// // // // // //           'userId': coiffeuseId,
// // // // // //           'intitule_service': intitule,
// // // // // //           'description': description,
// // // // // //           'prix': prix,
// // // // // //           'temps_minutes': temps,
// // // // // //         }),
// // // // // //       );
// // // // // //
// // // // // //       // Log de debug
// // // // // //       if (kDebugMode) {
// // // // // //         print("Status code: ${response.statusCode}");
// // // // // //         print("Réponse: ${response.body}");
// // // // // //       }
// // // // // //
// // // // // //       // Analyser la réponse
// // // // // //       if (response.statusCode == 201) {
// // // // // //         // Fermer la modal et appeler le callback de succès
// // // // // //         Navigator.pop(context, true);
// // // // // //         onSuccess();
// // // // // //       } else {
// // // // // //         // Traiter les différents codes d'erreur
// // // // // //         Map<String, dynamic> errorResponse = {};
// // // // // //         try {
// // // // // //           errorResponse = json.decode(response.body);
// // // // // //         } catch (e) {
// // // // // //           // Si la réponse n'est pas du JSON valide
// // // // // //         }
// // // // // //
// // // // // //         String errorMessage = errorResponse['message'] ??
// // // // // //             errorResponse['detail'] ??
// // // // // //             "Erreur lors de l'ajout du service (${response.statusCode})";
// // // // // //
// // // // // //         // Si erreur d'authentification, effacer le token
// // // // // //         if (response.statusCode == 401) {
// // // // // //           await TokenService.clearAuthToken();
// // // // // //         }
// // // // // //
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
// // // // // //         );
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
// // // // // //       );
// // // // // //     } finally {
// // // // // //       setModalState(() => isLoading = false);
// // // // // //     }
// // // // // //   }
// // // // // //
// // // // // //   return showModalBottomSheet(
// // // // // //     context: context,
// // // // // //     isScrollControlled: true,
// // // // // //     backgroundColor: Colors.transparent,
// // // // // //     builder: (context) {
// // // // // //       return StatefulBuilder(
// // // // // //         builder: (BuildContext context, StateSetter setModalState) {
// // // // // //           return AnimatedPadding(
// // // // // //             duration: const Duration(milliseconds: 300),
// // // // // //             curve: Curves.easeOut,
// // // // // //             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
// // // // // //             child: DraggableScrollableSheet(
// // // // // //               initialChildSize: 0.85,
// // // // // //               maxChildSize: 0.95,
// // // // // //               minChildSize: 0.5,
// // // // // //               expand: false,
// // // // // //               builder: (context, scrollController) => Container(
// // // // // //                 decoration: const BoxDecoration(
// // // // // //                   color: Color(0xFFF7F7F9),
// // // // // //                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
// // // // // //                 ),
// // // // // //                 padding: const EdgeInsets.all(20),
// // // // // //                 child: ListView(
// // // // // //                   controller: scrollController,
// // // // // //                   children: [
// // // // // //                     Center(
// // // // // //                       child: Container(
// // // // // //                         width: 40,
// // // // // //                         height: 5,
// // // // // //                         margin: const EdgeInsets.only(bottom: 20),
// // // // // //                         decoration: BoxDecoration(
// // // // // //                           color: Colors.grey[300],
// // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                     const Text("Ajouter un service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
// // // // // //                     const SizedBox(height: 30),
// // // // // //                     buildTextField("Nom du service", nameController, Icons.design_services),
// // // // // //                     buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
// // // // // //                     buildTextField("Prix (€)", priceController, Icons.euro, keyboardType: TextInputType.number),
// // // // // //                     buildTextField("Durée (minutes)", durationController, Icons.timer, keyboardType: TextInputType.number),
// // // // // //                     const SizedBox(height: 20),
// // // // // //                     SizedBox(
// // // // // //                       width: double.infinity,
// // // // // //                       child: ElevatedButton(
// // // // // //                         onPressed: isLoading ? null : () => addService(setModalState),
// // // // // //                         style: ElevatedButton.styleFrom(
// // // // // //                           backgroundColor: primaryViolet,
// // // // // //                           padding: const EdgeInsets.symmetric(vertical: 16),
// // // // // //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // // // // //                           elevation: 4,
// // // // // //                         ),
// // // // // //                         child: isLoading
// // // // // //                             ? const CircularProgressIndicator(color: Colors.white)
// // // // // //                             : const Text("Ajouter le service", style: TextStyle(fontWeight: FontWeight.bold)),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           );
// // // // // //         },
// // // // // //       );
// // // // // //     },
// // // // // //   );
// // // // // // }