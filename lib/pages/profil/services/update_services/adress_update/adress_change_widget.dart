// lib/pages/profil/widgets/address_change_widget.dart
// Remplacer complètement le contenu de votre fichier par ceci

import 'package:flutter/material.dart';
// Imports avec alias pour éviter les conflits
import 'package:hairbnb/models/current_user.dart' as UserModel;
import 'package:hairbnb/models/adresse.dart' as AdresseModel;
import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_update_service.dart';
import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_validation.dart';

import '../../../profil_widgets/auto_complete_widget.dart';
import '../../../profil_widgets/commune_autofill_widget.dart';

class AddressChangeWidget extends StatefulWidget {
  final UserModel.CurrentUser currentUser;
  final UserModel.Adresse? currentAddress; // Utiliser le modèle CurrentUser
  final Function(bool) setLoadingState;
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;

  const AddressChangeWidget({
    super.key,
    required this.currentUser,
    this.currentAddress,
    required this.setLoadingState,
    required this.primaryColor,
    required this.successColor,
    required this.errorColor,
  });

  @override
  State<AddressChangeWidget> createState() => _AddressChangeWidgetState();
}

class _AddressChangeWidgetState extends State<AddressChangeWidget> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  late TextEditingController _numeroController;
  late TextEditingController _rueController;
  late TextEditingController _communeController;
  late TextEditingController _codePostalController;

  // État de validation
  bool _isValidating = false;
  bool _isAddressValid = false;
  String? _validationMessage;
  double? _validatedLatitude;
  double? _validatedLongitude;

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs avec conversion explicite
    _numeroController = TextEditingController(
        text: widget.currentAddress?.numero != null
            ? widget.currentAddress!.numero.toString()
            : ''
    );
    _rueController = TextEditingController(
        text: widget.currentAddress?.rue?.nomRue ?? ''
    );
    _communeController = TextEditingController(
        text: widget.currentAddress?.rue?.localite?.commune ?? ''
    );
    _codePostalController = TextEditingController(
        text: widget.currentAddress?.rue?.localite?.codePostal ?? ''
    );

    // Reset validation quand l'utilisateur modifie
    _numeroController.addListener(_resetValidation);
    _rueController.addListener(_resetValidation);
    _communeController.addListener(_resetValidation);
    _codePostalController.addListener(_resetValidation);
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _rueController.dispose();
    _communeController.dispose();
    _codePostalController.dispose();
    super.dispose();
  }

  void _resetValidation() {
    if (_isAddressValid) {
      setState(() {
        _isAddressValid = false;
        _validationMessage = null;
        _validatedLatitude = null;
        _validatedLongitude = null;
      });
    }
  }

  Future<void> _validateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    // Créer l'adresse pour validation avec le modèle AdresseModel
    final adresse = AdresseModel.Adresse(
      numero: int.tryParse(_numeroController.text),
      rue: AdresseModel.Rue(
        nomRue: _rueController.text,
        localite: AdresseModel.Localite(
          commune: _communeController.text,
          codePostal: _codePostalController.text,
        ),
      ),
    );

    try {
      final result = await AddressValidationService.validateAddress(adresse);

      setState(() {
        _isValidating = false;
        _isAddressValid = result.isValid;

        if (result.isValid) {
          _validatedLatitude = result.latitude;
          _validatedLongitude = result.longitude;
          _validationMessage = "✅ Adresse validée avec succès";
        } else {
          _validationMessage = "❌ ${result.errorMessage}";
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _isAddressValid = false;
        _validationMessage = "❌ Erreur: $e";
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_isAddressValid) {
      _showSnackBar("Veuillez d'abord valider l'adresse", widget.errorColor);
      return;
    }

    // Préparer les données
    Map<String, dynamic> addressData = {
      'numero': int.tryParse(_numeroController.text),
      'rue': {
        'nomRue': _rueController.text,
        'localite': {
          'commune': _communeController.text,
          'codePostal': _codePostalController.text
        }
      },
      'latitude': _validatedLatitude,
      'longitude': _validatedLongitude,
      'is_validated': true,
      'validation_date': DateTime.now().toIso8601String(),
    };

    try {
      widget.setLoadingState(true);

      await AddressUpdateService.updateUserAddress(
        context,
        widget.currentUser,
        addressData,
        successGreen: widget.successColor,
        errorRed: widget.errorColor,
        setLoadingState: widget.setLoadingState,
      );

      Navigator.of(context).pop(true);
      _showSnackBar("✅ Adresse mise à jour avec succès", widget.successColor);

    } catch (e) {
      _showSnackBar("❌ Erreur: $e", widget.errorColor);
    } finally {
      widget.setLoadingState(false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.location_on, color: widget.primaryColor),
          SizedBox(width: 8),
          Text(
            "Modifier l'adresse",
            style: TextStyle(
              color: widget.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Numéro
              TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Numéro",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro est requis';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Rue avec autocomplétion
              StreetAutocomplete(
                streetController: _rueController,
                communeController: _communeController,
                codePostalController: _codePostalController,
                geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
                onStreetSelected: _resetValidation,
                onStreetChanged: _resetValidation,
              ),
              SizedBox(height: 16),

              // Code postal avec autocomplétion commune
              CommuneAutoFill(
                codePostalController: _codePostalController,
                communeController: _communeController,
                geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
                onCommuneFound: _resetValidation,
                onCommuneNotFound: _resetValidation,
              ),
              SizedBox(height: 16),

              // Commune (lecture seule)
              TextFormField(
                controller: _communeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Commune",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              SizedBox(height: 20),

              // Bouton de validation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isValidating ? null : _validateAddress,
                  icon: _isValidating
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.check_circle),
                  label: Text(_isValidating ? "Validation..." : "Valider l'adresse"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Message de validation
              if (_validationMessage != null) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isAddressValid
                        ? widget.successColor.withOpacity(0.1)
                        : widget.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isAddressValid ? widget.successColor : widget.errorColor,
                    ),
                  ),
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: _isAddressValid ? widget.successColor : widget.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // Coordonnées GPS
              if (_isAddressValid && _validatedLatitude != null && _validatedLongitude != null) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📍 Coordonnées GPS :",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Lat: ${_validatedLatitude!.toStringAsFixed(6)}",
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                      Text(
                        "Lng: ${_validatedLongitude!.toStringAsFixed(6)}",
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: Text("Annuler"),
        ),
        TextButton(
          onPressed: _isAddressValid ? _saveAddress : null,
          style: TextButton.styleFrom(
            foregroundColor: _isAddressValid ? widget.primaryColor : Colors.grey,
          ),
          child: Text("Sauvegarder"),
        ),
      ],
    );
  }
}
















// // lib/pages/profil/widgets/address_change_widget.dart
// // Remplacer complètement le contenu de votre fichier par ceci
//
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_update_service.dart';
// import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_validation.dart';
//
// import '../../../../../models/adresse.dart' as AdresseModel;
// import '../../../profil_widgets/auto_complete_widget.dart';
// import '../../../profil_widgets/commune_autofill_widget.dart';
//
// class AddressChangeWidget extends StatefulWidget {
//   final CurrentUser currentUser;
//   final Adresse? currentAddress;
//   final Function(bool) setLoadingState;
//   final Color primaryColor;
//   final Color successColor;
//   final Color errorColor;
//
//   const AddressChangeWidget({
//     super.key,
//     required this.currentUser,
//     this.currentAddress,
//     required this.setLoadingState,
//     required this.primaryColor,
//     required this.successColor,
//     required this.errorColor,
//   });
//
//   @override
//   State<AddressChangeWidget> createState() => _AddressChangeWidgetState();
// }
//
// class _AddressChangeWidgetState extends State<AddressChangeWidget> {
//   final _formKey = GlobalKey<FormState>();
//
//   // Contrôleurs
//   late TextEditingController _numeroController;
//   late TextEditingController _rueController;
//   late TextEditingController _communeController;
//   late TextEditingController _codePostalController;
//
//   // État de validation
//   bool _isValidating = false;
//   bool _isAddressValid = false;
//   String? _validationMessage;
//   double? _validatedLatitude;
//   double? _validatedLongitude;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialiser les contrôleurs avec conversion explicite
//     _numeroController = TextEditingController(
//         text: widget.currentAddress?.numero != null
//             ? widget.currentAddress!.numero.toString()
//             : ''
//     );
//     _rueController = TextEditingController(
//         text: widget.currentAddress?.rue?.nomRue ?? ''
//     );
//     _communeController = TextEditingController(
//         text: widget.currentAddress?.rue?.localite?.commune ?? ''
//     );
//     _codePostalController = TextEditingController(
//         text: widget.currentAddress?.rue?.localite?.codePostal ?? ''
//     );
//
//     // Reset validation quand l'utilisateur modifie
//     _numeroController.addListener(_resetValidation);
//     _rueController.addListener(_resetValidation);
//     _communeController.addListener(_resetValidation);
//     _codePostalController.addListener(_resetValidation);
//   }
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //
//   //   // Initialiser les contrôleurs
//   //   _numeroController = TextEditingController(
//   //       text: widget.currentAddress?.numero?.toString() ?? '' // ✅ Conversion int? → String
//   //   );
//   //   _rueController = TextEditingController(
//   //       text: widget.currentAddress?.rue?.nomRue ?? ''
//   //   );
//   //   _communeController = TextEditingController(
//   //       text: widget.currentAddress?.rue?.localite?.commune ?? ''
//   //   );
//   //   _codePostalController = TextEditingController(
//   //       text: widget.currentAddress?.rue?.localite?.codePostal ?? ''
//   //   );
//   //
//   //   // Reset validation quand l'utilisateur modifie
//   //   _numeroController.addListener(_resetValidation);
//   //   _rueController.addListener(_resetValidation);
//   //   _communeController.addListener(_resetValidation);
//   //   _codePostalController.addListener(_resetValidation);
//   // }
//
//   @override
//   void dispose() {
//     _numeroController.dispose();
//     _rueController.dispose();
//     _communeController.dispose();
//     _codePostalController.dispose();
//     super.dispose();
//   }
//
//   void _resetValidation() {
//     if (_isAddressValid) {
//       setState(() {
//         _isAddressValid = false;
//         _validationMessage = null;
//         _validatedLatitude = null;
//         _validatedLongitude = null;
//       });
//     }
//   }
//
//   Future<void> _validateAddress() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       _isValidating = true;
//       _validationMessage = null;
//     });
//
//     // Créer l'adresse pour validation avec le bon modèle
//     final adresse = AdresseModel.Adresse(
//       numero: int.tryParse(_numeroController.text),
//       rue: AdresseModel.Rue(
//         nomRue: _rueController.text,
//         localite: AdresseModel.Localite(
//           commune: _communeController.text,
//           codePostal: _codePostalController.text,
//         ),
//       ),
//     );
//
//     try {
//       final result = await AddressValidationService.validateAddress(adresse);
//
//       setState(() {
//         _isValidating = false;
//         _isAddressValid = result.isValid;
//
//         if (result.isValid) {
//           _validatedLatitude = result.latitude;
//           _validatedLongitude = result.longitude;
//           _validationMessage = "✅ Adresse validée avec succès";
//         } else {
//           _validationMessage = "❌ ${result.errorMessage}";
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _isValidating = false;
//         _isAddressValid = false;
//         _validationMessage = "❌ Erreur: $e";
//       });
//     }
//   }
//
//   // Future<void> _validateAddress() async {
//   //   if (!_formKey.currentState!.validate()) return;
//   //
//   //   setState(() {
//   //     _isValidating = true;
//   //     _validationMessage = null;
//   //   });
//   //
//   //   // Créer l'adresse pour validation
//   //   final adresse = Adresse(
//   //     numero: int.tryParse(_numeroController.text),
//   //     rue: Rue(
//   //       nomRue: _rueController.text,
//   //       localite: Localite(
//   //         commune: _communeController.text,
//   //         codePostal: _codePostalController.text,
//   //       ),
//   //     ),
//   //   );
//   //
//   //   try {
//   //     final result = await AddressValidationService.validateAddress(adresse);
//   //
//   //     setState(() {
//   //       _isValidating = false;
//   //       _isAddressValid = result.isValid;
//   //
//   //       if (result.isValid) {
//   //         _validatedLatitude = result.latitude;
//   //         _validatedLongitude = result.longitude;
//   //         _validationMessage = "✅ Adresse validée avec succès";
//   //       } else {
//   //         _validationMessage = "❌ ${result.errorMessage}";
//   //       }
//   //     });
//   //   } catch (e) {
//   //     setState(() {
//   //       _isValidating = false;
//   //       _isAddressValid = false;
//   //       _validationMessage = "❌ Erreur: $e";
//   //     });
//   //   }
//   // }
//
//   Future<void> _saveAddress() async {
//     if (!_isAddressValid) {
//       _showSnackBar("Veuillez d'abord valider l'adresse", widget.errorColor);
//       return;
//     }
//
//     // Préparer les données
//     Map<String, dynamic> addressData = {
//       'numero': int.tryParse(_numeroController.text),
//       'rue': {
//         'nomRue': _rueController.text,
//         'localite': {
//           'commune': _communeController.text,
//           'codePostal': _codePostalController.text
//         }
//       },
//       'latitude': _validatedLatitude,
//       'longitude': _validatedLongitude,
//       'is_validated': true,
//       'validation_date': DateTime.now().toIso8601String(),
//     };
//
//     try {
//       widget.setLoadingState(true);
//
//       await AddressUpdateService.updateUserAddress(
//         context,
//         widget.currentUser,
//         addressData,
//         successGreen: widget.successColor,
//         errorRed: widget.errorColor,
//         setLoadingState: widget.setLoadingState,
//       );
//
//       Navigator.of(context).pop(true);
//       _showSnackBar("✅ Adresse mise à jour avec succès", widget.successColor);
//
//     } catch (e) {
//       _showSnackBar("❌ Erreur: $e", widget.errorColor);
//     } finally {
//       widget.setLoadingState(false);
//     }
//   }
//
//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Row(
//         children: [
//           Icon(Icons.location_on, color: widget.primaryColor),
//           SizedBox(width: 8),
//           Text(
//             "Modifier l'adresse",
//             style: TextStyle(
//               color: widget.primaryColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Numéro
//               TextFormField(
//                 controller: _numeroController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: "Numéro",
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: widget.primaryColor, width: 2),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Le numéro est requis';
//                   }
//                   if (int.tryParse(value) == null) {
//                     return 'Numéro invalide';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//
//               // Rue avec autocomplétion
//               StreetAutocomplete(
//                 streetController: _rueController,
//                 communeController: _communeController,
//                 codePostalController: _codePostalController,
//                 geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
//                 onStreetSelected: _resetValidation,
//                 onStreetChanged: _resetValidation,
//               ),
//               SizedBox(height: 16),
//
//               // Code postal avec autocomplétion commune
//               CommuneAutoFill(
//                 codePostalController: _codePostalController,
//                 communeController: _communeController,
//                 geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
//                 onCommuneFound: _resetValidation,
//                 onCommuneNotFound: _resetValidation,
//               ),
//               SizedBox(height: 16),
//
//               // Commune (lecture seule)
//               TextFormField(
//                 controller: _communeController,
//                 readOnly: true,
//                 decoration: InputDecoration(
//                   labelText: "Commune",
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                   filled: true,
//                   fillColor: Colors.grey[100],
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Bouton de validation
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _isValidating ? null : _validateAddress,
//                   icon: _isValidating
//                       ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                   )
//                       : Icon(Icons.check_circle),
//                   label: Text(_isValidating ? "Validation..." : "Valider l'adresse"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: widget.primaryColor,
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                   ),
//                 ),
//               ),
//
//               // Message de validation
//               if (_validationMessage != null) ...[
//                 SizedBox(height: 12),
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _isAddressValid
//                         ? widget.successColor.withOpacity(0.1)
//                         : widget.errorColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: _isAddressValid ? widget.successColor : widget.errorColor,
//                     ),
//                   ),
//                   child: Text(
//                     _validationMessage!,
//                     style: TextStyle(
//                       color: _isAddressValid ? widget.successColor : widget.errorColor,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//
//               // Coordonnées GPS
//               if (_isAddressValid && _validatedLatitude != null && _validatedLongitude != null) ...[
//                 SizedBox(height: 12),
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "📍 Coordonnées GPS :",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         "Lat: ${_validatedLatitude!.toStringAsFixed(6)}",
//                         style: TextStyle(fontSize: 12, color: Colors.blue[700]),
//                       ),
//                       Text(
//                         "Lng: ${_validatedLongitude!.toStringAsFixed(6)}",
//                         style: TextStyle(fontSize: 12, color: Colors.blue[700]),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           style: TextButton.styleFrom(foregroundColor: Colors.grey),
//           child: Text("Annuler"),
//         ),
//         TextButton(
//           onPressed: _isAddressValid ? _saveAddress : null,
//           style: TextButton.styleFrom(
//             foregroundColor: _isAddressValid ? widget.primaryColor : Colors.grey,
//           ),
//           child: Text("Sauvegarder"),
//         ),
//       ],
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
// // // lib/pages/profil/widgets/address_change_widget.dart
// // // Créer ce nouveau fichier
// //
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/current_user.dart';
// // import 'package:hairbnb/pages/profil/profil_widgets/auto_complete_widget.dart';
// // import 'package:hairbnb/pages/profil/profil_widgets/commune_autofill_widget.dart';
// //
// // import 'adress_update_service.dart';
// // import 'adress_validation.dart';
// //
// // class AddressChangeWidget extends StatefulWidget {
// //   final CurrentUser currentUser;
// //   final Adresse? currentAddress;
// //   final Function(bool) setLoadingState;
// //   final Color primaryColor;
// //   final Color successColor;
// //   final Color errorColor;
// //
// //   const AddressChangeWidget({
// //     super.key,
// //     required this.currentUser,
// //     this.currentAddress,
// //     required this.setLoadingState,
// //     required this.primaryColor,
// //     required this.successColor,
// //     required this.errorColor,
// //   });
// //
// //   @override
// //   State<AddressChangeWidget> createState() => _AddressChangeWidgetState();
// // }
// //
// // class _AddressChangeWidgetState extends State<AddressChangeWidget> {
// //   final _formKey = GlobalKey<FormState>();
// //
// //   // Contrôleurs
// //   late TextEditingController _numeroController;
// //   late TextEditingController _rueController;
// //   late TextEditingController _communeController;
// //   late TextEditingController _codePostalController;
// //
// //   // État de validation
// //   bool _isValidating = false;
// //   bool _isAddressValid = false;
// //   String? _validationMessage;
// //   double? _validatedLatitude;
// //   double? _validatedLongitude;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //     // Initialiser les contrôleurs
// //     _numeroController = TextEditingController(
// //         text: widget.currentAddress?.numero?.toString() ?? ''
// //     );
// //     _rueController = TextEditingController(
// //         text: widget.currentAddress?.rue?.nomRue ?? ''
// //     );
// //     _communeController = TextEditingController(
// //         text: widget.currentAddress?.rue?.localite?.commune ?? ''
// //     );
// //     _codePostalController = TextEditingController(
// //         text: widget.currentAddress?.rue?.localite?.codePostal ?? ''
// //     );
// //
// //     // Reset validation quand l'utilisateur modifie
// //     _numeroController.addListener(_resetValidation);
// //     _rueController.addListener(_resetValidation);
// //     _communeController.addListener(_resetValidation);
// //     _codePostalController.addListener(_resetValidation);
// //   }
// //
// //   @override
// //   void dispose() {
// //     _numeroController.dispose();
// //     _rueController.dispose();
// //     _communeController.dispose();
// //     _codePostalController.dispose();
// //     super.dispose();
// //   }
// //
// //   void _resetValidation() {
// //     if (_isAddressValid) {
// //       setState(() {
// //         _isAddressValid = false;
// //         _validationMessage = null;
// //         _validatedLatitude = null;
// //         _validatedLongitude = null;
// //       });
// //     }
// //   }
// //
// //   Future<void> _validateAddress() async {
// //     if (!_formKey.currentState!.validate()) return;
// //
// //     setState(() {
// //       _isValidating = true;
// //       _validationMessage = null;
// //     });
// //
// //     // Créer l'adresse pour validation
// //     final adresse = Adresse(
// //       numero: int.tryParse(_numeroController.text),
// //       rue: Rue(
// //         nomRue: _rueController.text,
// //         localite: Localite(
// //           commune: _communeController.text,
// //           codePostal: _codePostalController.text,
// //         ),
// //       ),
// //     );
// //
// //     try {
// //       final result = await AddressValidationService.validateAddress(adresse);
// //
// //       setState(() {
// //         _isValidating = false;
// //         _isAddressValid = result.isValid;
// //
// //         if (result.isValid) {
// //           _validatedLatitude = result.latitude;
// //           _validatedLongitude = result.longitude;
// //           _validationMessage = "✅ Adresse validée avec succès";
// //         } else {
// //           _validationMessage = "❌ ${result.errorMessage}";
// //         }
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _isValidating = false;
// //         _isAddressValid = false;
// //         _validationMessage = "❌ Erreur: $e";
// //       });
// //     }
// //   }
// //
// //   Future<void> _saveAddress() async {
// //     if (!_isAddressValid) {
// //       _showSnackBar("Veuillez d'abord valider l'adresse", widget.errorColor);
// //       return;
// //     }
// //
// //     // Préparer les données
// //     Map<String, dynamic> addressData = {
// //       'numero': int.tryParse(_numeroController.text),
// //       'rue': {
// //         'nomRue': _rueController.text,
// //         'localite': {
// //           'commune': _communeController.text,
// //           'codePostal': _codePostalController.text
// //         }
// //       },
// //       'latitude': _validatedLatitude,
// //       'longitude': _validatedLongitude,
// //       'is_validated': true,
// //       'validation_date': DateTime.now().toIso8601String(),
// //     };
// //
// //     try {
// //       widget.setLoadingState(true);
// //
// //       await AddressUpdateService.updateUserAddress(
// //         context,
// //         widget.currentUser,
// //         addressData,
// //         successGreen: widget.successColor,
// //         errorRed: widget.errorColor,
// //         setLoadingState: widget.setLoadingState,
// //       );
// //
// //       Navigator.of(context).pop(true);
// //       _showSnackBar("✅ Adresse mise à jour avec succès", widget.successColor);
// //
// //     } catch (e) {
// //       _showSnackBar("❌ Erreur: $e", widget.errorColor);
// //     } finally {
// //       widget.setLoadingState(false);
// //     }
// //   }
// //
// //   void _showSnackBar(String message, Color color) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: color,
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return AlertDialog(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //       title: Row(
// //         children: [
// //           Icon(Icons.location_on, color: widget.primaryColor),
// //           SizedBox(width: 8),
// //           Text(
// //             "Modifier l'adresse",
// //             style: TextStyle(
// //               color: widget.primaryColor,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //         ],
// //       ),
// //       content: SingleChildScrollView(
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               // Numéro
// //               TextFormField(
// //                 controller: _numeroController,
// //                 keyboardType: TextInputType.number,
// //                 decoration: InputDecoration(
// //                   labelText: "Numéro",
// //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
// //                   focusedBorder: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                     borderSide: BorderSide(color: widget.primaryColor, width: 2),
// //                   ),
// //                 ),
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Le numéro est requis';
// //                   }
// //                   if (int.tryParse(value) == null) {
// //                     return 'Numéro invalide';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //
// //               // Rue avec autocomplétion
// //               StreetAutocomplete(
// //                 streetController: _rueController,
// //                 communeController: _communeController,
// //                 codePostalController: _codePostalController,
// //                 geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
// //                 onStreetSelected: _resetValidation,
// //                 onStreetChanged: _resetValidation,
// //               ),
// //               SizedBox(height: 16),
// //
// //               // Code postal avec autocomplétion commune
// //               CommuneAutoFill(
// //                 codePostalController: _codePostalController,
// //                 communeController: _communeController,
// //                 geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
// //                 onCommuneFound: _resetValidation,
// //                 onCommuneNotFound: _resetValidation,
// //               ),
// //               SizedBox(height: 16),
// //
// //               // Commune (lecture seule)
// //               TextFormField(
// //                 controller: _communeController,
// //                 readOnly: true,
// //                 decoration: InputDecoration(
// //                   labelText: "Commune",
// //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
// //                   filled: true,
// //                   fillColor: Colors.grey[100],
// //                 ),
// //               ),
// //               SizedBox(height: 20),
// //
// //               // Bouton de validation
// //               SizedBox(
// //                 width: double.infinity,
// //                 child: ElevatedButton.icon(
// //                   onPressed: _isValidating ? null : _validateAddress,
// //                   icon: _isValidating
// //                       ? SizedBox(
// //                     width: 20,
// //                     height: 20,
// //                     child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
// //                   )
// //                       : Icon(Icons.check_circle),
// //                   label: Text(_isValidating ? "Validation..." : "Valider l'adresse"),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: widget.primaryColor,
// //                     foregroundColor: Colors.white,
// //                     padding: EdgeInsets.symmetric(vertical: 12),
// //                   ),
// //                 ),
// //               ),
// //
// //               // Message de validation
// //               if (_validationMessage != null) ...[
// //                 SizedBox(height: 12),
// //                 Container(
// //                   width: double.infinity,
// //                   padding: EdgeInsets.all(12),
// //                   decoration: BoxDecoration(
// //                     color: _isAddressValid
// //                         ? widget.successColor.withOpacity(0.1)
// //                         : widget.errorColor.withOpacity(0.1),
// //                     borderRadius: BorderRadius.circular(8),
// //                     border: Border.all(
// //                       color: _isAddressValid ? widget.successColor : widget.errorColor,
// //                     ),
// //                   ),
// //                   child: Text(
// //                     _validationMessage!,
// //                     style: TextStyle(
// //                       color: _isAddressValid ? widget.successColor : widget.errorColor,
// //                       fontWeight: FontWeight.w500,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //
// //               // Coordonnées GPS
// //               if (_isAddressValid && _validatedLatitude != null && _validatedLongitude != null) ...[
// //                 SizedBox(height: 12),
// //                 Container(
// //                   width: double.infinity,
// //                   padding: EdgeInsets.all(12),
// //                   decoration: BoxDecoration(
// //                     color: Colors.blue.withOpacity(0.1),
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         "📍 Coordonnées GPS :",
// //                         style: TextStyle(
// //                           fontWeight: FontWeight.w600,
// //                           color: Colors.blue[800],
// //                         ),
// //                       ),
// //                       SizedBox(height: 4),
// //                       Text(
// //                         "Lat: ${_validatedLatitude!.toStringAsFixed(6)}",
// //                         style: TextStyle(fontSize: 12, color: Colors.blue[700]),
// //                       ),
// //                       Text(
// //                         "Lng: ${_validatedLongitude!.toStringAsFixed(6)}",
// //                         style: TextStyle(fontSize: 12, color: Colors.blue[700]),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ],
// //           ),
// //         ),
// //       ),
// //       actions: [
// //         TextButton(
// //           onPressed: () => Navigator.of(context).pop(),
// //           style: TextButton.styleFrom(foregroundColor: Colors.grey),
// //           child: Text("Annuler"),
// //         ),
// //         TextButton(
// //           onPressed: _isAddressValid ? _saveAddress : null,
// //           style: TextButton.styleFrom(
// //             foregroundColor: _isAddressValid ? widget.primaryColor : Colors.grey,
// //           ),
// //           child: Text("Sauvegarder"),
// //         ),
// //       ],
// //     );
// //   }
// // }