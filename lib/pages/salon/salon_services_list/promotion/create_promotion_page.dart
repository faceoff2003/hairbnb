import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePromotionModal extends StatefulWidget {
  final int serviceId; // ID du service concerné

  const CreatePromotionModal({Key? key, required this.serviceId}) : super(key: key);

  @override
  _CreatePromotionModalState createState() => _CreatePromotionModalState();
}

class _CreatePromotionModalState extends State<CreatePromotionModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _percentageController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool isLoading = false;

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      double discount = _percentageController.text.isNotEmpty
          ? double.tryParse(_percentageController.text) ?? 0.0
          : 0.0;

      String startDate;
      String endDate;
      try {
        startDate = _startDateController.text.isNotEmpty
            ? DateTime.parse(_startDateController.text).toIso8601String()
            : DateTime.now().toIso8601String();
        endDate = DateTime.parse(_endDateController.text).toIso8601String();
      } catch (e) {
        _showError("Format de date invalide.");
        return;
      }

      if (discount <= 0 || startDate.isEmpty || endDate.isEmpty) {
        _showError("Veuillez remplir tous les champs correctement.");
        return;
      }

      final response = await http.post(
        Uri.parse('https://www.hairbnb.site/api/create_promotion/${widget.serviceId}/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "discount_percentage": discount,
          "start_date": startDate,
          "end_date": endDate,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Promotion créée avec succès ✅"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        final responseData = json.decode(response.body);
        _showError("Erreur : ${responseData.toString()}");
      }
    } catch (e) {
      _showError("Erreur de connexion au serveur.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pour résoudre l'erreur "No Material widget found",
    // on enveloppe tout le contenu du modal dans un widget Material.
    return Material(
      color: Colors.transparent, // Permet de garder le fond transparent si besoin
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text("Créer une promotion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _percentageController,
                  decoration: const InputDecoration(labelText: "Pourcentage de réduction (%)"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Champ obligatoire";
                    double? parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0 || parsed > 100) return "Valeur entre 1 et 100";
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                    labelText: "Date de début",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          _startDateController.text = pickedDate.toIso8601String();
                        }
                      },
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Champ obligatoire" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _endDateController,
                  decoration: InputDecoration(
                    labelText: "Date de fin",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          _endDateController.text = pickedDate.toIso8601String();
                        }
                      },
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Champ obligatoire" : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitPromotion,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : const Text("Créer la promotion"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
















// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class CreatePromotionPage extends StatefulWidget {
//   final int serviceId; // ID du service concerné
//
//   const CreatePromotionPage({Key? key, required this.serviceId}) : super(key: key);
//
//   @override
//   _CreatePromotionPageState createState() => _CreatePromotionPageState();
// }
//
// class _CreatePromotionPageState extends State<CreatePromotionPage> {
//   final _formKey = GlobalKey<FormState>();
//   TextEditingController _percentageController = TextEditingController();
//   TextEditingController _startDateController = TextEditingController();
//   TextEditingController _endDateController = TextEditingController();
//   bool isLoading = false;
//
//   /// **📡 Envoie la promotion à l'API**
//   Future<void> _submitPromotion() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       // ✅ Convertir le pourcentage en double sécurisé
//       double discount = _percentageController.text.isNotEmpty
//           ? double.tryParse(_percentageController.text) ?? 0.0
//           : 0.0;
//
//       // ✅ Vérifier si l'utilisateur a sélectionné une date
//       String startDate;
//       String endDate;
//
//       try {
//         startDate = _startDateController.text.isNotEmpty
//             ? DateTime.parse(_startDateController.text).toIso8601String()
//             : DateTime.now().toIso8601String(); // ✅ Définit la date actuelle si vide
//
//         endDate = DateTime.parse(_endDateController.text).toIso8601String();
//       } catch (e) {
//         _showError("Format de date invalide.");
//         return;
//       }
//
//       // ✅ Vérifier que tous les champs sont remplis
//       if (discount <= 0 || startDate.isEmpty || endDate.isEmpty) {
//         _showError("Veuillez remplir tous les champs.");
//         return;
//       }
//
//       final response = await http.post(
//         Uri.parse('http://192.168.0.248:8000/api/create_promotion/${widget.serviceId}/'),
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "discount_percentage": discount, // ✅ Valeur sécurisée
//           "start_date": startDate, // ✅ Format ISO
//           "end_date": endDate, // ✅ Format ISO
//         }),
//       );
//
//       if (response.statusCode == 201) { // ✅ Vérifie le bon code HTTP
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Promotion créée avec succès ✅"), backgroundColor: Colors.green),
//         );
//         Navigator.pop(context, true); // ✅ Retour avec succès
//       } else {
//         final responseData = json.decode(response.body);
//         _showError("Erreur : ${responseData.toString()}"); // 🔥 DEBUG : Affiche toute la réponse
//       }
//     } catch (e) {
//       _showError("Erreur de connexion au serveur.");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
//
//
//
//   // Future<void> _submitPromotion() async {
//   //   if (!_formKey.currentState!.validate()) return;
//   //
//   //   setState(() {
//   //     isLoading = true;
//   //   });
//   //
//   //   try {
//   //     final response = await http.post(
//   //       Uri.parse('http://192.168.0.248:8000/api/create_promotion/${widget.serviceId}/'),
//   //       headers: {"Content-Type": "application/json"},
//   //       body: json.encode({
//   //         "service_id": widget.serviceId,
//   //         "discount_percentage": double.parse(_percentageController.text),
//   //         "start_date": _startDateController.text,
//   //         "end_date": _endDateController.text,
//   //       }),
//   //     );
//   //
//   //     if (response.statusCode == 200) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(content: Text("Promotion créée avec succès ✅"), backgroundColor: Colors.green),
//   //       );
//   //       Navigator.pop(context, true); // Retourne avec succès
//   //     } else {
//   //       final responseData = json.decode(response.body);
//   //       _showError(responseData['error'] ?? "Erreur inconnue.");
//   //     }
//   //   } catch (e) {
//   //     _showError("Erreur de connexion au serveur.");
//   //   } finally {
//   //     setState(() {
//   //       isLoading = false;
//   //     });
//   //   }
//   // }
//
//   /// **⚠️ Afficher une erreur**
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Créer une promotion"),
//         backgroundColor: Colors.orange,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // % de réduction
//               TextFormField(
//                 controller: _percentageController,
//                 decoration: const InputDecoration(labelText: "Pourcentage de réduction (%)"),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) return "Champ obligatoire";
//                   double? parsed = double.tryParse(value);
//                   if (parsed == null || parsed <= 0 || parsed > 100) return "Valeur entre 1 et 100";
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 10),
//
//               // Date de début
//               TextFormField(
//                 controller: _startDateController,
//                 decoration: InputDecoration(
//                   labelText: "Date de début",
//                   suffixIcon: IconButton(
//                     icon: Icon(Icons.calendar_today),
//                     onPressed: () async {
//                       DateTime? pickedDate = await showDatePicker(
//                         context: context,
//                         initialDate: DateTime.now(),
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime(2100),
//                       );
//                       if (pickedDate != null) {
//                         _startDateController.text = pickedDate.toIso8601String();
//                       }
//                     },
//                   ),
//                 ),
//                 validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
//               ),
//               const SizedBox(height: 10),
//
//               // Date de fin
//               TextFormField(
//                 controller: _endDateController,
//                 decoration: InputDecoration(
//                   labelText: "Date de fin",
//                   suffixIcon: IconButton(
//                     icon: Icon(Icons.calendar_today),
//                     onPressed: () async {
//                       DateTime? pickedDate = await showDatePicker(
//                         context: context,
//                         initialDate: DateTime.now(),
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime(2100),
//                       );
//                       if (pickedDate != null) {
//                         _endDateController.text = pickedDate.toIso8601String();
//                       }
//                     },
//                   ),
//                 ),
//                 validator: (value) => value!.isEmpty ? "Champ obligatoire" : null,
//               ),
//               const SizedBox(height: 20),
//
//               // Bouton de soumission
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : _submitPromotion,
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//                   child: isLoading
//                       ? CircularProgressIndicator(color: Colors.white)
//                       : const Text("Créer la promotion"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
