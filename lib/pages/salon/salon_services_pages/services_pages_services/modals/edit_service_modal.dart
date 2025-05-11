import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../../models/service_with_promo.dart';

Future<void> showEditServiceModal(BuildContext context,ServiceWithPromo serviceWithPromo, VoidCallback onSuccess) {
  final TextEditingController nameController = TextEditingController(text: serviceWithPromo.intitule);
  final TextEditingController descriptionController = TextEditingController(text: serviceWithPromo.description);
  final TextEditingController priceController = TextEditingController(text: serviceWithPromo.prix.toString());
  final TextEditingController durationController = TextEditingController(text: serviceWithPromo.temps.toString());

  bool isLoading = false;
  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color errorRed = Colors.red;
  final Color successGreen = Colors.green;

  Map<String, String?> errors = {'name': null, 'description': null, 'price': null, 'duration': null};
  Map<String, bool> isValid = {'name': true, 'description': true, 'price': true, 'duration': true};

  bool hasAtMostTwoDecimalPlaces(double value) {
    return ((value * 100).roundToDouble() == (value * 100));
  }

  void showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text("Modifié !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  void validateField(String key, String value, StateSetter setModalState) {
    switch (key) {
      case 'name':
        if (value.isEmpty) {
          errors[key] = "Le nom est obligatoire";
          isValid[key] = false;
        } else if (value.length > 100) {
          errors[key] = "Maximum 100 caractères";
          isValid[key] = false;
        } else {
          errors[key] = null;
          isValid[key] = true;
        }
        break;

      case 'description':
        if (value.isEmpty) {
          errors[key] = "Description requise";
          isValid[key] = false;
        } else if (value.length > 700) {
          errors[key] = "Maximum 700 caractères";
          isValid[key] = false;
        } else {
          errors[key] = null;
          isValid[key] = true;
        }
        break;

      case 'price':
        final parsed = double.tryParse(value);
        if (value.isEmpty) {
          errors[key] = "Prix requis";
          isValid[key] = false;
        } else if (parsed == null) {
          errors[key] = "Nombre invalide";
          isValid[key] = false;
        } else if (parsed > 999) {
          errors[key] = "Maximum 999€";
          isValid[key] = false;
        } else if (!hasAtMostTwoDecimalPlaces(parsed)) {
          errors[key] = "Max 2 décimales";
          isValid[key] = false;
        } else {
          errors[key] = null;
          isValid[key] = true;
        }
        break;

      case 'duration':
        final parsed = int.tryParse(value);
        if (value.isEmpty) {
          errors[key] = "Durée requise";
          isValid[key] = false;
        } else if (parsed == null || parsed <= 0) {
          errors[key] = "Durée invalide";
          isValid[key] = false;
        } else if (parsed > 480) {
          errors[key] = "Max 480 minutes";
          isValid[key] = false;
        } else {
          errors[key] = null;
          isValid[key] = true;
        }
        break;
    }

    setModalState(() {});
  }

  Widget buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      String fieldKey,
      StateSetter setModalState, {
        TextInputType? keyboardType,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (val) => validateField(fieldKey, val, setModalState),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryViolet),
              suffixIcon: errors[fieldKey] != null
                  ? Icon(Icons.close, color: errorRed)
                  : (isValid[fieldKey]! ? Icon(Icons.check_circle, color: successGreen) : null),
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: errors[fieldKey] != null
                    ? BorderSide(color: errorRed)
                    : (isValid[fieldKey]! ? BorderSide(color: successGreen) : BorderSide.none),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryViolet, width: 2),
              ),
            ),
          ),
          if (errors[fieldKey] != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: errorRed, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(errors[fieldKey]!, style: TextStyle(color: errorRed, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> updateService(StateSetter setModalState) async {
    final name = nameController.text.trim();
    final desc = descriptionController.text.trim();
    final prixText = priceController.text.trim();
    final durationText = durationController.text.trim();

    validateField('name', name, setModalState);
    validateField('description', desc, setModalState);
    validateField('price', prixText, setModalState);
    validateField('duration', durationText, setModalState);

    if (errors.values.any((e) => e != null)) return;

    setModalState(() => isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('https://www.hairbnb.site/api/update_service/${serviceWithPromo.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'intitule_service': name,
          'description': desc,
          'prix': double.parse(prixText),
          'temps_minutes': int.parse(durationText),
        }),
      );

      if (response.statusCode == 200) {
        showSuccessAnimation(context);
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(context).pop(); // success modal
          Navigator.of(context).pop(true); // bottom sheet
          onSuccess();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${response.body}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setModalState(() => isLoading = false);
    }
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                const Text("Modifier le service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 30),
                buildTextField("Nom du service", nameController, Icons.design_services, 'name', setModalState),
                buildTextField("Description", descriptionController, Icons.description, 'description', setModalState, maxLines: 3),
                buildTextField("Prix (€)", priceController, Icons.euro, 'price', setModalState, keyboardType: TextInputType.number),
                buildTextField("Durée (minutes)", durationController, Icons.timer, 'duration', setModalState, keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : () => updateService(setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryViolet,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
